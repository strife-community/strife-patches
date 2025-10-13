-- Custom logic for Ace Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local AVALANCHE_MIN_DISTANCE_TO_TARGET = 200

-- Custom Abilities

-- Q --
local WhirlingBladeAbility = {}

function WhirlingBladeAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    local num = self.owner:GetNumEnemyHeroes(self.ability:GetTargetRadius())
    local num_Boss = self.owner:GetNumNeutralBosses(self.ability:GetTargetRadius())

    return ((num + num_Boss) > 0)
end

function WhirlingBladeAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(WhirlingBladeAbility, self)
    return self
end

-- W --
local AvalancheAbility = {}

function AvalancheAbility:Evaluate()
    if not JumpToPositionAbility.Evaluate(self) then
        return false
    end

    local distance_to_target = Vector2.Distance(self.targetPos, self.owner.hero:GetPosition())
    if (distance_to_target < AVALANCHE_MIN_DISTANCE_TO_TARGET) then
        return false
    end

    return true
end

function AvalancheAbility.Create(owner, ability)
    local self = JumpToPositionAbility.Create(owner, ability)
    ShallowCopy(AvalancheAbility, self)

    self.settings.doAddRadiusToRange = true

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
    local abilityQ = WhirlingBladeAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = AvalancheAbility.Create(self, self.hero:GetAbility(1))
    local abilityE = SelfShieldAbility.Create(self, self.hero:GetAbility(2))
    local abilityR = TargetEnemyAbility.Create(self, self.hero:GetAbility(3))

    self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityE)
    self:RegisterAbility(abilityR)

    Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

AceBot.Create(object)

