local function originsRegister(object)

	local select_mode_spe_splash						= object:GetWidget('select_mode_spe_splash')
	local selection_origins_logo_image					= object:GetWidget('select_mode_spe_logo_image')
	local selection_origins_region_title1				= object:GetWidget('select_mode_spe_region_title1')
	local selection_origins_region_title2				= object:GetWidget('select_mode_spe_region_title2')
	local selection_origins_primary_btn					= object:GetWidget('selection_origins_primary_btn')
	local selection_origins_secondary_btn				= object:GetWidget('selection_origins_secondary_btn')
	local selection_origins_primary_btn2				= object:GetWidget('selection_origins_primary_btn2')
	local select_mode_spe_splash_sound_wrapper_1		= object:GetWidget('select_mode_spe_splash_sound_wrapper_1')
	local select_mode_spe_splash_sound_wrapper_2		= object:GetWidget('select_mode_spe_splash_sound_wrapper_2')
	
	if (GetCvarString('host_language') == 'en') then
		selection_origins_logo_image:SetTexture('/ui/main/origins/textures/child_of_the_dawn_logo.tga')
		selection_origins_region_title1:SetVisible(0)
		selection_origins_region_title2:SetVisible(0)
	else
		selection_origins_logo_image:SetTexture('/ui/main/origins/textures/child_of_the_dawn_regions.tga')
		selection_origins_region_title1:SetVisible(1)
		selection_origins_region_title2:SetVisible(1)
	end

	selection_origins_primary_btn:SetCallback('onclick', function(widget)
		mainUI.AdaptiveTraining.RecordUtilisationInstanceByFeatureName('play_spe_1')
		PlaySound('/ui/sounds/sfx_ui_creategame_2.wav')
		ManagedSetLoadingInterface('loading_bastion_1')
		StartGame('tutorial', Translate('game_name_default_tutorial'), 'map:bastact1 nolobby:true', '-vid_d9')			
	end)
	
	selection_origins_primary_btn2:SetCallback('onclick', function(widget)
		GenericDialogAutoSize(
			'pre_play_option_1_SPE_1_btn', 'pre_play_option_1_SPE_1_info', '', 'general_play', 'general_cancel', 
				function()
					mainUI.AdaptiveTraining.RecordUtilisationInstanceByFeatureName('play_spe_1')
					PlaySound('/ui/sounds/sfx_ui_creategame_2.wav')
					ManagedSetLoadingInterface('loading_bastion_1')
					StartGame('tutorial', Translate('game_name_default_tutorial'), 'map:bastact1 nolobby:true', '-vid_d9')												
				end,
				function()
					PlaySound('/ui/sounds/sfx_ui_back.wav')
				end
		)	
	end)

	selection_origins_secondary_btn:SetCallback('onclick', function(widget)	
		select_mode_spe_splash:FadeOut(250)
	end)	
	
	select_mode_spe_splash:SetCallback('onshow', function()
		mainUI.AdaptiveTraining.RecordViewInstanceByFeatureName('play_spe_1')
		if GetCvarBool('sound_mute') or GetCvarBool('sound_muteMusic') or (GetCvarNumber('sound_masterVolume') < 0.3) then
			select_mode_spe_splash_sound_wrapper_1:FadeIn(125)
			select_mode_spe_splash_sound_wrapper_2:FadeIn(125)
			if (GetCvarBool('sound_muteMusic')) and GetWidget('select_mode_spe_splash_sound_label') then
				GetWidget('select_mode_spe_splash_sound_label'):SetText(Translate('origin_splash_goto_sound2'))
			elseif GetWidget('select_mode_spe_splash_sound_label') then
				GetWidget('select_mode_spe_splash_sound_label'):SetText(Translate('origin_splash_goto_sound'))
			end
		else
			select_mode_spe_splash_sound_wrapper_1:FadeOut(125)
			select_mode_spe_splash_sound_wrapper_2:FadeOut(125)
		end
	end)
	
	select_mode_spe_splash_sound_wrapper_2:SetCallback('onclick', function()
		local mainPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
		mainPanelStatus.main = 26
		mainPanelStatus:Trigger(false)
		libThread.threadFunc(function()
			wait(styles_mainSwapAnimationDuration)		
			Strife_Options:SelectSubCategory('2', 0)
		end)
	end)
	
end

originsRegister(object)