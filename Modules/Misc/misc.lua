local R, E, L, V, P, G = unpack(select(2, ...))

if GetLocale() == 'zhCN' then
    StaticPopupDialogs["LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS"] = {
        text = "针对此项活动，你的队伍人数已满，将被移出列表。",
        button1 = OKAY,
        timeout = 0,
        whileDead = 1,
    }
end

-- 参与《魔兽世界》任何形式的PvP活动是我在玩这款游戏里做得最错的事情。
-- 谨此铭刻于心

PVEFrameTab2:SetScript('OnClick', E.noop)

-- block function call showing
hooksecurefunc('PVEFrame_ShowFrame', function(sidePanelName, selection)
    if sidePanelName == 'PVPUIFrame' then
        PVEFrame_ShowFrame('GroupFinderFrame')
    end
end)
