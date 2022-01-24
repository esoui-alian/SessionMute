local stringsEN = {
	MUTE_PLAYER_SESSION_MUTE_MENU_ITEM = "Session Mute",
	MUTE_PLAYER_SESSION_UNMUTE_MENU_ITEM = "Session Unmute",
	MUTE_PLAYER_SESSION_MUTE = "You Muted",
	MUTE_PLAYER_SHOW_LIST = "Muted Players",
	MUTE_PLAYER_MUTED_MESSAGE_DEFAULT = "Muted Message",
	MUTE_PLAYER_MUTED = "Muted",
	MUTE_PLAYER_PLAYER_UNMUTED = "You Unmuted",
	MUTE_PLAYER_PLAYER_NOT_IN_LIST = "is not currently muted."
}

for id, stringVar in pairs(stringsEN) do
   ZO_CreateStringId(id, stringVar)
   SafeAddVersion(id, 1)
end