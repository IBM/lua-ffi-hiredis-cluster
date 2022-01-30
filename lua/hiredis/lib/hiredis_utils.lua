-- @file hiredis_utils.lua
-- Utility functions for Redis FFI wrapper.
local ffi = require("ffi")
local constants = require("hiredis.lib.hiredis_constants")

local string_sub, string_find, format = string.sub, string.find, string.format
local insert = table.insert
local wrapper_errors = constants.wrapper_errors

local M = {}
M.__index = M

function M.hiredis_error(error_type, ...)
  -- Use one of the defined error types.
  error(format("%s : %s", format(wrapper_errors[error_type], ...), debug.traceback()), 2)
end

function M.string_split(text, delimiter)
  local delimiter_size = #delimiter

  if delimiter_size <= 0 then
    -- Invalid delimiter.
    return { text }
  end

  local start_position = 1
  local items = {}
  local delimiter_position

  while text and start_position do
    delimiter_position = string_find(text, delimiter, start_position, true)
    if delimiter_position then
      insert(items, string_sub(text, start_position, delimiter_position - 1))
      start_position = delimiter_position + delimiter_size
    else
      insert(items, string_sub(text, start_position))
      return items
    end
  end

  return items
end

function M.check_error(connection)
  if not connection then
    M.hiredis_error("REDIS_NOT_CONNECTED")
  end

  if connection.err ~= 0 then
    M.hiredis_error("REDIS_ERROR", ffi.string(connection.errstr))
  end

  return true
end

return M
