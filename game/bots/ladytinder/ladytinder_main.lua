-- Custom logic for Lady Tinder Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

local TinderTouchAbility = {}

function TinderTouchAbility:Evaluate()
	if TargetAllyAbility.Evaluate(self) then
		return true
	end

    return TargetEnemyAbility.Evaluate(self)
end

function TinderTouchAbility.Create(owner, ability)
    local self = TargetEnemyAbility.Create(owner, ability)
    ShallowCopy(TinderTouchAbility, self)

    self.settings.doTargetCreeps = true
    self.settings.doTargetBosses = true
    self.settings.favorCC = false

    return self
end

local SummonAbility = {}

function SummonAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	local target = self.owner:GetAttackTarget()
	if ((target ~= nil) and (target:IsNeutralBoss())) then
		self.targetPos = self.owner.teambot:GetLastSeenPosition(target)
	else
		self.targetPos = self.owner:FindSummonPosition(self.ability:GetRange())
	end

	return (self.targetPos ~= nil)
end

function SummonAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability)
	ShallowCopy(SummonAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local LadyTinderBot = {}

function LadyTinderBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(LadyTinderBot, self)
	return self
end

function LadyTinderBot:State_Init()
    local abilityQ = TargetPositionAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = TinderTouchAbility.Create(self, self.hero:GetAbility(1))
    local abilityE = ShieldAbility.Create(self, self.hero:GetAbility(2))
    local abilityR = SummonAbility.Create(self, self.hero:GetAbility(3))

    abilityQ.settings.needClearPath = true

	self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityE)
    self:RegisterAbility(abilityR)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

LadyTinderBot.Create(object)

