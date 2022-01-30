-- @file:cdefs.lua
-- Loads Hiredis using FFI creates access using cdefs.
local ffi = require("ffi")

local format = string.format

-- Order is important for cdef_file_names.
local cdef_file_names = {
  "enums",
  "structs",
  "functions",
}

local load_cdef_string = function()
  local cdefs = ""
  for _, file_name in pairs(cdef_file_names) do
    local added_string = require(format("hiredis.ffi.cdefs.%s", file_name))
    cdefs = format("%s\n%s", cdefs, added_string)
  end
  return cdefs
end

local function load_library(library_name)
  local ok, library
  ok, library = pcall(ffi.load, library_name, true)
  if ok then
    return library
  end
  error(format("Hiredis: failed loading library %s, last error was: %s", library_name, library))
end

local M = {}
M.loaded = false
M.__index = M

local hiredis, hiredis_ssl, hiredis_cluster

function M.load()
  if M.loaded then
    return hiredis, hiredis_ssl, hiredis_cluster
  end

  local ok, cdef_string

  -- Load hiredis library.
  hiredis = load_library("hiredis")
  hiredis_ssl = load_library("hiredis_ssl")
  hiredis_cluster = load_library("hiredis_cluster")


  ok, cdef_string = pcall(load_cdef_string)
  if not ok or not cdef_string then
    return false, "Redis C Driver: Failed to load CDEF string for FFI"
  end

  ok = pcall(ffi.cdef, cdef_string)

  if not ok then
    return false, format("Redis C Driver: Failed to define library functions when loading hiredis libraries.", cdef_string)
  end

  M.loaded = true
  return hiredis, hiredis_ssl, hiredis_cluster
end

return M
