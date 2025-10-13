-- Custom logic for Fetterstone Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_FETTERSTONE_AGGRO = BF_USER1

-- Custom Abilities

local ShardAbility = {}

function ShardAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    local _, enemies = self.owner:CheckEngagement(2000)
    if enemies == nil or enemies < 2 then
        return false
    end
    
    return true
end

function ShardAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(ShardAbility, self)
	return self
end
-- End Custom Abilities

-- Custom Behavior Tree Functions

local FetterstoneBot = {}

function FetterstoneBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(FetterstoneBot, self)
	return self
end

function FetterstoneBot:State_Init()
    local abilityQ = TargetPositionAbility.Create(self, self.hero:GetAbility(0)) 
    local abilityW = SelfShieldAbility.Create(self, self.hero:GetAbility(1))
    -- ability E is passive
    local abilityR = ShardAbility.Create(self, self.hero:GetAbility(3))

    abilityQ.settings.needClearPath = true
    abilityQ.settings.doTargetBosses = true

    local ability 
    self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityR)

    Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

FetterstoneBot.Create(object)

