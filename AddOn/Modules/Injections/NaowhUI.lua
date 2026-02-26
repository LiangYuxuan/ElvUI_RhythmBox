local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')
local AB = E:GetModule('ActionBars')
local DT = E:GetModule('DataTexts')

-- Lua functions
local _G = _G
local ipairs, unpack = ipairs, unpack
local hooksecurefunc = hooksecurefunc
local string_match = string.match

-- WoW API / Variables
local C_EditMode_GetLayouts = C_EditMode.GetLayouts
local C_EditMode_SetActiveLayout = C_EditMode.SetActiveLayout
local CreateFrame = CreateFrame

-- luacheck: globals Enum.EditModePresetLayoutsMeta.NumValues
local Enum_EditModePresetLayoutsMeta_NumValues = Enum.EditModePresetLayoutsMeta.NumValues

local classSpecMap = {
    {
        -- Warrior
        'Arms',
        'Fury',
        'Protection',
    },
    {
        -- Paladin
        'Holy',
        'Protection',
        'Retribution',
    },
    {
        -- Hunter
        'Beast Mastery',
        'Marksmanship',
        'Survival',
    },
    {
        -- Rogue
        'Assassination',
        'Outlaw',
        'Subtlety',
    },
    {
        -- Priest
        'Discipline',
        'Holy',
        'Shadow',
    },
    {
        -- Death Knight
        'Blood',
        'Frost',
        'Unholy',
    },
    {
        -- Shaman
        'Elemental',
        'Enhancement',
        'Restoration',
    },
    {
        -- Mage
        'Arcane',
        'Fire',
        'Frost',
    },
    {
        -- Warlock
        'Affliction',
        'Demonology',
        'Destruction',
    },
    {
        -- Monk
        'Brewmaster',
        'Mistweaver',
        'Windwalker',
    },
    {
        -- Druid
        'Balance',
        'Feral',
        'Guardian',
        'Restoration',
    },
    {
        -- Demon Hunter
        'Havoc',
        'Vengeance',
        'Devourer',
    },
    {
        -- Evoker
        'Devastation',
        'Preservation',
        'Augmentation',
    },
}

local bars = {
    'bar1',
    'bar2',
    'bar3',
    'bar4',
    'bar5',
    'bar6',
}

local basicBars = {
    'bar1',
    'bar2',
    'bar3',
    'bar4',
    'bar5',
    'bar6',
    'barPet',
    'stanceBar',
}

local function LoadEditModeLayout(layoutInfo)
    if not layoutInfo.layouts[layoutInfo.activeLayout] then return end

    if layoutInfo.layouts[layoutInfo.activeLayout].layoutName == 'Naowh' then
        return
    end

    for index, layout in ipairs(layoutInfo.layouts) do
        if layout.layoutName == 'Naowh' then
            C_EditMode_SetActiveLayout(Enum_EditModePresetLayoutsMeta_NumValues + index)
        end
    end
end

local function TweakElvUIProfile()
    for _, bar in ipairs(basicBars) do
        local barConfig = E.db.actionbar[bar]

        barConfig.backdrop = false
        barConfig.buttonSize = 36
        barConfig.buttonSpacing = 1
        barConfig.enabled = true
        barConfig.mouseover = false
    end

    E.db.actionbar.barPet.buttons = 10
    E.db.actionbar.barPet.buttonsPerRow = 10
    E.db.actionbar.barPet.point = 'BOTTOMLEFT'

    E.db.actionbar.stanceBar.buttons = 10
    E.db.actionbar.stanceBar.buttonsPerRow = 10
    E.db.actionbar.stanceBar.point = 'BOTTOMLEFT'

    for _, bar in ipairs(bars) do
        local barConfig = E.db.actionbar[bar]

        barConfig.buttons = 12
        barConfig.macrotext = true
        barConfig.macroTextPosition = 'BOTTOM'
        barConfig.macroTextYOffset = 0
        barConfig.targetReticle = true
    end

    E.db.actionbar.bar1.buttonsPerRow = 12
    E.db.actionbar.bar1.point = 'BOTTOMLEFT'
    E.db.actionbar.bar1.showGrid = true

    E.db.actionbar.bar2.buttonsPerRow = 12
    E.db.actionbar.bar2.point = 'BOTTOMLEFT'
    E.db.actionbar.bar2.showGrid = false

    E.db.actionbar.bar3.buttonsPerRow = 6
    E.db.actionbar.bar3.point = 'BOTTOMLEFT'
    E.db.actionbar.bar3.showGrid = true

    E.db.actionbar.bar4.buttonsPerRow = 1
    E.db.actionbar.bar4.point = 'TOPLEFT'
    E.db.actionbar.bar4.showGrid = false

    E.db.actionbar.bar5.buttonsPerRow = 12
    E.db.actionbar.bar5.point = 'BOTTOMLEFT'
    E.db.actionbar.bar5.showGrid = true

    E.db.actionbar.bar6.buttonsPerRow = 6
    E.db.actionbar.bar6.point = 'BOTTOMLEFT'
    E.db.actionbar.bar6.showGrid = true

    AB:UpdateButtonSettings()

    _G.ElvAB_1:ClearAllPoints()
    _G.ElvAB_1:SetPoint('BOTTOM', E.UIParent, 'BOTTOM', 0, 1)
    E:SaveMoverPosition(_G.ElvAB_1.name)

    _G.ElvAB_2:ClearAllPoints()
    _G.ElvAB_2:SetPoint('BOTTOM', E.UIParent, 'BOTTOM', 0, 75)
    E:SaveMoverPosition(_G.ElvAB_2.name)

    _G.ElvAB_3:ClearAllPoints()
    _G.ElvAB_3:SetPoint('BOTTOM', E.UIParent, 'BOTTOM', -335, 1)
    E:SaveMoverPosition(_G.ElvAB_3.name)

    _G.ElvAB_4:ClearAllPoints()
    _G.ElvAB_4:SetPoint('TOPRIGHT', E.UIParent, 'TOPRIGHT', 0, -500)
    E:SaveMoverPosition(_G.ElvAB_4.name)

    _G.ElvAB_5:ClearAllPoints()
    _G.ElvAB_5:SetPoint('BOTTOM', E.UIParent, 'BOTTOM', 0, 38)
    E:SaveMoverPosition(_G.ElvAB_5.name)

    _G.ElvAB_6:ClearAllPoints()
    _G.ElvAB_6:SetPoint('BOTTOM', E.UIParent, 'BOTTOM', 335, 1)
    E:SaveMoverPosition(_G.ElvAB_6.name)

    _G.PetAB:ClearAllPoints()
    _G.PetAB:SetPoint('BOTTOM', E.UIParent, 'BOTTOM', 0, 112)
    E:SaveMoverPosition(_G.PetAB.name)

    _G.ShiftAB:ClearAllPoints()
    _G.ShiftAB:SetPoint('BOTTOM', E.UIParent, 'BOTTOM', -335, 75)
    E:SaveMoverPosition(_G.ShiftAB.name)

    _G.ABSlotItemAnchorMover:ClearAllPoints()
    _G.ABSlotItemAnchorMover:SetPoint('BOTTOMRIGHT', E.UIParent, 'BOTTOMRIGHT', -560, 242)
    E:SaveMoverPosition(_G.ABSlotItemAnchorMover.name)

    _G.ABQuestItemAnchorMover:ClearAllPoints()
    _G.ABQuestItemAnchorMover:SetPoint('BOTTOMRIGHT', E.UIParent, 'BOTTOMRIGHT', -560, 200)
    E:SaveMoverPosition(_G.ABQuestItemAnchorMover.name)

    _G.RhythmBoxQuickMacroContainerMover:ClearAllPoints()
    _G.RhythmBoxQuickMacroContainerMover:SetPoint('BOTTOMRIGHT', E.UIParent, 'BOTTOMRIGHT', -560, 158)
    E:SaveMoverPosition(_G.RhythmBoxQuickMacroContainerMover.name)

    local panelName = 'TopPanel'
    if not E.db.datatexts.panels[panelName] then
        E.db.datatexts.panels[panelName] = { enable = true, battleground = false }
    end

    local panelProfile = E.db.datatexts.panels[panelName]
    panelProfile.enable = true
    panelProfile[1] = 'LDB_EventTimetable'
    panelProfile[2] = 'Combat'
    panelProfile[3] = 'Target Range'
    panelProfile[4] = 'Coords'
    panelProfile[5] = 'Time'

    if not E.global.datatexts.customPanels[panelName] then
        E.global.datatexts.customPanels[panelName] = E:CopyTable({}, G.datatexts.newPanelInfo)

        local panelGlobal = E.global.datatexts.customPanels[panelName]
        panelGlobal.width = 500
        panelGlobal.numPoints = 5
        panelGlobal.tooltipAnchor = 'ANCHOR_BOTTOM'
        panelGlobal.tooltipXOffset = 0
        panelGlobal.tooltipYOffset = -4
        panelGlobal.fonts.enable = true
        panelGlobal.name = panelName

        DT:SetupPanelOptions(panelName)
        DT:BuildPanelFrame(panelName)
    else
        DT:UpdatePanelAttributes(panelName, E.global.datatexts.customPanels[panelName])
    end

    local panelMover = _G['DTPanel' .. panelName .. 'Mover']
    panelMover:ClearAllPoints()
    panelMover:SetPoint('TOPLEFT', E.UIParent, 'TOPLEFT', 0, 0)
    E:SaveMoverPosition(panelMover.name)

    E.db.bags.bankCombined = true
    E.db.general.autoRepair = 'GUILD'
    E.db.general.itemLevel.showItemLevel = false
    E.db.chat.timeStampFormat = '%H:%M:%S '
end

local function HookSetupElvUI(_, import)
    if import then
        TweakElvUIProfile()
    end
end

local function NaowhUI()
    R:RegisterAddOnLoad('NaowhUI', function()
        local NUI = unpack(_G.NaowhUI)
        local SE = NUI:GetModule('Setup')

        NUI.IsTokenValid = function()
            return true
        end

        local eventFrame = CreateFrame('Frame')
        eventFrame:RegisterEvent('EDIT_MODE_LAYOUTS_UPDATED')
        eventFrame:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
        eventFrame:SetScript('OnEvent', function(self, event, layoutInfo)
            if event == 'EDIT_MODE_LAYOUTS_UPDATED' then
                LoadEditModeLayout(layoutInfo)
            elseif event == 'PLAYER_SPECIALIZATION_CHANGED' then
                LoadEditModeLayout(C_EditMode_GetLayouts())
            end
        end)
        LoadEditModeLayout(C_EditMode_GetLayouts())

        local originalClassCooldowns = SE.ClassCooldowns
        SE.ClassCooldowns = function(addon, import, ...)
            if import then
                local layoutManager = _G.CooldownViewerSettings:GetLayoutManager()
                local currentSpecTag = layoutManager:GetCurrentSpecTag()
                for layoutID in layoutManager:EnumerateLayouts() do
                    layoutManager:RemoveLayout(layoutID)
                end

                local result = originalClassCooldowns(addon, import, ...)

                local specNames = classSpecMap[E.myClassID]
                for _, layout in layoutManager:EnumerateLayouts() do
                    for specIndex, specName in ipairs(specNames) do
                        if string_match(layout.layoutName, specName) then
                            local specTag = E.myClassID * 10 + specIndex
                            layoutManager:SetPreviouslyActiveLayoutByName(layout.layoutName, specTag)

                            if specTag == currentSpecTag then
                                layoutManager:SetActiveLayout(layout)
                            end
                        end
                    end
                end

                layoutManager:SaveLayouts()

                return result
            else
                return originalClassCooldowns(addon, import, ...)
            end
        end

        hooksecurefunc(SE, 'ElvUI', HookSetupElvUI)
    end)
end

RI:RegisterPipeline(NaowhUI)
