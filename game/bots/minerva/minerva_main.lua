-- Custom logic for Minerva Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

local MinervaAbility = {}

function MinervaAbility:Evaluate()
	if self.owner.hero:GetHealthPercent() < 0.75 then
		return false
	end

	return TargetEnemyAbility.Evaluate(self)
end

function MinervaAbility.Create(owner, ability)
	local self = TargetEnemyAbility.Create(owner, ability, true)
	ShallowCopy(MinervaAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local MinervaBot = {}

function MinervaBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(MinervaBot, self)
	return self
end

function MinervaBot:State_Init()
	-- Zig and Zag
	local ability = MinervaAbility.Create(self, self.hero:GetAbility(0))
	self:RegisterAbility(ability)

	-- Heartstrike Arrow
	ability = TargetEnemyAbility.Create(self, self.hero:GetAbility(1), true)
	self:RegisterAbility(ability)

	-- Eviscerate
	ability = TargetEnemyAbility.Create(self, self.hero:GetAbility(3), false)
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

MinervaBot.Create(object)

