-- Custom logic for Caprice Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Behavior Tree Functions

local CapriceBot = {}

function CapriceBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(CapriceBot, self)
	return self
end

function CapriceBot:State_Init()
	-- Fire Lager
	local ability = TargetPositionAbility.Create(self, self.hero:GetAbility(0), true)
	self:RegisterAbility(ability)

	-- Anchors
	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(1), true)
	self:RegisterAbility(ability)

	-- Quick Draw
	ability = EscapeAbility.Create(self, self.hero:GetAbility(3), false)
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

CapriceBot.Create(object)

