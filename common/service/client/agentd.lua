local skynet = require "skynet"

local csession

local CMD = {}

function CMD.connect(c)
  csession = c
end

function CMD.disconnect()
	skynet.exit()
end

function CMD.message(msg)
  if csession then
      if msg == "bye" then
        skynet.send(GLOBAL.SERVICE_NAME.GATED,"lua","logout",csession.fd)
      else
        skynet.send(GLOBAL.SERVICE_NAME.GATED,"lua","response",csession.fd,msg)
      end
  end
end

-- 内部命令转发
-- 1. 命令来源
-- 2. 命令名称
-- 3. 命令参数
local function command_handler(command, ...)
    skynet.error("This function is not implemented.")
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
	   skynet.error("dcs---cmd--"..cmd)
		 local fn = assert(CMD[cmd])
		 if fn then
       skynet.ret(skynet.pack(fn(...)))
		 else
		   skynet.ret(skynet.pack(command_handler(cmd, ...)))
		 end
	end)
end)
