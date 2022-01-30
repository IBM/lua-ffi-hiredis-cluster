-- @file enums.lua
-- Header definitions for Hiredis - exposes enums to Lua FFI.

local enums_string = [[
  typedef enum {
    REDIS_SSL_CTX_NONE = 0,
    REDIS_SSL_CTX_CREATE_FAILED,
    REDIS_SSL_CTX_CERT_KEY_REQUIRED,
    REDIS_SSL_CTX_CA_CERT_LOAD_FAILED,
    REDIS_SSL_CTX_CLIENT_CERT_LOAD_FAILED,
    REDIS_SSL_CTX_PRIVATE_KEY_LOAD_FAILED
} redisSSLContextError;

  enum redisConnectionType {
    REDIS_CONN_TCP,
    REDIS_CONN_UNIX,
    REDIS_CONN_USERFD
  };
]]

return enums_string
