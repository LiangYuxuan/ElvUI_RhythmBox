local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G
local ipairs, unpack = ipairs, unpack
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
    end)
end

RI:RegisterPipeline(NaowhUI)
