-- From ProjectAzilroka
-- https://git.tukui.org/Azilroka/ProjectAzilroka/blob/master/Modules/FasterLoot.lua

local R, E, L, V, P, G = unpack((select(2, ...)))
local FL = R:NewModule('FastLoot', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local select = select

-- WoW API / Variables
local C_Container_GetBagName = C_Container.GetBagName
local EquipItemByName = EquipItemByName
local GetCVarBool = GetCVarBool
local GetItemInfo = GetItemInfo
local GetLootSlotLink = GetLootSlotLink
local GetNumLootItems = GetNumLootItems
local IsModifiedClick = IsModifiedClick
local LootSlot = LootSlot

local NUM_BAG_SLOTS = NUM_BAG_SLOTS

function FL:LootItems()
    if self.isLooting then return end

    for i = 0, NUM_BAG_SLOTS do
        if not C_Container_GetBagName(i) then
            self.HaveEmptyBagSlots = self.HaveEmptyBagSlots + 1
        end
    end

    local link, itemEquipLoc, bindType, _
    if (GetCVarBool('autoLootDefault') ~= IsModifiedClick('AUTOLOOTTOGGLE')) then
        self.isLooting = true
        for i = GetNumLootItems(), 1, -1 do
            link = GetLootSlotLink(i)
            LootSlot(i)
            if link then
                itemEquipLoc, _, _, _, _, bindType = select(9, GetItemInfo(link))

                if itemEquipLoc == "INVTYPE_BAG" and bindType < 2 and self.HaveEmptyBagSlots > 0 then
                    EquipItemByName(link)
                end
            end
        end
    end
end

function FL:LOOT_CLOSED()
    self.isLooting = nil
    self.HaveEmptyBagSlots = 0
end

function FL:Initialize()
    if E.db.RhythmBox.Misc.FastLoot then
        _G.LOOTFRAME_AUTOLOOT_DELAY = 0.1
        _G.LOOTFRAME_AUTOLOOT_RATE = 0.1

        self:RegisterEvent('LOOT_READY', 'LootItems')
        self:RegisterEvent('LOOT_OPENED', 'LootItems')
        self:RegisterEvent('LOOT_CLOSED')
    else
        _G.LOOTFRAME_AUTOLOOT_DELAY = 0.3
        _G.LOOTFRAME_AUTOLOOT_RATE = 0.35

        self:UnregisterAllEvents()
    end

    self.isLooting = nil
    self.HaveEmptyBagSlots = 0
end

R:RegisterModule(FL:GetName())
