local function newPlayerExperienceRegister(object)
	-- NewPlayerExperience.requiresLogin	= true	-- now in lib

	local newPlayerExperience_script	= object:GetWidget('newPlayerExperience_script')
	
	local function GetSoundDurationFromStringKey(stringKey)
		local duration = TranslateOrNil(stringKey) or 0
		duration = tonumber(duration)
		return duration
	end
	
	local lastNPEThread = nil
	local function clearNPEThreads()
		if lastNPEThread ~= nil then
			lastNPEThread:kill()
			lastNPEThread = nil
		end

		NewPlayerExperience.trigger.busySpeaking = false
		NewPlayerExperience.trigger:Trigger(false)
	end

	local function clearNPEWidgetFocus()
		spotlightWidget()
		darkenAroundWidget()
		pointAtWidgetStop()
		widgetHighlightMulti()
		object:GetWidget('newPlayerExperienceCraftingInfo'):SetVisible(false)
		blockInput(false)
		-- darkenScreen()	-- rmm may want to add this back
	end

	-- ===============================================================

	function NewPlayerExperience.skipTutorial()
		ClearAllKeeperNotifications(true)
		clearNPEThreads()
		clearNPEWidgetFocus()
		NewPlayerExperience.trigger.tutorialComplete			= true
		NewPlayerExperience.trigger.tutorialProgressBeforeSkip	= NewPlayerExperience.trigger.tutorialProgress
		NewPlayerExperience.trigger.tutorialProgress			= NPE_PROGRESS_TUTORIALCOMPLETE
		NewPlayerExperience.trigger:Trigger(true)
		if LuaTrigger.GetTrigger('mainPanelStatus').main == 0 then
			object:GetWidget('newPlayerExperience_skipToLogin'):FadeOut(250)
			object:GetWidget('newPlayerExperience_loadMap'):FadeOut(250)
			object:GetWidget('main_login_prompt_parent'):FadeIn(250)
			object:GetWidget('newPlayerExperience_enterName'):FadeOut(250)
		end
		libThread.threadFunc(function()
			wait(2000)
			if (not mainUI.savedRemotely) or (not mainUI.savedRemotely.splashScreensViewed) or (not mainUI.savedRemotely.splashScreensViewed['splash_screen_control_presets']) then
				mainUI.savedRemotely = mainUI.savedRemotely or {}
				mainUI.savedRemotely.splashScreensViewed = mainUI.savedRemotely.splashScreensViewed or {}
				mainUI.savedRemotely.splashScreensViewed['splash_screen_control_presets'] = true
				SaveState()
				local mainPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
				mainPanelStatus.main = mainUI.MainValues.controlPresets
				mainPanelStatus:Trigger(false)
			end	
		end)
	end

	function NewPlayerExperience.skipAll()
		ClearAllKeeperNotifications(true)
		clearNPEThreads()
		clearNPEWidgetFocus()
		NewPlayerExperience.trigger.tutorialComplete			= true
		NewPlayerExperience.trigger.tutorialProgressBeforeSkip	= NewPlayerExperience.trigger.tutorialProgress
		NewPlayerExperience.trigger.tutorialProgress			= NPE_PROGRESS_TUTORIALCOMPLETE
		NewPlayerExperience.trigger.craftingIntroProgress		= 1
		NewPlayerExperience.trigger.enchantingIntroProgress		= 1
		NewPlayerExperience.trigger.corralIntroProgress			= 1
		NewPlayerExperience.trigger.rewardsIntroProgress		= 1
		NewPlayerExperience.trigger:Trigger(true)
		if LuaTrigger.GetTrigger('mainPanelStatus').main == 0 then
			object:GetWidget('newPlayerExperience_skipToLogin'):FadeOut(250)
			object:GetWidget('newPlayerExperience_loadMap'):FadeOut(250)
			object:GetWidget('main_login_prompt_parent'):FadeIn(250)
			object:GetWidget('newPlayerExperience_enterName'):FadeOut(250)
		end
		libThread.threadFunc(function()
			wait(2000)		
			if (not mainUI.savedRemotely) or (not mainUI.savedRemotely.splashScreensViewed) or (not mainUI.savedRemotely.splashScreensViewed['splash_screen_control_presets']) then
				mainUI.savedRemotely = mainUI.savedRemotely or {}
				mainUI.savedRemotely.splashScreensViewed = mainUI.savedRemotely.splashScreensViewed or {}
				mainUI.savedRemotely.splashScreensViewed['splash_screen_control_presets'] = true
				SaveState()
				local mainPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
				mainPanelStatus.main = mainUI.MainValues.controlPresets
				mainPanelStatus:Trigger(false)
			end	
		end)
	end

	-- ===============================================================
	-- Run NPE code, unless the region specifically prohibits it.
	if not (Strife_Region.regionTable and Strife_Region.regionTable[Strife_Region.activeRegion] and Strife_Region.regionTable[Strife_Region.activeRegion].new_player_experience == false) then
		local loginContainer	= object:GetWidget('main_login_prompt_parent')
		local lastNPESection = 0

		local function newNPEThread(newThreadFunc)
			clearNPEThreads()
			lastNPEThread = libThread.threadFunc(newThreadFunc)
		end

		local function checkClearNPE(newSection)
			if newSection ~= lastNPESection then

				if lastNPESection ~= 0 and lastNPESection ~= 101 then
					ClearAllKeeperNotifications(true)
				end

				clearNPEThreads()
				if newSection == 1 or newSection == 2 or newSection == 5 then
					if newSection ~= 1 then	-- Crafting
						newPlayerExperienceCraftingStep(0, nil, false)
					end

					if newSection ~= 2 then	-- Pets
						newPlayerExperiencePetsStep(0, nil, false)
					end

					if newSection ~= 5 then	-- Enchanting
						newPlayerExperienceEnchantingStep(0, nil, false)
					end

				else
					newPlayerExperiencePetsStep(0, nil, false)
					newPlayerExperienceEnchantingStep(0, nil, false)
					newPlayerExperienceCraftingStep(0, nil, false)
					clearNPEWidgetFocus()
				end
				triggerNPE		= NewPlayerExperience.trigger
				triggerNPE:Trigger(false)
			end
			lastNPESection = newSection
		end

		if LuaTrigger.GetTrigger('npeLoginInfo') then LuaTrigger.DestroyGroupTrigger('npeLoginInfo') end
		LuaTrigger.CreateGroupTrigger('npeLoginInfo', {
			'LoginStatus.isLoggedIn',
			'LoginStatus.hasIdent',
			'LoginStatus.externalLogin',
			'LoginStatus.launchedViaSteam',
			'LoginStatus.loggedInViaSteam',
			'AccountInfo.tutorialProgress',
			'newPlayerExperience.tutorialProgress'
		})

		if LuaTrigger.GetTrigger('newPlayerExperienceSectionIntro') then LuaTrigger.DestroyGroupTrigger('newPlayerExperienceSectionIntro') end
		LuaTrigger.CreateGroupTrigger('newPlayerExperienceSectionIntro', {
			'mainPanelAnimationStatus.main',
			'mainPanelAnimationStatus.newMain',
			'GamePhase.gamePhase',
			'newPlayerExperience.tutorialComplete',
			'newPlayerExperience.craftingIntroProgress',
			'newPlayerExperience.craftingIntroStep',
			'newPlayerExperience.enchantingIntroProgress',
			'newPlayerExperience.enchantingIntroStep',
			'newPlayerExperience.corralIntroProgress',
			'newPlayerExperience.corralIntroStep'
		})

		function newPlayerExperienceCraftingStep(step, progress, fireTrigger)
			if fireTrigger == nil then fireTrigger = true end
			if step then
				local triggerNPE = NewPlayerExperience.trigger
				progress = progress or triggerNPE.craftingIntroProgress
				triggerNPE.craftingIntroProgress = progress
				triggerNPE.craftingIntroStep = step
				if fireTrigger then
					triggerNPE:Trigger(false)
				end
			end
		end

		function newPlayerExperienceEnchantingStep(step, progress, fireTrigger)
			if fireTrigger == nil then fireTrigger = true end
			if step then
				local triggerNPE = NewPlayerExperience.trigger
				progress = progress or triggerNPE.enchantingIntroProgress
				triggerNPE.enchantingIntroProgress = progress
				triggerNPE.enchantingIntroStep = step
				if fireTrigger then
					triggerNPE:Trigger(false)
				end
			end
		end

		function newPlayerExperiencePetsStep(step, progress, fireTrigger)
			if fireTrigger == nil then fireTrigger = true end
			if step then
				local triggerNPE = NewPlayerExperience.trigger
				progress = progress or triggerNPE.corralIntroProgress
				triggerNPE.corralIntroProgress = progress
				triggerNPE.corralIntroStep = step
				if fireTrigger then
					triggerNPE:Trigger(false)
				end
			end
		end

		--[[
		newPlayerExperience_script:RegisterWatchLua('GameClientRequestsEnchantCraftedItem', function(widget, trigger)
			if trigger.status == 2 then
				genericEvent.broadcast('crafting_enchantItem')
			end
		end, false, nil, 'status')
		--]]

		local function getShopButtonFromSlotData(slotData)
			local useWidget
			
			if type(slotData) == 'table' then
				useWidget = shopGetWidget('gameShopItemListRow'..slotData[1]..'Item'..slotData[2]..'Button')
			else
				useWidget = shopGetWidget('gameShopItemListItem'..slotData..'Button')
			end

			return useWidget
		end

		local function getShopButton(index)
			local slotData = gameShopGetItemSlotID(index)

			return getShopButtonFromSlotData(slotData)
		end

		local function resumeNewPlayerExperienceCrafting(NPETrigger)
			local triggerNPE
			if NPETrigger then
				triggerNPE		= NPETrigger
			else
				triggerNPE		= NewPlayerExperience.trigger
			end

			local introStep			= triggerNPE.craftingIntroStep
			local introProgress		= triggerNPE.craftingIntroProgress

			if introProgress == 0 then
				if introStep == 0 then
					local function notificationsFinish()
					
						local panelInfo		= LuaTrigger.GetTrigger('gamePanelInfo')
						panelInfo.shopItemView = 0
						Set('_shopItemView', '0', 'bool')
						panelInfo:Trigger(false)					
					
						local slotData = gameShopGetItemSlotIDFromEntity('Item_Gauntlet')

						local itemButton = (getShopButtonFromSlotData(slotData))

						darkenAroundWidget(itemButton)
						spotlightWidget(itemButton)
					end
					newNPEThread(function()
						blockInput(true)
						wait(500)
						blockInput(false)
						trigger_shopFilter.shopCategory = ''
						trigger_shopFilter:Trigger(false)
						widgetHighlightMulti()
						spotlightWidget()
						darkenAroundWidget()

						Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('mew_player_experience_craftitem_01_length') + 10000), Translate('mew_player_experience_craftitem_01'), nil, nil, '/ui/main/keepers/textures/draknia.png', nil, '/ui/sounds/tutorial/vo_draknia_1.wav', nil, true, nil, nil, 'draknia', 'draknia_ui_1')

						Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('mew_player_experience_craftitem_01b_length') + 10000), Translate('mew_player_experience_craftitem_01b'), nil, nil, '/ui/main/keepers/textures/draknia.png', nil, '/ui/sounds/tutorial/vo_draknia_2.wav', nil, true, nil, nil, 'draknia', 'draknia_ui_2')

						Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('mew_player_experience_craftitem_01c_length') + 500), Translate('mew_player_experience_craftitem_01c'), nil, nil, '/ui/main/keepers/textures/draknia.png', notificationsFinish, '/ui/sounds/tutorial/vo_draknia_3.wav', nil, true, nil, nil, 'draknia', 'draknia_ui_3')
						lastNPEThread = nil
					end)

				elseif introStep == 1 then	-- Selected bracer
					clearNPEThreads()
					widgetHighlightMulti()
					spotlightWidget()
					darkenAroundWidget()

					local function notificationsFinish()
						object:GetWidget('newPlayerExperienceCraftingInfo'):FadeIn(250)
						object:GetWidget('newPlayerExperienceCraftingInfoLabel'):SetText(Translate('mew_player_experience_craftitem_01e'))
						object:GetWidget('newPlayerExperienceCraftingInfoNext'):SetCallback('onclick', function(widget)
							newPlayerExperienceCraftingStep(2)
						end)
						darkenAroundWidget(true, nil, 250)
						PlayStream('/ui/sounds/tutorial/vo_draknia_5_1.wav', nil, 9, 0)

						newNPEThread(function()
							wait(GetSoundDurationFromStringKey('mew_player_experience_craftitem_01e_length_1'))
							-- highlight
							--[[
							local groupWidgets = {}
							for k,v in ipairs(object:GetGroup('mainCraftingNewItemComponent_jublies')) do
								table.insert(groupWidgets, v)
							end
							for k,v in ipairs(object:GetGroup('craftingDraggableComponentJublies')) do
								table.insert(groupWidgets, v)
							end
							--]]

							-- widgetHighlightMulti(groupWidgets)

							local jubWidgets = {
								object:GetWidget('craftingDraggableComponentpower_comp1JublieImage'),
								object:GetWidget('craftingDraggableComponentpower_comp2JublieImage'),
								object:GetWidget('craftingDraggableComponentpower_comp3JublieImage')
							}
							for k,v in ipairs(jubWidgets) do
								widgetHighlightMulti({v})
								PlaySound('/ui/sounds/crafting/sfx_highlight_'..k..'.wav')
								wait(800)
							end

							wait(600)

							PlayStream('/ui/sounds/tutorial/vo_draknia_5_2.wav', nil, 9, 0)

							wait(GetSoundDurationFromStringKey('mew_player_experience_craftitem_01e_length_2'))

							spotlightWidget(object:GetWidget('craftingRequiredJublieCount'))
							PlaySound('/ui/sounds/crafting/sfx_highlight_4.wav')
							wait(GetSoundDurationFromStringKey('mew_player_experience_craftitem_01e_length_3'))

							PlayStream('/ui/sounds/tutorial/vo_draknia_5_3.wav', nil, 9, 0)
							-- spotlightWidget()
							lastNPEThread = nil
						end)
					end

					newNPEThread(function()
						blockInput(true)
						wait(700)
						blockInput(false)
						Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('mew_player_experience_craftitem_01c_length') + 500), Translate('mew_player_experience_craftitem_01d'), nil, nil, '/ui/main/keepers/textures/draknia.png', notificationsFinish, '/ui/sounds/tutorial/vo_draknia_4.wav', nil, true, nil, nil, 'draknia', 'draknia_ui_4')
						lastNPEThread = nil
					end)

				elseif introStep == 2 then
					widgetHighlightMulti()
					clearNPEThreads()
					spotlightWidget()
					object:UICmd("StopSound(9)")

					object:GetWidget('newPlayerExperienceCraftingInfo'):FadeIn(250)	-- really this should already be visible
					object:GetWidget('newPlayerExperienceCraftingInfoLabel'):SetText(Translate('mew_player_experience_craftitem_01f'))
					object:GetWidget('newPlayerExperienceCraftingInfoNext'):SetCallback('onclick', function(widget)
						newPlayerExperienceCraftingStep(3)
					end)
					darkenAroundWidget(true, nil, 250)
					PlayStream('/ui/sounds/tutorial/vo_draknia_6.wav', nil, 9, 0)

					newNPEThread(function()
						wait(14000)
						newPlayerExperienceCraftingStep(3)
						lastNPEThread = nil
					end)
				elseif introStep == 3 then
					object:GetWidget('newPlayerExperienceCraftingInfo'):FadeOut(250)
					widgetHighlightMulti()
					clearNPEThreads()
					spotlightWidget(object:GetWidget('craftingDraggableComponenthealth_regen_comp1'))
					darkenAroundWidget(object:GetWidget('craftingDraggableComponenthealth_regen_comp1'))
				elseif introStep == 4 then	-- Selected HP  regen
					clearNPEThreads()
					widgetHighlightMulti()
					darkenAroundWidget(object:GetWidget('craftingDraggableComponentmana_regen_comp1'))
					spotlightWidget(object:GetWidget('craftingDraggableComponentmana_regen_comp1'))
					-- highlight mp regen
				elseif introStep == 5 then	-- Selected MP Regen
					clearNPEThreads()
					widgetHighlightMulti()
					darkenAroundWidget(object:GetWidget('craftItemButton'))
					spotlightWidget(object:GetWidget('craftItemButton'))
				elseif introStep == 6 then	-- Entered enchanting
					clearNPEThreads()
					local function notificationsFinish()
						-- Highlight imbuements
						widgetHighlightPlacePlaceholder({
							object:GetWidget('craftingImbuement-1'),
							object:GetWidget('craftingImbuement0'),
							object:GetWidget('craftingImbuement1'),
							object:GetWidget('craftingImbuement2'),
							object:GetWidget('craftingImbuement3')
						})
						darkenAroundWidget(widgetHighlightGetPlaceholder())
					end
					widgetHighlightMulti()
					spotlightWidget()
					darkenAroundWidget()
					Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('mew_player_experience_craftitem_01h_length') + 10000), Translate('mew_player_experience_craftitem_01h'), nil, nil, '/ui/main/keepers/textures/draknia.png', notificationsFinish, '/ui/sounds/tutorial/vo_draknia_8.wav', nil, true, nil, nil, 'draknia', 'draknia_ui_8')
				elseif introStep == 7 then	-- Selected imbuement
					clearNPEThreads()
					local function notificationsFinish()
						darkenAroundWidget(object:GetWidget('craftItemButton'))
						spotlightWidget(object:GetWidget('craftItemButton'))
					end

					newNPEThread(function()
						blockInput(true)
						wait(1000)
						blockInput(false)

						widgetHighlightMulti()
						spotlightWidget()
						darkenAroundWidget()
						Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('mew_player_experience_craftitem_01i_length') + 10000), Translate('mew_player_experience_craftitem_01i'), nil, nil, '/ui/main/keepers/textures/draknia.png', notificationsFinish, '/ui/sounds/tutorial/vo_draknia_9.wav', nil, true, nil, nil, 'draknia', 'draknia_ui_9')

						lastNPEThread = nil
					end)
				elseif introStep == 8 then	-- Successfully crafted item
					clearNPEThreads()
					newPlayerExperienceCraftingStep(0, 1)	-- Finished, go to below

					newNPEThread(function()
						blockInput(true)
						wait(500)
						blockInput(false)

						widgetHighlightMulti()
						spotlightWidget()
						darkenAroundWidget()

						Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('mew_player_experience_craftitem_02_length') + 500), Translate('mew_player_experience_craftitem_02'), nil, nil, '/ui/main/keepers/textures/draknia.png', nil, '/ui/sounds/tutorial/vo_draknia_10.wav', nil, true, nil, nil, 'draknia', 'draknia_ui_10')



						lastNPEThread = nil
					end)
				end
			elseif introProgress == 1 then		-- Successfully crafted an item
				-- Crafting done
			end
		end

		local function resumeNewPlayerExperienceEnchanting(NPETrigger)
			if true then return false end
		end

		local function resumeNewPlayerExperiencePets(NPETrigger)
			local triggerNPE
			if NPETrigger then
				triggerNPE		= NPETrigger
			else
				triggerNPE		= NewPlayerExperience.trigger
			end
			local introStep		= triggerNPE.corralIntroStep
			local introProgress	= triggerNPE.corralIntroProgress

			if introProgress == 0 then
				if introStep == 0 then

					local initialPetPicked		= LuaTrigger.GetTrigger('Corral').initialPetPicked

					if not initialPetPicked then	-- handles a corner case where you can actually complete the tutorial without owning a pet
						newPlayerExperiencePetsStep(0, 2)
					else

						local function finishNotification()
							newPlayerExperiencePetsStep(0,1)
						end

						Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_feedpet_01_length') + 500), Translate('new_player_experience_feedpet_01'), nil, nil, '/ui/main/keepers/textures/auros.png', finishNotification, '/ui/sounds/tutorial/vo_auros_4.wav', nil, true, nil, nil, 'auros', 'ui_5')
					end
				end
			elseif introProgress == 1 then
				if introStep == 0 then	-- Highlight feed button, wait til fed
					-- clearNPEThreads()
					--[[
						highlight feed button handled elsewhere (newPlayerExperienceCheckCanFeedPet)
					--]]
				elseif introStep == 1 then	-- Fully fed pet (queued a level up)
					spotlightWidget()
					-- darkenAroundWidget()
					local function notificationsFinish()
						spotlightWidget()
					end
					Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_feedpet_02_length') + 500), Translate('new_player_experience_feedpet_02'), nil, nil, '/ui/main/keepers/textures/auros.png', notificationsFinish, '/ui/sounds/tutorial/vo_auros_5.wav', function()
						--[[
						newNPEThread(function()
							spotlightWidget(object:GetWidget('mainPetsInfo'))
							wait(3000)
							spotlightWidget()
							wait(2802)
							-- highlight food
							spotlightWidget(object:GetWidget('mainPetsFoodContainer'))
							wait(3698)
							spotlightWidget(object:GetWidget('player_card_gems'))
							lastNPEThread = nil
						end)
						--]]
					end, true, nil, nil, 'auros', 'ui_6')
					newPlayerExperiencePetsStep(0, 2)
				end

			elseif introProgress == 2 then
				-- Done feeding pet
			end
		end

		newPlayerExperience_script:RegisterWatchLua('newPlayerExperienceSectionIntro', function(widget, groupTrigger)
			local triggerPanelStatus	= groupTrigger['mainPanelAnimationStatus']
			local triggerNPE			= groupTrigger['newPlayerExperience']
			local gamePhase				= groupTrigger['GamePhase'].gamePhase

			if gamePhase == 0 and triggerNPE.tutorialComplete then
				local newMain				= triggerPanelStatus.newMain
				local main					= triggerPanelStatus.main
				checkClearNPE(newMain)

				if mainSectionAnimState(1, main, newMain) == 4 then
					if triggerNPE.craftingIntroStep >= 1 or LuaTrigger.GetTrigger('CraftingCommodityInfo').oreCount >= 360 then
						resumeNewPlayerExperienceCrafting(triggerNPE)
					end
				elseif mainSectionAnimState(2, main, newMain) == 4 then
					resumeNewPlayerExperiencePets(triggerNPE)


				--[[
				elseif mainSectionAnimState(5, main, newMain) == 4 then

					local function findMinimumElixirCostToEnchant()	-- hax
						local minimumCost
						local itemCost

						for i=0,99,1 do
							local itemInfo =  LuaTrigger.GetTrigger('CraftedItems'..i)

							if itemInfo and itemInfo.available then
								local itemCost = itemInfo.essenceEnchantCost
								if (minimumCost == nil) and (itemCost) and (itemCost > 0) then
									minimumCost = itemCost
								elseif (itemCost) and (itemCost > 0) then
									minimumCost = math.min(minimumCost, itemCost)
								end
							else
								break
							end
						end

						return minimumCost or 99999
					end

					if (triggerNPE.enchantingIntroStep >= 1 or LuaTrigger.GetTrigger('CraftingCommodityInfo').essenceCount >= findMinimumElixirCostToEnchant()) and LuaTrigger.GetTrigger('CraftedItems0').available then
						-- resumeNewPlayerExperienceEnchanting(triggerNPE)
					end
				--]]
				end
				local triggerPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
				triggerPanelStatus.hideSecondaryElements = GetCvarBool('ui_PAXDemo') or false
				triggerPanelStatus:Trigger(false)
			elseif (gamePhase == 0) then
				local triggerPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
				triggerPanelStatus.hideSecondaryElements = true
				triggerPanelStatus:Trigger(false)
			end
		end)

		libGeneral.createGroupTrigger('loginNPERewardStatus', {
			'newPlayerExperience.tutorialProgress',
			'newPlayerExperience.tutorialComplete',
			'newPlayerExperience.rewardsIntroProgress',
			'newPlayerExperience.rewardsIntroStep',
			'UnclaimedRewards.numUnclaimed',
			'GamePhase.gamePhase',
			'mainPanelStatus.main',
		})

		newPlayerExperience_script:RegisterWatchLua('loginNPERewardStatus', function(widget, groupTrigger)	-- rmm switch to using mainSectionAnimState() in order to let animations finish before being moved to rewards?
			local triggerNPE		= groupTrigger['newPlayerExperience']
			local gamePhase			= groupTrigger['GamePhase'].gamePhase
			local main				= groupTrigger['mainPanelStatus'].main
			local triggerRewards	= groupTrigger['UnclaimedRewards']

			if (not triggerNPE.tutorialComplete) and gamePhase == 0 and main == 101 and triggerNPE.tutorialProgress >= NPE_PROGRESS_FINISHTUT3 then
				if triggerNPE.rewardsIntroProgress == 0 then
					local firstMatchID = tostring(triggerRewards.firstMatchID)
					if triggerRewards.numUnclaimed > 0 then
						if NewPlayerExperience.trigger.rewardsIntroStep == 0 then
							if firstMatchID == '0.000' then
								local PostGameLoopStatus		= LuaTrigger.GetTrigger('PostGameLoopStatus')

								Rewards.ClaimFirstReward()
								PostGameLoopStatus.viaUnclaimed = true

								PostGameLoopStatus.matchID = firstMatchID
								PostGameLoopStatus:Trigger(true)
								EndMatch.Show(true)
							else	-- First claimable reward isn't special NPE reward, just mark as completed w/Lex speech
								newPlayerExperienceCompleted()
							end
						else
							newPlayerExperienceCompleted()
						end
					else
						newPlayerExperienceCompleted()
					end
				elseif triggerNPE.rewardsIntroProgress == 1 then	-- Actually received last reward
					newPlayerExperienceCompleted()
				end
			end
		end)

		local NPELastLoggedIn = -1

		libGeneral.createGroupTrigger('loginNPEUpdate', {
			'LoginStatus.isLoggedIn',
			'LoginStatus.hasIdent',
			'LoginStatus.externalLogin',
			'LoginStatus.isIdentPopulated',
			'LoginStatus.launchedViaSteam',
			'LoginStatus.loggedInViaSteam',
			'AccountInfo.tutorialProgress'
		})

		newPlayerExperience_script:RegisterWatchLua('loginNPEUpdate', function(widget, groupTrigger)
			if not NewPlayerExperience.crippledRegion() then
				local triggerNPE					= LuaTrigger.GetTrigger('newPlayerExperience')
				local triggerLogin					= groupTrigger['LoginStatus']
				local fullyLoggedIn					= (triggerLogin.isLoggedIn and ((triggerLogin.hasIdent and triggerLogin.isIdentPopulated)))

				if fullyLoggedIn then
					if NPELastLoggedIn ~= 1 then	-- Newly logged in
						ClearAllKeeperNotifications(true)
						clearNPEThreads()
						clearNPEWidgetFocus()
						triggerNPE.npeStarted = false
						NPELastLoggedIn = 1
					end
				else
					if NPELastLoggedIn ~= 0 then	-- Logged out
						triggerNPE.npeStarted = false
						NPELastLoggedIn = 0
					end
				end
			end
		end)

		newPlayerExperience_script:RegisterWatchLua('loginNPEStatusAnims', function(widget, groupTrigger)
			local triggerNPE					= groupTrigger['newPlayerExperience']
			local triggerGamePhase				= groupTrigger['GamePhase']
			local triggerMainPanelStatus		= groupTrigger['mainPanelAnimationStatus']

			local triggerUpdate					= groupTrigger['UpdateInfo']
			local mustUpdateFirst				= ((triggerUpdate.updateAvailable) and GetCvarBool('cl_checkForUpdate'))

			if NewPlayerExperience.crippledRegion() or mustUpdateFirst then
				ClearAllKeeperNotifications(true)
				clearNPEThreads()
				clearNPEWidgetFocus()
			else
				local main = triggerMainPanelStatus.main
				local newMain = triggerMainPanelStatus.newMain

				local validMain		= false

				local tutorialProgress	= triggerNPE.tutorialProgress

				if (main == 101) and (tutorialProgress >= NPE_PROGRESS_SELECTEDPET) and (tutorialProgress < NPE_PROGRESS_TUTORIALCOMPLETE) and (not LuaTrigger.GetTrigger('Corral').initialPetPicked) then -- If they got to this point but LOST their pet (DB Wipe) Go back a step
					validMain = true
					clearNPEThreads()
					triggerNPE.tutorialProgress = NPE_PROGRESS_ACCOUNTCREATED
					triggerNPE.npeStarted = false
					LuaTrigger.GetTrigger('newPlayerExperience'):Trigger(false)
					NewPlayerExperience.setTutorialProgress(NPE_PROGRESS_ACCOUNTCREATED, false)
					libThread.threadFunc(function()
						wait(1000)
						resumeNewPlayerExperience()
					end)
				elseif main == 101 then
					validMain = mainSectionAnimState(101, main, newMain) == 4
				elseif main == 0 then
					validMain = mainSectionAnimState(0, main, newMain) == 4
				elseif main == 2 and tutorialProgress == NPE_PROGRESS_SELECTEDPET then
					validMain = mainSectionAnimState(0, main, newMain) == 2
				end

				if validMain then
					local triggerLogin		= LuaTrigger.GetTrigger('LoginStatus')
					local fullyLoggedIn		= (triggerLogin.isLoggedIn and ((triggerLogin.hasIdent and triggerLogin.isIdentPopulated) or (((triggerLogin.externalLogin) and ((not triggerLogin.launchedViaSteam) or (triggerLogin.loggedInViaSteam))) and tutorialProgress < NPE_PROGRESS_ENTEREDNAME)))

					if ( triggerGamePhase.gamePhase == 0 and (not triggerNPE.tutorialComplete) and (not triggerNPE.npeStarted) and (fullyLoggedIn or (tutorialProgress < NPE_PROGRESS_ACCOUNTCREATED and (not NewPlayerExperience.requiresLogin))) ) then
						resumeNewPlayerExperience()
					elseif NewPlayerExperience.isNPEDemo2() then
						-- print('should show popup for npe demo 2=====================================\n')
						widget:GetWidget('newPlayerExperience_loadMap_demo2'):FadeIn(250)
						widget:GetWidget('newPlayerExperience_loadButton_demo2'):SetCallback('onclick', function(widget)
							StartGame('tutorial', Translate('game_name_default_tutorial'), 'map:tutorial_3 nolobby:true')
						end)
					end
				end
			end
		end)

		local newPlayerExperience_enterName				= object:GetWidget('newPlayerExperience_enterName')
		local newPlayerExperience_enterName_submit		= object:GetWidget('newPlayerExperience_enterName_submit')
		local newPlayerExperience_enterName_haveAccount	= object:GetWidget('newPlayerExperience_enterName_haveAccount')
		local newPlayerExperience_enterName_input		= object:GetWidget('newPlayerExperience_enterName_input')

		local function newPlayerExperience_enterName_valid()
			local inputValue	= newPlayerExperience_enterName_input:GetValue()
			return (inputValue and (string.len(inputValue) > 0) and (not ChatCensor.IsCensored(inputValue)))
		end

		local function newPlayerExperience_enterName_submitName()
			local inputValue = newPlayerExperience_enterName_input:GetValue()
			NewPlayerExperience.data.newIdentName = inputValue
			Cvar.GetCvar('net_name'):Set(inputValue)

			local IdentIDList = LuaTrigger.GetTrigger('IdentIDList')
			local triggerLogin = LuaTrigger.GetTrigger('LoginStatus')
			if (((triggerLogin.externalLogin) and ((not triggerLogin.launchedViaSteam) or (triggerLogin.loggedInViaSteam)))) and (not LuaTrigger.GetTrigger('LoginStatus').hasIdent) and ( (not IdentIDList) or (not IdentIDList.identNick0) or (Empty(IdentIDList.identNick0)) ) then
				CreateIdentID(inputValue)
			else
				println('not creating identID')
			end
			newPlayerExperience_enterName_input:EraseInputLine()
		end

		newPlayerExperience_enterName:SetCallback('onshow', function(widget)
			newPlayerExperience_enterName:SetCallback('onframe', function(widget)
				local IdentIDList = LuaTrigger.GetTrigger('IdentIDList')
				if (LuaTrigger.GetTrigger('LoginStatus').hasIdent) and ( (IdentIDList) and (IdentIDList.identNick0) and (not Empty(IdentIDList.identNick0)) ) then
					newPlayerExperience_enterName:ClearCallback('onframe')

					local inputValue = IdentIDList.identNick0
					NewPlayerExperience.data.newIdentName = inputValue
					Cvar.GetCvar('net_name'):Set(inputValue)

					newPlayerExperience_enterName_input:EraseInputLine()
					newPlayerExperience_enterName:FadeOut(250)

					NewPlayerExperience.trigger.tutorialProgress	= NPE_PROGRESS_ENTEREDNAME
					NewPlayerExperience.trigger.npeStarted			= false
					NewPlayerExperience.trigger:Trigger(false)
				end
			end)
		end)

		newPlayerExperience_enterName:SetCallback('onhide', function(widget)
			newPlayerExperience_enterName:ClearCallback('onframe')
		end)

		newPlayerExperience_enterName_input:SetCallback('onchange', function(widget)
			newPlayerExperience_enterName_submit:SetEnabled(newPlayerExperience_enterName_valid())
			if not widget:HasFocus() then
				object:GetWidget('newPlayerExperience_enterName_input_coverup'):SetVisible(string.len(widget:GetValue()) <= 0)
			end
		end)

		newPlayerExperience_enterName_input:RegisterWatchLua('loginNPEUpdate', function(widget, groupTrigger)
			local triggerAccount				= groupTrigger['AccountInfo']
			local triggerLogin					= groupTrigger['LoginStatus']
			local fullyLoggedIn					= (triggerLogin.isLoggedIn and ((triggerLogin.hasIdent and triggerLogin.isIdentPopulated) or (((triggerLogin.externalLogin) and ((not triggerLogin.launchedViaSteam) or (triggerLogin.loggedInViaSteam))))))

			widget:SetInputLine(triggerAccount.nickname)
			object:GetWidget('newPlayerExperience_enterName_input_coverup'):SetVisible(string.len(newPlayerExperience_enterName_input:GetValue()) <= 0)
		end)

		object:GetWidget('newPlayerExperience_enterName_input_coverup'):SetVisible(string.len(newPlayerExperience_enterName_input:GetValue()) <= 0)

		newPlayerExperience_enterName_input:SetCallback('onfocus', function(widget)
			object:GetWidget('newPlayerExperience_enterName_input_coverup'):SetVisible(false)
		end)

		newPlayerExperience_enterName_input:SetCallback('onlosefocus', function(widget)
			object:GetWidget('newPlayerExperience_enterName_input_coverup'):SetVisible(string.len(widget:GetValue()) <= 0)
		end)

		newPlayerExperience_enterName_submit:SetCallback('onclick', function(widget)
			newPlayerExperience_enterName_submitName()
		end)

		if NewPlayerExperience.isNPEDemo() or NewPlayerExperience.isNPEDemo2() then
			object:GetWidget('newPlayerExperience_enterName_haveAccountContainer'):SetVisible(false)
		else
			newPlayerExperience_enterName_haveAccount:SetCallback('onclick', function(widget)
				newPlayerExperience_enterName:FadeOut(250)
				object:GetWidget('main_login_prompt_parent'):FadeIn(250)
			end)

			newPlayerExperience_enterName_haveAccount:RegisterWatchLua('LoginStatus', function(widget, trigger)
				if ((trigger.externalLogin) and ((not trigger.launchedViaSteam) or (trigger.loggedInViaSteam))) then
					widget:SetVisible(false)
				end
			end, false, nil, 'externalLogin')
		end

		function newPlayerExperience_enterName_esc()
			newPlayerExperience_enterName_input:EraseInputLine()
		end

		function newPlayerExperience_enterName_enter()
			if newPlayerExperience_enterName_valid() then
				newPlayerExperience_enterName_submitName()
			end
		end

		local NPETut3PromptSelectHero		= false
		local NPETut3PromptSelectFamiliar	= false
		local NPETut3PromptSelectGear		= false

		libGeneral.createGroupTrigger('gamePhaseNPE', {
			'GamePhase.gamePhase',
			'newPlayerExperience.tutorialComplete',
			'newPlayerExperience.tutorialProgress',
			'HeroSelectLocalPlayerInfo.heroEntityName',
			'HeroSelectLocalPlayerInfo.petEntityName'
		})

		newPlayerExperience_script:RegisterWatchLua('gamePhaseNPE', function(widget, groupTrigger)
			local triggerNPE = groupTrigger['newPlayerExperience']
			if (not triggerNPE.tutorialComplete) then
				if triggerNPE.tutorialProgress == NPE_PROGRESS_SELECTEDPET then
					local gamePhase = groupTrigger['GamePhase'].gamePhase
					if gamePhase == 1 then

						NPETut3PromptSelectHero		= false
						NPETut3PromptSelectFamiliar	= false
						NPETut3PromptSelectGear		= false

						RequestBotFill()
						RequestBotDifficulty('tutorial3')
						Lobby.isFilledWithBots = true
						RequestMatchStart()

					elseif gamePhase == 3 then
						local playerInfo = groupTrigger['HeroSelectLocalPlayerInfo']
						local playerEntity	= playerInfo.heroEntityName
						local familiar		= playerInfo.petEntityName
						if (not NPETut3PromptSelectHero) and not (playerEntity and string.len(playerEntity) > 0) then
							widget:UICmd("StopSound(9)")
							-- ClearAllKeeperNotifications(true)
							clearNPEThreads()
							newNPEThread(function()
								wait(2000)
								PlaySound('/ui/sounds/tutorial/vo_announcer_3.wav', 1, 9)
								lastNPEThread = nil
							end)
							--Notifications.QueueKeeperPopupNotification(5500, Translate('new_player_experience_choosehero_01'), nil, nil, '/ui/main/keepers/textures/auros.png', nil, '/ui/sounds/tutorial/vo_announcer_3.wav', nil, true)
							NPETut3PromptSelectHero = true
						elseif (not NPETut3PromptSelectFamiliar) and not (familiar and string.len(familiar) > 0) then
							widget:UICmd("StopSound(9)")
							clearNPEThreads()
							-- ClearAllKeeperNotifications(true)
							-- Notifications.QueueKeeperPopupNotification(7500, Translate('new_player_experience_selectpet_01'), nil, nil, '/ui/main/keepers/textures/auros.png', nil, '/ui/sounds/tutorial/vo_announcer_4.wav', nil, true)
							newNPEThread(function()
								wait(2000)
								PlaySound('/ui/sounds/tutorial/vo_announcer_4.wav', 1, 9)
								-- spotlightWidget(object:GetWidget('selection_pet'))
								-- selection_pet
								wait(4500)
								-- spotlightWidget(object:GetWidget('selection_pet_entry_item_0Button'))

								lastNPEThread = nil
							end)

							NPETut3PromptSelectFamiliar = true
						elseif (not NPETut3PromptSelectGear) then
							widget:UICmd("StopSound(9)")
							spotlightWidget()
							-- ClearAllKeeperNotifications(true)
							clearNPEThreads()

							newNPEThread(function()
								wait(2000)

								NewPlayerExperience.trigger.busySpeaking = true
								NewPlayerExperience.trigger:Trigger(false)

								PlaySound('/ui/sounds/tutorial/vo_announcer_5.wav', 1, 9)	-- 6500

								local tempWidget
								local toHighlight = {}
								--[[
								for i=0,6,1 do
									tempWidget = object:GetWidget('selection_gear_set_dye_popup_item_'..i..'_button')
									if tempWidget and tempWidget:IsVisible() then
										table.insert(toHighlight, tempWidget)
									end
								end
								for i=0,3,1 do
									tempWidget = object:GetWidget('selection_gear_set_card_'..i..'_button')
									if tempWidget and tempWidget:IsVisible() then
										table.insert(toHighlight, tempWidget)
									end
								end
								widgetHighlightMulti(toHighlight)
								--]]

								wait(6500)

								--[[
								PlaySound('/ui/sounds/tutorial/vo_announcer_9.wav', 1, 9)	-- 5500

								toHighlight = {
									object:GetWidget('selection_builds_combobox_auto_btn_1'),
									object:GetWidget('selection_builds_combobox_auto_btn_2')
								}
								widgetHighlightMulti()
								widgetHighlightMulti(toHighlight)

								wait(5500)
								--]]

								--[[
									selection_builds_combobox
									selection_builds_combobox_auto_btn_1	-- items
									selection_builds_combobox_auto_btn_1	-- abilities

								--]]
								-- NewPlayerExperience.trigger.busySpeaking = true
								-- NewPlayerExperience.trigger:Trigger(false)
								NewPlayerExperience.trigger.busySpeaking = false
								NewPlayerExperience.trigger:Trigger(false)

								widgetHighlightMulti()
								PlaySound('/ui/sounds/tutorial/vo_announcer_6.wav', 1, 9)
								-- spotlightWidget(object:GetWidget('selection_ribbons_primary_btn'))
								wait(6500)
								widgetHighlightMulti()
								spotlightWidget()

								lastNPEThread = nil

							end)
							-- Notifications.QueueKeeperPopupNotification(6500, Translate('new_player_experience_choosegear_01'), nil, nil, '/ui/main/keepers/textures/auros.png', nil, '/ui/sounds/tutorial/vo_announcer_5.wav', nil, true)
							-- Notifications.QueueKeeperPopupNotification(5500, Translate('new_player_experience_startmatch_01'), nil, nil, '/ui/main/keepers/textures/auros.png', nil, '/ui/sounds/tutorial/vo_announcer_6.wav', nil, true)
							NPETut3PromptSelectGear = true
						end
					end
				end
			end
		end)

		object:GetWidget('newPlayerExperience_continue_tutorial'):SetCallback('onclick', function(widget)
			local popup = object:GetWidget('newPlayerExperience_loadMap')
			local tutorialProgress	= NewPlayerExperience.trigger.tutorialProgress

			libThread.threadFunc(function()
				popup:FadeOut(250)
				wait(250)
				if tutorialProgress == NPE_PROGRESS_ENTEREDNAME then
					NewPlayerExperience.data.seenTowerDamageWarning		= false
					NewPlayerExperience.data.seenAttackHeroWarning		= false
					ManagedSetLoadingInterface('loading_npe_1')
					StartGame('tutorial', Translate('game_name_default_tutorial'), 'map:tutorial nolobby:true')
				elseif tutorialProgress == NPE_PROGRESS_FINISHTUT1 then
					ManagedSetLoadingInterface('loading_npe_2')
					StartGame('tutorial', Translate('game_name_default_tutorial'), 'map:tutorial_2 nolobby:true')
				elseif tutorialProgress == NPE_PROGRESS_SELECTEDPET then
					StartGame('practice', Translate('game_name_default_practice'), 'map:tutorial_3')
				else
					print('trying to use newPlayerExperience_loadMap with invalid progress!\n')
					resumeNewPlayerExperience()
					wait(500)
					Cmd('ReloadInterfaces')
				end
			end)
		end)

		if LuaTrigger.GetTrigger('NPEPetPicked') then LuaTrigger.DestroyGroupTrigger('NPEPetPicked') end
		LuaTrigger.CreateGroupTrigger('NPEPetPicked', {
			'newPlayerExperience.tutorialProgress',
			'newPlayerExperience.tutorialComplete',
			'Corral.initialPetPicked'
		})

		newPlayerExperience_script:RegisterWatchLua('NPEPetPicked', function(widget, groupTrigger)
			local triggerNPE			= groupTrigger['newPlayerExperience']

			if not triggerNPE.tutorialComplete then
				local tutorialProgress		= triggerNPE.tutorialProgress
				local initialPetPicked		= groupTrigger['Corral'].initialPetPicked

				if tutorialProgress == NPE_PROGRESS_ACCOUNTCREATED and initialPetPicked then

					local function notificationsFinish()
						NewPlayerExperience.trigger.npeStarted			= false
						NewPlayerExperience.trigger.tutorialProgress	= NPE_PROGRESS_SELECTEDPET
						NewPlayerExperience.trigger:Trigger(false)
					end
					spotlightWidget()
					Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_choosepet_04_length') + 500), Translate('new_player_experience_choosepet_04'), nil, nil, '/ui/main/keepers/textures/auros.png', notificationsFinish, '/ui/sounds/tutorial/vo_auros_6.wav', nil, true, nil, nil, 'auros', 'ui_4')
				end
			end
		end)

		newPlayerExperience_script:RegisterWatchLua('mainPanelAnimationStatus', function(widget, trigger)

			if NewPlayerExperience.trigger.tutorialProgress == NPE_PROGRESS_ACCOUNTCREATED then

				local petsMainStatus = mainSectionAnimState(2, trigger.main, trigger.newMain)

				if petsMainStatus == 4 then
					ClearAllKeeperNotifications(true)
					clearNPEThreads()
					clearNPEWidgetFocus()

					-- darkenScreen(true)

					Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_choosepet_01_length') + 500), Translate('new_player_experience_choosepet_01'), nil, nil, '/ui/main/keepers/textures/auros.png', nil, '/ui/sounds/tutorial/vo_auros_1.wav', nil, true, nil, nil, 'auros', 'ui_1')
					Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_choosepet_02_length') + 500), Translate('new_player_experience_choosepet_02'), nil, nil, '/ui/main/keepers/textures/auros.png', nil, '/ui/sounds/tutorial/vo_auros_2.wav', function()
						--[[
							-- rmm for now, at least
						newNPEThread(function()
							wait(2693)
							local petSlots = {
								object:GetWidget('mainPetsListEntry0Button'),
								object:GetWidget('mainPetsListEntry1Button'),
								object:GetWidget('mainPetsListEntry2Button')
							}
							widgetHighlightPlacePlaceholder(petSlots, true)
							spotlightWidget(widgetHighlightGetPlaceholder())
							wait(3807)
							spotlightWidget(object:GetWidget('mainPetsXPHighlightTarget'))
							wait(2381)
							spotlightWidget(object:GetWidget('mainPetsInfo'))
							lastNPEThread = nil
						end)
						--]]
					end, true, nil, nil, 'auros', 'ui_2')
					Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_choosepet_03_length') + 500), Translate('new_player_experience_choosepet_03'), nil, nil, '/ui/main/keepers/textures/auros.png', function()
						--[[
						clearNPEThreads()
						local petSlots = {
							object:GetWidget('mainPetsListEntry0Button'),
							object:GetWidget('mainPetsListEntry1Button'),
							object:GetWidget('mainPetsListEntry2Button')
						}
						widgetHighlightPlacePlaceholder(petSlots, true)
						spotlightWidget(widgetHighlightGetPlaceholder())
						--]]

						-- darkenScreen()

					end, '/ui/sounds/tutorial/vo_auros_3.wav', function()
						--[[
						clearNPEThreads()
						clearNPEWidgetFocus()

						newNPEThread(function()
							wait(5630)
							local petSlots = {
								object:GetWidget('mainPetsListEntry0Button'),
								object:GetWidget('mainPetsListEntry1Button'),
								object:GetWidget('mainPetsListEntry2Button')
							}
							widgetHighlightPlacePlaceholder(petSlots, true)
							spotlightWidget(widgetHighlightGetPlaceholder())
							lastNPEThread = nil
						end)
						--]]
					end, true, nil, nil, 'auros', 'ui_3')
				elseif petsMainStatus == 1 and trigger.lastMain == 2 then
					ClearAllKeeperNotifications(true)
					clearNPEThreads()
					clearNPEWidgetFocus()
				end

			end
		end, false, nil, 'main', 'newMain')


		function newPlayerExperienceCompleted(showNotification)
			if showNotification == nil then showNotification = true end

			if showNotification then
				Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_finishcampaign_01_length')), Translate('new_player_experience_finishcampaign_01'), nil, nil, '/ui/main/keepers/textures/lexikhan.png', notificationsFinishB, '/ui/sounds/tutorial/vo_khan_8.wav', nil, true, true, nil, 'khan', 'ui_8')
			
				libThread.threadFunc(function()
					wait(GetSoundDurationFromStringKey('new_player_experience_finishcampaign_01_length'))			
			
					NewPlayerExperience.trigger.tutorialProgress = NPE_PROGRESS_TUTORIALCOMPLETE
					NewPlayerExperience.trigger.tutorialComplete = true
					NewPlayerExperience.trigger:Trigger(false)			
					
					wait(1200)
					
					if (not mainUI.savedRemotely) or (not mainUI.savedRemotely.splashScreensViewed) or (not mainUI.savedRemotely.splashScreensViewed['splash_screen_control_presets']) then
						mainUI.savedRemotely = mainUI.savedRemotely or {}
						mainUI.savedRemotely.splashScreensViewed = mainUI.savedRemotely.splashScreensViewed or {}
						mainUI.savedRemotely.splashScreensViewed['splash_screen_control_presets'] = true
						SaveState()
						local mainPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
						mainPanelStatus.main = mainUI.MainValues.controlPresets
						mainPanelStatus:Trigger(false)
					end						
				
				end)
			else
				NewPlayerExperience.trigger.tutorialProgress = NPE_PROGRESS_TUTORIALCOMPLETE
				NewPlayerExperience.trigger.tutorialComplete = true
				NewPlayerExperience.trigger:Trigger(false)			
			end
		end

		object:GetWidget('main_top_button_container'):RegisterWatchLua('newPlayerExperience', function(widget, trigger)
			widget:SetVisible(trigger.tutorialComplete or trigger.tutorialProgress >= NPE_PROGRESS_SELECTEDPET)
		end, false, nil, 'tutorialComplete', 'tutorialProgress')

		function resumeNewPlayerExperience()
			local canResume = true

			if NewPlayerExperience.crippledRegion() then
				canResume = false
			elseif NewPlayerExperience.requiresLogin then
				local triggerLogin	= LuaTrigger.GetTrigger('LoginStatus')
				if (not triggerLogin.isLoggedIn) and (not triggerLogin.hasIdent) and ((not triggerLogin.externalLogin) or (triggerLogin.launchedViaSteam and triggerLogin.loggedInViaSteam)) then
					canResume	= false
				end
			end

			if canResume then

				local tutorialProgress	= NewPlayerExperience.trigger.tutorialProgress

				NewPlayerExperience.trigger.npeStarted = true

				if tutorialProgress == NPE_PROGRESS_START then
					local function notificationsFinish()
						newPlayerExperience_enterName:FadeIn(250)
						local triggerLogin	= LuaTrigger.GetTrigger('LoginStatus')
						if (not (NewPlayerExperience.isNPEDemo() or NewPlayerExperience.isNPEDemo2() or ((triggerLogin.externalLogin) and ((not triggerLogin.launchedViaSteam) or (triggerLogin.loggedInViaSteam))))) then
							object:GetWidget('newPlayerExperience_skipToLogin'):FadeIn(250)
						end
					end

					Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_intro_01_length')), Translate('new_player_experience_intro_01'), nil, nil, '/ui/main/keepers/textures/lexikhan.png', nil, '/ui/sounds/tutorial/vo_khan_1.wav', nil, true, true, nil, 'khan', 'ui_1')
					Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_intro_02_length')), Translate('new_player_experience_intro_02'), nil, nil, '/ui/main/keepers/textures/lexikhan.png', notificationsFinish, '/ui/sounds/tutorial/vo_khan_2.wav', nil, true, true, nil, 'khan', 'ui_2')
				elseif tutorialProgress == NPE_PROGRESS_ENTEREDNAME then
					local function notificationsFinish()
						object:GetWidget('newPlayerExperience_loadMap'):FadeIn(250)
					end

					object:GetWidget('createAccountIdent'):SetInputLine(NewPlayerExperience.data.newIdentName or '')
					Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_intro_03_length')), Translate('new_player_experience_intro_03'), nil, nil, '/ui/main/keepers/textures/lexikhan.png', notificationsFinish, '/ui/sounds/tutorial/vo_khan_3.wav', nil, true, true, nil, 'khan', 'ui_3')
				elseif tutorialProgress == NPE_PROGRESS_FINISHTUT1 then	-- Finish tutorial 1, continue to tutorial 2
					local function notificationsFinish()
						object:GetWidget('newPlayerExperience_loadMap'):FadeIn(250)

					end

					Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_rescue_01_length')), Translate('new_player_experience_rescue_01'), nil, nil, '/ui/main/keepers/textures/lexikhan.png', nil, '/ui/sounds/tutorial/vo_khan_4_1.wav', nil, true, true, nil, 'khan', 'ui_4_1')
					Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_rescue_02_length')), Translate('new_player_experience_rescue_02'), nil, nil, '/ui/main/keepers/textures/lexikhan.png', nil, '/ui/sounds/tutorial/vo_khan_4_2.wav', nil, true, true, nil, 'khan', 'ui_4_2')
					Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_rescue_03_length')), Translate('new_player_experience_rescue_03'), nil, nil, '/ui/main/keepers/textures/lexikhan.png', notificationsFinish, '/ui/sounds/tutorial/vo_khan_4b.wav', nil, true, true, nil, 'khan', 'ui_4b')
				elseif tutorialProgress == NPE_PROGRESS_FINISHTUT2 then	-- Finish tutorial 2, need an account
					--[[
						-- rmm hack to skip tutorial 3
					if not NewPlayerExperience.trigger.tutorialComplete then
						Notifications.QueueKeeperPopupNotification(12500, Translate('new_player_experience_finishcampaign_01'), nil, nil, '/ui/main/keepers/textures/lexikhan.png', notificationsFinishB, '/ui/sounds/tutorial/vo_khan_8.wav', nil, true, true)
						NewPlayerExperience.trigger.tutorialProgress = NPE_PROGRESS_FINISHTUT3
						NewPlayerExperience.trigger.tutorialComplete = true
						NewPlayerExperience.trigger:Trigger(false)
					end
					--]]
					local triggerLogin	= LuaTrigger.GetTrigger('LoginStatus')
					if ((triggerLogin.externalLogin) and ((not triggerLogin.launchedViaSteam) or (triggerLogin.loggedInViaSteam))) then
						NewPlayerExperience.trigger.tutorialProgress	= NPE_PROGRESS_ACCOUNTCREATED
						NewPlayerExperience.trigger.npeStarted			= false
						NewPlayerExperience.trigger:Trigger(false)
					else
						local function notificationsFinish()
						
							GenericDialogAutoSize(
								Translate('general_go_to_website'), Translate('general_go_to_createaccount'), '', 'general_ok', 'general_cancel',
									function()
										mainUI.OpenURL(Strife_Region.regionTable[Strife_Region.activeRegion].createAccountURL or 'http://www.strife.com')
									end,
									nil
							)						
						
							local mainPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
							mainPanelStatus.main = 0
							mainPanelStatus:Trigger(false)
						end

						Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_postrescue_01_length')), Translate('new_player_experience_postrescue_01'), nil, nil, '/ui/main/keepers/textures/lexikhan.png', notificationsFinish, '/ui/sounds/tutorial/vo_khan_5.wav', nil, true, true, nil, 'khan', 'ui_5')
					end
				elseif tutorialProgress == NPE_PROGRESS_ACCOUNTCREATED then
					-- Account created, get user to habitat/select a pet
					-- Will need to log in to hit this point++

					if LuaTrigger.GetTrigger('Corral').initialPetPicked then	-- or already selected?
						NewPlayerExperience.trigger.tutorialProgress = NPE_PROGRESS_SELECTEDPET
						NewPlayerExperience.trigger:Trigger(false)
					else
						local function notificationsFinish()
							object:GetWidget('main_top_button_petsPulseEffect'):SetVisible(true)
							object:GetWidget('main_top_button_container'):FadeIn(250)
						end
						Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_postrescue_02_length')), Translate('new_player_experience_postrescue_02'), nil, nil, '/ui/main/keepers/textures/lexikhan.png', notificationsFinish, '/ui/sounds/tutorial/vo_khan_6.wav', nil, true, true, nil, 'khan', 'ui_6')
					end

				elseif tutorialProgress == NPE_PROGRESS_SELECTEDPET then
					-- Return from Corral, prep to start tuotrial

					local function notificationsFinishB()
						object:GetWidget('newPlayerExperience_loadMap'):FadeIn(250)
						object:GetWidget('main_top_button_petsPulseEffect'):SetVisible(false)
					end

					local triggerPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
					triggerPanelStatus.main = 101
					triggerPanelStatus:Trigger(false)

					newPlayerExperience_script:Sleep(1, function()
						Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_firstmatch_01_length')), Translate('new_player_experience_firstmatch_01'), nil, nil, '/ui/main/keepers/textures/lexikhan.png', notificationsFinishB, '/ui/sounds/tutorial/vo_khan_7.wav', nil, true, true, nil, 'khan', 'ui_7')

						-- rmm skip friend stuff
						-- Notifications.QueueKeeperPopupNotification(4500, Translate('new_player_experience_addfriend_01'), nil, nil, false, nil, '/ui/sounds/tutorial/vo_announcer_1.wav', nil, true)
						-- Notifications.QueueKeeperPopupNotification(4500, Translate('new_player_experience_addfriend_02'), nil, nil, false, nil, '/ui/sounds/tutorial/vo_announcer_2.wav', nil, true)

						--[[
						Notifications.QueueKeeperPopupNotification(5500, Translate('new_player_experience_choosehero_01'), nil, nil, false, nil, '/ui/sounds/tutorial/vo_announcer_3.wav', nil, true)
						-- Wait until hero is selected
						Notifications.QueueKeeperPopupNotification(7500, Translate('new_player_experience_selectpet_01'), nil, nil, false, nil, '/ui/sounds/tutorial/vo_announcer_4.wav', nil, true)
						-- Wait until pet is selected
						Notifications.QueueKeeperPopupNotification(6500, Translate('new_player_experience_choosegear_01'), nil, nil, false, nil, '/ui/sounds/tutorial/vo_announcer_5.wav', nil, true)
						Notifications.QueueKeeperPopupNotification(5500, Translate('new_player_experience_startmatch_01'), nil, nil, false, nil, '/ui/sounds/tutorial/vo_announcer_6.wav', nil, true)
						--]]
					end)
				elseif tutorialProgress == NPE_PROGRESS_FINISHTUT3 then
					if NewPlayerExperience.trigger.rewardsIntroProgress >= 1 then	-- Would have to finish rewards yet not successfully return to main
						newPlayerExperienceCompleted()
					end
				elseif tutorialProgress >= NPE_PROGRESS_TUTORIALCOMPLETE then	-- Completed tutorial but tutorial not marked as complete (should silently update local completion)
					newPlayerExperienceCompleted(false)
				end
			end
		end	-- end resumeNewPlayerExperience

		---[[
		local function updateContinueButtonLabel(widget, trigger)
			local tutorialProgress = trigger.tutorialProgress

			if tutorialProgress == NPE_PROGRESS_START then	-- Begin
				widget:SetText(Translate('new_player_experience_continue_01'))
			elseif tutorialProgress == NPE_PROGRESS_ENTEREDNAME then	-- Rescue auros
				widget:SetText(Translate('new_player_experience_continue_01'))
			elseif tutorialProgress == NPE_PROGRESS_FINISHTUT1 then	-- Rescue auros
				widget:SetText(Translate('new_player_experience_continue_02'))
			elseif tutorialProgress == NPE_PROGRESS_FINISHTUT2 or tutorialProgress == NPE_PROGRESS_ACCOUNTCREATED or tutorialProgress == NPE_PROGRESS_SELECTEDPET then	-- Trial of strife
				widget:SetText(Translate('new_player_experience_continue_03'))
			elseif tutorialProgress >= NPE_PROGRESS_FINISHTUT3 then
				widget:SetText(Translate('new_player_experience_continue_04'))
			end
		end

		object:GetWidget('newPlayerExperience_continue_tutorialLabel'):RegisterWatchLua('newPlayerExperience', updateContinueButtonLabel, false, nil, 'tutorialProgress')

		object:GetWidget('newPlayerExperience_skipToLogin'):RegisterWatchLua('loginNPEStatus', function(widget, groupTrigger)
			local triggerNewPlayerExperience	= groupTrigger['newPlayerExperience']
			local triggerGamePhase				= groupTrigger['GamePhase']
			local triggerMainPanelStatus		= groupTrigger['mainPanelStatus']
			local triggerLogin					= LuaTrigger.GetTrigger('LoginStatus')

			if (not (NewPlayerExperience.isNPEDemo() or NewPlayerExperience.isNPEDemo2())) and (not NewPlayerExperience.crippledRegion()) then
				widget:SetVisible((not NewPlayerExperience.requiresLogin) and triggerMainPanelStatus.main == 0 and not (triggerNewPlayerExperience.showLogin) and triggerNewPlayerExperience.tutorialProgress >= NPE_PROGRESS_ENTEREDNAME and triggerNewPlayerExperience.tutorialProgress < NPE_PROGRESS_FINISHTUT2 and (not triggerNewPlayerExperience.tutorialComplete))
				local fullyLoggedIn				= (triggerLogin.isLoggedIn and triggerLogin.hasIdent and triggerLogin.isIdentPopulated)
				if (fullyLoggedIn) then
					genericEvent.broadcast('newPlayerExperience_checkCanSkip')
				end
			end
		end)

		object:GetWidget('newPlayerExperience_skipToLogin'):SetCallback('onclick', function(widget, trigger)
			ClearAllKeeperNotifications(true)
			clearNPEThreads()
			clearNPEWidgetFocus()

			object:GetWidget('newPlayerExperience_enterName'):FadeOut(250)
			object:GetWidget('newPlayerExperience_skipToLogin'):FadeOut(250)
			object:GetWidget('newPlayerExperience_loadMap'):FadeOut(250)

			local triggerLogin = LuaTrigger.GetTrigger('LoginStatus')

			if triggerLogin.isLoggedIn and (triggerLogin.hasIdent or ((triggerLogin.externalLogin) and ((not triggerLogin.launchedViaSteam) or (triggerLogin.loggedInViaSteam)))) then
				NewPlayerExperience.trigger.tutorialProgress	= NPE_PROGRESS_ENTEREDNAME
				NewPlayerExperience.trigger.npeStarted			= false
				NewPlayerExperience.trigger:Trigger(false)
			else
				NewPlayerExperience.trigger.showLogin	= true
				NewPlayerExperience.trigger:Trigger(false)
			end
		end)

		NewPlayerExperience.trigger.tutorialComplete		= NewPlayerExperience.data.tutorialComplete
		NewPlayerExperience.trigger.tutorialProgress		= NewPlayerExperience.data.tutorialProgress
		NewPlayerExperience.trigger.craftingIntroProgress	= NewPlayerExperience.data.craftingIntroProgress or 0
		NewPlayerExperience.trigger.craftingIntroStep		= 0
		NewPlayerExperience.trigger.enchantingIntroProgress	= NewPlayerExperience.data.enchantingIntroProgress or 0
		NewPlayerExperience.trigger.enchantingIntroStep		= 0
		NewPlayerExperience.trigger.corralIntroProgress		= NewPlayerExperience.data.corralIntroProgress or 0
		NewPlayerExperience.trigger.corralIntroStep			= 0
		NewPlayerExperience.trigger.rewardsIntroProgress	= NewPlayerExperience.data.rewardsIntroProgress or 0
		NewPlayerExperience.trigger.rewardsIntroStep		= 0

		object:GetWidget('createAccountIdent'):SetInputLine(NewPlayerExperience.data.newIdentName or '')

		NewPlayerExperience.trigger.showLogin				= false
		NewPlayerExperience.trigger.npeStarted				= false
		NewPlayerExperience.trigger:Trigger(true)

		genericEvent.register(newPlayerExperience_script, 'closePlayRewards_endMatch', function()
			local triggerNPE = NewPlayerExperience.trigger

			if not triggerNPE.tutorialComplete then
				Notifications.QueueKeeperPopupNotification((GetSoundDurationFromStringKey('new_player_experience_finishcampaign_01_length')), Translate('new_player_experience_finishcampaign_01'), nil, nil, '/ui/main/keepers/textures/lexikhan.png', notificationsFinishB, '/ui/sounds/tutorial/vo_khan_8.wav', nil, true, true, nil, 'khan', 'ui_8')
				triggerNPE.tutorialComplete = true
				triggerNPE:Trigger(false)
			end
		end)

		genericEvent.register(newPlayerExperience_script, 'playRewards_chestShuffleComplete', function()
			local triggerNPE = NewPlayerExperience.trigger

			if triggerNPE.rewardsIntroStep == 2 then
				triggerNPE.rewardsIntroStep = 3
				triggerNPE:Trigger(false)
				playRewards.chestGame(false)
			end

			if triggerNPE.rewardsIntroStep == 1 then
				triggerNPE.rewardsIntroStep = 2
				triggerNPE:Trigger(false)
			end
		end)

		genericEvent.register(newPlayerExperience_script, 'playRewards_rewardProgress2', function()
			local triggerNPE = NewPlayerExperience.trigger

			if triggerNPE.rewardsIntroStep < 3 then
				triggerNPE.rewardsIntroStep = 3
				triggerNPE:Trigger(false)
			end
		end)

	else	-- new player experience disabled in region
		NewPlayerExperience.requiresLogin = true

		function newPlayerExperienceCraftingStep(step, progress)
		end

		function newPlayerExperienceEnchantingStep(step, progress)
		end

		function newPlayerExperiencePetsStep(step, progress)
		end

		NewPlayerExperience.trigger.tutorialComplete		= true
		NewPlayerExperience.trigger.tutorialProgress		= NPE_PROGRESS_FINISHTUT3
		NewPlayerExperience.trigger.craftingIntroProgress	= 1
		NewPlayerExperience.trigger.craftingIntroStep		= 0
		NewPlayerExperience.trigger.enchantingIntroProgress	= 1
		NewPlayerExperience.trigger.enchantingIntroStep		= 0
		NewPlayerExperience.trigger.corralIntroProgress		= 2
		NewPlayerExperience.trigger.corralIntroStep			= 0
		NewPlayerExperience.trigger.rewardsIntroProgress	= 1
		NewPlayerExperience.trigger.rewardsIntroStep		= 0
		NewPlayerExperience.trigger.busySpeaking			= false

		NewPlayerExperience.trigger.showLogin				= false
		NewPlayerExperience.trigger.npeStarted				= false
		NewPlayerExperience.trigger:Trigger(true)

	end		-- end new player experience for build/region check

	local skipSectionButton = object:GetWidget('newPlayerExperience_skipSection')

	skipSectionButton:SetCallback('onclick', function(widget)
		GenericDialog(
			'new_player_experience_skipallnpe', 'new_player_experience_skipallnpe_desc', '', 'general_ok', 'general_cancel',
			function()
				ClearAllKeeperNotifications(true)
				clearNPEThreads()
				clearNPEWidgetFocus()
				object:GetWidget('newPlayerExperience_loadMap'):FadeOut(250)
				if (LuaTrigger.GetTrigger('LoginStatus').hasIdent) then
					libThread.threadFunc(function()
						wait(200)
						LuaTrigger.GetTrigger('mainPanelStatus').main = 101
						LuaTrigger.GetTrigger('mainPanelStatus'):Trigger(true)
					end)
				else
					object:GetWidget('main_login_prompt_parent'):FadeIn(250)
				end
				object:GetWidget('newPlayerExperience_enterName'):FadeOut(250)
				skipSectionButton:FadeOut(250)
				NewPlayerExperience.trigger.npeStarted = false

				NewPlayerExperience.progressSkip()
			end,
			function()
				-- soundEvent - Cancel
				PlaySound('/ui/sounds/sfx_ui_back.wav')
			end
		)
	end)

	genericEvent.register(skipSectionButton, 'newPlayerExperience_checkCanSkip', function()
		libGeneral.fade(skipSectionButton, NewPlayerExperience.progressCanSkip(), 250)
	end)


	object:GetWidget('newPlayerExperience_saveIndicator'):RegisterWatchLua('setTutorialProgressStatus', function(widget, trigger)
		libGeneral.fade(widget, (trigger.busy and trigger.lastStatus == 2), 500)
	end)


	if (Strife_Region.regionTable) and (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].new_player_experience) then

		-- ====================================================
		-- NPE CRAFTING
		-- ====================================================

		genericEvent.register(newPlayerExperience_script, 'crafting_selectRecipe', function()
			if (NewPlayerExperience.trigger.craftingIntroProgress == 0 and NewPlayerExperience.trigger.craftingIntroStep == 0) and (LuaTrigger.GetTrigger('CraftingCommodityInfo').oreCount >= 360) then
				newPlayerExperienceCraftingStep(1)
			end
		end)

		genericEvent.register(newPlayerExperience_script, 'crafting_selectComponent', function()
			if NewPlayerExperience.trigger.craftingIntroProgress == 0 and NewPlayerExperience.trigger.craftingIntroStep == 4 then
				newPlayerExperienceCraftingStep(5)
			end

			if NewPlayerExperience.trigger.craftingIntroProgress == 0 and NewPlayerExperience.trigger.craftingIntroStep == 3 then
				newPlayerExperienceCraftingStep(4)
			end
		end)

		genericEvent.register(newPlayerExperience_script, 'crafting_openEnchanting', function()
			if NewPlayerExperience.trigger.craftingIntroProgress == 0 and NewPlayerExperience.trigger.craftingIntroStep == 5 then
				newPlayerExperienceCraftingStep(6)
			end
		end)

		genericEvent.register(newPlayerExperience_script, 'crafting_haveValidImbuement', function()
			if NewPlayerExperience.trigger.craftingIntroProgress == 0 and NewPlayerExperience.trigger.craftingIntroStep == 6 then
				newPlayerExperienceCraftingStep(7)
			end
		end)

		genericEvent.register(newPlayerExperience_script, 'crafting_itemCrafted', function()
			if NewPlayerExperience.trigger.craftingIntroProgress == 0 and NewPlayerExperience.trigger.craftingIntroStep == 7 then
				newPlayerExperienceCraftingStep(8)
			
			--pad if something went wrong and we crafted an item without being in the crafting tutorial, skip the tutorial
			elseif NewPlayerExperience.trigger.craftingIntroProgress == 0 then
				newPlayerExperienceCraftingStep(0,1)
			end
		end)
	end
end

newPlayerExperienceRegister(object)
