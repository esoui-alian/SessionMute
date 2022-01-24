local stringsEN = {
	MUTE_PLAYER_SESSION_MUTE_MENU_ITEM = "Session Mute",
	MUTE_PLAYER_SESSION_UNMUTE_MENU_ITEM = "Session Unmute",
	MUTE_PLAYER_SESSION_MUTE = "You muted [<<1>>]",
	MUTE_PLAYER_SHOW_LIST = "Muted players: ",
	MUTE_PLAYER_MUTED_MESSAGE_DEFAULT = "Muted Message",
	MUTE_PLAYER_MUTED = "Muted",
	MUTE_PLAYER_PLAYER_UNMUTED = "You unmuted [<<1>>]",
	MUTE_PLAYER_PLAYER_NOT_IN_LIST = "[<<1>>] is not currently muted.",

	--LAM settings menu
	MUTE_PLAYER_LAM_OPTIONS = "Options",
	MUTE_PLAYER_LAM_CHAT_NOTIFY = "Notify in Chat of Muted Messages",
	MUTE_PLAYER_LAM_CHAT_NOTIFY_TT = "If true this will display a chat message that a muted player has sent a message, but not what that message was.",
}

for id, stringVar in pairs(stringsEN) do
   ZO_CreateStringId(id, stringVar)
   SafeAddVersion(id, 1)
end