-- Custom logic for Ray Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

-- End Custom Abilities

-- Custom Behavior Tree Functions

local RayBot = {}

function RayBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(RayBot, self)
	return self
end

function RayBot:State_Init()
	-- Burrow Bots
	local ability = TargetPositionAbility.Create(self, self.hero:GetAbility(0))
	self:RegisterAbility(ability)

	-- Shock Field
	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(1))
	self:RegisterAbility(ability)

	-- Death Ray
	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

RayBot.Create(object)

