-- Custom logic for HARROWER Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_JINSHE_LONGJUMP = BF_USER1

-- Custom Abilities

local LongJumpAbility = {}

function LongJumpAbility:Evaluate()
    if not JumpToPositionAbility.Evaluate(self) then
		return false
	end

    if self.owner:GetNumEnemyHeroes(700) > 0 then
		return false
	end

    return true
end

function LongJumpAbility.Execute()
    self.owner:OrderEntity(self.owner.hero, "hold")

    LongJumpAbility.Execute(self)
end

function LongJumpAbility.Create(owner, ability)
    local ability_settings = GetSettingsCopy(JumpToPositionAbility)
    ability_settings.isEscapeAbility = false
    ability_settings.doForceMaxRange = true

	local self = JumpToPositionAbility.Create(owner, ability, ability_settings)
	ShallowCopy(LongJumpAbility, self)
	return self
end
 
SpinAbility = {}

function SpinAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	return ((self.owner:GetNumEnemyHeroes(self.ability:GetTargetRadius()-75) > 0) or (self.owner:GetNumNeutralBosses(self.ability:GetTargetRadius()-75) > 0))
end

function SpinAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(SpinAbility, self)
	return self
end

-- Shapeshift

local EmberAbility = {}

function EmberAbility:Evaluate()

	if not Ability.Evaluate(self) then
		return false
	end

	local num = self.ability:GetCharges()
	if num < 6 then
		return false
    end

    local enemy_heroes = self.owner:GetNumEnemyHeroes(350)
    if enemy_heroes == 0 then
        return false
    end
    
    if ((enemy_heroes == 1) and (self.owner.hero:GetHealthPercent() > 0.5)) then
        return false
    end

	return true
	
end

function EmberAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(EmberAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local JinsheBot = {}

function JinsheBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(JinsheBot, self)
	return self
end

function JinsheBot:State_Init()
	-- Line Stun
    local ability_settings = GetSettingsCopy(TargetPositionAbility)
    ability_settings.doTargetCreeps = false

	local ability = TargetPositionAbility.Create(self, self.hero:GetAbility(0), ability_settings)
	self:RegisterAbility(ability)

	-- Spin
	ability = SpinAbility.Create(self, self.hero:GetAbility(1))
	self:RegisterAbility(ability)

	-- Leap
	ability = LongJumpAbility.Create(self, self.hero:GetAbility(2))
	self:RegisterAbility(ability)

	-- Embers
	ability = EmberAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

function JinsheBot:UpdateBehaviorFlags()

	if self.hero:HasState("State_JinShe_Ability3_Channel") then
		self:SetBehaviorFlag(BF_JINSHE_LONGJUMP)
	else
		self:ClearBehaviorFlag(BF_JINSHE_LONGJUMP)
	end

	Bot.UpdateBehaviorFlags(self)
end

function JinsheBot:Choose_Match()
	if self:HasBehaviorFlag(BF_JINSHE_LONGJUMP) then
		-- Ensure the bot does nothing that invalidates its hold order for the duration of the ability
		return "Idle"
	end

	return Bot.Choose_Match(self)
end


function JinsheBot:CheckAbilities()
	if self:HasBehaviorFlag(BF_JINSHE_LONGJUMP) then
		return
	end

	local time = Game.GetGameTime()
	if time > self.nextAbilityCheck then
		for slot,ability in ipairs(self.abilities) do
			if ability.ability == nil then
				Echo(self:GetName() .. " has nil ability in slot " .. slot)
			elseif ability:Evaluate() then
				ability:Execute()

				-- Make sure we don't do anything else if we just activated wormhole
				if self.hero:HasState("State_JinShe_Ability3_Channel") then
					self:SetBehaviorFlag(BF_JINSHE_LONGJUMP)
					return
				end

				break
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

function JinsheBot:State_Teleport()
	local time = Game.GetGameTime() + 100
	while Game.GetGameTime() < time do
		coroutine.yield()
	end

	-- See if teleport is still channeling
	while self.hero:HasState(self.teleportState) do
		-- Check if enemies are nearby (except for ult, doesn't cancel on damage)
		if not self:HasBehaviorFlag(BF_JINSHE_LONGJUMP) and self:GetNumEnemyHeroes(500) > 0 then
			break
		end

		coroutine.yield()
	end

	self.teleportState = nil
end


-- End Custom Behavior Tree Functions

JinsheBot.Create(object)

