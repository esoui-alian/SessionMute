----------
----------
local addonName = "SessionMute"
local muteList = muteList or {}
local SessionMute = SessionMute or {}

----------
--SLASH_COMMANDS
----------

local function GetMutedPlayersList()
	CHAT_ROUTER:AddSystemMessage(zo_strformat("<<1>>: ", GetString(MUTE_PLAYER_SHOW_LIST)))
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
		CHAT_ROUTER:AddSystemMessage(zo_strformat("<<1>> [<<2>>]", GetString(MUTE_PLAYER_PLAYER_UNMUTED), name))
	else
		CHAT_ROUTER:AddSystemMessage(zo_strformat("[<<1>>] <<2>>", name, GetString(MUTE_PLAYER_PLAYER_NOT_IN_LIST)))
	end
end
SLASH_COMMANDS["/unmute"] = RemoveMutedPlayerFromList

----------
--PreHook Chat Router
----------

local function FormatAndAddChatMessage(_, eventKey, ...)
	if not eventKey == EVENT_CHAT_MESSAGE_CHANNEL then return end -- Only interested in this event

	local MultiLevelEventToCategoryMappings, SimpleEventToCategoryMappings = ZO_ChatSystem_GetEventCategoryMappings()
	local messageType, fromName, text, isFromCustomerService, fromDisplayName = ...

	if not IsChatSystemAvailableForCurrentPlatform() then
		return
	end

	-- Don't display if is 'muted'

	local charName = zo_strformat("<<1>>", fromName)
	if fromDisplayName and (muteList[charName] or muteList[fromDisplayName]) then
		if SessionMute.SV.showMissedMessage then 
			if not SessionMute.SV.showMissedMessagePlayerName then
				fromDisplayName = zo_strformat("@<<1>>", GetString(MUTE_PLAYER_MUTED))
				fromName = zo_strformat("<<1>>", GetString(MUTE_PLAYER_MUTED))
			end

			text = zo_strformat("<<<1>>>", GetString(MUTE_PLAYER_MUTED_MESSAGE_DEFAULT))
		else return end
	else return end

	local eventCategory = nil
	if SimpleEventToCategoryMappings[eventKey] then
		eventCategory = SimpleEventToCategoryMappings[eventKey]
	elseif MultiLevelEventToCategoryMappings[eventKey] then
		local messageType = select(1, ...)
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
ZO_PreHook(CHAT_ROUTER, "FormatAndAddChatMessage", FormatAndAddChatMessage)

----------
--PreHook Chat Player Context Menu
----------

--Rewrite ShowPlayerContextMenu (on Keyboard only)
local function ShowPlayerContextMenu(_, playerName, rawName)
	ClearMenu()

	-- If the player is showing up as "Muted" then it could get buggy so let's not allow menus here.
	if playerName == GetString(MUTE_PLAYER_MUTED) or rawName == GetString(MUTE_PLAYER_MUTED) then return end

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
			CHAT_ROUTER:AddSystemMessage(zo_strformat("<<1>>: [<<2>>]", GetString(MUTE_PLAYER_SESSION_MUTE), playerName))
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
	AddMenuItem(zo_strformat(SI_CHAT_PLAYER_CONTEXT_REPORT, rawName), function()
		ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(playerName, IgnoreSelectedPlayer)
	end)

	if ZO_Menu_GetNumMenuItems() > 0 then
		ShowMenu()
	end

	return true
end
ZO_PreHook(KEYBOARD_CHAT_SYSTEM, "ShowPlayerContextMenu", ShowPlayerContextMenu)

----------
--Settings
----------

local defaultVars = {showMissedMessage = false, showMissedMessagePlayerName = false}

local panelData = {
	type = "panel",
	name = "Session Mute",
	displayName = "Session Mute",
	author = "Alianym",
	version = "0.01",
	--slashCommand = "/muteplayersettings",
	registerForRefresh = true,
	registerForDefaults = true,
}

local optionsTable = {
	[1] = {
		type = "header",
		name = "Options",
		width = "full",	--or "half" (optional)
	},
	[2] = {
		type = "checkbox",
		name = "Notify in Chat of Muted Messages",
		getFunc = function() return SessionMute.SV.showMissedMessage end,
		setFunc = function(value) SessionMute.SV.showMissedMessage = value end,
		tooltip = "If true this will display a chat message that muted player has sent a message, but not what that message was.",
		width = "full", -- or "half" (optional)
		default = defaultVars.showMissedMessage,
	},
	[3] = {
		type = "checkbox",
		name = "Reveal Player Name in Muted Messages",
		getFunc = function() return SessionMute.SV.showMissedMessagePlayerName end,
		setFunc = function(value) SessionMute.SV.showMissedMessagePlayerName = value end,
		tooltip = "If true this will not hide the muted player's name when notifying in chat of a missed muted message.",
		width = "full", -- or "half" (optional)
		disabled = function() return not SessionMute.SV.showMissedMessage end,
		default = defaultVars.showMissedMessagePlayerName,
	},
}

----------
--OnLoad
----------

local function OnLoad(e, addOnName)
	if addOnName ~= addonName then return end

	SessionMute.SV = ZO_SavedVars:NewCharacterIdSettings("SessionMuteSavedVars", 1, nil, defaultVars, GetWorldName())

	local LAM = LibAddonMenu2
	LAM:RegisterAddonPanel(addonName, panelData)
	LAM:RegisterOptionControls(addonName, optionsTable)

	EVENT_MANAGER:UnregisterForEvent(addonName, EVENT_ADD_ON_LOADED) 
end
EVENT_MANAGER:RegisterForEvent(addonName, EVENT_ADD_ON_LOADED, OnLoad)