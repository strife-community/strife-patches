
local GetTrigger 				= LuaTrigger.GetTrigger
local triggerStatus 			= GetTrigger('selection_Status')
local triggerLobbyStatus 		= GetTrigger('LobbyStatus')
local triggerHeroSelectInfo 	= GetTrigger('HeroSelectInfo')
local triggerLobbyGameInfo 		= GetTrigger('LobbyGameInfo')
local triggerPartyStatus 		= GetTrigger('PartyStatus')
local partyCustomTrigger 		= GetTrigger('PartyTrigger')
local partyComboTrigger 		= GetTrigger('PartyComboStatus')
local HeroSelectLocalPlayerInfo	= GetTrigger('HeroSelectLocalPlayerInfo')
local ChatAvailability 			= GetTrigger('ChatAvailability')
local clientInfoDrag			= GetTrigger('clientInfoDrag')
local globalDragInfo			= GetTrigger('globalDragInfo')
local GamePhase 				= GetTrigger('GamePhase')
local teamPlayerInfos 			= GetTrigger('TeamPlayerInfos') or libGeneral.createGroupTrigger('TeamPlayerInfos', {'HeroSelectPlayerInfo0', 'HeroSelectPlayerInfo1', 'HeroSelectPlayerInfo2', 'HeroSelectPlayerInfo3', 'HeroSelectPlayerInfo4', 'HeroSelectLocalPlayerInfo', 'PartyStatus.queue', 'PartyStatus.wins', 'PartyStatus.losses'})

local slot = nil
local previousSlot = nil
local teamID = nil
local selectedIndex = nil
local lastHero = 1
local lastPet = 1

local function registerWatchAndDo(widget, trigger, func, ...)
	widget:UnregisterWatchLua(trigger)
	widget:RegisterWatchLua(trigger, func, unpack(arg))
	func(widget, LuaTrigger.GetTrigger(trigger))
end

local function InitHeroes()

	local selection_captains_mode_hero_pool 				= GetWidget('selection_captains_mode_hero_pool')

	local selection_captains_mode_hero_listbox 				= GetWidget('selection_captains_mode_hero_listbox')
	local selection_captains_mode_hero_listbox_vscroll 		= GetWidget('selection_captains_mode_hero_listbox_vscroll')

	
	local function showHeroes()
		local phase = LuaTrigger.GetTrigger('HeroSelectPhaseCountdown').phase
		local gamePhase = LuaTrigger.GetTrigger('GamePhase').gamePhase
		local heroSelected = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName ~= ""
		return gamePhase > 2 and (phase == 'preban' or phase == 'banning' or phase == 'pick' or phase == 'captainpick') and not heroSelected
	end
	
	selection_captains_mode_hero_pool:RegisterWatchLua('HeroSelectPhaseCountdown', function(widget, trigger)
		widget:SetVisible(showHeroes())
	end, false, nil, 'phase')
	selection_captains_mode_hero_pool:RegisterWatchLua('HeroSelectLocalPlayerInfo', function(widget, trigger)
		widget:SetVisible(showHeroes())
	end, false, nil, 'heroEntityName')
	
	local function WhoPickedThatHero(entityName)
		for playerIndex = 0, 10, 1 do
			local heroInfo = GetTrigger('HeroSelectPlayerInfo' .. playerIndex)
			if (heroInfo) and (heroInfo.heroEntityName == entityName) then
				-- return the account icon
				if (heroInfo.accountIconPath) and (not Empty(heroInfo.accountIconPath)) then
					return heroInfo.accountIconPath
				else
					return '/ui/main/friends/textures/icon_profile.tga'
				end
			end
		end
		return '/ui/main/friends/textures/icon_profile.tga'
	end

	local function HeroRegister(index, heroListbox, prefix)
		local container		= GetWidget('selection_hero_entry_item_'..prefix..index)
		local hoverGlow		= GetWidget('selection_hero_entry_item_'..prefix..index..'hoverGlow')
		local icon			= GetWidget('selection_hero_entry_item_'..prefix..index..'Icon')
		local heroName		= GetWidget('selection_hero_entry_item_'..prefix..index..'Name')
		local frame			= GetWidget('selection_hero_entry_item_'..prefix..index..'Frame')
		local picked		= GetWidget('selection_hero_entry_item_'..prefix..index..'Picked')
		local pickedIcon	= GetWidget('selection_hero_entry_item_'..prefix..index..'PickedIcon')
		local button		= GetWidget('selection_hero_entry_item_'..prefix..index..'Button')
		-- local border		= GetWidget('selection_hero_entry_item_'..prefix..index..'_border')
		local hover			= GetWidget('selection_hero_entry_item_'..prefix..index..'Hover')
		local hoverTexture	= GetWidget('selection_hero_entry_item_'..prefix..index..'HoverTexture')
		local recommended	= GetWidget('selection_hero_entry_item_'..prefix..index..'Recommended')
		local mastered		= GetWidget('selection_hero_entry_item_'..prefix..index..'Mastered')
		local longwait		= GetWidget('selection_hero_entry_item_'..prefix..index..'LongWait')
		local banned		= GetWidget('selection_hero_entry_item_'..prefix..index..'Banned')
		local locked		= GetWidget('selection_hero_entry_item_'..prefix..index..'Locked')


		local lastIndex		= nil

		local triggerSlotInfo = LuaTrigger.CreateCustomTrigger(
			'heroSelectSlot'..prefix..index,
			{
				{ name	= 'index',					type	= 'number' }
			}
		)

		local newIndex		= index

		if lastIndex ~= nil then
			container:UnregisterAllWatchLuaByKey('heroSelectHero'..index..'Watch')
		end

		if newIndex >= 0 then
			heroListbox:ShowItemByValue(index)

			lastIndex = newIndex

			local HeroSelectHeroList_trigger = GetTrigger('HeroSelectHeroList'..newIndex)
			local trigger_heroSelectInfo 	= GetTrigger('HeroSelectInfo')

			registerWatchAndDo(icon, 'HeroSelectHeroList'..newIndex, function(widget, trigger)
				widget:SetTexture(trigger.iconPath)
				if trigger.canSelect and ((trigger_heroSelectInfo.teamID == 1) or (trigger_heroSelectInfo.teamID == 2)) and (not trigger.isBanned) then
					widget:SetRenderMode('normal')
				else
					widget:SetRenderMode('grayscale')
				end
			end, false, 'heroSelectHero'..index..'Watch', 'iconPath', 'canSelect', 'isBanned')

			registerWatchAndDo(picked, 'HeroSelectHeroList'..newIndex, function(widget, trigger)
				widget:SetVisible(trigger.isAvailable == -2 and not trigger.canSelect)
			end, false, 'heroSelectHero'..index..'Watch', 'canSelect', 'isAvailable')

			registerWatchAndDo(pickedIcon, 'HeroSelectHeroList'..newIndex, function(widget, trigger)
				if trigger.isAvailable == -2 and (not trigger.canSelect) then
					local accountIcon = WhoPickedThatHero(trigger.entityName)
					widget:SetVisible(1)
					widget:SetTexture(accountIcon)
				else
					widget:SetVisible(0)
				end
			end, false, 'heroSelectHero'..index..'Watch', 'entityName', 'canSelect', 'isAvailable')

			registerWatchAndDo(heroName, 'HeroSelectHeroList'..newIndex, function(widget, trigger)
				widget:SetText(trigger.displayName)
				if (not trigger.canSelect) then
					widget:SetColor('.6 .6 .6 .8')
				else
					widget:SetColor('1 1 1 .8')
				end
			end, false, 'heroSelectHero'..index..'Watch', 'displayName', 'canSelect')

			button:RegisterWatchLua('HeroSelectHeroList'..newIndex, function(widget, trigger)
				widget:SetEnabled(trigger.canSelect)
			end, false, 'heroSelectHero'..index..'Watch', 'canSelect')

			button:SetCallback('onmouseout', function(widget2)
				triggerStatus.hoveringHero = -1
				triggerStatus:Trigger(false)
				simpleTipGrowYUpdate(false)
			end)

			button:SetCallback('onmouseover', function(widget)
				triggerStatus.hoveringHero = lastIndex or -1
				triggerStatus.stickyHoveringHero = lastIndex or -1
				triggerStatus:Trigger(false)
			end)

			registerWatchAndDo(locked, 'HeroSelectHeroList'..newIndex, function(widget, trigger)
				local team = GetTrigger('HeroSelectLocalPlayerInfo').teamID
				if (trigger.pickedByTeam > 0) and (trigger.pickedByTeam == team) then
					widget:SetVisible(0)
				elseif (trigger.pickedByTeam > 0) and (trigger.pickedByTeam ~= team) then
					widget:SetVisible(1)
				else
					widget:SetVisible(0)
				end
			end, false, nil, 'canSelect', 'pickedByTeam')
			
			registerWatchAndDo(frame, 'HeroSelectHeroList'..newIndex, function(widget, trigger)
				local team = GetTrigger('HeroSelectLocalPlayerInfo').teamID
				if (not trigger.canSelect) then
					widget:SetColor('.6 .6 .6 1')
				else
					widget:SetColor('1 1 1 1')
				end
				if (trigger.pickedByTeam > 0) and (trigger.pickedByTeam == team) then
					widget:SetTexture('/ui/main/shared/textures/iconframe_interactive_txt2_green.tga')
				elseif (trigger.pickedByTeam > 0) and (trigger.pickedByTeam ~= team) then
					widget:SetTexture('/ui/main/shared/textures/iconframe_interactive_txt2_red.tga')
				else
					widget:SetTexture('/ui/main/shared/textures/iconframe_interactive_txt2.tga')
				end
			end, false, nil, 'canSelect', 'pickedByTeam')				
			
			registerWatchAndDo(banned, 'HeroSelectPhaseCountdown', function(widget, trigger)
				if (trigger.phase == 'banning') then
					widget:SetColor('1 1 1 1')
				else
					widget:SetColor('.4 .4 .4 1')
				end
			end, false, nil, 'phase')

			registerWatchAndDo(banned, 'HeroSelectHeroList'..newIndex, function(widget, trigger)
				local team = GetTrigger('HeroSelectLocalPlayerInfo').teamID
				if (trigger.isBanned) then
					widget:SetVisible(1)
				else
					widget:SetVisible(0)
				end
			end, false, nil, 'isBanned')				
			
			registerWatchAndDo(hover, 'selection_Status', function(widget, trigger)
				if (triggerStatus.hoveringHero == newIndex) then
					widget:FadeIn(175)
				else
					widget:FadeOut(175)
				end
			end, false, nil, 'hoveringHero')
			
			registerWatchAndDo(hoverTexture, 'HeroSelectHeroList'..newIndex, function(widget, trigger)
				local team = GetTrigger('HeroSelectLocalPlayerInfo').teamID
				if (trigger.pickedByTeam > 0) and (trigger.pickedByTeam == team) then
					widget:SetTexture('/ui/main/shared/textures/iconframe_interactive_txt2_green_hover.tga')
				elseif (trigger.pickedByTeam > 0) and (trigger.pickedByTeam ~= team) then
					widget:SetTexture('/ui/main/shared/textures/iconframe_interactive_txt2_red_hover.tga')
				else
					widget:SetTexture('/ui/main/shared/textures/iconframe_interactive_txt2_hover.tga')
				end
			end, false, nil, 'canSelect', 'pickedByTeam')					
			
			registerWatchAndDo(hoverGlow, 'selection_Status', function(widget, trigger)
				if (triggerStatus.hoveringHero == newIndex) then
					widget:FadeIn(175)
				else
					widget:FadeOut(175)
				end
			end, false, nil, 'hoveringHero')

			registerWatchAndDo(recommended, 'selection_Status', function(widget, trigger)
				if (triggerStatus.recommendedHero == newIndex) then
					widget:FadeIn(175)
				else
					widget:FadeOut(175)
				end
			end, false, nil, 'selectedHero', 'recommendedHero')

			local infoTrigger	= GetTrigger('HeroSelectHeroList'..newIndex)
			infoTrigger:Trigger(true)
		else
			lastIndex = nil
			heroListbox:HideItemByValue(index)
		end

		button:SetCallback('onmouseover', function(widget)
			triggerStatus.hoveringHero = lastIndex or -1
			triggerStatus.stickyHoveringHero = lastIndex or -1
			triggerStatus:Trigger(false)
		end)

		button:SetCallback('onclick', function(widget)
			local heroInfo 					= GetTrigger('HeroSelectHeroList'..lastIndex)
			local trigger_heroSelectInfo 	= GetTrigger('HeroSelectInfo')
			if (trigger_heroSelectInfo.teamID ~= 1) and (trigger_heroSelectInfo.teamID ~= 2) then
				println('^r A spectator tried to pick a hero ')
				return
			end

			if (heroInfo.entityName) and (not Empty(heroInfo.entityName)) and ValidateEntity(heroInfo.entityName) then

				local function SpawnTheHero()
					println('Spawning index ' .. index .. ' | ' .. ' lastIndex ' .. lastIndex .. ' | entityName ' .. tostring(heroInfo.entityName))

					PlaySound(heroInfo['heroSelectAnnouncement'], 1, 3, 0)

					SelectHero(heroInfo.entityName)
					lastHero = lastIndex

					-- sound_heroSelect
					PlaySound('/ui/sounds/pets/sfx_select.wav')

					if (HeroSelectLocalPlayerInfo.heroEntityName == heroInfo.entityName) then
						-- set selected hero
						triggerStatus.selectedHero 			= lastIndex
						triggerStatus.stickyHoveringHero	= -1
						triggerStatus.hoveringHero			= -1

						HeroSelectLocalPlayerInfo:Trigger(true)
					end
				end

				SpawnTheHero()

			else
				SevereError('Spawn Hero Entity Invalid: ' .. tostring(heroInfo.entityName), 'main_reconnect_thatsucks', '', nil, nil, nil)
			end
		end)

	end
	
	for index = 0, 99, 1 do
		if (LuaTrigger.GetTrigger('HeroSelectHeroList'..index).isValid) then
			selection_captains_mode_hero_listbox:AddTemplateListItem('selection_hero_entry_item_template', tostring(index), 'id', index, 'prefix', 'captainsmode')
			selection_captains_mode_hero_listbox:HideItemByValue(index)
			HeroRegister(index, selection_captains_mode_hero_listbox, 'captainsmode')
		else
			break
		end
	end

end

local function InitPets()

	local selection_captains_mode_pet_selection 						= GetWidget('selection_captains_mode_pet_selection')
	local selection_captains_mode_pet_listbox 							= GetWidget('selection_captains_mode_pet_listbox')

	local selectionPetLeftAnimationThread
	
	local function showPets()
		local phase = LuaTrigger.GetTrigger('HeroSelectPhaseCountdown').phase
		local gamePhase = LuaTrigger.GetTrigger('GamePhase').gamePhase
		local heroSelected = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName ~= ""
		local petSelected = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').petEntityName ~= ""
		return gamePhase > 2 and phase == 'pick' and heroSelected and not petSelected
	end
	
	selection_captains_mode_pet_selection:RegisterWatchLua('HeroSelectPhaseCountdown', function(widget, trigger)
		widget:SetVisible(showPets())
	end, false, nil, 'phase')
	
	selection_captains_mode_pet_selection:RegisterWatchLua('HeroSelectLocalPlayerInfo', function(widget, trigger)
		widget:SetVisible(showPets())
	end, false, nil, 'heroEntityName', 'petEntityName')
	
	local function PetRegister(index, petListbox, prefix)
		local container	= GetWidget('selection_pet_entry_item_'..prefix..index)		
		local hoverGlow	= GetWidget('selection_pet_entry_item_'..prefix..index..'hoverGlow')		
		local icon		= GetWidget('selection_pet_entry_item_'..prefix..index..'Icon')
		local petName	= GetWidget('selection_pet_entry_item_'..prefix..index..'Name')
		local button	= GetWidget('selection_pet_entry_item_'..prefix..index..'Button')
		local hover		= GetWidget('selection_pet_entry_item_'..prefix..index..'Hover')
		local boost		= GetWidget('selection_pet_entry_item_'..prefix..index..'Boost')
		local frame		= GetWidget('selection_pet_entry_item_'..prefix..index..'_frame')

		local petTrigger = LuaTrigger.GetTrigger('HeroSelectFamiliarList'..index)

		if (not petTrigger) then
			-- println('^o Warning - Trigger Doesnt Exist: HeroSelectFamiliarList' .. index)
			return
		end		
		
		-- Container
		registerWatchAndDo(container, 'HeroSelectFamiliarList'..index, function (widget, trigger)
			if (trigger.entityName) and (not Empty(trigger.entityName)) and ValidateEntity(trigger.entityName) then
				petListbox:ShowItemByValue(index)
			else
				petListbox:HideItemByValue(index)
			end
		end, false, nil, 'entityName', 'selectable')

		-- Boost
		registerWatchAndDo(boost, 'HeroSelectFamiliarList'..index, function(widget, trigger)
			widget:SetVisible(trigger.boosted)
		end, false, nil, 'boosted')
		
		-- Icon
		registerWatchAndDo(icon, 'HeroSelectFamiliarList'..index, function(widget, trigger)
			local texturePath, failed = Pets.GetCurrentlySelectedSkinIcon(trigger.entityName)
			if (not failed) then
				widget:SetTexture(texturePath)
			elseif (trigger.entityName) and (not Empty(trigger.entityName)) and ValidateEntity(trigger.entityName) then
				widget:SetTexture(GetEntityIconPath(trigger.entityName))
			else
				widget:SetTexture(trigger.evolutionIcon0)
			end	
			if (trigger.selectable) then
				widget:SetRenderMode('normal')
			else
				widget:SetRenderMode('grayscale')
			end
		end, false, nil, 'entityName', 'level', 'selectable')

		-- Name
		registerWatchAndDo(petName, 'HeroSelectFamiliarList'..index, function(widget, trigger)
			if (trigger.entityName) and ValidateEntity(trigger.entityName) then
				if (trigger['customName']) and (not Empty(trigger['customName'])) then
					widget:SetText(trigger['customName'])
				else
					widget:SetText(GetEntityDisplayName(trigger['entityName']))
				end
			end
		end, false, nil, 'entityName')

		-- Frame
		registerWatchAndDo(frame, 'selection_Status', function(widget, trigger)
			if (trigger.hoveringPet == index) or (trigger.stickyHoveringPet == index) then
				if (petTrigger.selectable) then
					frame:SetBorderColor('1 1 0 1')
				else
					frame:SetBorderColor('1 .5 0 1')
				end
			else
				frame:SetBorderColor('#999999')
			end
		end, false, nil, 'hoveringPet', 'stickyHoveringPet')

		button:SetCallback('onmouseover', function(widget)
			local familiarInfo	= GetTrigger('HeroSelectFamiliarList'..index)
			if (familiarInfo.entityName) and (not Empty(familiarInfo.entityName)) and ValidateEntity(familiarInfo.entityName) then
				triggerStatus.stickyHoveringPet = index
				triggerStatus.hoveringPet = index
				triggerStatus:Trigger(false)
				hover:FadeIn(175)
				hoverGlow:FadeIn(175)
			end
		end)

		button:SetCallback('onmouseout', function(widget)
			triggerStatus.hoveringPet = -1
			triggerStatus:Trigger(false)
			hover:FadeOut(175)
			hoverGlow:FadeOut(175)
		end)

		button:SetCallback('onclick', function(widget)
			local familiarInfo	= GetTrigger('HeroSelectFamiliarList'..index)
			local triggerSection	= GetTrigger('selection_Status')

			if (familiarInfo.entityName) and (not Empty(familiarInfo.entityName)) and ValidateEntity(familiarInfo.entityName) then

				if (familiarInfo.selectable) then
					
					if (mainUI.savedRemotely) and (mainUI.savedRemotely.petBuilds) and (mainUI.savedRemotely.petBuilds[familiarInfo.entityName]) and (mainUI.savedRemotely.petBuilds[familiarInfo.entityName].default_petSkin) then
						if (familiarInfo['skinOwned'..mainUI.savedRemotely.petBuilds[familiarInfo.entityName].default_petSkinIndex]) then
							SpawnFamiliar(familiarInfo.entityName, mainUI.savedRemotely.petBuilds[familiarInfo.entityName].default_petSkin)
							triggerStatus.selectedPetSkin 		= mainUI.savedRemotely.petBuilds[familiarInfo.entityName].default_petSkin
							triggerStatus.selectedPetSkinIndex 	= mainUI.savedRemotely.petBuilds[familiarInfo.entityName].default_petSkinIndex
						else
							SpawnFamiliar(familiarInfo.entityName)
							triggerStatus.selectedPetSkin 			= 'default'
							triggerStatus.selectedPetSkinIndex 	= -1							
						end
					else
						SpawnFamiliar(familiarInfo.entityName)
						triggerStatus.selectedPetSkin 			= 'default'
						triggerStatus.selectedPetSkinIndex 	= -1					
					end					
					lastPet = index
					
					-- sound_petSelect
					PlaySound(familiarInfo['petSelectAnnouncement'])
					PlaySound('/ui/sounds/pets/sfx_select.wav')

					local heroTrigger				= GetTrigger('HeroSelectHeroList' .. triggerStatus.selectedHero)
					if (heroTrigger) then
						mainUI.savedRemotely.heroBuilds = mainUI.savedRemotely.heroBuilds or {}
						mainUI.savedRemotely.heroBuilds[heroTrigger.entityName] 				= mainUI.savedRemotely.heroBuilds[heroTrigger.entityName] or {}
						mainUI.savedRemotely.heroBuilds[heroTrigger.entityName].default_pet 	= mainUI.savedRemotely.heroBuilds[heroTrigger.entityName].default_pet or {}
						mainUI.savedRemotely.heroBuilds[heroTrigger.entityName].default_pet[1]  = familiarInfo.entityName
						mainUI.savedRemotely.heroBuilds[heroTrigger.entityName].default_pet[2]  = tonumber(index)
						SaveState()
					end

					if (HeroSelectLocalPlayerInfo.petEntityName == familiarInfo.entityName) then
						familiarInfo:Trigger(true)
						triggerStatus.selectedPet		= index
						triggerStatus.hoveringPet 		= -1
						triggerStatus.stickyHoveringPet = -1
						
						if (mainUI.savedRemotely) and (mainUI.savedRemotely.petBuilds) and (mainUI.savedRemotely.petBuilds[familiarInfo.entityName]) and (mainUI.savedRemotely.petBuilds[familiarInfo.entityName].default_petSkin) and (mainUI.savedRemotely.petBuilds[familiarInfo.entityName].default_petSkinIndex) then
							if (familiarInfo['skinOwned'..mainUI.savedRemotely.petBuilds[familiarInfo.entityName].default_petSkinIndex]) then
								triggerStatus.selectedPetSkin 		= mainUI.savedRemotely.petBuilds[familiarInfo.entityName].default_petSkin
								triggerStatus.selectedPetSkinOwned 	= mainUI.savedRemotely.petBuilds[familiarInfo.entityName].default_petSkin
								triggerStatus.selectedPetSkinIndex 	= mainUI.savedRemotely.petBuilds[familiarInfo.entityName].default_petSkinIndex
							else
								triggerStatus.selectedPetSkin 			= 'default'
								triggerStatus.selectedPetSkinOwned 	= 'default'
								triggerStatus.selectedPetSkinIndex 	= 1							
							end
						else
							triggerStatus.selectedPetSkin 			= 'default'
							triggerStatus.selectedPetSkinOwned 	= 'default'
							triggerStatus.selectedPetSkinIndex 	= 1
						end							
						
						triggerStatus:Trigger(true)
					else
						triggerStatus:Trigger(false)
					end

				end
			else
				SevereError('Spawn Pet Entity Invalid: ' .. tostring(familiarInfo.entityName), 'main_reconnect_thatsucks', '', nil, nil, nil)
			end

		end)

	end

	for index = 0, 99, 1 do
		local trigger = LuaTrigger.GetTrigger('HeroSelectFamiliarList'..index)
		if (trigger and trigger.entityName ~= "") then
			selection_captains_mode_pet_listbox:AddTemplateListItem('selection_pet_entry_item_template', tostring(index), 'id', index, 'prefix', 'captainsmode')
			PetRegister(index, selection_captains_mode_pet_listbox, 'captainsmode')
		else
			break
		end
	end

end

local currentLayout = -1 -- 0:normal 1:captaions

-- Note: RegisterRadialEaseStartingOverrides uses absolute positions
local function arrangePregameToCaptainsMode()
	triggerStatus.selectionSection				= mainUI.Selection.selectionSections.CAPTAINS_MODE
	triggerStatus:Trigger(false)
	
	if (currentLayout == 1) then return end
	currentLayout = 1
	
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_skin_container_parent')]	= {'450s', '255s'}
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_label_2')]				= {'460s', '500s'}
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_pet_skin_container')]		= {'450s', '526s'}
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_label_3')]				= {'462s', '614s'}
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_builds_combobox_parent')]	= {'437s', '637s'}
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_edit_build')]				= {'730s', '639s'}
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_undo_container')]			= {'0s', '-60s'}
	
	GetWidget('main_pregame_customization_ready_container'):SetVisible(false)
	GetWidget('main_pregame_side_fades'):SetVisible(false)
	GetWidget('main_pregame_hero_name_container'):SetX("-100%")
end

local function arrangePregameToNormalMode()
	if (currentLayout == 0) then return end
	currentLayout = 0
	
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_skin_container_parent')]	= {'20s', '238s'}
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_label_2')]				= {'13s', '492s'}
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_pet_skin_container')]		= {'20s', '520s'}
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_label_3')]				= {'13s', '620s'}
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_builds_combobox_parent')]	= {'-5s', '645s'}
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_edit_build')]				= {'288s', '647s'}
	RegisterRadialEaseStartingOverrides[GetWidget('main_pregame_customization_undo_container')]			= {'0s', '-60s'}
	
	GetWidget('main_pregame_customization_ready_container'):SetVisible(true)
	GetWidget('main_pregame_side_fades'):SetVisible(true)
	GetWidget('main_pregame_hero_name_container'):SetX(0)
end

local function InitCustomized()
	local selection_captains_mode_customize = GetWidget('selection_captains_mode_customize')
	local visible = false
	local function showCustomized()
		visible = true
		
		arrangePregameToCaptainsMode()
		mainUI.openCustomized(lastHero, lastPet)
		
		GetWidget('main_pregame_customization_container'):SetVisible(1)
		
		GetWidget('main_pregame_hero_name_container'):SetVisible(0)
		GetWidget('main_pregame_selection_container'):SetVisible(0)
		GetWidget('main_pregame_customization_container'):SetVisible(1)
		GetWidget('main_pregame_party_container'):SetVisible(0)
		GetWidget('main_pregame_timer_container'):SetVisible(0)
		GetWidget('main_pregame_dye_selection_container'):SetVisible(0)
		GetWidget('main_pregame_selection_container'):SetVisible(0)
		
		GetWidget('main_pregame_container'):SetVisible(true)
		
		
	end
	local function hideCustomized()
		visible = false
		GetWidget('main_pregame_container'):SetVisible(0)
	end
	
	local function showCustomize()
		local phase = LuaTrigger.GetTrigger('HeroSelectPhaseCountdown').phase
		local gamePhase = LuaTrigger.GetTrigger('GamePhase').gamePhase
		local heroSelected = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName ~= ""
		local petSelected = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').petEntityName ~= ""
		return gamePhase > 2 and phase == 'pick' and heroSelected and petSelected
	end
	
	local function checkVis()
		local show = showCustomize()
		if (show and not visible) then
			showCustomized()
		elseif (not show and visible) then
			hideCustomized()
		end
	end
	
	selection_captains_mode_customize:RegisterWatchLua('HeroSelectPhaseCountdown', function(widget, trigger)
			checkVis()
	end, false, nil, 'phase')
	
	selection_captains_mode_customize:RegisterWatchLua('HeroSelectLocalPlayerInfo', function(widget, trigger)
		checkVis()
	end, false, nil, 'heroEntityName', 'petEntityName')
	
end

local function InitBreadcrumbs()
	
	local selection_captains_mode_customize				= GetWidget('selection_captains_mode_customize')
	
	-- visiblility ==
	
	selection_captains_mode_customize:RegisterWatchLua('GamePhase', function(widget, trigger)
		widget:SetVisible(trigger.gamePhase > 2)
	end, false, nil)
	
end	

local function InitSpectators()
	for index=0,9,1 do
		
		local container		= GetWidget('lobby_entry_caps_'..index)
		local button		= GetWidget('lobby_entry_caps_'..index..'UserButton')
		local playerName	= GetWidget('lobby_entry_caps_'..index..'UserName')
		local darken		= GetWidget('lobby_entry_caps_'..index..'UserDarken')
		local dropTarget	= GetWidget('lobby_entry_caps_'..index..'DropTarget')
		
		local hasPlayer		= false
		
		button:SetCallback('onclick', function(widget)
			println('onclick')
			selectedIndex = nil
			interface:UICmd("Team(0)")
			ClearDrag()	
		end)
		
		button:RegisterWatchLua('LobbyStatus', function(widget, trigger)
			widget:SetCallback('onrightclick', function()
				println('onrightclick LobbySpectators ' .. index)
				local infoTrigger = LuaTrigger.GetTrigger('LobbySpectators'..index)
				if trigger.isHost and infoTrigger.identID and IsValidIdent(infoTrigger.identID) then
					lobbyRightClickOpen(infoTrigger.clientNum, index, 0, infoTrigger.identID)
				end
			end)	
		end)
		
		container:SetVisible(1)
		container:RegisterWatchLua('LobbyTeamInfo0', function(widget, trigger)
			widget:SetVisible(1)
		end, false, nil, 'maxPlayers')
		
		playerName:RegisterWatchLua('LobbySpectators'..index, function(widget, trigger)
			if (not Empty(trigger.playerName)) then
				hasPlayer = true
				selectedIndex = nil
			
				widget:SetText(trigger.playerName)
				widget:SetColor('1 1 1 1')
			else
				hasPlayer = false
			
				widget:SetText(Translate('temp_gamelobby_team3_slot', 'value', index))
				widget:SetColor('.4 .4 .4 1')
			end
		end)
		
		playerName:SetText(Translate('temp_gamelobby_team3_slot', 'value', index))
		playerName:SetColor('.4 .4 .4 1')
		
		button:SetCallback('onmouseover', function(widget)
			UpdateCursor(widget, true, { canLeftClick = true, canRightClick = true, canDrag = true })
		end)

		button:SetCallback('onmouseout', function(widget)
			UpdateCursor(widget, false, { canLeftClick = true, canRightClick = true, canDrag = true })
		end)		
		
		LuaTrigger.GetTrigger('LobbySpectators'..index):Trigger(true)
		
	end
end


local function InitPlayers()
	local function PlayerRegister(index)
		local parent								= GetWidget('selection_captains_mode_player_entry_parent_'..index)		
		local background							= GetWidget('selection_captains_mode_player_entry_base_'..index)	
		local swapHover								= GetWidget('selection_captains_mode_player_entry_swaphover_'..index)	
		local playerName							= GetWidget('selection_captains_mode_player_'..index)		
		local playerStatus							= GetWidget('selection_captains_mode_player_status_'..index)		
		local noHeroParent							= GetWidget('selection_captains_mode_player_nohero_'..index)		
		local noHeroLabel							= GetWidget('selection_captains_mode_player_status_nohero_'..index)		
		local heroIcon								= GetWidget('selection_captains_mode_player_hero_'..index)
		
		parent:SetCallback('onclick', function(widget)
			-- Fades out the hover widget
			swapHover:FadeOut(100)
			
			-- Sets the previous slot
			if (teamID) and (teamID == 1) then
				previousSlot = slot
			elseif (teamID) and (teamID == 2) then
				previousSlot = slot + 5
			end
			
			slot = index
			selectedIndex = index
			teamID = 0
			
			-- Sets the new slot team and texture (if we wanted to do team specific selection textures or anything, just uncomment this and the setting previous texture back to normal below)
			if (index >= 0) and (index <= 4) then
				teamID = 1
				--background:SetTexture('/ui/main/play/textures/player_entry_highlight_green.tga')
			elseif (index >= 5) and (index <= 9) then
				teamID = 2
				--background:SetTexture('/ui/main/play/textures/player_entry_highlight_red.tga')
				slot = slot - 5
			end
			
			-- Sets the previous slot texture back to normal
			-- if (previousSlot) then
				-- widget:GetWidget('selection_captains_mode_player_entry_base_'..previousSlot):SetTexture('/ui/main/play/textures/player_entry_base.tga')
			-- end
			
			PlaySound('/ui/sounds/ui_joinmatch_%.wav')
			widget:UICmd("Team(0)")
			widget:UICmd("Team("..teamID..", "..slot..")")
			-- JoinTeam(teamID, slot)
		end)
		
		parent:SetCallback('onmouseover', function(widget)
			swapHover:FadeIn(200)
		end)
		
		parent:SetCallback('onmouseout', function(widget)
			swapHover:FadeOut(100)
		end)
		
		parent:RegisterWatchLua('LobbyStatus', function(widget, trigger)
			widget:SetCallback('onrightclick', function()
				println('onrightclick HeroSelectPlayerInfo ' .. index)
				local infoTrigger = LuaTrigger.GetTrigger('HeroSelectPlayerInfo'..index)
				if trigger.isHost and infoTrigger.identID and IsValidIdent(infoTrigger.identID) then
					lobbyRightClickOpen(infoTrigger.clientNum, index, 0, infoTrigger.identID)
				end
			end)	
		end)		
		
		parent:RegisterWatchLua('GamePhase', function(widget, trigger)
	
			if (trigger.gamePhase == 3) then		 

				background:UnregisterWatchLua('HeroSelectPhaseCountdown')
				playerName:UnregisterWatchLua('HeroSelectPlayerInfo' .. index)
				playerStatus:UnregisterWatchLua('HeroSelectPhaseCountdown')
				noHeroParent:UnregisterWatchLua('HeroSelectPlayerInfo' .. index)
				heroIcon:UnregisterWatchLua('HeroSelectPlayerInfo' .. index)	
				playerName:UnregisterWatchLua('LobbyPlayerInfo' .. index)
				playerStatus:UnregisterWatchLua('LobbyPlayerInfo' .. index)			
			
				local playerTrigger 						= GetTrigger('HeroSelectPlayerInfo' .. index)
				
				if playerTrigger and (parent) then
				
					local isCaptain = ((index == 0) or (index == 5))

					background:RegisterWatchLua('HeroSelectPhaseCountdown', function(widget, trigger)
						local myTeam 		= GetTrigger('HeroSelectLocalPlayerInfo').teamID
						local team 			= GetTrigger('HeroSelectPlayerInfo' .. index).teamID
						local needControl 	= ( (trigger.phase == 'banning') or (trigger.phase == 'captainpick') )
						local hasControl 	= (team == trigger.Team)
						local isMyTeam  	= (GetTrigger('HeroSelectPlayerInfo' .. index).teamID == myTeam)
						
						if (isCaptain) and (hasControl) then
							if (isMyTeam) then
								widget:SetTexture('/ui/main/play/textures/player_entry_highlight_green.tga')
							else
								widget:SetTexture('/ui/main/play/textures/player_entry_highlight_red.tga')
							end
						else
							widget:SetTexture('/ui/main/play/textures/player_entry_base.tga')
						end
					end, false, nil, 'Team', 'phase')
					
					playerName:RegisterWatchLua('HeroSelectPlayerInfo' .. index, function(widget, trigger)
						if (trigger.playerName) and (not Empty(trigger.playerName)) then
							widget:SetText(trigger.playerName)
							widget:SetColor('1 1 1 1')
						else
							widget:SetText(Translate('captains_mode_empty_slot'))
							widget:SetColor('.3 .3 .3 1')
						end
					end, false, nil, 'playerName')
					
					playerStatus:RegisterWatchLua('HeroSelectPhaseCountdown', function(widget, trigger)
						local team 			= GetTrigger('HeroSelectPlayerInfo' .. index).teamID
						local needControl 	= ( (trigger.phase == 'banning') or (trigger.phase == 'captainpick') )
						local hasControl 	= (team == trigger.Team)
						
						if (isCaptain) and (needControl and hasControl) then
							if (trigger.phase == 'banning') then
								widget:SetText(Translate('captains_mode_banning'))
							elseif (trigger.phase == 'captainpick') then
								widget:SetText(Translate('captains_mode_drafting'))
							else
								widget:SetText(Translate('captains_mode_waiting'))
							end
						else
							if (trigger.phase == 'pick') and (playerTrigger.heroEntityName == '') then
								widget:SetText(Translate('captains_mode_picking'))
							else
								widget:SetText(Translate('captains_mode_waiting'))
							end
						end
					end)
					
					noHeroParent:RegisterWatchLua('HeroSelectPlayerInfo' .. index, function(widget, trigger)
						widget:SetVisible(Empty(trigger.heroEntityName))
					end, false, nil, 'heroEntityName')		
					
					heroIcon:RegisterWatchLua('HeroSelectPlayerInfo' .. index, function(widget, trigger)
						if not Empty(trigger.heroEntityName) then
							local texture = libGeneral.getCutoutOrRegularIcon(trigger.heroEntityName)		
							widget:SetTexture(texture or trigger.heroIconPath)
						end
						widget:SetVisible(not Empty(trigger.heroEntityName))
					end, false, nil, 'heroEntityName')
					
					playerTrigger:Trigger(true)
					
				else
					println('^r Captains mode could not register player')
					println("GetTrigger('HeroSelectPlayerInfo' .. index) " .. tostring(GetTrigger('HeroSelectPlayerInfo' .. index)))
					println("parent " .. tostring(parent))
				end
			
			elseif (trigger.gamePhase == 1) then
	
				background:UnregisterWatchLua('HeroSelectPhaseCountdown')
				playerName:UnregisterWatchLua('HeroSelectPlayerInfo' .. index)
				playerStatus:UnregisterWatchLua('HeroSelectPhaseCountdown')
				noHeroParent:UnregisterWatchLua('HeroSelectPlayerInfo' .. index)
				heroIcon:UnregisterWatchLua('HeroSelectPlayerInfo' .. index)	
				playerName:UnregisterWatchLua('LobbyPlayerInfo' .. index)
				playerStatus:UnregisterWatchLua('LobbyPlayerInfo' .. index)	
	
				local playerTrigger 						= GetTrigger('LobbyPlayerInfo' .. index)
				
				if playerTrigger and (parent) then
				
					local isCaptain = ((index == 0) or (index == 5))

					background:SetTexture('/ui/main/play/textures/player_entry_base.tga')
					
					playerName:RegisterWatchLua('LobbyPlayerInfo' .. index, function(widget, trigger)
						if (trigger.playerName) and (not Empty(trigger.playerName)) then
							widget:SetText(trigger.playerName)
							widget:SetColor('1 1 1 1')
						else
							widget:SetText(Translate('captains_mode_empty_slot'))
							widget:SetColor('.3 .3 .3 1')
						end
					end, false, nil, 'playerName')
					
					playerStatus:RegisterWatchLua('LobbyPlayerInfo' .. index, function(widget, trigger)
						if (trigger.ready) then
							widget:SetText(Translate('captains_mode_status_ready'))
						else
							widget:SetText(Translate('captains_mode_status_notready'))
						end
					end)
					
					noHeroParent:SetVisible(1)	
					
					heroIcon:SetVisible(0)
					
					playerTrigger:Trigger(true)
					
				else
					println('^r Captains mode could not register player')
					println("GetTrigger('LobbyPlayerInfo' .. index) " .. tostring(GetTrigger('LobbyPlayerInfo' .. index)))
					println("parent " .. tostring(parent))
				end	
			
			end
		end)
	end
	
	for index = 0, 9, 1 do
		PlayerRegister(index)
	end	
	
end

local function InitTeams()
	
	local function RegisterTeam(index, name)
		local captains_team_myteam_indicator_logo							= GetWidget('captains_team_'..index..'_myteam_indicator_logo')
		local captains_team_myteam_indicator_teamname						= GetWidget('captains_team_'..index..'_myteam_indicator_teamname')
		local captains_team_myteam_indicator_label						= GetWidget('captains_team_'..index..'_myteam_indicator_label')
		
		captains_team_myteam_indicator_logo:RegisterWatchLua('HeroSelectLocalPlayerInfo', function(widget, trigger)
			local myTeam = trigger.teamID == index
			if (myTeam) then
				widget:SetTexture('/ui/game/loading/textures/team_logo_' .. name .. '_green.tga')
			else
				widget:SetTexture('/ui/game/loading/textures/team_logo_' .. name .. '_red.tga')
			end
		end, false, nil, 'teamID')
		
		captains_team_myteam_indicator_teamname:RegisterWatchLua('HeroSelectLocalPlayerInfo', function(widget, trigger)
			local myTeam = trigger.teamID == index
			if (myTeam) then
				widget:SetColor('#01d823')
			else
				widget:SetColor('#d90000')
			end
		end, false, nil, 'teamID')

		captains_team_myteam_indicator_label:RegisterWatchLua('HeroSelectLocalPlayerInfo', function(widget, trigger)
			local myTeam = trigger.teamID == index
			if (myTeam) then
				widget:SetText(Translate('general_your_team'))
			else
				widget:SetText(Translate('general_team'))
			end
		end, false, nil, 'teamID')		
	end
	
	RegisterTeam(1, 'glory')
	RegisterTeam(2, 'valor')
	
end

local function InitCaptainsMode()

	if ((mainUI.featureMaintenance) and (mainUI.featureMaintenance['scrim'])) or ((mainUI.featureMaintenance) and (mainUI.featureMaintenance['captainsmode'])) then
		return
	end

	GetWidget('selection_captains_mode'):RegisterWatchLua('HeroSelectMode', function(widget, trigger)
		if (trigger.mode == 'captains') then
			arrangePregameToCaptainsMode()
		else
			arrangePregameToNormalMode()
		end
	end, false, nil, 'mode')
	
	local selectionCaptainsModeAnimationThread
	GetWidget('selection_captains_mode'):RegisterWatchLua('mainPanelStatus', function(widget, trigger)
		
		if (trigger.main == mainUI.MainValues.captainsMode) then
			if (not GetWidget('selection_captains_mode'):IsVisible()) then
				if (selectionCaptainsModeAnimationThread) then
					selectionCaptainsModeAnimationThread:kill()
					selectionCaptainsModeAnimationThread = nil
					if GetWidget('selection_captains_mode', nil, true) then
						GetWidget('selection_captains_mode'):SetPassiveChildren(0)
					end
				end

				selectionCaptainsModeAnimationThread = libThread.threadFunc(function()
					GetWidget('selection_captains_mode'):FadeIn(styles_mainSwapAnimationDuration)
					wait(styles_mainSwapAnimationDuration / 3)
					wait(styles_mainSwapAnimationDuration / 3)
					groupfcall('selection_animation_widgets_group_5_slide', function(_, widget) widget:DoEventN(7) end)
					wait(styles_mainSwapAnimationDuration)
					GetWidget('selection_captains_mode'):SetPassiveChildren(0)
					selectionCaptainsModeAnimationThread = nil
				end)
			end
		else
			if (GetWidget('selection_captains_mode'):IsVisible()) then
				if (selectionCaptainsModeAnimationThread) then
					selectionCaptainsModeAnimationThread:kill()
					selectionCaptainsModeAnimationThread = nil
					if GetWidget('selection_captains_mode', nil, true) then
						GetWidget('selection_captains_mode'):SetPassiveChildren(0)
					end
				end

				selectionCaptainsModeAnimationThread = libThread.threadFunc(function()
					GetWidget('selection_captains_mode'):SetPassiveChildren(1)
					groupfcall('selection_animation_widgets_group_5_slide', function(_, widget) widget:DoEventN(8) end)
					--wait(styles_mainSwapAnimationDuration)
					GetWidget('selection_captains_mode'):FadeOut(styles_mainSwapAnimationDuration)
					selectionCaptainsModeAnimationThread = nil
				end)
			end
		end
	end, false, nil, 'main')	
	
	-- Selection Section
	GetWidget('selection_captains_mode_selection'):RegisterWatchLua('HeroSelectPhaseCountdown', function(widget, trigger)
		if (trigger.phase ~= 'ready') then
			widget:SetVisible(1)
		else
			widget:SetVisible(0)
		end
	end, false, nil, 'phase')	
	
	GetWidget('selection_captains_mode_label_1'):RegisterWatchLua('HeroSelectPhaseCountdown', function(widget, trigger)
		widget:SetText(Translate('captains_mode_phase_'..trigger.phase))
	end, false, nil, 'phase')	
	
	GetWidget('selection_captains_mode_label_2'):RegisterWatchLua('HeroSelectPhaseCountdown', function(widget, trigger)
		local teamName = Translate('captains_mode_team_' .. trigger.Team)
		local countDown = ''
		if (trigger.timeRemaining) and (tonumber(trigger.timeRemaining)) and (tonumber(trigger.timeRemaining) > 0) and (tonumber(trigger.timeRemaining) <= 6000000) then
			countDown = math.floor(trigger.timeRemaining/1000) .. 's'
		end
		widget:SetText(Translate('captains_mode_phase_'..trigger.phase..'_desc', 'team', teamName, 'countdown', countDown))
	end)
	
	-- Hero Pick Section
	if (LuaTrigger.GetTrigger('HeroSelectHeroList0').isValid) then
		InitHeroes()
	else
		GetWidget('selection_captains_mode'):RegisterWatchLua('HeroSelectHeroList0', function(widget, trigger)
			if (trigger.isValid) then
				widget:UnregisterWatchLua('HeroSelectHeroList0')
				libThread.threadFunc(function()
					wait(1)
					InitHeroes()
				end)
			end
		end, false, nil, 'isValid')
	end
	
	-- Pet Pick Section
	if (LuaTrigger.GetTrigger('HeroSelectFamiliarList0').entityName ~= "") then
		InitPets()
	else
		GetWidget('selection_captains_mode'):RegisterWatchLua('HeroSelectFamiliarList0', function(widget, trigger)
			if (trigger.entityName ~= "") then
				widget:UnregisterWatchLua('HeroSelectFamiliarList0')
				libThread.threadFunc(function()
					wait(1)
					InitPets()
				end)
			end
		end, false, nil, 'entityName')
	end
	
	
	-- Customise
	InitCustomized()
	InitBreadcrumbs()
	
	-- Players
	InitPlayers()	
	
	-- Spectators
	InitSpectators()
	
	-- Teams
	InitTeams()
	
	-- Ready Up
	GetWidget('selection_captains_mode_ready_up'):RegisterWatchLua('HeroSelectPhaseCountdown', function(widget, trigger)
		if (trigger.phase == 'ready') then
			widget:SetVisible(1)
		else
			widget:SetVisible(0)
		end
	end, false, nil, 'phase')	
	
	local function ScanReadyPlayers()
		local ready = 0
		for i=0,9,1 do
			local trigger = GetTrigger('LobbyPlayerInfo' .. i)
			if (trigger.ready) then
				ready = ready + 1
			end
		end
		GetWidget('selection_captains_mode_ready_up_label_2'):SetText(Translate('captains_mode_x_x_are_ready', 'value', ready, 'value2', 10))	
	end
	
	for i=0,9,1 do
		GetWidget('selection_captains_mode_ready_up_label_2'):RegisterWatchLua('LobbyPlayerInfo'..i, function(widget, _)
			ScanReadyPlayers()
		end, false, nil, 'ready')	
	end
	ScanReadyPlayers()
	
	GetWidget('selection_captains_mode_ready_up_label_3'):RegisterWatchLua('HeroSelectLocalPlayerInfo', function(widget, trigger)
		if (trigger.isReady) then
			widget:SetText(Translate('captains_mode_curstate_ready'))
		else
			widget:SetText(Translate('captains_mode_curstate_unready'))
		end
	end)		

	GetWidget('selection_captains_mode_ready_up_btnLabel'):RegisterWatchLua('HeroSelectLocalPlayerInfo', function(widget, trigger)
		if (trigger.isReady) then
			widget:SetText(Translate('captains_mode_notready'))
		else
			widget:SetText(Translate('captains_mode_ready'))
		end
	end)		
	
	GetWidget('selection_captains_mode_ready_up_btn'):SetCallback('onclick', function(widget)
		if (GetTrigger('HeroSelectLocalPlayerInfo').isReady) then
			Unready()
		else
			Ready()
		end
	end)
	
	GetWidget('selection_captains_mode_leave_party'):SetCallback('onclick', function(widget)
		Party.LeaveParty()
		LeaveGameLobby()
	end)
	
	GetWidget('selection_captains_mode_spectators'):SetCallback('onclick', function(widget)
		GetWidget('selection_captains_mode_ready_up_spectatorssection'):SetVisible(1)
		GetWidget('selection_captains_mode_ready_up_explainsection'):SetVisible(0)
		GetWidget('selection_captains_mode_moreinfo'):SetVisible(1)
		GetWidget('selection_captains_mode_spectators'):SetVisible(0)
	end)	
	
	GetWidget('selection_captains_mode_moreinfo'):SetCallback('onclick', function(widget)
		GetWidget('selection_captains_mode_ready_up_spectatorssection'):SetVisible(0)
		GetWidget('selection_captains_mode_ready_up_explainsection'):SetVisible(1)
		GetWidget('selection_captains_mode_moreinfo'):SetVisible(0)
		GetWidget('selection_captains_mode_spectators'):SetVisible(1)
	end)		
	
	GetWidget('selection_captains_mode_spectators'):RegisterWatchLua('HeroSelectLocalPlayerInfo', function(widget, trigger)
		if (trigger.teamID == -1) then
			GetWidget('selection_captains_mode_ready_up_spectatorssection'):SetVisible(1)
			GetWidget('selection_captains_mode_ready_up_explainsection'):SetVisible(0)
			GetWidget('selection_captains_mode_moreinfo'):SetVisible(1)
			GetWidget('selection_captains_mode_spectators'):SetVisible(0)		
		end
	end)
	
	GetWidget('selection_captains_mode_spectators'):RegisterWatchLua('HeroSelectMode', function(widget, trigger)
		if (trigger.isCustomLobby) then
			GetWidget('selection_captains_mode_ready_up_spectatorssection'):SetVisible(0)
			GetWidget('selection_captains_mode_ready_up_explainsection'):SetVisible(1)
			GetWidget('selection_captains_mode_moreinfo'):SetVisible(0)
			GetWidget('selection_captains_mode_spectators'):SetVisible(1)	
		else
			GetWidget('selection_captains_mode_ready_up_spectatorssection'):SetVisible(0)
			GetWidget('selection_captains_mode_ready_up_explainsection'):SetVisible(1)
			GetWidget('selection_captains_mode_moreinfo'):SetVisible(0)
			GetWidget('selection_captains_mode_spectators'):SetVisible(0)		
		end
	end)	
	
	-- Debug
	
	function TestCaptainsMode()
		triggerStatus.selectionSection				= mainUI.Selection.selectionSections.CAPTAINS_MODE
		triggerStatus.selectionLeftContent 			= 0
		triggerStatus.selectionRightContent 		= -1
		triggerStatus.selectionComplete 			= false
		triggerStatus:Trigger(false)
		-- GetWidget('selection_captains_mode_ready_up'):SetVisible(0)
		-- GetWidget('selection_captains_mode_selection'):SetVisible(1)
		
		--GetWidget('selection_overall_breadcrumbs'):SetParent(GetWidget('selection_captains_mode_customize'))
		--GetWidget('selection_overall_breadcrumbs'):SetX('-30s')
		--GetWidget('selection_overall_breadcrumbs'):SetY('50s')		

	end

	if (GetCvarBool('ui_devCaptainsMode')) then
		libThread.threadFunc(function()
			wait(5000)
			TestCaptainsMode()
		end)
	end	
	
	if (GetCvarBool('ui_devCaptainsMode2')) then
		Cmd('WatchLuaTrigger HeroSelectMode')
		-- Cmd('WatchLuaTrigger HeroSelectPhaseCountdown')
		for i=0,9,1 do
			Cmd('WatchLuaTrigger HeroSelectPlayerInfo'..i)
		end
	end	
	
end


InitCaptainsMode()
