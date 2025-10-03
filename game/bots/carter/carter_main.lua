-- Custom logic for Carter Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

local RingAbility = {}

function RingAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	return (self.owner:GetNumEnemyHeroes(2 * self.ability:GetRange()) > 1) or (self.owner:GetNumNeutralBosses(2 * self.ability:GetRange()) > 0)
end

function RingAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability, true)
	ShallowCopy(RingAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local CarterBot = {}

function CarterBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(CarterBot, self)
	return self
end

function CarterBot:State_Init()
    local ability

    -- Firecrackers
	ability = RingAbility.Create(self, self.hero:GetAbility(2))
	self:RegisterAbility(ability)

	-- Yak Attack
	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(1), true, true, false, true)
	self:RegisterAbility(ability)

    -- Rocket Barrage
	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(0), true, true, true, true)
	self:RegisterAbility(ability)

	-- Grand Finale
	ability = TargetEnemyAbility.Create(self, self.hero:GetAbility(3), false, false, true)
	self:RegisterAbility(ability)

	Bot.State_Init(self)

	self.evadeRadius = 750
end

function CarterBot:CalculateThreatLevel(pos)
	return Bot.CalculateThreatLevel(self, pos) + 0.2 -- Nudge threat slightly
end

-- End Custom Behavior Tree Functions

CarterBot.Create(object)

