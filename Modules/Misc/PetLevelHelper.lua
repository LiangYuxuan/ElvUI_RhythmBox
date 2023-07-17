local R, E, L, V, P, G = unpack((select(2, ...)))
local PLH = R:NewModule('PetLevelHelper', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local format = format

-- WoW API / Variables
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_TooltipInfo_GetHyperlink = C_TooltipInfo.GetHyperlink
local C_TooltipInfo_GetSpellByID = C_TooltipInfo.GetSpellByID
local ClearOverrideBindings = ClearOverrideBindings
local CreateFrame = CreateFrame
local GetMaxLevelForPlayerExpansion = GetMaxLevelForPlayerExpansion
local InCombatLockdown = InCombatLockdown
local SetOverrideBinding = SetOverrideBinding
local SetCVar = SetCVar

local DISABLE = DISABLE
local ENABLE = ENABLE

local npcID = 197102 -- Bakhushek
local mapID = 2023 -- Ohn'ahran Plains

local itemMacro = '/use item:184489'
local basicMacro = '/cast %s\n/target %s\n/run C_GossipInfo.SelectOptionByIndex(1)'

local npcName
local spellName

local function DisplayButtonOnClick()
    PLH:Toggle()
end

function PLH:FetchName()
    local npcData = C_TooltipInfo_GetHyperlink('unit:Creature-0-0-0-0-' .. npcID)
    npcName = npcData and npcData.lines and npcData.lines[1] and npcData.lines[1].leftText or npcName

    local spellData = C_TooltipInfo_GetSpellByID(125439)
    spellName = spellData and spellData.lines and spellData.lines[1] and spellData.lines[1].leftText or spellName
end

function PLH:EnableHelper()
    if not npcName or not spellName then
        self:FetchName()
    end

    if not npcName or not spellName then
        R.ErrorHandler('Failed to fetch npcName or spellName')
    end

    local macroText = format(basicMacro, spellName, npcName)

    if E.mylevel >= 48 then
        macroText = itemMacro .. '\n' .. macroText
    end

    self.macroButton:SetAttribute('macrotext', macroText)

    ClearOverrideBindings(self.macroButton)
    SetOverrideBinding(self.macroButton, true, '8', 'CLICK RhythmBoxPLHMacro:LeftButton')
    SetOverrideBinding(self.macroButton, true, '9', 'INTERACTTARGET')
    SetOverrideBinding(self.macroButton, true, '0', 'CLICK tdBattlePetScriptAutoButton:LeftButton')

    SetCVar('autoInteract', 1)
end

function PLH:DisableHelper()
    SetCVar('autoInteract', 0)
    ClearOverrideBindings(self.macroButton)
end

function PLH:Toggle()
    if self.enabled then
        self:DisableHelper()
        self.displayButton.icon:SetDesaturated(true)
        self.displayButton.text:SetTextColor(1, 0, 0, 1)
        self.displayButton.text:SetText(DISABLE)
        self.enabled = nil
    else
        self:EnableHelper()
        self.displayButton.icon:SetDesaturated(false)
        self.displayButton.text:SetTextColor(0, 1, 0, 1)
        self.displayButton.text:SetText(ENABLE)
        self.enabled = true
    end
end

function PLH:UpdateZone(event)
    if InCombatLockdown() then
        self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateZone')
        return
    end

    if event == 'PLAYER_REGEN_ENABLED' then
        self:UnregisterEvent('PLAYER_REGEN_ENABLED')
    elseif event == 'PLAYER_ENTERING_WORLD' then
        SetCVar('autoInteract', 0)
    end

    local uiMapID = C_Map_GetBestMapForUnit('player')
    if uiMapID == mapID then
        -- enableing error might be error
        -- display button early to allow user retry
        self.displayButton:Show()

        self:EnableHelper()

        self.displayButton.icon:SetDesaturated(false)
        self.displayButton.text:SetTextColor(0, 1, 0, 1)
        self.displayButton.text:SetText(ENABLE)
        self.enabled = true
    else
        self:DisableHelper()

        self.displayButton:Hide()
        self.displayButton.icon:SetDesaturated(true)
        self.displayButton.text:SetTextColor(1, 0, 0, 1)
        self.displayButton.text:SetText(DISABLE)
        self.enabled = nil
    end
end

function PLH:Initialize()
    if E.mylevel >= GetMaxLevelForPlayerExpansion() then
        SetCVar('autoInteract', 0)
        return
    end

    local macroButton = CreateFrame('Button', 'RhythmBoxPLHMacro', E.UIParent, 'SecureActionButtonTemplate')
    macroButton:EnableMouse(true)
    macroButton:RegisterForClicks('AnyUp', 'AnyDown')
    macroButton:SetAttribute('type', 'macro')
    self.macroButton = macroButton

    local display = CreateFrame('Button', nil, E.UIParent)
    display:SetScript('OnClick', DisplayButtonOnClick)
    display:ClearAllPoints()
    display:SetPoint('CENTER', -300, -350)
    display:SetSize(64, 64)
    display:SetTemplate('Default')
    display:StyleButton()
    display:EnableMouse(true)
    self.displayButton = display

    display.icon = display:CreateTexture(nil, 'OVERLAY')
    display.icon:SetInside(display, 2, 2)
    display.icon:SetTexCoord(.1, .9, .1, .9)
    display.icon:SetTexture(644389)
    display.icon:SetDesaturated(true)

    display.text = display:CreateFontString(nil, 'OVERLAY')
    display.text:FontTemplate(nil, 24, 'OUTLINE')
    display.text:SetTextColor(1, 0, 0, 1)
    display.text:SetPoint('TOP', display, 'BOTTOM', 0, -2)
    display.text:SetJustifyH('CENTER')
    display.text:SetText(DISABLE)

    self:FetchName()

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateZone')
    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'UpdateZone')
end

R:RegisterModule(PLH:GetName())
