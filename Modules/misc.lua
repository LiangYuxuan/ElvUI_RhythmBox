if GetLocale() == "zhCN" then
	StaticPopupDialogs["LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS"] = {
		text = "针对此项活动，你的队伍人数已满，将被移出列表。",
		button1 = OKAY,
		timeout = 0,
		whileDead = 1,
	}
end
