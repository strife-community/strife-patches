-- Common hero ability classes

runfile "/bots/globals.lua"

-- Base ability class

Ability = {}
Ability.settings = {}
Ability.settings.hasAggro = true            -- Determines if ability is agressive (to determine if it would aggro towers)
Ability.settings.abilityManaSaver = nill    -- Ability to save mana for if it is ready

function Ability:Evaluate()
    if not self.ability:CanActivate() then
        return false
    end

    if (self.settings.hasAggro) then
        local selfPosition = self.owner.hero:GetPosition()
        if self.owner:IsPositionUnderEnemyTower(self.owner.hero:GetPosition()) then
            return false
        end
    end

    if (self.settings.abilityManaSaver ~= nil) then
        if (
            self.settings.abilityManaSaver.ability:IsReady() and 
            (self.owner.hero:GetMana() < (self.ability:GetManaCost() + self.settings.abilityManaSaver.ability:GetManaCost())) and
            (not self.owner:HasBehaviorFlag(BF_NEED_HEAL))
        ) then
            return false
        end
    end

    return true
end

function Ability:Execute()
    self.owner:OrderAbility(self.ability)
end

function Ability.Create(owner, ability)
    local self = ShallowCopy(Ability)

    self.ability = ability
    self.owner = owner

    return self
end

-- Position targetting ability

TargetPositionAbility = {}
TargetPositionAbility.settings = ShallowCopy(Ability.settings)
TargetPositionAbility.settings.doTargetCreeps =     false   -- Determines if ability would be used for pushing lane
TargetPositionAbility.settings.needClearPath =      false   -- Determines if ability requires check if no creeps in line
TargetPositionAbility.settings.doTargetBosses =     false   -- Determines if bosses should be targeted by the ability
TargetPositionAbility.settings.doAddRadiusToRange = false   -- Determines if radius is supposed to be added to ability range in calculations

function TargetPositionAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    if (self.settings.doTargetBosses and (self.owner.state == "Root:Match:TeamCombat:AttackTeamTarget")) then
        local boss_target = self.owner.teamTarget.unit
        if (boss_target:IsNeutralBoss()) then
            self.targetPos = self.owner.teambot:GetLastSeenPosition(boss_target)
            return (self.targetPos ~= nil)
        end
    end

    local target = self.owner:GetAttackTarget()
    if (target == nil) or (target:IsInvulnerable()) then
        return false
    end

    if (self.owner:HasBehaviorFlag(BF_FARM) or not self.settings.doTargetCreeps) and target:IsCreep() or (self.owner.hero:GetManaPercent() < 0.5) then
        return false
    end

    if self.settings.needClearPath and not self.owner:CheckClearPath(target, false) then
        return false
    end

    self.targetPos = self.owner.teambot:GetLastSeenPosition(target)
    local ability_range = self.ability:GetRange()
    if (self.settings.doAddRadiusToRange) then
        ability_range = ability_range + self.ability:GetTargetRadius()
    end

    if ((self.targetPos == nil) or (Vector2.Distance(self.targetPos, self.owner.hero:GetPosition()) > ability_range)) then
        return false
    end

    return true
end

function TargetPositionAbility:Execute()
    self.owner:OrderAbilityPosition(self.ability, self.targetPos)
end

function TargetPositionAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(TargetPositionAbility, self)

    if (settings ~= nil) then
        self.settings = settings
    end

    return self
end

-- Jump To Position ability

JumpToPositionAbility = {}
JumpToPositionAbility.settings = ShallowCopy(TargetPositionAbility.settings)
JumpToPositionAbility.settings.isEscapeAbility =    true   -- Determines if ability should be used for escape
JumpToPositionAbility.settings.doForceMaxRange =    false  -- Determines if ability should always use maximum range instead of target position
-- Inherited. Jump abilities should usually check target position for aggro, not current position 
JumpToPositionAbility.settings.hasAggro = false

function JumpToPositionAbility:EvaluateEscape()
    if (not Ability.Evaluate(self)) or (not self.owner:HasBehaviorFlag(BF_NEED_HEAL)) then
        return false
    end

    self.targetPos = self.owner:GetEscapePosition(self.ability:GetRange())
    if self.targetPos == nil then
        return false
    end

    if self.owner:CalculateThreatLevel(self.targetPos) >= self.owner.threat then
        return false
    end

    return true
end

function JumpToPositionAbility:Evaluate()
    if (self.settings.isEscapeAbility) then
        if (self:EvaluateEscape()) then
            return true
        end
    end

    if (self.owner:NeedToRetreat()) then
        return false
    end

    if not TargetPositionAbility.Evaluate(self) then
        return false
    end

    if (self.settings.doForceMaxRange) then
        local heroPos = self.owner.hero:GetPosition()
	    local dir = Vector2.Normalize(self.targetPos - heroPos)
	    self.targetPos = heroPos + dir * self.ability:GetRange()
    end

    if self.owner.teambot:PositionInTeamHazard(self.targetPos) then
		return false
	end

    if (self.owner:HasBehaviorFlag(BF_TRYHARD)) then
        return true
    end

    if self.owner:CalculateThreatLevel(self.targetPos) > 0.9 then
        return false
    end

    if (self.owner:IsPositionUnderEnemyTower(self.targetPos)) then
		return false
	end

    return true
end

function JumpToPositionAbility:Execute()
    TargetPositionAbility.Execute(self)
end

function JumpToPositionAbility.Create(owner, ability)
    local self = TargetPositionAbility.Create(owner, ability)
    ShallowCopy(JumpToPositionAbility, self)
    return self
end

-- Entity targetting ability

TargetEnemyAbility = {}
TargetEnemyAbility.settings = ShallowCopy(Ability.settings)
TargetEnemyAbility.settings.doTargetCreeps =    false   -- Determines if ability would be used for pushing lane
TargetEnemyAbility.settings.doTargetBosses =    false   -- Determines if bosses should be targeted by the ability

function TargetEnemyAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    if (self.settings.doTargetBosses and (self.owner.state == "Root:Match:TeamCombat:AttackTeamTarget")) then
        local boss_target = self.owner.teamTarget.unit
        if (boss_target:IsNeutralBoss()) then
            self.target = boss_target
            return true
        end
    end

    self.target = self.owner:GetAttackTarget()
    if self.target == nil then
        return false
    end

    if ((self.owner:HasBehaviorFlag(BF_FARM) or not self.settings.doTargetCreeps) and self.target:IsCreep()) or (self.owner.hero:GetManaPercent() < 0.5) then
        return false
    end

    if self.owner.teambot:UnitDistance(self.target, self.owner.hero:GetPosition()) > self.ability:GetRange() then
        return false
    end

    return true
end

function TargetEnemyAbility:Execute()
    self.owner:OrderAbilityEntity(self.ability, self.target)
end

function TargetEnemyAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(TargetEnemyAbility, self)

    if (settings ~= nil) then
        self.settings = settings
    end

    return self
end

-- Ally targetting ability

TargetAllyAbility = {}
TargetAllyAbility.settings = ShallowCopy(Ability.settings)
TargetAllyAbility.settings.favorCC =    false   -- Determines if hero with CC state should have higher priority
TargetAllyAbility.settings.hasAggro =   false   -- Inherited. Ally abilities are unlikely to be aggressive

function TargetAllyAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    self.target = self.owner:FindHealTarget(self.ability:GetRange(), 0.8, self.settings.favorCC)
    return self.target ~= nil
end

function TargetAllyAbility:Execute()
    self.owner:OrderAbilityEntity(self.ability, self.target)
end

function TargetAllyAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(TargetAllyAbility, self)

    if (settings ~= nil) then
        self.settings = settings
    end

    return self
end

-- Shield target ability

ShieldAbility = {}
ShieldAbility.settings = ShallowCopy(Ability.settings) -- Only has inherited settings
ShieldAbility.settings.hasAggro =   false   -- Inherited. Ally abilities are unlikely to be aggressive

function ShieldAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	self.target = self.owner:FindShieldTarget(self.ability:GetRange(), 0.8)
	return self.target ~= nil
end

function ShieldAbility:Execute()
    self.owner:OrderAbilityEntity(self.ability, self.target)
end

function ShieldAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(ShieldAbility, self)

    if (settings ~= nil) then
        self.settings = settings
    end

	return self
end

-- Self shield ability

SelfShieldAbility = {}
SelfShieldAbility.settings = ShallowCopy(Ability.settings) -- Only has inherited settings
SelfShieldAbility.settings.hasAggro =   false   -- Inherited. Shield abilities are unlikely to be aggressive

function SelfShieldAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    local num = self.owner:GetNumAttackers()
    if num > 2 then
        return true
    elseif num > 0 and self.owner.hero:GetHealthPercent() < 0.6 then
        return true
    end

    return false
end

function SelfShieldAbility:Execute()
    self.owner:OrderAbility(self.ability)
end

function SelfShieldAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(SelfShieldAbility, self)

    if (settings ~= nil) then
        self.settings = settings
    end

    return self
end

-- Self healing ability

SelfHealAbility = {}
SelfHealAbility.settings = ShallowCopy(Ability.settings) -- Only has inherited settings
SelfHealAbility.settings.hasAggro = false   -- Inherited. Shield abilities are unlikely to be aggressive

function SelfHealAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    return self.owner.hero:GetHealthPercent() < 0.6
end

function SelfHealAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(SelfHealAbility, self)

    if (settings ~= nil) then
        self.settings = settings
    end

    return self
end

-- Vector ability

VectorAbility = {}
VectorAbility.settings = ShallowCopy(Ability.settings) -- Only has inherited settings

function VectorAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    self.v1, self.v2 = self.owner:GetEnemyLineVectors(self.ability:GetRange(), 2)
    return self.v1 ~= nil
end

function VectorAbility:Execute()
    self.owner:OrderAbilityVector(self.ability, self.v1, self.v2)
end

function VectorAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(VectorAbility, self)

    if (settings ~= nil) then
        self.settings = settings
    end

    return self
end

-- Home Teleport Ability

HomeTeleportAbility = {}
HomeTeleportAbility.settings = ShallowCopy(Ability.settings) -- Only has inherited settings
HomeTeleportAbility.settings.hasAggro = false   -- Inherited. Unlikely to be aggressive

function HomeTeleportAbility:Evaluate()
    if not self.owner:HasBehaviorFlag(BF_CHECK_TELEPORT) then
        return false
    end

    if not Ability.Evaluate(self) then
        return false
    end

    local targetPos = self.owner:GetMoveTarget()
    if targetPos == nil then
        return false
    end

    if not self.owner:HasBehaviorFlag(BF_CALM) or not self.owner:CanTeleport(2000) then
        return false
    end

    local normalTime = self.owner:GetPathTravelTime(self.owner.hero:GetPosition(), targetPos)
    local teleportTime = self.owner:GetPathTravelTime(self.owner.well:GetPosition(), targetPos) + 8
    if normalTime > teleportTime then
        return true
    else
        self.owner:ClearTeleport()
    end
end

function HomeTeleportAbility:Execute()
    self.owner:Teleport("State_HomecomingStone_Source_Base")
    Ability.Execute(self)
end

function HomeTeleportAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(HomeTeleportAbility, self)

    if (settings ~= nil) then
        self.settings = settings
    end

    return self
end

