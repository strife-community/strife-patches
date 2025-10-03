-- Custom logic for Shank Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_SHANK_AGGRO = BF_USER1


-- Custom Abilities

StompAbility = {}

function StompAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	local target_num = self.owner:GetNumEnemyHeroes(self.ability:GetTargetRadius()-75)
	target_num = target_num + self.owner:GetNumNeutralBosses(self.ability:GetTargetRadius()-75)

	return (target_num > 0)
end

function StompAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability, true)
	ShallowCopy(StompAbility, self)
	return self
end

--

ShoutAbility = {}

function ShoutAbility:Evaluate()

	if EscapeAbility.Evaluate(self) then
		return true
	end
	
	if self.owner.hero:GetHealthPercent() < 0.6 then
		return false
	end

	if not TargetPositionAbility.Evaluate(self) then
		return false
	end

	return true
end

function ShoutAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability, false, false, false, true)
	ShallowCopy(ShoutAbility, self)
	return self
end

--

ShoutAbility = {}

function ShoutAbility:Evaluate()
	if self.owner.hero:GetHealthPercent() < 0.6 then
		return false
	end

	if not TargetPositionAbility.Evaluate(self) then
		return false
	end

	return true
end

function ShoutAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability, false, false, false, false)
	ShallowCopy(ShoutAbility, self)
	return self
end

--


HookAbility = {}

function HookAbility:Evaluate()

	if not TargetPositionAbility.Evaluate(self) then
		return false
	end
	
	if self.owner.hero:GetHealthPercent() < 0.4 then
		return false
	end
	
	return true

end

function HookAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability, false, true, false, true)
	ShallowCopy(HookAbility, self)
	return self
end

--


-- End Custom Abilities

-- Custom Behavior Tree Functions

local ShankBot = {}

function ShankBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(ShankBot, self)
	return self
end

function ShankBot:State_Init()
	-- Stomp
	local ability = StompAbility.Create(self, self.hero:GetAbility(0))
	self:RegisterAbility(ability)
	
	-- Shout
	local ability = ShoutAbility.Create(self, self.hero:GetAbility(1))
	self:RegisterAbility(ability)
	
	-- Hook
	local ability = HookAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)


	Bot.State_Init(self)
end

function ShankBot:UpdateBehaviorFlags()
	if self.hero:HasState("State_Shank_Ability2") then
		self:SetBehaviorFlag(BF_SHANK_AGGRO)
	else
		self:ClearBehaviorFlag(BF_SHANK_AGGRO)
	end

	Bot.UpdateBehaviorFlags(self)

	if self:HasBehaviorFlag(BF_SHANK_AGGRO) then
		self:SetBehaviorFlag(BF_TRYHARD)
	end
end

-- End Custom Behavior Tree Functions

ShankBot.Create(object)

