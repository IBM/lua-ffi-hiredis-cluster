-- @file functions.lua
-- Header definitions for Hiredis - exposes functions to Lua.
-- Note some functions have altered signature.
-- I.E. redisClusterCommand, in original header would return void*, changed to redisReply*.

local functions_string = [[
  int redisClusterConnect2(redisClusterContext *cc);
  redisClusterContext *redisClusterConnectWithTimeout(const char *addrs, const struct timeval tv, int flags);
  redisClusterContext *redisClusterContextInit(void);
  void redisClusterFree(redisClusterContext *cc);

  int redisClusterSetOptionAddNode(redisClusterContext *cc, const char *addr);
  int redisClusterSetOptionAddNodes(redisClusterContext *cc, const char *addrs);
  int redisClusterSetOptionConnectBlock(redisClusterContext *cc);
  int redisClusterSetOptionConnectNonBlock(redisClusterContext *cc);
  int redisClusterSetOptionParseSlaves(redisClusterContext *cc);
  int redisClusterSetOptionParseOpenSlots(redisClusterContext *cc);
  int redisClusterSetOptionRouteUseSlots(redisClusterContext *cc);
  int redisClusterSetOptionConnectTimeout(redisClusterContext *cc, const struct timeval tv);
  int redisClusterSetOptionTimeout(redisClusterContext *cc, const struct timeval tv);
  int redisClusterSetOptionMaxRedirect(redisClusterContext *cc, int max_retry_count);
  int redisClusterSetOptionPassword(redisClusterContext *cc, const char *password);

  int redisInitOpenSSL(void);
  int redisInitiateSSLWithContext(redisContext *c, redisSSLContext *redis_ssl_ctx);
  redisSSLContext *redisCreateSSLContext(const char *cacert_filename, const char *capath, const char *cert_filename, const char *private_key_filename, const char *server_name, redisSSLContextError *error);
  int redisClusterSetOptionEnableSSL(redisClusterContext *cc, redisSSLContext *ssl);
  void redisFreeSSLContext(redisSSLContext *redis_ssl_ctx);

  redisReply *redisClusterCommand(redisClusterContext *cc, const char *format, ...);
  redisReply *redisClusterCommandArgv(redisClusterContext *cc, int argc, const char **argv, const size_t *argvlen);
  void freeReplyObject(void *reply);

  int redisClusterAppendCommand(redisClusterContext *cc, const char *format, ...);
  int redisClusterAppendCommandArgv(redisClusterContext *cc, int argc, const char **argv, const size_t *argvlen);
  int redisClusterGetReply(redisClusterContext *cc, redisReply **reply);
  void redisClusterReset(redisClusterContext *cc);

  redisReply *redisCommand(redisContext *c, const char *format, ...);
  redisReply *redisCommandArgv(redisContext *c, int argc, const char **argv, const size_t *argvlen);
]]

return functions_string
