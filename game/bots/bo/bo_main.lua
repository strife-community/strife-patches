-- Custom logic for Bo Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_BO_ENRAGED = BF_USER1

-- Custom Abilities

CHARGE_RANGE_SQ = 300 * 300

local EnrageAbility = {}

function EnrageAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	local target = self.owner:GetAttackTarget()
	if target == nil or not target:IsHero() then
		return false
	end

	local pos = self.owner.teambot:GetLastSeenPosition(target, true)
	if pos == nil then
		return false
	end

	if Vector2.DistanceSq(self.owner.hero:GetPosition(), pos) < CHARGE_RANGE_SQ then
		return false
	end

	return true
end

function EnrageAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(EnrageAbility, self)
	return self
end

--

local WellAbility = {}

function WellAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	local target = self.owner:FindHealTarget(self.ability:GetRange(), 0.5)
	if target ~= nil then
		self.targetPos = target:GetPosition()
		return true
	end

	return false
end

function WellAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(WellAbility, self)

    self.settings.hasAggro = false
    
    return self
end

--

local RamAbility = {}

function RamAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	self.targetPos = self.owner:FindRamTarget(self.ability:GetRange(), 200)
	if self.targetPos == nil then
		return false
	end

	return true
end

function RamAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability)
	ShallowCopy(RamAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local BoBot = {}

function BoBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(BoBot, self)
	return self
end

function BoBot:State_Init()
    local abilityQ = TargetPositionAbility.Create(self, self.hero:GetAbility(0))
    self.enrageAbility = EnrageAbility.Create(self, self.hero:GetAbility(1))
    local abilityE = WellAbility.Create(self, self.hero:GetAbility(2))
    local abilityR = RamAbility.Create(self, self.hero:GetAbility(3))

    abilityQ.settings.doTargetCreeps = true
    abilityQ.settings.doTargetBosses = true

    self:RegisterAbility(abilityQ)
    -- DO NOT REGISTER W ABILITY - Checked manually on attack
    self:RegisterAbility(abilityE)
    self:RegisterAbility(abilityR)

	Bot.State_Init(self)
end

function BoBot:UpdateBehaviorFlags()
	if self.hero:HasState("State_Bo_Ability2") then
		self:SetBehaviorFlag(BF_BO_ENRAGED)
	else
		self:ClearBehaviorFlag(BF_BO_ENRAGED)
	end

	Bot.UpdateBehaviorFlags(self)

	if self:HasBehaviorFlag(BF_BO_ENRAGED) then
		self:SetBehaviorFlag(BF_TRYHARD)
	end
end

function BoBot:State_AttackTarget()
	if self.enrageAbility:Evaluate() then
		self.enrageAbility:Execute()
	end

	Bot.State_AttackTarget(self)
end

-- End Custom Behavior Tree Functions

BoBot.Create(object)

