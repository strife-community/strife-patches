-- Custom logic for Lady Tinder Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

local SummonAbility = {}

function SummonAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	self.targetPos = self.owner:FindSummonPosition(self.ability:GetRange())
	return self.targetPos ~= nil
end

function SummonAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability, false)
	ShallowCopy(SummonAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local LadyTinderBot = {}

function LadyTinderBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(LadyTinderBot, self)
	return self
end

function LadyTinderBot:State_Init()
	-- Bindweed
	local ability = TargetPositionAbility.Create(self, self.hero:GetAbility(0), false, true)
	self:RegisterAbility(ability)

	-- Tinder Touch
	ability = TargetAllyAbility.Create(self, self.hero:GetAbility(1))
	self:RegisterAbility(ability)

	-- Stonebark Shield
	ability = TargetAllyAbility.Create(self, self.hero:GetAbility(2))
	self:RegisterAbility(ability)

	-- Nature's Fury
	ability = SummonAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

LadyTinderBot.Create(object)

