-- Custom logic for Bastion Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_BASTION_CHOSEN = BF_USER1

-- Custom Abilities

-- Q --
local BreathAbility = {}

function BreathAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    local target = self.owner:GetAttackTarget()
    if target == nil then
        return false
    end

    if target:IsCreep() then
        self.targetPos = self.owner.teambot:GetCenterOfCreeps(target, 200, 2)
    else
        self.targetPos = self.owner.teambot:GetLastSeenPosition(target)
    end

    if self.targetPos == nil or Vector2.Distance(self.targetPos, self.owner.hero:GetPosition()) > self.ability:GetRange() then
        return false
    end

    return true
end

function BreathAbility.Create(owner, ability)
    local self = TargetPositionAbility.Create(owner, ability)
    ShallowCopy(BreathAbility, self)

    self.settings.doTargetCreeps = true
    self.settings.doTargetBosses = true

    return self
end

-- W --
local RammingSpeedAbility = {}

function RammingSpeedAbility.Create(owner, ability)
    local self = JumpToPositionAbility.Create(owner, ability)
    ShallowCopy(RammingSpeedAbility, self)

    self.settings.doForceMaxRange = true

    return self
end

-- E --
local GlowingBracersAbility = {}

function GlowingBracersAbility:Execute()
    Ability.Execute(self)
end

function GlowingBracersAbility.Create(owner, ability)
    local self = ShieldAbility.Create(owner, ability)
    ShallowCopy(GlowingBracersAbility, self)

    return self
end

-- R --
local ChosenAbility = {}

function ChosenAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    if self.owner:HasBehaviorFlag(BF_RETREAT) or self.owner:HasBehaviorFlag(BF_NEED_HEAL) then
        return false
    end

    local _, enemies = self.owner:CheckEngagement(1500)
    if (enemies == nil) or (enemies < 2) then
        return false
    end

    return true
end

function ChosenAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(ChosenAbility, self)
    return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local BastionBot = {}

function BastionBot.Create(object)
    local self = Bot.Create(object)
    ShallowCopy(BastionBot, self)
    return self
end

function BastionBot:State_Init()
    local abilityQ = BreathAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = RammingSpeedAbility.Create(self, self.hero:GetAbility(1))
    local abilityE = GlowingBracersAbility.Create(self, self.hero:GetAbility(2))
    local abilityR = ChosenAbility.Create(self, self.hero:GetAbility(3))

    abilityQ.settings.abilityManaSaver = abilityR
    abilityW.settings.abilityManaSaver = abilityR

    self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityE)
    self:RegisterAbility(abilityR)

    Bot.State_Init(self)
end

function BastionBot:UpdateBehaviorFlags()
    if self.hero:HasState("State_Bastion_Ability4_Buildup") or self.hero:HasState("State_Bastion_Ability4_Immolation") then
        self:SetBehaviorFlag(BF_BASTION_CHOSEN)
    else
        self:ClearBehaviorFlag(BF_BASTION_CHOSEN)
    end

    Bot.UpdateBehaviorFlags(self)

    if self:HasBehaviorFlag(BF_BASTION_CHOSEN) then
        self:SetBehaviorFlag(BF_TRYHARD)
    else
        self:ClearBehaviorFlag(BF_TRYHARD)
    end
end

-- End Custom Behavior Tree Functions

BastionBot.Create(object)

