local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G
local ipairs = ipairs

-- WoW API / Variables
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UIDropDownMenu_AddSeparator = UIDropDownMenu_AddSeparator
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo

local STABLES = STABLES

-- GLOBALS: LibStub

local function hookDropDownMenu(overlayFrame)
    -- Constants
    local SHOW_SPECIES = 'ptHideSpecies'
    local SHOW_STABLES = 'ptHideStables'

    -- Replace L in following code
    local L = LibStub('AceLocale-3.0'):GetLocale('PetTracker')

    hooksecurefunc(overlayFrame, 'InitializeDropDown', function(self)
        local function OnSelection(button)
            self:OnSelection(button.value, button.checked)
        end

        UIDropDownMenu_AddSeparator()
        local info = UIDropDownMenu_CreateInfo()

        info.isTitle = true
        info.notCheckable = true
        info.text = "PetTracker"

        UIDropDownMenu_AddButton(info)
        info.text = nil

        info.isTitle = nil
        info.disabled = nil
        info.notCheckable = nil
        info.isNotRadio = true
        info.keepShownOnClick = true
        info.func = OnSelection

        info.text = L.Species
        info.value = SHOW_SPECIES
        info.checked = not _G.PetTracker.sets.hideSpecies
        UIDropDownMenu_AddButton(info)

        info.text = STABLES
        info.value = SHOW_STABLES
        info.checked = not _G.PetTracker.sets.hideStables
        UIDropDownMenu_AddButton(info)
    end)

    local origOverlayFrame_onSelection = overlayFrame.OnSelection
    overlayFrame.OnSelection = function(self, value, checked)
        if (value == SHOW_SPECIES) then
            _G.PetTracker.sets.hideSpecies = not checked
            _G.PetTracker.MapSearch:UpdateBoxes()
            _G.PetTracker.MapCanvas:UpdateAll()
        elseif (value == SHOW_STABLES) then
            _G.PetTracker.sets.hideStables = not checked
            _G.PetTracker.MapSearch:UpdateBoxes()
            _G.PetTracker.MapCanvas:UpdateAll()
        end
        origOverlayFrame_onSelection(self, value, checked)
    end
end

function RI:PetTracker()
    -- Replace L in following code
    local L = LibStub('AceLocale-3.0'):GetLocale('PetTracker')

    _G.PetTracker.MapSearch.Init = function(self, frame)
        if self.Frames[frame] or not frame.overlayFrames then
            return
        end

        for _, overlay in ipairs(frame.overlayFrames) do
            if overlay.OnClick == _G.WorldMapTrackingOptionsButtonMixin.OnClick and overlay:IsObjectType('Button') then
                local search = CreateFrame('EditBox', '$parentPetTrackerSearch', overlay, 'SearchBoxTemplate')
                search.Instructions:SetText(L.FilterPets)
                search:SetScript('OnTextChanged', function() self:SetTextFilter(search:GetText()) end)
                search:HookScript('OnEditFocusGained', function() self:ShowSuggestions(search) end)
                search:HookScript('OnEditFocusLost', function() self:HideSuggestions() end)
                search:SetPoint('RIGHT', overlay, 'LEFT', 0, 1)
                search:SetSize(128, 20)

                -- overlay:SetScript('OnMouseDown', function() self:ToggleTrackingTypes(overlay) end)
                hookDropDownMenu(overlay)

                self.Frames[frame] = search
                self:UpdateBox(frame)
            end
        end
    end
end

RI:RegisterInjection(RI.PetTracker, 'PetTracker')
