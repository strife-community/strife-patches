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

    --local _, enemies = self.owner:CheckEngagement(2000)
	--if enemies == nil or enemies < 2 then
	--	return false
	--end
    
    --return true
	return self.owner:GetNumEnemyHeroes(700) > 1
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
    -- Pistol
    local ability_settings = GetSettingsCopy(TargetPositionAbility)
    ability_settings.needClearPath = true
    ability_settings.doTargetBosses = true

    local ability = TargetPositionAbility.Create(self, self.hero:GetAbility(0), ability_settings)
    self:RegisterAbility(ability)

    -- Crystal Shield
    ability = SelfShieldAbility.Create(self, self.hero:GetAbility(1))
    self:RegisterAbility(ability)

    -- Shard Attack
    ability = ShardAbility.Create(self, self.hero:GetAbility(3))
    self:RegisterAbility(ability)

    Bot.State_Init(self)
end

-- function FetterstoneBot:UpdateBehaviorFlags()
-- 	if self.hero:HasState("State_Fetterstone_Ability2") or self.hero:HasState("State_Fetterstone_Ability4") then
-- 		self:SetBehaviorFlag(BF_FETTERSTONE_AGGRO)
-- 	else
-- 		self:ClearBehaviorFlag(BF_FETTERSTONE_AGGRO)
-- 	end

-- 	Bot.UpdateBehaviorFlags(self)

-- 	if self:HasBehaviorFlag(BF_FETTERSTONE_AGGRO) then
-- 		self:SetBehaviorFlag(BF_TRYHARD)
-- 	end
-- end


-- End Custom Behavior Tree Functions

FetterstoneBot.Create(object)

