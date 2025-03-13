local R, E, L, V, P, G = unpack((select(2, ...)))
local M = R:NewModule('Misc')

-- Lua functions
local _G = _G

-- WoW API / Variables
local CinematicFinished = CinematicFinished
local IsShiftKeyDown = IsShiftKeyDown
local SetCVar = SetCVar

local CinematicFrame = CinematicFrame
local MovieFrame = MovieFrame
local PVEFrame_ShowFrame = PVEFrame_ShowFrame
local QuestMapFrame_ToggleShowDestination = QuestMapFrame_ToggleShowDestination

local Enum_CinematicType_GameMovie = Enum.CinematicType.GameMovie

-- fix LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS for zhCN
if GetLocale() == 'zhCN' then
    StaticPopupDialogs['LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS'] = {
        text = "针对此项活动，你的队伍人数已满，将被移出列表。",
        button1 = OKAY,
        timeout = 0,
        whileDead = 1,
    }
end

-- Block PvP
hooksecurefunc('PVEFrame_ShowFrame', function(sidePanelName)
    if E.db.RhythmBox.Misc.BlockPvP and sidePanelName == 'PVPUIFrame' then
        PVEFrame_ShowFrame('GroupFinderFrame')
    end
end)

-- Set CVar
function M:ConfigCVar()
    SetCVar('advancedCombatLogging', '1')
    SetCVar('alwaysCompareItems', '1')
    SetCVar('alwaysShowActionBars', '1')
    SetCVar('autoLootDefault', '1')
    SetCVar('cameraDistanceMaxZoomFactor', '2.6')
    SetCVar('CameraKeepCharacterCentered', '0')
    SetCVar('cameraPitchMoveSpeed', '45.000000')
    SetCVar('cameraSmoothStyle', '0')
    SetCVar('cameraYawMoveSpeed', '90.000000')
    SetCVar('chatStyle', 'classic')
    SetCVar('countdownForCooldowns', '1')
    SetCVar('missingTransmogSourceInItemTooltips', '1')

    SetCVar('nameplateLargerScale', '1.15')
    SetCVar('nameplateMaxScaleDistance', '40')
    SetCVar('nameplateMinAlpha', '0.9')
    SetCVar('nameplateMinScale', '1.0')
    SetCVar('nameplateMinScaleDistance', '0')
    SetCVar('nameplateMotion', '1')
    SetCVar('nameplateSelectedAlpha', '1')
    SetCVar('nameplateSelectedScale', '1.15')
    SetCVar('nameplateSelfAlpha', '1.0')
    SetCVar('nameplateShowAll', '1')
    SetCVar('nameplateShowDebuffsOnFriendly', '0')
    SetCVar('nameplateShowEnemyGuardians', '0')
    SetCVar('nameplateShowFriendlyNPCs', '0')
    SetCVar('nameplateShowOnlyNames', '1')
    SetCVar('nameplateShowSelf', '0')
    SetCVar('nameplateTargetBehindMaxDistance', '30')
    SetCVar('nameplateTargetRadialPosition', '1')

    SetCVar('overrideArchive', '0')
    SetCVar('screenshotQuality', '10')
    SetCVar('scriptErrors', '1')
    SetCVar('Sound_EnableEmoteSounds', '0')
    SetCVar('Sound_EnablePositionalLowPassFilter', '0')
    SetCVar('Sound_MasterVolume', '0.10000000149012')
    SetCVar('Sound_NumChannels', '128')
    SetCVar('SpellQueueWindow', '100')
    SetCVar('statusTextDisplay', 'BOTH')
    SetCVar('violenceLevel', '5')
    SetCVar('whisperMode', 'inline')

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
hooksecurefunc('QuestMapFrame_ShowQuestDetails', function()
    if (
        E.db.RhythmBox.Misc.ShowDestination and not IsShiftKeyDown() and
        _G.QuestMapFrame.DetailsFrame.DestinationMapButton:IsShown()
    ) then
        QuestMapFrame_ToggleShowDestination()
    end
end)

-- Raises the cap of the standard blizzard Equipment Manager to 20
-- from https://wago.io/r1GjIaUJf
---@diagnostic disable-next-line: inject-field
_G.MAX_EQUIPMENT_SETS_PER_PLAYER = 100

-- Fix The War Within login cinematic
do
    local frame = CreateFrame('Frame')
    frame:SetScript('OnEvent', function (_, _, movieID)
        if movieID == 1024 then
            CinematicFinished(Enum_CinematicType_GameMovie, true)
            MovieFrame:Hide()
            R:Print("已跳过开场动画。")
        end
        frame:UnregisterAllEvents()
    end)
    frame:RegisterEvent('PLAY_MOVIE')
end
