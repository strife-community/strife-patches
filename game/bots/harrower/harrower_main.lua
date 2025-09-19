-- Custom logic for HARROWER Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_HARROWER_MELEE = BF_USER1
local BF_HARROWER_ATKBUFF = BF_USER2

-- Custom Abilities

local LeapAttackAbility = {}

function LeapAttackAbility:Evaluate()
	if EscapeAbility.Evaluate(self) then
		return true
	end

	if not TargetPositionAbility.Evaluate(self) then
		return false
	end

	if self.owner.hero:GetHealthPercent() < 0.6 then
		return false
	end

	if self.owner:HasBehaviorFlag(BF_TRYHARD) then
		return true
	end

	-- Push target position out to the maximum ability range
	local heroPos = self.owner.hero:GetPosition()
	local dir = Vector2.Normalize(self.targetPos - heroPos)
	self.targetPos = heroPos + dir * self.ability:GetRange()

	if self.owner.teambot:PositionInTeamHazard(self.targetPos) then
		return false
	end

	local threat = self.owner:CalculateThreatLevel(self.targetPos)
	if threat < 1.0 then
		return true
	end

	return false
end

function LeapAttackAbility:Execute()
	TargetPositionAbility.Execute(self)
end

function LeapAttackAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability, false, false)
	ShallowCopy(LeapAttackAbility, self)
	return self
end

--Spirit Wolf

local SpiritWolfAbility = {}

function SpiritWolfAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	return self.owner:GetNumEnemyHeroes(self.ability:GetRange()) > 0
end

function SpiritWolfAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(SpiritWolfAbility, self)
	return self
end

-- Shapeshift

local ShapeshiftAbility = {}

function ShapeshiftAbility:Evaluate()

	if not Ability.Evaluate(self) then
		return false
	end

	local threat = self.owner:CalculateThreatLevel(self.owner.hero:GetPosition())
	if self.owner:HasBehaviorFlag(BF_HARROWER_MELEE) then
		return self.owner:GetNumEnemyHeroes(300) < 1
	else
		if self.owner:GetNumEnemyHeroes(300) > 0 then
			return true
		elseif threat > 1.25 then
			return true
		else
			return false
		end
	end
end

function ShapeshiftAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(ShapeshiftAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local HarrowerBot = {}

function HarrowerBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(HarrowerBot, self)
	return self
end

function HarrowerBot:State_Init()
	-- Leap
	local ability = LeapAttackAbility.Create(self, self.hero:GetAbility(0))
	self:RegisterAbility(ability)

	-- Spirit Wolf
	ability = SpiritWolfAbility.Create(self, self.hero:GetAbility(1))
	self:RegisterAbility(ability)

	-- Shapeshift
	ability = ShapeshiftAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

function HarrowerBot:Choose_Match()
	if self:HasBehaviorFlag(BF_HARROWER_ATKBUFF) and self:UpdateAttackTarget(1500, 2000, self.threat) then
		return "AttackTarget"
	end

	return Bot.Choose_Match(self)
end

function HarrowerBot:UpdateBehaviorFlags()

	if self.hero:HasState("State_Harrower_Ability1_Buff") then
		self:SetBehaviorFlag(BF_HARROWER_ATKBUFF)
	else
		self:ClearBehaviorFlag(BF_HARROWER_ATKBUFF)
	end

	if self.hero:HasState("State_Harrower_Ability4") then
		self:SetBehaviorFlag(BF_HARROWER_MELEE)
	else
		self:ClearBehaviorFlag(BF_HARROWER_MELEE)
	end

	Bot.UpdateBehaviorFlags(self)
end

-- End Custom Behavior Tree Functions

HarrowerBot.Create(object)

