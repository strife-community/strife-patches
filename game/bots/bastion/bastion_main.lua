-- Custom logic for Bastion Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_BASTION_CHOSEN = BF_USER1

-- Custom Abilities

BreathAbility = {}

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
	return self
end

--

local RammingSpeedAbility = {}

function RammingSpeedAbility:Evaluate()
	if EscapeAbility.Evaluate(self) then
		return true
	end

	if not TargetPositionAbility.Evaluate(self) then
		return false
	end

	-- Push target position out to the maximum ability range
	local heroPos = self.owner.hero:GetPosition()
	local dir = Vector2.Normalize(self.targetPos - heroPos)
	self.targetPos = heroPos + dir * self.ability:GetRange()

	local threat = self.owner:CalculateThreatLevel(self.targetPos)
	if self.owner.hero:GetHealthPercent() > 0.4 and threat < 1.2 then
		return true
	end

	return false
end

function RammingSpeedAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability, false, false)
	ShallowCopy(RammingSpeedAbility, self)
	return self
end

--

local GlowingBracersAbility = {}

function GlowingBracersAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	if self.owner:GetNumEnemyHeroes(1000) < 2 then
		return false
	end

	if self.owner:GetNumAllyHeroes(1000) < 2 then
		return false
	end

	self.target = self.owner:FindHealTarget(self.ability:GetRange(), 0.8)
	return self.target ~= nil
end

function GlowingBracersAbility:Execute()
	self.owner:OrderAbility(self.ability)
end

function GlowingBracersAbility.Create(owner, ability)
	local self = TargetEnemyAbility.Create(owner, ability, false)
	ShallowCopy(GlowingBracersAbility, self)
	return self
end

--

local ChosenAbility = {}

function ChosenAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	if self.owner.threat > 1.2 then
		return false
	end

	local allies, enemies = self.owner:CheckEngagement(2000)
	if allies == nil or allies < 2 or enemies < 2 then
		return false
	end

	return true
end

function ChosenAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability, false)
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
	-- Breath of the Oracles
	local ability = BreathAbility.Create(self, self.hero:GetAbility(0))
	self:RegisterAbility(ability)

	-- Ramming Speed
	ability = RammingSpeedAbility.Create(self, self.hero:GetAbility(1))
	self:RegisterAbility(ability)

	-- Glowing Bracers
	ability = GlowingBracersAbility.Create(self, self.hero:GetAbility(2))
	self:RegisterAbility(ability)

	-- Chosen
	ability = ChosenAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)

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
	end
end

-- End Custom Behavior Tree Functions

BastionBot.Create(object)

