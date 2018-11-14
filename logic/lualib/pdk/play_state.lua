---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by dengcs.
--- DateTime: 2018/11/5 17:06
---
local ENUM = require("config.gameenum")

local PLAY_STATE = ENUM.PLAY_STATE

local STATE_COUNT = {
	[PLAY_STATE.PREPARE] = 1,
	[PLAY_STATE.DEAL] = 3,
	[PLAY_STATE.SNATCH] = 4,
	[PLAY_STATE.DOUBLE] = 3,
	[PLAY_STATE.PLAY] = 120,
}

local play_state = {}

function play_state.new()
	local manager = {}
	manager.play_core = {}

	setmetatable(manager, {__index = play_state})

	return manager
end

-- 接收玩法模块授权的函数
function play_state:copy_functions_from_core(functions)
	self.play_core.functions = assert(functions)
end

function play_state:state_notify(idx, state)
	local state_notify = self.play_core.functions.state_notify
	if state_notify then
		state_notify(idx, state)
	end
end

function play_state:push_bottom()
	local push_bottom = self.play_core.functions.push_bottom
	if push_bottom then
		push_bottom()
	end
end

function play_state:get_landowner()
	local get_landowner = self.play_core.functions.get_landowner
	if get_landowner then
		return get_landowner()
	end
end

function play_state:reset_state_param()
	self.count  	= 1
	self.place_idx	= 0
end

function play_state:start()
	self.state 	= PLAY_STATE.PREPARE
	self:reset_state_param()
end

function play_state:stop()
	self.state 	= PLAY_STATE.OVER
	self:reset_state_param()
end

function play_state:watch_turn()
	return self.place_idx,self.state
end

function play_state:turn()
	self:turn_worker()
	print("dcs------------", self.place_idx, self.state)
	return self.place_idx,self.state
end

function play_state:turn_worker()
	if self.state > PLAY_STATE.PLAY then
		return
	end

	local max_count = STATE_COUNT[self.state]
	self.count 	= self.count + 1

	if self.count > max_count then
		self.state = self.state + 1
		self:reset_state_param()
		self:handle_state_event()
	end

	self.place_idx	= (self.place_idx % GLOBAL_PLAYER_NUM) + 1
end

-- 发底牌
function play_state:handle_push_bottom()
	if self.state == PLAY_STATE.DOUBLE then
		self:push_bottom()
	end
end

-- 地主出牌
function play_state:handle_landowner_play()
	if self.state == PLAY_STATE.PLAY then
		local landowner = self:get_landowner()
		if landowner > 0 then
			self.place_idx = landowner - 1
		end
	end
end

function play_state:handle_state_event()
	self:handle_push_bottom()
	self:handle_landowner_play()
end

-- 运行到发牌
function play_state:run()
	repeat
		local place_idx, state = self:turn()
		self:state_notify(place_idx, state)
		if state > PLAY_STATE.DEAL then
			break
		end
	until(false)
end

function play_state:start_and_run()
	self:start()
	self:run()
end

function play_state:is_prepare()
	return self.state == PLAY_STATE.PREPARE
end

function play_state:is_snatch()
	return self.state == PLAY_STATE.SNATCH
end

function play_state:is_double()
	return self.state == PLAY_STATE.DOUBLE
end

function play_state:is_play()
	return self.state == PLAY_STATE.PLAY
end

function play_state:is_over()
	return self.state == PLAY_STATE.OVER
end

return play_state