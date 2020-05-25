--[[
Name: LibCorruptedItem-1.0
Author: Rhythm
Database: NDui by siweia
Dependencies: LibStub
License: Public Domain

APIs:
spellID, rank, corruptionValue = LCI:GetCorruptionInfo(itemLink)
spellID, rank, corruptionValue = LCI:GetCorruptionInfoByBonusID(bonusID)
spellID, rank, corruptionValue = LCI:GetCorruptionInfoByContaminant(itemID)
rank1BonusID, rank2BonusID, rank3BonusID = LCI:GetCorruptionRanks(bonusID)
isCorruptedWeapon = LCI:IsCorruptedWeapon(itemID)
]]--

local MAJOR, MINOR = 'LibCorruptedItem-1.0', 5
assert(LibStub, MAJOR .. " requires LibStub")

local LCI = LibStub:NewLibrary(MAJOR, MINOR)
if not LCI then return end

-- Lua functions
local ipairs, strmatch, strsplit, tonumber, unpack = ipairs, strmatch, strsplit, tonumber, unpack

-- WoW API / Variables
local IsCorruptedItem = IsCorruptedItem

LCI.corruptions = {
    [6483] = {315607, 1,   8},  -- Avoidant
    [6484] = {315608, 2,   12}, -- Avoidant
    [6485] = {315609, 3,   16}, -- Avoidant
    [6474] = {315544, 1,   10}, -- Expedient
    [6475] = {315545, 2,   15}, -- Expedient
    [6476] = {315546, 3,   20}, -- Expedient
    [6471] = {315529, 1,   10}, -- Masterful
    [6472] = {315530, 2,   15}, -- Masterful
    [6473] = {315531, 3,   20}, -- Masterful
    [6480] = {315554, 1,   10}, -- Severe
    [6481] = {315557, 2,   15}, -- Severe
    [6482] = {315558, 3,   20}, -- Severe
    [6477] = {315549, 1,   10}, -- Versatile
    [6478] = {315552, 2,   15}, -- Versatile
    [6479] = {315553, 3,   20}, -- Versatile
    [6493] = {315590, 1,   17}, -- Siphoner
    [6494] = {315591, 2,   28}, -- Siphoner
    [6495] = {315592, 3,   45}, -- Siphoner
    [6437] = {315277, 1,   10}, -- Strikethrough
    [6438] = {315281, 2,   15}, -- Strikethrough
    [6439] = {315282, 3,   20}, -- Strikethrough
    [6555] = {318266, 1,   15}, -- Racing Pulse
    [6559] = {318492, 2,   20}, -- Racing Pulse
    [6560] = {318496, 3,   35}, -- Racing Pulse
    [6556] = {318268, 1,   15}, -- Deadly Momentum
    [6561] = {318493, 2,   20}, -- Deadly Momentum
    [6562] = {318497, 3,   35}, -- Deadly Momentum
    [6558] = {318270, 1,   15}, -- Surging Vitality
    [6565] = {318495, 2,   20}, -- Surging Vitality
    [6566] = {318499, 3,   35}, -- Surging Vitality
    [6557] = {318269, 1,   15}, -- Honed Mind
    [6563] = {318494, 2,   20}, -- Honed Mind
    [6564] = {318498, 3,   35}, -- Honed Mind
    [6549] = {318280, 1,   25}, -- Echoing Void
    [6550] = {318485, 2,   35}, -- Echoing Void
    [6551] = {318486, 3,   60}, -- Echoing Void
    [6552] = {318274, 1,   20}, -- Infinite Stars
    [6553] = {318487, 2,   50}, -- Infinite Stars
    [6554] = {318488, 3,   75}, -- Infinite Stars
    [6547] = {318303, 1,   12}, -- Ineffable Truth
    [6548] = {318484, 2,   30}, -- Ineffable Truth
    [6537] = {318276, 1,   25}, -- Twilight Devastation
    [6538] = {318477, 2,   50}, -- Twilight Devastation
    [6539] = {318478, 3,   75}, -- Twilight Devastation
    [6543] = {318481, 1,   10}, -- Twisted Appendage
    [6544] = {318482, 2,   35}, -- Twisted Appendage
    [6545] = {318483, 3,   66}, -- Twisted Appendage
    [6540] = {318286, 1,   15}, -- Void Ritual
    [6541] = {318479, 2,   35}, -- Void Ritual
    [6542] = {318480, 3,   66}, -- Void Ritual
    [6573] = {318272, nil, 15}, -- Gushing Wound
    [6546] = {318239, nil, 15}, -- Glimpse of Clarity
    [6571] = {318293, nil, 30}, -- Searing Flames
    [6572] = {316651, nil, 50}, -- Obsidian Skin
    [6567] = {318294, nil, 35}, -- Devour Vitality
    [6568] = {316780, nil, 25}, -- Whispered Truths
    [6570] = {318299, nil, 20}, -- Flash of Insight
    [6569] = {317290, nil, 25}, -- Lash of the Void
}

LCI.corruptionRanks = {
    {6483, 6484, 6485}, -- Avoidant
    {6474, 6475, 6476}, -- Expedient
    {6471, 6472, 6473}, -- Masterful
    {6480, 6481, 6482}, -- Severe
    {6477, 6478, 6479}, -- Versatile
    {6493, 6494, 6495}, -- Siphoner
    {6437, 6438, 6439}, -- Strikethrough
    {6555, 6559, 6560}, -- Racing Pulse
    {6556, 6561, 6562}, -- Deadly Momentum
    {6558, 6565, 6566}, -- Surging Vitality
    {6557, 6563, 6564}, -- Honed Mind
    {6549, 6550, 6551}, -- Echoing Void
    {6552, 6553, 6554}, -- Infinite Stars
    {6547, 6548},       -- Ineffable Truth
    {6537, 6538, 6539}, -- Twilight Devastation
    {6543, 6544, 6545}, -- Twisted Appendage
    {6540, 6541, 6542}, -- Void Ritual
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

LCI.contaminants = {
    [177955] = 6556, -- Deadly Momentum
    [177965] = 6561, -- Deadly Momentum
    [177966] = 6562, -- Deadly Momentum
    [177967] = 6551, -- Echoing Void
    [177968] = 6550, -- Echoing Void
    [177969] = 6549, -- Echoing Void
    [177970] = 6483, -- Avoidant
    [177971] = 6484, -- Avoidant
    [177972] = 6485, -- Avoidant
    [177973] = 6474, -- Expedient
    [177974] = 6475, -- Expedient
    [177975] = 6476, -- Expedient
    [177976] = 6546, -- Glimpse of Clarity
    [177977] = 6573, -- Gushing Wound
    [177978] = 6557, -- Honed Mind
    [177979] = 6563, -- Honed Mind
    [177980] = 6564, -- Honed Mind
    [177981] = 6547, -- Ineffable Truth
    [177982] = 6548, -- Ineffable Truth
    [177983] = 6552, -- Infinite Stars
    [177984] = 6553, -- Infinite Stars
    [177985] = 6554, -- Infinite Stars
    [177986] = 6471, -- Masterful
    [177987] = 6472, -- Masterful
    [177988] = 6473, -- Masterful
    [177989] = 6555, -- Racing Pulse
    [177990] = 6559, -- Racing Pulse
    [177991] = 6560, -- Racing Pulse
    [177992] = 6480, -- Severe
    [177993] = 6481, -- Severe
    [177994] = 6482, -- Severe
    [177995] = 6493, -- Siphoner
    [177996] = 6494, -- Siphoner
    [177997] = 6495, -- Siphoner
    [177998] = 6437, -- Strikethrough
    [177999] = 6438, -- Strikethrough
    [178000] = 6439, -- Strikethrough
    [178001] = 6558, -- Surging Vitality
    [178002] = 6565, -- Surging Vitality
    [178003] = 6566, -- Surging Vitality
    [178004] = 6537, -- Twilight Devastation
    [178005] = 6538, -- Twilight Devastation
    [178006] = 6539, -- Twilight Devastation
    [178007] = 6543, -- Twisted Appendage
    [178008] = 6544, -- Twisted Appendage
    [178009] = 6545, -- Twisted Appendage
    [178010] = 6477, -- Versatile
    [178011] = 6478, -- Versatile
    [178012] = 6479, -- Versatile
    [178013] = 6540, -- Void Ritual
    [178014] = 6541, -- Void Ritual
    [178015] = 6542, -- Void Ritual
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

do
    local itemCache = {}
    function LCI:GetCorruptionInfo(itemLink)
        if itemCache[itemLink] then
            return unpack(itemCache[itemLink])
        end

        if not IsCorruptedItem(itemLink) then return end

        local itemSplit = GetItemSplit(itemLink)

        if itemSplit[13] == 1 and self.corruptedWeapons[itemSplit[1]] then
            -- itemLink from Encounter Journal
            if self.corruptions[self.corruptedWeapons[itemSplit[1]]] then
                itemCache[itemLink] = self.corruptions[self.corruptedWeapons[itemSplit[1]]]
                return unpack(itemCache[itemLink])
            end
        else
            for index = 1, itemSplit[13] do
                if self.corruptions[itemSplit[13 + index]] then
                    itemCache[itemLink] = self.corruptions[itemSplit[13 + index]]
                    return unpack(itemCache[itemLink])
                end
            end
        end
    end
end

function LCI:GetCorruptionInfoByBonusID(bonusID)
    if self.corruptions[bonusID] then
        return unpack(self.corruptions[bonusID])
    end
end

function LCI:GetCorruptionInfoByContaminant(itemID)
    if self.contaminants[itemID] then
        return unpack(self.corruptions[self.contaminants[itemID]])
    end
end

function LCI:GetCorruptionRanks(bonusID)
    if self.corruptionRanks[bonusID] then
        return unpack(self.corruptionRanks[bonusID])
    else
        return bonusID
    end
end

function LCI:IsCorruptedWeapon(itemID)
    return not not self.corruptedWeapons[itemID]
end
