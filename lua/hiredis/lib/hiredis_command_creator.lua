local M = {}
M.__index = M

local ffi = require("ffi")
local loader = require("hiredis.ffi.loader")
local utils = require("hiredis.lib.hiredis_utils")
local constants = require("hiredis.lib.hiredis_constants")
local command_list = require("hiredis.lib.hiredis_command_list")
local reply_handler = require("hiredis.lib.hiredis_reply_handler")

local unpack = unpack
local string_upper = string.upper
local table_concat, table_insert = table.concat, table.insert
local string_split, hiredis_error = utils.string_split, utils.hiredis_error
local parse_reply = reply_handler.parse_reply
local command_modes = constants.command_modes

local ok, hiredis, hiredis_ssl, hiredis_cluster = pcall(loader.load)
if not (ok and hiredis and hiredis_ssl and hiredis_cluster) then
  hiredis_error("FAILED_TO_LOAD_LIBRARY")
end

-- List of possible options for commands - provided per command in hiredis_command_list.lua.
local default_options = {
  -- Should dictionaries be converted to a list of strings.
  -- e.g. { key1 = value1, key2 = value2 } => "key1", "value1","key2", "value2".
  from_dictionary         = false,

  -- Should arrays be converted to a list of strings.
  -- e.g. { value1, value2 } => "value1", "value2".
  from_array              = false,

  -- Should remap response to a dictionary.
  to_dictionary           = false,

  -- Remaps response of 1 to true, otherwise false (for backwards compatibilty).
  to_boolean              = false,

  -- Remaps response to double (number) responses that return in the string field.
  to_double               = false,
}

local function create_command_strings(command, options, ...)
  local args = { command, ... }

  -- Select() counts all values - including nil.
  for index = 1, select("#", ...) do
    if type(args[index]) == "nil" then
      -- Nil values can cause segmetation faults or break correct argument order.
      hiredis_error("NIL_ARGUMENT_PASSED")
    end
  end

  if options.from_dictionary then
    local new_args = {}
    for _, value in pairs(args) do
      if type(value) == "table" then
        for sub_key, sub_value in pairs(value) do
          table_insert(new_args, sub_key)
          table_insert(new_args, sub_value)
        end
      else
        table_insert(new_args, value)
      end
    end
    args = new_args
  elseif options.from_array then
    local new_args = {}
    for _, value in pairs(args) do
      if type(value) == "table" then
        for _, array_value in pairs(value) do
          table_insert(new_args, array_value)
        end
      else
        table_insert(new_args, value)
      end
    end
    args = new_args
  end

  local args_lengths = {}
  for key, value in pairs(args) do
    -- All arguments are formatted as strings in Hiredis driver.
    -- e.g "EXPIRE key 10" - both "key" and "10" are a string.
    -- Segmetation fault can happen if value is not formatted to a string!
    args[key] = tostring(value)
    args_lengths[key] = #args[key] or 0
  end

    -- Last item in the strings array is an empty byte.
    local c_strings = ffi.new("const char*[?]", #args + 1, args)
    -- Forces empty strings or weird bytes to be sent correctly.
    local c_string_lengths = ffi.new("const size_t[?]", #args_lengths, args_lengths)

  return #args, c_strings, c_string_lengths
end

local function wrap_special_command(instance, callback)
    return function(...)
      callback(instance, ...)
    end
end

local function create_command(instance, command, options)
  options = options or {}
  local cluster = instance.cluster

  for key, value in pairs(default_options) do
    if options[key] == nil then
      options[key] =  value
    end
  end

  -- Allows to use "flavored" commands like HMSET_DICTIONARY.
  -- Uses a dictionary instead of a list of strings like HMSET.
  local command_parts = string_split(command, "_")
  command = string_upper(command_parts[1])

  local command_callback = function(...)

    local c_arg_count, c_strings, c_string_lengths = create_command_strings(command, options, ...)

    if instance.meta.mode == command_modes.PIPELINE then
      -- Pipeline uses different callback, and we need to track its replies.
      instance.meta.pipeline_replies = instance.meta.pipeline_replies + 1

      -- Garbage collection done when collecting the reply.
      return hiredis_cluster.redisClusterAppendCommandArgv(cluster, c_arg_count, c_strings, c_string_lengths)
    end

    return ffi.gc(
      hiredis_cluster.redisClusterCommandArgv(cluster, c_arg_count, c_strings, c_string_lengths),
      hiredis.freeReplyObject
    )
  end

  return function(...)
    -- TODO: Add metric reports.
    local success, result = pcall(command_callback, ...)
    if not success then
      hiredis_error("FAILED_TO_SEND_COMMAND", result)
    end

    if type(result) == "number" then
      -- Pipeline command.
      return
    end

    success, result = pcall(parse_reply, cluster, result, options)
    if not success then
      hiredis_error("FAILED_TO_PARSE_REPLY", result)
    end
    return result
  end
end

function M.create_commands(instance, extra_functions)
  local commands = {}
  extra_functions = extra_functions or {}

  -- Generic Redis calls.
  for command_name, options in pairs(command_list) do
    commands[command_name] = create_command(instance, command_name, options)
  end

  -- Special functions.
  for command_name, command_callback in pairs(extra_functions) do
    commands[string_upper(command_name)] = wrap_special_command(instance, command_callback)
  end
  return commands
end

return M
