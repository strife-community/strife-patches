-- Custom logic for Minerva Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_MINERVA_ZIG_ZAG_ACTIVE = BF_USER1

-- Custom Abilities

local MinervaAbility = {}

function MinervaAbility:Evaluate()
    if self.owner:HasBehaviorFlag(BF_MINERVA_ZIG_ZAG_ACTIVE) then
        return false
    end

	if self.owner.hero:GetHealthPercent() < 0.75 then
		return false
	end

	return TargetEnemyAbility.Evaluate(self)
end

function MinervaAbility.Create(owner, ability)
	local self = TargetEnemyAbility.Create(owner, ability, true, true)
	ShallowCopy(MinervaAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local MinervaBot = {}

function MinervaBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(MinervaBot, self)
	return self
end

function MinervaBot:State_Init()
	-- Zig and Zag
	local ability = MinervaAbility.Create(self, self.hero:GetAbility(0))
	self:RegisterAbility(ability)

	-- Heartstrike Arrow
	ability = TargetEnemyAbility.Create(self, self.hero:GetAbility(1), true, true, true)
	self:RegisterAbility(ability)

	-- Eviscerate
	ability = TargetEnemyAbility.Create(self, self.hero:GetAbility(3), false, false, true)
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

function MinervaBot:UpdateBehaviorFlags()
    local can_blink = false

    if self.hero:HasState("State_Minerva_Ability1_Buff") then
        self:SetBehaviorFlag(BF_MINERVA_ZIG_ZAG_ACTIVE)
    else
        self:ClearBehaviorFlag(BF_MINERVA_ZIG_ZAG_ACTIVE)
    end

    Bot.UpdateBehaviorFlags(self)
end

-- End Custom Behavior Tree Functions

MinervaBot.Create(object)

