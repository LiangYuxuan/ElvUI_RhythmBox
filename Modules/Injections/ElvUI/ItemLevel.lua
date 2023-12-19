local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')
local M = E:GetModule('Misc')

-- Lua functions
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables
local C_Container_GetContainerItemInfo = C_Container.GetContainerItemInfo

local function safeGetItemQualityColor(quality)
    if quality then
        local r, g, b = GetItemQualityColor(quality)
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

    hooksecurefunc(M, 'UpdatePageStrings', function(_, _, _, inspectItem, slotInfo)
        updateButtonItemLevel(inspectItem, slotInfo.iLvl, unpack(slotInfo.itemLevelColors))
    end)
end

RI:RegisterPipeline(ElvUIItemLevel)
