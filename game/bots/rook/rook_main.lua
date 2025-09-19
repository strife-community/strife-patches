-- Custom logic for Rook Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_ROOK_GRAPPLE = BF_USER1
local BF_ROOK_INVULNERABLE = BF_USER2
local BF_ROOK_ATKBUFF = BF_USER3

-- Custom Abilities

local GrapplingHookAbility = {}

function GrapplingHookAbility:Evaluate()
	if self.owner:HasBehaviorFlag(BF_ROOK_GRAPPLE) then
		if EscapeAbility.Evaluate(self) then
			return true
		end

		if self.owner.hero:GetHealthPercent() < 0.7 then
			return false
		end

		if not TargetPositionAbility.Evaluate(self) then
			return false
		end

		if self.owner.teambot:PositionInTeamHazard(self.targetPos) then
			return false
		end

		local threat = self.owner:CalculateThreatLevel(self.targetPos)
		if threat < 0.8 then
			return true
		end

		return false
	end

	if EscapeAbility.Evaluate(self) then
		return true
	end

	if TargetPositionAbility.Evaluate(self) then
		return true
	end
		
	return false
end

function GrapplingHookAbility:Execute()
	if self.owner:HasBehaviorFlag(BF_ROOK_GRAPPLE) then
		Ability.Execute(self)
	else
		TargetPositionAbility.Execute(self)
	end
end

function GrapplingHookAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability, true)
	ShallowCopy(GrapplingHookAbility, self)
	return self
end

local HideThenSeekAbility = {}

function HideThenSeekAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	if self.owner.hero:GetHealthPercent() > 0.6 then
		return false
	end

	local num = self.owner:GetNumAttackers()
	if num > 2 then
		return true
	elseif num > 0 and self.owner.hero:GetHealthPercent() < 0.4 then
		return true
	end

	return false
end

function HideThenSeekAbility:Execute()
	self.owner:OrderEntity(self.owner.hero, "hold")

	return Ability.Execute(self)
end

function HideThenSeekAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(HideThenSeekAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local RookBot = {}

function RookBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(RookBot, self)
	return self
end

function RookBot:State_Init()
	-- Grappling Hook
	local ability = GrapplingHookAbility.Create(self, self.hero:GetAbility(0))
	self:RegisterAbility(ability)

	-- Hide Then Seek
	self.HSAbility = HideThenSeekAbility.Create(self, self.hero:GetAbility(1))
	self:RegisterAbility(self.HSAbility)

	-- Shell Shocker
	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(3), false)
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

function RookBot:Choose_Match()
	if self:HasBehaviorFlag(BF_ROOK_INVULNERABLE) then
		-- Ensure the bot does nothing that invalidates its hold order for the duration of the ability
		return "Idle"
	elseif self:HasBehaviorFlag(BF_ROOK_ATKBUFF) and self:UpdateAttackTarget(1500, 2000, self.threat) then
		return "AttackTarget"
	end

	return Bot.Choose_Match(self)
end

function RookBot:UpdateBehaviorFlags()
	if self.hero:HasState("State_Rook_Ability1_Self_Buff") then
		self:SetBehaviorFlag(BF_ROOK_GRAPPLE)
	else
		self:ClearBehaviorFlag(BF_ROOK_GRAPPLE)
	end

	if self.hero:HasState("State_Rook_Ability3_Buff") then
		self:SetBehaviorFlag(BF_ROOK_ATKBUFF)
	else
		self:ClearBehaviorFlag(BF_ROOK_ATKBUFF)
	end

	if self.hero:HasState("State_Rook_Ability2") then
		self:SetBehaviorFlag(BF_ROOK_INVULNERABLE)
		return
	else
		self:ClearBehaviorFlag(BF_ROOK_INVULNERABLE)
	end

	Bot.UpdateBehaviorFlags(self)
end

function RookBot:CheckAbilities()
	if self:HasBehaviorFlag(BF_ROOK_INVULNERABLE) then
		return
	end

	local time = Game.GetGameTime()
	if time > self.nextAbilityCheck then
		if not self:HasBehaviorFlag(BF_ROOK_ATKBUFF) then
			for slot,ability in ipairs(self.abilities) do
				if ability.ability == nil then
					Echo(self:GetName() .. " has nil ability in slot " .. slot)
				elseif ability:Evaluate() then
					ability:Execute()
					self.lastAbilityTime = time

					-- Make sure we don't do anything else if we just activated invulnerability
					if self.hero:HasState("State_Rook_Ability2") then
						self:SetBehaviorFlag(BF_ROOK_INVULNERABLE)
						return
					end

					break
				end
			end
		end

		for _,item in ipairs(self.items) do
			if item:Evaluate() then
				item:Execute()
				break
			end
		end

		self.nextAbilityCheck = time + self:GetAbilityCheckTime()
		if self.clearTeleport then
			self:ClearBehaviorFlag(BF_CHECK_TELEPORT)
		end
	end
end

-- End Custom Behavior Tree Functions

RookBot.Create(object)

