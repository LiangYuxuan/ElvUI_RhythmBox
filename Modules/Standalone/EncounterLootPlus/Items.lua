local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

-- Lua functions
local _G = _G
local abs, format, next, sort, select = abs, format, next, sort, select
local tinsert, tonumber, wipe, unpack = tinsert, tonumber, wipe, unpack

local bit_band = bit.band

-- WoW API / Variables
local EJ_GetInstanceByIndex = EJ_GetInstanceByIndex
local EJ_GetInstanceInfo = EJ_GetInstanceInfo
local EJ_GetSlotFilter = EJ_GetSlotFilter
local EJ_SelectEncounter = EJ_SelectEncounter
local EJ_SelectInstance = EJ_SelectInstance
local EJ_SelectTier = EJ_SelectTier
local EJ_SetDifficulty = EJ_SetDifficulty
local EJ_SetSlotFilter = EJ_SetSlotFilter
local GetItemInfo = GetItemInfo

local EncounterJournal_LootUpdate = EncounterJournal_LootUpdate

local LE_ITEM_FILTER_TYPE_ARTIFACT_RELIC = LE_ITEM_FILTER_TYPE_ARTIFACT_RELIC
local LE_ITEM_FILTER_TYPE_FINGER = LE_ITEM_FILTER_TYPE_FINGER

local ELP = E:GetModule('RhythmBox_EncounterLootPlus')
local db = ELP.db

local CURRENT_TIER = EJ_GetNumTiers() -- Get latest tier

local currLoots = {} -- current showing loots
local lootsInfo = {} -- loots info
local retrieving = {} -- retrieving loots
local slotFilter -- store current slotFilter

local classID = E.myClassID
local specID = E.myspec or 0

local tooltipName = 'ELP_ScanTooltip'
local tooltip = CreateFrame('GameTooltip', tooltipName, nil, 'GameTooltipTemplate')
local pattern = '^%+([0-9,]+) ([^ ]+)$'
local statTexts = {
    [STAT_CRITICAL_STRIKE]     = 1, --CR_CRIT_MELEE,
    [STAT_HASTE]               = 2, --CR_HASTE_MELEE,
    [STAT_VERSATILITY]         = 3, --CR_VERSATILITY_DAMAGE_DONE,
    [STAT_MASTERY]             = 4, --CR_MASTERY,
    [ITEM_MOD_STRENGTH_SHORT]  = 5, --LE_UNIT_STAT_STRENGTH
    [ITEM_MOD_AGILITY_SHORT]   = 6, --LE_UNIT_STAT_AGILITY
    [ITEM_MOD_INTELLECT_SHORT] = 8, --LE_UNIT_STAT_INTELLECT
}
function ELP:ScanStats(itemID, itemLink)
    if not itemID and not itemLink then return end
    if not itemID then
        local str = select(3, itemLink:find('^|c%x+|H(.+)|h%[.+%]'))
        if not str then return end
        itemID = tonumber(select(2, (':'):split(str)))
    end
    local _, link, _, itemLevel = GetItemInfo(itemID)
    if not link or not itemLevel then return end
    local fakeLink = format('item:%d::::::::120::::1:%d::', itemID, 1472 + (500 - itemLevel))

    local result
    tooltip:SetOwner(_G.WorldFrame, 'ANCHOR_NONE')
    tooltip:SetHyperlink(fakeLink, classID, specID)
    for i = 5, tooltip:NumLines() do
        local text = _G[tooltipName .. 'TextLeft' .. i]:GetText()
        if text then
            local _, _, value, attr = text:find(pattern)
            if attr and statTexts[attr] then
                value = tonumber((value:gsub(',', '')))
                result = result or {}
                result[statTexts[attr]] = abs(result[statTexts[attr]] or 0) + value
            end
        end
    end
    return result
end

local function sortByAttr1(leftItemID, rightItemID)
    local compare = db.items[leftItemID][db.secondaryStat1] - db.items[rightItemID][db.secondaryStat1]
    if compare == 0 then
        return leftItemID < rightItemID
    else
        return compare > 0
    end
end

function ELP:AddToList(itemID)
    if slotFilter == LE_ITEM_FILTER_TYPE_ARTIFACT_RELIC then
        tinsert(currLoots, itemID)
    elseif db.secondaryStat1 == 0 then
        tinsert(currLoots, itemID)
    elseif db.items[itemID] then
        if db.items[itemID] and db.items[itemID][db.secondaryStat1] then
            if db.secondaryStat2 == 0 then
                tinsert(currLoots, itemID)
                sort(currLoots, sortByAttr1)
            elseif db.items[itemID][db.secondaryStat2] then
                tinsert(currLoots, itemID)
                sort(currLoots, sortByAttr1)
            end
        end
    end
end

function ELP:UpdateItem()
    local itemID = next(retrieving)
    while (itemID and db.items[itemID]) do
        itemID = next(retrieving)
    end
    if not itemID then
        self.handling = true
        EncounterJournal_LootUpdate()
        self.handling = nil
    else
        local stats = ELP:ScanStats(itemID)
        if stats then
            db.items[itemID] = stats
            retrieving[itemID] = nil
            self:AddToList(itemID)
        end
    end
end

function ELP:UpdateItemList()
    if self.handling then return end
    wipe(currLoots)
    wipe(lootsInfo)

    local oldInstanceID, oldEncounterID
    if _G.EncounterJournal then
        _G.EncounterJournal:UnregisterEvent('EJ_LOOT_DATA_RECIEVED')
        _G.EncounterJournal:UnregisterEvent('EJ_DIFFICULTY_UPDATE')
        oldInstanceID = _G.EncounterJournal.instanceID
        oldEncounterID = _G.EncounterJournal.encounterID
    end

    EJ_SelectTier(CURRENT_TIER)
    -- force slot filter to avoid too many items listed
    slotFilter = EJ_GetSlotFilter()
    if slotFilter == 0 then
        EJ_SetSlotFilter(LE_ITEM_FILTER_TYPE_FINGER)
    end

    for currType = 1, 2 do
        if (bit_band(currType, db.searchRange) > 0) then
            local index = 1
            while true do
                local instanceID = EJ_GetInstanceByIndex(index, currType == 1)
                if not instanceID then break end
                EJ_SelectInstance(instanceID)
                local shouldDisplayDifficulty = select(9, EJ_GetInstanceInfo(instanceID))
                if shouldDisplayDifficulty then
                    EJ_SetDifficulty(currType == 1 and 16 or 23)
                else
                    EJ_SetDifficulty(currType == 1 and 14 or 1)
                end
                for lootIndex = 1, self.hooks.EJ_GetNumLoot() do
                    local tbl = {self.hooks.EJ_GetLootInfoByIndex(lootIndex)}
                    local itemID = tbl[1]

                    if db.itemLevel ~= 0 then
                        local _, _, _, itemLevel, _, _, _, _, equipSlot = GetItemInfo(itemID)
                        if equipSlot ~= 'INVTYPE_HEAD' and equipSlot ~= 'INVTYPE_SHOULDER' and equipSlot ~= 'INVTYPE_BODY' then
                            tbl[7] = tbl[7]:gsub('1:3524', '3:4779:4786:' .. (1472 + db.itemLevel - itemLevel))
                        end
                    end

                    if not lootsInfo[itemID] then
                        tbl.instanceID = instanceID
                        lootsInfo[itemID] = tbl
                        if db.secondaryStat1 == 0 then
                            -- without filter
                            self:AddToList(itemID)
                        else
                            -- filter
                            if not db.items[itemID] then
                                local stats = ELP:ScanStats(itemID)
                                if stats then
                                    db.items[itemID] = stats
                                else
                                    retrieving[itemID] = true
                                end
                            end
                            if db.items[itemID] then
                                self:AddToList(itemID)
                            end
                        end
                    end
                end

                index = index + 1
            end
        end
    end

    EJ_SetSlotFilter(slotFilter)
    if _G.EncounterJournal then
        if oldInstanceID  then EJ_SelectInstance(oldInstanceID)   end
        if oldEncounterID then EJ_SelectEncounter(oldEncounterID) end
        _G.EncounterJournal:RegisterEvent('EJ_LOOT_DATA_RECIEVED')
        _G.EncounterJournal:RegisterEvent('EJ_DIFFICULTY_UPDATE')
    end

    if next(retrieving) then
        self:ScheduleRepeatingTimer("UpdateItem", 0.1)
    end
end

function ELP:GetItemInstance(itemID)
    return lootsInfo[itemID] and lootsInfo[itemID].instanceID
end

function ELP:GetItemInfoByIndex(index)
    return unpack(lootsInfo[currLoots[index]])
end

function ELP:GetItemCount()
    return #currLoots
end
