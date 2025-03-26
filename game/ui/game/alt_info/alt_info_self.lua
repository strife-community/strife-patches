local interface = object

local triggerTabAltInfo	= LuaTrigger.GetTrigger('AltInfoSelf')
local triggerTabExplain	= LuaTrigger.GetTrigger('altInfoSelfTabExplain') or LuaTrigger.CreateCustomTrigger('altInfoSelfTabExplain', {
	{	name	= 'mitigation',			type	= 'boolean'	},
	{	name	= 'power',			type	= 'boolean'	},
	{	name	= 'dps',			type	= 'boolean'	},
	{	name	= 'resistance',			type	= 'boolean'	},
	{	name	= 'showMoreInfo',		type	= 'boolean'	},
	{	name	= 'offsetDamage',		type	= 'boolean'	},
	{	name	= 'mitigationFocus',		type	= 'boolean'	},
	{	name	= 'resistanceFocus',		type	= 'boolean'	},
	{	name	= 'DPSFocus',			type	= 'boolean'	},
	{	name	= 'powerFocus',			type	= 'boolean'	},
})

triggerTabExplain.mitigation		= false
triggerTabExplain.power				= false
triggerTabExplain.dps				= false
triggerTabExplain.resistance		= false
triggerTabExplain.offsetDamage		= false
triggerTabExplain.armorFocus		= false
triggerTabExplain.magicArmorFocus	= false
triggerTabExplain.mitigationFocus	= false
triggerTabExplain.resistanceFocus	= false
triggerTabExplain.DPSFocus			= false
triggerTabExplain.powerFocus		= false

local altInfoSelfMapTrigger	= LuaTrigger.GetTrigger('altInfoSelfMapTrigger') or LuaTrigger.CreateCustomTrigger('altInfoSelfMapTrigger', {
	{	name	= 'manaVis',			type	= 'boolean'	},
	{	name	= 'levelVis',			type	= 'boolean'	},
	{	name	= 'ifFullHealthHideThis',	type	= 'boolean'	},
	{	name	= 'healthVis',			type	= 'boolean'	},
})

altInfoSelfMapTrigger.manaVis				= true
altInfoSelfMapTrigger.levelVis				= true
altInfoSelfMapTrigger.ifFullHealthHideThis	= false
altInfoSelfMapTrigger.healthVis				= true


--[[
========================
Mana and Level Visible Changes
========================
]]--
interface:GetWidget('AltInfoSelfContainer'):RegisterWatchLua('altInfoSelfMapTrigger', function(widget, trigger)
	if (trigger.healthVis) then
		if (trigger.ifFullHealthHideThis) then
			widget:UnregisterWatchLua('AltInfoSelf')
			widget:RegisterWatchLua('AltInfoSelf', function(widget, trigger)
				widget:SetVisible(triggerTabAltInfo.healthPercent < 1)
			end, false, nil, 'healthPercent')	
		else
			widget:UnregisterWatchLua('AltInfoSelf')
			widget:SetVisible(1)		
		end
		
		if (trigger.manaVis) then
			widget:SetHeight('3.0h')
		else
			widget:SetHeight('1.5h')
		end		
	else
		widget:SetVisible(0)
	end
end, false, nil, 'manaVis', 'healthVis', 'ifFullHealthHideThis')

interface:GetWidget('AltInfoSelfHealth'):RegisterWatchLua('altInfoSelfMapTrigger', function(widget, trigger)
	if (trigger.manaVis) then
		widget:SetHeight('42.6%')
		widget:SetWidth('100%')
		widget:SetY('7.8%')
		widget:SetAlign('left')
	else
		widget:SetHeight('90%')
	end				
end, false, nil, 'manaVis')

interface:GetWidget('AltInfoSelfMana'):RegisterWatchLua('altInfoSelfMapTrigger', function(widget, trigger)
	widget:SetVisible(trigger.manaVis)
end, false, nil, 'manaVis')

interface:GetWidget('AltInfoSelfAmorXPRating'):RegisterWatchLua('altInfoSelfMapTrigger', function(widget, trigger)
	widget:SetVisible(trigger.levelVis)
end, false, nil, 'levelVis')

interface:GetWidget('AltInfoSelfRMM01'):RegisterWatchLua('altInfoSelfMapTrigger', function(widget, trigger)
	if (trigger.manaVis) then
		widget:UnregisterWatchLua('AltInfoSelf')
		widget:RegisterWatchLua('AltInfoSelf', function(widget, trigger2)	
			if (trigger2.shield == 0) and (not trigger2.isStunned) then
				widget:SetVisible(1)
			else
				widget:SetVisible(0)
			end
		end, false, nil, 'shield', 'isStunned')
	else
		widget:UnregisterWatchLua('AltInfoSelf')
		widget:SetVisible(0)
	end
end, false, nil, 'manaVis')

interface:GetWidget('AltInfoSelfRMM02'):RegisterWatchLua('altInfoSelfMapTrigger', function(widget, trigger)
	if (trigger.manaVis) then
		widget:UnregisterWatchLua('AltInfoSelf')
		widget:RegisterWatchLua('AltInfoSelf', function(widget, trigger2)	
			if ((trigger2.shield == 0) and (trigger2.isStunned)) or ((trigger2.shield > 0) and (not trigger2.isStunned)) then
				widget:SetVisible(1)
			else
				widget:SetVisible(0)
			end
		end, false, nil, 'shield', 'isStunned')
	else
		widget:UnregisterWatchLua('AltInfoSelf')
		widget:SetVisible(0)
	end
end, false, nil, 'manaVis')

interface:GetWidget('AltInfoSelfRMM03'):RegisterWatchLua('altInfoSelfMapTrigger', function(widget, trigger)
	if (trigger.manaVis) then
		widget:UnregisterWatchLua('AltInfoSelf')
		widget:RegisterWatchLua('AltInfoSelf', function(widget, trigger2)	
			if (trigger2.shield > 0) and (trigger2.isStunned) then
				widget:SetVisible(1)
			else
				widget:SetVisible(0)
			end
		end, false, nil, 'shield', 'isStunned')
	else
		widget:UnregisterWatchLua('AltInfoSelf')
		widget:SetVisible(0)
	end
end, false, nil, 'manaVis')

interface:GetWidget('AltInfoSelfRMMNoMana'):RegisterWatchLua('altInfoSelfMapTrigger', function(widget, trigger)
	if (trigger.manaVis) then
		widget:UnregisterWatchLua('AltInfoSelf')
		widget:SetVisible(0)
	else
		widget:UnregisterWatchLua('AltInfoSelf')
		widget:RegisterWatchLua('AltInfoSelf', function(widget, trigger2)	
			if (trigger2.shield == 0) and (not trigger2.isStunned) then
				widget:SetVisible(1)
			else
				widget:SetVisible(0)
			end
		end, false, nil, 'shield', 'isStunned')
	end
end, false, nil, 'manaVis')

interface:GetWidget('AltInfoSelfRMMNoManaStunned'):RegisterWatchLua('altInfoSelfMapTrigger', function(widget, trigger)
	if (trigger.manaVis) then
		widget:UnregisterWatchLua('AltInfoSelf')
		widget:SetVisible(0)
	else
		widget:UnregisterWatchLua('AltInfoSelf')
		widget:RegisterWatchLua('AltInfoSelf', function(widget, trigger2)
			if (trigger2.shield == 0) and (trigger2.isStunned) then
				widget:SetVisible(1)
			else
				widget:SetVisible(0)
			end
		end, false, nil, 'shield', 'isStunned')
	end
end, false, nil, 'manaVis')

interface:GetWidget('AltInfoSelfLevelUp'):RegisterWatchLua('altInfoSelfMapTrigger', function(widget, trigger)
	if (trigger.levelVis) then
		widget:UnregisterWatchLua('AltInfoSelf')
		widget:RegisterWatchLua('AltInfoSelf', function(widget, trigger2)	
			widget:SetVisible(trigger2.availablePoints > 0)
		end, false, nil, 'availablePoints')
	else
		widget:UnregisterWatchLua('AltInfoSelf')
		widget:SetVisible(0)
	end
end, false, nil, 'levelVis')

object:GetWidget('AltInfoSelfTutExplainPowerBorder'):RegisterWatchLua('altInfoSelfTabExplain', function(widget, trigger)
	widget:SetVisible(trigger.powerFocus)
end, false, nil, 'powerFocus')


object:GetWidget('AltInfoSelfTutExplainDPSBorder'):RegisterWatchLua('altInfoSelfTabExplain', function(widget, trigger)
	widget:SetVisible(trigger.DPSFocus)
end, false, nil, 'DPSFocus')



object:GetWidget('AltInfoSelfTutExplainMitigationBorder'):RegisterWatchLua('altInfoSelfTabExplain', function(widget, trigger)
	widget:SetVisible(trigger.mitigationFocus)
end, false, nil, 'mitigationFocus')


object:GetWidget('AltInfoSelfTutExplainResistanceBorder'):RegisterWatchLua('altInfoSelfTabExplain', function(widget, trigger)
	widget:SetVisible(trigger.resistanceFocus)
end, false, nil, 'resistanceFocus')


object:GetWidget('AltInfoSelfTutExplainPower'):RegisterWatchLua('AltInfoSelf', function(widget, trigger)
	triggerTabExplain.showMoreInfo = trigger.showMoreInfo
	triggerTabExplain:Trigger(false)
end, false, nil, 'showMoreInfo')

object:GetWidget('AltInfoSelfTutExplainPower'):RegisterWatchLua('altInfoSelfTabExplain', function(widget, trigger)
	widget:SetVisible(trigger.power or trigger.powerFocus)

	if trigger.offsetDamage then
		widget:SetX('15.75h')
	else
		widget:SetX('12.5h')
	end
	
end, false, nil, 'power', 'offsetDamage', 'powerFocus')

object:GetWidget('AltInfoSelfTutExplainDPS'):RegisterWatchLua('altInfoSelfTabExplain', function(widget, trigger)
	widget:SetVisible(trigger.dps or trigger.DPSFocus)
	
	if trigger.offsetDamage then
		widget:SetX('15.75h')
	else
		widget:SetX('12.5h')
	end
end, false, nil, 'dps', 'offsetDamage', 'DPSFocus')

object:GetWidget('AltInfoSelfTutExplainMitigation'):RegisterWatchLua('altInfoSelfTabExplain', function(widget, trigger)
	widget:SetVisible(trigger.mitigation or trigger.mitigationFocus)
end, false, nil, 'mitigation')

object:GetWidget('AltInfoSelfTutExplainResistance'):RegisterWatchLua('altInfoSelfTabExplain', function(widget, trigger)
	widget:SetVisible(trigger.resistance or trigger.resistanceFocus)
end, false, nil, 'resistance', 'resistanceFocus')

object:GetWidget('altInfoSelfStatContainer'):SetVisible(true)
object:GetWidget('altInfoSelfDamageContainer'):SetVisible(true)

object:GetWidget('altInfoSelfMitigation'):RegisterWatchLua('altInfoSelfTabExplain', function(widget, trigger)
	widget:SetVisible((trigger.showMoreInfo or trigger.mitigation))
end, false, nil, 'showMoreInfo', 'mitigation')

object:GetWidget('altInfoSelfResistance'):RegisterWatchLua('altInfoSelfTabExplain', function(widget, trigger)
	widget:SetVisible((trigger.showMoreInfo or trigger.resistance))
end, false, nil, 'showMoreInfo', 'resistance')

object:GetWidget('altInfoSelfPower'):RegisterWatchLua('altInfoSelfTabExplain', function(widget, trigger)
	widget:SetVisible((trigger.showMoreInfo or trigger.power))
end, false, nil, 'showMoreInfo', 'power')

object:GetWidget('altInfoSelfDamage'):RegisterWatchLua('altInfoSelfTabExplain', function(widget, trigger)
	widget:SetVisible((trigger.showMoreInfo or trigger.dps))
end, false, nil, 'showMoreInfo', 'dps')


triggerTabExplain.moreInfoKey = LuaTrigger.GetTrigger('AltInfoSelf').showMoreInfo
triggerTabExplain:Trigger(true)

local function altInfoSelfRegister(object)
	local powerIcon1		= object:GetWidget('AltInfoSelfPowerIcon_1')
	local powerEffect		= object:GetWidget('AltInfoSelfPowerEffect')

	object:GetWidget('AltInfoSelfPowerIcon_Parent'):RegisterWatchLua('AltInfoSelf', function(widget, trigger)
		local scaledPower	= ((trigger.power - 30) * (1 + (trigger.level/15)))
		local dps			= trigger.dps

		if (scaledPower >= 450) or (dps >= 525) then
			powerIcon1:SetVisible(1)
			powerIcon1:SetTexture('/ui/game/alt_info/textures/np_off_5.tga')
			powerEffect:SetVisible(1)
		elseif (scaledPower >= 400) or (dps >= 450) then
			powerIcon1:SetVisible(1)
			powerIcon1:SetTexture('/ui/game/alt_info/textures/np_off_5.tga')
			powerEffect:SetVisible(0)
		elseif (scaledPower >= 325) or (dps >= 325) then
			powerIcon1:SetVisible(1)
			powerIcon1:SetTexture('/ui/game/alt_info/textures/np_off_3.tga')
			powerEffect:SetVisible(0)
		elseif ((scaledPower >= 250) or (dps >= 200)) and (trigger.showMoreInfo) then
			powerIcon1:SetVisible(1)
			powerIcon1:SetTexture('/ui/game/alt_info/textures/np_off_2.tga')
			powerEffect:SetVisible(0)
		elseif ((scaledPower >= 175) or (dps >= 75)) and (trigger.showMoreInfo) then
			powerIcon1:SetVisible(1)
			powerIcon1:SetTexture('/ui/game/alt_info/textures/np_off_1.tga')
			powerEffect:SetVisible(0)
		else
			widget:GetWidget('AltInfoSelfPowerIcon_1'):SetVisible(0)
			powerEffect:SetVisible(0)
		end
	end, true, nil, 'power', 'level', 'dps', 'showMoreInfo')

	-- =======================================

	local armorIcon1	= object:GetWidget('AltInfoSelfArmorIcon_1')

	object:GetWidget('AltInfoSelfArmorIcon_Parent'):RegisterWatchLua('AltInfoSelf', function(widget, trigger)
		local totalArmor = trigger.armor + trigger.magicArmor + trigger.mitigation + trigger.resistance

		if (totalArmor >= 230) then 	-- max 302 min 62
			armorIcon1:SetVisible(1)
			armorIcon1:SetTexture('/ui/game/alt_info/textures/np_def_5.tga')
		elseif (totalArmor >= 180) then
			armorIcon1:SetVisible(1)
			armorIcon1:SetTexture('/ui/game/alt_info/textures/np_def_4.tga')
		elseif (totalArmor >= 120) then
			armorIcon1:SetVisible(1)
			armorIcon1:SetTexture('/ui/game/alt_info/textures/np_def_3.tga')
		elseif (totalArmor >= 80) then
			armorIcon1:SetVisible(1)
			armorIcon1:SetTexture('/ui/game/alt_info/textures/np_def_2.tga')
		elseif (totalArmor >= 40) then
			armorIcon1:SetVisible(1)
			armorIcon1:SetTexture('/ui/game/alt_info/textures/np_def_1.tga')
		else
			armorIcon1:SetVisible(1)
			armorIcon1:SetTexture('/ui/game/alt_info/textures/np_def_1.tga')
		end
	end, true, nil, 'armor', 'magicArmor', 'mitigation', 'resistance')	-- 'showMoreInfo'


	-- =======================================

	object:GetWidget('AltInfoSelfXPWheelParent'):RegisterWatchLua('AltInfoSelf', function(widget, trigger)
		widget:SetVisible(GetCvarBool('_expWheelVis', true) or trigger.showMoreInfo)
		if (GetCvarBool('_expWheelVis', true) or (trigger.showMoreInfo)) then
			widget:SetHeight('106%')
			widget:SetWidth('106@')
			widget:SetX('-3@')
		else
			widget:SetHeight('60%')
			widget:SetWidth('60@')
			widget:SetX('0')
		end
	end, true, nil, 'showMoreInfo')

	-- =======================================

	object:GetWidget('altInfoSelfStatContainer'):RegisterWatchLua('AltInfoSelf', function(widget, trigger)
		-- widget:SetVisible(trigger.showMoreInfo)
	end, true, nil, 'showMoreInfo')

	object:GetWidget('altInfoSelfMitigation'):RegisterWatchLua('AltInfoSelf', function(widget, trigger) widget:SetText(libNumber.round(trigger.mitigation, 0)) end, false, nil, 'mitigation')
	object:GetWidget('altInfoSelfResistance'):RegisterWatchLua('AltInfoSelf', function(widget, trigger) widget:SetText(libNumber.round(trigger.resistance, 0)) end, false, nil, 'resistance')

	object:GetWidget('altInfoSelfDamageContainer'):RegisterWatchLua('AltInfoSelf', function(widget, trigger)
		-- widget:SetVisible(trigger.showMoreInfo)

		local scaledPower = (trigger.power * (1 + (trigger.level/15)))

		if (scaledPower >= 325) or (trigger.dps >= 325) then
			widget:SetX('220@')
			triggerTabExplain.offsetDamage = true
		elseif ((scaledPower >= 175) or (trigger.dps >= 75)) and (trigger.showMoreInfo) then
			widget:SetX('220@')
			triggerTabExplain.offsetDamage = true
		else
			widget:SetX('100@')
			triggerTabExplain.offsetDamage = false
		end
		triggerTabExplain:Trigger(false)

	end, true, nil, 'showMoreInfo', 'power', 'level', 'dps')

	object:GetWidget('altInfoSelfPower'):RegisterWatchLua('AltInfoSelf', function(widget, trigger) widget:SetText(libNumber.round(trigger.power, 0)) end, false, nil, 'power')

	object:GetWidget('altInfoSelfDamage'):RegisterWatchLua('AltInfoSelf', function(widget, trigger) widget:SetText(libNumber.round(trigger.dps, 0)) end, false, nil, 'dps')

	local playerName = object:GetWidget('AltInfoSelfPlayerName')

	playerName:RegisterWatchLua('AltInfoSelf', function(widget, trigger)
		widget:SetText(trigger.playerName)
	end, true, nil, 'playerName')

	playerName:RegisterWatchLua('AltInfoSelf', function(widget, trigger)
		if (trigger.availablePoints) then
			widget:SetVisible(trigger.showMoreInfo and (trigger.availablePoints == 0))
		else
			widget:SetVisible(trigger.showMoreInfo)
		end
	end, true, nil, 'showMoreInfo', 'availablePoints')

	local combatPieRemainder = object:GetWidget('AltInfoSelfCombatPieRemainder')

	combatPieRemainder:RegisterWatchLua('AltInfoSelf', function(widget, trigger)
		widget:SetVisible((trigger.showMoreInfo or trigger.isHovering))
		if (trigger.shield > 0) and (trigger.isStunned) then
			widget:SetHeight('+22@')
			widget:SetY('6@')
		elseif (trigger.shield > 0) or (trigger.isStunned)  then
			widget:SetHeight('+16@')
			widget:SetY('2@')
		else
			widget:SetHeight('+8@')
			widget:SetY('0')
		end
	end, true, nil, 'showMoreInfo', 'isHovering', 'shield', 'isStunned')

	combatPieRemainder:SetColor(styles_healthBarSelfColor .. " 0.75")

	combatPieRemainder:RegisterWatchLua('updateHealthColors', function(widget)
		if not styles_healthBarAllyColor2 then return end
		widget:SetColor(styles_healthBarSelfColor .. " 0.75")
	end)

	object:GetWidget('AltInfoSelfShoppingIcon'):RegisterWatchLua('AltInfoSelf', function(widget, trigger) widget:SetVisible(trigger.shopOpen) end, true, nil, 'shopOpen')
	object:GetWidget('AltInfoSelfTalkingIcon'):RegisterWatchLua('AltInfoSelf', function(widget, trigger) widget:SetVisible(trigger.isTalking) end, true, nil, 'isTalking')
	object:GetWidget('AltInfoSelfTypingIcon'):RegisterWatchLua('AltInfoSelf', function(widget, trigger) widget:SetVisible(trigger.isTyping) end, true, nil, 'isTyping')
	object:GetWidget('AltInfoSelfShoppingIconContainer'):RegisterWatchLua('AltInfoSelf', function(widget, trigger)
		if (trigger.showMoreInfo or trigger.availablePoints > 0) then
			widget:SetY('-2.2h')
		else
			widget:SetY('0')
		end
	end, true, nil, 'showMoreInfo', 'availablePoints')

	local healthShadow = object:GetWidget('AltInfoSelfHealthShadow')

	if (GetCvarBool('_game_healthLerping')) then
		healthShadow:RegisterWatchLua('AltInfoSelf', function(widget, trigger)
			widget:SetVisible(trigger.healthLerp > 0)
			widget:SetWidth(ToPercent(trigger.healthLerp))
		end, true, nil, 'healthLerp')
		healthShadow:SetColor(styles_healthBarSelfLerpColor)
	else
		healthShadow:UnregisterWatchLua('AltInfoSelf')
		healthShadow:SetVisible(0)
	end

	healthShadow:RegisterWatchLua('updateHealthColors', function(widget)
		widget:SetColor(styles_healthBarSelfLerpColor)
		if (GetCvarBool('_game_healthLerping')) then
			widget:UnregisterWatchLua('AltInfoSelf')
			widget:RegisterWatchLua('AltInfoSelf', function(widget, trigger)
				widget:SetVisible(trigger.healthLerp > 0)
				widget:SetWidth(ToPercent(trigger.healthLerp))
			end, true, nil, 'healthLerp')
			widget:SetColor(styles_healthBarSelfLerpColor)
		else
			widget:UnregisterWatchLua('AltInfoSelf')
			widget:SetVisible(0)
		end
	end)
	
	altInfoSelfMapTrigger:Trigger(false)
end

altInfoSelfRegister(object)