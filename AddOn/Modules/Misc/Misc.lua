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

-- Block PvP
hooksecurefunc('PVEFrame_ShowFrame', function(sidePanelName)
    if E.db.RhythmBox.Misc.BlockPvP and sidePanelName == 'PVPUIFrame' then
        PVEFrame_ShowFrame('GroupFinderFrame')
    end
end)

-- Set CVar
function M:ConfigCVar()
    -- Install.lua Part 1
    SetCVar('statusTextDisplay', 'BOTH')
	SetCVar('screenshotQuality', '10')
	SetCVar('showTutorials', '0')
	SetCVar('showNPETutorials', '0')
	SetCVar('UberTooltips', '1')
	SetCVar('threatWarning', '3')
	SetCVar('lockActionBars', '1')
	SetCVar('ActionButtonUseKeyDown', '1')
	SetCVar('fstack_preferParentKeys', '0')
    SetCVar('cameraDistanceMaxZoomFactor', '2.6')
    SetCVar('countdownForCooldowns', '1')

    -- Nameplates.lua
	SetCVar('nameplateLargerScale', '1')
	SetCVar('nameplateMaxAlpha', '1.0')
	SetCVar('nameplateMaxAlphaDistance', '40')
	SetCVar('nameplateMaxScale', '1.0')
	SetCVar('nameplateMaxScaleDistance', '40')
	SetCVar('nameplateMinAlpha', '0.9')
	SetCVar('nameplateMinAlphaDistance', '0')
	SetCVar('nameplateMinScale', '1.0')
	SetCVar('nameplateMinScaleDistance', '0')
	SetCVar('nameplateOccludedAlphaMult', '0.4')
	SetCVar('nameplateOtherAtBase', '0')
	SetCVar('nameplateSelectedAlpha', '1.0')
	SetCVar('nameplateSelectedScale', '1.15')
	SetCVar('nameplateSelfAlpha', '1.0')
	SetCVar('nameplateTargetBehindMaxDistance', '40')

    -- Install.lua Part 2
    SetCVar('chatMouseScroll', '1')
    SetCVar('chatStyle', 'classic')
    SetCVar('whisperMode', 'inline')
    SetCVar('wholeChatWindowClickable', '0')

    -- Commands.lua
    SetCVar('scriptErrors', '1')

    -- ActionBars.lua
    SetCVar('AutoPushSpellToActionBar', '0')
    SetCVar('enableMouseoverCast', '0')
    SetCVar('autoSelfCast', '1')

    -- Maps.lua
    SetCVar('minimapTrackingShowAll', '1')

    -- AFK.lua
    SetCVar('autoClearAFK', '1')

    -- Custom
    SetCVar('advancedCombatLogging', '1')
    SetCVar('alwaysCompareItems', '1')
    SetCVar('autoLootDefault', '1')
    SetCVar('CameraKeepCharacterCentered', '0')
    SetCVar('cameraPitchMoveSpeed', '45.000000')
    SetCVar('cameraSmoothStyle', '0')
    SetCVar('cameraYawMoveSpeed', '90.000000')
    SetCVar('missingTransmogSourceInItemTooltips', '1')
    SetCVar('overrideArchive', '0')
    SetCVar('Sound_EnableEmoteSounds', '0')
    SetCVar('Sound_EnablePositionalLowPassFilter', '0')
    SetCVar('Sound_MasterVolume', '0.100000')
    SetCVar('Sound_NumChannels', '128')
    SetCVar('SpellQueueWindow', '100')
    SetCVar('violenceLevel', '5')

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

do
    SetCVar('timeMgrUseMilitaryTime', '1')
end
