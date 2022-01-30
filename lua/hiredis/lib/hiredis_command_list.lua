-- @file hiredis_command_list.lua
-- Stores available commands for hiredis_cluster module.
-- Note: Node-specific and utility functions (like info, keys, etc.) are
-- unavailable in cluster context and will not be supported by the driver.
-- To use them, use EVAL with a relevant script and 1 key, e.g.
-- `redis.EVAL('return redis.call("keys", "*")', 1, "somekey")`
-- This will query a node according to the key provided.

local command_list = {
  -- Utility.
  TYPE                = {},
  EXISTS              = {
    to_boolean = true,
  },
  -- Scripting
  EVAL                = {},
  -- Time to live.
  EXPIRE              = {
    to_boolean = true,
  },
  TTL                 = {},
  -- Standard keys.
  -- KEYS command is unsupported.
  GET                 = {},
  SET                 = {},
  DEL                 = {},
  -- GETSET is deprecated but SET with GET/EX/NX etc. is not supported in driver.
  GETSET              = {},
  -- SET and expire key.
  SETEX               = {},
  -- SET if not exist.
  SETNX               = {
    to_boolean = true,
  },
  INCR                = {},
  DECR                = {},
  INCRBY              = {},
  DECRBY              = {},
  -- Hashes.
  HSET                = {
    to_boolean = true,
  },
  -- TODO HSETEX expected in Redis 6.2 - replaces EVAL calls.
  HGET                = {},
  HDEL                = {
    from_array = true,
  },
  HGETALL             = {
    to_dictionary = true,
  },
  HEXISTS             = {
    to_boolean = true,
  },
  HSETNX              = {
    to_boolean = true,
  },
  HSCAN               = {},
  HINCRBY             = {},
  HINCRBYFLOAT        = {
    to_double = true,
  },
  HVALS               = {},
  HKEYS               = {},
  HLEN                = {},
  -- Multi set / get etc.
  MSET                = {},
  MGET                = {},
  -- HMSET/HMGET are deprecated but driver does not support variadic HSET/HGET.
  HMGET               = {},
  HMSET               = {},
  -- Flavored command that allows the developer to use a dictionary instead of a list of strings.
  -- The underscore separates the redis command string from the flavor name.
  HMSET_DICTIONARY    = {
    from_dictionary = true,
  },
  -- Sets.
  SADD                = {},
  SPOP                = {},
  SRANDMEMBER         = {},
  SREM                = {},
  SSCAN               = {},
  -- Lists.
  LINDEX              = {},
  LINSERT             = {},
  LLEN                = {},
  LPOP                = {},
  LPUSH               = {},
  LPUSHX              = {},
  LRANGE              = {},
  LREM                = {},
  LSET                = {},
  LTRIM               = {},
  RPOP                = {},
  RPUSH               = {},
  RPUSHX              = {},
}

return command_list
