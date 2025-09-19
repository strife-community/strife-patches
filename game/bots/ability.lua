-- Common hero ability classes

runfile "/bots/globals.lua"

-- Base ability class

Ability = {}

function Ability:Evaluate()
	return self.ability:CanActivate()
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

function TargetPositionAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	local target = self.owner:GetAttackTarget()
	if target == nil then
		return false
	end

	if (self.owner:HasBehaviorFlag(BF_FARM) or not self.targetCreeps) and target:IsCreep() then
		return false
	end

	if self.needClearPath and not self.owner:CheckClearPath(target, false) then
		return false
	end

	self.targetPos = self.owner.teambot:GetLastSeenPosition(target)
	if self.targetPos == nil or Vector2.Distance(self.targetPos, self.owner.hero:GetPosition()) > self.ability:GetRange() then
		return false
	end

	return true
end

function TargetPositionAbility:Execute()
	self.owner:OrderAbilityPosition(self.ability, self.targetPos)
end

function TargetPositionAbility.Create(owner, ability, targetCreeps, needClearPath)
	local self = Ability.Create(owner, ability)
	ShallowCopy(TargetPositionAbility, self)
	if owner:GetAbilitiesCanTargetCreeps() then
		self.targetCreeps = targetCreeps
	else
		self.targetCreeps = false
	end
	self.needClearPath = needClearPath
	return self
end

-- Jump To Position ability

JumpToPositionAbility = {}

function JumpToPositionAbility:Evaluate()
	if not self.owner:NeedToRetreat() and self.owner.hero:GetHealthPercent() < 0.7 then
		return false
	end

	if not TargetPositionAbility.Evaluate(self) then
		return false
	end

	if self.owner:CalculateThreatLevel(self.targetPos) > 0.9 then
		return false
	end

	return true
end

function JumpToPositionAbility.Create(owner, ability, targetCreeps, needClearPath)
	local self = TargetPositionAbility.Create(owner, ability, targetCreeps, needClearPath)
	ShallowCopy(JumpToPositionAbility, self)
	return self
end

-- Entity targetting ability

TargetEnemyAbility = {}

function TargetEnemyAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	self.target = self.owner:GetAttackTarget()
	if self.target == nil then
		return false
	end

	if (self.owner:HasBehaviorFlag(BF_FARM) or not self.targetCreeps) and self.target:IsCreep() then
		return false
	end

	if self.owner.teambot:UnitDistance(self.target, self.owner.hero:GetPosition()) > self.ability:GetRange() then
		return false
	end

	return true
end

function TargetEnemyAbility:Execute()
--	Echo(self.owner:GetName())
	self.owner:OrderAbilityEntity(self.ability, self.target)
end

function TargetEnemyAbility.Create(owner, ability, targetCreeps)
	local self = Ability.Create(owner, ability)
	ShallowCopy(TargetEnemyAbility, self)
	if owner:GetAbilitiesCanTargetCreeps() then
		self.targetCreeps = targetCreeps
	else
		self.targetCreeps = false
	end
	return self
end

-- Ally targetting ability

TargetAllyAbility = {}

function TargetAllyAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	self.target = self.owner:FindHealTarget(self.ability:GetRange(), 0.8, self.favorCC)
	return self.target ~= nil
end

function TargetAllyAbility.Create(owner, ability, favorCC)
	local self = TargetEnemyAbility.Create(owner, ability, false)
	ShallowCopy(TargetAllyAbility, self)
	self.favorCC = favorCC
	return self
end

-- Self healing ability

SelfHealAbility = {}

function SelfHealAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	return self.owner.hero:GetHealthPercent() < 0.6
end

function SelfHealAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(SelfHealAbility, self)
	return self
end

-- Escape ability

EscapeAbility = {}

function EscapeAbility:Evaluate()
	if self.owner:HasBehaviorFlag(BF_CALM) or self.owner:HasBehaviorFlag(BF_TRYHARD) or not self.owner:HasBehaviorFlag(BF_NEED_HEAL) or not Ability.Evaluate(self) then
		return false
	end

	local escapePos = self.owner:GetEscapePosition(self.ability:GetRange())
	if escapePos == nil then
		return false
	end

	if self.owner:CalculateThreatLevel(escapePos) < self.owner.threat then
		self.targetPos = escapePos
		return true
	end

	return false
end

function EscapeAbility.Create(owner, ability, targetCreeps)
	local self = TargetPositionAbility.Create(owner, ability, targetCreeps)
	ShallowCopy(EscapeAbility, self)
	return self
end

-- Vector ability

VectorAbility = {}

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
	return self
end

-- Home Teleport Ability

HomeTeleportAbility = {}

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
	return self
end

