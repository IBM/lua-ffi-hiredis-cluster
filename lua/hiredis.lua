-- @file hiredis.lua
-- FFI wrapper for hiredis-cluster C driver.
-- @see https://github.com/Nordix/hiredis-cluster

local ffi = require("ffi")
local loader = require("hiredis.ffi.loader")
local utils = require("hiredis.lib.hiredis_utils")
local command_creator = require("hiredis.lib.hiredis_command_creator")
local reply_handler = require("hiredis.lib.hiredis_reply_handler")
local constants = require("hiredis.lib.hiredis_constants")

local format, string_upper = string.format, string.upper
local check_error, hiredis_error = utils.check_error, utils.hiredis_error
local command_modes = constants.command_modes

local ok, hiredis, hiredis_ssl, hiredis_cluster = pcall(loader.load)
if not (ok and hiredis and hiredis_ssl and hiredis_cluster) then
  hiredis_error("FAILED_TO_LOAD_LIBRARY")
end

-- SSL Context lifetime needs to be global - Hiredis cluster can initiate reconnects behind the scenes.
local ssl_context

local function ssl_setup(cluster, ssl_config)
  hiredis_ssl.redisInitOpenSSL()
  local ssl_error = ffi.new("redisSSLContextError[1]")
  if ssl_config and ssl_config.cafile then
    local certificate_file = ssl_config.cafile
    local certificate_file_location = ssl_config.cadir

    ssl_context = ffi.gc(
      hiredis_ssl.redisCreateSSLContext(certificate_file, certificate_file_location, nil, nil, nil, ssl_error),
      hiredis_ssl.redisFreeSSLContext
    )

    if ssl_error[0] ~= "REDIS_SSL_CTX_NONE" then
      hiredis_error("SSL Context creation error:", constants.ssl_errors[tonumber(ssl_error[0])])
    end

    hiredis_cluster.redisClusterSetOptionEnableSSL(cluster, ssl_context)
  end
end

local M = {}
M.commands = nil
M.meta = {
  mode = command_modes.SYNC,
  pipeline_replies = 0,
}

M.__index = function(object, key)
  return object.commands[string_upper(key)] or hiredis_error("UNSUPPORTED_COMMAND", key)
end

-------------- Pipelining. --------------

local function reset_after_pipeline(instance)
  if not instance then
    -- Nothing to reset.
    return
  end

  --Driver reset outside of an active pipeline will completely reset the connection.
  if instance.meta.mode == command_modes.PIPELINE then
    -- Pipeline mode reset will only clear the reply queue - must be done before making additional calls.
    hiredis_cluster.redisClusterReset(instance.cluster)
  end

  instance.meta = {
    mode = command_modes.SYNC,
    pipeline_replies = 0,
  }
end

-- Receives a callback to execute Redis commands in pipeline mode.
-- Used to execute many commands quickly - replies can be returned or ignored.
-- @see https://redis.io/topics/pipelining
local function pipeline_callback(instance, callback, ignore_replies)
  if instance.meta.mode == command_modes.PIPELINE then
    reset_after_pipeline(instance)
    hiredis_error("RECURSIVE_PIPELINE_CALL")
  end

  instance.meta.mode = command_modes.PIPELINE
  local success, result = pcall(callback)
  if not success then
      -- Clean up.
      reset_after_pipeline(instance)
      -- Always return array.
      return { result }
  end

  local response = {}
  if not ignore_replies then
    for _ = 1, instance.meta.pipeline_replies do
      -- @see https://www.freelists.org/post/luajit/FFI-pointers-to-pointers,1
      local reply = ffi.new("redisReply*[1]")
      hiredis_cluster.redisClusterGetReply(instance.cluster, reply)

      -- ffi.new garbage collection does not follow pointers - specifiy garbage collection on the created object.
      ffi.gc(
        reply[0],
        hiredis.freeReplyObject
      )

      if reply[0] ~= nil then
        local _, parsed = pcall(reply_handler.parse_reply, instance.cluster, reply[0], {})
        response[#response + 1] = parsed
      end
    end
  end

  reset_after_pipeline(instance)

  return response
end

-------------- Base class --------------

local function hiredis_new()
  local m = {}
  setmetatable(m, M)
  m.cluster = nil
  m.commands = {}
  m.meta = {
    mode = command_modes.SYNC,
    pipeline_replies = 0,
  }
  return m
end

local function get_config(config)
  -- Use default config.
  local redis_config = constants.default_config

  -- Override defaults with configured values only.
  for key, value in pairs(config) do
    redis_config[key] = value
  end

  return redis_config
end

-- Reset Driver state in case of previous failures.
local function clear_state(instance)
  reset_after_pipeline(instance)
end

local function connect(config)
  config = get_config(config)

  local instance = hiredis_new()
  local cluster = ffi.gc(
    hiredis_cluster.redisClusterContextInit(),
    hiredis_cluster.redisClusterFree
  )

  -- Verify we have all the necessary parameters.
  if not (config and config.host and config.port) then
    hiredis_error("MISSING_CONFIG")
  end

  -- Set Redis cluster connection options.
  local node_address_string = format("%s:%s", tostring(config.host), tostring(config.port))
  hiredis_cluster.redisClusterSetOptionAddNodes(cluster, node_address_string);

  if config.ssl then
    ssl_setup(cluster, config.ssl)
  end

  if config.password then
    hiredis_cluster.redisClusterSetOptionPassword(cluster, config.password)
  end

  -- Connect timeout.
  local connection_timeout = ffi.new("timeval", { config.connection_timeout.seconds, config.connection_timeout.microseconds })
  hiredis_cluster.redisClusterSetOptionConnectTimeout(cluster, connection_timeout)

  -- Command timeout.
  local command_timeout = ffi.new("timeval", { config.command_timeout.seconds, config.command_timeout.microseconds })
  hiredis_cluster.redisClusterSetOptionTimeout(cluster, command_timeout)

  if config.max_retry_count then
    -- Max retries before command or connection fails. Will trigger cluster remapping.
    -- Renamed function to be replaced with redisClusterSetOptionMaxRetry in >v0.6.0.
    hiredis_cluster.redisClusterSetOptionMaxRedirect(cluster, config.max_retry_count)
  end

  -- Perform the connections to the cluster.
  hiredis_cluster.redisClusterConnect2(cluster)
  check_error(cluster)

  local extra_functions = {
    -- Verifies driver not stuck in another state after a failure.
    CLEAR_STATE = clear_state,
    PIPELINE = pipeline_callback,
  }

  instance.cluster = cluster
  instance.commands = command_creator.create_commands(instance, extra_functions)

  return instance
end

function M.init(config)
  return connect(config)
end

return M
