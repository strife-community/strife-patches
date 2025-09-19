-- Custom logic for Nikolai Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_NIKOLAI_BASH = BF_USER1

-- Custom Abilities

local BashAbility = {}

function BashAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	if self.owner.threat > 1.2 then
		return false
	end

	return self.owner:GetNumEnemyHeroes(300) > 0
end

function BashAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability, false)
	ShallowCopy(BashAbility, self)
	return self
end

--Gound Stomp

local StompAbility = {}

function StompAbility:Evaluate()
	if not TargetPositionAbility.Evaluate(self) then
		return false
	end

	return self.owner:GetNumEnemyHeroes(200) > 0
end

function StompAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability)
	ShallowCopy(StompAbility, self)
	return self
end

--Bolster

local BolsterAbility = {}

function BolsterAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	return self.owner:GetNumEnemyHeroes(self.ability:GetRange()) > 1 
end

function BolsterAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(BolsterAbility, self)
	return self
end

-- Body Slam

local BodySlamAbility = {}

function BodySlamAbility:Evaluate()

	if self.owner.threat > 1.3 then
		return false
	end

	local allies, enemies = self.owner:CheckEngagement(600)
	if enemies < 2 then
		return false
	end

	if TargetPositionAbility.Evaluate(self) then
		return true
	end
end

function BodySlamAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability)
	ShallowCopy(BodySlamAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local NikolaiBot = {}

function NikolaiBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(NikolaiBot, self)
	return self
end

function NikolaiBot:State_Init()
	-- Bash
	local ability = BashAbility.Create(self, self.hero:GetAbility(0))
	self:RegisterAbility(ability)

	-- Ground Slam
	ability = StompAbility.Create(self, self.hero:GetAbility(1))
	self:RegisterAbility(ability)

	-- Bolster
	ability = BolsterAbility.Create(self, self.hero:GetAbility(2))
	self:RegisterAbility(ability)

	-- Body Slam
	ability = BodySlamAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

function NikolaiBot:Choose_Match()
	if self:HasBehaviorFlag(BF_NIKOLAI_BASH) and self:UpdateAttackTarget(1500, 2000, self.threat) then
		return "AttackTarget"
	end

	return Bot.Choose_Match(self)
end

--

function NikolaiBot:UpdateBehaviorFlags()
	if self.hero:HasState("State_Nikolai_Ability1") or self.hero:HasState("State_Nikolai_Ability4") then
		self:SetBehaviorFlag(BF_NIKOLAI_BASH)
	else
		self:ClearBehaviorFlag(BF_NIKOLAI_BASH)
	end

	Bot.UpdateBehaviorFlags(self)

	if self:HasBehaviorFlag(BF_NIKOLAI_BASH) then
		self:SetBehaviorFlag(BF_TRYHARD)
	end
end

-- End Custom Behavior Tree Functions

NikolaiBot.Create(object)

