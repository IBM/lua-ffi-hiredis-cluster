# lua-ffi-hiredis-cluster
A Lua FFI wrapper for hiredis-cluster library.
@see https://github.com/Nordix/hiredis-cluster

Tested on luajit 2.0.4 on Centos7.

### Usage:
```lua
local Redis = require("hiredis")

-- Settings available.
local settings = {
  host = "localhost",
  port = 6379,
}

local client = Redis.init(settings)

client.set("testkey", "testvalue")
print(client.get("testkey"))
```

```
$ luajit test.lua
testvalue
```

#### Pipelining sample:
```lua
local result = client.pipeline(function()
  client.set("testkey", "testvalue")
  client.get("testkey")
end)
for k,v in pairs(result) do
  print(k,v)
end
```

```
$ luajit test.lua
1	OK
2	testvalue
```

### Features supported:
 - Pipelining
 - SSL
 - Supported commands in `lua/hiredis/lib/hiredis_command_list.lua`

### Limitations:
 - Can only be used with Redis instances in cluster mode.
 - No transactions.
 - Functions that assume a single instance (like INFO) will not work. Use EVAL to perform them with any single key.

### Config
Available config values:

 - host - string, required. Address of one of the Redis cluster machines.
 - port - number, required. Port used.
 - ssl - table, optional:
   - cafile - string, optional (required if ssl table exists). Location of the certificate used to communicate with the cluster.
 - password - string, optional. Password for the Redis cluster (if exists).

## Install: 
On Centos7 - install in `/usr/lib64` and run `ldconfig -v`

### Dependencies:
hiredis, hiredis-ssl and hiredis-cluster libraries:
 - libhiredis.so (1.0.0)
 - libhiredis_ssl.so (1.0.0)
 - libhiredis_cluster.so (0.6.0)


### Compilation:
Run `./make_rocks.sh <TAG>` command (e.g. `./make_rocks.sh 0.1-36`).
