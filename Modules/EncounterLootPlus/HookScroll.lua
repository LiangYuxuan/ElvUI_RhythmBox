local E, L, V, P, G = unpack(ElvUI)
local R = unpack(select(2, ...))
local ELP = R.ELP
local db = ELP.db

local currentItems = ELP.currentItems
local pendingItems = ELP.pendingItems

local INSTANCE_LOOT_BUTTON_HEIGHT = 64

-- Hook EJ_GetLootInfoByIndex
function ELP:EJ_GetLootInfoByIndex(index, encounterIndex)
    if db.searchRange == 0 then return self.hooks.EJ_GetLootInfoByIndex(index, encounterIndex) end
    return unpack(pendingItems[currentItems[index]])
end

-- Hook EncounterJournal_LootUpdate
function ELP:EncounterJournal_LootUpdate()
    if db.searchRange == 0 then
        local items = EncounterJournal.encounter.info.lootScroll.buttons
        for _, item in ipairs(items) do
            if item.instance then
                item.instance:SetText("")
            end
        end
        return self.hooks.EncounterJournal_LootUpdate()
    end
    if self:IsRetrieving() then return end

    EncounterJournal_UpdateFilterString()
    local scrollFrame = EncounterJournal.encounter.info.lootScroll
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local items = scrollFrame.buttons
    local item, index

    local numLoot = #currentItems
    local buttonSize = INSTANCE_LOOT_BUTTON_HEIGHT

    for i = 1, #items do
        item = items[i]
        index = offset + i
        if index <= numLoot then
            item:SetHeight(INSTANCE_LOOT_BUTTON_HEIGHT)
            item.boss:Show()
            item.bossTexture:Show()
            item.bosslessTexture:Hide()
            item.index = index
            EncounterJournal_SetLootButton(item)
        else
            item:Hide()
        end
    end

    local totalHeight = numLoot * buttonSize
    HybridScrollFrame_Update(scrollFrame, totalHeight, scrollFrame:GetHeight())
end

-- Hook EncounterJournal_SetLootButton
function ELP:EncounterJournal_SetLootButton(item)
    if not item.UpdateTooltip then item.UpdateTooltip = item:GetScript('OnEnter') end -- for Azerite Tooltip Update
    if db.searchRange == 0 then return self.hooks.EncounterJournal_SetLootButton(item) end

    local itemID = currentItems[item.index]
    local instanceID = pendingItems[itemID].instanceID
    local _, encounterID, name, icon, slot, armorType, link = unpack(pendingItems[itemID])
    local _, _, _, itemLevel, _, _, _, _, equipSlot = GetItemInfo(itemID)
    
    item.link = link
    if name then
        item.name:SetText(format("|cffb37fff%s|r", name)) -- a335ee
        item.icon:SetTexture(icon)
        item.slot:SetText(slot)
        item.armorType:SetText(armorType)
        if not item.instance then
            item.instance = item:CreateFontString('$parentInst', 'OVERLAY', 'GameFontBlack')
            item.instance:SetJustifyH('RIGHT')
            item.instance:SetSize(0, 12)
            item.instance:SetPoint('BOTTOMRIGHT', -6, 6)
            item.instance:SetTextColor(1, 1, 1, 1)
        end
        instanceID = instanceID and EJ_GetInstanceInfo(instanceID)
        item.instance:SetText(instanceID or "")

        item.boss:SetFormattedText(BOSS_INFO_STRING, EJ_GetEncounterInfo(encounterID))

        SetItemButtonQuality(item, 4, itemID)
    else
        item.name:SetText(RETRIEVING_ITEM_INFO)
        item.icon:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark')
        item.slot:SetText('')
        item.armorType:SetText('')
        item.boss:SetText('')
        if item.instance then item.instance:SetText('') end
    end
    item.encounterID = encounterID
    item.itemID = itemID
    item:Show()
    if item.showingTooltip then
        EncounterJournal_SetTooltip(itemLink)
    end
end

-- Hook EncounterJournal_Loot_OnClick
function ELP:EncounterJournal_Loot_OnClick(frame)
    if db.searchRange == 0 then return self.hooks.EncounterJournal_Loot_OnClick(frame) end

    local instanceID = pendingItems[frame.itemID].instanceID
    local old = EncounterJournal.encounter.info.lootScroll.scrollBar:GetValue()
    self.handling = true
    if instanceID then
        NavBar_Reset(EncounterJournal.navBar)
        EncounterJournal_DisplayInstance(instanceID)
    end
    PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN)
    EncounterJournal_DisplayEncounter(frame.encounterID)
    EncounterJournal.encounter.info.lootScroll.scrollBar:SetValue(old)
    self.handling = nil
end

function ELP:HandleScroll()
    self:RawHook('EJ_GetLootInfoByIndex', true)
    self:RawHook('EncounterJournal_LootUpdate', true)
    self:RawHook('EncounterJournal_SetLootButton', true)
    self:RawHook('EncounterJournal_Loot_OnClick', true)

    EncounterJournal.encounter.info.lootScroll.update = function()
        self:EncounterJournal_LootUpdate()
    end
    EncounterJournal.encounter.info.lootScroll.scrollBar.doNotHide = true
    EncounterJournal.encounter.info.lootScroll.dynamic = function(offset)
        if db.searchRange == 0 then return EncounterJournal_LootCalcScroll(offset) end

        local buttonHeight = INSTANCE_LOOT_BUTTON_HEIGHT
        local numLoot = #currentItems
    
        local index = floor(offset / buttonHeight)
        return index, offset - (index * buttonHeight)    
    end

    -- manually click boss will reset the option
    self:SecureHook('EncounterJournal_DisplayEncounter', function()
        if not self.handling and self.searchRange ~= 0 then
            db.searchRange = 0
        end
    end)

    self:SecureHook('EJ_ResetLootFilter', 'UpdateItemList')
    self:SecureHook(self, 'UpdateItemList', function()
        EncounterJournal.encounter.info.lootScroll.scrollBar:SetValue(0)
    end)

    --fix sometime can't go back
    self:SecureHook(EncounterJournalNavBarHomeButton, 'Disable', function(self, enabled)
        self:SetEnabled(true)
    end)
end
