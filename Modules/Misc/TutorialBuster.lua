-- Modified from https://github.com/VahnRPG/TutorialBuster

local R, E, L, V, P, G = unpack((select(2, ...)))
local TB = R:NewModule('TutorialBuster', 'AceEvent-3.0')

-- Lua functions
local ipairs, pairs = ipairs, pairs

-- WoW API / Variables
local C_CVar_SetCVar = C_CVar.SetCVar
local C_CVar_SetCVarBitfield = C_CVar.SetCVarBitfield

local NUM_LE_FRAME_TUTORIAL_ACCCOUNTS = NUM_LE_FRAME_TUTORIAL_ACCCOUNTS
local NUM_LE_FRAME_TUTORIALS = NUM_LE_FRAME_TUTORIALS

local MAX_BIT_FLAGS_TUTORIAL = 4294934528
local cvarFieldsSpecial = {
    ['orderHallMissionTutorial']    = MAX_BIT_FLAGS_TUTORIAL,
    ['lastGarrisonMissionTutorial'] = MAX_BIT_FLAGS_TUTORIAL,
    ['azeriteEssenceSwapTutorial']  = 2,
}

local cvarFields = {
	'shipyardMissionTutorialFirst',
	'shipyardMissionTutorialBlockade',
	'shipyardMissionTutorialAreaBuff',
	'lastVoidStorageTutorial',
}

function TB:PLAYER_ENTERING_WORLD()
    for i = 1, NUM_LE_FRAME_TUTORIAL_ACCCOUNTS do
        C_CVar_SetCVarBitfield('closedInfoFramesAccountWide', i, true)
    end

    for i = 1, NUM_LE_FRAME_TUTORIALS do
        C_CVar_SetCVarBitfield('closedInfoFrames', i, true)
    end

    for _, cvar in ipairs(cvarFields) do
        C_CVar_SetCVar(cvar, '1')
    end

    for cvar, value in pairs(cvarFieldsSpecial) do
        C_CVar_SetCVar(cvar, value)
    end
end

function TB:Initialize()
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
end

R:RegisterModule(TB:GetName())
