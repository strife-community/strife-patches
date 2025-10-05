-- Custom logic for Malady Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

local GhostlyVeilAbility = {}

function GhostlyVeilAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	self.v1, self.v2 = self.owner:FindWallVectors(self.ability:GetRange())
	return self.v1 ~= nil
end

function GhostlyVeilAbility.Create(owner, ability)
    local ability_settings = GetSettingsCopy(VectorAbility)
    ability_settings.hasAggro = false

	local self = VectorAbility.Create(owner, ability, ability_settings)
	ShallowCopy(GhostlyVeilAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local MaladyBot = {}

function MaladyBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(MaladyBot, self)
	return self
end

function MaladyBot:State_Init()
    local ability_settings

	-- Graveyard
    ability_settings = GetSettingsCopy(TargetPositionAbility)
    ability_settings.doTargetCreeps = true
    ability_settings.doTargetBosses = true

	local ability = TargetPositionAbility.Create(self, self.hero:GetAbility(0), ability_settings)
	self:RegisterAbility(ability)

	-- Exorcise
    ability_settings = GetSettingsCopy(TargetPositionAbility)
    ability_settings.doTargetCreeps = true
    ability_settings.doTargetBosses = true

	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(1), ability_settings)
	self:RegisterAbility(ability)

	-- Ghostly veil
	ability = GhostlyVeilAbility.Create(self, self.hero:GetAbility(2))
	self:RegisterAbility(ability)

	-- Silver bullet
    ability_settings = GetSettingsCopy(TargetEnemyAbility)

	ability = TargetEnemyAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

MaladyBot.Create(object)

