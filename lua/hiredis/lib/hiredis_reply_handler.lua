local ffi = require("ffi")
local utils = require("hiredis.lib.hiredis_utils")
local constants = require("hiredis.lib.hiredis_constants")

local check_error, hiredis_error = utils.check_error, utils.hiredis_error
local reply_types = constants.reply_types

local M = {}
M.__index = M

local callbacks = {

  STRING = function(connection, reply, options)
    return ffi.string(reply.str, reply.len)
  end,

  ARRAY = function(connection, reply, options)
    local result = {}
    for index = 0, (tonumber(reply.elements) - 1) or 0 do
      local _, parsed = pcall(M.parse_reply, connection,  reply.element[index], options)
      result[#result + 1] = parsed
    end
    if options.to_dictionary then
      local mapped_result = {}
      for index = 1,#result, 2 do
        mapped_result[result[index]] = result[index + 1]
      end
      result = mapped_result
    end
    return result
  end,

  NUMBER = function(connection, reply, options)
    return tonumber(reply.integer)
  end,

  DOUBLE = function(connection, reply, options)
    return tonumber(ffi.string(reply.str, reply.len))
  end,

  BOOLEAN = function(connection, reply, options)
    return tonumber(reply.integer) == 1
  end,

  NIL_VALUE = function(connection, reply, options)
    return nil
  end,

  NOT_IMPLEMENTED = function(connection, reply, options)
    hiredis_error("UNHANDLED_REPLY", reply.type)
  end,
}

local reply_callbacks = {
  [reply_types.STRING]  = callbacks.STRING,
  [reply_types.ARRAY]   = callbacks.ARRAY,
  [reply_types.INTEGER] = callbacks.NUMBER,
  [reply_types.NIL]     = callbacks.NIL_VALUE,
  [reply_types.STATUS]  = callbacks.STRING,
  [reply_types.ERROR]   = callbacks.STRING,
  [reply_types.DOUBLE]  = callbacks.DOUBLE,
  [reply_types.BOOL]    = callbacks.BOOLEAN,
  [reply_types.MAP]     = callbacks.ARRAY,
  [reply_types.SET]     = callbacks.ARRAY,
  -- ATTR Deprecated since Redis 6.0.6.
  [reply_types.ATTR]    = callbacks.NOT_IMPLEMENTED,
  [reply_types.PUSH]    = callbacks.ARRAY,
  [reply_types.BIGNUM]  = callbacks.DOUBLE,
  [reply_types.VERB]    = callbacks.STRING,
}

function M.parse_reply(connection, reply, options)
  check_error(connection)
  -- Parse reply.
  if reply and tonumber(reply.type) then
    if options.to_boolean then
      return callbacks.BOOLEAN(connection, reply, options)
    end
    if options.to_double then
      return callbacks.DOUBLE(connection, reply, options)
    end
    local callback = reply_callbacks[tonumber(reply.type)]
    if type(callback) ~= "function" then
      return callbacks.NOT_IMPLEMENTED
    end
    return callback(connection, reply, options)
  end
  hiredis_error("MALFORMED_REPLY")
end

return M
