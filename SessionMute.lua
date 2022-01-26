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
	CHAT_ROUTER:AddSystemMessage(GetString(SESSION_MUTE_SHOW_LIST))
	for name, isMuted in pairs(muteList) do
		if isMuted then
			CHAT_ROUTER:AddSystemMessage(name)
		end
	end
end
SLASH_COMMANDS["/sessionmutelist"] = GetMutedPlayersList

local function RemoveMutedPlayerFromList(name)
	if muteList[name] then
		muteList[name] = false
		CHAT_ROUTER:AddSystemMessage(zostrfor(GetString(SESSION_MUTE_PLAYER_UNMUTED), name))
	else
		CHAT_ROUTER:AddSystemMessage(zostrfor(GetString(SESSION_MUTE_PLAYER_NOT_IN_LIST), name))
	end
end
SLASH_COMMANDS["/sessionmuteremove"] = RemoveMutedPlayerFromList

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
	local fmtFromName = zostrfor("<<1>>", fromName)

	-- If 'muted', don't display (unless set to show that a message was missed)
	if (not isFromCustomerService) and fromDisplayName and (muteList[fmtFromName] or muteList[fromDisplayName]) then
		-- If showMissedMessage then show the chat from a muted player, but 'mute' the text
		if settings.showMissedMessage then
			text = GetString(SESSION_MUTE_MUTED_MESSAGE_DEFAULT)
		else return true end
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
		name = GetString(SESSION_MUTE_LAM_OPTIONS),
		width = "full",	--or "half" (optional)
	},
	[2] = {
		type = "description",
		--title = "My Title",	--(optional)
		text = GetString(SESSION_MUTE_LAM_DESC_TEXT),
		width = "full",	--or "half" (optional)
	},
	[3] = {
		type = "checkbox",
		name = GetString(SESSION_MUTE_LAM_CHAT_NOTIFY),
		tooltip = GetString(SESSION_MUTE_LAM_CHAT_NOTIFY_TT),
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
	EVENT_MANAGER:UnregisterForEvent(addonName, EVENT_ADD_ON_LOADED) 

	sm.SV = ZO_SavedVars:NewAccountWide("SessionMuteSavedVars", 1, nil, defaultVars, GetWorldName())
	settings = sm.SV

	local LAM = LibAddonMenu2
	LAM:RegisterAddonPanel(addonName, panelData)
	LAM:RegisterOptionControls(addonName, optionsTable)

	local function SessionMutePlayerContextMenu(playerName, rawName)
		local function MutePlayerForSession()
			if not muteList[playerName] then
				muteList[playerName] = true
				CHAT_ROUTER:AddSystemMessage(zostrfor(GetString(SESSION_MUTE_SESSION_MUTE), playerName))
			end
		end

		local function UnMutePlayerForSession()
			RemoveMutedPlayerFromList(playerName)
		end

		if not muteList[playerName] then
			AddCustomMenuItem(GetString(SESSION_MUTE_SESSION_MUTE_MENU_ITEM), MutePlayerForSession)
		else
			AddCustomMenuItem(GetString(SESSION_MUTE_SESSION_UNMUTE_MENU_ITEM), UnMutePlayerForSession)
		end
	end

	LibCustomMenu:RegisterPlayerContextMenu(SessionMutePlayerContextMenu, LibCustomMenu.CATEGORY_LATE)
	
end
EVENT_MANAGER:RegisterForEvent(addonName, EVENT_ADD_ON_LOADED, OnLoad)
