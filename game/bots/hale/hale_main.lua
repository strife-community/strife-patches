-- Custom logic for Hale Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local SWIFT_STRIKE_MIN_DISTANCE = 200

-- Custom Abilities

-- Q --
local SwiftStrikeAbility = {}

function SwiftStrikeAbility:Evaluate()
    if not JumpToPositionAbility.Evaluate(self) then
        return false
    end

    local distance_to_target = Vector2.Distance(self.targetPos, self.owner.hero:GetPosition())
    if (distance_to_target < SWIFT_STRIKE_MIN_DISTANCE) then
        return false
    end

    return true
end

function SwiftStrikeAbility.Create(owner, ability)
    local self = JumpToPositionAbility.Create(owner, ability)
    ShallowCopy(SwiftStrikeAbility, self)

    self.settings.doForceMaxRange = true

    return self
end

-- W --
local InertialSwordAbility = {}

function InertialSwordAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    local target = self.owner:GetAttackTarget()
    if target == nil then
        return false
    end

    if self.owner.teambot:UnitDistance(target, self.owner.hero:GetPosition()) > 500 then
        return false
    end

    return true
end

function InertialSwordAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(InertialSwordAbility, self)
    return self
end

-- E --
local SoulCaliburAbility = {}

function SoulCaliburAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    if self.owner.hero:GetHealthPercent() > 0.9 then
        return false
    end

    local target = self.owner:GetAttackTarget()
    if (target == nil) or (not target:IsValid()) or (not (target:IsHero() or target:IsNeutralBoss())) then
        return false
    end

    if (self.owner.teambot:UnitDistance(target, self.owner.hero:GetPosition()) > 500) then
        return false
    end

    return true
end

function SoulCaliburAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(SoulCaliburAbility, self)

    self.settings.hasAggro = false

    return self
end

-- R --
local EarthquakeAbility = {}

function EarthquakeAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    return self.owner:GetNumEnemyHeroes(self.ability:GetTargetRadius()) > 1
end

function EarthquakeAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(EarthquakeAbility, self)
    return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local HaleBot = {}

function HaleBot.Create(object)
    local self = Bot.Create(object)
    ShallowCopy(HaleBot, self)
    return self
end

function HaleBot:State_Init()
    local abilityQ = SwiftStrikeAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = InertialSwordAbility.Create(self, self.hero:GetAbility(1))
    local abilityE = SoulCaliburAbility.Create(self, self.hero:GetAbility(2))
    local abilityR = EarthquakeAbility.Create(self, self.hero:GetAbility(3))

    self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityE)
    self:RegisterAbility(abilityR)

    Bot.State_Init(self)
end

function HaleBot:UpdateBehaviorFlags()
    Bot.UpdateBehaviorFlags(self)

    if self.hero:HasState("State_Hale_Ability2") then
        self:SetBehaviorFlag(BF_TRYHARD)
    else
        self:ClearBehaviorFlag(BF_TRYHARD)
    end
end

-- End Custom Behavior Tree Functions

HaleBot.Create(object)

