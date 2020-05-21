--[[
Name: LibCorruptedItem-1.0
Author: Rhythm
Dependencies: LibStub
License: Public Domain

APIs:
spellID, rank = LCI:GetCorruptionInfo(itemLink)
spellID, rank = LCI:GetCorruptionInfoByBonusID(bonusID)
isCorruptedWeapon = LCI:IsCorruptedWeapon(itemID)
]]--

local MAJOR, MINOR = 'LibCorruptedItem-1.0', 1
assert(LibStub, MAJOR .. " requires LibStub")

local LCI = LibStub:NewLibrary(MAJOR, MINOR)
if not LCI then return end

-- Lua functions
local ipairs, strmatch, strsplit, tonumber, unpack = ipairs, strmatch, strsplit, tonumber, unpack

-- WoW API / Variables
local IsCorruptedItem = IsCorruptedItem

LCI.bonusIDs = {
    [6483] = {315607, 1}, -- Avoidant
    [6484] = {315608, 2}, -- Avoidant
    [6485] = {315609, 3}, -- Avoidant
    [6474] = {315544, 1}, -- Expedient
    [6475] = {315545, 2}, -- Expedient
    [6476] = {315546, 3}, -- Expedient
    [6471] = {315529, 1}, -- Masterful
    [6472] = {315530, 2}, -- Masterful
    [6473] = {315531, 3}, -- Masterful
    [6480] = {315554, 1}, -- Severe
    [6481] = {315557, 2}, -- Severe
    [6482] = {315558, 3}, -- Severe
    [6477] = {315549, 1}, -- Versatile
    [6478] = {315552, 2}, -- Versatile
    [6479] = {315553, 3}, -- Versatile
    [6493] = {315590, 1}, -- Siphoner
    [6494] = {315591, 2}, -- Siphoner
    [6495] = {315592, 3}, -- Siphoner
    [6437] = {315277, 1}, -- Strikethrough
    [6438] = {315281, 2}, -- Strikethrough
    [6439] = {315282, 3}, -- Strikethrough
    [6555] = {318266, 1}, -- Racing Pulse
    [6559] = {318492, 2}, -- Racing Pulse
    [6560] = {318496, 3}, -- Racing Pulse
    [6556] = {318268, 1}, -- Deadly Momentum
    [6561] = {318493, 2}, -- Deadly Momentum
    [6562] = {318497, 3}, -- Deadly Momentum
    [6558] = {318270, 1}, -- Surging Vitality
    [6565] = {318495, 2}, -- Surging Vitality
    [6566] = {318499, 3}, -- Surging Vitality
    [6557] = {318269, 1}, -- Honed Mind
    [6563] = {318494, 2}, -- Honed Mind
    [6564] = {318498, 3}, -- Honed Mind
    [6549] = {318280, 1}, -- Echoing Void
    [6550] = {318485, 2}, -- Echoing Void
    [6551] = {318486, 3}, -- Echoing Void
    [6552] = {318274, 1}, -- Infinite Stars
    [6553] = {318487, 2}, -- Infinite Stars
    [6554] = {318488, 3}, -- Infinite Stars
    [6547] = {318303, 1}, -- Ineffable Truth
    [6548] = {318484, 2}, -- Ineffable Truth
    [6537] = {318276, 1}, -- Twilight Devastation
    [6538] = {318477, 2}, -- Twilight Devastation
    [6539] = {318478, 3}, -- Twilight Devastation
    [6543] = {318481, 1}, -- Twisted Appendage
    [6544] = {318482, 2}, -- Twisted Appendage
    [6545] = {318483, 3}, -- Twisted Appendage
    [6540] = {318286, 1}, -- Void Ritual
    [6541] = {318479, 2}, -- Void Ritual
    [6542] = {318480, 3}, -- Void Ritual
    [6573] = {318272},    -- Gushing Wound
    [6546] = {318239},    -- Glimpse of Clarity
    [6571] = {318293},    -- Searing Flames
    [6572] = {316651},    -- Obsidian Skin
    [6567] = {318294},    -- Devour Vitality
    [6568] = {316780},    -- Whispered Truths
    [6570] = {318299},    -- Flash of Insight
    [6569] = {317290},    -- Lash of the Void
}

LCI.corruptedWeapons = {
    [172199] = 6571, -- Faralos, Empire's Dream
    [172200] = 6572, -- Sk'shuul Vaz
    [172191] = 6567, -- An'zig Vra
    [172193] = 6568, -- Whispering Eldritch Bow
    [172198] = 6570, -- Mar'kowa, the Mindpiercer
    [172197] = 6569, -- Unguent Caress
    [172227] = 6544, -- Shard of the Black Empire
    [172196] = 6541, -- Vorzz Yoq'al
    [174106] = 6550, -- Qwor N'lyeth
    [172189] = 6548, -- Eyestalk of Il'gynoth
    [174108] = 6553, -- Shgla'yos, Astral Malignity
    [172187] = 6539, -- Devastation's Hour
}

local function GetItemSplit(itemLink)
    local itemString = strmatch(itemLink, 'item:([%-?%d:]+)')
    local itemSplit = {strsplit(':', itemString)}

    -- Split data into a table
    for index, value in ipairs(itemSplit) do
        if value == '' then
            itemSplit[index] = 0
        else
            itemSplit[index] = tonumber(value)
        end
    end

    return itemSplit
end

function LCI:GetCorruptionInfo(itemLink)
    if not IsCorruptedItem(itemLink) then return end

    local itemSplit = GetItemSplit(itemLink)

    if itemSplit[13] == 1 and self.corruptedWeapons[itemSplit[1]] then
        -- itemLink from Encounter Journal
        if self.bonusIDs[self.corruptedWeapons[itemSplit[1]]] then
            return unpack(self.bonusIDs[self.corruptedWeapons[itemSplit[1]]])
        end
    else
        for index = 1, itemSplit[13] do
            if self.bonusIDs[itemSplit[13 + index]] then
                return unpack(self.bonusIDs[itemSplit[13 + index]])
            end
        end
    end
end

function LCI:GetCorruptionInfoByBonusID(bonusID)
    if self.bonusIDs[bonusID] then
        return unpack(self.bonusIDs[bonusID])
    end
end

function LCI:IsCorruptedWeapon(itemID)
    return not not self.corruptedWeapons[itemID]
end
