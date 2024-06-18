local R, E, L, V, P, G = unpack((select(2, ...)))
local C = R:GetModule('Chat')

-- Lua functions
local gsub, ipairs, select, strmatch, type = gsub, ipairs, select, strmatch, type
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables
local C_Item_GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo
local C_Item_GetItemInfoInstant = C_Item.GetItemInfoInstant

local ChatFrame_AddMessageEventFilter = ChatFrame_AddMessageEventFilter

local Enum_ItemClass_Armor = Enum.ItemClass.Armor
local Enum_ItemClass_Gem = Enum.ItemClass.Gem
local Enum_ItemClass_Weapon = Enum.ItemClass.Weapon
local Enum_ItemGemSubclass_Artifactrelic = Enum.ItemGemSubclass.Artifactrelic

local itemLinkPattern = '|c%x%x%x%x%x%x%x%x|Hitem:%d+:[%d:]+|h%[[^%]|]+%]|h|r'
local itemLinkCache = {}

local chatEvents = {
    'CHAT_MSG_ACHIEVEMENT',
    'CHAT_MSG_BATTLEGROUND',
    'CHAT_MSG_BN_WHISPER',
    'CHAT_MSG_CHANNEL',
    'CHAT_MSG_COMMUNITIES_CHANNEL',
    'CHAT_MSG_EMOTE',
    'CHAT_MSG_GUILD',
    'CHAT_MSG_INSTANCE_CHAT',
    'CHAT_MSG_INSTANCE_CHAT_LEADER',
    'CHAT_MSG_LOOT',
    'CHAT_MSG_OFFICER',
    'CHAT_MSG_PARTY',
    'CHAT_MSG_PARTY_LEADER',
    'CHAT_MSG_RAID',
    'CHAT_MSG_RAID_LEADER',
    'CHAT_MSG_SAY',
    'CHAT_MSG_TRADESKILLS',
    'CHAT_MSG_WHISPER',
    'CHAT_MSG_WHISPER_INFORM',
    'CHAT_MSG_YELL',
}

local function handleItemLink(itemLink)
    if itemLinkCache[itemLink] then
        return itemLinkCache[itemLink]
    end

    local classID, subclassID = select(6, C_Item_GetItemInfoInstant(itemLink))
    if not (
        classID == Enum_ItemClass_Weapon or
        classID == Enum_ItemClass_Armor or
        (classID == Enum_ItemClass_Gem and subclassID == Enum_ItemGemSubclass_Artifactrelic)
    ) then
        return
    end

    local itemLevel = C_Item_GetDetailedItemLevelInfo(itemLink)
    if not itemLevel then return end

    local newItemLink = gsub(itemLink, "|h%[(.-)%]|h", "|h[" .. itemLevel .. ":%1]|h")
    itemLinkCache[itemLink] = newItemLink

    return newItemLink
end

local chatFilterFunc = function(self, _, message, ...)
    local newMessage = gsub(message, itemLinkPattern, handleItemLink)

    return false, newMessage, ...
end

function C:ItemLevel()
    for _, event in ipairs(chatEvents) do
        ChatFrame_AddMessageEventFilter(event, chatFilterFunc)
    end

    R:RegisterAddOnLoad('Blizzard_Communities', function()
        hooksecurefunc('GuildNewsButton_SetText', function(frame, _, text, name, link, ...)
            if link and type(link) == 'string' and strmatch(link, itemLinkPattern) then
                local newLink = handleItemLink(link)
                if not newLink then return end

                frame.text:SetFormattedText(text, name, newLink, ...)
            end
        end)
    end)
end

C:RegisterPipeline(C.ItemLevel)
