local R, E, L, V, P, G = unpack(select(2, ...))

if GetLocale() == 'zhCN' and not R.Classic then
    StaticPopupDialogs["LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS"] = {
        text = "针对此项活动，你的队伍人数已满，将被移出列表。",
        button1 = OKAY,
        timeout = 0,
        whileDead = 1,
    }
end

-- CVar list
if false then
    SetCVar('overrideArchive', 0)
    SetCVar('profanityFilter', 0)

    SetCVar('cameraDistanceMaxZoomFactor', 2.6)
    SetCVar('violenceLevel', 5)
    SetCVar('ffxGlow', 1)
    SetCVar('ffxDeath', 1)
    SetCVar('ffxNether', 1)

    SetCVar('alwaysCompareItems', 1)

    if R.Retail then
        SetCVar('showQuestTrackingTooltips', 1)
        SetCVar('missingTransmogSourceInItemTooltips', 1)
    else
        SetCVar('chatClassColorOverride', 0)
    end
end

-- 参与《魔兽世界》任何形式的PvP活动是我在玩这款游戏里做得最错的事情。
-- 谨此铭刻于心

-- 如何让玩家玩PvP：把强大的奖励放进PvP的奖励里面。

--[[
PVEFrameTab2:SetScript('OnClick', E.noop)

-- block function call showing
hooksecurefunc('PVEFrame_ShowFrame', function(sidePanelName, selection)
    if sidePanelName == 'PVPUIFrame' then
        PVEFrame_ShowFrame('GroupFinderFrame')
    end
end)
]]--
