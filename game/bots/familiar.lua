-- Familiar ability classes

runfile "/bots/globals.lua"
runfile "/bots/ability.lua"

FamiliarAbilities = {}

-- Mystik

local MystikAbility = {}

function MystikAbility:Evaluate()
	if not self.owner:GetUseFamiliarAbilities() then
		return false
	end

	if not Ability.Evaluate(self) then
		return false
	end

	-- Only activate if you're low on mana
	if self.owner.hero:GetManaPercent() > 0.25 then
		return false
	end

	-- Only activate if there are 3 or more enemy heroes nearby (teamfight)
	if self.owner:GetNumEnemyHeroes(1500) < 2 then
		return false
	end

	return true
end

function MystikAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(MystikAbility, self)
	return self
end

FamiliarAbilities["Familiar_Mystik"] = MystikAbility

-- Pincer

local PincerAbility = {}

function PincerAbility:Evaluate()
	if not self.owner:GetUseFamiliarAbilities() then
		return false
	end

	if not Ability.Evaluate(self) then
		return false
	end

	if self.owner:CheckStunned() then
		return true
	else
		return false
	end

	--return self.owner:CheckStunned()
end

function PincerAbility:Execute()
	self.owner:ClearStunned()
	Ability.Execute(self)
end

function PincerAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(PincerAbility, self)
	return self
end

FamiliarAbilities["Familiar_Pincer"] = PincerAbility

-- Tortus

local TortusAbility = {}

function TortusAbility:Evaluate()
	if not self.owner:GetUseFamiliarAbilities() then
		return false
	end

	if not Ability.Evaluate(self) then
		return false
	end

	-- Only activate if you're low on health
	local health = self.owner.hero:GetHealthPercent()
	if health > 0.25 then
		return false
	elseif health < 0.05 then
		-- Use it regardless of situation if you're severely low on health
		return true
	end

	-- Only activate if there are 3 or more enemy heroes nearby (teamfight)
	if self.owner:GetNumEnemyHeroes(1500) < 2 then
		return false
	end

	return true
end

function TortusAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(TortusAbility, self)
	return self
end

FamiliarAbilities["Familiar_Tortus"] = TortusAbility

-- Topps

local ToppsAbility = {}

function ToppsAbility:Evaluate()
	if not self.owner:GetUseFamiliarAbilities() then
		return false
	end

	if not Ability.Evaluate(self) then
		return false
	end

	-- Only activate if there are 3 or more enemy heroes nearby
	if self.owner:GetNumEnemyHeroes(500) < 2 then
		return false
	end

	return true
end

function ToppsAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(ToppsAbility, self)
	return self
end

FamiliarAbilities["Familiar_Topps"] = ToppsAbility

-- Bounder

local BounderAbility = {}

function BounderAbility:Evaluate()
	if not self.owner:GetUseFamiliarAbilities() then
		return false
	end

	if self.owner:HasBehaviorFlag(BF_TRYHARD) or not self.owner:HasBehaviorFlag(BF_NEED_HEAL) or not Ability.Evaluate(self) then
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

function BounderAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability, false, false)
	ShallowCopy(BounderAbility, self)
	return self
end

FamiliarAbilities["Familiar_Bounder"] = BounderAbility

-- Luster

local LusterAbility = {}

function LusterAbility:Evaluate()
	if not self.owner:GetUseFamiliarAbilities() then
		return false
	end

	if not Ability.Evaluate(self) then
		return false
	end

	self.target = self.owner:GetAttackTarget()
	if self.target == nil then
		return false
	end

	if self.target:IsHero() then
		return false
	end

	if self.owner.teambot:UnitDistance(self.target, self.owner.hero:GetPosition()) > self.ability:GetRange() then
		return false
	end

	return true
end

function LusterAbility.Create(owner, ability)
	local self = TargetEnemyAbility.Create(owner, ability)
	ShallowCopy(LusterAbility, self)
	return self
end

FamiliarAbilities["Familiar_Luster"] = LusterAbility

-- Razer

local RazerAbility = {}

function RazerAbility:Evaluate()
	if not self.owner:GetUseFamiliarAbilities() then
		return false
	end

	if self.owner:HasBehaviorFlag(BF_TRYHARD) or not self.owner:HasBehaviorFlag(BF_NEED_HEAL) or not Ability.Evaluate(self) then
		return false
	end

	return self.owner.hero:GetHealthPercent() < 0.3
end

function RazerAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(RazerAbility, self)
	return self
end

FamiliarAbilities["Familiar_Razer"] = RazerAbility

