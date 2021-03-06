--
-- 房间战组队
--
local skynet  = require "skynet"
local handler = {}
local REQUEST = {}

-----------------------------------------------------------
-- 请求服务接口
-----------------------------------------------------------


-- 创建房间
function REQUEST:room_create()
    local resp = "room_create_resp"
    local ret = 0
    
    local vdata = self.user:call("Player", "get_snapshot")

    vdata.agent = skynet.self()
    local ok = skynet.call(GLOBAL.SERVICE_NAME.ROOM, "lua", "on_create", 1, vdata)
    if ok ~= 0 then
        ret = ERRCODE.ROOM_CREATE_FAILED
    end

    local ret_msg = {ret = ret}
    self.response(resp, ret_msg)
end

-- 快速加入
function REQUEST:room_qkjoin()
	local resp = "room_qkjoin_resp"
    local ret = 0
    
    local ret_msg = {ret = ret}
    self.response(resp, ret_msg)
end

-- 离开房间
function REQUEST:room_quit()
	local resp = "room_quit_resp"
    local ret = 0
    
    local ret_msg = {ret = ret}
    self.response(resp, ret_msg)
end

-- 邀请好友
function REQUEST:room_invite()
	local resp = "room_invite_resp"
    local ret = 0
    
    local ret_msg = {ret = ret}
    self.response(resp, ret_msg)
end

-- '请求/命令' - 注册
handler.REQUEST = REQUEST
return handler
