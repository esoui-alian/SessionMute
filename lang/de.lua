local stringsDE = {
	MUTE_PLAYER_SESSION_MUTE_MENU_ITEM = "Stummschalten (diese Session)",
	MUTE_PLAYER_SESSION_UNMUTE_MENU_ITEM = "Stummschaltung aufheben",
	MUTE_PLAYER_SESSION_MUTE = "Du hast [<<1>>] stummgeschaltet",
	MUTE_PLAYER_SHOW_LIST = "Stummgeschaltete Spieler: ",
	MUTE_PLAYER_MUTED_MESSAGE_DEFAULT = "Stummgeschaltet Nachricht",
	MUTE_PLAYER_MUTED = "Stumm geschaltet",
	MUTE_PLAYER_PLAYER_UNMUTED =  "[<<1>>] ist nicht mehr stummgeschaltet",
	MUTE_PLAYER_PLAYER_NOT_IN_LIST = "[<<1>>] ist aktuell nicht stummgeschaltet.",

	--LAM settings menu
	MUTE_PLAYER_LAM_OPTIONS = "Optionen",
	MUTE_PLAYER_LAM_CHAT_NOTIFY = "Im Chat benachrichtigen",
	MUTE_PLAYER_LAM_CHAT_NOTIFY_TT = "Ist diese Option aktiviert, so wird im Chat eine Nachricht angezeigt, wenn der stummgeschaltete Spieler eine Nachricht gesendet hat (ohne Inhalt dieser Nachricht).",
}

for id, stringVar in pairs(stringsDE) do
	SafeAddString(_G[id], stringVar, 1)
end