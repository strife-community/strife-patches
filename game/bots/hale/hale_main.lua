-- Custom logic for Hale Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local SWIFT_STRIKE_MIN_DISTANCE = 200

-- Custom Abilities

local SwiftStrikeAbility = {}

function SwiftStrikeAbility:Evaluate()
    -- If we need to escape, ignore rest, evaluate
    if EscapeAbility.Evaluate(self) then
        return true
    end

    if not JumpToPositionAbility.Evaluate(self) then
		return false
	end

	local distance_to_target = Vector2.Distance(self.targetPos, self.owner.hero:GetPosition())
    if (distance_to_target < SWIFT_STRIKE_MIN_DISTANCE) then
        return false
    end

    return true
end

function SwiftStrikeAbility.Create(owner, ability)
    local self = JumpToPositionAbility.Create(owner, ability, false, false, false)
    ShallowCopy(SwiftStrikeAbility, self)
    return self
end

--
--[[
local SwiftStrikesAbility = {}

function SwiftStrikesAbility:Evaluate()
	if self.owner.hero:GetHealthPercent() < 0.7 then
		return false
	end

	if not TargetPositionAbility.Evaluate(self) then
		return false
	end

	local cone_condition = (self.owner:GetNumEnemyHeroesInCone(self.ability:GetRange(), 30) < 2)
	local target_high_hp_condition = true

	local target = self.owner:GetAttackTarget()
	if target ~= nil and target:IsValid() then
		target_high_hp_condition = (self.owner:GetAttackTarget().GetHealthPercent() > 0.4)
	end

	if (cone_condition and target_high_hp_condition) then
		return false
	end

	local heroPos = self.owner.hero:GetPosition()
	local dir = Vector2.Normalize(self.targetPos - heroPos)
	local targetPos = heroPos + dir * self.ability:GetRange()
	if self.owner:CalculateThreatLevel(targetPos) > 1.25 then
		return false
	end

	return true
end

function SwiftStrikesAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability, true, false, false)
	ShallowCopy(SwiftStrikesAbility, self)
	return self
end
]]
--

local InertialSwordAbility = {}

function InertialSwordAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

    -- If we need to escape, ignore rest, evaluate
    if EscapeAbility.Evaluate(self) then
        return true
    end

	local target = self.owner:GetAttackTarget()
	if target == nil then
		return false
	end

	if self.owner.teambot:UnitDistance(target, self.owner.hero:GetPosition()) > 500 then
		return false
	end

	return true
end

function InertialSwordAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(InertialSwordAbility, self)
	return self
end

--

local SoulCaliburAbility = {}

function SoulCaliburAbility:Evaluate()
	if self.owner.hero:GetHealthPercent() > 0.9 then
		return false
	end

	if not Ability.Evaluate(self) then
		return false
	end

	local target = self.owner:GetAttackTarget()
	if target == nil or not target:IsValid() then
		return false
	end

	if self.owner.teambot:UnitDistance(target, self.owner.hero:GetPosition()) > 500 then
		return false
	end

	return true
end

function SoulCaliburAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(SoulCaliburAbility, self)
	return self
end

--

local EarthquakeAbility = {}

function EarthquakeAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	return self.owner:GetNumEnemyHeroes(self.ability:GetTargetRadius()) > 1
end

function EarthquakeAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(EarthquakeAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local HaleBot = {}

function HaleBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(HaleBot, self)
	return self
end

function HaleBot:State_Init()
	-- Swift Strikes
	local ability = SwiftStrikeAbility.Create(self, self.hero:GetAbility(0))
	self:RegisterAbility(ability)

	-- Inertial Sword
	ability = InertialSwordAbility.Create(self, self.hero:GetAbility(1))
	self:RegisterAbility(ability)

	-- Soul Calibur
	ability = SoulCaliburAbility.Create(self, self.hero:GetAbility(2))
	self:RegisterAbility(ability)

	-- Earthquake
	ability = EarthquakeAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

HaleBot.Create(object)

