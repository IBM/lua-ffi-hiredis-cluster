local M = {}
M.__index = M

M.default_config = {
  host = "127.0.0.1",
  port = 6379,
  ssl = nil,
  max_retry_count = 100,
  command_timeout = {
    seconds = 5,
    microseconds = 0,
  },
  connection_timeout = {
    seconds = 10,
    microseconds = 0,
  },
}

M.wrapper_errors = {
  REDIS_ERROR                 = "Redis error: %s",
  MISSING_CONFIG              = "Host and/or port not provided in config.",
  UNHANDLED_REPLY             = "Reply type %s parse callback is not implemented.",
  MALFORMED_REPLY             = "Reply object is nil or reply type field is not a number.",
  SSL_CONTEXT_ERROR           = "SSL Context error: %s",
  UNSUPPORTED_COMMAND         = "Unsupported command %s",
  REDIS_NOT_CONNECTED         = "Redis instance is not connected.",
  NIL_ARGUMENT_PASSED         = "A nil value was passed to redis command.",
  FAILED_TO_PARSE_REPLY       = "Parse command reply: %s",
  FAILED_TO_SEND_COMMAND      = "Failed to send command: %s",
  FAILED_TO_LOAD_LIBRARY      = "Failed to load hiredis library.",
  RECURSIVE_PIPELINE_CALL     = "Cannot call redis.pipeline inside pipeline callback.",
}

-- Order is important.
M.ssl_errors = {
  -- Index 0 is "no error", will never be used.
  "CREATE_FAILED",
  "CERT_KEY_REQUIRED",
  "CA_CERT_LOAD_FAILED",
  "CLIENT_CERT_LOAD_FAILED",
  "PRIVATE_KEY_LOAD_FAILED",
}

-- @see read.h - REDIS_REPLY_* defines.
M.reply_types = {
  STRING  = 1,
  ARRAY   = 2,
  INTEGER = 3,
  NIL     = 4,
  STATUS  = 5,
  ERROR   = 6,
  DOUBLE  = 7,
  BOOL    = 8,
  MAP     = 9,
  SET     = 10,
  ATTR    = 11,
  PUSH    = 12,
  BIGNUM  = 13,
  VERB    = 14,
}

-- @see read.h - * defines.
M.error_types = {
  IO        = 1,
  OTHER     = 2,
  EOF       = 3,
  PROTOCOL  = 4,
  OOM       = 5,
  TIMEOUT   = 6,
}

M.command_modes = {
  SYNC = 1,
  PIPELINE = 2,
}

return M
