local R, E, L, V, P, G = unpack((select(2, ...)))
local PLH = R:NewModule('PetLevelHelper', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions

-- WoW API / Variables
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local ClearOverrideBindings = ClearOverrideBindings
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local SetOverrideBinding = SetOverrideBinding
local SetCVar = SetCVar

local macroText = [[
/use 法夜竖琴
/施放 复活战斗宠物(战斗宠物)
/target 巴库歇克
/script SelectGossipOption(2)
/click tdBattlePetScriptAutoButton
]]

function PLH:EnableHelper()
    SetCVar('autointeract', 1)
    SetOverrideBinding(self.button, true, '8', 'CLICK RhythmBoxPLHMacro:LeftButton')
    SetOverrideBinding(self.button, true, '9', 'INTERACTTARGET')

    self.enabled = true
end

function PLH:DisableHelper()
    SetCVar('autointeract', 0)
    ClearOverrideBindings(self.button)

    self.enabled = nil
end

function PLH:Toggle(event)
    if InCombatLockdown() then return end

    if event == 'PLAYER_ENTERING_WORLD' then
        SetCVar('autointeract', 0)
    end

    local uiMapID = C_Map_GetBestMapForUnit('player')
    if E.mylevel < 70 and E.myrealm ~= 'Illidan' and uiMapID == 2023 and not self.enabled then
        self:EnableHelper()
    elseif self.enabled then
        self:DisableHelper()
    end
end

function PLH:Initialize()
    local button = CreateFrame('Button', 'RhythmBoxPLHMacro', E.UIParent, 'SecureActionButtonTemplate')
    button:EnableMouse(true)
    button:RegisterForClicks('AnyUp')
    button:SetAttribute('type', 'macro')
    button:SetAttribute('macrotext', macroText)
    self.button = button

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'Toggle')
    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'Toggle')
end

-- R:RegisterModule(PLH:GetName())
