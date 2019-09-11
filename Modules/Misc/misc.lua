local R, E, L, V, P, G = unpack(select(2, ...))
local M = E:NewModule('RhythmBox_Misc')

-- fix LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS for zhCN
if GetLocale() == 'zhCN' and R.Retail then
    StaticPopupDialogs["LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS"] = {
        text = "针对此项活动，你的队伍人数已满，将被移出列表。",
        button1 = OKAY,
        timeout = 0,
        whileDead = 1,
    }
end

-- Block PvP
if R.Retail then
    -- block tab button click showing
    hooksecurefunc('PVEFrame_TabOnClick', function(self)
        if self:GetID() == 2 then
            PVEFrame_ShowFrame('GroupFinderFrame')
        end
    end)

    -- block function call showing
    hooksecurefunc('PVEFrame_ShowFrame', function(sidePanelName, selection)
        if sidePanelName == 'PVPUIFrame' then
            PVEFrame_ShowFrame('GroupFinderFrame')
        end
    end)
end

function M:ConfigCVar()
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
