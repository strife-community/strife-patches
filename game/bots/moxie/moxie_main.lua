-- Custom logic for Moxie Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

-- End Custom Abilities

-- Custom Behavior Tree Functions

local MoxieBot = {}

function MoxieBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(MoxieBot, self)
	return self
end

function MoxieBot:State_Init()
	-- Zap
	local ability = TargetEnemyAbility.Create(self, self.hero:GetAbility(0), false)
	self:RegisterAbility(ability)

	-- Lightning Blast
	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(1), false)
	self:RegisterAbility(ability)

	-- Rolling Thunder
	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(3), false)
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

MoxieBot.Create(object)

