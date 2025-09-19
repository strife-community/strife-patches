-- Custom logic for HARROWER Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_GOKONG_ULT = BF_USER1
local BF_GOKONG_ULT_TWO = BF_USER2
local valueTrack = 0

SpinAbility = {}

function SpinAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	return self.owner:GetNumEnemyHeroes(self.ability:GetTargetRadius()-75) > 0
end

function SpinAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(SpinAbility, self)
	return self
end

BuffAbility = {}
function BuffAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	if self.owner.threat > 1.2 then
		return false
	end

	return self.owner:GetNumEnemyHeroes(600) > 0
end

function BuffAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(BuffAbility, self)
	return self
end

local MonkeyAbility = {}

function MonkeyAbility:Evaluate()

	if self.owner:HasBehaviorFlag(BF_GOKONG_ULT) then
		if self.owner:HasBehaviorFlag(BF_GOKONG_ULT_TWO) then
			if not TargetPositionAbility.Evaluate(self) then
				return false
			end

			local threat = self.owner:CalculateThreatLevel(self.targetPos)
			if threat < 1.2 then
				return true
			end
		end
	end

	if not self.owner:HasBehaviorFlag(BF_GOKONG_ULT) then
		if valueTrack == 0.0 then
			if self.owner:GetNumEnemyHeroes(2000) > 0 then
				if self.owner.hero:GetHealthPercent() < 0.6 then
					return false
				end

				if not Ability.Evaluate(self) then
					return false
				end

				valueTrack = 1
				return true
			end
		end
	end

	return false
	
end

function MonkeyAbility:Execute()
	if self.owner:HasBehaviorFlag(BF_GOKONG_ULT) then
		TargetPositionAbility.Execute(self)
	else
		Ability.Execute(self)
	end
end

function MonkeyAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(MonkeyAbility, self)
	return self
end

-- Custom Behavior Tree Functions

local GoKongBot = {}

function GoKongBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(GoKongBot, self)
	return self
end

function GoKongBot:State_Init()
	-- Leap
	local ability = SpinAbility.Create(self, self.hero:GetAbility(0))
	self:RegisterAbility(ability)

	-- Spirit Wolf
	ability = JumpToPositionAbility.Create(self, self.hero:GetAbility(1))
	self:RegisterAbility(ability)

	-- Shapeshift
	ability = BuffAbility.Create(self, self.hero:GetAbility(2))
	self:RegisterAbility(ability)

	-- Shapeshift
	ability = MonkeyAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

function GoKongBot:UpdateBehaviorFlags()

	if self.hero:HasState("State_GoKong_Ability4") then
		self:SetBehaviorFlag(BF_GOKONG_ULT)
	else
		self:ClearBehaviorFlag(BF_GOKONG_ULT)
		valueTrack = 0
	end

	if self.hero:HasState("State_GoKong_Ability4_Bot") then
		self:SetBehaviorFlag(BF_GOKONG_ULT_TWO)
		valueTrack = 1
	else
		self:ClearBehaviorFlag(BF_GOKONG_ULT_TWO)
	end

	Bot.UpdateBehaviorFlags(self)
end

-- End Custom Behavior Tree Functions

GoKongBot.Create(object)

