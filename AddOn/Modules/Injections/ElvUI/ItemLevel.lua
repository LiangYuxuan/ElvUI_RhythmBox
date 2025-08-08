local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')
local M = E:GetModule('Misc')

-- Lua functions
local unpack = unpack
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables
local C_Container_GetContainerItemInfo = C_Container.GetContainerItemInfo
local C_Item_GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo
local C_Item_GetItemQualityColor = C_Item.GetItemQualityColor
local GetInventoryItemLink = GetInventoryItemLink
local GetInventoryItemQuality = GetInventoryItemQuality

local EquipmentManager_GetLocationData = EquipmentManager_GetLocationData

local function safeGetItemQualityColor(quality)
    if quality then
        local r, g, b = C_Item_GetItemQualityColor(quality)
        return r, g, b
    else
        return 1, 1, 1
    end
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

local function ElvUIItemLevel()
    hooksecurefunc('EquipmentFlyout_DisplayButton', function(button)
        local location = button.location
        if not location then return end

        local locationData = EquipmentManager_GetLocationData(location)
        if (locationData.isBank or locationData.isBags) and locationData.bag and locationData.slot then
            local data = C_Container_GetContainerItemInfo(locationData.bag, locationData.slot)
            local itemLevel = data and data.hyperlink and C_Item_GetDetailedItemLevelInfo(data.hyperlink)
            local r, g, b = safeGetItemQualityColor(data and data.quality)
            updateButtonItemLevel(button, itemLevel, r, g, b)
        elseif locationData.isPlayer and locationData.slot then
            local itemLink = GetInventoryItemLink('player', locationData.slot)
            local itemLevel = itemLink and C_Item_GetDetailedItemLevelInfo(itemLink)
            local quality = GetInventoryItemQuality('player', locationData.slot)
            local r, g, b = safeGetItemQualityColor(quality)
            updateButtonItemLevel(button, itemLevel, r, g, b)
        else
            updateButtonItemLevel(button)
        end
    end)

    hooksecurefunc(M, 'UpdatePageStrings', function(_, _, _, inspectItem, slotInfo)
        updateButtonItemLevel(inspectItem, slotInfo.iLvl, unpack(slotInfo.itemLevelColors))
    end)
end

RI:RegisterPipeline(ElvUIItemLevel)
