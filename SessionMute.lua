----------
----------

SessionMute = SessionMute or {}
local sm = SessionMute
sm.name = "SessionMute"
sm.displayName = "Session Mute"
sm.author = "Alianym"
sm.version = "0.01"

local addonName =  sm.name
sm.muteList = {}
local muteList = sm.muteList
sm.SV = {}
local settings = sm.SV

local zostrfor = zo_strformat

----------
--SLASH_COMMANDS
----------

local function GetMutedPlayersList()
	CHAT_ROUTER:AddSystemMessage(GetString(MUTE_PLAYER_SHOW_LIST))
	for name, isMuted in pairs(muteList) do
		if isMuted then
			local fmtName = zostrfor("<<1>>", name) -- Because muteList stores rawName, we want to format it before displaying it
			CHAT_ROUTER:AddSystemMessage(fmtName)
		end
	end
end
SLASH_COMMANDS["/mutedlist"] = GetMutedPlayersList

local function RemoveMutedPlayerFromList(playerName, rawName)
	if muteList[rawName] then
		muteList[rawName] = false
		CHAT_ROUTER:AddSystemMessage(zostrfor(GetString(MUTE_PLAYER_PLAYER_UNMUTED), playerName))
	else
		CHAT_ROUTER:AddSystemMessage(zostrfor(GetString(MUTE_PLAYER_PLAYER_NOT_IN_LIST), playerName))
	end
end
SLASH_COMMANDS["/unmute"] = RemoveMutedPlayerFromList

----------
--Function for PreHook Chat Router (Hooked at OnPlayerActivated below)
----------

local function FormatAndAddChatMessage(_, eventKey, ...)
	if not eventKey == EVENT_CHAT_MESSAGE_CHANNEL then return end -- Only interested in this event

	if not IsChatSystemAvailableForCurrentPlatform() then
		return
	end

	local MultiLevelEventToCategoryMappings, SimpleEventToCategoryMappings = ZO_ChatSystem_GetEventCategoryMappings()
	local messageType, fromName, text, isFromCustomerService, fromDisplayName = ...

	-- If 'muted', don't display
	if fromDisplayName and (muteList[fromName] or muteList[fromDisplayName]) then
		-- If showMissedMessage then show the chat from a muted player, but 'mute' the text
		if settings.showMissedMessage then
			text = GetString(MUTE_PLAYER_MUTED_MESSAGE_DEFAULT)
		else return end
	else return end

	local eventCategory = nil
	if SimpleEventToCategoryMappings[eventKey] then
		eventCategory = SimpleEventToCategoryMappings[eventKey]
	elseif MultiLevelEventToCategoryMappings[eventKey] then
		messageType = select(1, ...)
		eventCategory = MultiLevelEventToCategoryMappings[eventKey][messageType]
	end

	local messageFormatter = CHAT_ROUTER.registeredMessageFormatters[eventKey]
	if messageFormatter then
		local formattedEventText, targetChannel, fromDisplayName, rawMessageText = messageFormatter(messageType, fromName, text, isFromCustomerService, fromDisplayName)

		if formattedEventText then
			if targetChannel then
				local target = select(2, ...)
				CHAT_ROUTER:FireCallbacks("TargetAddedToChannel", targetChannel, target)
			end

			CHAT_ROUTER:FireCallbacks("FormattedChatMessage", formattedEventText, eventCategory, targetChannel, fromDisplayName, rawMessageText)
		end
	end

	return true
end

----------
--Add PlayerContextMenu Option
----------

local function OnPlayerActivated()
	local function sessionMutePlayerContextMenu(playerName, rawName)
		local function MutePlayerForSession()
			if not muteList[rawName] then
				muteList[rawName] = true
				CHAT_ROUTER:AddSystemMessage(zostrfor(GetString(MUTE_PLAYER_SESSION_MUTE), playerName))
			end
		end

		local function UnMutePlayerForSession()
			RemoveMutedPlayerFromList(playerName, rawName)
		end

		if not muteList[rawName] then
			AddCustomMenuItem(GetString(MUTE_PLAYER_SESSION_MUTE_MENU_ITEM), MutePlayerForSession)
		else
			AddCustomMenuItem(GetString(MUTE_PLAYER_SESSION_UNMUTE_MENU_ITEM), UnMutePlayerForSession)
		end
	end

	LibCustomMenu:RegisterPlayerContextMenu(sessionMutePlayerContextMenu, LibCustomMenu.CATEGORY_LATE)

	ZO_PreHook(CHAT_ROUTER, "FormatAndAddChatMessage", FormatAndAddChatMessage)

	EVENT_MANAGER:UnregisterForEvent(addonName, EVENT_PLAYER_ACTIVATED)
end
EVENT_MANAGER:RegisterForEvent(addonName, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

----------
--Settings
----------

local defaultVars = {showMissedMessage = false, showMissedMessagePlayerName = false}

local panelData = {
	type = "panel",
	name = 			sm.name,
	displayName = 	sm.displayName,
	author = 		sm.author,
	version = 		sm.version,
	--slashCommand = "/sessionmutesettings",
	registerForDefaults = true,
}

local optionsTable = {
	[1] = {
		type = "header",
		name = GetString(MUTE_PLAYER_LAM_OPTIONS),
		width = "full",	--or "half" (optional)
	},
	[2] = {
		type = "checkbox",
		name = GetString(MUTE_PLAYER_LAM_CHAT_NOTIFY),
		tooltip = GetString(MUTE_PLAYER_LAM_CHAT_NOTIFY_TT),
		getFunc = function() return settings.showMissedMessage end,
		setFunc = function(value) settings.showMissedMessage = value end,
		width = "full", -- or "half" (optional)
		default = defaultVars.showMissedMessage,
	},
}

----------
--OnLoad
----------

local function OnLoad(e, addOnName)
	if addOnName ~= addonName then return end

	sm.SV = ZO_SavedVars:NewAccountWide("SessionMuteSavedVars", 1, nil, defaultVars, GetWorldName())
	settings = sm.SV

	local LAM = LibAddonMenu2
	LAM:RegisterAddonPanel(addonName, panelData)
	LAM:RegisterOptionControls(addonName, optionsTable)

	EVENT_MANAGER:UnregisterForEvent(addonName, EVENT_ADD_ON_LOADED) 
end
EVENT_MANAGER:RegisterForEvent(addonName, EVENT_ADD_ON_LOADED, OnLoad)
