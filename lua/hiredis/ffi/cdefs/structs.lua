-- @file structs.lua
-- Header definitions for Hiredis - exposes structs to Lua FFI.
-- Note: some structs are defined to be "ignored" by FFI (e.g. SSL_CTX).
-- There is no need to completely define every struct and sub-struct, only those that are exposed to Lua.

local structs_string = [[
  typedef struct hiarray hiarray;
  typedef struct cluster_node cluster_node;
  typedef struct hilist hilist;
  typedef struct redisReader redisReader;
  typedef struct redisContextFuncs redisContextFuncs;
  typedef struct redisPushFn redisPushFn;
  typedef struct SSL_CTX SSL_CTX;
  typedef int redisFD;

  typedef long time_t;
  typedef struct timeval {
    time_t tv_sec;
    time_t tv_usec;
  } timeval;

  typedef struct redisSSLContext {
    SSL_CTX *ssl_ctx;
  } redisSSLContext;

  typedef struct redisReply {
    int type;
    long long integer;
    double dval;
    size_t len;
    char *str;
    char vtype[4];
    size_t elements;
    struct redisReply **element;
  } redisReply;

  typedef struct redisContext {
    const redisContextFuncs *funcs;
    int err;
    char errstr[128];
    redisFD fd;
    int flags;
    char *obuf;
    redisReader *reader;

    enum redisConnectionType connection_type;
    struct timeval *connect_timeout;
    struct timeval *command_timeout;

    struct {
        char *host;
        char *source_addr;
        int port;
    } tcp;

    struct {
        char *path;
    } unix_sock;

    struct sockadr *saddr;
    size_t addrlen;
    void *privdata;
    void (*free_privdata)(void *);
    void *privctx;
    redisPushFn *push_cb;
  } redisContext;

  typedef struct redisClusterContext {
    int err;
    char errstr[128];

    int flags;
    struct timeval *connect_timeout;
    struct timeval *command_timeout;
    int max_retry_count;
    char password[512 + 1];

    struct dict *nodes;
    struct hiarray *slots;
    uint64_t route_version;
    cluster_node *table[16384];

    struct hilist *requests;

    int retry_count;
    int need_update_route;
    int64_t update_route_time;
    redisSSLContext *ssl;
  } redisClusterContext;
]]

return structs_string
