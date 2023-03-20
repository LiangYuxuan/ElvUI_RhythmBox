local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')
local StdUi = LibStub('StdUi')

-- Lua functions
local _G = _G

-- WoW API / Variables
local STABLES = STABLES

-- GLOBALS: LibStub

local button, panel

function RI:PetTracker()
    -- Replace L in following code
    local L = LibStub('AceLocale-3.0'):GetLocale('PetTracker')

    _G.PetTracker.MapSearch.Init = E.noop

    button:Show()

    panel = StdUi:PanelWithTitle(button, 150, 130, "PetTracker")
    panel:ClearAllPoints()
    panel:SetPoint('TOP', button, 'BOTTOM', 0, -5)
    panel:Hide()

    local speciesCheckbox = StdUi:Checkbox(panel, L.Species)
    StdUi:GlueTop(speciesCheckbox, panel, 10, -40, 'LEFT')
    speciesCheckbox:SetChecked(not _G.PetTracker.sets.hideSpecies)
    speciesCheckbox.OnValueChanged = function(_, value)
        _G.PetTracker.sets.hideSpecies = not value
        _G.WorldMapFrame:OnMapChanged()
    end

    local searchEditbox = StdUi:SearchEditBox(panel, 130, 20, L.FilterSpecies)
    StdUi:GlueBelow(searchEditbox, speciesCheckbox, 0, -10, 'LEFT')
    searchEditbox.OnValueChanged = function(_, value)
        _G.PetTracker.MapSearch:SetText(value)
    end

    local stablesCheckbox = StdUi:Checkbox(panel, STABLES)
    StdUi:GlueBelow(stablesCheckbox, searchEditbox, 0, -10, 'LEFT')
    stablesCheckbox:SetChecked(not _G.PetTracker.sets.hideStables)
    stablesCheckbox.OnValueChanged = function(_, value)
        _G.PetTracker.sets.hideStables = not value
        _G.WorldMapFrame:OnMapChanged()
    end
end

do
    -- ElvUI workaround
    -- Creating button before skin loading to avoid lua error

    button = _G.WorldMapFrame:AddOverlayFrame(
        nil, 'Button', 'TOPRIGHT',
        _G.WorldMapFrame:GetCanvasContainer(), 'TOPRIGHT', -100, -2
    )
    button:SetSize(32, 32)
    button:SetFrameStrata('HIGH')
    button:SetHighlightTexture('Interface/Minimap/UI-Minimap-ZoomButton-Highlight', 'ADD')
    button:SetScript('OnClick', function()
        if panel:IsShown() then
            panel:Hide()
        else
            panel:Show()
        end
    end)
    button.Refresh = E.noop
    button:Hide()

    button.Background = button:CreateTexture(nil, 'BACKGROUND')
    button.Background:SetSize(25, 25)
    button.Background:ClearAllPoints()
    button.Background:SetPoint('TOPLEFT', 2, -4)
    button.Background:SetTexture('Interface/Minimap/UI-Minimap-Background')
    button.Background:SetVertexColor(1, 1, 1, 1)

    button.Icon = button:CreateTexture(nil, 'ARTWORK')
    button.Icon:SetSize(20, 20)
    button.Icon:ClearAllPoints()
    button.Icon:SetPoint('TOPLEFT', 6, -6)
    button.Icon:SetTexture(618973)

    button.Border = button:CreateTexture(nil, 'OVERLAY')
    button.Border:SetSize(54, 54)
    button.Border:ClearAllPoints()
    button.Border:SetPoint('TOPLEFT')
    button.Border:SetTexture('Interface/Minimap/MiniMap-TrackingBorder')
end

RI:RegisterInjection(RI.PetTracker, 'PetTracker')
