---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Dengcs.
--- DateTime: 2018/11/1 10:01
---
local random 	= require("utils.random")
local play_core	= require("pdk.play_core")

local tb_insert = table.insert

local play_manager = {}

function play_manager.new()
	local manager = {}
	manager.play_core = play_core.new()

	setmetatable(manager, {__index = play_manager})
	manager:init()

	return manager
end

function play_manager:init()
	self.pokers = {} -- 洗的牌
	self.places = {} -- 每个座位上的牌
	self.cards = {} -- 底牌
	self.game	= {} -- 游戏相关信息

	for i = 1, GLOBAL_POKER_MAX do
		tb_insert(self.pokers, i)
	end

	for i = 1, GLOBAL_PLAYER_NUM do
		tb_insert(self.places, {cards = {}})
	end

	local functions = self:auth_functions_to_core()
	self.play_core:copy_functions_from_manager(functions)
end

-- 接收游戏模块授权的函数
function play_manager:copy_functions_from_game(functions)
	self.game.functions = assert(functions)
end

-- 内部消息通知
function play_manager:event(id, data)
	local event = self.game.functions.event
	if event then
		event(id, data)
	end
end

-- 座位通知消息
function play_manager:notify(idx, data)
	local notify = self.game.functions.notify
	if notify then
		notify(idx, data)
	end
end

-- 游戏广播消息
function play_manager:broadcast(data)
	local broadcast = self.game.functions.broadcast
	if broadcast then
		broadcast(data)
	end
end

function play_manager:auth_functions_to_core()
	local function broadcast(data)
		self:broadcast(data)
	end

	local function notify(idx, data)
		self:notify(idx, data)
	end

	local function event(id, data)
		self:event(id, data)
	end

	local functions = {}
	functions.broadcast = broadcast
	functions.notify = notify
	functions.event = event

	return functions
end

-- 洗牌
function play_manager:shuffle()
	-- 1次随机洗牌
	local poker_max = GLOBAL_POKER_MAX
	local temp_poker = 0
	for i = 1, poker_max do
		local random_idx = random.Get(poker_max)
		local cur_idx = (i % poker_max) + 1
		if random_idx ~= cur_idx then
			temp_poker = self.pokers[cur_idx]
			self.pokers[cur_idx] 	= self.pokers[random_idx]
			self.pokers[random_idx] = temp_poker
		end
	end
end

-- 发牌
function play_manager:deal()
	local poker_idx = 1
	for _, v in pairs(self.places) do
		for i = 1, GLOBAL_POKER_NUM do
			v.cards[i] = self.pokers[poker_idx]
			poker_idx = poker_idx + 1
		end
		-- 初始化身份（0：平民，1：地主）
		v.identity = 0
	end

	-- 底牌
	for i = 1, 3 do
		self.cards[i] = self.pokers[poker_idx]
		poker_idx = poker_idx + 1
	end

	local core_data = {places = self.places, cards = self.cards}
	self.play_core:begin(core_data)
end

-- 洗牌并发牌
function play_manager:shuffle_and_deal()
	self:shuffle()
	self:deal()
end

-- 玩家操作
function play_manager:update(idx, data)
	self.play_core:update(idx, data)
end

return play_manager