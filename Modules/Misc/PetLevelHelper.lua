local R, E, L, V, P, G = unpack((select(2, ...)))
local PLH = R:NewModule('PetLevelHelper', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local error, format, ipairs, pairs, tinsert = error, format, ipairs, pairs, tinsert
local table_concat = table.concat

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

local enableMap = {
    -- Player Leveling
    [2023] = { -- Ohn'ahran Plains
        197102, -- Bakhushek
    },
    -- Pet Leveling
    [582] = { -- Lunarfall
        79179, -- Squirt
    },
    [634] = { -- Stormheim
        105455, -- Trapper Jarrun
        98270, -- Robert Craig
    },
    [627] = { -- Dalaran
        97804, -- Tiffany Nelson
        -- 99182, -- Sir Galveston
        -- 107489, -- Amalia
    },
    [659] = { -- Stonedark Grotto
        104553, -- Odrogg
    },
}

local stopMacro = '/stopmacro [petbattle]'
local itemMacro = '/use item:184489'
local castMacroTemplate = '/cast %s'
local targetMacroTemplate = '/target %s'
local selectOptionMacro = '/run C_GossipInfo.SelectOptionByIndex(1)'

local spellName

local function DisplayButtonOnClick()
    PLH:Toggle()
end

function PLH:GetNPCName(npcID)
    local npcData = C_TooltipInfo_GetHyperlink('unit:Creature-0-0-0-0-' .. npcID)
    return npcData and npcData.lines and npcData.lines[1] and npcData.lines[1].leftText
end

function PLH:EnableHelper()
    if not spellName then
        local spellData = C_TooltipInfo_GetSpellByID(125439)
        spellName = spellData and spellData.lines and spellData.lines[1] and spellData.lines[1].leftText or spellName
    end

    if not spellName then
        error('Failed to fetch name of spell 125439')
    end

    local uiMapID = C_Map_GetBestMapForUnit('player')
    local npcIDs = enableMap[uiMapID]
    local targetMacros = {}

    for _, npcID in ipairs(npcIDs) do
        local npcName = self:GetNPCName(npcID)
        if not npcName then
            error('Failed to fetch name of npc ' .. npcID)
        end

        tinsert(targetMacros, format(targetMacroTemplate, npcName))
    end

    local macroText = format(
        '%s\n%s\n%s\n%s\n%s',
        stopMacro,
        E.mylevel >= 48 and itemMacro or '',
        format(castMacroTemplate, spellName),
        table_concat(targetMacros, '\n'),
        selectOptionMacro
    )

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
        self.enabled = nil

        self.displayButton.icon:SetDesaturated(true)
        self.displayButton.text:SetTextColor(1, 0, 0, 1)
        self.displayButton.text:SetText(DISABLE)
    else
        self:EnableHelper()
        self.enabled = true

        self.displayButton.icon:SetDesaturated(false)
        self.displayButton.text:SetTextColor(0, 1, 0, 1)
        self.displayButton.text:SetText(ENABLE)
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
    if enableMap[uiMapID] then
        self.displayButton:Show()

        if E.mylevel < GetMaxLevelForPlayerExpansion() then
            -- Player Leveling: default to enable
            self:EnableHelper()
            self.enabled = true

            self.displayButton.icon:SetDesaturated(false)
            self.displayButton.text:SetTextColor(0, 1, 0, 1)
            self.displayButton.text:SetText(ENABLE)
        else
            -- Pet Leveling: default to disable
            self:DisableHelper()
            self.enabled = nil

            self.displayButton.icon:SetDesaturated(true)
            self.displayButton.text:SetTextColor(1, 0, 0, 1)
            self.displayButton.text:SetText(DISABLE)
        end
    else
        -- not in enable map
        self:DisableHelper()
        self.enabled = nil

        -- hide display button and reset display
        self.displayButton:Hide()
        self.displayButton.icon:SetDesaturated(true)
        self.displayButton.text:SetTextColor(1, 0, 0, 1)
        self.displayButton.text:SetText(DISABLE)
    end
end

function PLH:Initialize()
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

    for _, npcIDs in pairs(enableMap) do
        for _, npcID in ipairs(npcIDs) do
            self:GetNPCName(npcID)
        end
    end

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateZone')
    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'UpdateZone')
end

R:RegisterModule(PLH:GetName())
