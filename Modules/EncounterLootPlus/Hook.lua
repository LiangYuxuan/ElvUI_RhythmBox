local R, E, L, V, P, G = unpack(select(2, ...))
local ELP = E:GetModule('RhythmBox_EncounterLootPlus')
local db = ELP.db

-- Replace EJ_GetNumLoot
function ELP:EJ_GetNumLoot(...)
    if db.searchRange == 0 then
        return self.hooks.EJ_GetNumLoot(...)
    else
        return self:GetItemCount()
    end
end

-- Replace EJ_GetLootInfoByIndex
function ELP:EJ_GetLootInfoByIndex(index, ...)
    if db.searchRange == 0 then
        return self.hooks.EJ_GetLootInfoByIndex(index, ...)
    else
        return self:GetItemInfoByIndex(index)
    end
end

-- Replace EJ_GetNumEncountersForLootByIndex
function ELP:EJ_GetNumEncountersForLootByIndex(...)
    if db.searchRange == 0 then
        return self.hooks.EJ_GetNumEncountersForLootByIndex(...)
    else
        return 1
    end
end

-- Before EncounterJournal_LootUpdate
function ELP:EncounterJournal_LootUpdate()
    if db.searchRange == 0 then return end
    self:UpdateItemList()
    if EncounterJournal.encounterID and EncounterJournal.instanceID then
        -- ensure searching is instance display
        EncounterJournal.encounterID = nil
        local buttonData = {
            id = EncounterJournal.instanceID,
            name = EJ_GetInstanceInfo(EncounterJournal.instanceID),
            OnClick = EJNAV_RefreshInstance,
            listFunc = EJNAV_GetInstanceList,
        }
        NavBar_Reset(EncounterJournal.navBar)
        NavBar_AddButton(EncounterJournal.navBar, buttonData)
    end
    EncounterJournal.encounter.info.lootScroll.scrollBar:SetValue(0)
end

-- Before EncounterJournal_Loot_OnClick
function ELP:EncounterJournal_Loot_OnClick(item)
    if db.searchRange == 0 then return end
    local instanceID = self:GetItemInstance(item.itemID)
    -- keep encounter id
    local encounterID = item.encounterID
    if instanceID then
        NavBar_Reset(EncounterJournal.navBar)
        EncounterJournal_DisplayInstance(instanceID)
    end
    -- restone encounter id
    item.encounterID = encounterID
end

-- Before EncounterJournal_DisplayEncounter
function ELP:EncounterJournal_DisplayEncounter()
    -- manually click boss or click item
    db.searchRange = 0
end

-- After EncounterJournal_SetLootButton
function ELP:EncounterJournal_SetLootButton(item)
    if db.searchRange == 0 then
        -- clean instance text
        if item.instance then
            item.instance:SetText("")
        end
    else
        -- update instance text
        local instanceID = self:GetItemInstance(item.itemID)
        if not item.instance then
            item.instance = item:CreateFontString('$parentInst', 'OVERLAY', 'GameFontBlack')
            item.instance:SetJustifyH('RIGHT')
            item.instance:SetSize(0, 12)
            item.instance:SetPoint('BOTTOMRIGHT', -6, 6)
            item.instance:SetTextColor(1, 1, 1, 1)
        end
        item.instance:SetText(instanceID and EJ_GetInstanceInfo(instanceID) or "")
    end
end

function ELP:HandleHooks()
    self:RawHook('EJ_GetNumLoot', true)
    self:RawHook('EJ_GetLootInfoByIndex', true)
    self:RawHook('EJ_GetNumEncountersForLootByIndex', true)

    self:Hook('EncounterJournal_LootUpdate', true)
    self:Hook('EncounterJournal_Loot_OnClick', true)
    self:Hook('EncounterJournal_DisplayEncounter', true)

    self:SecureHook('EncounterJournal_SetLootButton')
end
