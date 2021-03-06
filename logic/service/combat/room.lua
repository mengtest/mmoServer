--
-- 房间赛组队服务
--
local skynet  = require "skynet"
local service = require "factory.service"
local model = require "combat.room"
local utils = require "combat.utils"
local robot = require "combat.robot"
-- 底层驱动加载
local userdriver = require "driver.userdriver"

local COMMAND = {}

-----------------------------------------------------------
--- 房间赛队伍模型
-----------------------------------------------------------

-- 加载频道模型
local Channel = model.Channel

-----------------------------------------------------------
--- 内部变量/内部逻辑
-----------------------------------------------------------

-- 频道集合
local channels = 
{
	[1] = Channel.new(1),	-- 自由频道
	[2] = Channel.new(2),	-- 初级频道
	[3] = Channel.new(3),	-- 中级频道
	[4] = Channel.new(4),	-- 高级频道
}

-- 间隔时间
local function interval()
	return 500
end

local function schedule()
	-- 逻辑
	local function fn()
		for id, channel in pairs(channels) do
			for _, team in pairs(channel.teams) do
				if team:prepare() then
					if team:is_full() then
						utils.start(1,1,team:snapshot())
						team:start()
						team:convert("RUNNING")
					else
						local member = robot.generate_robot()
						team:join(member)
					end
				end
			end
		end
	end
	-- 异常处理
	local function catch(message)
		LOG_ERROR(message)
	end
	-- 任务处理
	xpcall(fn, catch)
	skynet.timeout(interval(), schedule)
end

-----------------------------------------------------------
--- 房间组队服务接口
-----------------------------------------------------------

-- 创建房间
-- 1. 频道编号
-- 2. 创建者信息
function COMMAND.on_create(cid, vdata)
    -- 获取频道
    local channel = channels[cid]
	if channel == nil then
		return ERRCODE.COMMON_PARAMS_ERROR
	end

	local bJoin = false
	for _, team in pairs(channel.teams) do
		if team:join(vdata) then
			bJoin = true
			break
		end
	end

	if bJoin == false then
		-- 创建房间
		local team = channel:create(vdata)
		if team == nil then
			return ERRCODE.ROOM_CREATE_FAILED
		end
	end

	return 0
end

-- 加入房间
-- 1. 频道编号
-- 2. 房间编号
-- 3. 角色信息
function COMMAND.on_join(cid, tid, vdata)
    -- 获取频道
    local channel = channels[cid]
    if channel == nil then
        return ERRCODE.COMMON_PARAMS_ERROR
    end
    
    -- 队伍检查
    local team = channel:get(tid)
    if team == nil then
        return ERRCODE.COMMON_CLIENT_ERROR
    end
    if not team:prepare() then
        return ERRCODE.COMMON_CLIENT_ERROR
    end
    
    -- 加入队伍
    local member = team:join(vdata)
    if member ~= nil then
        return 0
    else
        return ERRCODE.COMMON_SYSTEM_ERROR
    end
end

-- 邀请好友
-- 1. 频道编号
-- 2. 房间编号
-- 3. 角色编号
-- 4. 目标编号
function COMMAND.on_invite(cid, tid, source, uid)
	-- 获取频道
	local channel = channels[cid]
	if channel == nil then
		return ERRCODE.COMMON_PARAMS_ERROR
	end
	-- 队伍检查
	local team = channel:get(tid)
	if team == nil then
		return ERRCODE.ROOM_NOT_EXISTS
	end
	if not team:prepare() then
		return ERRCODE.ROOM_NOT_PERPARE
	end
	-- 成员检查
	local member = team:get(source)
	if member == nil then
		return ERRCODE.ROOM_PERMISSION_DINIED
	end
	-- 发出邀请
	local name = "room_invite_notify"
	local data =
	{
		channel  = cid,
		roomid   = team.id,
		uid      = member.uid,
		nickname = member.nickname,
	}
	userdriver.usersend(uid, "on_common_invite", name, data)
	return 0
end

-- 队伍聊天（聊天服务转发）
-- 1. 频道编号
-- 2. 聊天协议
-- 3. 聊天内容
function COMMAND.on_chat(cid, tid, name, data)
    -- 获取频道
    local channel = channels[cid]
    if channel == nil then
		return ERRCODE.COMMON_PARAMS_ERROR
    end
    -- 队伍检查
    local team = channel:get(tid)
    if team ~= nil then
		-- 消息转发
		team:broadcast(name, data)
		return 0
    else
		return ERRCODE.ROOM_NOT_EXISTS
    end
end

-- 取消准备
-- 1. 频道编号
-- 2. 房间编号
-- 3. 角色编号
function COMMAND.on_cancel(cid, tid, uid)
	-- 获取频道
	local channel = channels[cid]
	if channel == nil then
		return ERRCODE.COMMON_PARAMS_ERROR
	end
	-- 队伍检查
	local team = channel:get(tid)
	if team == nil then
		return ERRCODE.ROOM_NOT_EXISTS
	end
	if not team:prepare() then
		return ERRCODE.ROOM_NOT_PERPARE
	end
	-- 成员检查
	local member = team:get(uid)
	if member == nil then
		return ERRCODE.ROOM_PERMISSION_DINIED
	end
	-- 状态转换
	member:convert("PREPARE")
	team:synchronize(cid)
	return 0
end

-- 战场通知战斗结束
-- 1. 队伍信息
-- 2. 胜者编号
function COMMAND.on_game_finish(cid, tid, data)
	-- 获取频道
	local channel = channels[cid]
	if channel == nil then
		return ERRCODE.COMMON_PARAMS_ERROR
	end
	-- 队伍检查
	local team = channel:get(tid)
	if team == nil then
		return ERRCODE.COMMON_SYSTEM_ERROR
	end

	-- 变更状态
	team:convert("PREPARE")
	team:synchronize()

	return 0
end

-----------------------------------------------------------
--- 注册房间组队服务
-----------------------------------------------------------

local handler = {}

function handler.init_handler()
	skynet.timeout(interval(), schedule)
end

-- 消息分发逻辑
-- 1. 消息来源
-- 2. 消息类型
-- 3. 消息内容
function handler.command_handler(source, cmd, ...)
	local fn = COMMAND[cmd]
	if fn then
		return fn(...)
	else
		ERROR("svcmanager : command[%s] can't find!!!", cmd)
	end
end

service.start(handler)
