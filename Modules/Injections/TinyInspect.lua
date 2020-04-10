local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G
local gsub, ipairs, strmatch, strsplit, tonumber, unpack = gsub, ipairs, strmatch, strsplit, tonumber, unpack

-- WoW API / Variables
local ChatFrame_AddMessageEventFilter = ChatFrame_AddMessageEventFilter
local GetSpellInfo = GetSpellInfo
local IsCorruptedItem = IsCorruptedItem

-- From Corruption Tooltip
local CorruptionBonuses = {
    [6483] = {"Avoidant", "I", 315607},
    [6484] = {"Avoidant", "II", 315608},
    [6485] = {"Avoidant", "III", 315609},
    [6474] = {"Expedient", "I", 315544},
    [6475] = {"Expedient", "II", 315545},
    [6476] = {"Expedient", "III", 315546},
    [6471] = {"Masterful", "I", 315529},
    [6472] = {"Masterful", "II", 315530},
    [6473] = {"Masterful", "III", 315531},
    [6480] = {"Severe", "I", 315554},
    [6481] = {"Severe", "II", 315557},
    [6482] = {"Severe", "III", 315558},
    [6477] = {"Versatile", "I", 315549},
    [6478] = {"Versatile", "II", 315552},
    [6479] = {"Versatile", "III", 315553},
    [6493] = {"Siphoner", "I", 315590},
    [6494] = {"Siphoner", "II", 315591},
    [6495] = {"Siphoner", "III", 315592},
    [6437] = {"Strikethrough", "I", 315277},
    [6438] = {"Strikethrough", "II", 315281},
    [6439] = {"Strikethrough", "III", 315282},
    [6555] = {"Racing Pulse", "I", 318266},
    [6559] = {"Racing Pulse", "II", 318492},
    [6560] = {"Racing Pulse", "III", 318496},
    [6556] = {"Deadly Momentum", "I", 318268},
    [6561] = {"Deadly Momentum", "II", 318493},
    [6562] = {"Deadly Momentum", "III", 318497},
    [6558] = {"Surging Vitality", "I", 318270},
    [6565] = {"Surging Vitality", "II", 318495},
    [6566] = {"Surging Vitality", "III", 318499},
    [6557] = {"Honed Mind", "I", 318269},
    [6563] = {"Honed Mind", "II", 318494},
    [6564] = {"Honed Mind", "III", 318498},
    [6549] = {"Echoing Void", "I", 318280},
    [6550] = {"Echoing Void", "II", 318485},
    [6551] = {"Echoing Void", "III", 318486},
    [6552] = {"Infinite Stars", "I", 318274},
    [6553] = {"Infinite Stars", "II", 318487},
    [6554] = {"Infinite Stars", "III", 318488},
    [6547] = {"Ineffable Truth", "I", 318303},
    [6548] = {"Ineffable Truth", "II", 318484},
    [6537] = {"Twilight Devastation", "I", 318276},
    [6538] = {"Twilight Devastation", "II", 318477},
    [6539] = {"Twilight Devastation", "III", 318478},
    [6543] = {"Twisted Appendage", "I", 318481},
    [6544] = {"Twisted Appendage", "II", 318482},
    [6545] = {"Twisted Appendage", "III", 318483},
    [6540] = {"Void Ritual", "I", 318286},
    [6541] = {"Void Ritual", "II", 318479},
    [6542] = {"Void Ritual", "III", 318480},
    [6573] = {"Gushing Wound", "", 318272},
    [6546] = {"Glimpse of Clarity", "", 318239},
    [6571] = {"Searing Flames", "", 318293},
    [6572] = {"Obsidian Skin", "", 316651},
    [6567] = {"Devour Vitality", "", 318294},
    [6568] = {"Whispered Truths", "", 316780},
    [6570] = {"Flash of Insight", "", 318299},
    [6569] = {"Lash of the Void", "", 317290},
}

-- fixed weapon bonuses for EJ
local CorruptionWeaponBonuses = {
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

local Cache = {}

local function AddCorruptionInfo(inputString)
    if Cache[inputString] then
        return Cache[inputString]
    end
    if not IsCorruptedItem(inputString) then return end

    local bonus
    local itemSplit = GetItemSplit(inputString)

    if itemSplit[13] == 1 then
        bonus = CorruptionWeaponBonuses[itemSplit[1]] -- index is itemID
    else
        for index = 1, itemSplit[13] do
            if CorruptionBonuses[itemSplit[13 + index]] then
                bonus = itemSplit[13 + index]
                break
            end
        end
    end

    if bonus and CorruptionBonuses[bonus] then
        local _, rank, spellID = unpack(CorruptionBonuses[bonus])
        local spellName, _, spellIcon = GetSpellInfo(spellID)
        if not spellName then return end

        if rank ~= '' then
            spellName = spellName .. rank
        end

        local result = inputString .. "|cff956dd1(|T" .. spellIcon .. ":0|t" .. spellName ..")|r"
        Cache[inputString] = result

        return result
    end
end

local function ItemLinkFilter(self, _, msg, ...)
    if _G.TinyInspectDB and _G.TinyInspectDB.EnableItemLevelChat then
        msg = gsub(msg, "(|Hitem:%d+:.-|h.-|h)", AddCorruptionInfo)
    end
    return false, msg, ...
end

function RI:TinyInspect()
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ItemLinkFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ItemLinkFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ItemLinkFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ItemLinkFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", ItemLinkFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ItemLinkFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", ItemLinkFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", ItemLinkFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", ItemLinkFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", ItemLinkFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", ItemLinkFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", ItemLinkFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", ItemLinkFilter)
end

RI:RegisterInjection(RI.TinyInspect, 'TinyInspect')
