local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RI = R:GetModule('Injections')
local LCI = LibStub('LibCorruptedItem-1.0')

-- Lua functions
local _G = _G
local gsub = gsub

-- WoW API / Variables
local ChatFrame_AddMessageEventFilter = ChatFrame_AddMessageEventFilter
local GetSpellInfo = GetSpellInfo

local rankText = {"I", "II", "III"}
local Cache = {}

local function AddCorruptionInfo(inputString)
    if Cache[inputString] then
        return Cache[inputString]
    end

    local spellID, rank = LCI:GetCorruptionInfo(inputString)
    if not spellID then return end

    local spellName, _, spellIcon = GetSpellInfo(spellID)
    if not spellName then return end

    if rank then
        spellName = spellName .. ' ' .. rankText[rank]
    end

    local result = inputString .. "|cff956dd1(|T" .. spellIcon .. ":0|t" .. spellName ..")|r"
    Cache[inputString] = result

    return result
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
