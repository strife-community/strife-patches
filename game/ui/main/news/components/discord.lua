-- A component entry should have:
-- internalName			The name to be used to save/id the component
-- externalName			The name to show on dialogues etc
-- singleton			Whether multiple of this component are disallowed
-- resizableContainer	The widget that represents the size of the component
-- onLoad				A function to be called when the component loads
-- onRemove				A function to be called when the component is removed
-- init					A function to be called to create the component, takes (parent, x, y, w, h)

local interface = object

local function setUpDiscordSection()
	local button = interface:GetWidget('main_discord_button')
	local buttonContainer = interface:GetWidget('main_discord_button_container')
	buttonContainer:SetCallback('onclick', function()
		mainUI.OpenURL("https://discord.gg/Z43YJaj")
	end)
	buttonContainer:SetCallback('onmouseover', function()
		button:SetTexture('/ui/shared/frames/blue_btn_over.tga')
		libAnims.bounceIn(button, button:GetWidth(), button:GetHeight(), nil, nil, 0.02, 200, 0.9, 0.1)
	end)
	buttonContainer:SetCallback('onmouseout', function()
		button:SetTexture('/ui/shared/frames/blue_btn_up.tga')
	end)
end

local function onLoad()
	setUpDiscordSection()
end
local function init(parent, x, y, w, h)
	return parent:InstantiateAndReturn('main_discord_container_template', 'x', x, 'y', y, 'w', w, 'h', h)[1]
end
local function onRemove()
	getResizableContainer():Destroy()
end

local function getResizableContainer()
	return interface:GetWidget("main_discord_container")
end

local newsDiscordComponent = {
	internalName = "main_news_discord",
	externalName = "news_component_discord",
	singleton = true,
	defaultPosition = {"20s", "390s", "606s", "83s"},
	sizeRange = {'543s', 999999, '65s', 999999},
	onLoad = onLoad,
	onRemove = onRemove,
	init = init,
	getResizableContainer = getResizableContainer,
}


mainUI.news.registerComponent(newsDiscordComponent)