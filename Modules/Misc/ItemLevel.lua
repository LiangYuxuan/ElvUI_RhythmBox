local R, E, L, V, P, G = unpack((select(2, ...)))
local IL = R:NewModule('ItemLevel', 'AceEvent-3.0', 'AceHook-3.0')

-- Lua functions
local _G = _G
local gsub, ipairs, select, strmatch, type = gsub, ipairs, select, strmatch, type
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables
local C_Container_GetContainerItemInfo = C_Container.GetContainerItemInfo
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo
local GetInventoryItemLink = GetInventoryItemLink
local GetInventoryItemQuality = GetInventoryItemQuality
local GetItemInfoInstant = GetItemInfoInstant
local GetItemQualityColor = GetItemQualityColor

local ChatFrame_AddMessageEventFilter = ChatFrame_AddMessageEventFilter
local EquipmentManager_UnpackLocation = EquipmentManager_UnpackLocation

local Enum_ItemClass_Armor = Enum.ItemClass.Armor
local Enum_ItemClass_Gem = Enum.ItemClass.Gem
local Enum_ItemClass_Weapon = Enum.ItemClass.Weapon
local Enum_ItemGemSubclass_Artifactrelic = Enum.ItemGemSubclass.Artifactrelic

local gearSlots = {
    { index = 1, name = HEADSLOT, button = 'HeadSlot' },
    { index = 2, name = NECKSLOT, button = 'NeckSlot' },
    { index = 3, name = SHOULDERSLOT, button = 'ShoulderSlot' },
    { index = 5, name = CHESTSLOT, button = 'ChestSlot' },
    { index = 6, name = WAISTSLOT, button = 'WaistSlot' },
    { index = 7, name = LEGSSLOT, button = 'LegsSlot' },
    { index = 8, name = FEETSLOT, button = 'FeetSlot' },
    { index = 9, name = WRISTSLOT, button = 'WristSlot' },
    { index = 10, name = HANDSSLOT, button = 'HandsSlot' },
    { index = 11, name = FINGER0SLOT, button = 'Finger0Slot' },
    { index = 12, name = FINGER1SLOT, button = 'Finger1Slot' },
    { index = 13, name = TRINKET0SLOT, button = 'Trinket0Slot' },
    { index = 14, name = TRINKET1SLOT, button = 'Trinket1Slot' },
    { index = 15, name = BACKSLOT, button = 'BackSlot' },
    { index = 16, name = MAINHANDSLOT, button = 'MainHandSlot' },
    { index = 17, name = SECONDARYHANDSLOT, button = 'SecondaryHandSlot' },
}

local itemLinkPattern = '|c%x%x%x%x%x%x%x%x|Hitem:%d+:[%d:]+|h%[[^%]|]+%]|h|r'
local itemLinkCache = {}

local function safeGetItemQualityColor(quality)
    if quality then
        local r, g, b = GetItemQualityColor(quality)
        return r, g, b
    else
        return 1, 1, 1
    end
end

local function handleItemLink(itemLink)
    if itemLinkCache[itemLink] then
        return itemLinkCache[itemLink]
    end

    local classID, subclassID = select(6, GetItemInfoInstant(itemLink))
    if not (
        classID == Enum_ItemClass_Weapon or
        classID == Enum_ItemClass_Armor or
        (classID == Enum_ItemClass_Gem and subclassID == Enum_ItemGemSubclass_Artifactrelic)
    ) then
        return
    end

    local itemLevel = GetDetailedItemLevelInfo(itemLink)
    if not itemLevel then return end

    local newItemLink = gsub(itemLink, "|h%[(.-)%]|h", "|h[" .. itemLevel .. ":%1]|h")
    itemLinkCache[itemLink] = newItemLink

    return newItemLink
end

local function updateButtonItemLevel(button, itemLevel, r, g, b)
    if not itemLevel then
        if button.itemLevelText then
            button.itemLevelText:SetText('')
        end
        return
    end

    if not button.itemLevelText then
        button.itemLevelText = button:CreateFontString(nil, 'ARTWORK', nil, 1)
        button.itemLevelText:Point('TOP')
        button.itemLevelText:FontTemplate(nil, 14, 'OUTLINE')
    end

    button.itemLevelText:SetText(itemLevel)
    button.itemLevelText:SetTextColor(r, g, b)
end

function IL:UpdateInspectInfo()
    if not _G.InspectFrame or not _G.InspectFrame:IsShown() then return end

    local unitID = _G.InspectFrame.unit
    if unitID then
        for _, slot in ipairs(gearSlots) do
            local itemLink = GetInventoryItemLink(unitID, slot.index)
            local itemLevel = itemLink and GetDetailedItemLevelInfo(itemLink)
            local quality = GetInventoryItemQuality(unitID, slot.index)
            local r, g, b = safeGetItemQualityColor(quality)

            updateButtonItemLevel(_G['Inspect' .. slot.button], itemLevel, r, g, b)
        end
    else
        for _, slot in ipairs(gearSlots) do
            updateButtonItemLevel(_G['Inspect' .. slot.button])
        end
    end
end

function IL:UpdateCharacterInfo()
    if not _G.PaperDollFrame:IsShown() then return end

    for _, slot in ipairs(gearSlots) do
        local itemLink = GetInventoryItemLink('player', slot.index)
        local itemLevel = itemLink and GetDetailedItemLevelInfo(itemLink)
        local quality = GetInventoryItemQuality('player', slot.index)
        local r, g, b = safeGetItemQualityColor(quality)

        updateButtonItemLevel(_G['Character' .. slot.button], itemLevel, r, g, b)
    end
end

function IL:HookFlyout()
    hooksecurefunc('EquipmentFlyout_DisplayButton', function(button)
        local location = button.location
        if not location then return end

        local player, bank, bags, _, slot, bag = EquipmentManager_UnpackLocation(location)
        if (bank or bags) and bag and slot then
            local data = C_Container_GetContainerItemInfo(bag, slot)
            local itemLevel = data and data.hyperlink and GetDetailedItemLevelInfo(data.hyperlink)
            local r, g, b = safeGetItemQualityColor(data and data.quality)
            updateButtonItemLevel(button, itemLevel, r, g, b)
        elseif player and slot then
            local itemLink = GetInventoryItemLink('player', slot)
            local itemLevel = itemLink and GetDetailedItemLevelInfo(itemLink)
            local quality = GetInventoryItemQuality('player', slot)
            local r, g, b = safeGetItemQualityColor(quality)
            updateButtonItemLevel(button, itemLevel, r, g, b)
        else
            updateButtonItemLevel(button)
        end
    end)
end

function IL:HookGuildNews()
    hooksecurefunc('GuildNewsButton_SetText', function(frame, _, text, name, link, ...)
        if link and type(link) == 'string' and strmatch(link, itemLinkPattern) then
            local newLink = handleItemLink(link)
            if not newLink then return end

            frame.text:SetFormattedText(text, name, newLink, ...)
        end
    end)
end

function IL:HookInspect()
    self:SecureHookScript(_G.InspectFrame, 'OnShow', 'UpdateInspectInfo')
end

function IL:HookChatMessage()
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

    local chatFilterFunc = function(self, _, message, ...)
        local newMessage = gsub(message, itemLinkPattern, handleItemLink)

        return false, newMessage, ...
    end

    for _, event in ipairs(chatEvents) do
        ChatFrame_AddMessageEventFilter(event, chatFilterFunc)
    end
end

function IL:Initialize()
    self:HookChatMessage()

    R:RegisterAddOnLoad('Blizzard_Communities', self.HookGuildNews, self)

    self:HookFlyout()

    self:SecureHookScript(_G.PaperDollFrame, 'OnShow', 'UpdateCharacterInfo')
    self:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', 'UpdateCharacterInfo')

    R:RegisterAddOnLoad('Blizzard_InspectUI', self.HookInspect, self)
end

R:RegisterModule(IL:GetName())
