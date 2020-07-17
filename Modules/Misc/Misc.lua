local R, E, L, V, P, G = unpack(select(2, ...))
local M = R:NewModule('Misc')

-- Lua functions
local _G = _G

-- WoW API / Variables
local IsShiftKeyDown = IsShiftKeyDown
local SetCVar = SetCVar

local CinematicFrame = CinematicFrame
local FCF_GetCurrentChatFrame = FCF_GetCurrentChatFrame
local MovieFrame = MovieFrame
local PVEFrame_ShowFrame = PVEFrame_ShowFrame
local QuestMapFrame_ToggleShowDestination = QuestMapFrame_ToggleShowDestination

-- fix LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS for zhCN
if R.Retail and GetLocale() == 'zhCN' then
    StaticPopupDialogs['LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS'] = {
        text = "针对此项活动，你的队伍人数已满，将被移出列表。",
        button1 = OKAY,
        timeout = 0,
        whileDead = 1,
    }
end

-- Block PvP
if R.Retail then
    hooksecurefunc('PVEFrame_ShowFrame', function(sidePanelName)
        if E.db.RhythmBox.Misc.BlockPvP and sidePanelName == 'PVPUIFrame' then
            PVEFrame_ShowFrame('GroupFinderFrame')
        end
    end)
end

-- profanityFilter workaround
do
    C_Timer.After(10, function()
        SetCVar('portal', 'TW')
        SetCVar('profanityFilter', 0)
    end)
end

-- Set CVar
function M:ConfigCVar()
    SetCVar('SpellQueueWindow', 100)
    SetCVar('overrideArchive', 0)
    -- SetCVar('profanityFilter', 0)

    SetCVar('violenceLevel', 5)
    SetCVar('ffxGlow', 1)
    SetCVar('ffxDeath', 1)
    SetCVar('ffxNether', 1)
    SetCVar('cameraDistanceMaxZoomFactor', 2.6)
    SetCVar('cameraSmoothStyle', 4)
    SetCVar('cameraYawMoveSpeed', 180)
    SetCVar('cameraPitchMoveSpeed', 90)

    SetCVar('autoLootDefault', 1)
    SetCVar('alwaysCompareItems', 1)

    E:GetModule('NamePlates'):CVarReset()
    SetCVar('nameplateLargerScale', 1.15)
    SetCVar("nameplateSelectedScale", 1.1)

    -- from ElvUI Install
    SetCVar('statusTextDisplay', 'BOTH')
    SetCVar('screenshotQuality', 10)
    SetCVar('chatMouseScroll', 1)
    SetCVar('chatStyle', 'classic')
    SetCVar('wholeChatWindowClickable', 0)
    SetCVar('showTutorials', 0)
    SetCVar('UberTooltips', 1)
    SetCVar('alwaysShowActionBars', 1)
    SetCVar('lockActionBars', 1)
    SetCVar('spamFilter', 0)

    -- from https://www.mmo-champion.com/threads/2370808-Details-of-the-7-3-5-sound-issue-(from-DBM-lead-MysticalOS)
    SetCVar('Sound_NumChannels', 128)

    _G.InterfaceOptionsActionBarsPanelPickupActionKeyDropDown:SetValue('SHIFT')
    _G.InterfaceOptionsActionBarsPanelPickupActionKeyDropDown:RefreshValue()

    if R.Retail then
        SetCVar('threatWarning', 3)
        SetCVar('showQuestTrackingTooltips', 1)
        SetCVar('missingTransmogSourceInItemTooltips', 1)
        SetCVar('fstack_preferParentKeys', 0) --Add back the frame names via fstack!
    else
        SetCVar('chatClassColorOverride', 0)
        SetCVar("colorChatNamesByClass", 1)
    end

    R:Print("已设置CVar。")
end

-- Faster movie skip
-- Allow space bar, escape key and enter key to cancel cinematic without confirmation
CinematicFrame:HookScript('OnKeyDown', function(self, key)
    if E.db.RhythmBox.Misc.FasterMovieSkip and key == 'ESCAPE' then
        if CinematicFrame:IsShown() and CinematicFrame.closeDialog and _G.CinematicFrameCloseDialogConfirmButton then
            _G.CinematicFrameCloseDialog:Hide()
        end
    end
end)
CinematicFrame:HookScript('OnKeyUp', function(self, key)
    if E.db.RhythmBox.Misc.FasterMovieSkip and (key == 'SPACE' or key == 'ESCAPE' or key == 'ENTER') then
        if CinematicFrame:IsShown() and CinematicFrame.closeDialog and _G.CinematicFrameCloseDialogConfirmButton then
            _G.CinematicFrameCloseDialogConfirmButton:Click()
        end
    end
end)
MovieFrame:HookScript('OnKeyUp', function(self, key)
    if E.db.RhythmBox.Misc.FasterMovieSkip and (key == 'SPACE' or key == 'ESCAPE' or key == 'ENTER') then
        if MovieFrame:IsShown() and MovieFrame.CloseDialog and MovieFrame.CloseDialog.ConfirmButton then
            MovieFrame.CloseDialog.ConfirmButton:Click()
        end
    end
end)

-- Always show destination
if R.Retail then
    hooksecurefunc('QuestMapFrame_ShowQuestDetails', function()
        if E.db.RhythmBox.Misc.ShowDestination and not IsShiftKeyDown() and _G.QuestMapFrame.DetailsFrame.DestinationMapButton:IsShown() then
            QuestMapFrame_ToggleShowDestination()
        end
    end)
end

-- raises the cap of the standard blizzard Equipment Manager to 20
-- from https://wago.io/r1GjIaUJf
_G.MAX_EQUIPMENT_SETS_PER_PLAYER = 100
