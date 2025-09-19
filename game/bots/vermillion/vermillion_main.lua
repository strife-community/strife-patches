-- Custom logic for Vermillion Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

-- End Custom Abilities

-- Custom Behavior Tree Functions

local VermillionBot = {}

function VermillionBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(VermillionBot, self)
	return self
end

function VermillionBot:State_Init()
	-- Explosive flare
	local ability = TargetPositionAbility.Create(self, self.hero:GetAbility(0), true)
	self:RegisterAbility(ability)

	-- Rocket Jump
	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(3), false)
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

VermillionBot.Create(object)

