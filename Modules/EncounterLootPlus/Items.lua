local E, L, V, P, G = unpack(ElvUI)
local R = unpack(select(2, ...))
local ELP = R.ELP
local db = ELP.db

local CURRENT_TIER = EJ_GetNumTiers() -- Get latest tier

local currentItems = {} -- current showing items
local pendingItems = {} -- pending items
local retrieving = {} -- retrieving items
ELP.currentItems = currentItems
ELP.pendingItems = pendingItems

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
    tooltip:SetOwner(WorldFrame, 'ANCHOR_NONE')
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

local updateFrame = CreateFrame('Frame')
updateFrame:Hide()
updateFrame:SetScript('OnUpdate', function()
    local itemID = next(retrieving)
    while (itemID and db.items[itemID]) do
        itemID = next(retrieving)
    end
    if not itemID then
        ELP:RetrieveDone()
    else
        local stats = ELP:ScanStats(itemID)
        if stats then
            db.items[itemID] = stats
            retrieving[itemID] = nil
        end
    end
end)

function ELP:IsRetrieving()
    return next(retrieving) ~= nil
end

local function sortByAttr1(leftItemID, rightItemID)
    local compare = db.items[leftItemID][db.secondaryStat1] - db.items[rightItemID][db.secondaryStat1]
    if compare == 0 then
        return leftItemID < rightItemID
    else
        return compare > 0
    end
end
function ELP:RetrieveDone()
    updateFrame:Hide()
    for itemID in pairs(pendingItems) do
        if EJ_GetSlotFilter() == LE_ITEM_FILTER_TYPE_ARTIFACT_RELIC then
            tinsert(currentItems, itemID)
        elseif db.secondaryStat1 == 0 then
            tinsert(currentItems, itemID)
        elseif db.items[itemID] and db.items[itemID][db.secondaryStat1] then
            if db.secondaryStat2 == 0 then
                tinsert(currentItems, itemID)
            elseif db.items[itemID][db.secondaryStat2] then
                tinsert(currentItems, itemID)
            end
        end
    end
    -- sort according to attr1
    if db.secondaryStat1 ~= 0 and EJ_GetSlotFilter() ~= LE_ITEM_FILTER_TYPE_ARTIFACT_RELIC then
        sort(currentItems, sortByAttr1)
    end
    self:EncounterJournal_LootUpdate()
end

function ELP:RetrieveStart()
    if next(retrieving) then
        updateFrame:Show()
    else
        self:RetrieveDone()
    end
end

function ELP:UpdateItemList()
    if db.searchRange == 0 then return end
    if EncounterJournal then
        EncounterJournal:UnregisterEvent('EJ_LOOT_DATA_RECIEVED')
        EncounterJournal:UnregisterEvent('EJ_DIFFICULTY_UPDATE')
    end
    wipe(currentItems)
    wipe(pendingItems)

    EJ_SelectTier(CURRENT_TIER)
    -- force slot filter to avoid too many items listed
    local slotFilter = EJ_GetSlotFilter()
    if slotFilter == 0 then
        EJ_SetSlotFilter(LE_ITEM_FILTER_TYPE_FINGER)
    end

    for currType = 1, 2 do
        if (bit.band(currType, db.searchRange) > 0) then
            local index = 1
            while true do
                local instanceID, name = EJ_GetInstanceByIndex(index, currType == 1)
                if not instanceID then break end
                EJ_SelectInstance(instanceID)
                local shouldDisplayDifficulty = select(9, EJ_GetInstanceInfo(instanceID))
                if shouldDisplayDifficulty then
                    EJ_SetDifficulty(currType == 1 and 16 or 23)
                else
                    EJ_SetDifficulty(currType == 1 and 14 or 1)
                end
                for lootIndex = 1, EJ_GetNumLoot() do
                    local tbl = {self.hooks.EJ_GetLootInfoByIndex(lootIndex)}
                    local itemID = tbl[1]

                    if db.itemLevel ~= 0 then
                        local _, _, _, itemLevel, _, _, _, _, equipSlot = GetItemInfo(itemID)
                        if equipSlot ~= 'INVTYPE_HEAD' and equipSlot ~= 'INVTYPE_SHOULDER' and equipSlot ~= 'INVTYPE_BODY' then
                            tbl[7] = tbl[7]:gsub('1:3524', '3:4779:4786:' .. (1472 + db.itemLevel - itemLevel))
                        end
                    end

                    if not pendingItems[itemID] then
                        if not db.items[itemID] then
                            retrieving[itemID] = true
                        end
                        tbl.instanceID = instanceID
                        pendingItems[itemID] = tbl
                    end
                end

                index = index + 1
            end
        end
    end

    EJ_SetSlotFilter(slotFilter)
    if EncounterJournal then
        EncounterJournal:RegisterEvent('EJ_LOOT_DATA_RECIEVED')
        EncounterJournal:RegisterEvent('EJ_DIFFICULTY_UPDATE')
    end

    self:RetrieveStart()
end
