mainUI = mainUI or {}
mainUI.savedLocally 	= mainUI.savedLocally 	or {}
mainUI.savedRemotely 	= mainUI.savedRemotely 	or {}
Karma = Karma or {}

local function endgameKarmaRegister(object)
	
	local container		= object:GetWidget('endgame_karma')
	local leaveButton	= object:GetWidget('endgame_karma_leavegame')
	local leaveButton2	= object:GetWidget('endgame_karma_leavegame2')
	local leavegame_parent	= object:GetWidget('endgame_karma_leavegame_parent')
	local IwasInThisGame = false
	
	container:RegisterWatchLua('GameReinitialize', function(widget, trigger)
		widget:SetVisible(false)
	end)
	
	leaveButton2:SetCallback('onclick', function(widget)
		FinishMatch()
	end)
	
	leaveButton:SetCallback('onclick', function(widget)
		container:FadeOut(250)
	end)	
	
	function Karma.PopulateKarmaEndgame(object, matchStatsTable, submitTime, incMatchID, IwasInThisGame)
		println('Karma.PopulateKarmaEndgame')
		
		leavegame_parent:FadeIn(250)
		
		for playerIndex = 0,9,1 do
			local parent 							= GetWidget('endgame_karma_player_parent_' .. playerIndex, 'game', true)
			if (parent) then
				parent:SetVisible(0)
			end
		end
		
		local myTeam = LuaTrigger.GetTrigger('Team').team
		
		local function isAlly(slot)		
			slot = tonumber(slot)
			myTeam = tonumber(myTeam)
			if (not myTeam) or ((myTeam ~= 1) and (myTeam ~= 2)) then
				return false
			elseif (myTeam == 1) and ((slot) and ((slot) <= 4) and ((slot) >= 0)) then
				return true
			elseif (myTeam == 2) and ((slot) and ((slot) <= 9) and ((slot) >= 5)) then
				return true
			else
				return false
			end
		end
		
		for playerIndex, playerInfo in pairs(matchStatsTable.matchStats.stats) do
			if (playerInfo) then
			
				if playerInfo.ident_id == GetIdentID() then
					IwasInThisGame = true
				end					
			
				if (not playerInfo.slot) then
					SevereError('playerInfo Player Slot Missing #0: '.. tostring(playerInfo.slot), 'main_reconnect_thatsucks', '', nil, nil, false)
					return
				else
					-- println('^g playerInfo Player Slot Valid: '.. tostring(playerInfo.slot) .. ' | ' .. playerIndex, 'main_reconnect_thatsucks', '', nil, nil, false)
				end
				
				local slot 								= playerInfo.slot
				local parent 							= object:GetWidget('endgame_karma_player_parent_' .. slot)
				local hero_model 						= object:GetWidget('endgame_karma_player_heromodel_' .. slot)
				
				local identID							 = playerInfo.ident_id or 0
				playerInfo.isBot = (math.floor(tonumber(playerInfo.ident_id or 0)) == 0)
				
				if ((playerInfo.nickname) and (playerInfo.ident_id) and (not playerInfo.isBot) and (not IsMe(playerInfo.ident_id)) and (not IsOpponent(playerInfo.ident_id))) then
					AddRecentlyPlayedWith(playerInfo.nickname, playerInfo.uniqid, playerInfo.ident_id, Translate('general_strife_beta'))
				end
				
				if (playerInfo.matchmakingHeroStats) then
					if ((not IsMe(playerInfo.ident_id)) and (isAlly(slot) or IsAlly(playerInfo.ident_id))) and ((not playerInfo.isBot) or (GetCvarBool('ui_dev_endgame_karma'))) then
						if (playerInfo.matchmakingHeroStats.entityName) and ValidateEntity(playerInfo.matchmakingHeroStats.entityName) and (GetEntityIconPath(playerInfo.matchmakingHeroStats.entityName)) then
							parent:SetVisible(1)
							hero_model:SetVisible(1)
							hero_model:SetModel(GetPreviewModel(playerInfo.matchmakingHeroStats.entityName))
							hero_model:SetEffect(GetPreviewPassiveEffect(playerInfo.matchmakingHeroStats.entityName))
							hero_model:SetModelOrientation(GetPreviewAngles(playerInfo.matchmakingHeroStats.entityName))
							hero_model:SetModelPosition(GetPreviewPos(playerInfo.matchmakingHeroStats.entityName))
							hero_model:SetModelScale(GetPreviewScale(playerInfo.matchmakingHeroStats.entityName) * 1)
							hero_model:SetModelSkin(playerInfo.matchmakingHeroStats.entityName) -- rmm get get and dye info
							-- .gearset
							-- .dye
						else
							parent:SetVisible(0)
							hero_model:SetVisible(0)
							-- println('no stats ' .. playerInfo.slot)
						end	
					else
						parent:SetVisible(0)
						hero_model:SetVisible(0)
						-- println('not ally ' .. playerInfo.slot .. ' | ' .. playerInfo.ident_id)
					end
				elseif (not playerInfo.isBot) then
					SevereError('No matchmakingHeroStats in EndMatch (gamescoreboard) data', 'main_reconnect_thatsucks', '', nil, nil, false)
				end

				-- Karma
				local upvote_parent 						= object:GetWidget('endgame_karma_player_upvote_' .. slot)				
				local upvote_button 						= object:GetWidget('endgame_karma_player_upvote_' .. slot .. '_button')				
				local upvote_glow_darken 					= object:GetWidget('endgame_karma_player_upvote_' .. slot .. '_glow_darken')				
				local upvote_icon_darken 					= object:GetWidget('endgame_karma_player_upvote_' .. slot .. '_icon_darken')				

				local downvote_parent 						= object:GetWidget('endgame_karma_player_downvote_' .. slot)				
				local downvote_button 						= object:GetWidget('endgame_karma_player_downvote_' .. slot .. '_button')				
				local downvote_glow_darken 					= object:GetWidget('endgame_karma_player_downvote_' .. slot .. '_glow_darken')				
				local downvote_icon_darken 					= object:GetWidget('endgame_karma_player_downvote_' .. slot .. '_icon_darken')	
				
				local reason_parent 						= object:GetWidget('endgame_karma_player_downvote_' .. slot .. '_reason_parent')		
				
				local banner 								= object:GetWidget('endgame_karma_player_parent_' .. slot .. '_banner')						
				local name 									= object:GetWidget('endgame_karma_player_parent_' .. slot .. '_name')						
				local bg 									= object:GetWidget('endgame_karma_player_parent_' .. slot .. '_model_bg')						
				local border 								= object:GetWidget('endgame_karma_player_parent_' .. slot .. '_model_border')						
				local model_glow 							= object:GetWidget('endgame_karma_player_parent_' .. slot .. '_model_glow')						
				
				name:SetText(playerInfo.nickname or '?')
				
				local function UpdateKarma()		
					if (mainUI) and (mainUI.savedLocally.downVoteList) and (mainUI.savedLocally.downVoteList[identID]) then -- Downvoted
						upvote_parent:SetRenderMode('grayscale')	
						upvote_parent:SetColor('0.5 0.5 0.5 0.6')	
						upvote_glow_darken:SetVisible(1)
						upvote_icon_darken:SetVisible(1)
						
						--downvote_parent:SetRenderMode('normal')	
						--downvote_parent:SetColor('1 1 1 1')	
						downvote_glow_darken:SetVisible(0)
						downvote_icon_darken:SetVisible(0)							
						
						banner:SetTexture('/ui/game/karma/textures/banner_downvote_red.tga')
						border:SetTexture('/ui/game/karma/textures/golden_border_downvote.tga')
						bg:SetColor('1 0 0 1')
						model_glow:SetVisible(0)
						
						reason_parent:FadeIn(250)
						
						hero_model:SetAnim('downvote')
						
					elseif (mainUI) and (mainUI.savedLocally.upVoteList) and (mainUI.savedLocally.upVoteList[identID]) then  -- Upvoted
						upvote_parent:SetRenderMode('normal')	
						upvote_parent:SetColor('1 1 1 1')	
						upvote_glow_darken:SetVisible(0)
						upvote_icon_darken:SetVisible(0)	

						--downvote_parent:SetRenderMode('grayscale')	
						--downvote_parent:SetColor('0.5 0.5 0.5 0.6')	
						downvote_glow_darken:SetVisible(1)
						downvote_icon_darken:SetVisible(1)
						
						banner:SetTexture('/ui/game/karma/textures/banner_upvote.tga')
						border:SetTexture('/ui/game/karma/textures/golden_border_upvote.tga')
						bg:SetColor('0.24 0.94 0.15 1')
						model_glow:SetVisible(1)
						
						reason_parent:FadeOut(250)
						
						hero_model:SetAnim('upvote')
						
					else	-- Niether
						upvote_parent:SetRenderMode('normal')	
						upvote_parent:SetColor('1 1 1 1')	
						upvote_glow_darken:SetVisible(0)
						upvote_icon_darken:SetVisible(0)		

						--downvote_parent:SetRenderMode('normal')	
						--downvote_parent:SetColor('1 1 1 1')	
						downvote_glow_darken:SetVisible(0)
						downvote_icon_darken:SetVisible(0)
						
						banner:SetTexture('/ui/game/karma/textures/banner_normal.tga')
						border:SetTexture('/ui/game/karma/textures/golden_border.tga')
						bg:SetColor('0.24 0.94 0.15 1')
						model_glow:SetVisible(0)
						
						reason_parent:FadeOut(250)
						
						hero_model:SetAnim('idle')
						
					end								
				end
				UpdateKarma()
				
				if (not playerInfo.ident_id) or (playerInfo.ident_id == '') or (playerInfo.ident_id == GetIdentID()) then
					downvote_button:SetVisible(0)
				else
					downvote_button:SetVisible(1)
				end
				
				downvote_button:SetCallback('onclick', function(widget)
					if (mainUI) and (mainUI.savedLocally.downVoteList) and (mainUI.savedLocally.downVoteList[identID]) then
						mainUI.savedLocally.downVoteList[identID] = nil
						UpdateKarma()						
					else
						GenericDialogGame(
							'karma_downvote', 'karma_downvote_desc', '', 'general_ok', 'general_cancel', 
								function()
									mainUI = mainUI or {}
									mainUI.savedLocally.downVoteList = mainUI.savedLocally.downVoteList or {}
									mainUI.savedLocally.downVoteList[identID] = true
									mainUI.savedLocally.upVoteList = mainUI.savedLocally.upVoteList or {}
									mainUI.savedLocally.upVoteList[identID] = false		
									UpdateKarma()									
								end,
								function()
									PlaySound('/ui/sounds/sfx_ui_back.wav')
								end,
								nil, nil, nil, true
						)											
					end	
				end)				

				if (not playerInfo.ident_id) or (playerInfo.ident_id == '') or (playerInfo.ident_id == GetIdentID()) then
					upvote_button:SetVisible(0)
				else
					upvote_button:SetVisible(1)
				end
				
				upvote_button:SetCallback('onclick', function(widget)
					if (mainUI) and (mainUI.savedLocally.upVoteList) and (mainUI.savedLocally.upVoteList[identID]) then
						mainUI.savedLocally.upVoteList[identID] = nil
					else
						mainUI = mainUI or {}
						mainUI.savedLocally.upVoteList = mainUI.savedLocally.upVoteList or {}
						mainUI.savedLocally.upVoteList[identID] = true
						mainUI.savedLocally.downVoteList = mainUI.savedLocally.downVoteList or {}
						mainUI.savedLocally.downVoteList[identID] = false							
					end	
					UpdateKarma()
				end)					
				
				libButton2.initializeButton(upvote_button, 'endgame_karma_player_upvote_' .. slot .. '_button', 'standardButton2', {texture_up = '/ui/shared/frames/green_btn_up.tga', texture_over = '/ui/shared/frames/green_btn_over.tga'})
				
				local radioButton1 				= object:GetWidget('endgame_karma_disapproved_reason_' .. slot .. '_1')
				local radioButton2 				= object:GetWidget('endgame_karma_disapproved_reason_' .. slot .. '_2')
				local radioButton3 				= object:GetWidget('endgame_karma_disapproved_reason_' .. slot .. '_3')
				local radioButton4 				= object:GetWidget('endgame_karma_disapproved_reason_' .. slot .. '_4')
				local radioButton5 				= object:GetWidget('endgame_karma_disapproved_reason_' .. slot .. '_5')
				
				local radioButton1Check 		= object:GetWidget('endgame_karma_disapproved_reason_' .. slot .. '_1Check')
				local radioButton2Check 		= object:GetWidget('endgame_karma_disapproved_reason_' .. slot .. '_2Check')
				local radioButton3Check 		= object:GetWidget('endgame_karma_disapproved_reason_' .. slot .. '_3Check')
				local radioButton4Check 		= object:GetWidget('endgame_karma_disapproved_reason_' .. slot .. '_4Check')				
				local radioButton5Check 		= object:GetWidget('endgame_karma_disapproved_reason_' .. slot .. '_5Check')				
				
				local function ToggleReason(button, check, reason)
					radioButton1Check:SetVisible(0)
					radioButton2Check:SetVisible(0)
					radioButton3Check:SetVisible(0)
					radioButton4Check:SetVisible(0)
					radioButton5Check:SetVisible(0)
					if (check:IsVisibleSelf()) then
						check:SetVisible(0)
						mainUI.savedLocally.downVoteList[identID] = true
					else
						check:SetVisible(1)
						mainUI.savedLocally.downVoteList[identID] = reason		
					end
				end
				
				radioButton1:SetCallback('onclick', function(widget) ToggleReason(widget, radioButton1Check, 1) end)
				radioButton2:SetCallback('onclick', function(widget) ToggleReason(widget, radioButton2Check, 2) end)
				radioButton3:SetCallback('onclick', function(widget) ToggleReason(widget, radioButton3Check, 3) end)
				radioButton4:SetCallback('onclick', function(widget) ToggleReason(widget, radioButton4Check, 4) end)
				radioButton5:SetCallback('onclick', function(widget) ToggleReason(widget, radioButton5Check, 5) end)
				
			else
				print('no stats for index ' .. playerIndex)
			end
			
		end
		
		if (IwasInThisGame) then
			container:FadeIn(250)		
		end

	end

end

endgameKarmaRegister(object)