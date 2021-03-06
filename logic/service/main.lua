local skynet = require "skynet_ex"
local spconf = require "config.spconf"
local hibernaloader = require "data.hibernaloader"

skynet.start(function()
  skynet.error("Server start")
  skynet.newservice("debug_console",41001)

  hibernaloader.register(spconf)
  
  -- 启动公共服务
  local services = require("config.services")
  local summdriver = skynet.summdriver()
  summdriver.start()
  summdriver.autoload(services.list)

  local gated = skynet.newservice("client/gated")
  skynet.name(GLOBAL.SERVICE_NAME.GATED,gated)
  skynet.call(gated, "lua", "open", {
    port = 51001,
    maxclient = 100,
    nodelay = true,
  })
  
  -- 启动控制后台
  local cmd = skynet.newservice("httpd", "logic.cmd", 1)
  skynet.call(cmd, "lua", "init", {
    address = "0.0.0.0",
    port    = 41002,
    auto    = true,
    router  = { "router.cmd" },
  })

  skynet.error("Server end")
  skynet.exit()
end)