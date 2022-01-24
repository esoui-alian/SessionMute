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
			CHAT_ROUTER:AddSystemMessage(name)
		end
	end
end
SLASH_COMMANDS["/mutedlist"] = GetMutedPlayersList

local function RemoveMutedPlayerFromList(name)
	if muteList[name] then
		muteList[name] = false
		CHAT_ROUTER:AddSystemMessage(zostrfor(GetString(MUTE_PLAYER_PLAYER_UNMUTED), name))
	else
		CHAT_ROUTER:AddSystemMessage(zostrfor(GetString(MUTE_PLAYER_PLAYER_NOT_IN_LIST), name))
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
	local charName = zostrfor("<<1>>", fromName)
	if fromDisplayName and (muteList[charName] or muteList[fromDisplayName]) then
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
	local function SessionMute(playerName, rawName)
		local function MutePlayerForSession()
			if not muteList[playerName] then
				muteList[playerName] = true
				CHAT_ROUTER:AddSystemMessage(zostrfor(GetString(MUTE_PLAYER_SESSION_MUTE), playerName))
			end
		end

		local function UnMutePlayerForSession()
			RemoveMutedPlayerFromList(playerName)
		end

		if not muteList[playerName] then
			AddCustomMenuItem(GetString(MUTE_PLAYER_SESSION_MUTE_MENU_ITEM), MutePlayerForSession)
		else
			AddCustomMenuItem(GetString(MUTE_PLAYER_SESSION_UNMUTE_MENU_ITEM), UnMutePlayerForSession)
		end
	end

	LibCustomMenu:RegisterPlayerContextMenu(SessionMute, LibCustomMenu.CATEGORY_LATE)

	ZO_PreHook(CHAT_ROUTER, "FormatAndAddChatMessage", FormatAndAddChatMessage)
end
EVENT_MANAGER:RegisterForEvent(addonName, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

--Rewrite ShowPlayerContextMenu (on Keyboard only)
--[[local function ShowPlayerContextMenu(_, playerName, rawName)
	ClearMenu()

	-- Add to/Remove from Group
	if IsGroupModificationAvailable() then
		local localPlayerIsGrouped = IsUnitGrouped("player")
		local localPlayerIsGroupLeader = IsUnitGroupLeader("player")
		local otherPlayerIsInPlayersGroup = IsPlayerInGroup(rawName)
		if not localPlayerIsGrouped or (localPlayerIsGroupLeader and not otherPlayerIsInPlayersGroup) then
			AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_ADD_GROUP), function()
			local SENT_FROM_CHAT = false
			local DISPLAY_INVITED_MESSAGE = true
			TryGroupInviteByName(playerName, SENT_FROM_CHAT, DISPLAY_INVITED_MESSAGE) end)
		elseif otherPlayerIsInPlayersGroup and localPlayerIsGroupLeader then
			AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_REMOVE_GROUP), function() GroupKickByName(rawName) end)
		end
	end

	-- Whisper
	AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_WHISPER), function() KEYBOARD_CHAT_SYSTEM:StartTextEntry(nil, CHAT_CHANNEL_WHISPER, playerName) end)

	-- Ignore
	local function IgnoreSelectedPlayer()
		if not IsIgnored(playerName) then
			AddIgnore(playerName)
		end
	end

	if not IsIgnored(playerName) then
		AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_ADD_IGNORE), IgnoreSelectedPlayer)
	end

	----------
	-- Session Mute/Unmute
	----------
	local function MutePlayerForSession()
		if not muteList[playerName] then
			muteList[playerName] = true
			CHAT_ROUTER:AddSystemMessage(zostrfor("<<1>>: [<<2>>]", GetString(MUTE_PLAYER_SESSION_MUTE), playerName))
		end
	end

	local function UnMutePlayerForSession()
		RemoveMutedPlayerFromList(playerName)
	end

	if not muteList[playerName] then
		AddMenuItem(GetString(MUTE_PLAYER_SESSION_MUTE_MENU_ITEM), MutePlayerForSession)
	else
		AddMenuItem(GetString(MUTE_PLAYER_SESSION_UNMUTE_MENU_ITEM), UnMutePlayerForSession)
	end
	----------
	----------

	-- Add Friend
	if not IsFriend(playerName) then
		AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_ADD_FRIEND), function() ZO_Dialogs_ShowDialog("REQUEST_FRIEND", { name = playerName }) end)
	end

	-- Report player
	AddMenuItem(zostrfor(SI_CHAT_PLAYER_CONTEXT_REPORT, rawName), function()
		ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(playerName, IgnoreSelectedPlayer)
	end)

	if ZO_Menu_GetNumMenuItems() > 0 then
		ShowMenu()
	end

	return true
end
ZO_PreHook(KEYBOARD_CHAT_SYSTEM, "ShowPlayerContextMenu", ShowPlayerContextMenu)]]

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
	registerForRefresh = false, --not needed if there are no disabled functions or other callbacks!
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
