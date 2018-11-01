---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Dengcs.
--- DateTime: 2018/11/1 10:01
---
local random = require("utils.random")

local tb_insert = table.insert

local poker_manager = {}

function poker_manager.new()
	local manager = {}

	setmetatable(manager, {__index = poker_manager})
	manager:init()

	return manager
end

function poker_manager:init()
	self.pokers = {}
	self.places = {}

	for i = 1, GLOBAL_POKER_MAX do
		tb_insert(self.pokers, i)
	end

	for i = 1, GLOBAL_PLAYER_NUM do
		tb_insert(self.places, {cards = {}})
	end
end

-- 洗牌
function poker_manager:shuffle()
	local replace_count = GLOBAL_POKER_MAX * 3
	local temp_poker = 0
	for i = 1, replace_count do
		local random_idx = random.Get(54)
		local cur_idx = (i % GLOBAL_POKER_MAX) + 1
		if random_idx ~= cur_idx then
			temp_poker = self.pokers[cur_idx]
			self.pokers[cur_idx] 	= self.pokers[random_idx]
			self.pokers[random_idx] = temp_poker
		end
	end
end

-- 发牌
function poker_manager:deal()
	local poker_idx = 1
	for _, v in pairs(self.places) do
		for i = 1, GLOBAL_POKER_NUM do
			tb_insert(v.cards, self.pokers[poker_idx])
			poker_idx = poker_idx + 1
		end
	end
end

-- 获取底牌
function poker_manager:get_dipai()
	local cards = {}

	local start = #self.pokers
	for i = start, start-2, -1 do
		tb_insert(cards, self.pokers[i])
	end
	return cards
end

-- 获取某个位置的牌
function poker_manager:get_cards(idx)
	local place = self.places[idx]
	if place then
		return place.cards
	end
end

return poker_manager