local OPTION_WRAP = false 				-- when scrolling the left menu with the wheel, should the options wrap end to end?

local SUBCATEGORY_SLIDE_TIME = 40 		-- how long to take to slide a sub category per slot it needs to slide (20 into the first, 40 into the second, etc.)
local SUBCATEGORY_EXTRA_SLIDE = "0.5h"	-- extra amount to slide over 0 to make it look like the sub category is sliding into the category text
local SUBCATEGORY_SPACING = "3.0h" 		-- the amount to slide each subcategory text
local SUBCATEGORY_SPACING_TOP = "0.0h" 		-- the amount to slide each subcategory text

local SUBCATEGORY_ARROW_OFFSET = "4.6h"	-- the distance from the top of the options panel scroll area to the sub indiactor arrow

local SCROLL_AMOUNT = "2.0h"			-- how much to scroll in one tick of the mouse wheel
local SCROLL_BOTTOM_PADDING = "1.0h" 	-- amount beyond the size of the category to allow scrolling below the panel
local SCROLL_ARROW_AMOUNT = "0.25h"		-- how much to scroll when hovering the arrows, higher means faster

local debug_output = false

----------------------------------------------------------

local _G = getfenv(0)
local ipairs, pairs, select, string, table, next, type, unpack, tinsert, tconcat, tremove, format, tostring, tonumber, tsort, ceil, floor, atan2, sin, cos, pi, sqrt, max, min, sub, find, gfind = _G.ipairs, _G.pairs, _G.select, _G.string, _G.table, _G.next, _G.type, _G.unpack, _G.table.insert, _G.table.concat, _G.table.remove, _G.string.format, _G.tostring, _G.tonumber, _G.table.sort, _G.math.ceil, _G.math.floor, _G.math.atan2, _G.math.sin, _G.math.cos, _G.math.pi, _G.math.sqrt, _G.math.max, _G.math.min, _G.string.sub, _G.string.find, _G.string.gfind
local interface, interfaceName = object, object:GetName()

mainOptions 				= 	mainOptions or {}
mainOptions.buttonBinder 	= 	mainOptions.buttonBinder or {}
local optionsWidgetsToUpdate = {}
local sliderTempValue = GetCvarNumber("ui_options_gfxslider", true) or 3

local optionsTrigger = LuaTrigger.GetTrigger('optionsTrigger') or LuaTrigger.CreateCustomTrigger('optionsTrigger',
	{
		{ name	= 'updateVisuals',				type	= 'bool' },
		{ name	= 'hasChanges',					type	= 'bool' },
		{ name	= 'isSynced',					type	= 'bool' },
	}
)


Strife_Options = {}
Strife_Options.selectedCategory = nil
Strife_Options.selectedSubCategory = nil
Strife_Options.scrollPosition = 0
Strife_Options.maxPossibleScroll = 100
Strife_Options.canScroll = true
Strife_Options.categoryInfo = nil
Strife_Options.sliding = false
Strife_Options.scrollState = 0
Strife_Options.staffOffset = nil
Strife_Options.lastLoginStatus = false
Strife_Options.scrollMultiplyer = 1.0
Strife_Options.targetCategory = nil
Strife_Options.targetSubCategory = nil
optionsTrigger.isSynced = GetCvarBool('cg_cloudSynced')

Strife_Options.graphicsSliderValues = {
	[0] = {	-- low
	
	},
	[1] = {	-- med
	
	},
	[2] = {	-- high
	
	},	
}

Strife_Options.newSettingsUndo = {}
Strife_Options.newSettings = {}
Strife_Options.currentSettings = {}
Strife_Options.keybindSettings = {}

local globalGetWidget = GetWidget
local function GetWidget(widgetName, fromInterface, hideErrors)
	return globalGetWidget(widgetName, fromInterface or 'options_new', hideErrors)
end

function getInterfaceFromGameOrMain(widgetName)
	local interface
	if LuaTrigger.GetTrigger('GamePhase').gamePhase >= 5 then
		interface	= UIManager.GetInterface('game')
	else
		interface	= UIManager.GetInterface('main')
	end
	
	return interface:GetWidget(widgetName)
end

function Strife_Options:PromptToKeepSettings(duration)
	if (duration > 0) then

		local thread = libThread.threadFunc(function(thread)	
			GenericDialogAutoSize(
				'options_keep_these_settings', Translate('options_keep_these_settings_desc_timed', 'value', math.ceil(duration/1000)), '', 'general_yes', 'general_no', 
				function()
					-- ok
					Strife_Options.ApplyChanges()
					duration = 0
					getInterfaceFromGameOrMain('generic_dialog_box'):SetVisible(0)
					getInterfaceFromGameOrMain('generic_dialog_box_wrapper'):SetVisible(0)								
				end,
				function()
					-- cancel
					Strife_Options.UndoChanges()
					duration = 0
					getInterfaceFromGameOrMain('generic_dialog_box'):SetVisible(0)
					getInterfaceFromGameOrMain('generic_dialog_box_wrapper'):SetVisible(0)								
				end
			)			
			while (duration > 0) do
				if (duration > 0) then
					getInterfaceFromGameOrMain('generic_dialog_label_1'):SetText(Translate('options_keep_these_settings_desc_timed', 'value', math.ceil(duration/1000)))
				end
				duration = duration - 1000
				wait(1000)
			end
			Strife_Options.UndoChanges()
			getInterfaceFromGameOrMain('generic_dialog_box'):SetVisible(0)
			getInterfaceFromGameOrMain('generic_dialog_box_wrapper'):SetVisible(0)			
		end)
	else
		GenericDialogAutoSize(
			'options_keep_these_settings', 'options_keep_these_settings_desc', '', 'general_yes', 'general_no', 
			function()
				-- ok
				Strife_Options.ApplyChanges()
				local triggerPanelStatus		= LuaTrigger.GetTrigger('mainPanelStatus')
				if (triggerPanelStatus.hasIdent) then
					triggerPanelStatus.main = 101
				else
					triggerPanelStatus.main = 0
				end
				triggerPanelStatus:Trigger(false)					
				
			end,
			function()
				-- cancel
				Strife_Options.UndoChanges()
				local triggerPanelStatus		= LuaTrigger.GetTrigger('mainPanelStatus')
				if (triggerPanelStatus.hasIdent) then
					triggerPanelStatus.main = 101
				else
					triggerPanelStatus.main = 0
				end
				triggerPanelStatus:Trigger(false)					
			end
		)
	end
end

local multiPartSettingTable = {
	['options_shadowQuality'] = {
		['default'] = '1',
		['1'] = { -- high
			{'vid_shadows', 		'true', 	'boolean'},
			{'vid_shadowmapSize', 	'2048', 	'string'},
			{'vid_shadowmapType', 	'1', 		'int'},
		},
		['2'] = {
			{'vid_shadows', 		'true', 	'boolean'},
			{'vid_shadowmapSize', 	'1024', 	'string'},
			{'vid_shadowmapType', 	'1', 		'int'},
		},
		['3'] = {
			{'vid_shadows', 		'true', 	'boolean'},
			{'vid_shadowmapSize', 	'512', 		'string'},
			{'vid_shadowmapType', 	'2', 		'int'},
		},
	},
	['options_soundQuality'] = {
		['default'] = '1',
		['1'] = {
			{'sound_mixrate', 			'44100', 	'int'},
			{'sound_maxVariations', 	'16', 		'int'},
			{'sound_resampler', 		'2', 		'int'},
		},
		['2'] = {
			{'sound_mixrate', 			'22050', 	'int'},
			{'sound_maxVariations', 	'8', 		'int'},
			{'sound_resampler', 		'1', 		'int'},
		},
		['3'] = {
			{'sound_mixrate', 			'11025', 	'int'},
			{'sound_maxVariations', 	'2', 		'int'},
			{'sound_resampler', 		'1', 		'int'},
		},			
	},	
	['options_window_mode'] = {
		['default'] = '1',
		['1'] = { -- full screen exclusive
			{'vid_fullscreen', 		'true', 	'boolean'},
			{'d9_exclusive', 	'true', 	'boolean'},
			{'d11_exclusive', 	'true', 	'boolean'},
			{'gl_exclusive', 	'true', 	'boolean'},
		},
		['2'] = { --  full screen (borderless)
			{'vid_fullscreen', 		'true', 	'boolean'},
			{'d9_exclusive', 	'false', 	'boolean'},
			{'d11_exclusive', 	'false', 	'boolean'},
			{'gl_exclusive', 	'false', 	'boolean'},
		},
		['3'] = { -- window
			{'vid_fullscreen', 		'false', 	'boolean'},
			{'d9_exclusive', 	'false', 	'boolean'},
			{'d11_exclusive', 	'false', 	'boolean'},
			{'gl_exclusive', 	'false', 	'boolean'},
		},			
	},
	['options_shaderQuality'] = {
		['default'] = '1',
		['1'] = { -- high
			{'vid_deferred', 				'true', 	'boolean'},
			{'vid_shaderLightingQuality', 	'0', 		'int'},
			{'options_shaderQuality', 		'1', 		'int'},
			{'vid_dynamicLights', 			'true', 	'boolean'},			
		},
		['2'] = { -- medium
			{'vid_deferred', 				'false', 	'boolean'},
			{'vid_shaderLightingQuality', 	'0', 	'int'},
			{'options_shaderQuality', 		'2', 		'int'},
			{'vid_dynamicLights', 			'false', 	'boolean'},			
		},
		['3'] = { -- low
			{'vid_deferred', 				'false', 	'boolean'},
			{'vid_shaderLightingQuality', 	'2', 		'int'},
			{'options_shaderQuality', 		'3', 		'int'},
			{'vid_dynamicLights', 			'false', 	'boolean'},			
		},
	},
	['options_vsync'] = {
		['default'] = true,
		[true] = {
			{'d9_presentInterval', 		'1', 	'int'},
			{'d11_presentInterval', 	'1', 	'int'},
			{'gl_swapInterval',		 	'1', 		'int'},
		},
		[false] = {
			{'d9_presentInterval', 		'0', 	'int'},
			{'d11_presentInterval', 	'0', 	'int'},
			{'gl_swapInterval',		 	'0', 		'int'},
		},
	},
	['options_framequeuing'] = {
		['default'] = true,
		[true] = {
			{'d9_flush', 		'1', 	'int'},
			{'d11_flush', 		'1', 	'int'},
		},
		[false] = {
			{'d9_flush', 		'0', 	'int'},
			{'d11_flush', 		'0', 	'int'},
		},
	},
}

local function SetMultiPartSetting(optionCvarName, optionCvarValue)

	if (multiPartSettingTable) and (multiPartSettingTable[optionCvarName]) and (multiPartSettingTable[optionCvarName][optionCvarValue]) then
		for i, v in pairs(multiPartSettingTable[optionCvarName][optionCvarValue]) do
			SetSave(v[1], v[2], v[3])
		end
	end
	
end

function Strife_Options.SoftApplyChanges()
	-- printr(Strife_Options.newSettings)
	if (Strife_Options.newSettings) then
		for i, v in pairs(Strife_Options.newSettings) do
			if (i) and (v.value ~= nil) then
				-- println('Setting ' .. tostring(i) .. ' to ' .. tostring(v.value) )
				if (v.type) and (v.type == 'lua') then
					mainUI.savedRemotely = mainUI.savedRemotely or {}
					mainUI.savedRemotely.luaOptions = mainUI.savedRemotely.luaOptions or {}				
					mainUI.savedRemotely.luaOptions[i] = v.value
					if (Strife_Options.currentSettings[i]) then
						Strife_Options.currentSettings[i].value = v.value	
					else
						-- println('^r options setting something that does not exist !' .. i)
					end					
				else				
					if Cvar.GetCvar(i) then
						Cvar.GetCvar(i):Set(tostring(v.value))
						Cvar.GetCvar(i):SetSave(true)
					end
					SetMultiPartSetting(i, v.value)
					if (Strife_Options.currentSettings[i]) then
						Strife_Options.currentSettings[i].value = v.value	
					else
						-- println('^r options setting something that does not exist !' .. i)
					end
				end
			end
		end
	end
end

function Strife_Options.ApplyChanges()
	-- printr(Strife_Options.newSettings)
	if (Strife_Options.newSettings) then
		for i, v in pairs(Strife_Options.newSettings) do
			if (i) and (v) and (type(v) == 'table') and (v.value) and (v.value ~= nil) then
				if (v.type) and (v.type == 'lua') then
					mainUI.savedRemotely = mainUI.savedRemotely or {}
					mainUI.savedRemotely.luaOptions = mainUI.savedRemotely.luaOptions or {}
					mainUI.savedRemotely.luaOptions[i] = v.value
					if (Strife_Options.currentSettings[i]) then
						Strife_Options.currentSettings[i].value = v.value	
					else
						-- println('^r options setting something that does not exist !' .. i)
					end					
				else				
					-- println('Setting ' .. tostring(i) .. ' to ' .. tostring(v.value) )
					if Cvar.GetCvar(i) then
						Cvar.GetCvar(i):Set(tostring(v.value))
						Cvar.GetCvar(i):SetSave(true)
					end
					SetMultiPartSetting(i, v.value)
					if (Strife_Options.currentSettings[i]) then
						Strife_Options.currentSettings[i].value = v.value	
					else
						-- println('^r options setting something that does not exist !' .. i)
					end
				end
			end
		end
		optionsTrigger.isSynced = false
		SetSave('cg_cloudSynced', 'false', 'bool')
	end
	Strife_Options.newSettings = {}
	Strife_Options.newSettingsUndo = {}
	Strife_Options.CanApply()
		
	optionsTrigger:Trigger(true)
	
	Set('ui_options_gfxslider', tostring(sliderTempValue), 'string')
	SetSave('ui_options_gfxslider', tostring(sliderTempValue), 'string')
	Strife_Options:PopulateSlider()
end

function Strife_Options.UndoChanges()
	if (Strife_Options.newSettingsUndo) then
		for i, v in pairs(Strife_Options.newSettingsUndo) do
			if (v.name) then
				if Cvar.GetCvar(v.name) then
					Cvar.GetCvar(v.name):Set(tostring(v.value))
				end
				-- SetMultiPartSetting(v.name, v.value)
			elseif (i) and (v.value ~= nil) then
				if (Cvar.GetCvar(i)) then
					Cvar.GetCvar(i):Set(tostring(v.value))
					-- SetMultiPartSetting(i, v.value)
				else
					-- println('^r missing cvar ' .. i)
				end
			end
		end
	end
	Strife_Options.newSettings = {}
	Strife_Options.newSettingsUndo = {}
	Strife_Options.CanApply()
	
	optionsTrigger.isSynced = false
	optionsTrigger:Trigger(true)
	
	sliderTempValue =  GetCvarNumber("ui_options_gfxslider", true) or 3
	Strife_Options:PopulateSlider()
end

function Strife_Options.LeaveOptionsScreen()
	if Strife_Options.CanApply() then
		Strife_Options:PromptToKeepSettings(0)
	else
		local triggerPanelStatus		= LuaTrigger.GetTrigger('mainPanelStatus')
		if LuaTrigger.GetTrigger('GamePhase').gamePhase >= 4 or triggerPanelStatus.main == 0 then -- either login, or end of match black screen.
			Cmd('HideWidget game_options')
		else
			if (triggerPanelStatus.hasIdent) then
				triggerPanelStatus.main = 101
			else
				triggerPanelStatus.main = 0
			end
			triggerPanelStatus:Trigger(false)
		end
	end
end

function Strife_Options:ApplySettings()
	local vidReset, soundRestart, setVideoMode, reloadShaders, reloadModels, reloadTextures, restartClient = false, false, false, false, false, false, false
	if (Strife_Options.newSettings) then
		for i, cvar in pairs(Strife_Options.newSettings) do
			
			-- println('opt ' .. (cvar.name or i) .. ' ' .. tostring(cvar.value))
			local name = cvar.name or i
			
			local vidResetTemp, soundRestartTemp, setVideoModeTemp, reloadShadersTemp, reloadModelsTemp, reloadTexturesTemp = OptionRequiresRestart(name) 

			-- println('option  ' .. name .. ' ' .. tostring(vidResetTemp) .. ' ' .. tostring(soundRestartTemp) .. ' ' .. tostring(setVideoModeTemp) .. ' ' .. tostring(reloadShadersTemp) .. ' ' .. tostring(reloadModelsTemp) .. ' ' .. tostring(reloadTexturesTemp))
			
			if (name) and (name == 'host_videoDriver') then -- RMM Hack until this is added to OptionRequiresRestart
				restartClient = true
			end
			
			if (vidResetTemp) 		then 	
				vidReset 		= true 	
			end
			if (soundRestartTemp) 	then 	
				soundRestart 	= true 	
			end
			if (setVideoModeTemp) 	then 	
				setVideoMode 	= true 	
			end
			if (reloadShadersTemp) 	then 	
				reloadShaders 	= true 	
			end
			if (reloadModelsTemp) 	then 	
				reloadModels 	= true 	
			end
			if (reloadTexturesTemp) 	then 	
				reloadTextures 	= true 	
			end
			
			if (multiPartSettingTable) and (multiPartSettingTable[name]) and (multiPartSettingTable[name][cvar.value]) then
				for i2, v in pairs(multiPartSettingTable[name][cvar.value]) do
					local subname = v[1]
					
					local vidResetTemp, soundRestartTemp, setVideoModeTemp, reloadShadersTemp, reloadModelsTemp, reloadTexturesTemp = OptionRequiresRestart(subname) 

					-- println('suboption  ' .. subname .. ' ' .. tostring(vidResetTemp) .. ' ' .. tostring(soundRestartTemp) .. ' ' .. tostring(setVideoModeTemp) .. ' ' .. tostring(reloadShadersTemp) .. ' ' .. tostring(reloadModelsTemp) .. ' ' .. tostring(reloadTexturesTemp))

					if (vidResetTemp) 		then 	
						vidReset 		= true 	
					end
					if (soundRestartTemp) 	then 	
						soundRestart 	= true 	
					end
					if (setVideoModeTemp) 	then 	
						setVideoMode 	= true 	
					end
					if (reloadShadersTemp) 	then 	
						reloadShaders 	= true 	
					end
					if (reloadModelsTemp) 	then 	
						reloadModels 	= true 	
					end
					if (reloadTexturesTemp) 	then 	
						reloadTextures 	= true 	
					end
				end
			end
		end
		Strife_Options.SoftApplyChanges()
	end
	local delay = 0
	if (vidReset) then
		Cmd('VidReset')
		delay = delay + 30000
	end
	if (soundRestart) then
		RestartSoundManager()
		delay = delay + 15000
	end
	if (setVideoMode) then
		Cmd('SetVideoMode')
		delay = delay + 30000
	end
	if (reloadShaders) then
		Cmd('ReloadShaders')
	end
	if (reloadModels) then
		Cmd('ReloadModels')
	end
	if (reloadTextures) then
		Cmd('ReloadTextures')
	end
	if (restartClient) then
		if (LuaTrigger.GetTrigger('GamePhase').gamePhase <= 4) then
			GenericDialogAutoSize(
				'options_confirm_client_restart', 'options_confirm_client_restart_desc', '', 'general_yes', 'general_no', 
				function()
					-- ok
					Strife_Options.ApplyChanges()
					libThread.threadFunc(function(thread)
						wait(500)
						Client.RestartAndRestoreSession()
					end)
				end,
				function()
					-- cancel
					Strife_Options.UndoChanges()				
				end
			)
		else
			GenericDialogAutoSize(
				'options_confirm_client_restart', 'options_confirm_client_restart_desc_ingame', '', 'general_yes', 'general_no', 
				function()
					-- ok
					Strife_Options.ApplyChanges()
					libThread.threadFunc(function(thread)
						wait(500)
						Client.RestartAndRestoreSession()
					end)
				end,
				function()
					-- cancel
					Strife_Options.UndoChanges()				
				end,
				nil, nil, nil, nil, true
			)		
		end
	else
		if (delay > 0) then
			Strife_Options:PromptToKeepSettings(delay)
		else
			Strife_Options.ApplyChanges()
		end
	end
end

function Strife_Options.CanApply()
	local count = 0
	if (Strife_Options.newSettings) then
		for i, v in pairs(Strife_Options.newSettings) do
			if (v ~= nil) then
				count = count + 1
			end
			break
		end
	end
	
	if GetWidget('options_std_btn_3', nil, true) then
		GetWidget('options_std_btn_3'):SetEnabled(count > 0)
		GetWidget('options_std_btn_4'):SetEnabled(count > 0)
		GetWidget('option_gfx_slider_apply'):SetEnabled(count > 0)
	end
	
	if (Strife_Options.newSettings) then
		Strife_Options.newSettingsUndo = table.copy(Strife_Options.newSettings)
	end

	return (count > 0)
end

function Strife_Options:RegisterDropdown(sourceWidget, sourceTargetName, cvarName, nameid, group, precision, numerictype, percent, round_var)
	local cvar = Cvar.GetCvar(cvarName)
	percent = AtoB(percent)
	round_var = AtoB(round_var)
	
	if (not cvar) then
		println('^r Failed to register RegisterDropdown for  ' .. cvarName)
		return
	end

	local parent 	= GetWidget(cvarName .. nameid .. '_parent')
	local combobox 	= GetWidget(cvarName .. nameid .. '_combobox')
	
	table.insert(optionsWidgetsToUpdate, combobox)
	
	local function Update()
		if (Strife_Options.newSettings[cvarName]) then
			if (Strife_Options.newSettings[cvarName].value) then
				-- println('^g Strife_Options.newSettings[cvarName].value ' .. cvarName .. ' | ' .. tostring(Strife_Options.newSettings[cvarName].value) )		
				combobox:SetSelectedItemByValue((Strife_Options.newSettings[cvarName].value))
			end
		else
			if (not Strife_Options.currentSettings[cvarName]) then
				-- println('^r Strife_Options.currentSettings missing for ' .. cvarName)
			else
				if (Strife_Options.currentSettings[cvarName].value) then
					-- println('^y Strife_Options.currentSettings[cvarName].value ' .. cvarName .. ' | ' .. tostring(Strife_Options.currentSettings[cvarName].value) )
					if (Strife_Options.currentSettings[cvarName].value) and (not Empty(Strife_Options.currentSettings[cvarName].value)) then
						combobox:SetSelectedItemByValue((Strife_Options.currentSettings[cvarName].value))	
					else
						combobox:SetSelectedItemByIndex(0)	
					end
				end
			end
		end
		Strife_Options.CanApply()
	end	
	
	parent:SetCallback('onshow', function(widget)
		Update()
	end)	

	combobox:RegisterWatchLua('optionsTrigger', function(widget, trigger)
		Update()
	end, false, nil, 'updateVisuals')	
	
	parent:RegisterWatchLua('optionsTrigger', function(widget, trigger)
		Update()
	end, false, nil, 'updateVisuals')	
	
	-- local oldOnselect = combobox:GetCallback('onselect')
	combobox:SetCallback('onselect', function(widget)

		local value = widget:GetValue()

		Strife_Options.newSettings[cvarName] = Strife_Options.newSettings[cvarName] or {}
		Strife_Options.newSettings[cvarName].name 	= cvarName
		Strife_Options.newSettings[cvarName].type 	= 'string'

		if (Strife_Options.newSettings[cvarName])then
			Strife_Options.newSettings[cvarName].value 	= value
			if (Strife_Options.newSettings[cvarName].value == Strife_Options.currentSettings[cvarName].value) then
				Strife_Options.newSettings[cvarName] = nil
			end
		else
			Strife_Options.newSettings[cvarName].value 	= Strife_Options.currentSettings[cvarName].value
		end	

		-- if (cvarName == 'sound_playbackDriver') and (Strife_Options.newSettings[cvarName]) and (Strife_Options.newSettings[cvarName].value ~= nil) then -- RMM Hack, kill
			-- SetSave('voice_playbackDriver', Strife_Options.newSettings[cvarName].value, 'string')
		-- end
		
		Update()
		
		-- if (oldOnselect) then
			-- oldOnselect()
		-- end
		
	end)

	parent:RefreshCallbacks()
	combobox:RefreshCallbacks()
	Update()
	
end

function Strife_Options:RegisterSlider(sourceWidget, cvarName, nameid, group, precision, numerictype, percent, round_var)
	local cvar = Cvar.GetCvar(cvarName)
	percent = AtoB(percent)
	round_var = AtoB(round_var)
	
	if (not cvar) then
		println('^r Failed to register RegisterSlider for  ' .. cvarName)
		return
	end

	local parent 	= GetWidget(cvarName .. nameid .. '_parent')
	local slider 	= GetWidget(cvarName .. nameid .. '_slider')
	local label 	= GetWidget(cvarName .. nameid .. '_value_label')
	
	local function Update()
		if (Strife_Options.newSettings[cvarName]) then
			if (Strife_Options.newSettings[cvarName].value) then
				-- println('^g Strife_Options.newSettings[cvarName].value ' .. cvarName .. ' | ' .. tostring(Strife_Options.newSettings[cvarName].value) )
				slider:SetValue(tonumber(Strife_Options.newSettings[cvarName].value))
				if (percent) then
					label:SetText(floor(tonumber(Strife_Options.newSettings[cvarName].value) * 100) .. '%')
				elseif (round_var) then
					label:SetText(floor(tonumber(Strife_Options.newSettings[cvarName].value)))
				elseif (precision) and (tonumber(precision)) then
					label:SetText(FtoA(tonumber(Strife_Options.newSettings[cvarName].value), tonumber(precision)))
				else
					label:SetText(Strife_Options.newSettings[cvarName].value)
				end
			end
		else
			if (not Strife_Options.currentSettings[cvarName]) then
				-- println('^r Strife_Options.currentSettings missing for ' .. cvarName)
			else
				if (Strife_Options.currentSettings[cvarName].value) then
					-- println('^y Strife_Options.currentSettings[cvarName].value ' .. cvarName .. ' | ' .. tostring(Strife_Options.currentSettings[cvarName].value) )
					slider:SetValue(tonumber(Strife_Options.currentSettings[cvarName].value))					
					if (percent) then
						label:SetText(floor(tonumber(Strife_Options.currentSettings[cvarName].value) * 100) .. '%')
					elseif (round_var) then
						label:SetText(floor(tonumber(Strife_Options.currentSettings[cvarName].value)))	
					elseif (precision) and (tonumber(precision)) then
						label:SetText(FtoA(tonumber(Strife_Options.currentSettings[cvarName].value), tonumber(precision)))
					else
						label:SetText(Strife_Options.currentSettings[cvarName].value)
					end
				end
			end
		end
		Strife_Options.CanApply()
	end	
	
	parent:SetCallback('onshow', function(widget)
		Update()
	end)	

	parent:RegisterWatchLua('optionsTrigger', function(widget, trigger)
		Update()
	end, false, nil, 'updateVisuals')	
	
	slider:SetCallback('onchange', function(widget)
		
		local value = widget:GetValue()

		Strife_Options.newSettings[cvarName] = Strife_Options.newSettings[cvarName] or {}
		Strife_Options.newSettings[cvarName].name 	= cvarName
		Strife_Options.newSettings[cvarName].type 	= 'string'

		if (Strife_Options.newSettings[cvarName])then
			Strife_Options.newSettings[cvarName].value 	= value
			local multiplier = percent and 100 or 1
			if (Strife_Options.newSettings[cvarName].value == Strife_Options.currentSettings[cvarName].value) or ((round_var) and tonumber(Strife_Options.newSettings[cvarName].value) and tonumber(Strife_Options.currentSettings[cvarName].value) and (math.floor(tonumber(Strife_Options.newSettings[cvarName].value*multiplier)) == math.floor(tonumber(Strife_Options.currentSettings[cvarName].value*multiplier)))) then
				Strife_Options.newSettings[cvarName] = nil
			end
		else
			Strife_Options.newSettings[cvarName].value 	= Strife_Options.currentSettings[cvarName].value
		end	

		Update()
	end)

	parent:RefreshCallbacks()
	slider:RefreshCallbacks()
	Update()
	
end

function Strife_Options:RegisterCheckboxLua(sourceWidget, tableName, fieldName, default)

	local parent 	= GetWidget(tableName .. fieldName  .. '_cbpanel')
	local button 	= GetWidget(tableName .. fieldName  .. '_cbname')
	local frame 	= GetWidget('options_checkbox_frame_' .. tableName .. fieldName )
	local check 	= GetWidget('options_checkbox_check_' .. tableName .. fieldName )
	local label 	= GetWidget('options_checkbox_titlelabel_' .. tableName .. fieldName )	

	local function Update()
		
		if (Strife_Options.newSettings[fieldName] ~= nil) then
			if (not button:IsEnabled()) then
				label:SetColor('.5 .5 .5 1')
				frame:SetColor('.5 .5 .5 1')
				frame:SetBorderColor('.5 .5 .5 1')
				frame:SetRenderMode('grayscale')
				check:SetVisible(0)
				button:SetButtonState(0)			
				button:SetEnabled(0)					
			elseif (Strife_Options.newSettings[fieldName].value) then
				frame:SetColor('#4ab4ff')
				frame:SetBorderColor('#4ab4ff')
				frame:SetRenderMode('normal')
				check:SetVisible(1)
				button:SetButtonState(1)
			else
				frame:SetColor('.8 .8 .8 1')
				frame:SetBorderColor('.8 .8 .8 1')
				frame:SetRenderMode('grayscale')
				check:SetVisible(0)
				button:SetButtonState(0)
			end
		else
			if (Strife_Options.currentSettings[fieldName] == nil) then
				-- println('^r Strife_Options.currentSettings missing for ' .. tableName .. fieldName)
			else
				if (not button:IsEnabled()) then
					label:SetColor('.5 .5 .5 1')
					frame:SetColor('.5 .5 .5 1')
					frame:SetBorderColor('.5 .5 .5 1')
					frame:SetRenderMode('grayscale')
					check:SetVisible(0)
					button:SetButtonState(0)			
					button:SetEnabled(0)						
				elseif (Strife_Options.currentSettings[fieldName].value) then
					frame:SetColor('#4ab4ff')
					frame:SetBorderColor('#4ab4ff')
					frame:SetRenderMode('normal')
					check:SetVisible(1)
					button:SetButtonState(1)
				else
					frame:SetColor('.8 .8 .8 1')
					frame:SetBorderColor('.8 .8 .8 1')
					frame:SetRenderMode('grayscale')
					check:SetVisible(0)
					button:SetButtonState(0)
				end
			end
		end
		Strife_Options.CanApply()
	end
	
	parent:SetCallback('onshow', function(widget)
		Update()
	end)	

	parent:RegisterWatchLua('optionsTrigger', function(widget, trigger)
		Update()
	end, false, nil, 'updateVisuals')
	
	button:SetCallback('onclick', function(widget)
		
		Strife_Options.newSettings 									= Strife_Options.newSettings or {}
		Strife_Options.newSettings[fieldName] 						= Strife_Options.newSettings[fieldName] or {}
		Strife_Options.newSettings[fieldName].name 					= cvarName

		Strife_Options.newSettings[fieldName].type 	= 'lua'
		if (Strife_Options.newSettings[fieldName]) and (Strife_Options.newSettings[fieldName].value ~= nil) then
			Strife_Options.newSettings[fieldName].value 	= not Strife_Options.newSettings[fieldName].value
			if (Strife_Options.newSettings[fieldName].value == Strife_Options.currentSettings[fieldName].value) then
				Strife_Options.newSettings[fieldName] = nil		
			end
		else
			Strife_Options.newSettings[fieldName].value 	= not Strife_Options.currentSettings[fieldName].value
		end
		
		Update()
		optionsTrigger:Trigger(true)
	end)
	
	parent:RefreshCallbacks()
	button:RefreshCallbacks()
	
	Strife_Options.currentSettings[fieldName] = Strife_Options.currentSettings[fieldName] or {}
	Strife_Options.currentSettings[fieldName].type 	= 'lua'
	
	mainUI.savedRemotely 						= mainUI.savedRemotely or {}
	mainUI.savedRemotely.luaOptions 			= mainUI.savedRemotely.luaOptions or {}
	if (mainUI.savedRemotely.luaOptions[fieldName] == nil) or (mainUI.savedRemotely.luaOptions[fieldName] and type(mainUI.savedRemotely.luaOptions[fieldName]) == 'table') then
		if (default) and (default == 'true') then
			Strife_Options.currentSettings[fieldName].value = true
			mainUI.savedRemotely.luaOptions[fieldName] = true
		else
			Strife_Options.currentSettings[fieldName].value = false
			mainUI.savedRemotely.luaOptions[fieldName] = false
		end
	else
		Strife_Options.currentSettings[fieldName].value = mainUI.savedRemotely.luaOptions[fieldName]
	end

	Update()

end

function Strife_Options:RegisterCheckbox(sourceWidget, cvarName, nameid, group, offValue, onValue, enablecondition)
	local cvar = Cvar.GetCvar(cvarName)
	local parent 	= GetWidget(cvarName .. nameid .. '_cbpanel')
	local button 	= GetWidget(cvarName .. nameid .. '_cbname')
	local frame 	= GetWidget('options_checkbox_frame_' .. cvarName .. nameid)
	local check 	= GetWidget('options_checkbox_check_' .. cvarName .. nameid)
	local label 	= GetWidget('options_checkbox_titlelabel_' .. cvarName .. nameid)	
	
	if (not cvar) then
		println('^r Failed to register checkbox for  ' .. cvarName)
		label:SetColor('.5 .5 .5 1')
		frame:SetColor('.5 .5 .5 1')
		frame:SetBorderColor('.5 .5 .5 1')
		frame:SetRenderMode('grayscale')
		check:SetVisible(0)
		button:SetButtonState(0)			
		button:SetEnabled(0)			
		return
	end

	local function Update()
		if (offValue) and (onValue) and (not Empty(offValue)) and (not Empty(onValue)) then
			if (Strife_Options.newSettings[cvarName]) then
				
				println('cvarName ' .. tostring(cvarName) )
				println('onValue ' .. tostring(onValue) .. ' | ' .. type(onValue) )
				println('offValue ' .. tostring(offValue) .. ' | ' .. type(offValue) )
				println('Strife_Options.newSettings[cvarName].value ' .. tostring(Strife_Options.newSettings[cvarName].value) .. ' | ' .. type(Strife_Options.newSettings[cvarName].value) )				

				if (not button:IsEnabled()) or ((enablecondition ~= nil) and (not (enablecondition))) then
					label:SetColor('.5 .5 .5 1')
					frame:SetColor('.5 .5 .5 1')
					frame:SetBorderColor('.5 .5 .5 1')
					frame:SetRenderMode('grayscale')
					check:SetVisible(0)
					button:SetButtonState(0)			
					button:SetEnabled(0)			
				elseif (Strife_Options.newSettings[cvarName].value) and (Strife_Options.newSettings[cvarName].value == onValue) then
					frame:SetColor('#4ab4ff')
					frame:SetBorderColor('#4ab4ff')
					frame:SetRenderMode('normal')
					check:SetVisible(1)
					button:SetButtonState(1)
				else
					frame:SetColor('.8 .8 .8 1')
					frame:SetBorderColor('.8 .8 .8 1')
					frame:SetRenderMode('grayscale')
					check:SetVisible(0)
					button:SetButtonState(0)
				end
			else
				--[[
				println('cvarName ' .. tostring(cvarName) )
				println('onValue ' .. tostring(onValue) .. ' | ' .. type(onValue) )
				println('offValue ' .. tostring(offValue) .. ' | ' .. type(offValue) )
				println('Strife_Options.currentSettings[cvarName].value ' .. tostring(Strife_Options.currentSettings[cvarName].value) .. ' | ' .. type(Strife_Options.currentSettings[cvarName].value) )	
				]]
				if (not Strife_Options.currentSettings[cvarName]) then
					-- println('^r Strife_Options.currentSettings missing for ' .. cvarName)
				else
					if (not button:IsEnabled()) or ((enablecondition ~= nil) and (not (enablecondition))) then
						label:SetColor('.5 .5 .5 1')
						frame:SetColor('.5 .5 .5 1')
						frame:SetBorderColor('.5 .5 .5 1')
						frame:SetRenderMode('grayscale')
						check:SetVisible(0)
						button:SetButtonState(0)			
						button:SetEnabled(0)						
					elseif (Strife_Options.currentSettings[cvarName].value) and (Strife_Options.currentSettings[cvarName].value == onValue) then
						frame:SetColor('#4ab4ff')
						frame:SetBorderColor('#4ab4ff')
						frame:SetRenderMode('normal')
						check:SetVisible(1)
						button:SetButtonState(1)
					else
						frame:SetColor('.8 .8 .8 1')
						frame:SetBorderColor('.8 .8 .8 1')
						frame:SetRenderMode('grayscale')
						check:SetVisible(0)
						button:SetButtonState(0)
					end
				end
			end	
		else
			if (Strife_Options.newSettings[cvarName]) then
				if (not button:IsEnabled()) or ((enablecondition ~= nil) and (not (enablecondition))) then
					label:SetColor('.5 .5 .5 1')
					frame:SetColor('.5 .5 .5 1')
					frame:SetBorderColor('.5 .5 .5 1')
					frame:SetRenderMode('grayscale')
					check:SetVisible(0)
					button:SetButtonState(0)			
					button:SetEnabled(0)					
				elseif (Strife_Options.newSettings[cvarName].value) then
					frame:SetColor('#4ab4ff')
					frame:SetBorderColor('#4ab4ff')
					frame:SetRenderMode('normal')
					check:SetVisible(1)
					button:SetButtonState(1)
				else
					frame:SetColor('.8 .8 .8 1')
					frame:SetBorderColor('.8 .8 .8 1')
					frame:SetRenderMode('grayscale')
					check:SetVisible(0)
					button:SetButtonState(0)
				end
			else
				if (not Strife_Options.currentSettings[cvarName]) then
					-- println('^r Strife_Options.currentSettings missing for ' .. cvarName)
				else
					if (not button:IsEnabled()) or ((enablecondition ~= nil) and (not (enablecondition))) then
						label:SetColor('.5 .5 .5 1')
						frame:SetColor('.5 .5 .5 1')
						frame:SetBorderColor('.5 .5 .5 1')
						frame:SetRenderMode('grayscale')
						check:SetVisible(0)
						button:SetButtonState(0)			
						button:SetEnabled(0)						
					elseif (Strife_Options.currentSettings[cvarName].value) then
						frame:SetColor('#4ab4ff')
						frame:SetBorderColor('#4ab4ff')
						frame:SetRenderMode('normal')
						check:SetVisible(1)
						button:SetButtonState(1)
					else
						frame:SetColor('.8 .8 .8 1')
						frame:SetBorderColor('.8 .8 .8 1')
						frame:SetRenderMode('grayscale')
						check:SetVisible(0)
						button:SetButtonState(0)
					end
				end
			end
		end
		Strife_Options.CanApply()
	end
	
	parent:SetCallback('onshow', function(widget)
		Update()
	end)	

	parent:RegisterWatchLua('optionsTrigger', function(widget, trigger)
		Update()
	end, false, nil, 'updateVisuals')
	
	button:SetCallback('onclick', function(widget)
		
		Strife_Options.newSettings = Strife_Options.newSettings or {}
		Strife_Options.newSettings[cvarName] = Strife_Options.newSettings[cvarName] or {}
		Strife_Options.newSettings[cvarName].name 	= cvarName

		if (onValue) and (offValue) and (not Empty(offValue)) and (not Empty(onValue)) then
			Strife_Options.newSettings[cvarName].type 	= 'int'
			if (Strife_Options.newSettings[cvarName]) and (Strife_Options.newSettings[cvarName].value ~= nil) then
				if (Strife_Options.newSettings[cvarName].value == onValue) then
					Strife_Options.newSettings[cvarName].value = offValue
				else
					Strife_Options.newSettings[cvarName].value = onValue
				end
				if (Strife_Options.newSettings[cvarName].value == Strife_Options.currentSettings[cvarName].value) then
					Strife_Options.newSettings[cvarName] = nil		
				end
			else
				if (Strife_Options.currentSettings[cvarName].value == onValue) then
					Strife_Options.newSettings[cvarName].value = offValue
				else
					Strife_Options.newSettings[cvarName].value = onValue
				end	
			end		
		else
			Strife_Options.newSettings[cvarName].type 	= 'bool'
			if (Strife_Options.newSettings[cvarName]) and (Strife_Options.newSettings[cvarName].value ~= nil) then
				Strife_Options.newSettings[cvarName].value 	= not Strife_Options.newSettings[cvarName].value
				if (Strife_Options.newSettings[cvarName].value == Strife_Options.currentSettings[cvarName].value) then
					Strife_Options.newSettings[cvarName] = nil		
				end
			else
				Strife_Options.newSettings[cvarName].value 	= not Strife_Options.currentSettings[cvarName].value
			end		
		end
		
		Update()
		optionsTrigger:Trigger(true)
	end)
	
	parent:RefreshCallbacks()
	button:RefreshCallbacks()
	
	Update()
	
end

function Strife_Options:RegisterColorPicker(sourceWidget, cvarName, default, nameid, group, defaultColor)
	local cvar = Cvar.GetCvar(cvarName)
	if not cvar then
		cvar = Cvar.CreateCvar(cvarName, 'string', default)
	end
	
	if (not cvar) then
		println('^r Failed to register colorPicker for ' .. cvarName)
		return
	end

	local parent 		= GetWidget(cvarName .. nameid .. '_cppanel')
	local button 		= GetWidget(cvarName .. nameid .. '_cppanel_button')
	local resetButton	= GetWidget(cvarName .. nameid .. '_cppanel_reset_button')
	local frame 		= GetWidget(cvarName .. nameid .. '_cppanel_preview')
	
	local function Update()
		if (Strife_Options.newSettings[cvarName]) then
			frame:SetColor(Strife_Options.newSettings[cvarName].value)
			frame:SetBorderColor(Strife_Options.newSettings[cvarName].value)
		else
			if (not Strife_Options.currentSettings[cvarName] or not Strife_Options.currentSettings[cvarName].value) then
				-- println('^r Strife_Options.currentSettings missing for ' .. cvarName)
			else
				frame:SetColor(Strife_Options.currentSettings[cvarName].value)
				frame:SetBorderColor(Strife_Options.currentSettings[cvarName].value)
			end
		end
		Strife_Options.CanApply()
	end
	
	parent:SetCallback('onshow', function(widget)
		Update()
	end)	

	parent:RegisterWatchLua('optionsTrigger', function(widget, trigger)
		Update()
	end, false, nil, 'updateVisuals')
	
	button:SetCallback('onclick', function(widget)
		GenericColorPicker(widget, Translate('options_choose_new_color'), Translate('general_ok'), Translate('general_cancel'), function(red, green, blue)
				-- accepted
				Strife_Options.newSettings = Strife_Options.newSettings or {}
				Strife_Options.newSettings[cvarName] = Strife_Options.newSettings[cvarName] or {}
				Strife_Options.newSettings[cvarName].name 	= cvarName
				Strife_Options.newSettings[cvarName].type 	= 'string'
				Strife_Options.newSettings[cvarName].value 	= red .." " .. green .. " " .. blue .. " 1", "string"
				frame:SetColor(red .." " .. green .. " " .. blue .. " 1")
				frame:SetBorderColor(red .." " .. green .. " " .. blue .. " 1")
				Strife_Options.CanApply()
			end,
			function()
				-- cancelled				
			end
			,false)
		Update()
	end)
	
	resetButton:SetCallback('onclick', function(widget)
		Strife_Options.newSettings = Strife_Options.newSettings or {}
		Strife_Options.newSettings[cvarName] = Strife_Options.newSettings[cvarName] or {}
		Strife_Options.newSettings[cvarName].name 	= cvarName
		Strife_Options.newSettings[cvarName].type 	= 'string'
		Strife_Options.newSettings[cvarName].value 	= defaultColor, "string"
		frame:SetColor(defaultColor)
		frame:SetBorderColor(defaultColor)
		Strife_Options.CanApply()
		Update()
	end)
	
	parent:RefreshCallbacks()
	button:RefreshCallbacks()
	
	Update()
	
end

function clamp(val, low, high)
	local retVal = val
	if low <= high then
		if low ~= nil and retVal < low then
			retVal = low
		end	
		
		if high ~= nil and retVal > high then
			retVal = high
		end
	end
	return retVal
end

local red = 1
local green = 1
local blue = 1
local contrastedRed=1
local contrastedGreen=1
local contrastedBlue=1
local contrast = 1
local firstPick = true
function GenericColorPicker(widget, header, btn1, btn2, onConfirm, onCancel, dontDimBG)
	
	if (UIManager.GetActiveInterface():GetName() == 'game') then
		--GenericDialogGame(header, label1, label2, btn1, btn2, onConfirm, onCancel, dontDimBG, showFlair, forceDisplay)
		--return
	elseif (UIManager.GetActiveInterface():GetName() == 'game_spectator') then
		--GenericDialogGameSpec(header, label1, label2, btn1, btn2, onConfirm, onCancel, dontDimBG, showFlair, forceDisplay)
		--return
	end	
	
	if (not interface:GetWidget('generic_color_dialog_bg')) then 
		println('^r^: GenericColorPicker Called Before Exists : ' .. tostring(header..' '..label1..' '..label2) )
		return 
	end
		
	if (dontDimBG) then
		interface:GetWidget('generic_color_dialog_bg'):SetColor('invisible')
	else
		interface:GetWidget('generic_color_dialog_bg'):SetColor('0 0 0 0.4')
	end
	
	interface:GetWidget('generic_color_dialog_header_1'):SetText(Translate(header) or '?')
	interface:GetWidget('generic_color_dialog_header_1'):SetFont('maindyn_22')

	local button1 = interface:GetWidget('generic_color_dialog_button_1')
	if (btn1) and (not Empty(btn1)) then
		groupfcall('generic_color_dialog_button_1_label_group', function(_, widget) widget:SetText(btn1) end)
		button1:SetVisible(1)
	else
		groupfcall('generic_color_dialog_button_1_label_group', function(_, widget) widget:SetText('') end)
		button1:SetVisible(0)
	end		

	local button2 = interface:GetWidget('generic_color_dialog_button_2')
	if (btn2) and (not Empty(btn2)) then
		groupfcall('generic_color_dialog_button_2_label_group', function(_, widget) widget:SetText(btn2) end)
		button2:SetVisible(1)
	else
		groupfcall('generic_color_dialog_button_2_label_group', function(_, widget) widget:SetText('') end)
		button2:SetVisible(0)
	end		

	local button 	= GetWidget('generic_color_dialog_color_wheel')
	local selection	= GetWidget('generic_color_dialog_selection')
	if (firstPick) then
		selection:SetX(selection:GetX() - (selection:GetAbsoluteX() - (button:GetAbsoluteX()+button:GetWidth()/2)) -  selection:GetWidth()/2)
		selection:SetY(selection:GetY() - (selection:GetAbsoluteY() - (button:GetAbsoluteY()+button:GetHeight()/2)) -  selection:GetHeight()/2)
		firstPick = false
	end
	local contrastSelection	= GetWidget('generic_color_dialog_contrast_selection')
	button:SetCallback('onclick', function(widget)
		local cursorPosX = Input.GetCursorPosX()-13
		local cursorPosY = Input.GetCursorPosY()-9
		local xOffset =   cursorPosX-(widget:GetAbsoluteX()+widget:GetWidth() /2)
		local yOffset = -(cursorPosY-(widget:GetAbsoluteY()+widget:GetHeight()/2)) -- y is flipped
		local angle = atan2(yOffset,xOffset)
		local distance = sqrt((xOffset*xOffset+yOffset*yOffset))
		
		selection:SetX(selection:GetX() + (cursorPosX-selection:GetAbsoluteX()))
		selection:SetY(selection:GetY() + (cursorPosY-selection:GetAbsoluteY()))
		
		local colorCorrection = 0
		red = cos(colorCorrection+angle)
		green = cos(colorCorrection+angle - (2*pi)/3)
		blue = cos(colorCorrection+angle - (4*pi)/3)
		
		local maximum = max(red, green, blue)
		local multiplier = 1/maximum
		red = red * multiplier
		green = green * multiplier
		blue = blue * multiplier
		
		--distance saturates.
		local saturation = 1-(1/(widget:GetWidth()*25))*(distance*distance) --spans about 25% of the image
		saturation = clamp(saturation, 0, 1)
		--println(saturation)
		red = red + (1-red)*saturation
		green = green + (1-green)*saturation
		blue = blue + (1-blue)*saturation
		
		red = clamp(red, 0, 1)
		green = clamp(green, 0, 1)
		blue = clamp(blue, 0, 1)
		
		contrastedRed = red * contrast
		contrastedGreen = green * contrast
		contrastedBlue = blue * contrast
		interface:GetWidget('generic_color_dialog_preview'):SetColor(contrastedRed.." "..contrastedGreen.." "..contrastedBlue.." 1")
		interface:GetWidget('generic_color_dialog_contrast'):SetColor(red.." "..green.." "..blue.." 1")
		--println(angle.. ", " .. xOffset .. ", " .. yOffset)
	end)
	
	interface:GetWidget('generic_color_dialog_contrast'):SetCallback('onclick', function(widget)
		contrast = 1-((Input.GetCursorPosY()) - widget:GetAbsoluteY())/widget:GetHeight()
		contrastSelection:SetY(contrastSelection:GetY() + ((Input.GetCursorPosY())-contrastSelection:GetAbsoluteY())-10)
		contrastedRed = red * contrast
		contrastedGreen = green * contrast
		contrastedBlue = blue * contrast
		interface:GetWidget('generic_color_dialog_preview'):SetColor(contrastedRed.." "..contrastedGreen.." "..contrastedBlue.." 1")
	end)

	interface:GetWidget('generic_color_dialog_button_1'):SetCallback('onclick', function()
		-- dialogGenericConfirm
		-- PlaySound('/soundpath/file.wav')
		interface:GetWidget('generic_color_dialog'):SetVisible(false)
		interface:GetWidget('generic_color_dialog_box_wrapper'):SetVisible(0)
		if (onConfirm) then
			onConfirm(contrastedRed, contrastedGreen, contrastedBlue)
		end
	end)
	
	interface:GetWidget('generic_color_dialog_button_2'):SetCallback('onclick', function()
		-- dialogGenericCancel
		-- PlaySound('/soundpath/file.wav')
		interface:GetWidget('generic_color_dialog'):SetVisible(false)
		interface:GetWidget('generic_color_dialog_box_wrapper'):SetVisible(0)
		if (onCancel) then
			onCancel()
		end		
	end)	

	interface:GetWidget('generic_color_dialog_box_closex'):SetCallback('onclick', function()
		-- dialogGenericCloseX
		-- PlaySound('/soundpath/file.wav')
		interface:GetWidget('generic_color_dialog'):SetVisible(false)
		interface:GetWidget('generic_color_dialog_box_wrapper'):SetVisible(0)
		if (onCancel) then
			onCancel()
		end		
	end)
	
	interface:GetWidget('generic_color_dialog_box_wrapper'):SetHeight(0)
	interface:GetWidget('generic_color_dialog_box_wrapper'):SetWidth(0)
	interface:GetWidget('generic_color_dialog_box_wrapper'):SetVisible(1)
	interface:GetWidget('generic_color_dialog_bg'):SetVisible(0)
	
	interface:GetWidget('generic_color_dialog_box_wrapper'):Scale(interface:GetWidget('generic_color_dialog_box_insert'):GetWidth(), interface:GetWidget('generic_color_dialog_box_insert'):GetHeight(), 125)
	
	interface:GetWidget('generic_color_dialog'):Sleep(125, function()	
		interface:GetWidget('generic_color_dialog'):FadeIn(125)
	end)	
	
	interface:GetWidget('generic_color_dialog_bg'):FadeIn(1500)
	
	FindChildrenClickCallbacks(interface:GetWidget('generic_color_dialog'))

end

function Strife_Options:RegisterKeybind(sourceWidget, templateName, instantiateTemplate, currentBinding, bindTable, action, param, num, isImpulse, label)
	Strife_Options.keybindSettings[bindTable .. action .. param .. num .. isImpulse] = {
		currentBinding 	= 	currentBinding,
		impulse 		= 	isImpulse or false,
		bindTable 		= 	bindTable or 'game',
		action 			= 	action or '',
		param 			= 	param or '',
		num 			= 	num or 1,
	}

	Strife_Options.optionsInfoTable = Strife_Options.optionsInfoTable or {}
	Strife_Options.optionsInfoTable[templateName .. label] = {	
		option_template = instantiateTemplate,
		category = '',
		subcategory = '',
		cvar = '',
		label = label,
		title = label,
		sub_text1 = label,
		sub_text2 = label,
		sub_text3 = label,
		tip_image = '',
		tip_name = '',
		tip_text1 = '',
		tip_text2 = '',
		tip_text3 = '',
		gradPos1 = '',
		gradPos2 = '',
		gradPos3 = '',
		gradPos4 = '',
		gradPos5 = '',
		gradName1 = '',
		gradName2 = '',
		gradName3 = '',
		gradName4 = '',
		gradName5 = '',
		maxvalue = '',
		data = '',
		onchange = '',
		onchangelua = '',
		onloadlua = '',
		oninstantiatelua = '',
		oneventlua = '',
		onselect = '',
		populate = '',
		maxlistheight = '',
		slidefunction = '',
		inverted = '',
		pair = '',
		enforce = '',
		enforce2 = '',
		enforce3 = '',
		enforce4 = '',
		precision = '',
		numerictype = '',
		percent = '',
		round_var = '',
		title_font = '',
		command = '',
		currentBinding = currentBinding,
		table = bindTable,
		action = action,
		param = param,
		impulse = isImpulse,
		onclick = ''
	}
	
end


function Strife_Options:RefreshKeybinds(keybindSettings)
	keybindSettings = keybindSettings or Strife_Options.keybindSettings
	if not keybindSettings then return end
	
	for o = 0, 1 do
		for i, v in pairs(keybindSettings) do
			if (tonumber(v.num) == o) then -- Order the hotkey registration, first then second. Without this, hotkeys overwrite each-other half the time.
				Strife_Options.keybindSettings = Strife_Options.keybindSettings or {}
				Strife_Options.keybindSettings[i] = Strife_Options.keybindSettings[i] or {}
				local bindCmd	= 'BindButton'
				if v.impulse=="true" then
					bindCmd = 'BindImpulse'
				end
				local keybindButton = GetKeybindButton(v.bindTable, v.action, v.param, v.num)
				if (keybindButton) then
					Cmd('Unbind ' .. v.bindTable .. ' ' .. keybindButton )
				end
				Cmd(bindCmd .. ' ' .. v.bindTable .. ' ' .. v.currentBinding .. ' ' .. v.action .. ' "' .. v.param .. '" ' .. v.num )
				Strife_Options.keybindSettings[i].currentBinding = v.currentBinding
			end
		end
	end
	interface:UICmd('Refresh()')
end

function Strife_Options:ResetKeybinds(dontLoad)
	Strife_Options.newSettings = {}
	local keybindSettings = Strife_Options.keybindSettings
	if not keybindSettings then return end
	for i, v in pairs(keybindSettings) do
		local bindCmd	= 'BindButton'
		if v.impulse=="true" then
			bindCmd = 'BindImpulse'
		end
		for o = 1, 2 do -- when you delete a button, sometimes another will take it's place, so do it twice.
			local keybindButton = GetKeybindButton(v.bindTable, v.action, v.param, v.num)
			if (keybindButton) then
				Cmd('Unbind ' .. v.bindTable .. ' ' .. keybindButton )
			end
		end
		v.currentBinding = "None "
	end
	if not dontLoad then
		Exec('default_binds.cfg')
	end
	Strife_Options.UpdateCurrentSettings()
	Strife_Options.ApplySettings()
	interface:UICmd('Refresh()')
	LuaTrigger.GetTrigger('optionsTrigger'):Trigger(true)
end

function Strife_Options:LoadOptionsFromWeb()
	local keybindSettings = mainUI.savedRemotely.optionsKeybinds
	for i,v in pairs(mainUI.savedRemotely.optionsMenu) do
		if string.find(i, 'vid_') or string.find(i, 'host_') or string.find(i, 'd9_') or string.find(i, 'd11_') or string.find(i, 'gl_') or string.find(i, 'options_window_mode') or string.find(i, 'options_framequeuing') or string.find(i, 'options_shaderQuality') or string.find(i, 'options_vsync') or string.find(i, 'options_shadowQuality') then
			mainUI.savedRemotely.optionsMenu[i] = nil
		end
	end
	Strife_Options.newSettings = mainUI.savedRemotely.optionsMenu
	if (mainUI.savedRemotely.luaOptions) then
		for i,v in pairs(mainUI.savedRemotely.luaOptions) do
			Strife_Options.newSettings[i] = v
		end
	end
	Strife_Options.ApplyChanges()
	Strife_Options:RefreshKeybinds(keybindSettings)
	interface:UICmd('Refresh()')
end
	
function GetOptionsToSaveToWeb()
	mainUI.savedRemotely.optionsMenu 		= 	mainUI.savedRemotely.optionsMenu or {}
	mainUI.savedRemotely.optionsKeybinds 	= 	--[[mainUI.savedRemotely.optionsKeybinds or]] {}
	
	for i, v in pairs(Strife_Options.keybindSettings) do
		mainUI.savedRemotely.optionsKeybinds[i] = v
	end
	
	for i, v in pairs(Strife_Options.currentSettings) do
		if (i ~= 'luaOptions') and  (not (string.find(i, 'vid_') or string.find(i, 'host_') or string.find(i, 'd9_') or string.find(i, 'd11_') or string.find(i, 'gl_') or string.find(i, 'options_window_mode') or string.find(i, 'options_framequeuing') or string.find(i, 'options_shaderQuality') or string.find(i, 'options_vsync') or string.find(i, 'options_shadowQuality'))) then
			mainUI.savedRemotely.optionsMenu[i] = v
		end
	end
	
end
			
function Strife_Options:OnShow()

	if (not Strife_Options.categoryInfo) then
		Strife_Options:BuildCategoryInfo()
	end

	if (Strife_Options.targetCategory and Strife_Options.targetSubCategory) then
		Strife_Options:SelectSubCategory(Strife_Options.targetCategory, Strife_Options.targetSubCategory)
		Strife_Options.targetCategory, Strife_Options.targetSubCategory = nil, nil
	elseif (not Strife_Options.selectedCategory) then
		Strife_Options:SelectSubCategory(1, 0)
	end
	
	optionsTrigger:Trigger(true)	
	
	Strife_Options.UpdateCurrentSettings()
	
end

function Strife_Options:CatTableUpdate(isLoggedIn)
	isLoggedIn = AtoB(isLoggedIn)
	if (Strife_Options.lastLoginStatus ~= isLoggedIn) then
		Strife_Options.lastLoginStatus = isLoggedIn

		if (GetWidget("game_options"):IsVisible()) then
			if (Strife_Options.staffOffset and Strife_Options.selectedCategory and Strife_Options.selectedCategory == Strife_Options.staffOffset) then
				Strife_Options:SelectSubCategory(Strife_Options.categoryInfo.numCategories-1, 0)
			end

			Strife_Options.categoryInfo = nil
			Strife_Options:BuildCategoryInfo()	-- update the categories
		else
			Strife_Options.categoryInfo = nil
		end
	end
end

function Strife_Options:SetStaffOffset(offset)
	Strife_Options.staffOffset = tonumber(offset)
end

function Strife_Options:BuildCategoryInfo()
	Strife_Options.categoryInfo = {}

	-- get the number of categories, and the height of each subcatehory list
	Strife_Options.categoryInfo.numCategories = 1
	while (GetWidget("options_cat"..Strife_Options.categoryInfo.numCategories, nil, true) and GetWidget("options_cat"..Strife_Options.categoryInfo.numCategories):IsVisible()) do
		Strife_Options.categoryInfo[Strife_Options.categoryInfo.numCategories] = {}
		Strife_Options.categoryInfo[Strife_Options.categoryInfo.numCategories].height = 0
		if (not GetWidget("options_main_category"..Strife_Options.categoryInfo.numCategories)) then
			if (debug_output) then Echo("^rWARNING: The left options menu has a 'options_cat"..Strife_Options.categoryInfo.numCategories.."' but a corresponding 'options_main_category"..Strife_Options.categoryInfo.numCategories.."' in the main panel was not found!") end
		end
		if (not GetWidget("options_submenu"..Strife_Options.categoryInfo.numCategories)) then
			if (debug_output) then Echo("^rWARNING: The left options menu has a 'options_cat"..Strife_Options.categoryInfo.numCategories.."' but a corresponding 'options_submenu"..Strife_Options.categoryInfo.numCategories.."' was not found!") end
		end
		Strife_Options.categoryInfo.numCategories = Strife_Options.categoryInfo.numCategories + 1
	end
	Strife_Options.categoryInfo.numCategories = Strife_Options.categoryInfo.numCategories - 1 -- get rid of the extra that failed

	-- get the number of subcategories in each, and the position of said sub
	for i=1, Strife_Options.categoryInfo.numCategories do
		Strife_Options.categoryInfo[i].numSubs = 1
		while (GetWidget("options_sub"..i..Strife_Options.categoryInfo[i].numSubs, nil, true)) do
			if (GetWidget("options_main_sub"..i..Strife_Options.categoryInfo[i].numSubs)) then
				Strife_Options.categoryInfo[i][Strife_Options.categoryInfo[i].numSubs] = GetWidget("options_main_sub"..i..Strife_Options.categoryInfo[i].numSubs):GetY()
				Strife_Options.categoryInfo[i].height = Strife_Options.categoryInfo[i].height + interface:GetHeightFromString(SUBCATEGORY_SPACING)
			else
				if (debug_output) then Echo("^rWARNING: The left options menu has a 'options_sub"..i..Strife_Options.categoryInfo[i].numSubs.."' for 'options_cat"..i.."' but a corresponding 'options_main_sub"..i..Strife_Options.categoryInfo[i].numSubs.."' was not found!") end
			end
			Strife_Options.categoryInfo[i].numSubs = Strife_Options.categoryInfo[i].numSubs + 1
		end
		Strife_Options.categoryInfo[i].numSubs = Strife_Options.categoryInfo[i].numSubs - 1 -- get rid of the extra that failedss
	end

	if (debug_output) then
		Echo("^gNum categories found: "..Strife_Options.categoryInfo.numCategories)
		Echo("^gSubs and positions in each:")
		for i=1, Strife_Options.categoryInfo.numCategories do
			Echo("\tCategory: "..i)
			for j=1, Strife_Options.categoryInfo[i].numSubs do
				Echo("\t\tSub: "..j.."-- Pos: "..(Strife_Options.categoryInfo[i][j] or "^rUnable to retrieve"))
			end
		end
	end
end

function Strife_Options:SelectCategory(categoryIndex)
	categoryIndex = tonumber(categoryIndex)
	if (categoryIndex < 0 or categoryIndex > Strife_Options.categoryInfo.numCategories) then
		return
	end

	if (Strife_Options.selectedCategory == categoryIndex) then return
	elseif (Strife_Options.sliding) then return end

	-- leave me here plz
	local oldCategory = Strife_Options.selectedCategory
	Strife_Options.selectedCategory = categoryIndex

	-- get the height of the catefory to set the max scroll
	----------------- old max scroll, based on height of all widgets -----------------
	-- Strife_Options.maxPossibleScroll = GetWidget("options_main_category"..categoryIndex):GetHeight() - GetWidget("options_main_holder"):GetHeight()
	-- Strife_Options.maxPossibleScroll = Strife_Options.maxPossibleScroll + interface:GetHeightFromString(SCROLL_BOTTOM_PADDING)

	-- if (Strife_Options.maxPossibleScroll < 0) then
	-- 	Strife_Options.canScroll = false
	-- else
	-- 	Strife_Options.canScroll = true
	-- end
	-----------------------------------------------------------------------------------
	-- new, based on position of last sub header OR the bottom of that sub section (if it's taller than the screen)
	Strife_Options:CalculateScroll(categoryIndex)
	-----------------------------------------------------------------------------------

	-- slide the main menu (right) into view and the old one out
	if (oldCategory) then
		GetWidget("options_main_category"..oldCategory):SetVisible(0)
	end

	GetWidget("options_main_category"..categoryIndex):SetY(0) 		-- reset any scrolling
	GetWidget("options_main_category"..categoryIndex):SetVisible(1)

	-- collpase the old category and expand the new
	Strife_Options.sliding = true
	local sleep = Strife_Options:CollapseCategory(oldCategory)
	local sleep2 = Strife_Options:ExpandCategory(categoryIndex)
	if sleep2 > sleep then sleep = sleep2 end
	GetWidget("options_main_holder"):Sleep(sleep, function(...)
		Strife_Options.sliding = false
	end)

	Strife_Options:HighlightCategory(categoryIndex, oldCategory)
	Strife_Options.scrollPosition = 0
	optionsTrigger:Trigger(true)
end

function Strife_Options:SelectSubCategory(categoryIndex, subIndex)
	categoryIndex, subIndex = tonumber(categoryIndex), tonumber(subIndex)

	Strife_Options:HighlightSubCategory(categoryIndex, subIndex)

	if (categoryIndex ~= Strife_Options.selectedCategory) then
		if (Strife_Options.sliding) then return end
		Strife_Options:SelectCategory(categoryIndex)
	end

	-- set the y to that of the category
	if (Strife_Options.canScroll) then
		local scrollDest = 0
		if (subIndex > 0) then
			scrollDest = -Strife_Options.categoryInfo[categoryIndex][subIndex]
			scrollDest = scrollDest + interface:GetHeightFromString(SUBCATEGORY_ARROW_OFFSET)
		end

		if (scrollDest >= 0) then
			scrollDest = 0
			
		elseif (scrollDest <= -Strife_Options.maxPossibleScroll) then
			scrollDest = -Strife_Options.maxPossibleScroll
			
		else

		end

		GetWidget("options_main_category"..categoryIndex):SetY(scrollDest)
		Strife_Options.scrollPosition = scrollDest
	end

	if (subIndex == 0) then subIndex = 1 end
	Strife_Options.selectedSubCategory = subIndex
	optionsTrigger:Trigger(true)
end

function Strife_Options:HighlightSubCategory(categoryIndex, subCategory)
	if (Strife_Options.selectedCategory and Strife_Options.selectedSubCategory) and GetWidget("options_sub"..Strife_Options.selectedCategory..Strife_Options.selectedSubCategory.."_lbl", nil, true) then
		GetWidget("options_sub"..Strife_Options.selectedCategory..Strife_Options.selectedSubCategory.."_lbl"):SetColor("#37b2d9")
	end

	if (subCategory == 0) then subCategory = 1 end
	Strife_Options.selectedSubCategory = subCategory
	if GetWidget("options_sub"..categoryIndex..subCategory.."_lbl", nil, true) then
		GetWidget("options_sub"..categoryIndex..subCategory.."_lbl"):SetColor("1 1 1 1")
	end
end

function Strife_Options:HighlightCategory(categoryIndex, oldCategory)
	if (oldCategory) then
		GetWidget("options_cat"..oldCategory.."_lbl"):SetColor(".7 .7 .7")
	end

	GetWidget("options_cat"..categoryIndex.."_lbl"):SetColor("1 1 1")
end

function Strife_Options:ScrollMain(direction, amount)
	if (not Strife_Options.canScroll) then return end

	if (not amount) then amount = interface:GetHeightFromString(SCROLL_AMOUNT) end

	-- determine destinations
	direction = tonumber(direction)
	local scrollDest = nil

	if (direction == 1) then -- up
		scrollDest = Strife_Options.scrollPosition + amount
	else 					 -- down
		scrollDest = Strife_Options.scrollPosition - amount
	end

	-- clamp, change the time to match the change in destination as well, so speed is always the same
	if (scrollDest) then
		if (scrollDest >= 0) then
			scrollDest = 0

		elseif (scrollDest <= -Strife_Options.maxPossibleScroll) then
			scrollDest = -Strife_Options.maxPossibleScroll

		elseif (Strife_Options.scrollPosition == 0) then -- scrolling from top
			
		elseif (Strife_Options.scrollPosition == -Strife_Options.maxPossibleScroll) then --scrolling from bottom
			
		end

		-- scroll
		GetWidget("options_main_category"..Strife_Options.selectedCategory):SetY(scrollDest)
		Strife_Options.scrollPosition = scrollDest

		local selectedOffset = nil
		-- check if we need to highlight a new sub
		for i=1,Strife_Options.categoryInfo[Strife_Options.selectedCategory].numSubs do
			if ((-(Strife_Options.scrollPosition - interface:GetHeightFromString(SUBCATEGORY_ARROW_OFFSET)) >= Strife_Options.categoryInfo[Strife_Options.selectedCategory][i])) then
				selectedOffset = i
			else
				break
			end
		end

		if (selectedOffset and selectedOffset ~= Strife_Options.selectedSubCategory) then
			Strife_Options:HighlightSubCategory(Strife_Options.selectedCategory, selectedOffset)
		end
	end
end

function Strife_Options:ScrollSub(direction)
	direction = tonumber(direction)
	local main, sub = nil, nil

	if (direction == 1) then -- up
		sub = Strife_Options.selectedSubCategory - 1
		if (sub <= 0) then
			main = Strife_Options.selectedCategory - 1
			if (main <= 0) then
				if (OPTION_WRAP) then
					main = Strife_Options.categoryInfo.numCategories
				else
					return
				end
			end

			sub = Strife_Options.categoryInfo[main or Strife_Options.selectedCategory].numSubs
		end
	else 					 -- down
		sub = Strife_Options.selectedSubCategory + 1
		if (sub > Strife_Options.categoryInfo[Strife_Options.selectedCategory].numSubs) then
			main = Strife_Options.selectedCategory + 1
			if (main > Strife_Options.categoryInfo.numCategories) then
				if (OPTION_WRAP) then
					main = 1
				else
					return
				end
			end

			sub = 1
		end
	end

	if (sub and main) then
		if (not Strife_Options.sliding) then
			Strife_Options:SelectSubCategory(main, sub)
		else
			return
		end
	elseif (sub) then
		Strife_Options:SelectSubCategory(Strife_Options.selectedCategory, sub)
	end
end

function Strife_Options:ExpandCategory(categoryIndex)
	categoryIndex = tonumber(categoryIndex)
	if (not categoryIndex) then return SUBCATEGORY_SLIDE_TIME+15 end

	local optionsWidget = GetWidget("options_submenu"..categoryIndex)
	if (optionsWidget) then
		local menuHeight = Strife_Options.categoryInfo[categoryIndex].height
		local expandTime = Strife_Options.categoryInfo[categoryIndex].numSubs * SUBCATEGORY_SLIDE_TIME

		-- expand the panel holding the sub options
		GetWidget("options_submenu"..categoryIndex):ScaleHeight(menuHeight, expandTime)
		
		-- slide the sub categories down
		for i=1, Strife_Options.categoryInfo[categoryIndex].numSubs do
			local subWidget = GetWidget("options_sub"..categoryIndex..i)
			subWidget:SetY(-interface:GetHeightFromString(SUBCATEGORY_EXTRA_SLIDE))
			subWidget:SetVisible(1)
			subWidget:SlideY(((interface:GetHeightFromString(SUBCATEGORY_SPACING) * (i-1)) + (interface:GetHeightFromString(SUBCATEGORY_SPACING_TOP))), SUBCATEGORY_SLIDE_TIME * i)
			libThread.threadFunc(function()
				wait(SUBCATEGORY_SLIDE_TIME * i)
				if (not subWidget:IsVisible()) then
					subWidget:SetVisible(1)
				end
			end)
		end
		GetWidget("options_submenu"..categoryIndex):SetVisible(1)

		return expandTime+15
	end
end

function Strife_Options:CollapseCategory(categoryIndex)
	categoryIndex = tonumber(categoryIndex)
	if (not categoryIndex) then return SUBCATEGORY_SLIDE_TIME+15 end

	local optionsWidget = GetWidget("options_submenu"..categoryIndex)
	if (optionsWidget) then
		local menuHeight = Strife_Options.categoryInfo[categoryIndex].height
		local collapseTime = SUBCATEGORY_SLIDE_TIME * Strife_Options.categoryInfo[categoryIndex].numSubs

		-- collapse the panel holding the sub options
		GetWidget("options_submenu"..categoryIndex):ScaleHeight(0, collapseTime)

		-- slide the sub categories up
		for i=1, Strife_Options.categoryInfo[categoryIndex].numSubs do
			local subWidget = GetWidget("options_sub"..categoryIndex..i)
			subWidget:SlideY(-interface:GetHeightFromString("2.5h"), SUBCATEGORY_SLIDE_TIME * i)
			subWidget:Sleep((SUBCATEGORY_SLIDE_TIME * i) - (SUBCATEGORY_SLIDE_TIME), function()
				subWidget:SetVisible(0)
			end)
		end
		
		GetWidget("options_cat"..categoryIndex):Sleep(collapseTime, function()
			GetWidget("options_submenu"..categoryIndex):SetVisible(0)
		end)

		return collapseTime+15
	end
end

function Strife_Options:HoverScroller()
	if (Strife_Options.canScroll) then
		if (Strife_Options.scrollPosition < 0) then
			
		end
		if (Strife_Options.scrollPosition > -Strife_Options.maxPossibleScroll) then
			
		end
	end
end

function Strife_Options:DoScroll()	
	if (Strife_Options.scrollState == 1) then
		Strife_Options:ScrollMain(0, interface:GetHeightFromString(SCROLL_ARROW_AMOUNT) * Strife_Options.scrollMultiplyer)
		if (Strife_Options.scrollPosition > -Strife_Options.maxPossibleScroll) then
			GetWidget('options_main_scroller'):Sleep(1, function() Strife_Options:DoScroll() end)
		end
	elseif (Strife_Options.scrollState == -1) then
		Strife_Options:ScrollMain(1, interface:GetHeightFromString(SCROLL_ARROW_AMOUNT) * Strife_Options.scrollMultiplyer)
		if (Strife_Options.scrollPosition < 0) then
			GetWidget('options_main_scroller'):Sleep(1, function() Strife_Options:DoScroll() end)
		end
	end
end

function Strife_Options:StartScrollDown()
	Strife_Options:HoverScroller()
	Strife_Options.scrollState = 1
	Strife_Options:DoScroll()	
end

function Strife_Options:StartScrollUp()
	Strife_Options:HoverScroller()
	Strife_Options.scrollState = -1
	Strife_Options:DoScroll()	
end

function Strife_Options:MultiplyScrollSpeed(amount)
	amount = tonumber(amount)
	if (Strife_Options.scrollMultiplyer == amount) then
		Strife_Options.scrollMultiplyer = 1.0
	else
		Strife_Options.scrollMultiplyer = amount
	end
end

function Strife_Options:StopScroll()
	Strife_Options.scrollState = 0
	Strife_Options.scrollMultiplyer = 1.0
end

function Strife_Options:ReferralPage()
	UIManager.GetInterface('webpanel'):HoNWebPanelF('LoadURLWithThrob', GetCvarString('ui_options_referral_url') .. '?lang=' .. GetCvarString('host_language') .. '&cookie=' .. (interface:UICmd("GetCookie()")), GetWidget("options_referral_browser"))
end

function Strife_Options:CalculateScroll(categoryIndex)
	if (not categoryIndex) then categoryIndex = Strife_Options.selectedCategory end

	Strife_Options.maxPossibleScroll = Strife_Options.categoryInfo[categoryIndex][Strife_Options.categoryInfo[categoryIndex].numSubs] - interface:GetHeightFromString(SUBCATEGORY_ARROW_OFFSET)
	local distanceToBottomFromLastHeader = GetWidget("options_main_category"..categoryIndex):GetHeight() - Strife_Options.maxPossibleScroll
	if (distanceToBottomFromLastHeader > GetWidget("options_main_holder"):GetHeight()) then -- distance is larger than a screen's height
		Strife_Options.maxPossibleScroll = Strife_Options.maxPossibleScroll + (distanceToBottomFromLastHeader - GetWidget("options_main_holder"):GetHeight())
		Strife_Options.maxPossibleScroll = Strife_Options.maxPossibleScroll + interface:GetHeightFromString(SCROLL_BOTTOM_PADDING)
	end

	if (Strife_Options.maxPossibleScroll <= 0) then
		Strife_Options.canScroll = false

	else
		Strife_Options.canScroll = true
	end

	if (Strife_Options.scrollPosition < -Strife_Options.maxPossibleScroll) then
		Strife_Options.scrollPosition = -Strife_Options.maxPossibleScroll
		GetWidget("options_main_category"..Strife_Options.selectedCategory):SetY(Strife_Options.scrollPosition)
		-- we will be at the bottom, hide the scrollers and stuff
	elseif (Strife_Options.scrollPosition ~= -Strife_Options.maxPossibleScroll) then -- not at bottom
	end
end

function Strife_Options:UpdateScrollAmounts()
	Strife_Options:CalculateScroll(Strife_Options.selectedCategory)
end

function Strife_Options:HoverCategory(over, cat, sub)
	cat, sub = tonumber(cat), tonumber(sub)

	if (over) then -- on mouse over
		if (cat ~= Strife_Options.selectedCategory) then
			GetWidget("options_cat"..cat.."_lbl"):SetColor(".9 .9 .9 1")
		end
		if (sub ~= 0 and sub ~= Strife_Options.selectedSubCategory) then
			GetWidget("options_sub"..cat..sub.."_lbl"):SetColor("#9ED6E8")
		end
	else  		   -- on mouse out
		if (cat ~= Strife_Options.selectedCategory) then
			GetWidget("options_cat"..cat.."_lbl"):SetColor(".8 .8 .8 1")
		end
		if (sub ~= 0 and sub ~= Strife_Options.selectedSubCategory) then
			GetWidget("options_sub"..cat..sub.."_lbl"):SetColor("#37b2d9")
		end
	end
end

function Strife_Options:ExpandCollapseFAQ(faqID)
	Strife_Options:ToggleWidgetVisibility(GetWidget("faq_q"..faqID))
end

function Strife_Options:ToggleWidgetVisibility(widget)
	local isVisible = not widget:IsVisible()
	widget:SetVisible(isVisible)

	local setY = nil
	if (isVisible) then -- check if we need to move down to fit the collapsed item
		local currentYBottom = GetWidget("options_main_holder"):GetAbsoluteY() + GetWidget("options_main_holder"):GetHeight()
		local widgetBottom = widget:GetAbsoluteY() + widget:GetHeight() + interface:GetHeightFromString("2.5h")
		-- 2.5 on the widget bottom so it won't appear in the bottom gradient

		if (widgetBottom > currentYBottom) then
			setY = Strife_Options.scrollPosition - (widgetBottom - currentYBottom)
		end
	end

	Strife_Options:UpdateScrollAmounts()

	-- set the y if we need to and do any hiding, showing, updating if we need to
	if (setY) then
		if (setY >= 0) then
			setY = 0

		elseif (setY <= -Strife_Options.maxPossibleScroll) then
			setY = -Strife_Options.maxPossibleScroll

		else

		end

		-- scroll
		GetWidget("options_main_category"..Strife_Options.selectedCategory):SetY(setY)
		Strife_Options.scrollPosition = setY

		local selectedOffset = nil
		-- check if we need to highlight a new sub
		for i=1,Strife_Options.categoryInfo[Strife_Options.selectedCategory].numSubs do
			if ((-(Strife_Options.scrollPosition - interface:GetHeightFromString(SUBCATEGORY_ARROW_OFFSET)) >= Strife_Options.categoryInfo[Strife_Options.selectedCategory][i])) then
				selectedOffset = i
			else
				break
			end
		end

		if (selectedOffset and selectedOffset ~= Strife_Options.selectedSubCategory) then
			Strife_Options:HighlightSubCategory(Strife_Options.selectedCategory, selectedOffset)
		end
	end
end

----- Graduated Slider functions ------

function Strife_Options:NoSlideFunction(value)
	value = tonumber(value)
	Echo("^rGraduated Slider not hooked up to a proper function (slidefunction=). ^gSlider Value: "..value)
end

function Strife_Options:GraphicsSlideFunction(value)
	
	if (sliderTempValue == tonumber(value)) then
		return
	end

	value = tonumber(value)
	sliderTempValue =  value
	
	Strife_Options.newSettings = Strife_Options.newSettings or {}

	Strife_Options.newSettings['px_enable']			= {}
	Strife_Options.newSettings['px_enableApex']			= {}
	Strife_Options.newSettings['d11_hair']			= {}
	Strife_Options.newSettings['vid_postEffects']			= {}
	-- Strife_Options.newSettings['vid_reflections']			= {}
	Strife_Options.newSettings['vid_sceneBuffer']		= {}
	Strife_Options.newSettings['vid_dynamicLights']		= {}
	-- Strife_Options.newSettings['options_foliage']			= {}
	-- Strife_Options.newSettings['options_rimlighting']		= {}
	-- Strife_Options.newSettings['options_skybox']			= {}
	
	Strife_Options.newSettings['model_quality']		= {}
	Strife_Options.newSettings['vid_textureDownsize']		= {}
	Strife_Options.newSettings['options_shaderQuality']		= {}
	Strife_Options.newSettings['options_shadowQuality']		= {}

	Strife_Options.newSettings['vid_dynamicLights']		= {}
	Strife_Options.newSettings['vid_antialiasing'] 		= {}
	Strife_Options.newSettings['vid_textureFiltering'] 		= {}	
	
	if (value == 1) then -- low

		Strife_Options.newSettings['px_enable'].value						=	false
		Strife_Options.newSettings['px_enableApex'].value					=	false
		Strife_Options.newSettings['d11_hair'].value						=	false		
		Strife_Options.newSettings['vid_postEffects'].value					=	false
		-- Strife_Options.newSettings['vid_reflections'].value				=	false
		Strife_Options.newSettings['vid_sceneBuffer'].value					=	false
		Strife_Options.newSettings['vid_dynamicLights'].value				=	false
		-- Strife_Options.newSettings['options_foliage'].value				=	false
		-- Strife_Options.newSettings['options_rimlighting'].value			=	false
		-- Strife_Options.newSettings['options_skybox'].value				=	false
		
		Strife_Options.newSettings['model_quality'].value		=	'low'
		Strife_Options.newSettings['vid_textureDownsize'].value			=	'1' -- 0
		Strife_Options.newSettings['options_shaderQuality'].value		=	'3' -- 0
		Strife_Options.newSettings['options_shadowQuality'].value		=	'3' -- 1

		Strife_Options.newSettings['vid_antialiasing'].value = '0,0,0' -- 8,0,0
		Strife_Options.newSettings['vid_textureFiltering'].value = '2' -- 8
	elseif (value == 2) then -- med
		Strife_Options.newSettings['px_enable'].value						=	false
		Strife_Options.newSettings['px_enableApex'].value					=	false
		Strife_Options.newSettings['d11_hair'].value						=	false		
		Strife_Options.newSettings['vid_postEffects'].value					=	false
		-- Strife_Options.newSettings['vid_reflections'].value				=	false
		Strife_Options.newSettings['vid_sceneBuffer'].value					=	true
		Strife_Options.newSettings['vid_dynamicLights'].value				=	false
		-- Strife_Options.newSettings['options_foliage'].value				=	false
		-- Strife_Options.newSettings['options_rimlighting'].value			=	false
		-- Strife_Options.newSettings['options_skybox'].value				=	false
		
		Strife_Options.newSettings['model_quality'].value		=	'med'
		Strife_Options.newSettings['vid_textureDownsize'].value			=	'1' -- 0
		Strife_Options.newSettings['options_shaderQuality'].value		=	'2' -- 0
		Strife_Options.newSettings['options_shadowQuality'].value		=	'2' -- 1

		Strife_Options.newSettings['vid_antialiasing'].value = '0,0,0' -- 8,0,0
		Strife_Options.newSettings['vid_textureFiltering'].value = '2' -- 8
	elseif (value == 3) then -- high
		Strife_Options.newSettings['px_enable'].value						=	false
		Strife_Options.newSettings['px_enableApex'].value					=	false
		Strife_Options.newSettings['d11_hair'].value						=	false		
		Strife_Options.newSettings['vid_postEffects'].value					=	true
		-- Strife_Options.newSettings['vid_reflections'].value				=	true
		Strife_Options.newSettings['vid_sceneBuffer'].value					=	true
		Strife_Options.newSettings['vid_dynamicLights'].value				=	true
		-- Strife_Options.newSettings['options_foliage'].value				=	true
		-- Strife_Options.newSettings['options_rimlighting'].value			=	true
		-- Strife_Options.newSettings['options_skybox'].value				=	true
		
		Strife_Options.newSettings['model_quality'].value		=	'high'
		Strife_Options.newSettings['vid_textureDownsize'].value			=	'0' -- 0
		Strife_Options.newSettings['options_shaderQuality'].value		=	'1' -- 0
		Strife_Options.newSettings['options_shadowQuality'].value		=	'1' -- 1

		if IsTxaaAvailable() then
			Strife_Options.newSettings['vid_antialiasing'].value = '4,0,1' -- Enable TXAA on high quality if available
		else
			Strife_Options.newSettings['vid_antialiasing'].value = '4,0,0' -- 8,0,0
		end
		Strife_Options.newSettings['vid_textureFiltering'].value = '4' -- 8
		
	elseif (value == 4) then -- ultra
		Strife_Options.newSettings['px_enable'].value						=	true
		Strife_Options.newSettings['px_enableApex'].value					=	false
		Strife_Options.newSettings['d11_hair'].value						=	true
		Strife_Options.newSettings['vid_postEffects'].value					=	true
		-- Strife_Options.newSettings['vid_reflections'].value				=	true
		Strife_Options.newSettings['vid_sceneBuffer'].value					=	true
		Strife_Options.newSettings['vid_dynamicLights'].value				=	true
		-- Strife_Options.newSettings['options_foliage'].value				=	true
		-- Strife_Options.newSettings['options_rimlighting'].value			=	true
		-- Strife_Options.newSettings['options_skybox'].value				=	true
		
		Strife_Options.newSettings['model_quality'].value		=	'high'
		Strife_Options.newSettings['vid_textureDownsize'].value			=	'0' -- 0
		Strife_Options.newSettings['options_shaderQuality'].value		=	'1' -- 0
		Strife_Options.newSettings['options_shadowQuality'].value		=	'1' -- 1

		if IsTxaaAvailable() then
			Strife_Options.newSettings['vid_antialiasing'].value = '4,0,1' -- Enable TXAA on high quality if available
		else
			Strife_Options.newSettings['vid_antialiasing'].value = '4,0,0' -- 8,0,0
		end
		Strife_Options.newSettings['vid_textureFiltering'].value = '4' -- 8		
		
	end
	
	for i, v in pairs(Strife_Options.newSettings) do
		if (Strife_Options.newSettings[i]) and (Strife_Options.newSettings[i].value ~= nil) and (Strife_Options.currentSettings[i]) and (Strife_Options.currentSettings[i].value ~= nil) then
			if (Strife_Options.newSettings[i].value == Strife_Options.currentSettings[i].value) then
				-- println('^c ' .. i .. '  Strife_Options.currentSettings[i].value  ' .. tostring(Strife_Options.currentSettings[i].value) .. ' | ' .. tostring(Strife_Options.newSettings[i].value) )
				Strife_Options.newSettings[i] = nil	
			else
				-- println('^y ' .. i .. '  Strife_Options.currentSettings[i].value  ' .. tostring(Strife_Options.currentSettings[i].value) .. ' | ' .. tostring(Strife_Options.newSettings[i].value) )
			end
		end
	end
	
	optionsTrigger:Trigger(true)
	Strife_Options:UpdatePreview(value)
	
	-- printr(Strife_Options.newSettings)
	
end

function Strife_Options:PopulateSlider()
	Strife_Options:UpdatePreview(sliderTempValue)
	GetWidget('optn_graphics_slider'):SetValue(sliderTempValue)
end

function Strife_Options:UpdatePreview(sliderPos)
	GetWidget("ui_options_preview_ultra"):SetVisible(sliderPos == 4)
	GetWidget("ui_options_preview_high"):SetVisible(sliderPos == 3)
	GetWidget("ui_options_preview_med"):SetVisible(sliderPos == 2)
	GetWidget("ui_options_preview_low"):SetVisible(sliderPos == 1)
end

function Strife_Options:SlideScroller(position)
	position = -tonumber(position)
	local diffToScroll = round(Strife_Options.scrollPosition - position)

	if (diffToScroll < 0) then
		Strife_Options:ScrollMain(1, math.abs(diffToScroll))
	elseif (diffToScroll > 0) then
		Strife_Options:ScrollMain(-1, math.abs(diffToScroll))
	end
end

---------------------------------------

function Strife_Options:UpdateLUAOptions()

	local groupTable = interface:GetGroup('options_options_lua')
	if (groupTable) and (#groupTable > 0) then
		for i, widget in pairs(groupTable) do 
			widget:DoEventN(9)
		end
	end

	local groupTable = interface:GetGroup('options_search_results')
	if (groupTable) and (#groupTable > 0) then
		for i, widget in pairs(groupTable) do 
			widget:DoEventN(9)
		end
	end	

end

--------------- Search WIP

Strife_Options.optionsInfoTable = nil

function Strife_Options:SearchButton()
	Strife_Options:SelectSubCategory(5, 1)
	-- focus the input box
	GetWidget("options_search_input"):SetFocus(true)
end

function Strife_Options.UpdateCurrentSettings()
	for cvar, _ in pairs(Strife_Options.currentSettings) do
		local cvarData = Cvar.GetCvar(cvar)
		
		if (not cvarData) then
			println('^r Failed to update cvar for  ' .. cvar)
		else
			-- println('^g Registered cvar ' .. cvar .. ' ' .. cvarData:GetString() )
			local value
			if (cvarData:GetString() == 'true') or (cvarData:GetString() == 'false') then 
				value = cvarData:GetBoolean()
			else
				value = cvarData:GetString()
			end
			Strife_Options.currentSettings[cvar].value = value
		end
	end
end
	
function Strife_Options.RegisterOption(option_template, category, subcategory, cvar, title, sub_text1, sub_text2, sub_text3, tip_image, tip_name, tip_text1, tip_text2, tip_text3, gradPos1, gradPos2, gradPos3, gradPos4, gradPos5, gradName1, gradName2, gradName3, gradName4, gradName5, slidefunction, maxvalue, data, onchange, onchangelua, onselect, populate, maxlistheight, pair, inverted, enforce, enforce2, enforce3, enforce4, precision, numerictype, percent, round_var, title_font, command, table, action, param, impulse, onclick, oneventlua, oninstantiatelua, minvalue, step)

	if (debug_output) then
		println('Register ' .. tostring(option_template) .. ' | ' .. tostring(title) .. ' | ' .. tostring(category) .. ' | ' .. tostring(subcategory) .. ' | ' .. tostring(cvar) .. ' | ' .. tostring(slidefunction) .. " | " )
	end
	
	Strife_Options.currentSettings[cvar] = Strife_Options.currentSettings[cvar] or {}
	
	local cvarData = Cvar.GetCvar(cvar)
	
	if (not cvarData) then
		println('^r Failed to register cvar for  ' .. cvar .. ' | ' .. option_template .. ' | ' .. title)
		return
	else
		-- println('^g Registered cvar ' .. cvar .. ' ' .. cvarData:GetString() )
	end
	
	local value
	if (cvarData:GetString() == 'true') or (cvarData:GetString() == 'false') then 
		value = cvarData:GetBoolean()
	else
		value = cvarData:GetString()
	end
	Strife_Options.currentSettings[cvar].value = value
	
	Strife_Options.optionsInfoTable = Strife_Options.optionsInfoTable or {}
	Strife_Options.optionsInfoTable[cvar] = {	
		option_template = option_template,
		category = category,
		subcategory = subcategory,
		cvar = cvar,
		title = title,
		sub_text1 = sub_text1,
		sub_text2 = sub_text2,
		sub_text3 = sub_text3,
		tip_image = tip_image,
		tip_name = tip_name,
		tip_text1 = tip_text1,
		tip_text2 = tip_text2,
		tip_text3 = tip_text3,
		gradPos1 = gradPos1,
		gradPos2 = gradPos2,
		gradPos3 = gradPos3,
		gradPos4 = gradPos4,
		gradPos5 = gradPos5,
		gradName1 = gradName1,
		gradName2 = gradName2,
		gradName3 = gradName3,
		gradName4 = gradName4,
		gradName5 = gradName5,
		maxvalue = maxvalue,
		minvalue = minvalue or '',
		data = data,
		onchange = onchange,
		onchangelua = onchangelua,
		onloadlua = oninstantiatelua,
		oninstantiatelua = oninstantiatelua,
		oneventlua = oneventlua,
		onselect = onselect,
		populate = populate,
		maxlistheight = maxlistheight,
		slidefunction = slidefunction,
		inverted = inverted,
		pair = pair,
		enforce = enforce,
		enforce2 = enforce2,
		enforce3 = enforce3,
		enforce4 = enforce4,
		precision = precision,
		numerictype = numerictype,
		percent = percent,
		round_var = round_var,
		title_font = title_font,
		command = command,
		table = table,
		action = action,
		param = param,
		impulse = impulse,
		step = step or '',
		onclick = onclick
	}
	
end

local function DisplaySearchResults(matchingOptionTable) 
	
	local function EscapeString(input)
		return string.gsub(input, "'", "\'")
	end
	local resultCount = 0
	
	for _, optionTable in pairs(matchingOptionTable) do
	
		resultCount = resultCount + 1
		if (resultCount > 10) then break end

		local newWidgets = GetWidget('options_search_insertion_point'):InstantiateAndReturn(optionTable.option_template,
			'nameid', '_search',
			'width', '100%',
			'group', 'options_search_results',
			'category', optionTable.category,
			'subcategory', optionTable.subcategory,
			'cvar', optionTable.cvar,
			'title', EscapeString(optionTable.title),
			'sub_text1', EscapeString(optionTable.sub_text1),
			'sub_text2', EscapeString(optionTable.sub_text2),
			'sub_text3', EscapeString(optionTable.sub_text3),
			'tip_image', EscapeString(optionTable.tip_image),
			'tip_name', EscapeString(optionTable.tip_name),
			'tip_text1', EscapeString(optionTable.tip_text1),
			'tip_text2', EscapeString(optionTable.tip_text2),
			'tip_text3', EscapeString(optionTable.tip_text3),
			'gradmark1_pos', optionTable.gradPos1,
			'gradmark2_pos', optionTable.gradPos2,
			'gradmark3_pos', optionTable.gradPos3,
			'gradmark4_pos', optionTable.gradPos4,
			'gradmark5_pos', optionTable.gradPos5,
			'gradmark1_name', EscapeString(optionTable.gradName1),
			'gradmark2_name', EscapeString(optionTable.gradName2),
			'gradmark3_name', EscapeString(optionTable.gradName3),
			'gradmark4_name', EscapeString(optionTable.gradName4),
			'gradmark5_name', EscapeString(optionTable.gradName5),
			'maxvalue', optionTable.maxvalue,
			'data', optionTable.data,
			'onchange', optionTable.onchange,
			'onchangelua', optionTable.onchangelua,
			'oninstantiatelua', optionTable.oninstantiatelua,
			'onloadlua', optionTable.oninstantiatelua,
			'oneventlua', optionTable.oneventlua,
			'onselect', optionTable.onselect,
			'populate', optionTable.populate,
			'maxlistheight', optionTable.maxlistheight,
			'slidefunction', optionTable.slidefunction,
			'inverted', optionTable.inverted,
			'pair', optionTable.pair,
			'enforce', optionTable.enforce,
			'enforce2', optionTable.enforce2,
			'enforce3', optionTable.enforce3,
			'enforce4', optionTable.enforce4,
			'precision', optionTable.precision,
			'numerictype', optionTable.numerictype,
			'percent', optionTable.percent,
			'round_var', optionTable.round_var,
			'title_font', optionTable.title_font,
			'command', optionTable.command,
			'table', optionTable.table,
			'action', optionTable.action,
			'param', optionTable.param,
			'impulse', optionTable.impulse,
			'onclick', optionTable.onclick,
			'label', optionTable.label or '',
			'register', 'false'
		)

		if (resultCount == 1) then
			newWidgets[1]:SetY(0)
		end
		
	end

	local groupTable = interface:GetGroup('options_search_results')
	if (groupTable) and (#groupTable > 0) then
		for i, widget in pairs(groupTable) do 
			widget:DoEventN(9)
		end
	end	

	GetWidget('options_search_cover_throb'):SetVisible(0)	
		
	if (#matchingOptionTable > 0) then
		GetWidget('options_search_insertion_point_cover'):SetVisible(0)
		GetWidget('options_search_cover_label'):SetVisible(0)
	else
		GetWidget('options_search_insertion_point_cover'):SetVisible(1)
		GetWidget('options_search_cover_label'):SetVisible(1)
		GetWidget('options_search_cover_label'):SetText(Translate("options_search_not_found"))
	end

end

local function SearchOptions(searchString)
	
	-- println('searchString = ' .. tostring(searchString) )
	if (debug_output) then
		Echo("Searching for "..searchString)
	end
	
	local groupTable = interface:GetGroup('options_search_results')
	if (groupTable) and (#groupTable > 0) then
		for i, widget in pairs(groupTable) do 
			widget:Destroy()
		end
	end	
	
	local matchingOptionTable = {}

	for k, optionTable in pairs(Strife_Options.optionsInfoTable) do
		-- search the title, the sub texts, the tips, and cvar name for matches
		-- instead of the old way which was against everything and against them untranslated
		if (find(string.lower(Translate(optionTable.title)), string.lower(searchString)) or
		find(string.lower(Translate(optionTable.sub_text1)), string.lower(searchString)) or
		find(string.lower(Translate(optionTable.sub_text2)), string.lower(searchString)) or
		find(string.lower(Translate(optionTable.sub_text3)), string.lower(searchString)) or
		find(string.lower(Translate(optionTable.tip_name)), string.lower(searchString)) or
		find(string.lower(Translate(optionTable.tip_text1)), string.lower(searchString)) or
		find(string.lower(Translate(optionTable.tip_text2)), string.lower(searchString)) or
		find(string.lower(Translate(optionTable.tip_text3)), string.lower(searchString)) or
		find(string.lower(optionTable.cvar), string.lower(searchString))) then
			tinsert(matchingOptionTable, optionTable)
			if (debug_output) then
				Echo("Match found in search "..optionTable.title.." Key: "..k.." Translated: "..Translate(optionTable.title))
			end
			-- println('^g optionInfo = ' .. tostring(optionInfo) .. ' | searchString = ' .. tostring(searchString) )
		else
			if (debug_output) then
				Echo("Match found ^rNOT^* found in search "..optionTable.title.." Key: "..k.." Translated: "..Translate(optionTable.title))
			end
			-- println('^r optionInfo = ' .. tostring(optionInfo) .. ' | searchString = ' .. tostring(searchString) )
		end
	end

	-- printTable(matchingOptionTable)
	
	GetWidget('options_search_insertion_point'):Sleep(1, function()
		DisplaySearchResults(matchingOptionTable)
	end)
end

function Strife_Options.SearchOptionsInput(searchString)
	
	local destroyTable = interface:GetGroup('options_search_results')
	
	if (destroyTable) and (#destroyTable > 0) then
		for i, widget in pairs(destroyTable) do 
			widget:Destroy()
		end
	end
	
	GetWidget('options_search_insertion_point_cover'):SetVisible(1)

	if (searchString) and (not Empty(searchString)) then
		if (string.len(searchString) >= 3) then
			Strife_Options.canScroll = false

			GetWidget("options_main_category"..Strife_Options.selectedCategory):SetY(0)
			Strife_Options.scrollPosition = 0

			GetWidget('options_search_cover_throb'):SetVisible(1)
			GetWidget('options_search_cover_label'):SetVisible(0)
			GetWidget('options_search_input'):Sleep(550, function()
				SearchOptions(searchString)
			end)
		else
			GetWidget('options_search_cover_throb'):SetVisible(0)
			GetWidget('options_search_cover_label'):SetText(Translate("options_search_too_short"))
			GetWidget('options_search_cover_label'):SetVisible(1)

			Strife_Options.canScroll = false
			
			-- interrupt an already running sleep to do a search
			GetWidget('options_search_input'):Sleep(1, function() end)

			GetWidget("options_main_category"..Strife_Options.selectedCategory):SetY(0)
			Strife_Options.scrollPosition = 0
		end
	else
		GetWidget('options_search_cover_throb'):SetVisible(0)
		GetWidget('options_search_cover_label'):SetText(Translate("options_search_terms"))
		GetWidget('options_search_cover_label'):SetVisible(1)
		-- interrupt an already running sleep to do a search
		GetWidget('options_search_input'):Sleep(1, function() end)

		if (Strife_Options.selectedCategory == 8) then -- update me if the search moves
			Strife_Options.canScroll = false

			GetWidget("options_main_category"..Strife_Options.selectedCategory):SetY(0)
			Strife_Options.scrollPosition = 0
		end
	end
end

---------------------- end search

-- function to open the options from elsewhere
function OpenOptions(category, subCategory, forceOpen)
	if (not GetWidget("game_options"):IsVisible()) then
		Strife_Options.targetCategory, Strife_Options.targetSubCategory = tonumber(category), tonumber(subCategory)

		local mainPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
		mainPanelStatus.main = 26
		mainPanelStatus:Trigger(false)
	else
		Strife_Options:SelectSubCategory(tonumber(category), tonumber(subCategory))
	end
end

function Strife_Options:Register(object)
	
	for i, v in pairs(multiPartSettingTable) do
		if Cvar.GetCvar(i) then
			-- println('no ' .. i .. ' ' .. v.default)
		else
			-- println('save ' .. i .. ' ' .. v.default)
			Set(i, v.default, 'string')
			SetSave(i, v.default, 'string')
		end
	end			
	
	if (not Strife_Options.optionsInfoTable) then
		if (debug_output) then
			println("Registering Options...")
		end
		Strife_Options.optionsInfoTable = {}
		
		local groupTable = interface:GetGroup('options_options')
		if (groupTable) and (#groupTable > 0) then
			for i, widget in pairs(groupTable) do 
				widget:DoEventN(8)
			end
		end			
		
	end	
	
	-- if (LuaTrigger.GetTrigger('navigationAnimationGroupTrigger')) then -- only in launcher
		object:GetWidget('game_options'):RegisterWatchLua('mainPanelAnimationStatus', function(self, trigger)
			-- local trigger  = groupTrigger['mainPanelAnimationStatus']
			if ((mainUI.featureMaintenance) and (mainUI.featureMaintenance['options'])) then	-- fully hidden due to feature maintenance
				self:SetVisible(0)
			else
				if (trigger.newMain ~= 26) and (trigger.newMain ~= -1) then			-- outro
					self:FadeOut(500)
				elseif (trigger.main ~= 26) and (trigger.newMain ~= 26) then			-- fully hidden
					self:SetVisible(0)
				elseif (trigger.newMain == 26) and (trigger.newMain ~= -1) then		-- intro
					self:FadeIn(500)
				elseif (trigger.main == 26) then										-- fully displayed
					self:SetVisible(1)
				end
			end
		end, false, nil, 'main', 'newMain')
	-- end
	
	object:GetWidget('optionsButtonControlPresets'):SetCallback('onclick', function(widget)
		local mainPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
		mainPanelStatus.main = mainUI.MainValues.controlPresets
		mainPanelStatus:Trigger(false)
		mainUI.savedRemotely = mainUI.savedRemotely or {}
		mainUI.savedRemotely.splashScreensViewed = mainUI.savedRemotely.splashScreensViewed or {}
		mainUI.savedRemotely.splashScreensViewed['splash_screen_control_presets'] = true
		SaveState()		
	end)
	
	local cloudPanel = object:GetWidget('options_cloud_indicator')
	local cloudImage = object:GetWidget('options_cloud_indicator_image')
	
	if optionsTrigger.isSynced then
		cloudImage:SetTexture('/ui/main/shared/textures/cloud_success.tga')
	else
		cloudImage:SetTexture('/ui/main/shared/textures/cloud_fail.tga')
	end
	cloudPanel:SetCallback('onclick', function(widget) --allow re-sync on cloud-press
		if not optionsTrigger.isSynced and IsFullyLoggedIn(GetIdentID()) then
			optionsTrigger.isSynced = true --no spam-clicking
			SaveDBToWeb()
		end
	end)
	cloudImage:RegisterWatchLua('optionsTrigger', function(widget, trigger)
		if optionsTrigger.isSynced then
			widget:SetTexture('/ui/main/shared/textures/cloud_success.tga')
		else
			widget:SetTexture('/ui/main/shared/textures/cloud_fail.tga')
		end
	end, false, nil, 'updateVisuals')
	
	object:GetWidget('optionsButtonBinderDefault'):SetCallback('onclick', function(widget)
		-- mainOptionsDefaultKeybindings
		-- PlaySound('/path_to/filename.wav')
		GenericDialogAutoSize(
			'options_button_default_binds', 'options_button_default_binds_desc', '', 'general_yes', 'general_no', 
				function()
					-- ok
					Strife_Options:ResetKeybinds()
					object:UICmd('Refresh()')
					
				end,
				function()
					-- cancel				
				end
		)		
	end)

	object:GetWidget('optionsButtonBinderClear'):SetCallback('onclick', function(widget)
		-- mainOptionsRemoveAllBindings
		-- PlaySound('/path_to/filename.wav')
		GenericDialogAutoSize(
			'options_button_clear_binds', 'options_button_clear_binds_desc', '', 'general_yes', 'general_no', 
				function()
					-- ok
					Exec('clear_binds.cfg')			
					object:UICmd('Refresh()')
				end,
				function()
					-- cancel				
				end
		)
	end)
	
	-- Voice
	object:GetWidget('text_mic_level_bar_1'):RegisterWatchLua('VoiceTestLevel', function(widget, trigger)
		if object:GetWidget('Mvoice_test_stop'):IsVisible() then
			widget:SetWidth( ( (1 - trigger.averageLevel) * 100 ) .. '%')
		end
	end, false, nil, 'averageLevel')
	
	object:GetWidget('text_mic_level_bar_2'):RegisterWatchLua('VoiceTestLevel', function(widget, trigger)
		if object:GetWidget('Mvoice_test_stop'):IsVisible() then
			widget:SetWidth( ( (1 - trigger.level) * 100 ) .. '%')
		end
	end, false, nil, 'level')	
	
	object:GetWidget('text_mic_level_bar_1_1'):RegisterWatchLua('VoiceTestLevel', function(widget, trigger)
		if object:GetWidget('Mvoice_test_stop2'):IsVisible() then
			object:GetWidget('text_mic_level_nubbin_2'):SetX( (GetCvarNumber('voice_activationStartLevel')*100)  .. '%' )
			widget:SetWidth( ( (trigger.averageLevel) * 100 ) .. '%')
			if (trigger.isTalking) then
				widget:SetColor('#18d901')
			else
				widget:SetColor('#FF0000')
			end
		end
	end, false, nil, 'averageLevel', 'isTalking')	
	
	Strife_Options.CanApply()
	
	-- ======================

	-- rmm replace later when we have a non-cvar replacement for RegisterOption / RegisterCheckbox	
	object:GetWidget('launcher_music_cbname'):SetCallback('onclick', function(widget, trigger)
		local triggerPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
		triggerPanelStatus.launcherMusicEnabled = (not triggerPanelStatus.launcherMusicEnabled)
		triggerPanelStatus:Trigger(false)
	end)

	local function launcherMusicCheckboxUpdate(widget, trigger, saveUpdate)
		trigger = trigger or LuaTrigger.GetTrigger('mainPanelStatus')
		
		if saveUpdate == nil then saveUpdate = true end
		
		local launcherMusicEnabled	= trigger.launcherMusicEnabled
		local frame					= object:GetWidget('options_checkbox_frame_launcher_music')
		
		if saveUpdate then
			mainUI.launcherMusicEnabled = launcherMusicEnabled
		end
		
		if launcherMusicEnabled then
			widget:SetVisible(true)
			frame:SetColor('#4ab4ff')
			frame:SetBorderColor('#4ab4ff')
			frame:SetRenderMode('normal')
		else
			widget:SetVisible(false)
			frame:SetColor('.8 .8 .8 1')
			frame:SetBorderColor('.8 .8 .8 1')
			frame:SetRenderMode('grayscale')
		end
	end
	
	object:GetWidget('options_checkbox_check_launcher_music'):RegisterWatchLua('mainPanelStatus', launcherMusicCheckboxUpdate, false, nil, 'launcherMusicEnabled')
	launcherMusicCheckboxUpdate(object:GetWidget('options_checkbox_check_launcher_music'), nil, false)
end

function Strife_Options:ResetOptions()
	local function resetCvar(cvarName)
		local c = Cvar.GetCvar(cvarName)
		if c then
			c:Reset()
			--println('^greset '..cvarName.." value is: "..c:GetString())
		end
	end
	
	for cvar, _ in pairs(Strife_Options.currentSettings) do
		if string.find(cvar, 'vid_') or string.find(cvar, 'd9_') or string.find(cvar, 'd11_') or string.find(cvar, 'gl_') or string.find(cvar, 'options_window_mode') or string.find(cvar, 'options_framequeuing') or string.find(cvar, 'options_shaderQuality') or string.find(cvar, 'options_vsync') or string.find(cvar, 'options_shadowQuality') then
			-- Don't reset video modes etc.
		else
			resetCvar(cvar)
		end
	end
	Exec('default_options.cfg')
	Strife_Options:ResetKeybinds() -- Reset the keybinds
	
end