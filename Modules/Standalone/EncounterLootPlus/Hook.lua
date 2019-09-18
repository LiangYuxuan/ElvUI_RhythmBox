local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local ELP = R:GetModule('EncounterLootPlus')
local db = ELP.db

-- Lua functions
local _G = _G

-- WoW API / Variables
local EJ_GetInstanceInfo = EJ_GetInstanceInfo

local EncounterJournal_DisplayInstance = EncounterJournal_DisplayInstance
local NavBar_AddButton = NavBar_AddButton
local NavBar_Reset = NavBar_Reset

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
    if _G.EncounterJournal.encounterID and _G.EncounterJournal.instanceID then
        -- ensure searching is instance display
        _G.EncounterJournal.encounterID = nil
        local buttonData = {
            id = _G.EncounterJournal.instanceID,
            name = EJ_GetInstanceInfo(_G.EncounterJournal.instanceID),
            OnClick = _G.EJNAV_RefreshInstance,
            listFunc = _G.EJNAV_GetInstanceList,
        }
        NavBar_Reset(_G.EncounterJournal.navBar)
        NavBar_AddButton(_G.EncounterJournal.navBar, buttonData)
    end
    _G.EncounterJournal.encounter.info.lootScroll.scrollBar:SetValue(0)
end

-- Before EncounterJournal_Loot_OnClick
function ELP:EncounterJournal_Loot_OnClick(item)
    if db.searchRange == 0 then return end
    local instanceID = self:GetItemInstance(item.itemID)
    -- keep encounter id
    local encounterID = item.encounterID
    if instanceID then
        NavBar_Reset(_G.EncounterJournal.navBar)
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
