-- From: https://wago.io/HkUtqi7QQ
-- By: Permok

local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

-- Lua functions
local _G = _G
local C_Timer_After = C_Timer.After

-- WoW API / Variables
local C_AzeriteEmpoweredItem_SetHasBeenViewed = C_AzeriteEmpoweredItem.SetHasBeenViewed
local C_AzeriteEmpoweredItem_HasBeenViewed = C_AzeriteEmpoweredItem.HasBeenViewed
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemID = GetContainerItemID
local GetItemInfoFromHyperlink = GetItemInfoFromHyperlink
local hooksecurefunc = hooksecurefunc
local IsAddOnLoaded = IsAddOnLoaded
local UIParentLoadAddOn = UIParentLoadAddOn

local OpenAzeriteEmpoweredItemUIFromItemLocation = OpenAzeriteEmpoweredItemUIFromItemLocation

local NUM_BAG_SLOTS = NUM_BAG_SLOTS

local SAA = E:NewModule('RhythmBox_SkipAzeriteAnimation', 'AceEvent-3.0')

function SAA:ADDON_LOADED(_, addonName)
    if addonName == 'Blizzard_AzeriteUI' then
        self:UnregisterEvent('ADDON_LOADED')
        self:HookOnItemSet()
    end
end

function SAA:AZERITE_EMPOWERED_ITEM_LOOTED(_, item)
    local itemID = GetItemInfoFromHyperlink(item)

    C_Timer_After(0.4, function()
        local bag, slot
        for i = 0, NUM_BAG_SLOTS do
            for j = 1, GetContainerNumSlots(i) do
                local id = GetContainerItemID(i, j)
                if id and id == itemID then
                    bag = i
                    slot = j
                    break
                end
            end
        end

        if slot then
            local location = _G.ItemLocation:CreateFromBagAndSlot(bag, slot)
            C_AzeriteEmpoweredItem_SetHasBeenViewed(location)
            C_AzeriteEmpoweredItem_HasBeenViewed(location)
        end
    end)
end

function SAA:AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED(_, itemLocation)
    OpenAzeriteEmpoweredItemUIFromItemLocation(itemLocation)
end

function SAA:HookOnItemSet()
    hooksecurefunc(_G.AzeriteEmpoweredItemUI, 'OnItemSet', function(self)
        local itemLocation = self.azeriteItemDataSource:GetItemLocation()
        if self:IsAnyTierRevealing() then
            C_Timer_After(0.7, function()
                OpenAzeriteEmpoweredItemUIFromItemLocation(itemLocation)
            end)
        end
    end)
end

function SAA:Initialize()
    if not IsAddOnLoaded('Blizzard_AzeriteUI') then
        self:RegisterEvent('ADDON_LOADED')
        UIParentLoadAddOn('Blizzard_AzeriteUI')
    else
        self:HookOnItemSet()
    end

    self:RegisterEvent('AZERITE_EMPOWERED_ITEM_LOOTED')
    self:RegisterEvent('AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED')
end

local function InitializeCallback()
    SAA:Initialize()
end

E:RegisterModule(SAA:GetName(), InitializeCallback)
