-- Custom logic for Ace Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

local WhirlingBladeAbility = {}

function WhirlingBladeAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	local num = self.owner:GetNumEnemyHeroes(self.ability:GetRange())
	return num ~= nil and num > 1
end

function WhirlingBladeAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(WhirlingBladeAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local AceBot = {}

function AceBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(AceBot, self)
	return self
end

function AceBot:State_Init()
	-- Whirling Blade
	local ability = WhirlingBladeAbility.Create(self, self.hero:GetAbility(0))
	self:RegisterAbility(ability)

	-- Staggering Leap
	ability = JumpToPositionAbility.Create(self, self.hero:GetAbility(1), false, false)
	self:RegisterAbility(ability)

	-- Undying Rage
	ability = SelfHealAbility.Create(self, self.hero:GetAbility(2))
	self:RegisterAbility(ability)

	-- The Axe
	ability = TargetEnemyAbility.Create(self, self.hero:GetAbility(3), false)
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

AceBot.Create(object)

