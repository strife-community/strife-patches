-- Custom logic for Caprice Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local QUICK_DRAW_MIN_DISTANCE_TO_TARGET = 300

local CapriceBot = {}

-- Custom Behavior Tree Functions

local QuickDrawAbility = {}

function QuickDrawAbility:Evaluate()
    if not JumpToPositionAbility.Evaluate(self) then
        return false
    end

    local distance_to_target = Vector2.Distance(self.targetPos, self.owner.hero:GetPosition())
    if (distance_to_target < QUICK_DRAW_MIN_DISTANCE_TO_TARGET) then
        return false
    end

    return true
end

function QuickDrawAbility.Create(owner, ability)
    local self = JumpToPositionAbility.Create(owner, ability)
    ShallowCopy(QuickDrawAbility, self)

    self.settings.doAddRadiusToRange = true

    return self
end

function CapriceBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(CapriceBot, self)
	return self
end

function CapriceBot:State_Init()
    local abilityQ = TargetPositionAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = TargetPositionAbility.Create(self, self.hero:GetAbility(1))
    -- E is passive
    local abilityR = QuickDrawAbility.Create(self, self.hero:GetAbility(3))

    abilityQ.settings.doTargetCreeps = true
    abilityQ.settings.doTargetBosses = true	

    abilityW.settings.doTargetCreeps = true
    abilityW.settings.doTargetBosses = true

    self:RegisterAbility(abilityQ)
	self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityR)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

CapriceBot.Create(object)

