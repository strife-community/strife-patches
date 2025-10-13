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

	if self.owner.hero:GetHealthPercent() < 0.25 then
		return false
	end

	return TargetEnemyAbility.Evaluate(self)
end

function MinervaAbility.Create(owner, ability)
    local self = TargetEnemyAbility.Create(owner, ability)
    ShallowCopy(MinervaAbility, self)

    self.settings.doTargetCreeps = true
    self.settings.doTargetBosses = true
    
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
    local abilityQ = MinervaAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = TargetEnemyAbility.Create(self, self.hero:GetAbility(1)) 
    -- ability E is passive
    local abilityR = TargetEnemyAbility.Create(self, self.hero:GetAbility(3))

    abilityQ.doTargetBosses = true

    abilityW.doTargetBosses = true

    self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityR)

	Bot.State_Init(self)
end

function MinervaBot:UpdateBehaviorFlags()
    if self.hero:HasState("State_Minerva_Ability1_Buff") then
        self:SetBehaviorFlag(BF_MINERVA_ZIG_ZAG_ACTIVE)
    else
        self:ClearBehaviorFlag(BF_MINERVA_ZIG_ZAG_ACTIVE)
    end

    Bot.UpdateBehaviorFlags(self)
end

-- End Custom Behavior Tree Functions

MinervaBot.Create(object)

