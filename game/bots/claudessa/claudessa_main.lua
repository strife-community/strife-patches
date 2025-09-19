-- Custom logic for Claudessa Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_CLAUDESSA_SCORCH = BF_USER1

-- Custom Behavior Tree Functions

local ClaudessaBot = {}

function ClaudessaBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(ClaudessaBot, self)
	return self
end

--

ShieldAbility = {}

function ShieldAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	self.target = self.owner:FindShieldTarget(self.ability:GetRange(), 0.8)
	return self.target ~= nil
end

function ShieldAbility.Create(owner, ability)
	local self = TargetAllyAbility.Create(owner, ability, true)
	ShallowCopy(ShieldAbility, self)
	return self
end

--

local ScorchAbility = {}

function ScorchAbility:Evaluate()
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

function ScorchAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability, false)
	ShallowCopy(ScorchAbility, self)
	return self
end

--

function ClaudessaBot:State_Init()
	-- Dragon Knockback
	local ability = TargetPositionAbility.Create(self, self.hero:GetAbility(0), true)
	self:RegisterAbility(ability)

	-- Heal+Shield
	ability = ShieldAbility.Create(self, self.hero:GetAbility(1))
	self:RegisterAbility(ability)

	-- Ground Scorch
	ability = ScorchAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)

	Bot.State_Init(self) 
end

function ClaudessaBot:UpdateBehaviorFlags()
	if self.hero:HasState("State_Claudessa_Ability4_Linger") then
		self:SetBehaviorFlag(BF_CLAUDESSA_SCORCH)
	else
		self:ClearBehaviorFlag(BF_CLAUDESSA_SCORCH)
	end

	Bot.UpdateBehaviorFlags(self)

	if self:HasBehaviorFlag(BF_CLAUDESSA_SCORCH) then
		self:SetBehaviorFlag(BF_TRYHARD)
	end
end

-- End Custom Behavior Tree Functions

ClaudessaBot.Create(object)

