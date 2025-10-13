-- Custom logic for HARROWER Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_HARROWER_MELEE = BF_USER1
local BF_HARROWER_ATKBUFF = BF_USER2

-- Custom Abilities

local LeapAttackAbility = {}

function LeapAttackAbility.Create(owner, ability)
    local self = JumpToPositionAbility.Create(owner, ability)
    ShallowCopy(LeapAttackAbility, self)

    self.settings.doTargetBosses = true
    self.settings.doForceMaxRange = true

    return self
end

--Spirit Wolf

local SpiritWolfAbility = {}

function SpiritWolfAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	if (self.owner:GetNumEnemyHeroes(self.ability:GetRange()) <= 0) then
		return false
	end

	local target = self.owner:GetAttackTarget()
	if (target == nil) then
		return false
	end

	return target:IsHero()
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
		return (self.owner:GetNumEnemyHeroes(300) < 1)
	else
		if (self.owner:GetNumEnemyHeroes(300) > 0) or (self.owner:GetNumNeutralBosses(300) > 0) or (threat > 1.25) then
			return true
		end
	end

    return false
end

function ShapeshiftAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(ShapeshiftAbility, self)

    self.settings.hasAggro = false

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

