local floor = math.floor
local GetTrigger = LuaTrigger.GetTrigger
local triggerStatus = GetTrigger('selection_Status')
local tinsert = table.insert
mainUI = mainUI or {}
mainUI.savedLocally 	= mainUI.savedLocally 		or {}
mainUI.savedRemotely 	= mainUI.savedRemotely 		or {}
mainUI.savedAnonymously	= mainUI.savedAnonymously 	or {}
ShopUI = ShopUI or {}
ShopUI.defaultCategory = 'crafted+itembuild'
ShopUI.maxItems = 99
ShopUI.maxRows = 35
ShopUI.selectedBuild = -1
ShopUI.lastFilterArray = ''
ShopUI.lastHeroRetrieved = ''
ShopUI.numItemsInSlot = {} -- This is the number and indices of items of the same type, which can be swapped around. It also points to the base item, for duplicate items.
local interface = object

local slotSwapUpdatedTrigger = LuaTrigger.CreateCustomTrigger('slotSwapUpdatedTrigger',{})

local listViewFonts	= {
	'subdyn_12',
	'subdyn_11',
	'subdyn_10',
	'subdyn_9',	
}

ShopUI.oldHeroBuild = ShopUI.oldHeroBuild or nil

mainUI.savedLocally.LastBuild = mainUI.savedLocally.LastBuild or {}
local hero = LuaTrigger.GetTrigger('HeroUnit').heroEntity
if hero == "" then -- New game
	object:GetWidget('gameShopContainer'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		hero = trigger.heroEntity
		ShopUI.oldHeroBuild = mainUI.savedLocally.LastBuild[hero] -- Load the current build into the global table - so it isn't changed on reload.
		mainUI.savedLocally.LastBuild[hero] = {Skills={}, Items={}}
		widget:UnregisterWatchLua('HeroUnit')
	end, false, nil, 'heroEntity')
else -- Interface reload
	mainUI.savedLocally.LastBuild[hero] = mainUI.savedLocally.LastBuild[hero] or {Skills={}, Items={}}
	mainUI.savedLocally.LastBuild[hero].Skills = {}
end

local shopCategories = {
	'',		-- All
	'crafted+itembuild',
	'boots',
	'attack',
	'ability',
	'mana',
	'defense',
	'utility',
	'consumable',
	'components',
}

itemStatTypeFormat_itemTip	= {
	maxMana					= function(input, showName)
		local value = libNumber.commaFormat(input, 0)
		if showName then
			return Translate('item_stat_count_format_maxMana', 'amount', value)
		else
			return value
		end
	end,
	power					= function(input, showName)
		local value = FtoA2(input, 0, 0)
		if showName then
			return Translate('item_stat_count_format_power', 'amount', value)
		else
			return value
		end
	end,
	maxHealth				= function(input, showName)
		local value = libNumber.commaFormat(input, 0)
		if showName then
			return Translate('item_stat_count_format_maxHealth', 'amount', value)
		else
			return value
		end
	end,
	baseHealthRegen	= function(input, showName)
		local value = libNumber.round(input, 2)
		if showName then
			return Translate('item_stat_count_format_baseHealthRegen', 'amount', value)
		else
			return value
		end
	end,
	baseManaRegen		= function(input, showName)
		local value = libNumber.round(input, 2)
		if showName then
			return Translate('item_stat_count_format_baseManaRegen', 'amount', value)
		else
			return value
		end
	end,
	baseAttackSpeed				= function(input, showName)
		local value = FtoA2(100 * input, 0, 1)
		if showName then
			return Translate('item_stat_count_format_baseAttackSpeed', 'amount', value)
		else
			return value
		end
	end,
	armor	= function(input, showName)
		local value = libNumber.round(input, 2)
		if showName then
			return Translate('item_stat_count_format_armor', 'amount', value)
		else
			return value
		end
	end,
	magicArmor	= function(input, showName)
		local value = libNumber.round(input, 2)
		if showName then
			return Translate('item_stat_count_format_magicArmor', 'amount', value)
		else
			return value
		end
	end,
	mitigation	= function(input, showName)
		local value = libNumber.round(input, 2)
		if showName then
			return Translate('item_stat_count_format_mitigation', 'amount', value)
		else
			return value
		end
	end,
	resistance	= function(input, showName)
		local value = libNumber.round(input, 2)
		if showName then
			return Translate('item_stat_count_format_resistance', 'amount', value)
		else
			return value
		end
	end,
}

compNameToFilterName	= {
	Item_Manastone = {'mana_comp1'},
	Item_Diamond = {'mana_comp2'},
	Item_Brain = {'mana_comp3'},
	Item_Manaregen1 = {'mana_regen_comp1'},
	Item_Manaregen2 = {'mana_regen_comp2'},
	Item_Healthstone = {'health_comp1'},
	Item_Booster = {'health_comp2'},
	Item_Heart = {'health_comp3'},
	Item_Mender = {'health_regen_comp1'},
	Item_Sustainer = {'health_regen_comp2'},
	Item_Blade = {'power_comp1'},
	Item_Staff = {'power_comp2'},
	Item_Relic = {'power_comp3'},
	Item_GlovesOfHaste = {'attack_speed_comp1'},
	Item_Warpcleft = {'attack_speed_comp2'},
}

--Functions to assist with item management
local function GetBaseItem(i)
	return (ShopUI.numItemsInSlot[i] and ShopUI.numItemsInSlot[i].baseItem) or i
end
local function GetBaseTable(i)
	return ShopUI.numItemsInSlot[GetBaseItem(i)]
end
local function GetCurrentItem(i)
	local base = GetBaseTable(i)
	return base.indices[base.current]
end


function gameShopRemoveOwned()
	local itemInfo
	for i=8,0,-1 do	-- Have to go backwards due to how list populates
		itemInfo = GetTrigger('BookmarkQueue'..i)
		if itemInfo.isOwned then
			Shop.RemoveBookmark(i)
		end
	end
	object:GetWidget('gameShopBuyQueueBackground'):DoEvent()
end

local filterTable = {
	activatable = {'activatable'},
	attack_speed = {'attack_speed'},
	attack_mod = {'attack_mod'},
	defense_armor = {'armor'},
	buff_team = {'buff_team'},
	attack_crit = {'crit'},
	cd_reduction = {'cd_reduction'},
	debuff_enemy = {'debuff_enemy'},
	defense_health = {'health'},
	attack_lifesteal = {'lifesteal'},
	defense_magic_armor = {'magic_armor'},
	ability_mana = {'mana'},
	mobility = {'other_mobility'},
	ability_power = {'power'},
	stealth = {'stealth'},
	attack_damage = {'attack_damage'},
	mana_comp1 = {'mana_comp1'},
	mana_comp2 = {'mana_comp2'},
	mana_comp3 = {'mana_comp3'},
	mana_regen_comp1 = {'mana_regen_comp1'},
	mana_regen_comp2 = {'mana_regen_comp2'},
	health_comp1 = {'health_comp1'},
	health_comp2 = {'health_comp2'},
	health_comp3 = {'health_comp3'},
	health_regen_comp1 = {'health_regen_comp1'},
	health_regen_comp2 = {'health_regen_comp2'},
	power_comp1 = {'power_comp1'},
	power_comp2 = {'power_comp2'},
	power_comp3 = {'power_comp3'},
	attack_speed_comp1 = {'attack_speed_comp1'},
	attack_speed_comp2 = {'attack_speed_comp2'},
	defense_mitigation = {'mitigation'},
	defense_resistance = {'resistance'},
}

local filterVisibilityTable = {
	search = {
		activatable = true,
		attack_speed = true,
		attack_mod = true,
		defense_armor = false,
		buff_team = true,
		attack_crit = true,
		cd_reduction = true,
		debuff_enemy = true,
		defense_health = true,
		attack_lifesteal = true,
		defense_magic_armor = false,
		ability_mana = true,
		mobility = true,
		ability_power = true,
		attack_damage = true,
		defense_mitigation = true,
		defense_resistance = true,
	},
	crafted = {
		activatable = true,
		attack_speed = true,
		attack_mod = true,
		defense_armor = false,
		buff_team = true,
		attack_crit = true,
		cd_reduction = true,
		debuff_enemy = true,
		defense_health = true,
		attack_lifesteal = true,
		defense_magic_armor = false,
		ability_mana = true,
		mobility = true,
		ability_power = true,
		attack_damage = true,
		defense_mitigation = true,
		defense_resistance = true,
	},
	boots = {
		activatable = true,
		attack_damage = true,
		attack_speed = true,
		defense_health = true,
		ability_power = true,
	},
	attack = {
		activatable = true,
		attack_speed = true,
		attack_mod = true,
		attack_crit = true,
		debuff_enemy = true,
		defense_health = true,
		attack_lifesteal = true,
		mobility = true,
		ability_power = true,
	},
	ability = {
		activatable = true,
		attack_mod = true,
		cd_reduction = true,
		defense_health = true,
		attack_lifesteal = true,
		ability_power = true,
	},
	mana = {
		activatable = true,
		buff_team = true,
		defense_health = true,
		ability_mana = true,
	},
	defense = {
		activatable = true,
		attack_speed = true,
		defense_armor = false,
		buff_team = true,
		debuff_enemy = true,
		defense_health = true,
		defense_magic_armor = false,
		ability_mana = true,
		mobility = true,
		ability_power = true,
		defense_mitigation = true,
		defense_resistance = true,
	},
	utility = {
		activatable = true,
		attack_mod = true,
		buff_team = true,
		debuff_enemy = true,
		ability_mana = true,
		mobility = true,
		stealth = true,
	},
	consumable = {
	},
	components = {
		mana_comp1 			= true,
		mana_comp2 			= true,
		mana_comp3 			= true,
		mana_regen_comp1 	= true,
		mana_regen_comp2 	= true,
		health_comp1 		= true,
		health_comp2 		= true,
		health_comp3 		= true,
		health_regen_comp1 	= true,
		health_regen_comp2 	= true,
		power_comp1 		= true,
		power_comp2 		= true,
		power_comp3 		= true,
		attack_speed_comp1	= true,
		attack_speed_comp2	= true,
	},
}

local function shopRegisterBindableHotkey(object, buttonID, onButtonClick)
	local button		= object:GetWidget(buttonID..'Button')
	local backer		= object:GetWidget(buttonID..'Backer')
	local body		= object:GetWidget(buttonID..'Body')
	local label			= object:GetWidget(buttonID..'Label')
	local highlight		= object:GetWidget(buttonID..'Highlight')
	local buttonTip		= object:GetWidget(buttonID..'ButtonTip')

	button:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
		widget:SetNoClick(not trigger.moreInfoKey)
	end, false)

	backer:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
		if trigger.moreInfoKey then
			widget:SetColor(styles_colors_hotkeyCanSet)
			widget:SetBorderColor(styles_colors_hotkeyCanSet)
		else
			widget:SetColor(styles_colors_hotkeyNoSet)
			widget:SetBorderColor(styles_colors_hotkeyNoSet)
		end
	end, false)


	buttonTip:SetCallback('onmouseover', function(widget)
		simpleTipNoFloatUpdate(true, nil, Translate('game_keybind_1'), Translate('game_keybind_2', 'value', GetKeybindButton('game', 'TriggerToggle', 'gameShowMoreInfo', 0)), nil, nil, libGeneral.HtoP(-18), 'center', 'bottom')
		UpdateCursor(widget, true, { canLeftClick = true})
	end)

	buttonTip:SetCallback('onmouseout', function(widget)
		simpleTipNoFloatUpdate(false)
		UpdateCursor(widget, false, { canLeftClick = true})
	end)

	button:SetCallback('onmouseover', function(widget)
		simpleTipNoFloatUpdate(true, nil, Translate('game_keybind_1'), Translate('game_keybind_2_no_mod'), nil, nil, libGeneral.HtoP(-18), 'center', 'bottom')
		UpdateCursor(widget, true, { canLeftClick = true, canRightClick = false })
	end)

	button:SetCallback('onmouseout', function(widget)
		simpleTipNoFloatUpdate(false)
		UpdateCursor(widget, false, { canLeftClick = true, canRightClick = false })
	end)

	button:SetCallback('onclick', function(widget)
		onButtonClick(widget, buttonInfo)
	end)
end

shopRegisterBindableHotkey(object, 'shopItemListTabHotkey', function()
	local binderData	= LuaTrigger.GetTrigger('buttonBinderData')
	local oldButton		= nil
	binderData.show			= true
	binderData.table		= 'game'
	binderData.action		= 'ToggleShop'
	binderData.param		= ''
	binderData.keyNum		= 0	-- 0 for leftclick, 1 for rightclick
	binderData.impulse		= true
	binderData.oldButton	= (GetKeybindButton('game', 'ToggleShop', '', 0) or 'None')
	binderData:Trigger(false)
end)

shopRegisterBindableHotkey(object, 'shopAbilitiesTabHotkey', function()
	local binderData	= LuaTrigger.GetTrigger('buttonBinderData')
	local oldButton		= nil
	binderData.show			= true
	binderData.table		= 'game'
	binderData.action		= 'TriggerToggle'
	binderData.param		= 'gameShowSkills'
	binderData.keyNum		= 0	-- 0 for leftclick, 1 for rightclick
	binderData.impulse		= false
	binderData.oldButton	= (GetKeybindButton('game', 'TriggerToggle', 'gameShowSkills', 0) or 'None')
	binderData:Trigger(false)
end)

local shopitemInfoStatTypeInfo = {
	{ param	= 'power', icon = style_crafting_componentTypeIcons['power'], color = style_crafting_componentTypeColors['power'] },
	{ param	= 'baseAttackSpeed', icon = style_crafting_componentTypeIcons['baseAttackSpeed'], color = style_crafting_componentTypeColors['baseAttackSpeed'] },
	{ param	= 'maxHealth', icon = style_crafting_componentTypeIcons['maxHealth'], color = style_crafting_componentTypeColors['maxHealth'] },
	{ param	= 'maxMana', icon = style_crafting_componentTypeIcons['maxMana'], color = style_crafting_componentTypeColors['maxMana'] },
	{ param	= 'baseHealthRegen', icon = style_crafting_componentTypeIcons['healthRegen'], color = style_crafting_componentTypeColors['healthRegen'] },
	{ param	= 'baseManaRegen', icon = style_crafting_componentTypeIcons['manaRegen'], color = style_crafting_componentTypeColors['manaRegen'] },
}

local function getShopItemStatInfo(itemInfo, index)
	for k,v in ipairs(shopitemInfoStatTypeInfo) do
		if itemInfo['recipeComponentDetail'..index..v.param] > 0 then
			return v
		end
	end
	return false
end

function ShopUI.ClearFilters()
	for k,v in pairs(preTrigger_shopFilterList) do
		trigger_shopFilter[k] = false
	end
	trigger_shopFilter:Trigger(false)
end

local function ActivateRelatedFilters(filter)
	--[[ Filters in use
		boots cc_resist activatable attack_speed_comp health_comp health_regen_comp
		mana_comp mana_regen_comp power_comp consumable attack_speed power other_mobility stealth utility lifesteal
		attack ability debuff_enemy attack_mod defense health defense armor magic_armor crit spell_vamp
		cd_reduction heal lifesteal buff_team maxmana  mana mana_regen health_regen
	--]]

	local filterList = {}
	local isFiltering = false
	local filterArray = {''}

	if trigger_shopFilter.forceCategory == '' then
		for k,_ in pairs(preTrigger_shopFilterList) do
			if trigger_shopFilter[k] then
				filterList[k] = true
				isFiltering = true
			end
		end

		if (trigger_shopFilter.shopCategory) and (not Empty(trigger_shopFilter.shopCategory)) and (not ((isFiltering) and (trigger_shopFilter.shopCategory == 'components'))) then
			filterArray = {trigger_shopFilter.shopCategory}
		end

		for i1,v1 in pairs(filterList) do
			if (filterTable[i1]) then
				for i2,v2 in pairs(filterTable[i1]) do
					table.insert(filterArray, v2)
				end
			else
				table.insert(filterArray, i1)
			end
		end
	else
		filterArray = { trigger_shopFilter.forceCategory }
	end

	trigger_gamePanelInfo.shopIsFiltered = (#filterArray > 1)
	trigger_gamePanelInfo:Trigger(false)

	Shop.SetFilter(filterArray)

	ShopUI.lastFilterArray = filterArray
end

local function gameShopRegisterFilterCheckbox(object, filter)
	local container	= object:GetWidget('shopFilterCheckbox'..filter)
	local button	= object:GetWidget('shopFilterCheckbox'..filter..'Button')
	local frame_1	= object:GetWidget('shopFilterCheckbox'..filter..'_frame_1')
	local frame_2	= object:GetWidget('shopFilterCheckbox'..filter..'_frame_2')
	local frame_3	= object:GetWidget('shopFilterCheckbox'..filter..'_frame_3')
	local frame_4	= object:GetWidget('shopFilterCheckbox'..filter..'_frame_4')
	local frame_5	= object:GetWidget('shopFilterCheckbox'..filter..'_frame_5')
	local checkButton	= object:GetWidget('shopFilterCheckbox'..filter..'CheckButton')
	local check		= object:GetWidget('shopFilterCheckbox'..filter..'Check')

	if (not button) then return end

	button:SetCallback('onmouseover', function(widget)
		frame_1:SetColor('#463f3c')
		frame_1:SetBorderColor('#463f3c')
		frame_2:SetColor('#4f433A')
		frame_2:SetBorderColor('#4f433A')
		frame_3:SetColor('#352c27')
		frame_3:SetBorderColor('#352c27')
		UpdateCursor(widget, true, { canLeftClick = true})
	end)

	button:SetCallback('onmouseout', function(widget)
		frame_1:SetColor('#241f1a')
		frame_1:SetBorderColor('#241f1a')
		frame_2:SetColor('#2e2118')
		frame_2:SetBorderColor('#2e2118')
		frame_3:SetColor('#130a05')
		frame_3:SetBorderColor('#130a05')
		UpdateCursor(widget, false, { canLeftClick = true})
	end)

	button:SetCallback('onclick', function(widget)
		-- sound_filterLeftclick
		-- PlaySound('/path_to/filename.wav')
		object:GetWidget('game_shop_search_input'):EraseInputLine()
		trigger_gamePanelInfo.selectedShopItem = -1
		trigger_gamePanelInfo.selectedShopItemType = ''
		trigger_gamePanelInfo:Trigger(false)

		if trigger_shopFilter[filter] then
			trigger_shopFilter[filter] = false
		else
			ShopUI.ClearFilters()
			trigger_shopFilter[filter] = true
		end

		trigger_shopFilter:Trigger(false)
	end)

	button:SetCallback('onrightclick', function(widget)
		-- sound_filterRightclick
		-- PlaySound('/path_to/filename.wav')
		object:GetWidget('game_shop_search_input'):EraseInputLine()
		trigger_gamePanelInfo.selectedShopItem = -1
		trigger_gamePanelInfo.selectedShopItemType = ''
		trigger_gamePanelInfo:Trigger(false)

		if trigger_shopFilter[filter] then
			trigger_shopFilter[filter] = false
		else
			ShopUI.ClearFilters()
			trigger_shopFilter[filter] = true
		end

		trigger_shopFilter:Trigger(false)
	end)

	checkButton:SetCallback('onclick', function(widget)
		-- sound_filterCheckLeftclick
		-- PlaySound('/path_to/filename.wav')
		object:GetWidget('game_shop_search_input'):EraseInputLine()
		trigger_gamePanelInfo.selectedShopItem = -1
		trigger_gamePanelInfo.selectedShopItemType = ''
		trigger_gamePanelInfo:Trigger(false)

		if trigger_shopFilter[filter] then
			trigger_shopFilter[filter] = false
		else
			trigger_shopFilter[filter] = true
		end

		trigger_shopFilter:Trigger(false)
	end)

	checkButton:SetCallback('onrightclick', function(widget)
		-- sound_filterCheckRightclick
		-- PlaySound('/path_to/filename.wav')
		object:GetWidget('game_shop_search_input'):EraseInputLine()
		trigger_gamePanelInfo.selectedShopItem = -1
		trigger_gamePanelInfo.selectedShopItemType = ''
		trigger_gamePanelInfo:Trigger(false)

		if trigger_shopFilter[filter] then
			trigger_shopFilter[filter] = false
		else
			trigger_shopFilter[filter] = true
		end

		trigger_shopFilter:Trigger(false)
	end)

	checkButton:SetCallback('onmouseover', function(widget)
		frame_1:SetColor('#463f3c')
		frame_1:SetBorderColor('#463f3c')
		frame_2:SetColor('#4f433A')
		frame_2:SetBorderColor('#4f433A')
		frame_3:SetColor('#352c27')
		frame_3:SetBorderColor('#352c27')
		frame_4:SetColor('0.8 0.8 0.8 1')
		frame_4:SetBorderColor('0.8 0.8 0.8 1')
		frame_5:SetColor('0.9 0.9 0.9 1')
		frame_5:SetBorderColor('0.9 0.9 0.9 1')
		UpdateCursor(widget, true, { canLeftClick = true})
	end)

	checkButton:SetCallback('onmouseout', function(widget)
		frame_1:SetColor('#241f1a')
		frame_1:SetBorderColor('#241f1a')
		frame_2:SetColor('#2e2118')
		frame_2:SetBorderColor('#2e2118')
		frame_3:SetColor('#130a05')
		frame_3:SetBorderColor('#130a05')
		frame_4:SetColor('1 1 1 1')
		frame_4:SetBorderColor('1 1 1 1')
		frame_5:SetColor('0 0 0 1')
		frame_5:SetBorderColor('0 0 0 1')
		UpdateCursor(widget, false, { canLeftClick = true})
	end)

	check:RegisterWatchLua('gameShopFilterInfo', function(widget, trigger)
		widget:SetVisible(trigger[filter])
	end, false, nil, filter)

end

for k,v in pairs(preTrigger_shopFilterList) do
	gameShopRegisterFilterCheckbox(object, k)
end

local function gameShopRegisterCategoryTab(object, index, category, useGlow)
	local button		= object:GetWidget('shopCategoryButton'..index)

	local hover			= object:GetWidget('shopCategoryButton'..index..'Hover')
	local hoverTexture	= object:GetWidget('shopCategoryButton'..index..'HoverTexture')
	local selected		= object:GetWidget('shopCategoryButton'..index..'Selected')
	local selectGlow	= object:GetWidget('shopCategoryButton'..index..'SelectGlow')
	local current		= object:GetWidget('shopCategoryButton'..index..'Current')

	local pulseDuration = 1000
	local glowVis		= true
	local lastGlowVis	= false
	local glowR, glowG, glowB, glowA = selectGlow:GetColor()


	local function selectedCategory(trigger)
		trigger = trigger or GetTrigger('gameShopFilterInfo')
		local forcedCategory	= trigger.forceCategory
		local selectedCategory	= trigger.shopCategory
		local useForcedCategory = string.len(forcedCategory) > 0

		if useForcedCategory then
			selectedCategory = forcedCategory
		end

		if selectedCategory == category then
			return true
		end
	end

	local function glowEnd()
		selectGlow:UnregisterWatchLua('System')
		selectGlow:FadeOut(pulseDuration)
	end

	local function glowStart()
		glowEnd()
		selectGlow:RegisterWatchLua('System', function(widget, trigger)
			local hostTime = trigger.hostTime

			if glowVis and (lastGlowVis ~= glowVis) then
				widget:FadeIn(pulseDuration)
				lastGlowVis = glowVis
			elseif (not glowVis) and (lastGlowVis ~= glowVis) then
				widget:FadeOut(pulseDuration)
				lastGlowVis = glowVis
			end

			glowVis = ((hostTime % (pulseDuration * 2)) > pulseDuration)
		end, false, nil, 'hostTime')
	end

	current:RegisterWatchLua('gameShopFilterInfo', function(widget, trigger)
		if selectedCategory(trigger) then
			widget:FadeIn(175)
		else
			widget:FadeOut(175)
		end
	end, false, nil, 'shopCategory', 'forceCategory')

	hoverTexture:RegisterWatchLua('gameShopFilterInfo', function(widget, trigger)
		if selectedCategory(trigger) then
			widget:SetTexture('/ui/shared/frames/std_btn_inset.tga')
		else
			widget:SetTexture('/ui/shared/frames/stnd_btn_up.tga')
		end
	end, false, nil, 'shopCategory', 'forceCategory')

	button:SetCallback('onclick', function(widget)
		object:GetWidget('game_shop_search_input'):EraseInputLine()
		ShopUI.ClearFilters()
		trigger_shopFilter:Trigger(false)
		trigger_gamePanelInfo.selectedShopItem = -1
		trigger_gamePanelInfo.selectedShopItemType = ''
		trigger_gamePanelInfo:Trigger(false)

		if selectedCategory() then
			trigger_shopFilter.shopCategory	= ShopUI.defaultCategory
		else
			trigger_shopFilter.shopCategory	= category
		end

		-- sound_shopChangeCategory
		PlaySound('ui/sounds/crafting/sfx_category.wav')

		trigger_shopFilter:Trigger(false)
	end)

	button:SetCallback('onmouseover', function(widget)
		local trigger = GetTrigger('gameShopFilterInfo')

		if (not selectedCategory(trigger)) and string.len(trigger.forceCategory) > 0 then
			hover:SetColor(0,0,0,0)
		else
			hover:SetColor(0,0,0,0)
		end

		simpleTipGrowYUpdate(true, nil, Translate('game_shop_category_'..category), FormatStringNewline(Translate('game_shop_category_'..category..'_tip')), libGeneral.HtoP(27))
		hover:FadeIn(125)
		UpdateCursor(widget, true, { canLeftClick = true})
	end)

	button:SetCallback('onmouseout', function(widget)
		simpleTipGrowYUpdate(false)
		hover:FadeOut(125)
		UpdateCursor(widget, false, { canLeftClick = true})
	end)

	button:SetCallback('onhide', function(widget)
		glowEnd()
	end)

	button:SetCallback('onshow', function(widget)
		if selectedCategory() then
			glowStart()
		end
	end)

	selectGlow:SetCallback('onhide', function(widget)
		-- selectGlow:UnregisterWatchLua('System')
	end)

	selected:RegisterWatchLua('gameShopFilterInfo', function(widget, trigger)
		if selectedCategory(trigger) then
			glowStart()
			widget:FadeIn(175)
		else
			glowEnd()
			widget:FadeOut(175)
		end
	end, false, nil, 'shopCategory', 'forceCategory')

	if useGlow then
		libGeneral.createGroupTrigger('shopBootsGlowInfo', { 'ActiveInventory96.exists', 'gamePanelInfo.mapWidgetVis_shopBootsGlow' })
		object:GetWidget('shopCategoryButton'..index..'Glow'):RegisterWatchLua('shopBootsGlowInfo', function(widget, groupTrigger)

			local exists 	= groupTrigger['ActiveInventory96'].exists
			local useGlow	= groupTrigger['gamePanelInfo'].mapWidgetVis_shopBootsGlow
			widget:SetVisible(useGlow and not exists)
		end)
	end
end

local function gameShopRegisterBuyQueueEntryComponent(object, itemID, index)
	local container		= object:GetWidget('gameShopBuyQueueEntry'..itemID..'Component'..index)
	local color			= object:GetWidget('gameShopBuyQueueEntry'..itemID..'Component'..index..'Color')
	local icon			= object:GetWidget('gameShopBuyQueueEntry'..itemID..'Component'..index..'Icon')

	container:RegisterWatchLua('BookmarkQueue'..itemID, function(widget, trigger) widget:SetVisible(trigger['recipeComponentDetail'..index..'exists']) end, false, nil, 'recipeComponentDetail'..index..'exists')

	icon:RegisterWatchLua('BookmarkQueue'..itemID, function(widget, trigger)
		widget:SetTexture(trigger['recipeComponentDetail'..index..'icon'])
	end, false, nil, 'recipeComponentDetail'..index..'icon')

	color:RegisterWatchLua('BookmarkQueue'..itemID, function(widget, trigger)
		local exists		= trigger['recipeComponentDetail'..index..'exists']
		local isOwned		= trigger['recipeComponentDetail'..index..'isOwned']
		local isOnCourier	= trigger['recipeComponentDetail'..index..'isOnCourier']
		local isInStash		= trigger['recipeComponentDetail'..index..'isInStash']
		local isInBackPack	= trigger['recipeComponentDetail'..index..'isInBackPack']
		if exists then
			if isOwned then
				if isInBackPack then
					widget:SetColor('#22EE33')
				elseif isOnCourier then
					widget:SetColor('#FFDD33')
				elseif isInStash then
					widget:SetColor('#f7532e')
				else
					widget:SetColor('#00CCFF')
				end
			else
				widget:SetColor('#666666')
			end
		end
	end, false, nil, 'recipeComponentDetail'..index..'exists', 'recipeComponentDetail'..index..'isOwned', 'recipeComponentDetail'..index..'isInStash', 'recipeComponentDetail'..index..'isOnCourier', 'recipeComponentDetail'..index..'isInBackPack')
end

local function gameShopRegisterBuyQueueEntry(object, index)
	local container		= object:GetWidget('gameShopBuyQueueEntry'..index)
	local icon			= object:GetWidget('gameShopBuyQueueEntry'..index..'Icon')
	local piegraph		= object:GetWidget('gameShopBuyQueueEntry'..index..'Piegraph')	-- Percent of cost to next component / recipe scroll owned
	local dropTarget	= object:GetWidget('gameShopBuyQueueEntry'..index..'DropTarget')
	local dropHighlight	= object:GetWidget('gameShopBuyQueueEntry'..index..'DropHighlight')
	local removeButton	= object:GetWidget('gameShopBuyQueueEntry'..index..'Remove')

	local button			= object:GetWidget('gameShopBuyQueueEntry'..index..'Button')

	object:GetWidget('gameShopBuyQueueEntry'..index..'Crafted'):RegisterWatchLua('BookmarkQueue'..index, function(widget, trigger)
		widget:SetVisible(trigger.isPlayerCrafted)
	end, false, nil, 'isPlayerCrafted')

	button:SetCallback('onclick', function(widget)
		local itemInfo	= GetTrigger('BookmarkQueue'..index)
		if (itemInfo) and (itemInfo.exists) and (itemInfo.entity) then
			trigger_gamePanelInfo.selectedShopItemType = ''
			trigger_gamePanelInfo:Trigger(false)

			ShopUI.ClearFilters()

			if itemInfo.isRecipe then
				if trigger_gamePanelInfo.selectedShopItem == 0 then
					button:Sleep(1, function()
						gameShopUpdateRowDataSelectedID(object)
					end)
				else
					trigger_gamePanelInfo.selectedShopItem = 0
				end

				object:GetWidget('game_shop_search_input'):SetInputLine(itemInfo.displayName)
				trigger_shopFilter.shopCategory	= ''
			else
				trigger_gamePanelInfo.selectedShopItem = -1



				if compNameToFilterName[itemInfo.entity][1] then
					object:GetWidget('game_shop_search_input'):EraseInputLine()
					trigger_shopFilter.shopCategory	= 'components'
					trigger_shopFilter[compNameToFilterName[itemInfo.entity][1]] = true
				else
					trigger_shopFilter.shopCategory	= ''
					object:GetWidget('game_shop_search_input'):SetInputLine(itemInfo.displayName)
				end

			end

			trigger_gamePanelInfo:Trigger(false)
			trigger_shopFilter:Trigger(false)
		end
	end)

	button:SetCallback('ondoubleclick', function(widget)
		local itemInfo	= GetTrigger('BookmarkQueue'..index)

		gameShopSetLastPurchaseSourceWidget(widget)

		if itemInfo.isRecipe then
			Shop.PurchaseRemainingComponents(itemInfo.entity)
		else
			Shop.PurchaseByName(itemInfo.entity)
		end
	end)

	button:SetCallback('onrightclick', function(widget)
			if trigger_gamePanelInfo.mapWidgetVis_shopRightClick then
		local itemInfo	= GetTrigger('BookmarkQueue'..index)
		local exists	= itemInfo.exists
		local entity	= itemInfo.entity
		local isRecipe	= itemInfo.isRecipe

		if exists and entity then

			gameShopSetLastPurchaseSourceWidget(widget)

			if isRecipe then
				Shop.PurchaseRemainingComponents(entity)
			else
				Shop.PurchaseByName(entity)
					end
			end
		end
	end)

	removeButton:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
		widget:SetVisible(trigger.shift and trigger.ctrl)
	end, false, nil, 'shift', 'ctrl')

	removeButton:SetCallback('onclick', function(widget)
		-- sound_bookmarksRemove
		-- PlaySound('/path_to/filename.wav')
		Shop.RemoveBookmark(index)
	end)

	removeButton:SetCallback('onrightclick', function(widget)
		-- sound_bookmarksRemove
		-- PlaySound('/path_to/filename.wav')
		Shop.RemoveBookmark(index)
	end)

	removeButton:SetCallback('onmouseover', function(widget)
		simpleTipGrowYUpdate(true, nil, Translate('Remove from Bookmarks'), Translate('Click to remove this item from your bookmarks.'))
	end)

	removeButton:SetCallback('onmouseout', function(widget)
		simpleTipGrowYUpdate(false)
	end)

	removeButton:SetCallback('onshow', function(widget)
	end)

	button:SetCallback('onmouseout', function(widget)
		shopItemTipHide()
		UpdateCursor(widget, false, { canLeftClick = true, canRightClick = true, canDrag = true })
	end)

	container:RegisterWatchLua('BookmarkQueue'..index, function(widget, trigger) widget:SetVisible(trigger.exists) end, false, nil, 'exists')
	icon:RegisterWatchLua('BookmarkQueue'..index, function(widget, trigger) widget:SetTexture(trigger.icon) end, false, nil, 'icon')

	button:SetCallback('onmouseover', function(widget)
		shopItemTipShow(index, 'BookmarkQueue')
		UpdateCursor(widget, true, { canLeftClick = true, canRightClick = true, canDrag = true })
	end)

	dropHighlight:RegisterWatchLua('bookmarkDragInfo', function(widget, groupTrigger)
		local triggerDrag		= groupTrigger['globalDragInfo']
		widget:SetVisible(triggerDrag.active and (triggerDrag.type == 3 or ((triggerDrag.type == 4 or triggerDrag.type == 5 or triggerDrag.type == 6) and groupTrigger['Shop'].bookmarkQueueSize < 9 and not trigger_gamePanelInfo.shopDraggedItemOwnedRecipe)))
	end)

	dropTarget:SetCallback('onmouseover', function(widget)
		globalDraggerReadTarget(widget, function()
			local targIndex = index
			local sourceIndex = trigger_gamePanelInfo.shopLastBuyQueueDragged
			local placeEntity = ''
			if sourceIndex ~= targIndex then

				if sourceIndex >= 0 then
					placeEntity = GetTrigger('BookmarkQueue'..sourceIndex).entity

					if sourceIndex < targIndex then
						-- targIndex =
					elseif sourceIndex > targIndex then
						-- targIndex = targIndex - 1
					end

					Shop.RemoveBookmark(sourceIndex)
				else
					placeEntity = trigger_gamePanelInfo.shopDraggedItem
				end

				Shop.QueueBookmark(placeEntity, targIndex, false)
				object:GetWidget('gameShopBuyQueueBackground'):DoEvent()
			else
				return true
			end

			trigger_gamePanelInfo.shopLastBuyQueueDragged = -1
			trigger_gamePanelInfo.shopLastQuickSlotDragged = -1
		end)
	end)

	button:SetCallback('onstartdrag', function(widget)
		trigger_gamePanelInfo.shopLastBuyQueueDragged = index
	end)

	button:RefreshCallbacks()

	local playerGold = GetTrigger('PlayerGold')

	piegraph:SetValue(1)
	piegraph:SetVisible(true)
	piegraph:RegisterWatchLua('BookmarkQueue'..index, function(widget, trigger)
		if (trigger.isOnCourier) then	-- courier
			widget:SetColor('#efd056')
		elseif (trigger.isInStash) then	-- stash
			widget:SetColor('#efd056')
		elseif (trigger.isOwned) and (trigger.isRecipe) then	-- otherwise owned
			widget:SetColor('0.3 0.3 0.3 1')
		elseif (trigger.cost <= playerGold.gold) then	-- can purchase
			widget:SetColor('#5fc851')
		else										-- too broke
			widget:SetColor('#a82222')
		end
	end)

	piegraph:RegisterWatchLua('PlayerGold', function(widget, trigger)
		local itemInfo = GetTrigger('BookmarkQueue'..index)

		if (itemInfo.isOnCourier) then	-- courier
			widget:SetColor('#efd056')
		elseif (itemInfo.isInStash) then	-- stash
			widget:SetColor('#efd056')
		elseif (itemInfo.isOwned) and (itemInfo.isRecipe) then	-- otherwise owned
			widget:SetColor('0.3 0.3 0.3 1')
		elseif (itemInfo.cost <= trigger.gold) then	-- can purchase
			widget:SetColor('#5fc851')
		else										-- too broke
			widget:SetColor('#a82222')
		end
	end)

	globalDraggerRegisterSource(button, 3, 'gameDragLayer', function()
		Shop.RemoveBookmark(index)
		object:GetWidget('gameShopBuyQueueBackground'):DoEvent()
	end)

	for i=0,2,1 do
		gameShopRegisterBuyQueueEntryComponent(object, index, i)
	end
end


local minimapFlipped = false -- whether the minimap is currently swapped

local function gameShopRegisterItemList(object)
	local container			= object:GetWidget('gameShopItemList')

	local scrollBar			= object:GetWidget('gameShopItemListScrollbar')
	local scrollPanel		= object:GetWidget('gameShopItemListScrollPanel')
	local rowsMax			= 10

	local scrollMin			= 0	-- Will likely never change
	local scrollMax			= 0
	local scrollPos			= 0
	local itemsPerRow		= 4	-- Will change based on whether filters are visible
	local itemsPerRowMax	= 4

	local itemPaddingBase			= libGeneral.HtoP(0.5)
	local itemPaddingList			= itemPaddingBase
	local itemPaddingSimple			= itemPaddingBase
	local itemHeightSimpleBase		= libGeneral.HtoP(11)	-- 12.5
	local itemHeightListBase		= libGeneral.HtoP(7.75)		-- 8

	local lastValidRow				= 1
	local lastSelectedRow			= 1

	local itemHeightSimple			= itemHeightSimpleBase
	local itemHeightSimpleExpanded	= (itemHeightSimple * 2) + itemPaddingBase
	local itemHeightList			= itemHeightListBase
	local itemHeightListExpanded	= (itemHeightList * 2) + itemPaddingBase

	local fullItemWatchList		= 'gameShopItemListWatchList'
	local fullItemWatchSimple	= 'gameShopItemListWatchSimple'

	local itemList				= {}
	local rowData				= {}		-- What item contents exist per row, whether expanded, etc.
	local registeredRowTriggers	= {}
	local lastItemView			= -1
	local lastItemClickTime		= 0
	local clickDeselectTime		= 500
	local lastSelectedItem		= -1

	local function gameShopUpdateGlowColor(innerGlow, outerFrame, shoppingIcon, over, isOnCourier, isInStash, isOwned, canAfford, isRecipeScroll, itemCanAfford, needComponents)
		over			= over or false
		isOnCourier		= isOnCourier or false
		isOwned			= isOwned or false
		isInStash		= isInStash or false
		canAfford		= canAfford or false

		isRecipeScroll	= isRecipeScroll or false
		itemCanAfford	= itemCanAfford or false
		needComponents	= needComponents or false

		if innerGlow and outerFrame and shoppingIcon then
			local glowColor		= '#a8222260'
			local frameColor	= '#a82222'
			local iconTexture	= '/ui/shared/shop/textures/shop_hoverIcon_coins.tga'
			local updateTexture	= false
			local showIcon		= false

			if isOwned then
				showIcon	= true
				if isInStash then
					iconTexture = '/ui/shared/shop/textures/shop_hoverIcon_stash.tga'
					updateTexture = true
					glowColor	= '#efd05635'
					frameColor	= '#efd056'
				elseif isOnCourier then
					iconTexture = '/ui/shared/shop/textures/shop_hoverIcon_courier.tga'
					updateTexture = true
					glowColor	= '#efd05635'
					frameColor	= '#efd056'
				else
					iconTexture = '/ui/shared/shop/textures/shop_hoverIcon_owned.tga'
					updateTexture = true
					glowColor	= '#efd05635'
					frameColor	= '#efd056'
				end
			elseif (isRecipeScroll and needComponents) then
				showIcon	= true
				iconTexture = '/ui/shared/shop/filters/components_1.tga'
				updateTexture = true
				glowColor	= '#191919'
				frameColor	= '#333333'
			elseif canAfford or shopInLauncher then
				glowColor	= '#5fc85135'
				frameColor	= '#5fc851'

			else	-- only set texture if you can't afford.  this way if you purchase something and then sell it, and you can afford it, it'll just fade out the last state rather than switch to "need gold" icon
				showIcon	= true
				updateTexture = true
			end

			libGeneral.fade(shoppingIcon, ((over and showIcon) or (isOwned and (isOnCourier or isOwned or isInStash))), 125)


			if updateTexture then
				shoppingIcon:SetTexture(iconTexture)
			end

			innerGlow:SetColor(glowColor)

			if over then
				innerGlow:FadeIn(125)
				outerFrame:SetColor(frameColor)
				outerFrame:SetBorderColor(frameColor)
			else
				innerGlow:FadeOut(125)
				outerFrame:SetColor(0.75, 0.75, 0.75)
				outerFrame:SetBorderColor(0.75, 0.75, 0.75)
			end
		else
			print('missing widgets for gameShopUpdateGlowColor\n')
		end
	end

	function gameShopGetItemSlotID(index)
		for i=1,#rowData,1 do
			if rowData[i].itemID == index then
				return i
			elseif rowData[i].subList and type(rowData[i].subList) == 'table' then
				for k,v in ipairs(rowData[i].subList) do
					if v == index then
						return {i, k}	-- row, col
					end
				end
			end
		end
		return false
	end

	function gameShopGetItemSlotIDFromEntity(entity)
		for i=1,#rowData,1 do
			if rowData[i].itemID and LuaTrigger.GetTrigger('ShopItem'..rowData[i].itemID).entity == entity then
				return i
			elseif rowData[i].subList and type(rowData[i].subList) == 'table' then
				for k,v in ipairs(rowData[i].subList) do
					if LuaTrigger.GetTrigger('ShopItem'..v).entity == entity then
						return {i, k}	-- row, col
					end
				end
			end
		end
		return false
	end

	function testPrintRowData()
		printr(rowData)
	end

	local function rowHasSelectedItem(object, index)
		local rowInfo = rowData[index]
		if rowInfo.selectedID then
			return true
		end
		return false
	end

	local function updateRowHeight(object)
		local viewAreaBaseHeight = object:GetWidget('gameShopItemList'):GetHeight()

		local newItemHeight
		local newItemPadding

		if trigger_gamePanelInfo.shopItemView == 0 then
			local maxItemsSimple			= floor(viewAreaBaseHeight / (itemHeightSimpleBase + itemPaddingBase))
			local viewAreaSimple			= viewAreaBaseHeight - (maxItemsSimple * itemHeightSimpleBase) - ((maxItemsSimple - 1) * itemPaddingBase)
			local itemHeightSimpleExtra		= floor(viewAreaSimple / maxItemsSimple)
			local itemHeightSimpleAdd		= floor(itemHeightSimpleExtra / maxItemsSimple)
			itemHeightSimple				= itemHeightSimpleBase + itemHeightSimpleAdd
			viewAreaSimple					= viewAreaSimple - (itemHeightSimpleAdd * maxItemsSimple)
			local itemPaddingSimpleAdd		= floor(viewAreaSimple / (maxItemsSimple - 1))
			itemPaddingSimple				= itemPaddingBase + itemPaddingSimpleAdd
			itemHeightSimpleExpanded		= (itemHeightSimple * 2) + itemPaddingList

			newItemHeight = itemHeightSimple
			newItemPadding = itemPaddingSimple
		else
			local maxItemsList				= floor(viewAreaBaseHeight / (itemHeightListBase + itemPaddingBase))
			local viewAreaList				= viewAreaBaseHeight - (maxItemsList * itemHeightListBase) - ((maxItemsList - 1) * itemPaddingBase)
			local itemHeightListExtra		= floor(viewAreaList / maxItemsList)
			local itemHeightListAdd			= floor(itemHeightListExtra / maxItemsList)
			itemHeightList					= itemHeightListBase + itemHeightListAdd
			viewAreaList					= viewAreaList - (itemHeightListAdd * maxItemsList)
			local itemPaddingListAdd		= floor(viewAreaList / (maxItemsList - 1))
			itemPaddingList					= itemPaddingBase + itemPaddingListAdd
			local itemHeightListExpanded	= (itemHeightList * 2) + itemPaddingList

			newItemHeight = itemHeightList
			newItemPadding = itemPaddingList

		end

		for i=1,ShopUI.maxItems+1,1 do
			if rowHasSelectedItem(object, i) then
				object:GetWidget('gameShopItemRow'..i):SetHeight((newItemHeight * 2) + newItemPadding)
			else
				object:GetWidget('gameShopItemRow'..i):SetHeight(newItemHeight)
			end
		end

	end

	local listContainer		= object:GetWidget('gameShopItemListContainer')	-- meh on the naming here
	listContainer:RegisterWatchLua('shopVisControls', function(widget, groupTrigger)

		local trigger_gamePanelInfo	= groupTrigger['gamePanelInfo']
		local trigger_gamePhase		= groupTrigger['GamePhase']
		local trigger_craftingStage	= groupTrigger['craftingStage']
		local trigger_selection_Status	= groupTrigger['selection_Status']
		local mainPanelStatus	= groupTrigger['mainPanelStatus']

		local showFilters = (trigger_gamePanelInfo.shopView == 1 and (not trigger_gamePanelInfo.abilityPanel) and ((trigger_gamePanelInfo.shopShowFilters and trigger_gamePanelInfo.shopHasFiltersToDisplay) or trigger_gamePanelInfo.shopCategory == '' or trigger_gamePanelInfo.shopCategory == 'components'))

		if showFilters and (string.len(trigger_shopFilter.forceCategory) <= 0) then
			widget:SetWidth(libGeneral.HtoP(-19.25))
			widget:SetX(libGeneral.HtoP(-0.75))
		else
			widget:SetWidth(libGeneral.HtoP(-6))
			widget:SetX(libGeneral.HtoP(-3))
		end

		if trigger_gamePhase.gamePhase >= 4 then
			-- widget:SetHeight(libGeneral.HtoP(52))
			-- widget:SetY(libGeneral.HtoP(17.5))
			-- object:GetWidget('gameShopCategoryList'):SetY(libGeneral.HtoP(4.2))
			object:GetWidget('gameShopSelectRecipeLabel'):SetVisible(false)
		elseif (((trigger_selection_Status.selectionSection == mainUI.Selection.selectionSections.SKILL_BUILDS) and (mainPanelStatus.main == 40 or mainPanelStatus.main == 101))) then
			object:GetWidget('gameShopSelectRecipeLabel'):SetText(Translate('game_shop_drag_item_to_bookmarks'))
			object:GetWidget('gameShopSelectRecipeLabel'):SetVisible(true)
		else
			-- widget:SetHeight(libGeneral.HtoP(52))
			-- widget:SetY(libGeneral.HtoP(12))
			-- object:GetWidget('gameShopCategoryList'):SetY(0)
			object:GetWidget('gameShopSelectRecipeLabel'):SetText(Translate('game_shop_select_recipe_to_modify'))
			object:GetWidget('gameShopSelectRecipeLabel'):SetVisible(true)
		end

		updateRowHeight(widget)
		libScrollShop2.updatePosData(
			libScrollShop2.getScrollInfo('gameShopItemList'), false, nil, true
		)

		widget:SetVisible(not trigger_gamePanelInfo.abilityPanel)
	end)	-- , false, nil, 'shopView', 'abilityPanel', 'shopShowFilters', 'shopCategory', 'shopHasFiltersToDisplay'

	--[[
		row
			itemID		= #											-- If this is populated and not -1, show it as single item
			subList		= {itemID1, itemID2, itemID3, itemID4}		-- If these are populated, show row of items each with its own ItemID
			selectedID	= #											-- either matches ID of selected item or is empty/-1.  If populated, register contents to components and expand item
	--]]

	local paramList	= {
		{ name	= 'shopItemView',		type = 'number'},
		{ name	= 'shopCategory',		type = 'string'}
	}

	for i=1,ShopUI.maxItems+1,1 do
		rowData[i] = {}
	end

	for i=0,ShopUI.maxItems,1 do
		table.insert(paramList,
			{ name	= 'item'..i..'Exists',	type = 'boolean'}
		)
	end

	local itemListParams = LuaTrigger.CreateCustomTrigger('shopItemListParams', paramList)

	for i=0,ShopUI.maxItems,1 do
		itemListParams['item'..i..'Exists'] = false
		container:RegisterWatchLua('ShopItem'..i, function(widget, trigger)
			local exists = trigger.exists
			itemListParams['item'..i..'Exists'] = exists
			if not exists then
				registeredRowTriggers[i] = false
			end
			itemListParams:Trigger(false)

		end, false, nil, 'exists')
	end

	container:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		itemListParams.shopItemView			= trigger.shopItemView

		if lastItemView ~= shopItemView then
			lastItemView = shopItemView
			for i=0,ShopUI.maxItems,1 do
				registeredRowTriggers[i] = false
			end
		end
		itemListParams.shopCategory = trigger.shopCategory

		itemListParams:Trigger(false)
	end, false, nil, 'shopItemView', 'shopCategory') -- , 'shopView', 'abilityPanel'

	itemListParams.shopItemView			= trigger_gamePanelInfo.shopItemView
	itemListParams:Trigger(true)

	local function buildItemList(itemList, trigger)
		local useCategory		= trigger_shopFilter.shopCategory
		local isForceCategory	= false
		if string.len(trigger_shopFilter.forceCategory) > 0 then
			useCategory		= trigger_shopFilter.forceCategory
			isForceCategory	= true
		end
		for i=0,ShopUI.maxItems,1 do
			if (
				trigger['item'..i..'Exists'] and ((not isForceCategory) or (not shopForcedCategoryItems) or (not shopForcedCategoryItems[useCategory]) or libGeneral.isInTable(shopForcedCategoryItems[useCategory], LuaTrigger.GetTrigger('ShopItem'..i).entity))
			) then	-- Tutorial-Specific Mod
				table.insert(itemList, i)
			end
		end
	end
	
	local function unregisterRowItem(object, rowID)
		local container	= object:GetWidget('gameShopItemListItem'..rowID)
		container:UnregisterAllWatchLuaByKey(fullItemWatchList)
		container:SetVisible(false)
	end
	local function unregisterSub(object, rowID, subID)
		if rowID <= ShopUI.maxRows then
			local container	= object:GetWidget('gameShopItemListRow'..rowID..'Item'..subID)
			container:UnregisterAllWatchLuaByKey(fullItemWatchSimple)
			if container:IsVisibleSelf() then
				container:SetVisible(false)
			end
		end
	end

	local function buttonRegisterActions(button, index, icon, componentID, recipeScroll, innerGlow, outerFrame, shoppingIcon, listBG, listBGFrame)	-- rmm update to support component dragging
		local paramPrefix = ''
		local affordParam	= 'canAfford'
		recipeScroll = recipeScroll or false

		if recipeScroll then
			affordParam = 'recipeScrollCanAfford'
		end
		local isComponent = false
		if componentID then	-- expanded component
			isComponent = true
			paramPrefix = 'recipeComponentDetail'..componentID

			button:SetCallback('onclick', function(widget)

				local triggerPhase	= LuaTrigger.GetTrigger('GamePhase')

				if triggerPhase.gamePhase >= 4 then
					local itemInfo = LuaTrigger.GetTrigger('ShopItem'..index)
					if LuaTrigger.GetTrigger('ModifierKeyStatus').moreInfoKey then

						object:GetWidget('game_shop_search_input'):EraseInputLine()
						trigger_gamePanelInfo.selectedShopItem = -1

						trigger_gamePanelInfo.selectedShopItemType = ''
						trigger_gamePanelInfo:Trigger(false)

						ShopUI.ClearFilters()
						trigger_shopFilter.shopCategory	= 'components'
						trigger_shopFilter[compNameToFilterName[itemInfo[paramPrefix..'entity']][1]] = true
						trigger_shopFilter:Trigger(false)
					end
				end
			end)
		else
			button:SetCallback('onclick', function(widget)
				local itemInfo = GetTrigger('ShopItem'..index)

				local triggerPhase	= LuaTrigger.GetTrigger('GamePhase')

				if triggerPhase.gamePhase >= 4 then	-- rmm this is controlling whether select recipe via leftclick in crafting
					local currentTime	= GetTime()

					if itemInfo.isRecipe and trigger_gamePanelInfo.selectedShopItem ~= index then
						trigger_gamePanelInfo.selectedShopItem = index
						trigger_gamePanelInfo.selectedShopItemType = ''
						trigger_gamePanelInfo:Trigger(false)
					else
						if (lastItemClickTime + clickDeselectTime) < GetTime() and not recipeScroll then
							trigger_gamePanelInfo.selectedShopItem = -1
							trigger_gamePanelInfo.selectedShopItemType = ''
							trigger_gamePanelInfo:Trigger(false)
						end
					end

					lastItemClickTime = GetTime()
				else
					-- sound_craftingSelectRecipe2
					PlaySound('/ui/sounds/crafting/sfx_item_choose.wav')

					if LuaTrigger.GetTrigger('selection_Status').selectionSection == mainUI.Selection.selectionSections.SKILL_BUILDS then --build editing
						buildEditorAddItem(itemInfo[paramPrefix..'entity'])
					else
						craftingSelectRecipe(itemInfo[paramPrefix..'entity'])
					end
				end
			end)
		end

		local itemInfo = GetTrigger('ShopItem'..index)

		button:SetCallback('onmouseover', function(widget)

			shopItemTipShow(index, nil, isComponent, componentID)

			--local heroEntity = LuaTrigger.GetTrigger('HeroUnit').heroEntity
			

			if (hero == 'Hero_CapriceTutorial') then	
				widget:SetCursor('/core/cursors/right_click.cursor')
			else					
				UpdateCursor(widget, true, { canLeftClick = true, canRightClick = true, canDrag = true })
			end 
			

			if listBG then
				listBG:SetColor('#6d5d4a')
				listBG:SetBorderColor('#6d5d4a')
			end

			if listBGFrame then
				listBGFrame:SetColor('#121111')
				listBGFrame:SetBorderColor('#121111')
			end

			local needComponents = false

			for i=0,3,1 do
				if itemInfo['recipeComponentDetail'..i..'exists'] and not itemInfo['recipeComponentDetail'..i..'isOwned'] then
					needComponents = true
				end
			end

			gameShopUpdateGlowColor(innerGlow, outerFrame, shoppingIcon, true, itemInfo[paramPrefix..'isOnCourier'], itemInfo[paramPrefix..'isInStash'], itemInfo[paramPrefix..'isOwned'], itemInfo[paramPrefix..affordParam], recipeScroll, itemInfo.canAfford, needComponents)
		end)

		button:SetCallback('onmouseout', function(widget)
			shopItemTipHide()
			UpdateCursor(widget, false, { canLeftClick = true, canRightClick = true, canDrag = true })

			local needComponents = false

			for i=0,3,1 do
				if itemInfo['recipeComponentDetail'..i..'exists'] and not itemInfo['recipeComponentDetail'..i..'isOwned'] then
					needComponents = true
				end
			end

			gameShopUpdateGlowColor(innerGlow, outerFrame, shoppingIcon, false, itemInfo[paramPrefix..'isOnCourier'], itemInfo[paramPrefix..'isInStash'], itemInfo[paramPrefix..'isOwned'], itemInfo[paramPrefix..affordParam], needComponents)

			if listBG then
				listBG:SetColor('#4e453b')
				listBG:SetBorderColor('#4e453b')
			end

			if listBGFrame then
				listBGFrame:SetColor(0,0,0)
				listBGFrame:SetBorderColor(0,0,0)
			end
		end)

		button:SetCallback('onstartdrag', function(widget)
			local itemInfo = GetTrigger('ShopItem'..index)
			trigger_gamePanelInfo.shopLastBuyQueueDragged = -1
			trigger_gamePanelInfo.shopLastQuickSlotDragged = -1
			trigger_gamePanelInfo.shopDraggedItem = itemInfo[paramPrefix..'entity']
			trigger_gamePanelInfo.shopDraggedItemScroll	= recipeScroll
			trigger_gamePanelInfo.shopDraggedItemOwnedRecipe = (itemInfo.isOwned and itemInfo.isRecipe)

			local itemInfoDrag = LuaTrigger.GetTrigger('itemInfoDrag')
			itemInfoDrag.triggerName = 'ShopItem'
			itemInfoDrag.triggerIndex = index
			itemInfoDrag.type = 0
			itemInfoDrag.entityName = itemInfo[paramPrefix..'entity']
			itemInfoDrag:Trigger(false)

		end)

		globalDraggerRegisterSource(button, 4, 'gameDragLayer')

		local panelWheelUp			= scrollPanel:GetCallback('onmousewheelup')
		local panelWheelDown		= scrollPanel:GetCallback('onmousewheeldown')

		button:SetCallback('ondoubleclick', function(widget)
			local itemInfo = GetTrigger('ShopItem'..index)

			gameShopSetLastPurchaseSourceWidget(widget)

			if (not isComponent) and itemInfo.isRecipe and (not recipeScroll) then
				Shop.PurchaseRemainingComponents(itemInfo[paramPrefix..'entity'])
			else
				Shop.PurchaseByName(itemInfo[paramPrefix..'entity'])
			end
		end)

		button:SetCallback('onmousewheelup', function(widget)
			panelWheelUp(scrollPanel)

		end)
		button:SetCallback('onmousewheeldown', function(widget)
			panelWheelDown(scrollPanel)
		end)

		button:SetCallback('onrightclick', function(widget)
			local itemInfo = GetTrigger('ShopItem'..index)
			local triggerPhase	= LuaTrigger.GetTrigger('GamePhase')

			if triggerPhase.gamePhase >= 4 then
				if trigger_gamePanelInfo.mapWidgetVis_shopRightClick then
					gameShopSetLastPurchaseSourceWidget(widget)

					if itemInfo.isRecipe and (not recipeScroll) then
						if not (itemInfo.canAfford) and trigger_gamePanelInfo.selectedShopItem ~= index then
							trigger_gamePanelInfo.selectedShopItem = index
							trigger_gamePanelInfo.selectedShopItemType = ''
							trigger_gamePanelInfo:Trigger(false)
						end

						Shop.PurchaseRemainingComponents(itemInfo[paramPrefix..'entity'])
					else
						Shop.PurchaseByName(itemInfo[paramPrefix..'entity'])
					end
				end
			else
				if not isComponent then
					-- sound_craftingSelectRecipe
					PlaySound('/ui/sounds/crafting/sfx_item_choose.wav')
					if LuaTrigger.GetTrigger('selection_Status').selectionSection == mainUI.Selection.selectionSections.SKILL_BUILDS then --build editing
						buildEditorRemoveItem(itemInfo[paramPrefix..'entity'])
					else
						craftingSelectRecipe(itemInfo[paramPrefix..'entity'])
					end
				end

			end


		end)
	end

	local function updateItemCostStatus(widget, trigger, paramPrefix, isComponent, componentPrefix, iconImage)
		local isRecipe = false
		paramPrefix = paramPrefix or ''
		isComponent = isComponent or false
		local costValue = trigger[paramPrefix..'cost']
		local isLowered = false
		if not isComponent then
			isRecipe = trigger.isRecipe
			-- Subtract the cost of the owned components
			if GetCvarBool('ui_shop_useRemainingItemCost') then
				for i=0,2 do
					if trigger['recipeComponentDetail'..i..'exists'] and trigger['recipeComponentDetail'..i..'isOwned'] then
						costValue = costValue - trigger['recipeComponentDetail'..i..'cost']
						isLowered = true
					end
				end
			end
		end

		if trigger[paramPrefix..'isOwned'] then
			widget:SetText(Translate('general_owned'))
			widget:SetColor(0.8, 0.8, 0.8)
		elseif trigger[paramPrefix..'canAfford'] or shopInLauncher then
			widget:SetText(libNumber.commaFormat(costValue))
			if isLowered then
				widget:SetColor(1, 1, 0.3)
			else
				widget:SetColor(1, 1, 1)
			end
		else
			widget:SetText(libNumber.commaFormat(costValue))
			widget:SetColor(1, 0.5, 0.5)
		end
		
		if componentPrefix and paramPrefix == '' then
			if (not trigger[paramPrefix..'isOwned'] and isLowered) then
				-- Display the component container
				widget:GetWidget(componentPrefix):SetVisible(1)
				-- Find the number of components
				local components = 0
				for i=0,2 do
					if trigger['recipeComponentDetail'..i..'exists'] then
						components = components + 1
					end
				end
				-- Hide components indicators
				for i=1,4 do
					widget:GetWidget(componentPrefix..i):SetVisible(0)
				end
				-- Show existing component indicators
				for i=4-components,3 do
					local componentWidget = widget:GetWidget(componentPrefix..i)
					componentWidget:SetVisible(1)
					if (i == components) then
						componentWidget:SetColor("1 0 0 .8")
						componentWidget:SetRenderMode('normal')					
					elseif trigger['recipeComponentDetail'..(i-(4-components))..'isOwned'] then
						componentWidget:SetColor("1 1 1 1")
						componentWidget:SetRenderMode('normal')
					else
						componentWidget:SetColor("1 1 1 .8")
						componentWidget:SetRenderMode('grayscale')
					end
				end
				-- Recipe
				local componentWidget = widget:GetWidget(componentPrefix..(4))
				componentWidget:SetVisible(1)
				componentWidget:SetColor("1 1 1 .8")
				componentWidget:SetRenderMode('grayscale')				
				
			else
				widget:GetWidget(componentPrefix):SetVisible(0)
			end
		end
		
		if (iconImage and iconImage:IsValid()) then
			if isLowered then
				iconImage:SetTexture('/ui/shared/shop/textures/shop_hoverIcon_coins_minus.tga')
			else
				iconImage:SetTexture('/ui/shared/shop/textures/shop_hoverIcon_coins.tga')
			end
		end
	end
	
	local function registerItemListEntryDetailed(object, rowID, itemID)
		local infoTrigger			= GetTrigger('ShopItem'..itemID)
		local container				= object:GetWidget('gameShopItemListItem'..rowID)
		local icon					= object:GetWidget('gameShopItemListItem'..rowID..'Icon')
		local swap					= object:GetWidget('gameShopItemListItem'..rowID..'Swap')
		local swapLabel				= object:GetWidget('gameShopItemListItem'..rowID..'SwapLabel')
		local SwapClickLabelClick	= object:GetWidget('gameShopItemListItem'..rowID..'SwapClickLabelClick')
		local swapHover				= object:GetWidget('gameShopItemListItem'..rowID..'SwapHover')
		local name					= object:GetWidget('gameShopItemListItem'..rowID..'Name')
		local description			= object:GetWidget('gameShopItemListItem'..rowID..'Description')
		local cost					= object:GetWidget('gameShopItemListItem'..rowID..'Cost')
		local costIcon				= object:GetWidget('gameShopItemListItem'..rowID..'CostIcon')
		local costIconContainer		= object:GetWidget('gameShopItemListItem'..rowID..'CostIconContainer')
		local innerGlow				= object:GetWidget('gameShopItemListItem'..rowID..'InnerGlow')
		local outerFrame			= object:GetWidget('gameShopItemListItem'..rowID..'OuterFrame')
		local shoppingIcon			= object:GetWidget('gameShopItemListItem'..rowID..'ShoppingIcon')
		local canActivate			= object:GetWidget('gameShopItemListItem'..rowID..'CanActivate')


		icon:SetTexture(infoTrigger.icon)

		if infoTrigger.isOwned then
			icon:SetRenderMode('grayscale')
			name:SetColor('#999999')
			description:SetColor('#999999')
		else
			icon:SetRenderMode('normal')
			name:SetColor('#22EE33')
			description:SetColor('white')
		end
		container:SetVisible(infoTrigger.exists)

		canActivate:SetVisible(infoTrigger.isActivatable)

		SwapClickLabelClick:UnregisterWatchLua('slotSwapUpdatedTrigger')
		SwapClickLabelClick:RegisterWatchLua('slotSwapUpdatedTrigger', function(widget, trigger)
			local infoTable = GetBaseTable(itemID)
			if not infoTable then return end
			
			if infoTable.num > 1 then
				widget:SetVisible(true)
			else
				widget:SetVisible(false)
			end
		end)
		
		SwapClickLabelClick:SetCallback('onclick', function(widget)
			ShopUI.openItemSwapPopup(itemID, rowID)
		end)

		SwapClickLabelClick:SetCallback('onmouseover', function(widget)
			simpleTipGrowYUpdate(true, '/ui/elements:itemtype_crafted', Translate('game_shop_label_swapitems_title'), Translate('game_shop_label_swapitems_desc')) 
			swapHover:FadeIn(125)
		end)		
		
		SwapClickLabelClick:SetCallback('onmouseout', function(widget)
			simpleTipGrowYUpdate(false)
			swapHover:FadeOut(125)
		end)		
		
		swap:UnregisterWatchLua('slotSwapUpdatedTrigger')
		swap:RegisterWatchLua('slotSwapUpdatedTrigger', function(widget, trigger)
			canActivate:SetVisible(LuaTrigger.GetTrigger('ShopItem'..itemID).isActivatable)
			
			local infoTable = GetBaseTable(itemID)
			if not infoTable then return end
			
			if infoTable.num > 1 then
				widget:SetVisible(true)
				swapLabel:SetText(infoTable.num)
			else
				widget:SetVisible(false)
			end
		end)
		
		swap:SetCallback('onclick', function(widget)
			ShopUI.openItemSwapPopup(itemID, rowID)
		end)

		swap:SetCallback('onmouseover', function(widget)
			simpleTipGrowYUpdate(true, '/ui/elements:itemtype_crafted', Translate('game_shop_label_swapitems_title'), Translate('game_shop_label_swapitems_desc')) 
			swapHover:FadeIn(125)
		end)		
		
		swap:SetCallback('onmouseout', function(widget)
			simpleTipGrowYUpdate(false)
			swapHover:FadeOut(125)
		end)		
		
		swap:RefreshCallbacks()
		
		container:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger)
			widget:SetVisible(trigger.exists)
		end, false, fullItemWatchList, 'exists')

		icon:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger)
			widget:SetTexture(trigger.icon)

			if trigger.isOwned then
				icon:SetRenderMode('grayscale')
			else
				icon:SetRenderMode('normal')
			end
		end, false, fullItemWatchList, 'icon', 'isOwned')

		local function nameUpdate(widget, trigger)
			libThread.threadFunc(function()
				wait(1)
				local entityName		= trigger.entity
				if entityName and string.len(entityName) > 0 then

					local isRare			= false
					local isLegendary		= false

					local isCrafted			= trigger.isPlayerCrafted

					local rareBonus			= ''
					local legendaryBonus	= ''

					if (trigger.isRecipe) and isCrafted then
						rareBonus			= trigger.currentEmpoweredEffectDisplayName
						legendaryBonus	= trigger.legendaryDisplayName
						isRare		= (not Empty(trigger.currentEmpoweredEffectDisplayName))
						isLegendary	= trigger.isLegendary
					end

					local fullItemName = libGeneral.craftedItemFormatName(GetEntityDisplayName(entityName), isRare, rareBonus, isLegendary, legendaryBonus)
					local newFont = FitFontToLabel(widget, fullItemName, listViewFonts, true)
					--println('Fitting ' .. fullItemName .. ' into ' .. widget:GetWidth() .. ' decided on ' .. tostring(newFont))
					if not newFont then -- This will be a cut-off, if we don't seperate it.
						widget:SetFont('maindyn_11')
					end
					widget:SetText(fullItemName)

					if trigger.isOwned then
						widget:SetColor('#999999')
					elseif isCrafted then
						widget:SetColor(libGeneral.craftedItemGetNameColor(isRare, isRare))
					else
						widget:SetColor(style_crafting_tier_common_color)
					end

				end
			end)
		end
		
		local function descriptionUpdate(widget, trigger)
			libThread.threadFunc(function()
				wait(1)
				local entityDesc		= trigger.descriptionSimple
				if entityDesc and string.len(entityDesc) > 0 then
					widget:SetText(entityDesc)
					local estLines = estimateLines(widget, entityDesc, 'maindyn_11')
					if estLines > 2 then
						widget:SetFont('maindyn_10')
					elseif estLines > 1 then
						widget:SetFont('maindyn_11')
					else
						FitFontToLabel(widget, entityDesc, listViewFonts, true)
					end

					if trigger.isOwned then
						widget:SetColor('#999999')
					else
						widget:SetColor('white')
					end
				end
			end)
		end

		nameUpdate(name, infoTrigger)
		descriptionUpdate(description, infoTrigger)

		name:RegisterWatchLua('ShopItem'..itemID, nameUpdate, false, fullItemWatchList, 'entity', 'isOwned', 'isPlayerCrafted', 'isRare', 'isLegendary', 'rareDisplayName', 'legendaryDisplayName', 'currentEmpoweredEffectDisplayName', 'isRecipe')

		local componentsOwnedPrefix = "gameShopItemListItem"..rowID.."componentsOwned"
		updateItemCostStatus(cost, infoTrigger, nil, nil, componentsOwnedPrefix, costIcon)
		cost:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger) updateItemCostStatus(widget, trigger, nil, nil, componentsOwnedPrefix, costIcon) end, false, fullItemWatchList, 'cost', 'isOwned', 'isRecipe', 'canAfford','recipeComponentDetail0isOwned',
			'recipeComponentDetail0exists',
			'recipeComponentDetail1isOwned',
			'recipeComponentDetail1exists',
			'recipeComponentDetail2isOwned',
			'recipeComponentDetail2exists',
			'recipeComponentDetail3isOwned',
			'recipeComponentDetail3exists')

		costIconContainer:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger)
			widget:SetVisible((not trigger.isRecipe) or (not trigger.isOwned))
		end, false, fullItemWatchList, 'isOwned', 'isRecipe')

		-- object:GetWidget('gameShopItemListItem'..rowID..'CostIcon')
		description:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger)
			descriptionUpdate(widget, trigger)
		end, false, fullItemWatchList, 'descriptionSimple', 'isOwned')

		local button = object:GetWidget('gameShopItemListItem'..rowID..'Button')

		gameShopUpdateGlowColor(innerGlow, outerFrame, shoppingIcon, false, infoTrigger['isOnCourier'], infoTrigger['isInStash'], infoTrigger['isOwned'], infoTrigger['canAfford'])

		shoppingIcon:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger)
			gameShopUpdateGlowColor(innerGlow, outerFrame, shoppingIcon, (button:IsVisibleSelf() and libGeneral.mouseInWidgetArea(button)), trigger.isOnCourier, trigger.isInStash, trigger.isOwned, trigger.canAfford)
		end, false, fullItemWatchList, 'isOnCourier', 'isInStash', 'isOwned', 'canAfford')

		local listBG		= object:GetWidget('gameShopItemListItem'..rowID..'ListBG')
		local listBGGray		= object:GetWidget('gameShopItemListItem'..rowID..'ListBGGray')
		local listBGFrame	= object:GetWidget('gameShopItemListItem'..rowID..'ListBGFrame')

		listBGGray:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger)
			if trigger.isOwned then
				widget:SetVisible(true)
			else
				widget:SetVisible(false)
			end
		end, false, fullItemWatchList, 'isOwned')

		buttonRegisterActions(button, itemID, icon, nil, nil, innerGlow, outerFrame, shoppingIcon, listBG, listBGFrame)

	end

	local function registerItemListEntrySimple(object, prefix, rowID, subID, itemID, isComponent)
		prefix				= prefix or 'gameShopItemListRow'
		isComponent			= isComponent or false
		local paramPrefix	= ''

		local paramIcon		= 'icon'
		local paramExists	= 'exists'
		local paramOwned	= 'isOwned'
		local paramCost		= 'cost'

		local infoTrigger			= GetTrigger('ShopItem'..itemID)
		local container				= object:GetWidget(prefix..rowID..'Item'..subID)
		local body					= object:GetWidget(prefix..rowID..'Item'..subID..'Body')
		local icon					= object:GetWidget(prefix..rowID..'Item'..subID..'Icon')
		local cost					= object:GetWidget(prefix..rowID..'Item'..subID..'Cost')
		local costIcon				= object:GetWidget(prefix..rowID..'Item'..subID..'CostIcon')
		local costIconContainer		= object:GetWidget(prefix..rowID..'Item'..subID..'CostIconContainer')

		local innerGlow				= object:GetWidget(prefix..rowID..'Item'..subID..'InnerGlow')
		local outerFrame			= object:GetWidget(prefix..rowID..'Item'..subID..'OuterFrame')
		local shoppingIcon			= object:GetWidget(prefix..rowID..'Item'..subID..'ShoppingIcon')
		local canActivate			= object:GetWidget(prefix..rowID..'Item'..subID..'CanActivate')
		local moreInfo				= object:GetWidget(prefix..rowID..'Item'..subID..'MoreInfo')

		local button 				= object:GetWidget(prefix..rowID..'Item'..subID..'Button')
		local swap					= object:GetWidget(prefix..rowID..'Item'..subID..'Swap')
		local swapLabel				= object:GetWidget(prefix..rowID..'Item'..subID..'SwapLabel')
		local SwapClickLabelClick	= object:GetWidget(prefix..rowID..'Item'..subID..'SwapClickLabelClick')
		local swapHover				= object:GetWidget(prefix..rowID..'Item'..subID..'SwapHover')

		if isComponent then
			paramPrefix = 'recipeComponentDetail'..(subID - 1)

			buttonRegisterActions(button, itemID, icon, (subID - 1), nil, innerGlow, outerFrame, shoppingIcon)

			--[[
			cost:SetText(libNumber.commaFormat(infoTrigger[paramPrefix..paramCost]))

			cost:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger)
				widget:SetText(libNumber.commaFormat(trigger[paramPrefix..paramCost]))
			end, false, fullItemWatchSimple, paramPrefix..paramCost)
			--]]

			moreInfo:SetVisible(LuaTrigger.GetTrigger('ModifierKeyStatus').moreInfoKey)

			moreInfo:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
				widget:SetVisible(trigger.moreInfoKey)
			end, false, fullItemWatchSimple, 'moreInfoKey')

			costIconContainer:SetVisible(true)
		else

			moreInfo:SetVisible(false)
			buttonRegisterActions(button, itemID, icon, nil, nil, innerGlow, outerFrame, shoppingIcon)
			
			SwapClickLabelClick:UnregisterWatchLua('slotSwapUpdatedTrigger')
			SwapClickLabelClick:RegisterWatchLua('slotSwapUpdatedTrigger', function(widget, trigger)
				local infoTable = GetBaseTable(itemID)
				if not infoTable then return end
				
				if infoTable.num > 1 then
					widget:SetVisible(true)
				else
					widget:SetVisible(false)
				end
			end)
			
			SwapClickLabelClick:SetCallback('onclick', function(widget)
				ShopUI.openItemSwapPopup(itemID, rowID, subID)
			end)

			SwapClickLabelClick:SetCallback('onmouseover', function(widget)
				simpleTipGrowYUpdate(true, '/ui/elements:itemtype_crafted', Translate('game_shop_label_swapitems_title'), Translate('game_shop_label_swapitems_desc')) 
				swapHover:FadeIn(125)
			end)		
			
			SwapClickLabelClick:SetCallback('onmouseout', function(widget)
				simpleTipGrowYUpdate(false)
				swapHover:FadeOut(125)
			end)			
			
			swap:RegisterWatchLua('slotSwapUpdatedTrigger', function(widget, trigger)
				canActivate:SetVisible(LuaTrigger.GetTrigger('ShopItem'..itemID).isActivatable)
				
				local infoTable = GetBaseTable(itemID)
				if not infoTable then return end
				
				if infoTable.num > 1 then
					widget:SetVisible(true)
					swapLabel:SetText(infoTable.num)
				else
					widget:SetVisible(false)
				end
			end, false, fullItemWatchSimple)
			
			swap:SetCallback('onclick', function(widget)
				ShopUI.openItemSwapPopup(itemID, rowID, subID)
			end)
			
			swap:SetCallback('onmouseover', function(widget)
				simpleTipGrowYUpdate(true, '/ui/elements:itemtype_crafted', Translate('game_shop_label_swapitems_title'), Translate('game_shop_label_swapitems_desc'))
				swapHover:FadeIn(125)
			end)		
			
			swap:SetCallback('onmouseout', function(widget)
				simpleTipGrowYUpdate(false)
				swapHover:FadeOut(125)
			end)			
			
			costIconContainer:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger)
				widget:SetVisible((not trigger.isRecipe) or (not trigger.isOwned))
			end, false, fullItemWatchSimple, 'isOwned', 'isRecipe')

			container:SetVisible(infoTrigger[paramPrefix..paramExists])

			container:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger)
				widget:SetVisible(trigger[paramPrefix..paramExists])
			end, false, fullItemWatchSimple, paramPrefix..paramExists)
		end

		local componentsOwnedPrefix = "gameShopItemListRow"..rowID..'Item'..subID.."componentsOwned"
		updateItemCostStatus(cost, infoTrigger, paramPrefix, isComponent, componentsOwnedPrefix, costIcon)
		cost:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger) updateItemCostStatus(widget, trigger, paramPrefix, isComponent, componentsOwnedPrefix, costIcon) end, false, fullItemWatchSimple, paramPrefix..'cost', paramPrefix..'isOwned', 'isRecipe', paramPrefix..'canAfford','recipeComponentDetail0isOwned',
			'recipeComponentDetail0exists',
			'recipeComponentDetail1isOwned',
			'recipeComponentDetail1exists',
			'recipeComponentDetail2isOwned',
			'recipeComponentDetail2exists',
			'recipeComponentDetail3isOwned',
			'recipeComponentDetail3exists')

		local needComponents = false

		for i=0,3,1 do
			if infoTrigger['recipeComponentDetail'..i..'exists'] and not infoTrigger['recipeComponentDetail'..i..'isOwned'] then
				needComponents = true
			end
		end


		gameShopUpdateGlowColor(innerGlow, outerFrame, shoppingIcon, false, infoTrigger[paramPrefix..'isOnCourier'], infoTrigger[paramPrefix..'isInStash'], infoTrigger[paramPrefix..'isOwned'], infoTrigger[paramPrefix..'canAfford'], needComponents)

		shoppingIcon:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger)
			local needComponents = false

			for i=0,3,1 do
				if trigger['recipeComponentDetail'..i..'exists'] and not trigger['recipeComponentDetail'..i..'isOwned'] then
					needComponents = true
				end
			end

			gameShopUpdateGlowColor(innerGlow, outerFrame, shoppingIcon, (button:IsVisibleSelf() and libGeneral.mouseInWidgetArea(button)), infoTrigger[paramPrefix..'isOnCourier'], infoTrigger[paramPrefix..'isInStash'], infoTrigger[paramPrefix..'isOwned'], infoTrigger[paramPrefix..'canAfford'], needComponents)
		end, false, fullItemWatchSimple, paramPrefix..'isOnCourier', paramPrefix..'isInStash', paramPrefix..'isOwned', paramPrefix..'canAfford',
			'recipeComponentDetail0isOwned',
			'recipeComponentDetail0exists',
			'recipeComponentDetail1isOwned',
			'recipeComponentDetail1exists',
			'recipeComponentDetail2isOwned',
			'recipeComponentDetail2exists',
			'recipeComponentDetail3isOwned',
			'recipeComponentDetail3exists'
		)

		if infoTrigger[paramPrefix..paramExists] then
			icon:SetTexture(infoTrigger[paramPrefix..paramIcon])

			if infoTrigger[paramPrefix..paramOwned] then
				icon:SetRenderMode('grayscale')
			else
				icon:SetRenderMode('normal')
			end
		end

		icon:RegisterWatchLua('ShopItem'..itemID, function(widget, trigger)


			if paramPrefix..paramExists then
				widget:SetTexture(trigger[paramPrefix..paramIcon])

			end

			if trigger[paramPrefix..paramOwned] then
				icon:SetRenderMode('grayscale')
			else
				icon:SetRenderMode('normal')
			end

		end, false, fullItemWatchSimple, paramPrefix..paramIcon, paramPrefix..paramExists, paramPrefix..paramOwned)

	end
	
	function ShopUI.openItemSwapPopup(openedID, rowID, subID) -- Needs to be added to a table for visibility
		local parent = interface:GetWidget('gameShopItemItemChooser')
		local container = interface:GetWidget('gameShopItemSwapContainer')
		local scrollBarHider = interface:GetWidget('gameShopItemSwapContainerScrollHider');
		local infoTable = GetBaseTable(openedID)
		
		-- Show/hide scrollBar RMM this perhaps should be turned into a scrollbar
		scrollBarHider:SetVisible(infoTable.num < 7)
		
		-- Show popup
		parent:SetVisible(true)
		
		container:UICmd('SetVerticalListScroll(0)')

		-- Create item entries - it's worth noting, there could be >100 here, so dynamically instantiating makes sense.
		container:ClearItems()
		for i = 1, infoTable.num do
			local itemInfo = LuaTrigger.GetTrigger("ShopItem"..infoTable.indices[i])
			local component0Icon = (itemInfo.recipeComponentDetail0exists and itemInfo.recipeComponentDetail0icon) or "/ui/main/crafting/textures/component_blank.tga"
			local component1Icon = (itemInfo.recipeComponentDetail1exists and itemInfo.recipeComponentDetail1icon) or "/ui/main/crafting/textures/component_blank.tga"
			local component2Icon = (itemInfo.recipeComponentDetail2exists and itemInfo.recipeComponentDetail2icon) or "/ui/main/crafting/textures/component_blank.tga"
			
			local imbueDesc = itemInfo.currentEmpoweredEffectDisplayName
			local imbueIcon = '/ui/main/crafting/textures/imbue_icon_selected.tga'
			
			local labelColor = style_crafting_tier_legendary_color
			if imbueDesc == "" then
				imbueDesc = "game_shop_label_swapBaseItem"
				imbueIcon = "/ui/main/crafting/textures/imbue_icon.tga"
				labelColor = "0.8 0.8 0.8 1"
			else
				imbueIcon = '/ui/main/crafting/textures/imbue_icon_selected_' .. tonumber(string.sub(itemInfo.currentEmpoweredEffectEntityName, -1, -1))-1 .. '.tga'
			end
			
			container:AddTemplateListItem('gameShopItemSwapEntry', i,
			--container:Instantiate('gameShopItemSwapEntry', 
				'id', i, 
				'componentIcon1', component0Icon,
				'componentIcon2', component1Icon,
				'componentIcon3', component2Icon,
				'labelColor', labelColor,
				'imbueIcon', imbueIcon,
				'imbueDesc', imbueDesc,
				'cost', itemInfo.cost
			)
			
			local entry = interface:GetWidget('gameShopItemSwapEntry'..i)
			local button = interface:GetWidget('gameShopItemSwapEntry'..i..'Button')
			local selected = interface:GetWidget('gameShopItemSwapEntry'..i..'Selected')
			local frame = interface:GetWidget('gameShopItemSwapEntry'..i..'Frame')
			local imbueIcon = interface:GetWidget('gameShopItemSwapEntry'..i..'Item')
			local imbueDescWidget = interface:GetWidget('gameShopItemSwapEntry'..i..'Label')
			
			
			entry:SetCallback('onmouseout', function(widget)
				shopItemTipHide()
			end)
			entry:SetCallback('onmouseover', function(widget)
				shopItemTipShow(infoTable.indices[i])
			end)
			
			
			if infoTable.current == i then
				button:SetVisible(false)
				selected:SetVisible(true)
				frame:SetVisible(true)
			end
			
			-- Select item button
			libButton2.initializeButton(self, 'gameShopItemSwapEntry'..i..'Button', 'standardButton2', 'grayscale')
			button:SetCallback('onclick', function(widget)
				if (subID) then -- Tiles view
					rowData[rowID].subList[subID] = infoTable.indices[i]
					unregisterSub(interface, rowID, subID)
					registerItemListEntrySimple(interface, nil, rowID, subID, infoTable.indices[i]) --'gameShopItemSelectedRow'
				else -- List view
					unregisterRowItem(interface, rowID)
					registerItemListEntryDetailed(interface, rowID, infoTable.indices[i])
				end
				
				-- Make current selected and old not selected
				widget:SetVisible(false)
				selected:SetVisible(true)
				interface:GetWidget('gameShopItemSwapEntry'..infoTable.current..'Button'):SetVisible(true)
				interface:GetWidget('gameShopItemSwapEntry'..infoTable.current..'Selected'):SetVisible(false)
				
				-- Set our current item for this slot to this one.
				infoTable.current = i
				
				-- Set selected item to this, if one is selected
				if (trigger_gamePanelInfo.selectedShopItem >= 0) then
					trigger_gamePanelInfo.selectedShopItem				= infoTable.indices[i]
					trigger_gamePanelInfo.selectedShopItemType			= ''
					trigger_gamePanelInfo:Trigger(true)
				end
				
				-- Save this item as a default for use with this hero, if no guides say otherwise.
				local heroEntity = entityName or LuaTrigger.GetTrigger('ActiveUnit').heroEntity
				if Empty(heroEntity) then
					heroEntity = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName
				end
				local component0Name = (itemInfo.recipeComponentDetail0exists and itemInfo.recipeComponentDetail0displayName) or ""
				local component1Name = (itemInfo.recipeComponentDetail1exists and itemInfo.recipeComponentDetail1displayName) or ""
				local component2Name = (itemInfo.recipeComponentDetail2exists and itemInfo.recipeComponentDetail2displayName) or ""
				mainUI.savedLocally.lastBoughtItemsByHero[heroEntity][itemInfo.displayName] = {itemInfo.currentEmpoweredEffectEntityName, component0Name, component1Name, component2Name}
				
				-- Hide the popup
				parent:FadeOut(175)
			end)
		end
		
		container:UnregisterWatchLua("ShopItem"..rowID)
		container:RegisterWatchLua("ShopItem"..rowID, function(widget, trigger)
			if not selfTriggered then
				parent:SetVisible(false)
			end
		end, false, nil)
	end

	local function unregisterSelectedItemSub(object, rowID)
		local container
		local body
		local divider
		local dividerBody
		object:GetWidget('gameShopItemRow'..rowID..'SelectedContainer'):SetVisible(false)
		object:GetWidget('gameShopItemRow'..rowID..'SelectedBackerList'):FadeOut(175)
		object:GetWidget('gameShopItemRow'..rowID..'SelectedBackerSimple'):FadeOut(175)

		if trigger_gamePanelInfo.shopItemView == 0 then
			object:GetWidget('gameShopItemRow'..rowID):SetHeight(itemHeightSimple)
		else
			object:GetWidget('gameShopItemRow'..rowID):SetHeight(itemHeightList)
		end

		object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScrollBody'):SlideY('-100%', 175)
		object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScroll'):FadeOut(175)


		object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScroll'):UnregisterAllWatchLuaByKey(fullItemWatchSimple)

		for i=1,3,1 do
			container = object:GetWidget('gameShopItemSelectedRow'..rowID..'Item'..i)
			body = object:GetWidget('gameShopItemSelectedRow'..rowID..'Item'..i..'Body')

			container:UnregisterAllWatchLuaByKey(fullItemWatchSimple)

			body:SlideY('-100%', 175)
			container:FadeOut(175)

			if i > 1 then
				divider = object:GetWidget('gameShopItemSelectedRow'..rowID..'Item'..i..'Divider')
				dividerBody = object:GetWidget('gameShopItemSelectedRow'..rowID..'Item'..i..'DividerBody')
				divider:FadeOut(175)
				dividerBody:SlideY('-100%', 175)
				divider:UnregisterWatchLuaByKey(fullItemWatchSimple)
			end
		end
	end

	local function safeShowRow(index)
		local row = object:GetWidget('gameShopItemRow'..index)
		if not row:IsVisibleSelf() then
			row:SetVisible(true)
		end
	end

	local function safeHideRow(index)
		local row = object:GetWidget('gameShopItemRow'..index)
		if row:IsVisibleSelf() then
			row:SetVisible(false)
		end
	end

	local function registerSelectedItemSub(object, rowID, selectedItem)
		local selectedContainer	= object:GetWidget('gameShopItemRow'..rowID..'SelectedContainer')

		lastSelectedRow = rowID

		if not selectedContainer:IsVisibleSelf() then
			selectedContainer:SetVisible(true)
		end

		local selectedBackerList = object:GetWidget('gameShopItemRow'..rowID..'SelectedBackerList')
		local selectedBackerSimple = object:GetWidget('gameShopItemRow'..rowID..'SelectedBackerSimple')

		local subContainers	= {}

		if trigger_gamePanelInfo.shopItemView == 0 then
			object:GetWidget('gameShopItemRow'..rowID):SetHeight(itemHeightSimpleExpanded)
			selectedBackerSimple:SetVisible(false)
			selectedBackerSimple:SetHeight(libGeneral.HtoP(2))
			selectedBackerSimple:ScaleHeight(libGeneral.HtoP(11.0), 175)
			selectedBackerSimple:FadeIn(175)
			selectedBackerList:SetVisible(false)
			selectedContainer:SetY(libGeneral.HtoP(14.25))
			selectedContainer:SetHeight(libGeneral.HtoP(8.5))
		else
			object:GetWidget('gameShopItemRow'..rowID):SetHeight(itemHeightListExpanded)
			selectedBackerSimple:SetVisible(false)
			selectedBackerList:SetHeight(libGeneral.HtoP(5))
			selectedBackerList:ScaleHeight('+0.75h', 175)
			selectedBackerList:SetVisible(false)
			selectedBackerList:FadeIn(175)
			selectedContainer:SetY(libGeneral.HtoP(8.5))
			selectedContainer:SetHeight(libGeneral.HtoP(7))
		end

		local itemInfo = GetTrigger('ShopItem'..selectedItem)
		-- local recipeCost = itemInfo.cost

		local itemDivider
		local itemDividerBody

		local itemContainer
		local itemBody

		for i=1,3,1 do
			registerItemListEntrySimple(object, 'gameShopItemSelectedRow', rowID, i, selectedItem, true)
			itemContainer		= object:GetWidget('gameShopItemSelectedRow'..rowID..'Item'..i)
			itemBody			= object:GetWidget('gameShopItemSelectedRow'..rowID..'Item'..i..'Body')

			if i > 1 then
				itemDivider		= object:GetWidget('gameShopItemSelectedRow'..rowID..'Item'..i..'Divider')
				itemDividerBody	= object:GetWidget('gameShopItemSelectedRow'..rowID..'Item'..i..'DividerBody')
				if itemInfo['recipeComponentDetail'..(i - 1)..'exists'] then
					table.insert(subContainers, itemDivider)
					itemDividerBody:SetY('-100%')
					itemDividerBody:SlideY(0, 175)
					itemDivider:SetVisible(false)
					itemDivider:FadeIn(175)
				end
			end

			if itemInfo['recipeComponentDetail'..(i - 1)..'exists'] then
				table.insert(subContainers, itemContainer)
				itemBody:SetY('-100%')
				itemBody:SlideY(0, 175)
				itemContainer:SetVisible(false)
				itemContainer:FadeIn(175)

			end

			--[[
			if itemInfo['recipeComponentDetail'..(i - 1)..'exists'] then
				recipeCost = recipeCost - itemInfo['recipeComponentDetail'..(i - 1)..'cost']
			end
			--]]
		end

		local scroll = object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScroll')

		local scrollDivider = object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScrollDivider')

		table.insert(subContainers, scrollDivider)
		table.insert(subContainers, scroll)


		scrollDivider:SetVisible(false)
		scrollDivider:FadeIn(175)

		scroll:SetVisible(false)
		scroll:FadeIn(175)

		local scrollBody = object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScrollBody')
		local scrollDividerBody = object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScrollDividerBody')
		scrollBody:SetY('-100%')
		scrollBody:SlideY(0, 175)

		scrollDividerBody:SetY('-100%')
		scrollDividerBody:SlideY(0, 175)

		local icon = object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScrollIcon')

		icon:SetTexture(itemInfo.icon)

		local function iconScrollUpdate(widget, trigger)
			trigger = trigger or LuaTrigger.GetTrigger('ShopItem'..selectedItem)

			local needComponents = false

			for i=0,3,1 do
				if trigger['recipeComponentDetail'..i..'exists'] and not trigger['recipeComponentDetail'..i..'isOwned'] then
					needComponents = true
				end
			end

			if needComponents then
				widget:SetRenderMode('grayscale')
				widget:SetColor(0.5, 0.5, 0.5)
			else
				widget:SetRenderMode('normal')
				widget:SetColor(1,1,1)
			end
			-- not factoring in canAfford atm
		end

		local scrollOverlay = object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScrollScrollOverlay')

		iconScrollUpdate(icon)
		iconScrollUpdate(scrollOverlay)

		icon:RegisterWatchLua('ShopItem'..selectedItem, iconScrollUpdate, false, fullItemWatchSimple,'canAfford',
			'recipeComponentDetail0isOwned',
			'recipeComponentDetail0exists',
			'recipeComponentDetail1isOwned',
			'recipeComponentDetail1exists',
			'recipeComponentDetail2isOwned',
			'recipeComponentDetail2exists',
			'recipeComponentDetail3isOwned',
			'recipeComponentDetail3exists'
		)
		scrollOverlay:RegisterWatchLua('ShopItem'..selectedItem, iconScrollUpdate, false, fullItemWatchSimple, 'canAfford',
			'recipeComponentDetail0isOwned',
			'recipeComponentDetail0exists',
			'recipeComponentDetail1isOwned',
			'recipeComponentDetail1exists',
			'recipeComponentDetail2isOwned',
			'recipeComponentDetail2exists',
			'recipeComponentDetail3isOwned',
			'recipeComponentDetail3exists'
		)

		local scrollCost = object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScrollCost')

		local function updateScrollCost(widget, trigger)
			trigger = trigger or LuaTrigger.GetTrigger('ShopItem'..selectedItem)

			local needComponents = false

			for i=0,3,1 do
				if trigger['recipeComponentDetail'..i..'exists'] and not trigger['recipeComponentDetail'..i..'isOwned'] then
					needComponents = true
				end
			end

			if trigger.isOwned then
				if trigger.isRecipe then
					widget:SetText(Translate('general_owned'))
					widget:SetColor(0.8, 0.8, 0.8)
				else
					widget:SetText(libNumber.commaFormat(trigger.recipeScrollCost))
					widget:SetColor(1, 1, 1)
				end
			elseif needComponents then
				-- widget:SetText(Translate('game_shop_recipe_needcomponents_short'))
				widget:SetText(libNumber.commaFormat(trigger.recipeScrollCost))
				widget:SetColor(0.5, 0.5, 0.5)
			elseif (not trigger.canAfford) then
				widget:SetText(libNumber.commaFormat(trigger.recipeScrollCost))
				widget:SetColor(1, 0.5, 0.5)
			else
				widget:SetText(libNumber.commaFormat(trigger.recipeScrollCost))
				widget:SetColor(1, 1, 1)
			end
		end

		updateScrollCost(scrollCost)

		scrollCost:RegisterWatchLua('ShopItem'..selectedItem, updateScrollCost, false, fullItemWatchSimple,
			'isRecipe', 'isOwned', 'recipeScrollCost', 'recipeScrollCanAfford', 'canAfford',
			'recipeComponentDetail0isOwned',
			'recipeComponentDetail0exists',
			'recipeComponentDetail1isOwned',
			'recipeComponentDetail1exists',
			'recipeComponentDetail2isOwned',
			'recipeComponentDetail2exists',
			'recipeComponentDetail3isOwned',
			'recipeComponentDetail3exists'
		)

		buttonRegisterActions(object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScrollButton'), selectedItem, icon, nil, true,
			object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScrollInnerGlow'),
			object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScrollOuterFrame'),
			object:GetWidget('gameShopItemSelectedRow'..rowID..'ItemScrollShoppingIcon')
		)

		local floatPadding = libGeneral.HtoP(1.75)

		if (
			(trigger_gamePanelInfo.shopView == 1 and (not trigger_gamePanelInfo.abilityPanel) and ((trigger_gamePanelInfo.shopShowFilters and trigger_gamePanelInfo.shopHasFiltersToDisplay) or trigger_gamePanelInfo.shopCategory == '' or trigger_gamePanelInfo.shopCategory == 'components')) -- showFilters
		) then

			if trigger_gamePanelInfo.shopItemView == 0 then
				floatPadding = libGeneral.HtoP(0)
			else
				floatPadding = libGeneral.HtoP(0.5)
			end

		end

		local newWidth = libGeneral.floatRight(subContainers, floatPadding, true, nil, 175)

		selectedContainer:SlideX( (selectedContainer:GetParent():GetWidth() - newWidth) / 2, 175, true )
	end

	local function updateRowSub(object, index, subList)
		local oldSubList
		if rowData[index] then
			oldSubList = rowData[index].subList
		end
		if index then
			if subList then
				for i=1,itemsPerRowMax,1 do

					if not (oldSubList and oldSubList[i] == subList[i]) then	-- No match or no old
						unregisterSub(object, index, i)
						if subList[i] then
							registerItemListEntrySimple(object, nil, index, i, subList[i])
						end
					end
				end
				rowData[index].subList = subList
			else
				for i=1,itemsPerRowMax,1 do
					unregisterSub(object, index, i)

				end
				rowData[index].subList = nil
			end
		end
	end

	local function updateRowData(object, index, rowInfo)
		if index then
			if rowInfo then
				if rowInfo.itemID then
					safeShowRow(index)
					if rowInfo.itemID ~= rowData[index].itemID then
						unregisterRowItem(object, index)
						if rowInfo.itemID then
							registerItemListEntryDetailed(object, index, rowInfo.itemID)
						end
					end
					updateRowSub(object, index)	-- Clears
					rowData[index] = rowInfo
				elseif rowInfo.subList and #rowInfo.subList > 0 then
					safeShowRow(index)
					unregisterRowItem(object, index)
					updateRowSub(object, index, rowInfo.subList)
					rowData[index] = rowInfo
				else	-- No list item and no subs (empty row)
					safeHideRow(index)
					rowData[index] = {}
					unregisterRowItem(object, index)
					updateRowSub(object, index)	-- Clears
				end
			else	-- No row info at all, clear row entirely
				rowData[index] = {}
				unregisterRowItem(object, index)
				updateRowSub(object, index)	-- Clears
				safeHideRow(index)
			end
		else	-- Should never happen, output a warning
			print('no index for row with rowInfo of '..tostring(rowInfo)..'\n')
		end
	end

	local function updateRowDataSelectedID(object)
		for rowID, rowContents in ipairs(rowData) do
			-- Deals with multiple items in slots
			
			local selected = trigger_gamePanelInfo.selectedShopItem
			local ID = rowContents.itemID
			
			if trigger_gamePanelInfo.shopItemView ~= 0 and ID then
				ID = GetCurrentItem(ID)
			end
			
			if ID == selected then
				-- Expand swap icon, move the label etc
				object:GetWidget('gameShopItemListItem'..rowID..'SwapClickLabel'):FadeIn(125)
				-- object:GetWidget('gameShopItemListItem'..rowID..'SwapIcon'):Scale("133%", "133%", 300)
				-- local label = object:GetWidget('gameShopItemListItem'..rowID..'SwapLabel')
				-- label:SlideX('2.0h', 300)
				-- label:SlideY('0.9h', 300)
				-- label:SetFont('maindyn_14')
				
				rowContents.selectedID = trigger_gamePanelInfo.selectedShopItem
				if rowID <= ShopUI.maxRows then
					for i=1,4,1 do
						object:GetWidget('gameShopItemListRow'..rowID..'Item'..i..'SelectedBacker'):SetVisible(false)
					end
				end
			elseif rowContents.subList and type(rowContents.subList) == 'table' and #rowContents.subList > 0 then
				rowContents.selectedID = nil
				for subIndex, subItemID in ipairs(rowContents.subList) do
					if subItemID == selected then
						-- Expand swap icon, move the label etc
						object:GetWidget('gameShopItemListRow'..rowID..'Item'..subIndex..'SwapClickLabel'):FadeIn(125)
						-- object:GetWidget('gameShopItemListRow'..rowID..'Item'..subIndex..'SwapIcon'):Scale("133%", "133%", 300)
						-- local label = object:GetWidget('gameShopItemListRow'..rowID..'Item'..subIndex..'SwapLabel')
						-- label:SlideX('2.6h', 300)
						-- label:SlideY('1.3h', 300)
						-- label:SetFont('maindyn_18')
						
						rowContents.selectedID = trigger_gamePanelInfo.selectedShopItem
						object:GetWidget('gameShopItemListRow'..rowID..'Item'..subIndex..'SelectedBacker'):SetVisible(true)
					else
						object:GetWidget('gameShopItemListRow'..rowID..'Item'..subIndex..'SelectedBacker'):SetVisible(false)
						-- Reset swap icon and label
						object:GetWidget('gameShopItemListRow'..rowID..'Item'..subIndex..'SwapClickLabel'):FadeOut(125)
						-- object:GetWidget('gameShopItemListRow'..rowID..'Item'..subIndex..'SwapIcon'):Scale("100%", "100%", 300)
						-- local label = object:GetWidget('gameShopItemListRow'..rowID..'Item'..subIndex..'SwapLabel')
						-- label:SlideX('2h', 300)
						-- label:SlideY('1h', 300)
						-- label:SetFont('maindyn_14')
					end
				end
			else
				-- Reset swap icon and label
				object:GetWidget('gameShopItemListItem'..rowID..'SwapClickLabel'):FadeOut(125)
				-- object:GetWidget('gameShopItemListItem'..rowID..'SwapIcon'):Scale("100%", "100%", 300)
				-- local label = object:GetWidget('gameShopItemListItem'..rowID..'SwapLabel')
				-- label:SlideX('1.4h', 300)
				-- label:SlideY('0.5h', 300)
				-- label:SetFont('maindyn_12')
				
				if rowID <= ShopUI.maxRows then
					for i=1,4,1 do
						object:GetWidget('gameShopItemListRow'..rowID..'Item'..i..'SelectedBacker'):SetVisible(false)
					end
				end

				rowContents.selectedID = nil
			end

			if rowContents.selectedID then
				unregisterSelectedItemSub(object, rowID)
				registerSelectedItemSub(object, rowID, rowContents.selectedID)

			else
				unregisterSelectedItemSub(object, rowID)
			end
		end

	end

	function gameShopUpdateRowDataSelectedID(object)
		updateRowDataSelectedID(object)
	end

	local swappedMinimap = false -- whether it has been initially moved
	local function buildRowData(object, itemList)	-- Build the data structure for populateList
		local rowInfo
		local dataIndex	 = 0
		local subSelectedBacker

		local shopCategory = trigger_gamePanelInfo.shopCategory
		local filtersVisible = (trigger_gamePanelInfo.shopView == 1 and (not trigger_gamePanelInfo.abilityPanel) and ((trigger_gamePanelInfo.shopShowFilters and trigger_gamePanelInfo.shopHasFiltersToDisplay) or trigger_gamePanelInfo.shopCategory == '' or trigger_gamePanelInfo.shopCategory == 'components')) -- showFilters
		local floatPadding = libGeneral.HtoP(2.6)
		if filtersVisible then
			itemsPerRow = 3
			floatPadding = libGeneral.HtoP(1.5)
		else
			itemsPerRow = 4
		end

		local doneItems = {} -- Contains item names, and the first index which contained it.
		ShopUI.numItemsInSlot = {} -- Reset our array of items

		if trigger_gamePanelInfo.shopItemView == 0 then	-- Simple View
			local newRowWidth
			local subContainers = {}
			local rowSubContainer
			rowInfo = { subList = {} }

			local rowIndex = 0
			for i=1,#itemList,1 do
			
				local itemInfo = LuaTrigger.GetTrigger('ShopItem'..itemList[i])
				local name = itemInfo.displayName
				local extendedname = itemInfo.currentEmpoweredEffectEntityName
				local isPlayerCrafted = itemInfo.isPlayerCrafted
				if doneItems[name] == nil then
					-- Different item code
					doneItems[name] = itemList[i]
					ShopUI.numItemsInSlot[itemList[i]] = {num=1, current=1, indices={itemList[i]}, name=name, extendedName=extendedname,
						component1=(itemInfo.recipeComponentDetail0exists and itemInfo.recipeComponentDetail0displayName) or "",
						component2=(itemInfo.recipeComponentDetail1exists and itemInfo.recipeComponentDetail1displayName) or "",
						component3=(itemInfo.recipeComponentDetail2exists and itemInfo.recipeComponentDetail2displayName) or "",
						isPlayerCrafted=isPlayerCrafted
					} -- New item, so it's current for now. There may be more items, which increase num.
				
					rowIndex = rowIndex + 1
					rowInfo.subList[rowIndex] = itemList[i]

					if itemList[i] == trigger_gamePanelInfo.selectedShopItem then
						rowInfo.selectedID = itemList[i]
					end

					if rowIndex >= itemsPerRow then
						dataIndex = dataIndex + 1

						for i=1,#rowInfo.subList,1 do
							table.insert(subContainers, object:GetWidget('gameShopItemListRow'..dataIndex..'Item'..i))
						end
						updateRowData(object, dataIndex, rowInfo)

						rowInfo = { subList = {} }

						rowIndex = 0

						rowSubContainer = object:GetWidget('gameShopItemRow'..dataIndex..'SubContainer')


						newRowWidth = libGeneral.floatRight(subContainers, floatPadding, false, nil)
						rowSubContainer:SetWidth(newRowWidth)
						-- rowSubContainer:SetX( (rowSubContainer:GetParent():GetWidth() - newRowWidth) / 2 )

						subContainers = {}
					end
				else
					-- There is now one more entity in the slot.
					-- Insert this item/index to the entry for this item
					ShopUI.numItemsInSlot[doneItems[name]].num = ShopUI.numItemsInSlot[doneItems[name]].num + 1
					tinsert(ShopUI.numItemsInSlot[doneItems[name]].indices, itemList[i])
					ShopUI.numItemsInSlot[itemList[i]] = {baseItem=doneItems[name], name=name, extendedName=extendedname, -- Point to the base item
						component1=(itemInfo.recipeComponentDetail0exists and itemInfo.recipeComponentDetail0displayName) or "",
						component2=(itemInfo.recipeComponentDetail1exists and itemInfo.recipeComponentDetail1displayName) or "",
						component3=(itemInfo.recipeComponentDetail2exists and itemInfo.recipeComponentDetail2displayName) or "",
						isPlayerCrafted=isPlayerCrafted
					}
					-- If it's a crafted item, set current to this one (This likely won't last, it is overridden by last used by hero, guides, and session selected)
					if extendedname ~= "" then
						ShopUI.numItemsInSlot[doneItems[name]].current = ShopUI.numItemsInSlot[doneItems[name]].num
					end
				end
			end
			if #rowInfo.subList > 0 then	-- Flush last item
				dataIndex = dataIndex + 1

				for i=1,#rowInfo.subList,1 do
					table.insert(subContainers, object:GetWidget('gameShopItemListRow'..dataIndex..'Item'..i))
				end

				rowSubContainer = object:GetWidget('gameShopItemRow'..dataIndex..'SubContainer')

				updateRowData(object, dataIndex, rowInfo)

				newRowWidth = libGeneral.floatRight(subContainers, floatPadding, false, nil)
				rowSubContainer:SetWidth(newRowWidth)
				-- rowSubContainer:SetX( (rowSubContainer:GetParent():GetWidth() - newRowWidth) / 2 )

			end
		else	-- List view
			for i=1,#itemList,1 do
				-- Filter out crafted items, while keeping indexes in-tact
				local itemInfo = LuaTrigger.GetTrigger('ShopItem'..itemList[i])
				local name = itemInfo.displayName
				local extendedname = itemInfo.currentEmpoweredEffectEntityName
				local isPlayerCrafted = itemInfo.isPlayerCrafted
				if doneItems[name] == nil then
					-- Different item code
					dataIndex = dataIndex + 1
					doneItems[name] = itemList[i]
					ShopUI.numItemsInSlot[itemList[i]] = {num=1, current=1, indices={itemList[i]}, name=name, extendedName=extendedname, slot=dataIndex,
						component1=(itemInfo.recipeComponentDetail0exists and itemInfo.recipeComponentDetail0displayName) or "",
						component2=(itemInfo.recipeComponentDetail1exists and itemInfo.recipeComponentDetail1displayName) or "",
						component3=(itemInfo.recipeComponentDetail2exists and itemInfo.recipeComponentDetail2displayName) or "",
						isPlayerCrafted=isPlayerCrafted
					} -- New item, so it's default for now. There may be more items, which increase num.
					
					rowInfo = {
						itemID = itemList[i]
					}
					if itemList[i] == trigger_gamePanelInfo.selectedShopItem then
						rowInfo.selectedID = itemList[i]
					end
					--updateRowData(object, dataIndex, rowInfo)
				else
					-- There is now one more entity in the slot.
					-- Insert this item/index to the entry for this item
					ShopUI.numItemsInSlot[doneItems[name]].num = ShopUI.numItemsInSlot[doneItems[name]].num + 1
					tinsert(ShopUI.numItemsInSlot[doneItems[name]].indices, itemList[i])
					ShopUI.numItemsInSlot[itemList[i]] = {baseItem=doneItems[name], name=name, extendedName=extendedname, -- Point to the base item
						component1=(itemInfo.recipeComponentDetail0exists and itemInfo.recipeComponentDetail0displayName) or "",
						component2=(itemInfo.recipeComponentDetail1exists and itemInfo.recipeComponentDetail1displayName) or "",
						component3=(itemInfo.recipeComponentDetail2exists and itemInfo.recipeComponentDetail2displayName) or "",
						isPlayerCrafted=isPlayerCrafted
					}
					-- If it's a crafted item, set current to this one (This likely won't last, it is overridden by last used by hero, guides, and session selected)
					if extendedname ~= "" then
						ShopUI.numItemsInSlot[doneItems[name]].current = ShopUI.numItemsInSlot[doneItems[name]].num
					end
				end
			end
		end
		
		-- Sort out what the initial items in the slots should be. In order of least to most important:
		-- 1: Whichever random order they come here in. (done already)
		-- 2: The item last chosen by this hero
		local heroEntity = entityName or LuaTrigger.GetTrigger('ActiveUnit').heroEntity
		if Empty(heroEntity) then
			heroEntity = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName
		end
		if (not mainUI.savedLocally.lastBoughtItemsByHero) then
			mainUI.savedLocally.lastBoughtItemsByHero = {}
		end
		if (not mainUI.savedLocally.lastBoughtItemsByHero[heroEntity]) then
			mainUI.savedLocally.lastBoughtItemsByHero[heroEntity] = {}
		end
		for k,v in pairs(ShopUI.numItemsInSlot) do
			local localArray = mainUI.savedLocally.lastBoughtItemsByHero[heroEntity][v.name]
			if localArray and v.extendedName == localArray[1]
				and v.component1 == localArray[2]
				and v.component2 == localArray[3]
				and v.component3 == localArray[4] then
				local baseTable = GetBaseTable(k)
				for m = 1, baseTable.num do -- Find our item in the indices, and set current to it.
					if baseTable.indices[m] == k then
						baseTable.current = m
						break
					end
				end
			end
		end
		
		-- 3: RMM Whatever the guide says, if there is an exact match.
		
		
		-- 4: RMM Items selected this session will be top
		
		-- Fix for recommended tab, which shouldn't show all crafted items, rather, just crafted items where the base item is also present.
		if (trigger_gamePanelInfo.shopCategory == "crafted+itembuild") then -- Recommended tab
			-- Basically, with our new knowledge, we re-build all the arrays which display the shop
			dataIndex = 0
			rowData = {} -- reset row data too
			for n = 1, 100 do rowData[n] = {} end
			
			for k,v in pairs(ShopUI.numItemsInSlot) do
				if (not v.baseItem) then -- Base item
					-- See if the item has it's normal form in this menu
					local hasBasicItem = false
					for n = 1, v.num do
						if not ShopUI.numItemsInSlot[v.indices[n]].isPlayerCrafted then
							hasBasicItem = true
							break
						end
					end
					-- If not, seek and destroy! We don't want it here!
					if not hasBasicItem then 
						for n = 1, v.num do
							ShopUI.numItemsInSlot[v.indices[n]] = nil -- Nil all values of the item without it's basic form.
						end
					else
						-- We want this item, add it to the arrays
						dataIndex = dataIndex + 1
						v.slot = dataIndex
						-- Update all others to point to this
						for n = 1, v.num do
							if (not v.indices[n] == k) then
								ShopUI.numItemsInSlot[v.indices[n] ].baseItem = k
							end
						end
						
						-- Fix the rowData if in tiled view
						if trigger_gamePanelInfo.shopItemView == 0 then	-- Simple View
							local col = (dataIndex-1)%itemsPerRow + 1
							local row = floor((dataIndex-1)/itemsPerRow) + 1
							if not rowData[row].subList then
								updateRowData(object, row, nil)
								rowData[row] = {subList={}}
							end
							rowData[row].subList[col] = k
							updateRowData(object, row, rowData[row])
						end
					end
				end
			end
			-- Clean up: If in tile view, clear any rows the last one.
			if trigger_gamePanelInfo.shopItemView == 0 then
				dataIndex = floor(dataIndex/itemsPerRow) + 1
			end
		end
		
		-- Update items to show their current ones
		if trigger_gamePanelInfo.shopItemView ~= 0 then
			for k,v in pairs(ShopUI.numItemsInSlot) do
				if not v.baseItem then -- This is the base item
					updateRowData(object, v.slot, {itemID = v.indices[v.current]})
				end
			end
		end
		-- Fix the rowData array
		for n = 1, #rowData do
			if not rowData[n].subList then break end
			for o = 1, #rowData[n].subList do
				local slotInfo = ShopUI.numItemsInSlot[rowData[n].subList[o] ]
				if slotInfo and slotInfo.indices then
					rowData[n].subList[o] = slotInfo.indices[slotInfo.current]
					unregisterSub(interface, n, o)
					registerItemListEntrySimple(interface, nil, n, o, slotInfo.indices[slotInfo.current])
				end
			end
		end
		
		

		lastValidRow = dataIndex


		for i=(dataIndex + 1),ShopUI.maxItems+1,1 do	-- Clear remainder
			updateRowData(object, i, nil)
		end
		
		-- Flip shop and stash initially
		if not swappedMinimap then
			swappedMinimap = true
			checkMinimapSide()
			libThread.threadFunc(function()
				wait(1) -- removes nasty cross-screen shop movement.
				LuaTrigger.GetTrigger('shopVisControls'):Trigger(true)
			end)
		end
		slotSwapUpdatedTrigger:Trigger()
	end

	local scrollRegistry = {}

	libScrollShop2	= createLibScroll(scrollRegistry)

	local shopItemContainers	= {}

	for i=1,ShopUI.maxItems+1,1 do
		shopItemContainers[i] = object:GetWidget('gameShopItemRow'..i)
	end

	libScrollShop2.register(
		'gameShopItemList',
		shopItemContainers,
		{
			scrollbar		= scrollBar,
			scrollPanel		= scrollPanel,
			scrollArea		= object:GetWidget('gameShopItemList'),
			itemContainer	= object:GetWidget('gameShopItemListBody')
		},
		'simpleSmooth',
		{
			slideTime		= 100,
			entryPadding	= function()
				if trigger_gamePanelInfo.shopItemView == 1 then
					return itemPaddingList
				else
					return itemPaddingSimple
				end
			end,
			alwaysShowBar	= true,
			entrySize		= function(slotID)
				if trigger_gamePanelInfo.shopItemView == 1 then
					if rowData[slotID].selectedID then
						return itemHeightListExpanded
					end
					return itemHeightList
				else
					if rowData[slotID].selectedID then
						return itemHeightSimpleExpanded
					end
					return itemHeightSimple
				end
			end
			--[[,
			onScrollFunc	= function(scrollInfo)
			end
			--]]
		}
	)
	
	-- Intercept the scroll functions, because crafting isn't allowed to scroll.
	local oldUpFunc = scrollPanel:GetCallback('onmousewheelup')
	scrollPanel:SetCallback('onmousewheelup', function()
		local triggerNPE = LuaTrigger.GetTrigger('newPlayerExperience')
		local triggerMain = LuaTrigger.GetTrigger('mainPanelStatus')
		if not (triggerNPE and triggerMain and triggerMain.main == 1 and triggerNPE.craftingIntroProgress == 0 and triggerNPE.craftingIntroStep == 0) then
			oldUpFunc()
		end
	end)
	
	local oldDownFunc = scrollPanel:GetCallback('onmousewheeldown')
	scrollPanel:SetCallback('onmousewheeldown', function()
		local triggerNPE = LuaTrigger.GetTrigger('newPlayerExperience')
		local triggerMain = LuaTrigger.GetTrigger('mainPanelStatus')
		if not (triggerNPE and triggerMain and triggerMain.main == 1 and triggerNPE.craftingIntroProgress == 0 and triggerNPE.craftingIntroStep == 0) then
			oldDownFunc()
		end
	end)
	
	

	scrollBar:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		local selectedShopItem	= trigger.selectedShopItem
		updateRowDataSelectedID(object)

		if selectedShopItem >= 0 then
			local shopItemTrigger = LuaTrigger.GetTrigger('ShopItem'..selectedShopItem)
			if shopItemTrigger then
				if shopItemTrigger.entity then
					widget:UICmd("SendScriptMessage('shopSelectedItemEntity', '"..shopItemTrigger.entity.."')")
				end
			end

		end
		if selectedShopItem ~= lastSelectedItem then	-- change (has to only occur on change to prevent sound spam, etc.)
			if selectedShopItem >= 0 then	-- open
				-- sound_selectedItemOpen
				if Shop.GetVisible() then
					PlaySound('ui/sounds/shop/sfx_item_select.wav')
				end
			else	-- close
				-- sound_selectedItemClose
				-- PlaySound('/path_to/filename.wav')
			end
		end

		local scrollPos = nil

		if lastSelectedItem < 0 and scrollBar:GetMaxValue() > 0 and (lastValidRow - (scrollBar:GetMaxValue() - scrollBar:GetValue())) == lastSelectedRow then
			scrollPos = scrollBar:GetValue() + 1
			-- This solution is not required if the last selected item was > -1, but we're not currently recording that!
		end

		lastSelectedItem = selectedShopItem


		libScrollShop2.updatePosData(
			libScrollShop2.getScrollInfo('gameShopItemList'), false, scrollPos, true, false -- (lastValidRow == lastSelectedRow)
		)
	end, false, nil, 'selectedShopItem')

	container:RegisterWatchLua('shopItemListParams', function(widget, trigger)
		container:Sleep(1, function()
			itemList		= {}
			local shopItemView = triggershopItemView
			trigger_gamePanelInfo:Trigger(false)

			buildItemList(itemList, trigger)
			buildRowData(widget, itemList)

			updateRowHeight(object)

			updateRowDataSelectedID(object)

			libScrollShop2.updatePosData(
				libScrollShop2.getScrollInfo('gameShopItemList'), false, 0, true
			)
		end)

	end)

end	-- End gameShopRegisterItemList



-- ==================================================================
-- ==================================================================

local function gameShopRegisterViewTab(object, name, index, isAbilities)
	isAbilities = isAbilities or false
	local button		= object:GetWidget('gameShopTab'..name..'Button')
	local label			= object:GetWidget('gameShopTab'..name..'Label')
	local trigger_gamePanelInfo		= GetTrigger('gamePanelInfo')

	if isAbilities then

		button:SetCallback('onmouseover', function(widget)
			if trigger_gamePanelInfo.abilityPanel then
				label:SetFont('maindyn_18')
				label:SetColor(1,1,1)
			else
				label:SetFont('maindyn_18')
				label:SetColor(1,1,1)
			end
			UpdateCursor(button, true, { canLeftClick = true})
		end)

		button:SetCallback('onmouseout', function(widget)
			if trigger_gamePanelInfo.abilityPanel then
				label:SetFont('maindyn_18')
				label:SetColor(1,1,1)
			else
				label:SetFont('maindyn_18')
				label:SetColor(0.7, 0.7, 0.7)
			end
			UpdateCursor(button, false, { canLeftClick = true})
		end)

		button:RefreshCallbacks()

		label:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
			if trigger.abilityPanel then
				label:SetFont('maindyn_18')
				label:SetColor(1,1,1)
			else
				label:SetFont('maindyn_18')
				label:SetColor(0.7, 0.7, 0.7)
			end
		end, false, nil, 'abilityPanel')

		button:SetCallback('onclick', function(widget)
			gameToggleShowSkills(button, true)	-- Keep open
			--[[
			local panelInfo = GetTrigger('gamePanelInfo')
			panelInfo.abilityPanel = true
			panelInfo:Trigger(false)
			--]]
		end)
	else

		button:SetCallback('onmouseover', function(widget)
			if (trigger_gamePanelInfo.shopView == index and not trigger_gamePanelInfo.abilityPanel) then
				label:SetFont('maindyn_18')
				label:SetColor(1,1,1)
			else
				label:SetFont('maindyn_18')
				label:SetColor(1,1,1)
			end
			UpdateCursor(button, true, { canLeftClick = true})
		end)

		button:SetCallback('onmouseout', function(widget)
			if (trigger_gamePanelInfo.shopView == index and not trigger_gamePanelInfo.abilityPanel) then
				label:SetFont('maindyn_18')
				label:SetColor(1,1,1)
			else
				label:SetFont('maindyn_18')
				label:SetColor(0.7, 0.7, 0.7)
			end
			UpdateCursor(button, false, { canLeftClick = true})
		end)

		button:RefreshCallbacks()

		label:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
			if (trigger.shopView == index and not trigger.abilityPanel) then
				label:SetFont('maindyn_18')
				label:SetColor(1,1,1)
			else
				label:SetFont('maindyn_18')
				label:SetColor(0.7, 0.7, 0.7)
			end
		end, false, nil, 'shopView', 'abilityPanel')

		button:SetCallback('onclick', function(widget)
			local panelInfo = GetTrigger('gamePanelInfo')
			panelInfo.shopView = index
			Cvar.GetCvar('_shopView'):Set(index)
			panelInfo.abilityPanel = false
			panelInfo:Trigger(false)
			trigger_shopFilter:Trigger(false)
		end)
	end
end

local function InitBuilds(object)

	local gameShopBuildSelect_abilities		= object:GetWidget('gameShopBuildSelect_abilities')
	local gameShopBuildSelect_items			= object:GetWidget('gameShopBuildSelect_items')
	local items_builds_listbox				= object:GetWidget('game_bookmarks_load_listbox')
	local abilities_builds_combobox 		= object:GetWidget('game_shop_build_select_abilities_combobox')
	local selectedGuideTable 				= nil

	local function TransferItemBuildToBookmarks()
		local trigger
		local bookmarkIndex = 0
		Shop.ClearBookmarkQueue()
		if (selectedGuideTable) then
			for i,v in pairs(selectedGuideTable) do
				if ValidateEntity(v) then
					Shop.QueueBookmark(v, bookmarkIndex, true)
					bookmarkIndex = bookmarkIndex  + 1
				end
			end
		end
		gameShopBuildSelect_items:FadeOut(125)
		object:GetWidget('gameShopBuyQueueBackground'):DoEvent()
	end

	local function UpdateBuilds(object)

		-- Populate item builds in shop
		local function PopulateItemBuildDropdown(widget)

			if (not mainUI.Selection) or (not mainUI.Selection.itemsBuildTables) or (not mainUI.Selection.itemsBuildTables[1]) then
				SevereError('The shop has no item build tables', 'main_reconnect_thatsucks', '', nil, nil, nil)
				return
			end

			local function PreviewGuide()
				-- selectedGuideTable
			end

			local function SelectGuide()
				local value = widget:GetValue()
				if (value) and tonumber(value) and (tonumber(value) >= 1) then
					if (mainUI.Selection.itemsBuildTables) then
						if (mainUI.Selection.itemsBuildTables[tonumber(value)]) then
							selectedGuideTable = mainUI.Selection.itemsBuildTables[tonumber(value)]
							PreviewGuide()
						else
							SevereError('PopulateItemBuildDropdown has no build at index ' .. tostring(value), 'main_reconnect_thatsucks', '', nil, nil, nil)
						end
					else
						SevereError('PopulateItemBuildDropdown has no build table ' .. tostring(value), 'main_reconnect_thatsucks', '', nil, nil, nil)
					end
				end
			end

			if (widget) then

				widget:SetCallback('ondoubleclick', function()
					local heroEntity = LuaTrigger.GetTrigger('HeroUnit').heroEntity
					if (heroEntity) and ( (heroEntity == 'Hero_CapriceTutorial2') or (heroEntity == 'Hero_CapriceTutorial') ) then
						println('^y Builds Disabled - Tut Entity')
					else					
						SelectGuide()
						TransferItemBuildToBookmarks()
					end
				end)

				widget:GetWidget('game_shop_build_select_items_bookmark_btn'):SetCallback('onclick', function()
					local heroEntity = LuaTrigger.GetTrigger('HeroUnit').heroEntity
					if (heroEntity) and ( (heroEntity == 'Hero_CapriceTutorial2') or (heroEntity == 'Hero_CapriceTutorial') ) then
						println('^y Builds Disabled - Tut Entity')
					else					
						SelectGuide()
						TransferItemBuildToBookmarks()
					end
				end)

				widget:GetWidget('game_shop_build_clear_items_bookmark_btn'):SetCallback('onclick', function()
					Shop.ClearBookmarkQueue()
					gameShopBuildSelect_items:FadeOut(125)
					object:GetWidget('gameShopBuyQueueBackground'):DoEvent()
				end)

				widget:SetCallback('onselect', function()
					SelectGuide()
				end)

				widget:ClearItems()

				if (mainUI.Selection.itemsBuildTables) then
					for index, buildTable in ipairs(mainUI.Selection.itemsBuildTables) do
						if (mainUI.Selection.buildInfoTables[index]) and (mainUI.Selection.buildInfoTables[index].name) then
							widget:AddTemplateListItem(style_main_dropdownItem, index, 'label', mainUI.Selection.buildInfoTables[index].name)
						end
					end
				end

				widget:UICmd([[SetSelectedItemByValue(]] .. (ShopUI.selectedBuild) .. [[, true)]])

				if (triggerStatus.enableAutoBuild) then
					local heroEntity = LuaTrigger.GetTrigger('HeroUnit').heroEntity
					if (heroEntity) and ( (heroEntity == 'Hero_CapriceTutorial2') or (heroEntity == 'Hero_CapriceTutorial') ) then
						println('^y Auto Items Disabled - Tut Entity')
					else
						println('^g Auto Items Enabled ')
						selectedGuideTable = mainUI.Selection.itemsBuildTables[tonumber(ShopUI.selectedBuild)]
						TransferItemBuildToBookmarks()
					end
				else
					println('^y Auto Items Disabled ')
				end

			end

		end
		PopulateItemBuildDropdown(items_builds_listbox)

		-- Populate Ability builds in the shop
		local function PopulateAbilityBuildDropdown(widget)

			widget:SetCallback('onselect', function()
				local value = widget:GetValue()
				if (value) and tonumber(value) and (tonumber(value) >= 0) then
					if (mainUI.Selection.abilitiesBuildTables) then
						if (mainUI.Selection.abilitiesBuildTables[tonumber(value)]) then

							local tempTable = {}
							for abilityIndex,abilityEntity in pairs(mainUI.Selection.abilitiesBuildTables[tonumber(value)]) do
								-- println('^y ' .. value .. ' ' .. abilityIndex .. ' ' .. abilityEntity)
								if (abilityEntity) then
									if (tonumber(value) > 1) then
										local draggedAbilityIndex = (string.sub(abilityEntity, -1))
										abilityEntity = (string.sub(abilityEntity, 1, -2))
										abilityEntity = abilityEntity .. (draggedAbilityIndex + 1)
									end
									table.insert(tempTable, abilityEntity)
								end
							end

							SetAbilityBuild(tempTable)
							for abilityIndex, abilityEntity in pairs(tempTable) do
								-- println('^g ' .. value .. ' ' .. abilityIndex .. ' ' .. abilityEntity)
								if (abilityEntity) and ValidateEntity(abilityEntity) then
									widget:GetWidget('gameShopBuildSelect_abilities_icon_' .. abilityIndex):SetTexture(GetEntityIconPath(abilityEntity))
								end
							end
						else
							SevereError('PopulateItemBuildDropdown has no build at index ' .. tostring(value), 'main_reconnect_thatsucks', '', nil, nil, nil)
						end
					end
				end
			end)

			widget:ClearItems()

			if (mainUI.Selection) and (mainUI.Selection.abilitiesBuildTables) then
				for index, buildTable in ipairs(mainUI.Selection.abilitiesBuildTables) do
					if (mainUI.Selection.buildInfoTables[index]) and (mainUI.Selection.buildInfoTables[index].name) then
						widget:AddTemplateListItem(style_main_dropdownItem, index, 'label', mainUI.Selection.buildInfoTables[index].name)
					end
				end
			end

			widget:UICmd([[SetSelectedItemByValue(]] .. (ShopUI.selectedBuild) .. [[, true)]])

			if (triggerStatus.enableAutoAbilities) then
				if (not GetTrigger('Shop').autoLevelActive) then
					println('^g Auto Abilities Enabled ')
					Shop.ToggleAutoLevel()
				end
			else
				println('^y Auto Abilities Disabled ')
			end

		end
		PopulateAbilityBuildDropdown(abilities_builds_combobox)

	end


	local function LoadHeroBuilds(object, entityName)

		mainUI.Selection = mainUI.Selection or {}
		local triggerStatus = LuaTrigger.GetTrigger('selection_Status')

		local heroEntity = entityName or LuaTrigger.GetTrigger('ActiveUnit').heroEntity
		if Empty(heroEntity) then
			heroEntity = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName
		end

		if (heroEntity) and (not Empty(heroEntity)) and ValidateEntity(heroEntity) then
			
			ShopUI.selectedBuild = triggerStatus.selectedBuild
			
			if  ((not ShopUI.lastHeroRetrieved) or (ShopUI.lastHeroRetrieved ~= heroEntity)) then

				local buildEditorStatus = LuaTrigger.GetTrigger('buildEditorStatus')

				local successFunction =  function (request)	-- response handler
					local responseData = request:GetBody()
					if responseData == nil then
						if (buildEditorStatus) then
							buildEditorStatus.webRequestPending = false
							buildEditorStatus:Trigger(false)
						end
						SevereError('GetHeroBuild - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
						return nil
					else
						if (buildEditorStatus) then
							buildEditorStatus.webRequestPending = false
							buildEditorStatus:Trigger(false)
						end
						local webHeroBuildTable = responseData

						local sortedWebHeroBuildTable = {}

						if (webHeroBuildTable) then
							for index = 0, 5, 1 do
								if (webHeroBuildTable[tostring(index)]) then
									tinsert(sortedWebHeroBuildTable, webHeroBuildTable[tostring(index)])
								end
							end
						end

						-- These are split once in-game, so we need to seperate them
						mainUI.Selection.buildInfoTables = {}
						mainUI.Selection.abilitiesBuildTables = {}
						mainUI.Selection.itemsBuildTables = {}
						mainUI.Selection.craftedItemsBuildTables = {}

						-- Add default builds
						local defaultAbilityTable = GetDefaultAbilityBuild(heroEntity)
						local defaultItemTable = GetDefaultItemBuild(heroEntity)

						tinsert(mainUI.Selection.buildInfoTables, {name = Translate('builds_guide'), description = ''})

						if (defaultAbilityTable) then
							tinsert(mainUI.Selection.abilitiesBuildTables, defaultAbilityTable)
						end
						if (defaultItemTable) then
							tinsert(mainUI.Selection.itemsBuildTables, defaultItemTable)
						end

						-- Add web builds
						if (sortedWebHeroBuildTable) then
							for index, buildTable in ipairs(sortedWebHeroBuildTable) do
								if (buildTable.name) then
									tinsert(mainUI.Selection.buildInfoTables, {name = buildTable.name, description = buildTable.description, heroEntity = buildTable.heroEntity})

									--abilities are sent with a random order
									local sortedAbilities = {}
									--php sends this with an index of 0, so insert it manually.
									local sortedItems = {}
									for n=1,15 do
										sortedAbilities[n] = buildTable.skills[tostring(n)]
										sortedItems[n] = buildTable.items[tostring(n-1)] --0 indexed
									end
									tinsert(mainUI.Selection.abilitiesBuildTables, sortedAbilities)
									tinsert(mainUI.Selection.itemsBuildTables, sortedItems)

									tinsert(mainUI.Selection.craftedItemsBuildTables, buildTable.craftedItems)
								end
							end
						end
						
							-- Also insert our last games build if it is valid (an item or ability)
						if (ShopUI.oldHeroBuild) then -- exists
							local buildTable = ShopUI.oldHeroBuild
							if (#buildTable.Items > 0 or #buildTable.Skills > 0) then
								tinsert(mainUI.Selection.buildInfoTables, {name = Translate('builds_last_build'), description = '', heroEntity = (heroEntity)})
								tinsert(mainUI.Selection.abilitiesBuildTables, buildTable.Skills)
								tinsert(mainUI.Selection.itemsBuildTables, buildTable.Items)
							end
						end

						if (mainUI.Selection) and (mainUI.savedRemotely.heroBuilds) and (mainUI.savedRemotely.heroBuilds[heroEntity]) and (mainUI.savedRemotely.heroBuilds[heroEntity].default_build) and (mainUI.savedRemotely.heroBuilds[heroEntity].default_build >= 0) then
							triggerStatus.selectedBuild = mainUI.savedRemotely.heroBuilds[heroEntity].default_build
						else
							triggerStatus.selectedBuild = 1
						end

						ShopUI.lastHeroRetrieved = heroEntity

						SaveState()

						ShopUI.selectedBuild = triggerStatus.selectedBuild
						-- println('Setting ShopUI.selectedBuild Position A to ' .. tostring(ShopUI.selectedBuild) )
						UpdateBuilds(object)

						return true
					end
				end

				local failFunction =  function (request)	-- error handler
					if (buildEditorStatus) then
						buildEditorStatus.webRequestPending = false
						buildEditorStatus:Trigger(false)
					end
					SevereError('GetHeroBuild Request Error: ' .. Translate(request:GetError()), 'main_reconnect_thatsucks', '', nil, nil, false)
					return nil
				end

				Strife_Web_Requests:GetHeroBuild(heroEntity, successFunction, failFunction)

			end
		end

	end

	-- Update and activate builds in response to new selection, this is cleared at reinit
	gameShopBuildSelect_items:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		if (ShopUI.selectedBuild) and (ShopUI.selectedBuild ~= triggerStatus.selectedBuild) and (triggerStatus.selectedBuild >= 0) and (GetTrigger('GamePhase').gamePhase >= 5) then
			-- println('Setting ShopUI.selectedBuild Position B to ' .. tostring(ShopUI.selectedBuild) )
			LoadHeroBuilds(object, nil)
		end
		local heroEntity = LuaTrigger.GetTrigger('ActiveUnit').heroEntity
		if Empty(heroEntity) then
			heroEntity = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName
		end
		if (heroEntity) and (not Empty(heroEntity)) and ValidateEntity(heroEntity) then
			SetItemBuild(GetDefaultItemBuild(heroEntity))
		end
	end)

	-- Control item build visibility in the shop
	local bookmarkIcon						= object:GetWidget('gameShopBookmarkIcon')
	bookmarkIcon:SetCallback('onmouseover', function(widget)
		simpleTipGrowYUpdate(true, nil, Translate('game_shop_bookmarks'), Translate('game_shop_bookmarks_tip'))
	end)
	bookmarkIcon:SetCallback('onmouseout', function(widget)
		simpleTipGrowYUpdate(false)
	end)
	bookmarkIcon:SetCallback('onclick', function(widget)
		if (not gameShopBuildSelect_items:IsVisible()) then
			gameShopBuildSelect_items:FadeIn(125)
		else
			gameShopBuildSelect_items:FadeOut(125)
		end
	end)

	-- Control ability build dropdown visibility in the shop
	gameShopBuildSelect_abilities:RegisterWatchLua('gamePanelInfo', function(sourceWidget, trigger)
		if (trigger.abilityPanel and trigger.mapWidgetVis_buildControls) then
			sourceWidget:SetVisible(1)
		else
			sourceWidget:SetVisible(0)
		end
	end, false, nil, 'shopCategory', 'abilityPanel', 'shopView', 'mapWidgetVis_buildControls')

	object:GetWidget('game_shop_autolevel_checkbox'):SetCallback('onclick', function(widget)
		Shop.ToggleAutoLevel()
	end)

	object:GetWidget('game_shop_autolevel_checkbox'):RegisterWatchLua('Shop', function(widget, trigger)
		if (trigger.autoLevelActive) then
			widget:SetButtonState(1)
		else
			widget:SetButtonState(0)
		end
	end, false, nil, 'autoLevelActive')

	object:GetWidget('game_shop_autolevel_checkboxCheck'):RegisterWatchLua('Shop', function(widget, trigger)
		widget:SetVisible(trigger.autoLevelActive)
	end, false, nil, 'autoLevelActive')
end

local function gameShopRegister(object)
	local container							= object:GetWidget('gameShopContainer')
	local containerWidth					= container:GetWidth()
	local categoryList						= object:GetWidget('gameShopCategoryList')
	local filterList						= object:GetWidget('gameShopFilterList')
	local buyQueueContainer					= object:GetWidget('gameShopBuyQueueContainer')
	local itemListSimple					= object:GetWidget('gameShopItemListSimple')
	local itemListSimpleBox					= object:GetWidget('gameShopItemListSimpleBox')
	local itemListSimpleSlider				= object:GetWidget('gameShopItemListSimpleBox_vscroll_slider')
	local itemListDetailed					= object:GetWidget('gameShopItemListDetailed')
	local itemListDetailedBox				= object:GetWidget('gameShopItemListDetailedBox')
	local itemListDetailedSlider			= object:GetWidget('gameShopItemListDetailedBox_vscroll_slider')

	local itemViewButtonSimple				= object:GetWidget('gameShopItemViewButtonSimple')
	-- local itemViewButtonSimpleLabel		= object:GetWidget('gameShopItemViewButtonSimpleLabel')
	local itemViewButtonSimpleBacker		= object:GetWidget('gameShopItemViewButtonSimpleBacker')
	local itemViewButtonDetailed			= object:GetWidget('gameShopItemViewButtonDetailed')
	-- local itemViewButtonDetailedLabel	= object:GetWidget('gameShopItemViewButtonDetailedLabel')
	local itemViewButtonDetailedBacker		= object:GetWidget('gameShopItemViewButtonDetailedBacker')

	local stashContainer					= object:GetWidget('gameShopStashContainer')

	local buyQueueAdd						= object:GetWidget('autoBuyQueueAdd')
	local buyQueueAddIcon					= object:GetWidget('autoBuyQueueAdd_icon')
	local buyQueueAddDropTarget				= object:GetWidget('autoBuyQueueAddDropTarget')
	local buyQueueAddDropTargetFull			= object:GetWidget('autoBuyQueueAddDropTargetFull')

	local levelUpKeyController				= object:GetWidget('gameShopLevelUpKeyController')

	local lastPurchaseSourceWidget			= nil

	local bookmarkDragInfo = LuaTrigger.GetTrigger('bookmarkDragInfo') or LuaTrigger.CreateGroupTrigger('bookmarkDragInfo', { 'globalDragInfo.type', 'globalDragInfo.active', 'Shop.bookmarkQueueSize'	})

	local function ShopReinitialize()
		object:GetWidget('game_shop_search_input'):EraseInputLine()
		ShopUI.ClearFilters()
		ShopUI.selectedBuild = -1

		trigger_gamePanelInfo.selectedShopItem				= -1
		trigger_gamePanelInfo.selectedShopItemType			= ''
		trigger_gamePanelInfo:Trigger(true)

		trigger_shopFilter.shopCategory = ShopUI.defaultCategory
		trigger_shopFilter.forceCategory	= ''
		trigger_shopFilter:Trigger(true)
	end

	local function ShopReinitializeGame()
		trigger_gamePanelInfo.selectedBuild					= -1
		trigger_gamePanelInfo.mapWidgetVis_minimap			= true
		trigger_gamePanelInfo.mapWidgetVis_abilityBarPet	= true
		trigger_gamePanelInfo.mapWidgetVis_pushBar			= true
		trigger_gamePanelInfo.mapWidgetVis_heroInfos		= true
		trigger_gamePanelInfo.mapWidgetVis_shopItemList		= true
		trigger_gamePanelInfo.mapWidgetVis_courierButton	= true
		trigger_gamePanelInfo.mapWidgetVis_portHomeButton	= true
		trigger_gamePanelInfo.mapWidgetVis_abilityPanel		= true
		trigger_gamePanelInfo.mapWidgetVis_shopQuickSlots	= true
		trigger_gamePanelInfo.mapWidgetVis_shopClickable	= true
		trigger_gamePanelInfo.mapWidgetVis_shopClickable	= true
		trigger_gamePanelInfo.mapWidgetVis_shopRightClick	= true
		trigger_gamePanelInfo.mapWidgetVis_canToggleShop	= true
		trigger_gamePanelInfo.mapWidgetVis_shopBootsGlow	= true
		trigger_gamePanelInfo.mapWidgetVis_buildControls	= true


		ShopReinitialize()
	end

	container:RegisterWatchLua('GamePhase', function(widget, trigger)
		local gamePhase = trigger.gamePhase
		if gamePhase <= 4 then
			ShopUI.defaultCategory	= ''
			ShopReinitialize()
			shopInLauncher = true
		else
			shopInLauncher = false
			ShopUI.defaultCategory	= 'crafted+itembuild'
		end

		--[[
		if gamePhase == 0 then

		end
		--]]

	end, false)

	function gameShopSetLastPurchaseSourceWidget(widget)
		if widget and widget:IsValid() then
			lastPurchaseSourceWidget = widget
		else
			lastPurchaseSourceWidget = nil
		end
	end

	container:RegisterWatchLua('GameReinitialize', ShopReinitializeGame)

	container:GetWidget('game_shop_closex'):SetCallback('onclick', function(widget)

		local triggerPhase	= LuaTrigger.GetTrigger('GamePhase')
		local mainPanelStatus	= LuaTrigger.GetTrigger('mainPanelStatus')
		local trigger_selection_Status	= LuaTrigger.GetTrigger('selection_Status')

		if triggerPhase.gamePhase >= 4 then
			if trigger_gamePanelInfo.mapWidgetVis_canToggleShop then
				trigger_gamePanelInfo.shopOpen = false
				widget:UICmd("CloseShop()")
			end
		elseif (((trigger_selection_Status.selectionSection == mainUI.Selection.selectionSections.SKILL_BUILDS) and (mainPanelStatus.main == 40 or mainPanelStatus.main == 101))) then
			closeItemBuildEditor()
		else

			-- sound_craftingCloseRecipeSelection2
			PlaySound('/ui/sounds/crafting/sfx_book_close.wav')

			local itemInfo	= LuaTrigger.GetTrigger('CraftingUnfinishedDesign')
			local craftingStage = LuaTrigger.GetTrigger('craftingStage')

			if (itemInfo.name) and (not Empty(itemInfo.name)) then
				craftingStage.stage = 3
				craftingStage:Trigger(false)
			else
				craftingStage.stage = 7
				craftingStage:Trigger(false)
			end

		end

		--[[
		local triggerNPE = LuaTrigger.GetTrigger('newPlayerExperience')
		if triggerNPE.craftingIntroProgress == 0 and triggerNPE.craftingIntroStep == 2 then
			newPlayerExperienceCraftingStep(1)
		end
		--]]
	end)

	local autoBuyQueueAddDrop = LuaTrigger.GetTrigger('autoBuyQueueAddDrop') or LuaTrigger.CreateGroupTrigger('autoBuyQueueAddDrop', { 'Shop.bookmarkQueueSize', 'globalDragInfo.type', 'globalDragInfo.active' })

	buyQueueAdd:RegisterWatchLua('autoBuyQueueAddDrop', function(widget, groupTrigger)
		-- local shop_trigger = GetTrigger('Shop')
		local triggerShop	= groupTrigger['Shop']
		local triggerDrag	= groupTrigger['globalDragInfo']
		widget:SetVisible((triggerShop.bookmarkQueueSize < 9) or triggerDrag.type == 3)
	end)

	buyQueueAddIcon:RegisterWatchLua('globalDragInfo', function(widget, trigger)
		local dropType = trigger.type
		if dropType == 3 and trigger.active then
			widget:SetTexture('/ui/shared/shop/textures/trash/can_static.tga')
			widget:SetColor('1 1 1 1')
		else
			widget:SetTexture('/ui/shared/shop/textures/scroll_target.tga')
			widget:SetColor('1 1 1 .5')
		end
	end, false, nil, 'active', 'type')

	buyQueueAddDropTarget:RegisterWatchLua('autoBuyQueueAddDrop', function(widget, groupTrigger)
		local triggerShop	= groupTrigger['Shop']
		local triggerDrag	= groupTrigger['globalDragInfo']
		local dropType = triggerDrag.type
		widget:SetVisible(
			triggerDrag.active and (
				dropType == 3 or (
					(dropType == 4 or dropType == 5 or dropType == 6) and not trigger_gamePanelInfo.shopDraggedItemOwnedRecipe
					and triggerShop.bookmarkQueueSize < 9
				)
			)
		)
	end)

	buyQueueAddDropTargetFull:RegisterWatchLua('autoBuyQueueAddDrop', function(widget, groupTrigger)
		local triggerShop	= groupTrigger['Shop']
		local triggerDrag	= groupTrigger['globalDragInfo']
		local dropType = triggerDrag.type
		widget:SetVisible(triggerDrag.active and (dropType == 4 or dropType == 5 or dropType == 6) and not trigger_gamePanelInfo.shopDraggedItemOwnedRecipe and triggerShop.bookmarkQueueSize < 9)
	end)

	buyQueueAddDropTarget:SetCallback('onmouseover', function(widget)
		globalDraggerReadTarget(widget, function()
			local globalDragInfo_trigger = GetTrigger('globalDragInfo')
			if (globalDragInfo_trigger.type == 3) then
				Shop.RemoveBookmark(trigger_gamePanelInfo.shopLastBuyQueueDragged)
				object:GetWidget('gameShopBuyQueueBackground'):DoEvent()
			else
				local targIndex = GetTrigger('Shop').bookmarkQueueSize + 1
				local sourceIndex = trigger_gamePanelInfo.shopLastBuyQueueDragged
				local placeEntity = ''
				if sourceIndex ~= targIndex then

					if sourceIndex >= 0 then
						placeEntity = GetTrigger('BookmarkQueue'..sourceIndex).entity
						if sourceIndex < targIndex then
							targIndex = targIndex - 1
						end
						Shop.RemoveBookmark(sourceIndex)
						object:GetWidget('gameShopBuyQueueBackground'):DoEvent()
					else
						placeEntity = trigger_gamePanelInfo.shopDraggedItem
					end

					Shop.QueueBookmark(placeEntity, targIndex, false)
					object:GetWidget('gameShopBuyQueueBackground'):DoEvent()
				end

				trigger_gamePanelInfo.shopLastBuyQueueDragged = -1
				trigger_gamePanelInfo.shopLastQuickSlotDragged = -1
			end
		end)
	end)

	buyQueueAddDropTargetFull:SetCallback('onmouseover', function(widget)
		globalDraggerReadTarget(widget, function()
			local globalDragInfo_trigger = GetTrigger('globalDragInfo')
			if (globalDragInfo_trigger.type == 3) then
				Shop.RemoveBookmark(trigger_gamePanelInfo.shopLastBuyQueueDragged)
				object:GetWidget('gameShopBuyQueueBackground'):DoEvent()
			else
				local targIndex = GetTrigger('Shop').bookmarkQueueSize + 1
				local sourceIndex = trigger_gamePanelInfo.shopLastBuyQueueDragged
				local placeEntity = ''
				if sourceIndex ~= targIndex then

					if sourceIndex >= 0 then
						placeEntity = GetTrigger('BookmarkQueue'..sourceIndex).entity
						if sourceIndex < targIndex then
							targIndex = targIndex - 1
						end
						Shop.RemoveBookmark(sourceIndex)
						object:GetWidget('gameShopBuyQueueBackground'):DoEvent()
					else
						placeEntity = trigger_gamePanelInfo.shopDraggedItem
					end

					Shop.QueueBookmark(placeEntity, targIndex, false)
					object:GetWidget('gameShopBuyQueueBackground'):DoEvent()
				end

				trigger_gamePanelInfo.shopLastBuyQueueDragged = -1
				trigger_gamePanelInfo.shopLastQuickSlotDragged = -1
			end
		end)
	end)



	local itemPurchasedAnimScriptWidget		= object:GetWidget('gameShopItemPurchasedAnimScriptWidget')
	local itemPurchasedAnimsQueued			= false
	local itemPurchasedAnimQueue			= {}
	local itemPurchasedAnimQueueTimeLast	= 0
	local itemPurchasedAnimQueueTimeOffset	= 75
	local itemPurchasedAnimIndex			= 0		-- To give a unique id to each we instantiate
	local itemPurchasedAnimTime				= 350
	local itemPurchasedIndexActive			= {}

	local function itemPurchasedFindTarget(entityName)
		local itemTrigger
		for i=133,128,-1 do	-- Scan stash
			itemTrigger = LuaTrigger.GetTrigger('StashInventory'..i)
			if itemTrigger.entity == entityName and itemTrigger.exists and (not itemPurchasedIndexActive[i]) then
				return i, itemTrigger
			end
		end
		for i=104,96,-1 do
			itemTrigger = LuaTrigger.GetTrigger('ActiveInventory'..i)
			if itemTrigger.entity == entityName and itemTrigger.exists and (not itemPurchasedIndexActive[i]) then
				return i, itemTrigger
			end
		end
		return -1
	end

	local function itemPurchasedAnimate(widget, itemInfo)
		local itemIcon	= widget:GetWidget('gameInventory'..itemInfo[2]..'Icon')

		if itemIcon and itemIcon:IsValid() and lastPurchaseSourceWidget and lastPurchaseSourceWidget:IsValid() then

			itemPurchasedIndexActive[itemInfo[2]] = true

			local sourceX			= lastPurchaseSourceWidget:GetAbsoluteX()
			local sourceY			= lastPurchaseSourceWidget:GetAbsoluteY()
			local sourceWidth		= lastPurchaseSourceWidget:GetWidth()
			local sourceHeight		= lastPurchaseSourceWidget:GetHeight()

			local targX			= itemIcon:GetAbsoluteX()
			local targY			= itemIcon:GetAbsoluteY()
			local targWidth		= itemIcon:GetWidth()
			local targHeight	= itemIcon:GetHeight()

			local animWidgetWidth	= libGeneral.HtoP(6)
			local animWidgetHeight	= libGeneral.HtoP(6)

			local startX		= sourceX + ((math.max(sourceWidth, animWidgetWidth) - math.min(sourceWidth, animWidgetWidth)) / 2)
			local startY		= sourceY + ((math.max(sourceHeight, animWidgetHeight) - math.min(sourceHeight, animWidgetHeight)) / 2)

			local endX		= targX + ((math.max(targWidth, animWidgetWidth) - math.min(targWidth, animWidgetWidth)) / 2)
			local endY		= targY + ((math.max(targHeight, animWidgetHeight) - math.min(targHeight, animWidgetHeight)) / 2)

			itemPurchasedAnimScriptWidget:Instantiate('itemPurchasedAnimEntry', 'id', itemPurchasedAnimIndex, 'icon', GetEntityIconPath(itemInfo[1]), 'x', startX, 'y', startY)
			local animWidget = widget:GetWidget('itemPurchasedAnimEntry'..itemPurchasedAnimIndex)

			animWidget:SlideX(endX, itemPurchasedAnimTime)
			animWidget:SlideY(endY, itemPurchasedAnimTime)
			animWidget:Sleep(itemPurchasedAnimTime - 50, function()
				animWidget:FadeOut(50)
				animWidget:Sleep(50, function()
					itemPurchasedIndexActive[itemInfo[2]] = false
					animWidget:Destroy()
				end)
			end)


			itemPurchasedAnimIndex = itemPurchasedAnimIndex + 1
		else
			println('shop itemPurchasedAnimate cant find widgets ')
		end

	end
	
	container:RegisterWatchLua('ItemPurchased', function(widget, trigger)
		local itemEntity = trigger.entity
		if itemEntity == 'Item_Tome_Health' or itemEntity == 'Item_Tome_Power' or itemEntity == 'Item_Tome_Mana' then
			-- sound_purchaseTome
			PlaySound('ui/sounds/shop/sfx_item_purchase.wav', 1.0)
		else
			-- sound_itemPurchased
			PlaySound('ui/sounds/shop/sfx_item_purchase.wav', 1.0)
		end

		table.insert(itemPurchasedAnimQueue, itemEntity)

		itemPurchasedAnimQueueTimeLast = GetTime() - itemPurchasedAnimQueueTimeOffset + 50

		if not itemPurchasedAnimsQueued then
			itemPurchasedAnimsQueued = true
			itemPurchasedAnimScriptWidget:RegisterWatchLua('System', function(widget, trigger)
				if #itemPurchasedAnimQueue >= 1 then
					local hostTime = trigger.hostTime
					if itemPurchasedAnimQueueTimeLast + itemPurchasedAnimQueueTimeOffset <= hostTime then
						local itemEntity = table.remove(itemPurchasedAnimQueue, 1)

						local targetIndex, itemTrigger	= itemPurchasedFindTarget(itemEntity)
						if (itemTrigger) then-- and itemTrigger.isRecipeCompleted) then
							local name = itemTrigger.entity
							if (string.sub(name, 1, 1) == "$") then -- TODO RMM Kai Remove this, we want crafted items in our guides when possible.
								name = string.sub(name, string.find(name, "|")+1)
							end
							tinsert(mainUI.savedLocally.LastBuild[hero].Items, name)
						end
						
						if targetIndex >= 0 then
							itemPurchasedAnimate(
								widget, { itemEntity, targetIndex }
							)
							itemPurchasedAnimQueueTimeLast = hostTime
						end
					end
				else
					itemPurchasedAnimsQueued = false
					widget:UnregisterWatchLua('System')
				end
			end, false, nil, 'hostTime')
		end
	end)

	container:RegisterWatchLua('ItemPurchaseFailed', function(widget, trigger)
		if (trigger.reasonNum ~= 8) then
			PlaySound('/ui/sounds/shop/sfx_insufficient_gold.wav')
		end
	end)

	container:RegisterWatchLua('ItemSold', function(widget, trigger)
		-- sound_itemSold
		-- Stephen, this file probably already exists - might want to delete it if you're not just replacing it
		PlaySound('ui/sounds/shop/sfx_item_sell.wav')
	end)

	object:GetWidget('gameShopHeroGold'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		widget:SetText(libNumber.commaFormat(trigger.gold))
	end, false, nil, 'gold')

	local trashcanAnimateThread

	local dropSell		= object:GetWidget('gameShopDropSell')
	local dragSell		= object:GetWidget('gameShopDragSell')
	local dropTrashLid	= object:GetWidget('gameDropTrashLid')
	local gameShop_sell_area	= object:GetWidget('gameShop_sell_area')
	
	local trashcanIsOpen = false

	local function trashcanKillAnim()
		if trashcanAnimateThread then
			trashcanAnimateThread:kill()
			trashcanAnimateThread = nil
		end
	end

	function trashcanAnimateOpen()
		gameShop_sell_area:SetVisible(1)
		trashcanKillAnim()
		if not trashcanIsOpen then
			trashcanIsOpen = true
			trashcanAnimateThread = libThread.threadFunc(function()
				dropTrashLid:Rotate(-102, 225)
				wait(225)
				dropTrashLid:Rotate(-90, 75)
				wait(75)
				dropTrashLid:Rotate(-102, 75)
				trashcanAnimateThread = nil
			end)
			-- animate open
		end
	end

	local function trashcanAnimateClose()
		trashcanKillAnim()
		if trashcanIsOpen then
			trashcanIsOpen = false
			trashcanAnimateThread = libThread.threadFunc(function()
				dropTrashLid:Rotate(0, 225)
				wait(225)
				dropTrashLid:Rotate(-10, 75)
				wait(75)
				dropTrashLid:Rotate(0, 75)
				trashcanAnimateThread = nil
			end)
		end
	end

	gameShop_sell_area:RegisterWatchLua('ItemCursorVisible', function(widget, trigger)
		widget:SetVisible(trigger.cursorVisible and trigger.hasItem)
	end)

	gameShop_sell_area:RegisterWatchLua('globalDragInfo', function(widget, trigger)
		local dragType = trigger.type
		widget:SetVisible(trigger.active and (dragType == 5 or dragType == 6))
	end, false, nil, 'type', 'active')

	dropSell:RegisterWatchLua('ItemCursorVisible', function(widget, trigger)
		widget:SetVisible(trigger.cursorVisible and trigger.hasItem)
	end)

	dropSell:SetCallback('onclick', function(widget)
		Sell()
	end)

	dropSell:SetCallback('onmouseover', function(widget)
		trashcanAnimateOpen()
	end)

	dropSell:SetCallback('onmouseout', function(widget)
		trashcanAnimateClose()
	end)

	dragSell:RegisterWatchLua('globalDragInfo', function(widget, trigger)
		local dragType = trigger.type
		widget:SetVisible(trigger.active and (dragType == 5 or dragType == 6))
	end, false, nil, 'type', 'active')

	dragSell:SetCallback('onmouseover', function(widget)
		trashcanAnimateOpen()
		globalDraggerReadTarget(widget, function()
			local dragInfo = LuaTrigger.GetTrigger('globalDragInfo')
			local dragType = dragInfo.type
			local sourceIndex = trigger_gamePanelInfo.draggedInventoryIndex
			
			-- If we change our minds on an item, remove it from our Last Used build
			local trigger
			if sourceIndex < 110 then
				trigger = LuaTrigger.GetTrigger("HeroInventory"..sourceIndex)
			else
				trigger = LuaTrigger.GetTrigger("StashInventory"..sourceIndex)
			end
			local entity = trigger.entity
			if trigger.purchasedRecently then--and trigger.isRecipeCompleted then
				for i = 1, #mainUI.savedLocally.LastBuild[hero].Items do
					if (mainUI.savedLocally.LastBuild[hero].Items[i] == entity) then
						table.remove(mainUI.savedLocally.LastBuild[hero].Items, i)
						break
					end
				end
			end
			
			Sell(sourceIndex)
		end)
	end)

	dragSell:SetCallback('onmouseout', function(widget)
		trashcanAnimateClose()
	end)

	itemViewButtonSimple:SetCallback('onclick', function(widget)
		local panelInfo		= GetTrigger('gamePanelInfo')
		panelInfo.shopItemView = 0
		Cvar.GetCvar('_shopItemView'):Set(0)
		panelInfo:Trigger(false)
	end)

	itemViewButtonSimple:SetCallback('onmouseover', function(widget)
		simpleTipGrowYUpdate(true, nil, Translate('game_shop_itemview_simple'), Translate('game_shop_itemview_simple_tip'))
	end)

	itemViewButtonSimple:SetCallback('onmouseout', function(widget)
		simpleTipGrowYUpdate(false)
	end)

	itemViewButtonDetailed:SetCallback('onmouseover', function(widget)
		simpleTipGrowYUpdate(true, nil, Translate('game_shop_itemview_detailed'), Translate('game_shop_itemview_detailed_tip'))
	end)

	itemViewButtonDetailed:SetCallback('onmouseout', function(widget)
		simpleTipGrowYUpdate(false)
	end)

	itemViewButtonDetailed:SetCallback('onclick', function(widget)
		local panelInfo		= GetTrigger('gamePanelInfo')
		panelInfo.shopItemView = 1
		Cvar.GetCvar('_shopItemView'):Set(1)
		panelInfo:Trigger(false)
	end)

	itemViewButtonSimpleBacker:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		if trigger.shopItemView == 0 then
			widget:SetRenderMode('normal')
		else
			widget:SetRenderMode('grayscale')
		end
	end, false, nil, 'shopItemView')

	itemViewButtonDetailedBacker:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		if trigger.shopItemView == 1 then
			widget:SetRenderMode('normal')
		else
			widget:SetRenderMode('grayscale')
		end
	end, false, nil, 'shopItemView')


	gameShopRegisterViewTab(object, 'Items'    , 1  , false)
	gameShopRegisterViewTab(object, 'Abilities', nil, true)

	levelUpKeyController:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		local HeroUnit = GetTrigger('HeroUnit')
		Set('cg_levelupabilitiesoverride', (((trigger.shopOpen and trigger.abilityPanel) or trigger.moreInfoKey)) and (HeroUnit.availablePoints > 0), 'bool')
	end, true, nil, 'moreInfoKey', 'shopOpen', 'abilityPanel')

	-- THIS IS REQUIRED TO CLOSE THE LEVEL UP PANEL / SHOP WHEN LEVELING UP AN ABILITY VIA HOTKEY AND YOU'VE SPENT ALL POINTS
	levelUpKeyController:RegisterWatchLua('ActiveUnit', function(widget, trigger)
		if trigger.availablePoints == 0 and trigger_gamePanelInfo.shopOpen and trigger_gamePanelInfo.abilityPanel then
			gameToggleShowSkills(widget)
			--[[
			trigger_gamePanelInfo.shopOpen = false
			widget:UICmd("CloseShop()")
			--]]
		end
	end, false, nil, 'availablePoints')

	-- gamePanelInfo
	-- mainPanelStatus
	-- craftingStage

	libGeneral.createGroupTrigger('shopVisControls', {
		'craftingStage.stage',
		'GamePhase.gamePhase',
		'gamePanelInfo.shopOpen',
		'gamePanelInfo.mapWidgetVis_shopClickable',
		'gamePanelInfo.abilityPanel',
		'gamePanelInfo.shopView',
		'gamePanelInfo.shopCategory',
		'gamePanelInfo.shopHasFiltersToDisplay',
		'gamePanelInfo.shopShowFilters',
		'selection_Status.selectionSection',
		'mainPanelStatus.main'
	})

	object:GetWidget('shopCategoryButton9'):RegisterWatchLua('shopVisControls', function(widget, groupTrigger)
		local trigger_gamePanelInfo		= groupTrigger['gamePanelInfo']
		local trigger_gamePhase			= groupTrigger['GamePhase']
		local trigger_craftingStage		= groupTrigger['craftingStage']
		local trigger_selection_Status	= groupTrigger['selection_Status']
		local mainPanelStatus	= groupTrigger['mainPanelStatus']

		widget:SetVisible(trigger_gamePhase.gamePhase >= 4 or (trigger_craftingStage.stage ~= 7 and ((trigger_selection_Status.selectionSection == mainUI.Selection.selectionSections.SKILL_BUILDS) and (mainPanelStatus.main == 40 or mainPanelStatus.main == 101))))
	end)

	object:GetWidget('shopCategoryButton10'):RegisterWatchLua('shopVisControls', function(widget, groupTrigger)
		local trigger_gamePanelInfo		= groupTrigger['gamePanelInfo']
		local trigger_gamePhase			= groupTrigger['GamePhase']
		local trigger_craftingStage		= groupTrigger['craftingStage']
		local trigger_selection_Status	= groupTrigger['selection_Status']
		local mainPanelStatus	= groupTrigger['mainPanelStatus']

		widget:SetVisible(trigger_gamePhase.gamePhase >= 4 or (trigger_craftingStage.stage ~= 7 and ((trigger_selection_Status.selectionSection == mainUI.Selection.selectionSections.SKILL_BUILDS) and (mainPanelStatus.main == 40 or mainPanelStatus.main == 101))))
	end)

	local shopHeader	= object:GetWidget('gameShopHeader')

	shopHeader:RegisterWatchLua('shopVisControls', function(widget, groupTrigger)

		local trigger_gamePanelInfo	= groupTrigger['gamePanelInfo']
		local trigger_gamePhase		= groupTrigger['GamePhase']
		local trigger_craftingStage	= groupTrigger['craftingStage']
		local mainPanelStatus	= groupTrigger['mainPanelStatus']

		if trigger_gamePhase.gamePhase >= 4 then
			widget:SetVisible(true)
		else
			widget:SetVisible(false)
		end
	end)

	categoryList:RegisterWatchLua('shopVisControls', function(widget, groupTrigger)

		local trigger_gamePanelInfo	= groupTrigger['gamePanelInfo']
		local trigger_gamePhase		= groupTrigger['GamePhase']
		local trigger_craftingStage	= groupTrigger['craftingStage']
		local mainPanelStatus	= groupTrigger['mainPanelStatus']

		if trigger_gamePhase.gamePhase >= 4 then
			widget:SetVisible(trigger_gamePanelInfo.shopView == 1 and not trigger_gamePanelInfo.abilityPanel)
		else
			widget:SetVisible(true)
		end


	end)	-- , false, nil, 'shopView', 'abilityPanel'

	buyQueueContainer:RegisterWatchLua('shopVisControls', function(widget, groupTrigger)

		local trigger_gamePanelInfo	= groupTrigger['gamePanelInfo']
		local trigger_gamePhase		= groupTrigger['GamePhase']
		local trigger_craftingStage	= groupTrigger['craftingStage']
		local mainPanelStatus	= groupTrigger['mainPanelStatus']

		local shopView = trigger_gamePanelInfo.shopView

		widget:SetVisible((shopView == 0 or shopView == 1) and trigger_gamePhase.gamePhase >= 4 and not trigger_gamePanelInfo.abilityPanel)

	end)

	stashContainer:RegisterWatchLua('shopVisControls', function(widget, groupTrigger)
		local trigger_gamePanelInfo	= groupTrigger['gamePanelInfo']
		local trigger_gamePhase		= groupTrigger['GamePhase']
		local trigger_craftingStage	= groupTrigger['craftingStage']
		local mainPanelStatus	= groupTrigger['mainPanelStatus']

		if trigger_gamePhase.gamePhase >= 4 then
			widget:SetVisible(not trigger_gamePanelInfo.abilityPanel)
		else
			widget:SetVisible(false)
		end
	end)
	
	
	container:RegisterWatchLua('shopVisControls', function(widget, groupTrigger)
		local trigger_gamePanelInfo	= groupTrigger['gamePanelInfo']
		local trigger_gamePhase		= groupTrigger['GamePhase']
		local trigger_craftingStage	= groupTrigger['craftingStage']
		local craftingStage			= trigger_craftingStage.stage
		local trigger_selection_Status	= groupTrigger['selection_Status']
		local mainPanelStatus	= groupTrigger['mainPanelStatus']

		local showShop = false

		local gamePhase = trigger_gamePhase.gamePhase
		if gamePhase >= 7 then

		elseif gamePhase >= 4 then

			Shop.ClearExclusions()

			widget:SetHeight('-14h')
			widget:SetVAlign('top')
			widget:SetY(0)

			object:GetWidget('shopCategoryButton2'):SetVisible(true)	-- Crafted
			object:GetWidget('shopCategoryButton3'):SetVisible(true)	-- Boots

			if trigger_gamePanelInfo.shopOpen then
				if not widget:IsVisible() then	-- Just need to be sure this doesn't spam
					-- sound_shopOpen
					PlaySound('ui/sounds/shop/sfx_open.wav')
				end

				showShop = true
				-- widget:SlideX(0, styles_uiSpaceShiftTime)
				-- widget:FadeIn(styles_uiSpaceShiftTime)


			else

				if widget:IsVisible() then	-- Just need to be sure this doesn't spam
					-- sound_shopClose
					PlaySound('ui/sounds/shop/sfx_close.wav')
				end

				-- widget:SlideX(-containerWidth, styles_uiSpaceShiftTime)
				-- widget:FadeOut(styles_uiSpaceShiftTime)
			end

			widget:SetPassiveChildren(not trigger_gamePanelInfo.mapWidgetVis_shopClickable)
			trigger_gamePanelInfo.mapWidgetVis_shopBootsGlow = true
		else

			widget:SetHeight('600s')
			widget:SetVAlign('bottom')
			if (((trigger_selection_Status.selectionSection == mainUI.Selection.selectionSections.SKILL_BUILDS) and (mainPanelStatus.main == 40 or mainPanelStatus.main == 101))) then
				widget:SetY('-70s') --Guide Editor
			else
				widget:SetY('-36s') -- Crafting
			end

			object:GetWidget('shopCategoryButton2'):SetVisible(false)	-- Crafted
			object:GetWidget('shopCategoryButton3'):SetVisible(trigger_selection_Status.selectionSection == mainUI.Selection.selectionSections.SKILL_BUILDS)	-- Boots
			trigger_gamePanelInfo.mapWidgetVis_shopBootsGlow = false

			if craftingStage == 7 or (trigger_selection_Status.selectionSection == mainUI.Selection.selectionSections.SKILL_BUILDS and mainPanelStatus.main == 40)  then
				showShop = true

				if craftingStage == 7 then
					Shop.SetExclusion('crafted', 'component', 'consumable', 'boots')
				elseif trigger_selection_Status.selectionSection == mainUI.Selection.selectionSections.SKILL_BUILDS then --guide editing 	-- rmm do we exclude anything else in the build editor?
					Shop.SetExclusion('crafted')
				else
					Shop.ClearExclusions()
				end

				--[[
				local shopCategory = trigger_gamePanelInfo.shopCategory
				if string.len(shopCategory) <= 0 then
					shopCategory = 'ability'
				end

				trigger_gamePanelInfo.shopCategory = shopCategory
				Shop.SetFilter(shopCategory)

				trigger_gamePanelInfo:Trigger(false)
				--]]
			end
			widget:SetPassiveChildren(false)
		end
		
		if showShop then
			local XPos = 0
			local oldXPos = -containerWidth
			if minimapFlipped then --minimap flip
				XPos = GetScreenWidth()-containerWidth
				oldXPos = GetScreenWidth()+containerWidth
			end
			if (XPos ~= widget:GetX()) then
				widget:SetX(oldXPos)
				widget:SlideX(XPos, styles_uiSpaceShiftTime)
				widget:FadeIn(styles_uiSpaceShiftTime, function()
					--[[
					local triggerNPE = LuaTrigger.GetTrigger('newPlayerExperience')
					if gamePhase < 4 and craftingStage == 7 and triggerNPE.craftingIntroProgress == 0 then

						local craftingIntroStep = triggerNPE.craftingIntroStep

						if craftingIntroStep == 1 or (craftingIntroStep > 2 and craftingIntroStep <= 7) then
							if (craftingIntroStep > 2 and craftingIntroStep <= 7) then
								Crafting.ClearDesign()
							end
							newPlayerExperienceCraftingStep(2)
						end
					end
					--]]
				end)
				Shop.SetVisible(true)
			end
			Shop.SetVisible(true)
			widget:FadeIn(styles_uiSpaceShiftTime)
			libThread.threadFunc(function()
				wait(styles_uiSpaceShiftTime)
				widget:SetX(XPos)
			end)
		else
			local XPos = -containerWidth
			local oldXPos = 0
			if minimapFlipped then --minimap flip
				XPos = GetScreenWidth()+containerWidth
				oldXPos = GetScreenWidth()-containerWidth
			end
			if (XPos ~= widget:GetX()) then
				widget:SetX(oldXPos)
				widget:SlideX(XPos, styles_uiSpaceShiftTime)
			end
			widget:FadeOut(styles_uiSpaceShiftTime)
			Shop.SetVisible(false)
			libThread.threadFunc(function()
				wait(styles_uiSpaceShiftTime)
				widget:SetX(XPos)
			end)
		end


	end)
	
	function checkMinimapSide()
		if GetTrigger('GamePhase').gamePhase <= 3 then return end
		mainUI.minimapFlipped = GetCvarBool('ui_swapMinimap')
		if (minimapFlipped ~= mainUI.minimapFlipped) then
			-- Flip shop
			-- This has several children excluded from it because I don't want them to flip, for example the categories, or the level up panel.
			FlipWidgets(interface:GetWidget('gameShopContainer'), false, 1, true, false, {'gameShopItemListContainer', 'levelUpPanel', 'game_shop_build_select_abilities_combobox', 'gameShopFilterList', 'gameShopTabItemsButton', 'gameShopTabAbilitiesButton', 'gameShop_sell_area', 'gameShopCategoryList', 'gameShopItemItemChooser'})
			FlipWidgets(interface:GetWidget('gameShopHeader'), true, 1) -- flip header independently - flipping images.
			-- Flip stash if it exists.
			local stashContainers = interface:GetGroup('heroInventoryStashContainers')
			if stashContainers then
				for k,v in pairs(interface:GetGroup('heroInventoryStashContainers')) do
					FlipWidgets(v, false, 1, true)
				end
			end
			
			-- These shop widgets are implimented oddly and don't flip properly, so I excluded them from the main flip, and move it manually here.
			libThread.threadFunc(function()
				wait(1)
				-- Top, category icons
				interface:GetWidget('gameShopCategoryList'):SetX(minimapFlipped and '1h' or '0h')
				-- Trash can
				interface:GetWidget('gameShop_sell_area'  ):SetX(minimapFlipped and '-12h' or '50h')
				-- Swap dialog
				interface:GetWidget('gameShopItemItemChooserParent'):SetX(minimapFlipped and '-3h' or '3h')
			end)
		end
		minimapFlipped = mainUI.minimapFlipped
		
		
		-- Inventory
		local inventoryTrigger = GetTrigger('gameArrangeInventoryInfo')
		if inventoryTrigger then
			inventoryTrigger:Trigger(true)
		end
	end
	checkMinimapSide()
	container:RegisterWatchLua('optionsTrigger', function(widget, trigger)
		checkMinimapSide()
	end, false)
	

	container:RegisterWatchLua('gameShopFilterInfo', function(widget, trigger)
		ActivateRelatedFilters()
	end)

	for i=1,10,1 do
		gameShopRegisterCategoryTab(object, i, shopCategories[i], (i == 3))	-- Need to define categories (filters) later on
	end

	local tempID = ''

	for i=0,8,1 do
		gameShopRegisterBuyQueueEntry(object, i)
	end

	local function displayRelevantFilters(sourceWidget, category)
		if (not category) or Empty(category) then
			category = 'search'
		end

		trigger_gamePanelInfo.shopHasFiltersToDisplay = false

		for filterIndex,filterValueTable in pairs(filterTable) do
			if (filterVisibilityTable[category]) and (filterVisibilityTable[category][filterIndex]) then
				sourceWidget:GetWidget('shopFilterCheckbox'..filterIndex):SetVisible(1)
				trigger_gamePanelInfo.shopHasFiltersToDisplay = true
			else
				sourceWidget:GetWidget('shopFilterCheckbox'..filterIndex):SetVisible(0)
			end
		end
	end

	object:GetWidget('gameShopFilterList'):RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		if (trigger.shopView == 1 and not trigger.abilityPanel) then
			if ((trigger.shopShowFilters) or (trigger.shopCategory == '') or (trigger.shopCategory == 'components')) then
				displayRelevantFilters(widget, trigger.shopCategory)
				if (trigger.shopHasFiltersToDisplay) and string.len(trigger_shopFilter.forceCategory) <= 0 then
					widget:SetVisible(1)
				else
					widget:SetVisible(0)
				end
			else
				widget:SetVisible(0)
			end
		else
			widget:SetVisible(0)
		end
	end, false, nil, 'shopView', 'abilityPanel', 'shopShowFilters', 'shopCategory')

	object:GetWidget('shopToggleFilterBtn'):SetCallback('onclick', function(widget)
		trigger_gamePanelInfo.shopShowFilters = (not trigger_gamePanelInfo.shopShowFilters)
		trigger_gamePanelInfo:Trigger(false)
	end)

	object:GetWidget('shopToggleFilterBtn'):SetCallback('onmouseover', function(widget)
		simpleTipGrowYUpdate(true, nil, Translate('game_shop_filters'), Translate('game_shop_filters_tip'))
	end)

	object:GetWidget('shopToggleFilterBtn'):SetCallback('onmouseout', function(widget)
		simpleTipGrowYUpdate(false)
	end)

	object:GetWidget('shopToggleFilterBtnBacker'):RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		if (trigger.shopShowFilters) then
			widget:SetRenderMode('normal')
		else
			widget:SetRenderMode('grayscale')
		end
	end, false, nil, 'shopShowFilters')

	InitBuilds(object)

	FindChildrenClickCallbacks(gameShopContainer)
	object:GetWidget('gameShopCourierContainer'):RegisterWatchLua('gamePanelInfo', function(widget, trigger) widget:SetVisible(trigger.mapWidgetVis_courierButton) end, false, nil, 'mapWidgetVis_courierButton')
	object:GetWidget('gameShopTabItemsButton'):RegisterWatchLua('gamePanelInfo', function(widget, trigger) widget:SetEnabled(trigger.mapWidgetVis_shopItemList) end, false, nil, 'mapWidgetVis_shopItemList')
end	-- end gameShopRegister

gameShopRegister(object)

gameShopRegisterItemList(object)

local trigger_shopItemTipIntermediary_paramList = {
	{ name	= 'armor',											type		= 'number' },
	{ name	= 'baseAttackSpeed',									type		= 'number' },
	{ name	= 'attackSpeedMultiplier',							type		= 'number' },
	{ name	= 'baseHealthRegen',								type		= 'number' },
	{ name	= 'baseManaRegen',									type		= 'number' },
	{ name	= 'bonusDescription',								type		= 'string' },
	{ name	= 'canAfford',										type		= 'boolean' },
	{ name	= 'cooldown',										type		= 'number' },
	{ name	= 'cost',											type		= 'number' },
	{ name	= 'description',									type		= 'string' },
	{ name	= 'descriptionSimple',								type		= 'string' },
	{ name	= 'displayName',									type		= 'string' },
	{ name	= 'entity',											type		= 'string' },
	{ name	= 'exists',											type		= 'boolean' },
	-- { name	= 'healthRegen',									type		= 'number' },
	{ name	= 'icon',											type		= 'string' },
	{ name	= 'isActivatable',									type		= 'boolean' },
	{ name	= 'isInBackPack',									type		= 'boolean' },
	{ name	= 'isInStash',										type		= 'boolean' },
	{ name	= 'isLegendary',									type		= 'boolean' },
	{ name	= 'isOnCourier',									type		= 'boolean' },
	{ name	= 'isOwned',										type		= 'boolean' },
	{ name	= 'isPlayerCrafted',								type		= 'boolean' },
	{ name	= 'isRare',											type		= 'boolean' },
	{ name	= 'isRecipe',										type		= 'boolean' },
	{ name	= 'legendaryDescription',							type		= 'string' },
	{ name	= 'legendaryDisplayName',							type		= 'string' },
	{ name	= 'legendaryIcon',									type		= 'string' },
	{ name	= 'legendaryQuality',								type		= 'number' },
	{ name	= 'magicArmor',										type		= 'number' },
	{ name	= 'mitigation',										type		= 'number' },
	{ name	= 'resistance',										type		= 'number' },
	{ name	= 'manaCost',										type		= 'number' },
	-- { name	= 'manaRegen',										type		= 'number' },
	{ name	= 'maxHealth',										type		= 'number' },
	{ name	= 'maxMana',										type		= 'number' },
	{ name	= 'normalQuality',									type		= 'number' },
	{ name	= 'power',											type		= 'number' },
	{ name	= 'rareDescription',								type		= 'string' },
	{ name	= 'rareDisplayName',								type		= 'string' },
	{ name	= 'rareIcon',										type		= 'string' },
	{ name	= 'rareQuality',									type		= 'number' },
	{ name	= 'recipeScrollCanAfford',							type		= 'boolean' },
	{ name	= 'recipeScrollCost',								type		= 'number' },
	
	{ name	= 'currentEmpoweredEffectEntityName',				type		= 'string' },
	{ name	= 'currentEmpoweredEffectCost',						type		= 'number' },
	{ name	= 'currentEmpoweredEffectDisplayName',				type		= 'string' },
	{ name	= 'currentEmpoweredEffectDescription',				type		= 'string' },
	{ name	= 'empoweredEffect0EntityName',						type		= 'string' },
	{ name	= 'empoweredEffect1EntityName',						type		= 'string' },
	{ name	= 'empoweredEffect2EntityName',						type		= 'string' },
	{ name	= 'empoweredEffect3EntityName',						type		= 'string' },
	{ name	= 'empoweredEffect4EntityName',						type		= 'string' },
	{ name	= 'empoweredEffect5EntityName',						type		= 'string' },
	{ name	= 'empoweredEffect6EntityName',						type		= 'string' },
	{ name	= 'empoweredEffect7EntityName',						type		= 'string' },
	
	{ name	= 'active',											type		= 'boolean' },
	{ name	= 'isExpired',										type		= 'boolean' },
	{ name	= 'isPermanent',									type		= 'boolean' },
	{ name	= 'days',											type		= 'number' },
	{ name	= 'monthsLeft',										type		= 'number' },
	{ name	= 'daysLeft',										type		= 'number' },
	{ name	= 'hoursLeft',										type		= 'number' },
	{ name	= 'minutesLeft',									type		= 'number' },	
	
	{ name	= 'recipeComponentDetail'..(0)..'armor',					type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'baseAttackSpeed',			type		= 'number' },
	-- { name	= 'recipeComponentDetail'..(0)..'attackSpeedMultiplier',	type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'baseHealthRegen',		type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'baseManaRegen',			type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'canAfford',				type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(0)..'cooldown',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'cost',					type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'description',			type		= 'string' },
	{ name	= 'recipeComponentDetail'..(0)..'descriptionSimple',		type		= 'string' },
	{ name	= 'recipeComponentDetail'..(0)..'displayName',			type		= 'string' },
	{ name	= 'recipeComponentDetail'..(0)..'entity',					type		= 'string' },
	{ name	= 'recipeComponentDetail'..(0)..'exists',					type		= 'boolean' },
	-- { name	= 'recipeComponentDetail'..(0)..'healthRegen',			type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'icon',					type		= 'string' },
	{ name	= 'recipeComponentDetail'..(0)..'isInBackPack',			type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(0)..'isInStash',				type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(0)..'isOnCourier',			type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(0)..'isOwned',				type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(0)..'magicArmor',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'mitigation',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'resistance',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'manaCost',				type		= 'number' },
	-- { name	= 'recipeComponentDetail'..(0)..'manaRegen',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'maxHealth',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'maxMana',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(0)..'power',					type		= 'number' },

	{ name	= 'recipeComponentDetail'..(1)..'armor',					type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'baseAttackSpeed',			type		= 'number' },
	-- { name	= 'recipeComponentDetail'..(1)..'attackSpeedMultiplier',	type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'baseHealthRegen',		type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'baseManaRegen',			type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'canAfford',				type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(1)..'cooldown',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'cost',					type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'description',			type		= 'string' },
	{ name	= 'recipeComponentDetail'..(1)..'descriptionSimple',		type		= 'string' },
	{ name	= 'recipeComponentDetail'..(1)..'displayName',			type		= 'string' },
	{ name	= 'recipeComponentDetail'..(1)..'entity',					type		= 'string' },
	{ name	= 'recipeComponentDetail'..(1)..'exists',					type		= 'boolean' },
	-- { name	= 'recipeComponentDetail'..(1)..'healthRegen',			type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'icon',					type		= 'string' },
	{ name	= 'recipeComponentDetail'..(1)..'isInBackPack',			type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(1)..'isInStash',				type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(1)..'isOnCourier',			type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(1)..'isOwned',				type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(1)..'magicArmor',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'mitigation',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'resistance',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'manaCost',				type		= 'number' },
	-- { name	= 'recipeComponentDetail'..(1)..'manaRegen',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'maxHealth',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'maxMana',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(1)..'power',					type		= 'number' },


	{ name	= 'recipeComponentDetail'..(2)..'armor',					type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'baseAttackSpeed',			type		= 'number' },
	-- { name	= 'recipeComponentDetail'..(2)..'attackSpeedMultiplier',	type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'baseHealthRegen',		type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'baseManaRegen',			type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'canAfford',				type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(2)..'cooldown',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'cost',					type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'description',			type		= 'string' },
	{ name	= 'recipeComponentDetail'..(2)..'descriptionSimple',		type		= 'string' },
	{ name	= 'recipeComponentDetail'..(2)..'displayName',			type		= 'string' },
	{ name	= 'recipeComponentDetail'..(2)..'entity',					type		= 'string' },
	{ name	= 'recipeComponentDetail'..(2)..'exists',					type		= 'boolean' },
	-- { name	= 'recipeComponentDetail'..(2)..'healthRegen',			type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'icon',					type		= 'string' },
	{ name	= 'recipeComponentDetail'..(2)..'isInBackPack',			type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(2)..'isInStash',				type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(2)..'isOnCourier',			type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(2)..'isOwned',				type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(2)..'magicArmor',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'mitigation',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'resistance',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'manaCost',				type		= 'number' },
	-- { name	= 'recipeComponentDetail'..(2)..'manaRegen',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'maxHealth',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'maxMana',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(2)..'power',					type		= 'number' },

	{ name	= 'recipeComponentDetail'..(3)..'armor',					type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'baseAttackSpeed',			type		= 'number' },
	-- { name	= 'recipeComponentDetail'..(3)..'attackSpeedMultiplier',	type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'baseHealthRegen',		type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'baseManaRegen',			type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'canAfford',				type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(3)..'cooldown',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'cost',					type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'description',			type		= 'string' },
	{ name	= 'recipeComponentDetail'..(3)..'descriptionSimple',		type		= 'string' },
	{ name	= 'recipeComponentDetail'..(3)..'displayName',			type		= 'string' },
	{ name	= 'recipeComponentDetail'..(3)..'entity',					type		= 'string' },
	{ name	= 'recipeComponentDetail'..(3)..'exists',					type		= 'boolean' },
	-- { name	= 'recipeComponentDetail'..(3)..'healthRegen',			type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'icon',					type		= 'string' },
	{ name	= 'recipeComponentDetail'..(3)..'isInBackPack',			type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(3)..'isInStash',				type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(3)..'isOnCourier',			type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(3)..'isOwned',				type		= 'boolean' },
	{ name	= 'recipeComponentDetail'..(3)..'magicArmor',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'mitigation',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'resistance',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'manaCost',				type		= 'number' },
	-- { name	= 'recipeComponentDetail'..(3)..'manaRegen',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'maxHealth',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'maxMana',				type		= 'number' },
	{ name	= 'recipeComponentDetail'..(3)..'power',					type		= 'number' },

}

for i=0,3,1 do
--[[
	libGeneral.tableMerge({
		{ name	= 'recipeComponentDetail'..i..'armor',					type		= 'number' },
		{ name	= 'recipeComponentDetail'..i..'baseAttackSpeed',			type		= 'number' },
		-- { name	= 'recipeComponentDetail'..i..'attackSpeedMultiplier',	type		= 'number' },
		{ name	= 'recipeComponentDetail'..i..'baseHealthRegen',		type		= 'number' },
		{ name	= 'recipeComponentDetail'..i..'baseManaRegen',			type		= 'number' },
		{ name	= 'recipeComponentDetail'..i..'canAfford',				type		= 'boolean' },
		{ name	= 'recipeComponentDetail'..i..'cooldown',				type		= 'number' },
		{ name	= 'recipeComponentDetail'..i..'cost',					type		= 'number' },
		{ name	= 'recipeComponentDetail'..i..'description',			type		= 'string' },
		{ name	= 'recipeComponentDetail'..i..'descriptionSimple',		type		= 'string' },
		{ name	= 'recipeComponentDetail'..i..'displayName',			type		= 'string' },
		{ name	= 'recipeComponentDetail'..i..'entity',					type		= 'string' },
		{ name	= 'recipeComponentDetail'..i..'exists',					type		= 'boolean' },
		-- { name	= 'recipeComponentDetail'..i..'healthRegen',			type		= 'number' },
		{ name	= 'recipeComponentDetail'..i..'icon',					type		= 'string' },
		{ name	= 'recipeComponentDetail'..i..'isInBackPack',			type		= 'boolean' },
		{ name	= 'recipeComponentDetail'..i..'isInStash',				type		= 'boolean' },
		{ name	= 'recipeComponentDetail'..i..'isOnCourier',			type		= 'boolean' },
		{ name	= 'recipeComponentDetail'..i..'isOwned',				type		= 'boolean' },
		{ name	= 'recipeComponentDetail'..i..'magicArmor',				type		= 'number' },
		{ name	= 'recipeComponentDetail'..i..'manaCost',				type		= 'number' },
		-- { name	= 'recipeComponentDetail'..i..'manaRegen',				type		= 'number' },
		{ name	= 'recipeComponentDetail'..i..'maxHealth',				type		= 'number' },
		{ name	= 'recipeComponentDetail'..i..'maxMana',				type		= 'number' },
		{ name	= 'recipeComponentDetail'..i..'power',					type		= 'number' },
	}, trigger_shopItemTipIntermediary_paramList)
	--]]
end

local trigger_shopItemTipIntermediary	= LuaTrigger.CreateCustomTrigger('shopItemTipIntermediary', trigger_shopItemTipIntermediary_paramList)	-- All shop item tips widgets should only register to this trigger.  This significantly improves performance by dramatically reducing the amount of widget updates as the data is sourced from new triggers


local trigger_shopItemTipInfo = LuaTrigger.CreateCustomTrigger('shopItemTipInfo', {
	{ name	= 'index',			type		= 'number' },
	{ name	= 'itemType',		type		= 'string' },
	{ name	= 'isComponent',	type		= 'boolean' },
	{ name	= 'displayCrafted',	type		= 'boolean' },
	{ name	= 'componentID',	type		= 'number' },
})

local function shopItemTipRegisterStat(object, statName, heroTriggerName, iconPath, prefix)
	prefix = prefix or ''
	local container				= object:GetWidget('shopItemTip' .. prefix .. '_compare_'..heroTriggerName)
	local name					= object:GetWidget('shopItemTip' .. prefix .. '_compare_'..heroTriggerName..'Name')
	local value					= object:GetWidget('shopItemTip' .. prefix .. '_compare_'..heroTriggerName..'Value')
	local descriptionPanel		= object:GetWidget('shopItemTip' .. prefix .. '_compare_'..heroTriggerName..'DescriptionPanel')
	local description			= object:GetWidget('shopItemTip' .. prefix .. '_compare_'..heroTriggerName..'Description')
	local activeBacker			= object:GetWidget('shopItemTip' .. prefix .. '_compare_'..heroTriggerName..'ActiveBacker')

	libGeneral.createGroupTrigger('shopItemTipStatGroup'..heroTriggerName, {
		'shopItemTipIntermediary.'..statName,
		'shopItemTipIntermediary.isOwned',
		'shopItemTipIntermediary.isRecipe',
		'shopItemTipIntermediary.recipeComponentDetail0'..statName,
		'shopItemTipIntermediary.recipeComponentDetail1'..statName,
		'shopItemTipIntermediary.recipeComponentDetail2'..statName,
		'shopItemTipIntermediary.recipeComponentDetail0isOwned',
		'shopItemTipIntermediary.recipeComponentDetail1isOwned',
		'shopItemTipIntermediary.recipeComponentDetail2isOwned',
		'shopItemTipIntermediary.recipeComponentDetail0exists',
		'shopItemTipIntermediary.recipeComponentDetail1exists',
		'shopItemTipIntermediary.recipeComponentDetail2exists',
		'HeroUnit.'..heroTriggerName,
	})

	if (not container) then return end

	container:RegisterWatchLua('shopItemTipStatGroup'..heroTriggerName, function(widget, groupTrigger)
		local triggerItem	= groupTrigger['shopItemTipIntermediary']
		local heroValue		= groupTrigger['HeroUnit'][heroTriggerName]
		local fullItemValue	= triggerItem[statName]

		local ownedValue	= 0
		
		if (triggerItem.isOwned or true) then	-- All the things
			ownedValue = fullItemValue
		else	-- Figure out components
			if triggerItem.isRecipe then
				for i=0,2,1 do
					if triggerItem['recipeComponentDetail'..i..'exists'] and (triggerItem['recipeComponentDetail'..i..'isOwned'] or true) then
						ownedValue = ownedValue + triggerItem['recipeComponentDetail'..i..statName]
					end
				end
			end
		end

		if (ownedValue > 0) then
		
			local statTotal
			descriptionPanel:SetVisible(true)
			activeBacker:SetVisible(true)
			name:SetColor(styles_colors_stats[heroTriggerName])
			
			
			local valueSuffix	= ''
			if statName == 'baseAttackSpeed' then
				valueSuffix = '%'
				heroValue = heroValue / 100
			end
			
			local value1		= itemStatTypeFormat_itemTip[statName](fullItemValue)
			local value2	= itemStatTypeFormat_itemTip[statName](heroValue + fullItemValue - ownedValue)
			
			description:SetText(Translate('shop_item_compare_stat_'..heroTriggerName..'_tip', 'value', value1))

			value:SetText('(+' .. value1 .. valueSuffix .. ') ' .. value2 .. valueSuffix)
		else
			value:SetText('')
			name:SetColor(styles_colors_stats_empty)
			descriptionPanel:SetVisible(false)
			activeBacker:SetVisible(false)
		end

	end)
end

local function shopItemTipRegisterComponent(object, index)
	local container		= object:GetWidget('shopItemTipComponent'..index)
	local icon			= object:GetWidget('shopItemTipComponent'..index..'Icon')
	
	local ownedLabel	= object:GetWidget('shopItemTipComponent'..index..'OwnedLabel')
	local typeIcon		= object:GetWidget('shopItemTipComponent'..index..'TypeIcon')

	local statValue		= object:GetWidget('shopItemTipComponent'..index..'StatValue')
	local statName		= object:GetWidget('shopItemTipComponent'..index..'StatName')

	icon:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		widget:SetTexture(trigger['recipeComponentDetail'..index..'icon'])
	end, false, nil, 'recipeComponentDetail'..index..'icon')

	ownedLabel:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		if trigger['recipeComponentDetail'..index..'isOwned'] or trigger.isOwned then
			widget:SetColor(style_crafting_tier_common_color)
			widget:SetText(Translate('general_owned_cap'))
		else
			widget:SetColor(0.5, 0.5, 0.5)
			widget:SetText(Translate('general_required_cap'))
		end
	end, false, nil, 'recipeComponentDetail'..index..'isOwned', 'isOwned')
	
	typeIcon:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		if trigger['recipeComponentDetail'..index..'isOwned'] or trigger.isOwned then
			widget:SetRenderMode('normal')
		else
			widget:SetRenderMode('grayscale')
		end
	end, false, nil, 'recipeComponentDetail'..index..'isOwned', 'isOwned')

	ownedLabel:RegisterWatchLua('GamePhase', function(widget, trigger)
		widget:SetVisible(trigger.gamePhase >= 5)
	end, false, nil, 'gamePhase')
	
	typeIcon:RegisterWatchLua('GamePhase', function(widget, trigger)
		widget:SetVisible(trigger.gamePhase >= 5)
	end, false, nil, 'gamePhase')
	
	container:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		if trigger['recipeComponentDetail'..index..'exists'] then
			if not widget:IsVisibleSelf() then
				widget:SetVisible(true)
			end
		else
			if widget:IsVisibleSelf() then
				widget:SetVisible(false)
			end
		end
	end, false, nil, 'recipeComponentDetail'..index..'exists')

	statValue:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		local statInfo	= getShopItemStatInfo(trigger, index)
		
		if statInfo then
			statValue:SetText(
				itemStatTypeFormat_itemTip[statInfo.param](trigger['recipeComponentDetail'..index..statInfo.param], false)
			)
			statName:SetText(Translate('shop_item_stat_name_'..statInfo.param))
		else
			-- rmm handle move speed, etc.
			statValue:SetText('')
			statName:SetText('')
		end
	end, false, nil,
	'recipeComponentDetail'..index..'power',
	'recipeComponentDetail'..index..'baseAttackSpeed',
	'recipeComponentDetail'..index..'maxHealth',
	'recipeComponentDetail'..index..'maxMana',
	'recipeComponentDetail'..index..'baseHealthRegen',
	'recipeComponentDetail'..index..'baseManaRegen')
end

local function shopItemTipRegisterBonus(object, bonusType, rarityExistsParam, paramPrefix, qualityPrefix)
	local container		= object:GetWidget('shopItemTip_'..bonusType..'Bonus')
	local icon			= object:GetWidget('shopItemTip_'..bonusType..'Bonus_icon')
	local name			= object:GetWidget('shopItemTip_'..bonusType..'Bonus_label_1')
	local description	= object:GetWidget('shopItemTip_'..bonusType..'Bonus_label_3')
	local value			= object:GetWidget('shopItemTip_'..bonusType..'Bonus_label_2')

	qualityPrefix = qualityPrefix or paramPrefix

	value:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		if rarityExistsParam and not trigger[rarityExistsParam] then
			return
		end

		widget:SetText(Translate('abilitytip_craft_bonustier', 'tier', math.floor(trigger[qualityPrefix..'Quality'] * 10)))
	end, false, nil, 'isPlayerCrafted', qualityPrefix..'Quality', rarityExistsParam)

	if rarityExistsParam then

		icon:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
			if rarityExistsParam and not trigger[rarityExistsParam] then
				return
			end

			widget:SetTexture(trigger[paramPrefix..'Icon'])
		end, false, nil, 'isPlayerCrafted', rarityExistsParam)

		name:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
			if rarityExistsParam and not trigger[rarityExistsParam] then
				return
			end

			widget:SetText(trigger[paramPrefix..'DisplayName'])
		end, false, nil, 'isPlayerCrafted', rarityExistsParam)
	end


	container:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		local showBonus = false

		if trigger.isPlayerCrafted and trigger_shopItemTipInfo.displayCrafted and (not trigger_shopItemTipInfo.isComponent) then
			
			local quality = trigger[qualityPrefix..'Quality'] or 0
			if (quality == 0) then
				showBonus = false
			elseif rarityExistsParam then
				showBonus = trigger[rarityExistsParam]
			else
				showBonus = true
			end
		end

		if showBonus then
			if not widget:IsVisibleSelf() then
				widget:SetVisible(true)
			end
		else
			if widget:IsVisibleSelf() then
				widget:SetVisible(false)
			end
		end
	end, false, nil, 'isPlayerCrafted', rarityExistsParam)

	description:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		if rarityExistsParam and not trigger[rarityExistsParam] then
			return
		end
		widget:SetText(StripColorCodes(trigger[paramPrefix..'Description']))
	end, false, nil, 'isPlayerCrafted', paramPrefix..'Description', rarityExistsParam)
end

local function shopItemTipRegisterImbuement(object, index)
	local container		= object:GetWidget('shopItemTip_'..index..'Imbuement')
	local icon			= object:GetWidget('shopItemTip_'..index..'Imbuement_icon')
	local name			= object:GetWidget('shopItemTip_'..index..'Imbuement_label_1')
	local description	= object:GetWidget('shopItemTip_'..index..'Imbuement_label_3')
	-- local value			= object:GetWidget('shopItemTip_'..index..'Imbuement_label_2')

	-- value:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		-- if (trigger.currentEmpoweredEffectEntityName) and (not Empty(trigger.currentEmpoweredEffectEntityName)) and ValidateEntity(trigger.currentEmpoweredEffectEntityName) then
			-- widget:SetText(trigger.currentEmpoweredEffectCost or '?Cost?')
		-- else
			-- widget:SetText('')
		-- end
	-- end, false, nil, 'currentEmpoweredEffectEntityName', 'currentEmpoweredEffectCost')

	container:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		if (trigger.isRecipe) and (trigger.currentEmpoweredEffectEntityName) and (not Empty(trigger.currentEmpoweredEffectEntityName)) and ValidateEntity(trigger.currentEmpoweredEffectEntityName) then
			if not widget:IsVisibleSelf() then
				widget:SetVisible(true)
			end
		else
			if widget:IsVisibleSelf() then
				widget:SetVisible(false)
			end 
		end
	end, false, nil, 'currentEmpoweredEffectEntityName', 'isRecipe')
	
	icon:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		if (trigger.currentEmpoweredEffectEntityName) and (not Empty(trigger.currentEmpoweredEffectEntityName)) and ValidateEntity(trigger.currentEmpoweredEffectEntityName) then
			if  string.find(trigger['currentEmpoweredEffectEntityName'], '1') then
				widget:SetTexture('/ui/main/crafting/textures/imbue_icon_selected_' .. 0 .. '.tga')
			elseif string.find(trigger['currentEmpoweredEffectEntityName'], '2')  then
				widget:SetTexture('/ui/main/crafting/textures/imbue_icon_selected_' .. 1 .. '.tga')		
			elseif string.find(trigger['currentEmpoweredEffectEntityName'], '3')  then
				widget:SetTexture('/ui/main/crafting/textures/imbue_icon_selected_' .. 2 .. '.tga')	
			elseif string.find(trigger['currentEmpoweredEffectEntityName'], '4')  then
				widget:SetTexture('/ui/main/crafting/textures/imbue_icon_selected_' .. 3 .. '.tga')	
			elseif string.find(trigger['currentEmpoweredEffectEntityName'], '5')  then
				widget:SetTexture('/ui/main/crafting/textures/imbue_icon_selected_' .. 4 .. '.tga')	
			elseif string.find(trigger['currentEmpoweredEffectEntityName'], '6')  then
				widget:SetTexture('/ui/main/crafting/textures/imbue_icon_selected_' .. 5 .. '.tga')		
			elseif string.find(trigger['currentEmpoweredEffectEntityName'], '7')  then
				widget:SetTexture('/ui/main/crafting/textures/imbue_icon_selected_' .. 6 .. '.tga')	
			elseif string.find(trigger['currentEmpoweredEffectEntityName'], '8')  then
				widget:SetTexture('/ui/main/crafting/textures/imbue_icon_selected_' .. 7 .. '.tga')					
			else
				widget:SetTexture('/ui/main/crafting/textures/imbue_icon_selected.tga')
			end			
		else
			widget:SetTexture('/ui/main/crafting/textures/imbue_icon.tga')
		end
	end, false, nil, 'currentEmpoweredEffectEntityName')

	name:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		if (trigger.currentEmpoweredEffectEntityName) and (not Empty(trigger.currentEmpoweredEffectEntityName)) and ValidateEntity(trigger.currentEmpoweredEffectEntityName) then
			widget:SetText(trigger.currentEmpoweredEffectDisplayName or '?Name?')
		else
			widget:SetText(Translate('crafting_no_imbuement'))
		end
	end, false, nil, 'currentEmpoweredEffectEntityName', 'currentEmpoweredEffectDisplayName')

	description:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		if (trigger.currentEmpoweredEffectEntityName) and (not Empty(trigger.currentEmpoweredEffectEntityName)) and ValidateEntity(trigger.currentEmpoweredEffectEntityName) then
			widget:SetText(trigger.currentEmpoweredEffectDescription or '?Description?')
		else
			widget:SetText(Translate('crafting_no_imbuement'))
		end
	end, false, nil, 'currentEmpoweredEffectEntityName', 'currentEmpoweredEffectDescription')

end

local function shopItemTipRegister(object)
	local container						= object:GetWidget('shopItemTip')
	local icon							= object:GetWidget('shopItemTipIcon')
	local iconScroll					= object:GetWidget('shopItemTipIconScroll')
	local name							= object:GetWidget('shopItemTipName')
	local description					= object:GetWidget('shopItemTipDescription')
	local cost							= object:GetWidget('shopItemTipCost')
	local cooldownContainer				= object:GetWidget('shopItemTipCooldownContainer')
	local components					= object:GetWidget('shopItemTipComponents')
	local cooldown						= object:GetWidget('shopItemTipCooldown')

	local bonusRareIcon					= object:GetWidget('shopItemTip_rareBonus_icon')
	local bonusRareName					= object:GetWidget('shopItemTip_rareBonus_label_1')
	local bonusRareDescription			= object:GetWidget('shopItemTip_rareBonus_label_2')
	local bonusRareValue				= object:GetWidget('shopItemTip_rareBonus_label_3')

	local bonusLegendaryIcon			= object:GetWidget('shopItemTip_legendaryBonus_icon')
	local bonusLegendaryName			= object:GetWidget('shopItemTip_legendaryBonus_label_1')
	local bonusLegendaryDescription		= object:GetWidget('shopItemTip_legendaryBonus_label_2')
	local bonusLegendaryValue			= object:GetWidget('shopItemTip_legendaryBonus_label_3')

	local moreInfo						= object:GetWidget('shopItemTipMoreInfo')

	local recipeOwnedLabel				= object:GetWidget('shopItemTipRecipeOwnedLabel')
	local recipeTypeIcon				= object:GetWidget('shopItemTipRecipeTypeIcon')
	
	recipeOwnedLabel:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		if trigger['isOwned'] then
			widget:SetColor(style_crafting_tier_common_color)
			if trigger.isRecipe then
				widget:SetText(Translate('general_completed'))
			else
				widget:SetText(Translate('general_owned_cap'))
			end
			
		else
			widget:SetColor(0.5, 0.5, 0.5)
			widget:SetText(Translate('general_required_cap'))
		end
	end, false, nil, 'isOwned', 'isRecipe')
	
	recipeTypeIcon:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		if trigger['isOwned'] then
			widget:SetRenderMode('normal')
		else
			widget:SetRenderMode('grayscale')
		end
	end, false, nil, 'isOwned')

	local lastIndex			= -1

	function shopItemTipShow(index, itemType, isComponent, componentID, displayCrafted, xOffset, yOffset)
		itemType = itemType or ''
		isComponent = isComponent or false
		if (displayCrafted == nil) then
			displayCrafted = true
		end
		componentID = componentID or -1
		trigger_shopItemTipInfo.index = index
		trigger_shopItemTipInfo.itemType = itemType
		trigger_shopItemTipInfo.isComponent = isComponent
		trigger_shopItemTipInfo.componentID = componentID
		trigger_shopItemTipInfo.displayCrafted = displayCrafted
		trigger_shopItemTipInfo:Trigger(false)
	end

	moreInfo:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
		widget:SetVisible(trigger.moreInfoKey)
	end, false, nil, 'moreInfoKey')

	function shopItemTipHide()
		trigger_shopItemTipInfo.index = -1
		trigger_shopItemTipInfo:Trigger(false)
	end

	shopItemTipRegisterStat(object, 'power', 'power', '/ui/elements:itemtype_damage')
	shopItemTipRegisterStat(object, 'baseAttackSpeed', 'attackSpeed', '/ui/elements:itemtype_boots')
	shopItemTipRegisterStat(object, 'armor', 'armor', '/ui/elements:itemtype_physdefense')
	shopItemTipRegisterStat(object, 'magicArmor', 'magicArmor', '/ui/elements:itemtype_magdefense')
	shopItemTipRegisterStat(object, 'mitigation', 'mitigation', '/ui/elements:itemtype_physdefense')
	shopItemTipRegisterStat(object, 'resistance', 'magicArmor', '/ui/elements:itemtype_resistance')
	shopItemTipRegisterStat(object, 'maxHealth', 'healthMax', '/ui/elements:itemtype_health')
	shopItemTipRegisterStat(object, 'maxMana', 'manaMax', '/ui/elements:itemtype_mana')
	shopItemTipRegisterStat(object, 'baseHealthRegen', 'healthRegen', '/ui/elements:itemtype_healthregen')
	shopItemTipRegisterStat(object, 'baseManaRegen', 'manaRegen', '/ui/elements:itemtype_manaregen')

	for i=0,2,1 do
		shopItemTipRegisterComponent(object, i)
	end

	container:RegisterWatch('gameShowSkills', function(widget, keyDown)
		if AtoB(keyDown) and LuaTrigger.GetTrigger('gamePanelInfo').mapWidgetVis_abilityPanel then
			gameToggleShowSkills(widget)
		end
	end)

	local function updateCooldown(widget, trigger, cooldownParam)
		local cooldown = trigger[cooldownParam]

		if cooldown > 0 then
			widget:SetText(libNumber.round(cooldown / 1000, 1))
		end
	end

	local function componentsUpdate(widget, trigger)
		local showWidget = trigger.recipeComponentDetail0exists and trigger.isRecipe
		if showWidget then
			if not widget:IsVisibleSelf() then
				widget:SetVisible(true)
			end
		else
			if widget:IsVisibleSelf() then
				widget:SetVisible(false)
			end
		end
	end

	local shopItemTip_bottomInfoFrame	= object:GetWidget('shopItemTip_bottomInfoFrame')
	
	shopItemTip_bottomInfoFrame:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		local showWidget = ((trigger.isPlayerCrafted ) and (not trigger.isPermanent) and (((trigger.isExpired) or (trigger.days > 0) or (trigger.monthsLeft > 0) or (trigger.daysLeft > 0) or (trigger.hoursLeft > 0) or (trigger.minutesLeft > 0)))) or (trigger.isActivatable and not trigger_shopItemTipInfo.isComponent) or (trigger.cooldown > 0)
		if showWidget then
			if not widget:IsVisibleSelf() then
				widget:SetVisible(true)
			end	
		else
			if widget:IsVisibleSelf() then
				widget:SetVisible(false)
			end
		end			
	end, false, 'shopItemWatch', 'isExpired', 'isPermanent', 'isPlayerCrafted', 'days', 'monthsLeft', 'daysLeft', 'hoursLeft', 'minutesLeft', 'entity', 'isActivatable', 'cooldown')	
	
	local shopItemTip_lifetime	= object:GetWidget('shopItemTip_lifetime')
	local shopItemTip_lifetimeFrame	= object:GetWidget('shopItemTip_lifetimeFrame')	
	local shopItemTip_lifetime_label = object:GetWidget('shopItemTip_lifetime_label')	
	
	shopItemTip_lifetime:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		local showWidget = (trigger.isPlayerCrafted ) and (not trigger.isPermanent) and (((trigger.isExpired) or (trigger.days > 0) or (trigger.monthsLeft > 0) or (trigger.daysLeft > 0) or (trigger.hoursLeft > 0) or (trigger.minutesLeft > 0)))
		if showWidget then
			if not widget:IsVisibleSelf() then
				widget:SetVisible(true)
				shopItemTip_lifetimeFrame:SetVisible(true)
			end
			local careFactor = 2
			local label = Translate('general_expires_in') .. ': '
			if (trigger.monthsLeft > 0) then
				careFactor = careFactor - 1
				label = label .. Translate('general_months_amount', 'amount', trigger.monthsLeft) .. ' '
			end
			if (trigger.daysLeft > 0) then
				careFactor = careFactor - 1
				label = label .. Translate('general_days_amount', 'amount', trigger.daysLeft) .. ' '
			end
			if (trigger.hoursLeft > 0) and (careFactor > 0) then
				careFactor = careFactor - 1
				label = label .. Translate('general_hours_amount', 'amount', trigger.hoursLeft) .. ' '
			end
			if (trigger.minutesLeft > 0) and (careFactor > 0) then
				label = label .. Translate('general_minutes_amount', 'amount', trigger.minutesLeft) .. ' '
			end
			if (trigger.isExpired) then
				label = Translate('general_expired_now')
			end
			shopItemTip_lifetime_label:SetText(label)
		else
			if widget:IsVisibleSelf() then
				widget:SetVisible(false)
				shopItemTip_lifetimeFrame:SetVisible(false)
			end
		end
	end, false, 'shopItemWatch', 'isExpired', 'isPermanent', 'isPlayerCrafted', 'days', 'monthsLeft', 'daysLeft', 'hoursLeft', 'minutesLeft', 'entity')		
		
	
	local activatableContainer	= object:GetWidget('shopItemTip_activatable')
	local activatableContainerFrame	= object:GetWidget('shopItemTip_activatableFrame')
	-- local activatableLabelIcon	= object:GetWidget('shopItemTip_activatableIcon')
	-- local activatableLabel1		= object:GetWidget('shopItemTip_activatableLabel1')
	-- local activatableLabel2		= object:GetWidget('shopItemTip_activatableLabel2')
	-- local activatableLabel3		= object:GetWidget('shopItemTip_activatableLabel3')

	shopItemTipRegisterBonus(object, 'analog', nil, 'bonus', 'normal')
	shopItemTipRegisterBonus(object, 'rare', 'isRare', 'rare', nil)
	shopItemTipRegisterBonus(object, 'legendary', 'isLegendary', 'legendary', nil)
	
	shopItemTipRegisterImbuement(object, 0)

	icon:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		local triggerIcon	= trigger.icon

		widget:SetTexture(triggerIcon)
		iconScroll:SetTexture(triggerIcon)
	end, false, nil, 'icon')
	cost:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger) widget:SetText(libNumber.commaFormat(trigger.cost)) end, false, nil, 'cost')

	activatableContainer:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		local showWidget = (trigger.isActivatable and not trigger_shopItemTipInfo.isComponent)
		if showWidget then
			if not widget:IsVisibleSelf() then
				widget:SetVisible(true)
				activatableContainerFrame:SetVisible(true)
			end
		else
			if widget:IsVisibleSelf() then
				widget:SetVisible(false)
				activatableContainerFrame:SetVisible(false)
			end
		end
	end, false, 'shopItemWatch', 'isActivatable')


	name:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)	-- rmm component check for plain green name
		if trigger.exists then
			local isRare			= false
			local isLegendary		= false

			local isCrafted			= trigger.isPlayerCrafted

			local rareBonus			= ''
			local legendaryBonus	= ''

			if (trigger.isRecipe) and isCrafted and (trigger_shopItemTipInfo.displayCrafted) then
				rareBonus		= trigger.currentEmpoweredEffectDisplayName
				legendaryBonus	= trigger.legendaryDisplayName
				isRare			= (not Empty(trigger.currentEmpoweredEffectDisplayName))
				isLegendary		= trigger.isLegendary
			end

			local fullItemName = libGeneral.craftedItemFormatName(trigger.displayName, isRare, rareBonus, isLegendary, legendaryBonus)

			widget:SetText(fullItemName)

			widget:SetColor(libGeneral.craftedItemGetNameColor(isRare, isRare))

			--[[
			if trigger.isOwned then
				widget:SetColor('#999999')
			elseif isCrafted then

			else
				widget:SetColor(style_crafting_tier_common_color)
			end
			--]]

		end
	end, false, nil,
		'displayName',
		'exists',
		'isLegendary',
		'isRare',
		'rareDisplayName',
		'legendaryDisplayName',
		'isPlayerCrafted',
		'isRecipe',
		'currentEmpoweredEffectDisplayName'
	)

	components:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger) componentsUpdate(widget, trigger, 'recipeComponentDetail0exists') end, false, nil, 'recipeComponentDetail0exists', 'isRecipe')
	
	
	local recipeIconContainer	= object:GetWidget('shopItemTipRecipeIconContainer')
	local descriptionContainer	= object:GetWidget('shopItemTipRecipeDescriptionContainer')
	
	recipeIconContainer:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)


		if trigger.isRecipe then
		
			local descWidth
			if LuaTrigger.GetTrigger('GamePhase').gamePhase >= 5 then
				descWidth = '-4.5h'
			else
				descWidth = '-45s'
			end
		
			recipeIconContainer:SetVisible(true)
			descriptionContainer:SetWidth(descWidth)
		else
			recipeIconContainer:SetVisible(false)
			descriptionContainer:SetWidth('100%')
		end
	end, false, nil, 'isRecipe')
	
	description:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger) widget:SetText(trigger.description) end, false, nil, 'description')

	cooldownContainer:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		widget:SetVisible(trigger.cooldown > 0)
	end, false, nil, 'cooldown')

	cooldown:RegisterWatchLua('shopItemTipIntermediary', function(widget, trigger)
		updateCooldown(widget, trigger, 'cooldown')
	end, false, nil, 'cooldown')

	-- shopItemTipWatch

	local function containerTriggerGetParamList(isComponent, cooldownParam, costParam, recipeParam, paramPrefix, existsParam, isInventory, isFromCrafting)
		local paramList = {
			'armor',
			'baseAttackSpeed',
			'attackSpeedMultiplier',
			'baseHealthRegen',
			'baseManaRegen',
			'bonusDescription',
			'canAfford',
			'cooldown',
			'cost',
			'description',
			'descriptionSimple',
			'displayName',
			'entity',
			'exists',
			'healthRegen',
			'icon',
			'isActivatable',

			'isLegendary',

			'isPlayerCrafted',
			'isRare',
			'isRecipe',
			'legendaryDescription',
			'legendaryDisplayName',
			'legendaryIcon',
			'legendaryQuality',
			'magicArmor',
			'mitigation',
			'resistance',
			'manaCost',
			'manaRegen',
			'maxHealth',
			'maxMana',
			'normalQuality',
			'power',
			'rareDescription',
			'rareDisplayName',
			'rareIcon',
			'rareQuality',
			'recipeScrollCanAfford',
			'recipeScrollCost',
			
			'active',
			'isExpired',
			'isPermanent',
			'days',
			'monthsLeft',
			'daysLeft',
			'hoursLeft',
			'minutesLeft',			
			
		}


		if not isFromCrafting then
			table.insert(paramList, 'isOnCourier')
			table.insert(paramList, 'isOwned')
			table.insert(paramList, 'isInBackPack')
			table.insert(paramList, 'isInStash')
		end

		if not isComponent and not isInventory then
			for i=0,3,1 do
				libGeneral.tableMerge({
					'recipeComponentDetail'..i..'armor',
					'recipeComponentDetail'..i..'baseAttackSpeed',
					'recipeComponentDetail'..i..'attackSpeedMultiplier',
					'recipeComponentDetail'..i..'baseHealthRegen',
					'recipeComponentDetail'..i..'baseManaRegen',
					'recipeComponentDetail'..i..'canAfford',
					'recipeComponentDetail'..i..'cooldown',
					'recipeComponentDetail'..i..'cost',
					'recipeComponentDetail'..i..'description',
					'recipeComponentDetail'..i..'descriptionSimple',
					'recipeComponentDetail'..i..'displayName',
					'recipeComponentDetail'..i..'entity',
					'recipeComponentDetail'..i..'exists',
					'recipeComponentDetail'..i..'healthRegen',
					'recipeComponentDetail'..i..'icon',
					'recipeComponentDetail'..i..'isInBackPack',
					'recipeComponentDetail'..i..'isInStash',
					'recipeComponentDetail'..i..'isOnCourier',
					'recipeComponentDetail'..i..'isOwned',
					'recipeComponentDetail'..i..'magicArmor',
					'recipeComponentDetail'..i..'mitigation',
					'recipeComponentDetail'..i..'resistance',
					'recipeComponentDetail'..i..'manaCost',
					'recipeComponentDetail'..i..'manaRegen',
					'recipeComponentDetail'..i..'maxHealth',
					'recipeComponentDetail'..i..'maxMana',
					'recipeComponentDetail'..i..'power',
				}, paramList)
			end
		end

		return paramList
	end

	local function containerTriggerUpdate(widget, trigger, isComponent, cooldownParam, costParam, recipeParam, paramPrefix, iconParam, isInventory, isFromCrafting)
		trigger_shopItemTipIntermediary.cost = trigger[paramPrefix..costParam]
		trigger_shopItemTipIntermediary.displayName = trigger[paramPrefix..'displayName']
		trigger_shopItemTipIntermediary.exists = trigger[paramPrefix..'exists']
		-- trigger_shopItemTipIntermediary.healthRegen = trigger[paramPrefix..'healthRegen']
		trigger_shopItemTipIntermediary.icon = trigger[paramPrefix..iconParam]

		-- trigger_shopItemTipIntermediary.entity = trigger[paramPrefix..'entity']
		-- trigger_shopItemTipIntermediary.descriptionSimple = ''

		trigger_shopItemTipIntermediary.isPlayerCrafted = trigger.isPlayerCrafted or false
		-- trigger_shopItemTipIntermediary.attackSpeedMultiplier = trigger[paramPrefix..'attackSpeedMultiplier']
		-- trigger_shopItemTipIntermediary.manaRegen = 0


		if isInventory then
			trigger_shopItemTipIntermediary.isRecipe = ((not isComponent) and trigger.isRecipeCompleted)
		else
			trigger_shopItemTipIntermediary.isRecipe = ((not isComponent) and trigger.isRecipe)
		end

		trigger_shopItemTipIntermediary.baseAttackSpeed = trigger[paramPrefix..'baseAttackSpeed']
		trigger_shopItemTipIntermediary.magicArmor = trigger[paramPrefix..'magicArmor']
		trigger_shopItemTipIntermediary.armor = trigger[paramPrefix..'armor']
		trigger_shopItemTipIntermediary.mitigation = trigger[paramPrefix..'mitigation']
		trigger_shopItemTipIntermediary.resistance = trigger[paramPrefix..'resistance']
		
		trigger_shopItemTipIntermediary.maxHealth = trigger[paramPrefix..'maxHealth']
		trigger_shopItemTipIntermediary.maxMana = trigger[paramPrefix..'maxMana']
		trigger_shopItemTipIntermediary.power = trigger[paramPrefix..'power']
		trigger_shopItemTipIntermediary.baseHealthRegen = trigger[paramPrefix..'baseHealthRegen']
		trigger_shopItemTipIntermediary.baseManaRegen = trigger[paramPrefix..'baseManaRegen']

		trigger_shopItemTipIntermediary.description = trigger[paramPrefix..'description']

		if isComponent then
			trigger_shopItemTipIntermediary.active 			= true
			trigger_shopItemTipIntermediary.isExpired 		= false
			trigger_shopItemTipIntermediary.isPermanent		= true
			trigger_shopItemTipIntermediary.days 			= 0
			trigger_shopItemTipIntermediary.monthsLeft 		= 0
			trigger_shopItemTipIntermediary.daysLeft 		= 0
			trigger_shopItemTipIntermediary.hoursLeft 		= 0
			trigger_shopItemTipIntermediary.minutesLeft 	= 0			
		
			trigger_shopItemTipIntermediary.isActivatable = false

			trigger_shopItemTipIntermediary.bonusDescription = ''
			trigger_shopItemTipIntermediary.normalQuality = 0
			trigger_shopItemTipIntermediary.isRare = false
			trigger_shopItemTipIntermediary.rareDescription = ''
			trigger_shopItemTipIntermediary.rareDisplayName = ''
			trigger_shopItemTipIntermediary.rareIcon = ''
			trigger_shopItemTipIntermediary.rareQuality = 0
			trigger_shopItemTipIntermediary.isLegendary = false
			trigger_shopItemTipIntermediary.legendaryDescription = ''
			trigger_shopItemTipIntermediary.legendaryDisplayName = ''
			trigger_shopItemTipIntermediary.legendaryIcon = ''
			trigger_shopItemTipIntermediary.legendaryQuality = 0

			trigger_shopItemTipIntermediary.manaCost = 0
			trigger_shopItemTipIntermediary.cooldown = 0

			trigger_shopItemTipIntermediary.isInBackPack = trigger[paramPrefix..'isInBackPack']
			trigger_shopItemTipIntermediary.isInStash = trigger[paramPrefix..'isInStash']
			trigger_shopItemTipIntermediary.isOnCourier = trigger[paramPrefix..'isOnCourier']
			trigger_shopItemTipIntermediary.isOwned = trigger[paramPrefix..'isOwned']

			trigger_shopItemTipIntermediary.isActivatable = false

			for i=0,2,1 do
				trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'exists'] = false
				trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isInBackPack'] = false
				trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isInStash'] = false
				trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isOnCourier'] = false
				trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isOwned'] = false
			end

		else
			trigger_shopItemTipIntermediary.active 			= true
			trigger_shopItemTipIntermediary.isExpired 		= trigger[paramPrefix..'isExpired']
			trigger_shopItemTipIntermediary.isPermanent		= trigger[paramPrefix..'isPermanent']
			trigger_shopItemTipIntermediary.days 			= trigger[paramPrefix..'days']
			trigger_shopItemTipIntermediary.monthsLeft 		= trigger[paramPrefix..'monthsLeft']
			trigger_shopItemTipIntermediary.daysLeft 		= trigger[paramPrefix..'daysLeft']
			trigger_shopItemTipIntermediary.hoursLeft 		= trigger[paramPrefix..'hoursLeft']
			trigger_shopItemTipIntermediary.minutesLeft 	= trigger[paramPrefix..'minutesLeft']				
			
			trigger_shopItemTipIntermediary.manaCost = trigger.manaCost
			trigger_shopItemTipIntermediary.isActivatable = trigger.isActivatable
			trigger_shopItemTipIntermediary.bonusDescription = trigger.bonusDescription
			trigger_shopItemTipIntermediary.normalQuality = trigger.normalQuality
			trigger_shopItemTipIntermediary.isRare = trigger.isRare
			trigger_shopItemTipIntermediary.rareDescription = trigger.rareDescription
			trigger_shopItemTipIntermediary.rareDisplayName = trigger.rareDisplayName
			trigger_shopItemTipIntermediary.rareIcon = trigger.rareIcon
			trigger_shopItemTipIntermediary.rareQuality = trigger.rareQuality
			trigger_shopItemTipIntermediary.isLegendary = trigger.isLegendary
			trigger_shopItemTipIntermediary.legendaryDescription = trigger.legendaryDescription
			trigger_shopItemTipIntermediary.legendaryDisplayName = trigger.legendaryDisplayName
			trigger_shopItemTipIntermediary.legendaryIcon = trigger.legendaryIcon
			trigger_shopItemTipIntermediary.legendaryQuality = trigger.legendaryQuality
			
			trigger_shopItemTipIntermediary.currentEmpoweredEffectEntityName 	= trigger.currentEmpoweredEffectEntityName or ''
			trigger_shopItemTipIntermediary.currentEmpoweredEffectCost 			= trigger.currentEmpoweredEffectCost or 0
			trigger_shopItemTipIntermediary.currentEmpoweredEffectDisplayName 	= trigger.currentEmpoweredEffectDisplayName or ''
			trigger_shopItemTipIntermediary.currentEmpoweredEffectDescription 	= trigger.currentEmpoweredEffectDescription or ''
			
			-- trigger_shopItemTipIntermediary.empoweredEffect0EntityName 			= trigger.empoweredEffect0EntityName or ''
			-- trigger_shopItemTipIntermediary.empoweredEffect1EntityName 			= trigger.empoweredEffect1EntityName or ''
			-- trigger_shopItemTipIntermediary.empoweredEffect2EntityName 			= trigger.empoweredEffect2EntityName or ''
			-- trigger_shopItemTipIntermediary.empoweredEffect3EntityName 			= trigger.empoweredEffect3EntityName or ''
			-- trigger_shopItemTipIntermediary.empoweredEffect4EntityName 			= trigger.empoweredEffect4EntityName or ''
			-- trigger_shopItemTipIntermediary.empoweredEffect5EntityName 			= trigger.empoweredEffect5EntityName or ''
			-- trigger_shopItemTipIntermediary.empoweredEffect6EntityName 			= trigger.empoweredEffect6EntityName or ''
			-- trigger_shopItemTipIntermediary.empoweredEffect7EntityName 			= trigger.empoweredEffect7EntityName or ''
			
			
			if isInventory then
				trigger_shopItemTipIntermediary.cooldown = trigger.cooldownTime
			
				trigger_shopItemTipIntermediary.isInBackPack = false
				trigger_shopItemTipIntermediary.isInStash = false
				trigger_shopItemTipIntermediary.canAfford = false
				trigger_shopItemTipIntermediary.isOnCourier = trigger.isOnCourier
				trigger_shopItemTipIntermediary.isOwned = false

				for i=0,2,1 do
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isInBackPack'] = false
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isInStash'] = false
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isOnCourier'] = false
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isOwned'] = false
				end

				local componentPrefix = 'recipeComponentDetail'
				local componentPrefixFull = ''

				for i=0,2,1 do
					componentPrefixFull = componentPrefix..i

					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isInBackPack'] = false
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isInStash'] = false
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isOnCourier'] = false
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isOwned'] = false
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'canAfford'] = false

					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'exists'] = trigger['recipeComponentDetail'..i..'isValid']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'icon'] = trigger['recipeComponentDetail'..i..'icon']
					-- trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'cost'] = trigger['recipeComponentDetail'..i..'cost']

					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'description'] = trigger['recipeComponentDetail'..i..'description']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'displayName'] = trigger['recipeComponentDetail'..i..'displayName']

					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'maxHealth'] = trigger['recipeComponentDetail'..i..'maxHealth']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'maxMana'] = trigger['recipeComponentDetail'..i..'maxMana']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'power'] = trigger['recipeComponentDetail'..i..'power']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'baseAttackSpeed'] = trigger['recipeComponentDetail'..i..'baseAttackSpeed']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'baseHealthRegen'] = trigger['recipeComponentDetail'..i..'baseHealthRegen']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'baseManaRegen'] = trigger['recipeComponentDetail'..i..'baseManaRegen']

					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'entity'] = trigger['recipeComponentDetail'..i..'recipeComponentDetail'..i]	-- ..'entity' (WHAt???)
				end
				
			else
			
				trigger_shopItemTipIntermediary.cooldown = trigger.cooldown
			
				if not isFromCrafting then
					trigger_shopItemTipIntermediary.isInBackPack = trigger.isInBackPack
					trigger_shopItemTipIntermediary.isInStash = trigger.isInStash
					trigger_shopItemTipIntermediary.canAfford = trigger.canAfford
					trigger_shopItemTipIntermediary.isOnCourier = trigger.isOnCourier
					trigger_shopItemTipIntermediary.isOwned = trigger.isOwned
				else
					trigger_shopItemTipIntermediary.isInBackPack = false
					trigger_shopItemTipIntermediary.isInStash = false
					trigger_shopItemTipIntermediary.canAfford = false
					trigger_shopItemTipIntermediary.isOnCourier = false
					trigger_shopItemTipIntermediary.isOwned = false
				end

				local componentPrefix = 'recipeComponentDetail'
				local componentPrefixFull = ''

				for i=0,2,1 do
					componentPrefixFull = componentPrefix..i


					if not isFromCrafting then
						trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isInBackPack'] = trigger[componentPrefixFull..'isInBackPack']
						trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isInStash'] = trigger[componentPrefixFull..'isInStash']
						trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isOnCourier'] = trigger[componentPrefixFull..'isOnCourier']
						trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isOwned'] = trigger[componentPrefixFull..'isOwned']
						trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'canAfford'] = trigger[componentPrefixFull..'canAfford']
					else
						trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isInBackPack'] = false
						trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isInStash'] = false
						trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isOnCourier'] = false
						trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isOwned'] = false
						trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'canAfford'] = false
					end


					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'exists'] = trigger[componentPrefixFull..'exists']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'icon'] = trigger[componentPrefixFull..'icon']
					-- trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'cost'] = trigger[componentPrefixFull..'cost']

					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'description'] = trigger[componentPrefixFull..'description']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'displayName'] = trigger[componentPrefixFull..'displayName']

					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'maxHealth'] = trigger[componentPrefixFull..'maxHealth']

					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'maxMana'] = trigger[componentPrefixFull..'maxMana']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'power'] = trigger[componentPrefixFull..'power']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'baseAttackSpeed'] = trigger[componentPrefixFull..'baseAttackSpeed']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'baseHealthRegen'] = trigger[componentPrefixFull..'baseHealthRegen']
					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'baseManaRegen'] = trigger[componentPrefixFull..'baseManaRegen']

					trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'entity'] = trigger[componentPrefixFull..'entity']
				end
			end
		end

		trigger_shopItemTipIntermediary.recipeScrollCanAfford = false
		trigger_shopItemTipIntermediary.recipeScrollCost = 0
		trigger_shopItemTipIntermediary:Trigger(false)
	end
	
	local shopTipDelayThread
	local shopTipDelayDuration = GetCvarNumber('ui_tipDelayDuration', true) or 250
	container:RegisterWatchLua('shopItemTipInfo', function(widget, trigger)
		
		if (shopTipDelayThread) then
			shopTipDelayThread:kill()
			shopTipDelayThread = nil
		end
		
		local index = trigger.index

		container:UnregisterWatchLuaByKey('shopItemTipWatch')

		local triggerName			= 'ShopItem'
		local itemType				= trigger.itemType
		local isFromCrafting		= false
		if string.len(itemType) > 0 then triggerName = itemType end

		local triggerIndex = index

		if itemType == 'craftedItemInfoShop' then
			triggerIndex = ''
			isFromCrafting = true
		end

		local infoTrigger			= LuaTrigger.GetTrigger(triggerName..triggerIndex)

		if index >= 0 and infoTrigger and infoTrigger.exists then

			local isComponent			= trigger.isComponent
			local cooldownParam			= 'cooldown'
			local costParam				= 'cost'
			local recipeParam			= 'isRecipe'
			local isInventory			= false

			local paramPrefix			= ''

			if isComponent then
				paramPrefix	= 'recipeComponentDetail'..trigger.componentID
			end

			if itemType == 'ActiveInventory' or itemType == 'StashInventory' or itemType == 'HeroInventory' or itemType == 'SelectedInventory' then
				cooldownParam		= 'cooldownTime'
				costParam			= 'sellValue'
				-- recipeParam		= 'isRecipeCompleted'
				isInventory = true
			end

			if (LuaTrigger.GetTrigger('globalDragInfo').active ~= true) then
				object:GetWidget('gameDropTrashGold'):SetText('+' .. libNumber.commaFormat(math.floor(infoTrigger[paramPrefix..costParam])))
			end

			containerTriggerUpdate(container, infoTrigger, isComponent, cooldownParam, costParam, recipeParam, paramPrefix, 'icon', isInventory, isFromCrafting)
			container:RegisterWatchLua(triggerName..triggerIndex, function(widget, trigger)
				containerTriggerUpdate(widget, trigger, isComponent, cooldownParam, costParam, recipeParam, paramPrefix, 'icon', isInventory, isFromCrafting)
			end, false, 'shopItemTipWatch',
				containerTriggerGetParamList(isComponent, cooldownParam, costParam, recipeParam, paramPrefix, isInventory, isFromCrafting)
			)

			lastIndex = index
		end

		if index >= 0 then
			if not widget:IsVisibleSelf() then
				shopTipDelayThread = libThread.threadFunc(function()
					wait(shopTipDelayDuration)
					widget:SetVisible(true)
					shopTipDelayThread =  nil
				end)
			end
		else

			if widget:IsVisibleSelf() then
				widget:SetVisible(false)
			end
		end
	end)

	libGeneral.registerNonObscuringFloat(container)
end

shopItemTipRegister(object)

trigger_shopItemTipIntermediary.armor = 0
trigger_shopItemTipIntermediary.baseAttackSpeed = 0
-- trigger_shopItemTipIntermediary.attackSpeedMultiplier = 0
trigger_shopItemTipIntermediary.baseHealthRegen = 0
trigger_shopItemTipIntermediary.baseManaRegen = 0
trigger_shopItemTipIntermediary.bonusDescription = ''
trigger_shopItemTipIntermediary.canAfford = false
trigger_shopItemTipIntermediary.cooldown = 0
trigger_shopItemTipIntermediary.cost = 0
trigger_shopItemTipIntermediary.description = ''
trigger_shopItemTipIntermediary.descriptionSimple = ''
trigger_shopItemTipIntermediary.displayName = ''
trigger_shopItemTipIntermediary.entity = ''
trigger_shopItemTipIntermediary.exists = false
-- trigger_shopItemTipIntermediary.healthRegen = 0
trigger_shopItemTipIntermediary.icon = ''
trigger_shopItemTipIntermediary.isActivatable = false
trigger_shopItemTipIntermediary.isInBackPack = false
trigger_shopItemTipIntermediary.isInStash = false
trigger_shopItemTipIntermediary.isLegendary = false
trigger_shopItemTipIntermediary.isOnCourier = false
trigger_shopItemTipIntermediary.isOwned = false
trigger_shopItemTipIntermediary.isPlayerCrafted = false
trigger_shopItemTipIntermediary.isRare = false
trigger_shopItemTipIntermediary.isRecipe = false
trigger_shopItemTipIntermediary.legendaryDescription = ''
trigger_shopItemTipIntermediary.legendaryDisplayName = ''
trigger_shopItemTipIntermediary.legendaryIcon = ''
trigger_shopItemTipIntermediary.legendaryQuality = 0
trigger_shopItemTipIntermediary.magicArmor = 0
trigger_shopItemTipIntermediary.mitigation = 0
trigger_shopItemTipIntermediary.resistance = 0
trigger_shopItemTipIntermediary.manaCost = 0
-- trigger_shopItemTipIntermediary.manaRegen = 0
trigger_shopItemTipIntermediary.maxHealth = 0
trigger_shopItemTipIntermediary.maxMana = 0
trigger_shopItemTipIntermediary.normalQuality = 0
trigger_shopItemTipIntermediary.power = 0
trigger_shopItemTipIntermediary.rareDescription = ''
trigger_shopItemTipIntermediary.rareDisplayName = ''
trigger_shopItemTipIntermediary.rareIcon = ''
trigger_shopItemTipIntermediary.currentEmpoweredEffectEntityName = ''
trigger_shopItemTipIntermediary.currentEmpoweredEffectCost = 0
trigger_shopItemTipIntermediary.currentEmpoweredEffectDisplayName = ''
trigger_shopItemTipIntermediary.currentEmpoweredEffectDescription = ''
trigger_shopItemTipIntermediary.empoweredEffect0EntityName 			= ''
trigger_shopItemTipIntermediary.empoweredEffect1EntityName 			= ''
trigger_shopItemTipIntermediary.empoweredEffect2EntityName 			= ''
trigger_shopItemTipIntermediary.empoweredEffect3EntityName 			= ''
trigger_shopItemTipIntermediary.empoweredEffect4EntityName 			= ''
trigger_shopItemTipIntermediary.empoweredEffect5EntityName 			= ''
trigger_shopItemTipIntermediary.empoweredEffect6EntityName 			= ''
trigger_shopItemTipIntermediary.empoweredEffect7EntityName 			= ''
			
for i=0,3,1 do
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'armor'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'baseAttackSpeed'] = 0
	-- trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'attackSpeedMultiplier'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'baseHealthRegen'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'baseManaRegen'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'canAfford'] = false
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'cooldown'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'cost'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'description'] = ''
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'descriptionSimple'] = ''
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'displayName'] = ''
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'entity'] = ''
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'exists'] = false
	-- trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'healthRegen'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'icon'] = ''
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isInBackPack'] = false
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isInStash'] = false
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isOnCourier'] = false
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'isOwned'] = false
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'magicArmor'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'mitigation'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'resistance'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'manaCost'] = 0
	-- trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'manaRegen'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'maxHealth'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'maxMana'] = 0
	trigger_shopItemTipIntermediary['recipeComponentDetail'..i..'power'] = 0
end

trigger_shopItemTipIntermediary.active = true
trigger_shopItemTipIntermediary.isExpired = false
trigger_shopItemTipIntermediary.isPermanent = false
trigger_shopItemTipIntermediary.days = 0
trigger_shopItemTipIntermediary.monthsLeft = 0
trigger_shopItemTipIntermediary.daysLeft = 0
trigger_shopItemTipIntermediary.hoursLeft = 0
trigger_shopItemTipIntermediary.minutesLeft = 0

trigger_shopItemTipIntermediary.recipeScrollCanAfford = false
trigger_shopItemTipIntermediary.recipeScrollCost = 0
trigger_shopItemTipIntermediary:Trigger(true)

trigger_shopItemTipInfo.index		= -1
trigger_shopItemTipInfo.itemType	= ''
trigger_shopItemTipInfo.isComponent	= false
trigger_shopItemTipInfo.displayCrafted	= true
trigger_shopItemTipInfo:Trigger(true)

local interface = object

function shopGetInterface()
	return interface
end

function shopGetWidget(widgetName)
	if widgetName and string.len(widgetName) > 0 then
		return interface:GetWidget(widgetName)
	end
end

--[[
rmm tutorial stuff
object:GetWidget('gameShopItemViewButtonSimple'):SetEnabled(false)
object:GetWidget('gameShopItemViewButtonDetailed'):SetEnabled(false)

object:GetWidget('shopToggleFilterBtn'):SetEnabled(false)


object:GetWidget('levelUpPanelViewButtonSimple'):SetEnabled(false)
object:GetWidget('levelUpPanelViewButtonDetailed'):SetEnabled(false)
--]]
