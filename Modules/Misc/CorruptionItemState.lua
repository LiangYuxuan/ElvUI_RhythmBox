local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local CIS = R:NewModule('CorruptionItemState', 'AceEvent-3.0', 'AceHook-3.0')

-- Lua functions
local _G = _G
local ipairs, select, strmatch, strsplit, tonumber, type = ipairs, select, strmatch, strsplit, tonumber, type

-- WoW API / Variables
local GetItemInfo = GetItemInfo
local IsCorruptedItem = IsCorruptedItem

local ITEM_BIND_ON_EQUIP = ITEM_BIND_ON_EQUIP
local ITEM_BIND_ON_PICKUP = ITEM_BIND_ON_PICKUP
local ITEM_SOULBOUND = ITEM_SOULBOUND

local corruptableSlot = {
    ['INVTYPE_WAIST']          = true,
    ['INVTYPE_LEGS']           = true,
    ['INVTYPE_FEET']           = true,
    ['INVTYPE_WRIST']          = true,
    ['INVTYPE_HAND']           = true,
    ['INVTYPE_FINGER']         = true,
    ['INVTYPE_WEAPON']         = true,
    ['INVTYPE_SHIELD']         = true,
    ['INVTYPE_2HWEAPON']       = true,
    ['INVTYPE_WEAPONMAINHAND'] = true,
    ['INVTYPE_WEAPONOFFHAND']  = true,
    ['INVTYPE_HOLDABLE']       = true,
    ['INVTYPE_RANGED']         = true,
    ['INVTYPE_RANGEDRIGHT']    = true,
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
    function CIS:GetStateText(itemLink)
        if type(itemCache[itemLink]) ~= 'nil' then
            return itemCache[itemLink]
        end

        local eligible, hasCorruptionMarker, hasTaintMarker, hasGoodMarker
        local hasAnyCorruption = IsCorruptedItem(itemLink)

        local itemSplit = GetItemSplit(itemLink)

        for index = 1, itemSplit[13] do
            local bonusID = itemSplit[13 + index]
            if bonusID >= 6450 and bonusID <= 6614 then
                eligible = true
            end
            if bonusID == 6579 then
                hasCorruptionMarker = true
            elseif bonusID == 6578 then
                hasTaintMarker = true
            elseif bonusID == 6516 then
                hasGoodMarker = true
            end
        end

        if eligible then
            local text
            if hasCorruptionMarker then
                text = "|cffff3377[腐蚀]|r"
            elseif hasAnyCorruption then
                text = "|cffff66cc[腐蚀 (制作)]|r"
            elseif hasTaintMarker and hasGoodMarker then
                -- text = "|cffaadd44[净化 (新)]|r"
                text = "|cffaadd44[净化]|r"
            elseif hasTaintMarker then
                -- seems no longer exists, but still put it here
                text = "|cffffbb00[净化 (旧)]|r"
            else
                text = "|cff66ff99[纯净]|r"
            end

            itemCache[itemLink] = text
            return text
        else
            itemCache[itemLink] = false
        end
    end
end

function CIS:OnTooltipSetItem(tooltip)
    local _, itemLink = tooltip:GetItem()
    if not itemLink then return end

    local itemEquipLoc = select(9, GetItemInfo(itemLink))
    if not corruptableSlot[itemEquipLoc] then return end

    local stateText = self:GetStateText(itemLink)
    if not stateText then return end

    local tooltipName = tooltip:GetName()
    for i = 3, tooltip:NumLines() do
        local textLeft = _G[tooltipName .. 'TextLeft' .. i]
        if not textLeft then break end

        local text = textLeft:GetText()
        if text == ITEM_SOULBOUND or text == ITEM_BIND_ON_PICKUP or text == ITEM_BIND_ON_EQUIP then
            textLeft:SetText(text .. " " .. stateText)
            break
        end
    end
end

function CIS:Initialize()
    self:SecureHookScript(_G.GameTooltip, 'OnTooltipSetItem')
    self:SecureHookScript(_G.ItemRefTooltip, 'OnTooltipSetItem')
    self:SecureHookScript(_G.ShoppingTooltip1, 'OnTooltipSetItem')
    self:SecureHookScript(_G.ShoppingTooltip2, 'OnTooltipSetItem')
    self:SecureHookScript(_G.EmbeddedItemTooltip, 'OnTooltipSetItem')
end

R:RegisterModule(CIS:GetName())
