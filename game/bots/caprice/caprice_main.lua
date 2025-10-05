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
    local ability_settings = GetSettingsCopy(JumpToPositionAbility)
    ability_settings.doAddRadiusToRange = true

    local self = JumpToPositionAbility.Create(owner, ability, ability_settings)
    ShallowCopy(QuickDrawAbility, self)
    return self
end

function CapriceBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(CapriceBot, self)
	return self
end

function CapriceBot:State_Init()
    local ability
    local ability_settings

    -- Fire Lager
    ability_settings = GetSettingsCopy(TargetPositionAbility)
    ability_settings.doTargetCreeps = true
    ability_settings.doTargetBosses = true

	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(0), ability_settings)
	self:RegisterAbility(ability)

    -- Anchors
    ability_settings = GetSettingsCopy(TargetPositionAbility)
    ability_settings.doTargetCreeps = true
    ability_settings.doTargetBosses = true

	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(1), ability_settings)
	self:RegisterAbility(ability)

    -- Quick Draw
	ability = QuickDrawAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

CapriceBot.Create(object)

