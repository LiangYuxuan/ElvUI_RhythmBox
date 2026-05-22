local R, E, L, V, P, G = unpack((select(2, ...)))
local CA = R:NewModule('CrestAchievement', 'AceEvent-3.0')
local S = E:GetModule('Skins')

-- Lua functions
local _G = _G
local ipairs, pairs, rawset, setmetatable, tonumber, wipe = ipairs, pairs, rawset, setmetatable, tonumber, wipe
local math_ceil = math.ceil
local math_huge = math.huge
local math_max = math.max
local math_min = math.min
local string_format = string.format
local string_gmatch = string.gmatch
local string_match = string.match
local table_insert = table.insert
local table_sort = table.sort

-- WoW API / Variables
local C_Container_GetContainerItemInfo = C_Container.GetContainerItemInfo
local C_Container_GetContainerNumSlots = C_Container.GetContainerNumSlots
local C_CurrencyInfo_GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local C_Item_DoesItemContainSpec = C_Item.DoesItemContainSpec
local C_Item_GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo
local C_ItemUpgrade_GetHighWatermarkForSlot = C_ItemUpgrade.GetHighWatermarkForSlot
local C_ItemUpgrade_GetHighWatermarkSlotForItem = C_ItemUpgrade.GetHighWatermarkSlotForItem
local CreateFrame = CreateFrame
local GetAchievementInfo = GetAchievementInfo
local GetInventoryItemLink = GetInventoryItemLink

local tIndexOf = tIndexOf

local Enum_ItemRedundancySlot_MainhandWeapon = Enum.ItemRedundancySlot.MainhandWeapon
local Enum_ItemRedundancySlot_Offhand = Enum.ItemRedundancySlot.Offhand
local Enum_ItemRedundancySlot_OnehandWeapon = Enum.ItemRedundancySlot.OnehandWeapon
local Enum_ItemRedundancySlot_OnehandWeaponSecond = Enum.ItemRedundancySlot.OnehandWeaponSecond
local Enum_ItemRedundancySlot_Twohand = Enum.ItemRedundancySlot.Twohand

local BACKPACK_CONTAINER = BACKPACK_CONTAINER
local INVSLOT_FIRST_EQUIPPED = INVSLOT_FIRST_EQUIPPED
local INVSLOT_LAST_EQUIPPED = INVSLOT_LAST_EQUIPPED
local NUM_BAG_SLOTS = NUM_BAG_SLOTS

local atlasReady = '|A:ui-lfg-readymark-raid:14:14|a'
local atlasDecline = '|A:ui-lfg-declinemark-raid:14:14|a'
local atlasWarband = '|A:warbands-icon:14:14|a'

---@class ClassUsableWeaponData
---@field useTwoHand boolean
---@field useMainAndOffHand boolean
---@field useOneAndOffHand boolean
---@field useDualOneHand boolean

---@type ClassUsableWeaponData[]
local weaponDatas = {
    {
        -- Warrior
        useTwoHand = true,
        useMainAndOffHand = false,
        useOneAndOffHand = true,
        useDualOneHand = true,
    },
    {
        -- Paladin
        useTwoHand = true,
        useMainAndOffHand = true,
        useOneAndOffHand = true,
        useDualOneHand = false,
    },
    {
        -- Hunter
        useTwoHand = true,
        useMainAndOffHand = false,
        useOneAndOffHand = false,
        useDualOneHand = true,
    },
    {
        -- Rogue
        useTwoHand = false,
        useMainAndOffHand = false,
        useOneAndOffHand = false,
        useDualOneHand = true,
    },
    {
        -- Priest
        useTwoHand = true,
        useMainAndOffHand = true,
        useOneAndOffHand = false,
        useDualOneHand = false,
    },
    {
        -- Death Knight
        useTwoHand = true,
        useMainAndOffHand = false,
        useOneAndOffHand = false,
        useDualOneHand = true,
    },
    {
        -- Shaman
        useTwoHand = true,
        useMainAndOffHand = true,
        useOneAndOffHand = false,
        useDualOneHand = true,
    },
    {
        -- Mage
        useTwoHand = true,
        useMainAndOffHand = true,
        useOneAndOffHand = false,
        useDualOneHand = false,
    },
    {
        -- Warlock
        useTwoHand = true,
        useMainAndOffHand = true,
        useOneAndOffHand = false,
        useDualOneHand = false,
    },
    {
        -- Monk
        useTwoHand = true,
        useMainAndOffHand = true,
        useOneAndOffHand = false,
        useDualOneHand = true,
    },
    {
        -- Druid
        useTwoHand = true,
        useMainAndOffHand = true,
        useOneAndOffHand = false,
        useDualOneHand = false,
    },
    {
        -- Demon Hunter
        useTwoHand = false,
        useMainAndOffHand = false,
        useOneAndOffHand = false,
        useDualOneHand = true,
    },
    {
        -- Evoker
        useTwoHand = true,
        useMainAndOffHand = true,
        useOneAndOffHand = false,
        useDualOneHand = false,
    },
}
local weaponData = weaponDatas[E.myClassID]

---@class ArmorInventorySlotData
---@field inventorySlotID number
---@field itemRedundancySlot Enum.ItemRedundancySlot
---@field multipleItemSlotIndex number?
---@field name string

---@type ArmorInventorySlotData[]
local armorSlots = {
    {
        inventorySlotID = 1,
        itemRedundancySlot = Enum.ItemRedundancySlot.Head,
        name = INVTYPE_HEAD,
    },
    {
        inventorySlotID = 2,
        itemRedundancySlot = Enum.ItemRedundancySlot.Neck,
        name = INVTYPE_NECK,
    },
    {
        inventorySlotID = 3,
        itemRedundancySlot = Enum.ItemRedundancySlot.Shoulder,
        name = INVTYPE_SHOULDER,
    },
    {
        inventorySlotID = 5,
        itemRedundancySlot = Enum.ItemRedundancySlot.Chest,
        name = INVTYPE_CHEST,
    },
    {
        inventorySlotID = 6,
        itemRedundancySlot = Enum.ItemRedundancySlot.Waist,
        name = INVTYPE_WAIST,
    },
    {
        inventorySlotID = 7,
        itemRedundancySlot = Enum.ItemRedundancySlot.Legs,
        name = INVTYPE_LEGS,
    },
    {
        inventorySlotID = 8,
        itemRedundancySlot = Enum.ItemRedundancySlot.Feet,
        name = INVTYPE_FEET,
    },
    {
        inventorySlotID = 9,
        itemRedundancySlot = Enum.ItemRedundancySlot.Wrist,
        name = INVTYPE_WRIST,
    },
    {
        inventorySlotID = 10,
        itemRedundancySlot = Enum.ItemRedundancySlot.Hand,
        name = INVTYPE_HAND,
    },
    {
        inventorySlotID = 11,
        itemRedundancySlot = Enum.ItemRedundancySlot.Finger,
        multipleItemSlotIndex = 1,
        name = INVTYPE_FINGER .. 1,
    },
    {
        inventorySlotID = 12,
        itemRedundancySlot = Enum.ItemRedundancySlot.Finger,
        multipleItemSlotIndex = 2,
        name = INVTYPE_FINGER .. 2,
    },
    {
        inventorySlotID = 13,
        itemRedundancySlot = Enum.ItemRedundancySlot.Trinket,
        multipleItemSlotIndex = 1,
        name = INVTYPE_TRINKET .. 1,
    },
    {
        inventorySlotID = 14,
        itemRedundancySlot = Enum.ItemRedundancySlot.Trinket,
        multipleItemSlotIndex = 2,
        name = INVTYPE_TRINKET .. 2,
    },
    {
        inventorySlotID = 15,
        itemRedundancySlot = Enum.ItemRedundancySlot.Cloak,
        name = INVTYPE_CLOAK,
    },
}


---@class WeaponCombinationData
---@field label string
---@field isTwoHand boolean
---@field slots ArmorInventorySlotData[]

---@type WeaponCombinationData[]
local weaponCombinations = {}

if weaponData.useTwoHand then
    table_insert(weaponCombinations, {
        label = '双手武器',
        isTwoHand = true,
        slots = {
            {
                inventorySlotID = 16,
                itemRedundancySlot = Enum.ItemRedundancySlot.Twohand,
                name = INVTYPE_2HWEAPON,
            },
        },
    })
end

if weaponData.useMainAndOffHand then
    table_insert(weaponCombinations, {
        label = '智力主副手',
        isTwoHand = false,
        slots = {
            {
                inventorySlotID = 16,
                itemRedundancySlot = Enum.ItemRedundancySlot.MainhandWeapon,
                name = INVTYPE_WEAPONMAINHAND,
            },
            {
                inventorySlotID = 17,
                itemRedundancySlot = Enum.ItemRedundancySlot.Offhand,
                name = INVTYPE_WEAPONOFFHAND,
            },
        },
    })
end

if weaponData.useOneAndOffHand then
    table_insert(weaponCombinations, {
        label = '力量主副手',
        isTwoHand = false,
        slots = {
            {
                inventorySlotID = 16,
                itemRedundancySlot = Enum.ItemRedundancySlot.OnehandWeapon,
                name = INVTYPE_WEAPON,
            },
            {
                inventorySlotID = 17,
                itemRedundancySlot = Enum.ItemRedundancySlot.Offhand,
                name = INVTYPE_WEAPONOFFHAND,
            },
        },
    })
end

if weaponData.useDualOneHand then
    table_insert(weaponCombinations, {
        label = '双持单手',
        isTwoHand = false,
        slots = {
            {
                inventorySlotID = 16,
                itemRedundancySlot = Enum.ItemRedundancySlot.OnehandWeapon,
                name = INVTYPE_WEAPON,
            },
            {
                inventorySlotID = 17,
                itemRedundancySlot = Enum.ItemRedundancySlot.OnehandWeaponSecond,
                name = INVTYPE_WEAPON,
            },
        },
    })
end

---@class CrestAchievementData
---@field achievementID number
---@field achievementItemLevel number
---@field currencyID number
---@field maxItemLevel number
---@field minItemLevel number
---@field isAverageItemLevel boolean
---@field conditionalCostScaling number
---@field maxCurrencyCount number
---@field upgradePath number[]
---@field upgradePathCost table<number, number>
---@field itemLevelXCost table<number, number>
---@field itemBonusLists table<number, number>

---@type CrestAchievementData[]
local achievementDatas = {
    ---AUTO_GENERATED LEADING CrestAchievement
    -- ItemGroupIlvlScalingID 11
    {
        achievementID = 61809, -- Adventurer of the Dawn
        achievementItemLevel = 237,
        currencyID = 3383, -- Adventurer Dawncrest
        maxItemLevel = 237,
        minItemLevel = 220,
        isAverageItemLevel = false,
        conditionalCostScaling = 0.5,
        maxCurrencyCount = 100,
        upgradePath = {
            220, -- Adventurer 1/6
            224, -- Adventurer 2/6
            227, -- Adventurer 3/6
            230, -- Adventurer 4/6
            233, -- Adventurer 5/6
            237, -- Adventurer 6/6
        },
        upgradePathCost = {
            [220] = 0,  -- Adventurer 1/6
            [224] = 20, -- Adventurer 2/6
            [227] = 20, -- Adventurer 3/6
            [230] = 20, -- Adventurer 4/6
            [233] = 20, -- Adventurer 5/6
            [237] = 20, -- Adventurer 6/6
        },
        itemLevelXCost = {
            [220] = 100, -- Adventurer 1/6
            [224] = 80,  -- Adventurer 2/6
            [227] = 60,  -- Adventurer 3/6
            [230] = 40,  -- Adventurer 4/6
            [233] = 20,  -- Adventurer 5/6
            [237] = 0,   -- Adventurer 6/6
        },
        itemBonusLists = {
            [12769] = 100, -- Adventurer 1/6
            [12770] = 80,  -- Adventurer 2/6
            [12771] = 60,  -- Adventurer 3/6
            [12772] = 40,  -- Adventurer 4/6
            [12773] = 20,  -- Adventurer 5/6
            [12774] = 0,   -- Adventurer 6/6
        },
    },
    {
        achievementID = 42767, -- Veteran of the Dawn
        achievementItemLevel = 250,
        currencyID = 3341, -- Veteran Dawncrest
        maxItemLevel = 250,
        minItemLevel = 233,
        isAverageItemLevel = false,
        conditionalCostScaling = 0.5,
        maxCurrencyCount = 100,
        upgradePath = {
            233, -- Veteran 1/6
            237, -- Veteran 2/6
            240, -- Veteran 3/6
            243, -- Veteran 4/6
            246, -- Veteran 5/6
            250, -- Veteran 6/6
        },
        upgradePathCost = {
            [233] = 0,  -- Veteran 1/6
            [237] = 20, -- Veteran 2/6
            [240] = 20, -- Veteran 3/6
            [243] = 20, -- Veteran 4/6
            [246] = 20, -- Veteran 5/6
            [250] = 20, -- Veteran 6/6
        },
        itemLevelXCost = {
            [233] = 100, -- Veteran 1/6
            [237] = 80,  -- Veteran 2/6
            [240] = 60,  -- Veteran 3/6
            [243] = 40,  -- Veteran 4/6
            [246] = 20,  -- Veteran 5/6
            [250] = 0,   -- Veteran 6/6
        },
        itemBonusLists = {
            [12777] = 100, -- Veteran 1/6
            [12778] = 80,  -- Veteran 2/6
            [12779] = 60,  -- Veteran 3/6
            [12780] = 40,  -- Veteran 4/6
            [12781] = 20,  -- Veteran 5/6
            [12782] = 0,   -- Veteran 6/6
        },
    },
    {
        achievementID = 42768, -- Champion of the Dawn
        achievementItemLevel = 263,
        currencyID = 3343, -- Champion Dawncrest
        maxItemLevel = 263,
        minItemLevel = 246,
        isAverageItemLevel = false,
        conditionalCostScaling = 0.5,
        maxCurrencyCount = 100,
        upgradePath = {
            246, -- Champion 1/6
            250, -- Champion 2/6
            253, -- Champion 3/6
            256, -- Champion 4/6
            259, -- Champion 5/6
            263, -- Champion 6/6
        },
        upgradePathCost = {
            [246] = 0,  -- Champion 1/6
            [250] = 20, -- Champion 2/6
            [253] = 20, -- Champion 3/6
            [256] = 20, -- Champion 4/6
            [259] = 20, -- Champion 5/6
            [263] = 20, -- Champion 6/6
        },
        itemLevelXCost = {
            [246] = 100, -- Champion 1/6
            [250] = 80,  -- Champion 2/6
            [253] = 60,  -- Champion 3/6
            [256] = 40,  -- Champion 4/6
            [259] = 20,  -- Champion 5/6
            [263] = 0,   -- Champion 6/6
        },
        itemBonusLists = {
            [12785] = 100, -- Champion 1/6
            [12786] = 80,  -- Champion 2/6
            [12787] = 60,  -- Champion 3/6
            [12788] = 40,  -- Champion 4/6
            [12789] = 20,  -- Champion 5/6
            [12790] = 0,   -- Champion 6/6
        },
    },
    {
        achievementID = 42769, -- Hero of the Dawn
        achievementItemLevel = 276,
        currencyID = 3345, -- Hero Dawncrest
        maxItemLevel = 276,
        minItemLevel = 259,
        isAverageItemLevel = false,
        conditionalCostScaling = 0.5,
        maxCurrencyCount = 100,
        upgradePath = {
            259, -- Hero 1/6
            263, -- Hero 2/6
            266, -- Hero 3/6
            269, -- Hero 4/6
            272, -- Hero 5/6
            276, -- Hero 6/6
        },
        upgradePathCost = {
            [259] = 0,  -- Hero 1/6
            [263] = 20, -- Hero 2/6
            [266] = 20, -- Hero 3/6
            [269] = 20, -- Hero 4/6
            [272] = 20, -- Hero 5/6
            [276] = 20, -- Hero 6/6
        },
        itemLevelXCost = {
            [259] = 100, -- Hero 1/6
            [263] = 80,  -- Hero 2/6
            [266] = 60,  -- Hero 3/6
            [269] = 40,  -- Hero 4/6
            [272] = 20,  -- Hero 5/6
            [276] = 0,   -- Hero 6/6
        },
        itemBonusLists = {
            [12793] = 100, -- Hero 1/6
            [12794] = 80,  -- Hero 2/6
            [12795] = 60,  -- Hero 3/6
            [12796] = 40,  -- Hero 4/6
            [12797] = 20,  -- Hero 5/6
            [12798] = 0,   -- Hero 6/6
        },
    },
    {
        achievementID = 42770, -- Myth of the Dawn
        achievementItemLevel = 285,
        currencyID = 3347, -- Myth Dawncrest
        maxItemLevel = 289,
        minItemLevel = 272,
        isAverageItemLevel = true,
        conditionalCostScaling = 0.5,
        maxCurrencyCount = 100,
        upgradePath = {
            272, -- Myth 1/6
            276, -- Myth 2/6
            279, -- Myth 3/6
            282, -- Myth 4/6
            285, -- Myth 5/6
            289, -- Myth 6/6
        },
        upgradePathCost = {
            [272] = 0,  -- Myth 1/6
            [276] = 20, -- Myth 2/6
            [279] = 20, -- Myth 3/6
            [282] = 20, -- Myth 4/6
            [285] = 20, -- Myth 5/6
            [289] = 20, -- Myth 6/6
        },
        itemLevelXCost = {
            [272] = 100, -- Myth 1/6
            [276] = 80,  -- Myth 2/6
            [279] = 60,  -- Myth 3/6
            [282] = 40,  -- Myth 4/6
            [285] = 20,  -- Myth 5/6
            [289] = 0,   -- Myth 6/6
        },
        itemBonusLists = {
            [12801] = 100, -- Myth 1/6
            [12802] = 80,  -- Myth 2/6
            [12803] = 60,  -- Myth 3/6
            [12804] = 40,  -- Myth 4/6
            [12805] = 20,  -- Myth 5/6
            [12806] = 0,   -- Myth 6/6
        },
    },
    ---AUTO_GENERATED TAILING CrestAchievement
}

---@type table<number, number>
local itemBonusListXAchievementIndex = {}
for index, data in ipairs(achievementDatas) do
    for itemBonusListID in pairs(data.itemBonusLists) do
        itemBonusListXAchievementIndex[itemBonusListID] = index
    end
end

do
    ---@type table<Enum.ItemRedundancySlot, number[]>
    local itemRedundancySlotItemLevels = {}
    ---@type table<number, table<Enum.ItemRedundancySlot, number>>
    local upgradePathItemCount = {}

    local itemStringPattern = '^\124cnIQ[0-9]:\124Hitem:%d+:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:(.+)\124h%[.+%]\124h\124r$'

    ---@param itemLink string
    ---@return number?
    local function ParseItemLink(itemLink)
        ---@type string?
        local itemBonusString = string_match(itemLink, itemStringPattern)
        if not itemBonusString then return end

        local currentBonusIndex = 0
        local numBonusIds
        for text in string_gmatch(itemBonusString, '(%d*):') do
            local value = tonumber(text, 10)
            if not numBonusIds then
                numBonusIds = value or 0
            else
                currentBonusIndex = currentBonusIndex + 1

                if itemBonusListXAchievementIndex[value] then
                    return itemBonusListXAchievementIndex[value]
                end

                if currentBonusIndex >= numBonusIds then
                    break
                end
            end
        end
    end

    ---@param itemLink string
    local function ProcessItem(itemLink)
        local containSpec = C_Item_DoesItemContainSpec(itemLink, E.myClassID)
        if not containSpec then return end

        local itemRedundancySlot = C_ItemUpgrade_GetHighWatermarkSlotForItem(itemLink)
        if itemRedundancySlot then
            local itemLevel = C_Item_GetDetailedItemLevelInfo(itemLink)
            if itemLevel then
                itemRedundancySlotItemLevels[itemRedundancySlot] = itemRedundancySlotItemLevels[itemRedundancySlot] or {}
                table_insert(itemRedundancySlotItemLevels[itemRedundancySlot], itemLevel)

                local achievementIndex = ParseItemLink(itemLink)
                if achievementIndex then
                    upgradePathItemCount[achievementIndex] = upgradePathItemCount[achievementIndex] or {}
                    upgradePathItemCount[achievementIndex][itemRedundancySlot] = (upgradePathItemCount[achievementIndex][itemRedundancySlot] or 0) + 1
                end
            end
        end
    end

    local function ItemLevelCompare(a, b)
        return a > b
    end

    ---@return table<Enum.ItemRedundancySlot, number[]> itemRedundancySlotItemLevels, table<number, table<Enum.ItemRedundancySlot, number>> upgradePathItemCount
    function CA:ScanItems()
        wipe(itemRedundancySlotItemLevels)
        wipe(upgradePathItemCount)

        for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
            local itemLink = GetInventoryItemLink('player', i)
            if itemLink then
                ProcessItem(itemLink)
            end
        end

        for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            local numSlots = C_Container_GetContainerNumSlots(bagID)
            for slotID = 1, numSlots do
                local itemInfo = C_Container_GetContainerItemInfo(bagID, slotID)
                if itemInfo then
                    ProcessItem(itemInfo.hyperlink)
                end
            end
        end

        for _, itemLevels in pairs(itemRedundancySlotItemLevels) do
            table_sort(itemLevels, ItemLevelCompare)
        end

        -- XXX: Onehand Weapon Second special handle
        if weaponData.useDualOneHand then
            itemRedundancySlotItemLevels[Enum_ItemRedundancySlot_OnehandWeaponSecond] = { itemRedundancySlotItemLevels[Enum_ItemRedundancySlot_OnehandWeapon][2] }
            for _, data in pairs(upgradePathItemCount) do
                if data[Enum_ItemRedundancySlot_OnehandWeapon] then
                    data[Enum_ItemRedundancySlot_OnehandWeaponSecond] = data[Enum_ItemRedundancySlot_OnehandWeapon] - 1
                end
            end
        end

        return itemRedundancySlotItemLevels, upgradePathItemCount
    end
end

---@param achievementData CrestAchievementData
---@param slotItemLevel number
---@param accountHighWatermark number
---@param completed boolean
---@return number cost, number[]? costList, number[]? rewardList
function CA:GetItemUpgradeCost(achievementData, slotItemLevel, accountHighWatermark, completed)
    local multiplier = completed and achievementData.conditionalCostScaling or 1

    if not achievementData.isAverageItemLevel then
        local cost = slotItemLevel >= achievementData.minItemLevel and achievementData.itemLevelXCost[slotItemLevel] or achievementData.maxCurrencyCount
        return math_ceil(cost * multiplier)
    end

    local cost = 0
    ---@type number[]
    local costList = {}
    ---@type number[]
    local rewardList = {}

    local index = tIndexOf(achievementData.upgradePath, slotItemLevel) or 1
    for i = index + 1, #achievementData.upgradePath do
        local itemLevel = achievementData.upgradePath[i]
        local itemLevelCost = achievementData.upgradePathCost[itemLevel] * (itemLevel <= accountHighWatermark and multiplier or 1)

        cost = cost + itemLevelCost
        table_insert(costList, cost)
        table_insert(rewardList, itemLevel - slotItemLevel)
    end

    return cost, costList, rewardList
end

---@param currentItemLevel number
---@param targetItemLevel number
---@param costs number[][]
---@param rewards number[][]
---@return number minCost, table<number, number> slotUpgradeCount
function CA:GetUpgradeMinCost(currentItemLevel, targetItemLevel, costs, rewards)
    local dpLength = 0
    local dp = { [0] = 0 }
    setmetatable(dp, {
        __index = function()
            return math_huge
        end,
        __newindex = function(t, k, v)
            if k > dpLength then
                dpLength = k
            end

            rawset(t, k, v)
        end,
    })

    ---@type table<number, number>
    local prevRecord = {}
    ---@type table<number, { slotIndex: number, times: number }>
    local costRecord = {}

    for slotIndex, slotCosts in pairs(costs) do
        local maxTimes = #slotCosts
        local slotRewards = rewards[slotIndex]

        for i = dpLength, 0, -1 do
            if dp[i] ~= math_huge then
                for times = 1, maxTimes do
                    local reward = slotRewards[times]
                    if dp[i] + slotCosts[times] < dp[i + reward] then
                        dp[i + reward] = dp[i] + slotCosts[times]
                        prevRecord[i + reward] = i
                        costRecord[i + reward] = { slotIndex = slotIndex, times = times }
                    end
                end
            end
        end
    end

    local minCost = math_huge
    local minCostIndex = 0
    for i = dpLength, targetItemLevel - currentItemLevel, -1 do
        if dp[i] < minCost then
            minCost = dp[i]
            minCostIndex = i
        end
    end

    ---@type table<number, number>
    local slotUpgradeCount = {}
    local currentIndex = minCostIndex
    while currentIndex > 0 do
        local record = costRecord[currentIndex]
        slotUpgradeCount[record.slotIndex] = record.times
        currentIndex = prevRecord[currentIndex]
    end

    return minCost, slotUpgradeCount
end

---@alias SlotUpgradeCount { slotName: string, times: number }

---@class CrestAchievementCostData
---@field totalCost number
---@field minCost number?
---@field minCostSlotUpgradeCount SlotUpgradeCount[]?
---@field vaildMinCost number?
---@field vaildMinCostSlotUpgradeCount SlotUpgradeCount[]?

---@return ('completed' | 'warband' | 'incompleted')[] achievementStatus, CrestAchievementCostData[] achievementCost, number[] armorSlotItemLevelDisplay, table<number, number[]> armorSlotUpgradeCost, table<number, boolean[]> armorSlotHasVaildItem, number[][] weaponCombinationItemLevelDisplay, table<number, number[]>[] weaponCombinationUpgradeCost, table<number, boolean[]>[] weaponCombinationHasVaildItem
function CA:GetItemUpgradeData()
    local itemRedundancySlotItemLevels, upgradePathItemCount = self:ScanItems()

    ---@type ('completed' | 'warband' | 'incompleted')[]
    local achievementStatus = {}
    for index, data in ipairs(achievementDatas) do
        local _, _, _, completed, _, _, _, _, _, _, _, _, wasEarnedByMe = GetAchievementInfo(data.achievementID)
        achievementStatus[index] = (completed and wasEarnedByMe) and 'completed' or (completed and 'warband' or 'incompleted')
    end

    local armorSlotItemLevel = 0
    ---@type number[]
    local armorSlotItemLevelDisplay = {}
    ---@type table<number, number[]>
    local armorSlotUpgradeCost = {}
    ---@type table<number, boolean[]>
    local armorSlotHasVaildItem = {}
    ---@type table<number, number[][]>
    local armorCostList = {}
    ---@type table<number, number[][]>
    local armorRewardList = {}

    for index, armorSlotData in ipairs(armorSlots) do
        local slotIndex = armorSlotData.multipleItemSlotIndex or 1
        local itemRedundancySlot = armorSlotData.itemRedundancySlot

        local characterHighWatermark, accountHighWatermark = C_ItemUpgrade_GetHighWatermarkForSlot(itemRedundancySlot)

        local slotItemLevels = itemRedundancySlotItemLevels[itemRedundancySlot]
        local slotItemLevel = slotItemLevels[slotIndex] or characterHighWatermark
        armorSlotItemLevelDisplay[index] = slotItemLevel
        armorSlotItemLevel = armorSlotItemLevel + slotItemLevel

        for achievementIndex, achievementData in ipairs(achievementDatas) do
            armorSlotUpgradeCost[achievementIndex] = armorSlotUpgradeCost[achievementIndex] or {}
            armorSlotHasVaildItem[achievementIndex] = armorSlotHasVaildItem[achievementIndex] or {}
            if achievementData.isAverageItemLevel then
                armorCostList[achievementIndex] = armorCostList[achievementIndex] or {}
                armorRewardList[achievementIndex] = armorRewardList[achievementIndex] or {}
            end

            if slotItemLevel >= achievementData.maxItemLevel then
                armorSlotUpgradeCost[achievementIndex][index] = 0
                armorSlotHasVaildItem[achievementIndex][index] = true

                if achievementData.isAverageItemLevel then
                    armorCostList[achievementIndex][index] = {}
                    armorRewardList[achievementIndex][index] = {}
                end
            else
                local slotCost, slotCostList, slotRewardList = self:GetItemUpgradeCost(achievementData, slotItemLevel, accountHighWatermark, achievementStatus[achievementIndex] ~= 'incompleted')
                local hasVaildItem = upgradePathItemCount[achievementIndex]
                    and upgradePathItemCount[achievementIndex][itemRedundancySlot]
                    and upgradePathItemCount[achievementIndex][itemRedundancySlot] >= slotIndex

                armorSlotUpgradeCost[achievementIndex][index] = slotCost
                armorSlotHasVaildItem[achievementIndex][index] = hasVaildItem

                if achievementData.isAverageItemLevel then
                    armorCostList[achievementIndex][index] = slotCostList
                    armorRewardList[achievementIndex][index] = slotRewardList
                end
            end
        end
    end

    ---@type number[]
    local weaponCombinationItemLevel = {}
    ---@type number[][]
    local weaponCombinationItemLevelDisplay = {}
    ---@type table<number, number[]>[]
    local weaponCombinationUpgradeCost = {}
    ---@type table<number, boolean[]>[]
    local weaponCombinationHasVaildItem = {}
    ---@type table<number, number[][]>[]
    local weaponCombinationCostList = {}
    ---@type table<number, number[][]>[]
    local weaponCombinationRewardList = {}

    local twoHandCharacterHighWatermark, twoHandAccountHighWatermark = C_ItemUpgrade_GetHighWatermarkForSlot(Enum_ItemRedundancySlot_Twohand)
    local mainHandCharacterHighWatermark, mainHandAccountHighWatermark = C_ItemUpgrade_GetHighWatermarkForSlot(Enum_ItemRedundancySlot_MainhandWeapon)
    local oneHandCharacterHighWatermark, oneHandAccountHighWatermark = C_ItemUpgrade_GetHighWatermarkForSlot(Enum_ItemRedundancySlot_OnehandWeapon)
    local offHandCharacterHighWatermark, offHandAccountHighWatermark = C_ItemUpgrade_GetHighWatermarkForSlot(Enum_ItemRedundancySlot_Offhand)
    local oneHandSecondCharacterHighWatermark, oneHandSecondAccountHighWatermark = C_ItemUpgrade_GetHighWatermarkForSlot(Enum_ItemRedundancySlot_OnehandWeaponSecond)

    local twoHandCharacterItemLevel = twoHandCharacterHighWatermark
    local twoHandAccountItemLevel = twoHandAccountHighWatermark
    local mainHandCharacterItemLevel = math_max(mainHandCharacterHighWatermark, oneHandCharacterHighWatermark)
    local mainHandAccountItemLevel = math_max(mainHandAccountHighWatermark, oneHandAccountHighWatermark)
    local offHandCharacterItemLevel = math_max(offHandCharacterHighWatermark, oneHandSecondCharacterHighWatermark)
    local offHandAccountItemLevel = math_max(offHandAccountHighWatermark, oneHandSecondAccountHighWatermark)

    for index, weaponCombination in ipairs(weaponCombinations) do
        weaponCombinationItemLevel[index] = 0
        weaponCombinationItemLevelDisplay[index] = {}
        weaponCombinationUpgradeCost[index] = {}
        weaponCombinationHasVaildItem[index] = {}
        weaponCombinationCostList[index] = {}
        weaponCombinationRewardList[index] = {}

        for i, slotData in ipairs(weaponCombination.slots) do
            local itemRedundancySlot = slotData.itemRedundancySlot

            local characterHighWatermark, accountHighWatermark = C_ItemUpgrade_GetHighWatermarkForSlot(itemRedundancySlot)

            local slotItemLevels = itemRedundancySlotItemLevels[itemRedundancySlot]
            local slotItemLevel = slotItemLevels[1] or characterHighWatermark
            weaponCombinationItemLevelDisplay[index][i] = slotItemLevel

            -- handle weapon discount here
            -- two hand weapon can discount main hand and off hand weapon
            -- main hand weapon can discount other main hand weapon
            -- off hand weapon can discount other off hand weapon
            -- main hand and off hand weapon combination can discount two hand weapon
            if weaponCombination.isTwoHand then
                -- this is two hand weapon
                -- handle main and off hand combination to discount two hand weapon
                local combinationCharacterItemLevel = math_min(mainHandCharacterItemLevel, offHandCharacterItemLevel)
                local combinationAccountItemLevel = math_min(mainHandAccountItemLevel, offHandAccountItemLevel)

                if slotItemLevel < combinationCharacterItemLevel then
                    slotItemLevel = combinationCharacterItemLevel
                end

                if accountHighWatermark < combinationAccountItemLevel then
                    accountHighWatermark = combinationAccountItemLevel
                end

                weaponCombinationItemLevel[index] = weaponCombinationItemLevel[index] + slotItemLevel * 2 -- two hand weapon counts double
            else
                -- this is main hand and off hand combination
                -- handle two hand weapon to discount main hand and off hand weapon
                if slotItemLevel < twoHandCharacterItemLevel then
                    slotItemLevel = twoHandCharacterItemLevel
                end

                if accountHighWatermark < twoHandAccountItemLevel then
                    accountHighWatermark = twoHandAccountItemLevel
                end

                if i <= 1 then
                    -- this is main hand weapon
                    -- handle main hand weapon to discount other main hand weapon
                    if slotItemLevel < mainHandCharacterItemLevel then
                        slotItemLevel = mainHandCharacterItemLevel
                    end

                    if accountHighWatermark < mainHandAccountItemLevel then
                        accountHighWatermark = mainHandAccountItemLevel
                    end
                else
                    -- this is off hand weapon
                    -- handle off hand weapon to discount other off hand weapon
                    if slotItemLevel < offHandCharacterItemLevel then
                        slotItemLevel = offHandCharacterItemLevel
                    end

                    if accountHighWatermark < offHandAccountItemLevel then
                        accountHighWatermark = offHandAccountItemLevel
                    end
                end

                weaponCombinationItemLevel[index] = weaponCombinationItemLevel[index] + slotItemLevel
            end

            for achievementIndex, achievementData in ipairs(achievementDatas) do
                weaponCombinationUpgradeCost[index][achievementIndex] = weaponCombinationUpgradeCost[index][achievementIndex] or {}
                weaponCombinationHasVaildItem[index][achievementIndex] = weaponCombinationHasVaildItem[index][achievementIndex] or {}
                if achievementData.isAverageItemLevel then
                    weaponCombinationCostList[index][achievementIndex] = weaponCombinationCostList[index][achievementIndex] or {}
                    weaponCombinationRewardList[index][achievementIndex] = weaponCombinationRewardList[index][achievementIndex] or {}
                end

                if slotItemLevel >= achievementData.maxItemLevel then
                    weaponCombinationUpgradeCost[index][achievementIndex][i] = 0
                    weaponCombinationHasVaildItem[index][achievementIndex][i] = true

                    if achievementData.isAverageItemLevel then
                        weaponCombinationCostList[index][achievementIndex][i] = {}
                        weaponCombinationRewardList[index][achievementIndex][i] = {}
                    end
                else
                    local slotCost, slotCostList, slotRewardList = self:GetItemUpgradeCost(achievementData, slotItemLevel, accountHighWatermark, achievementStatus[achievementIndex] ~= 'incompleted')
                    local hasVaildItem = upgradePathItemCount[achievementIndex]
                        and upgradePathItemCount[achievementIndex][itemRedundancySlot]
                        and upgradePathItemCount[achievementIndex][itemRedundancySlot] >= 1

                    weaponCombinationUpgradeCost[index][achievementIndex][i] = slotCost
                    weaponCombinationHasVaildItem[index][achievementIndex][i] = hasVaildItem

                    if achievementData.isAverageItemLevel then
                        if weaponCombination.isTwoHand then
                            -- two hand weapon counts double, so double the reward
                            for j = 1, #slotRewardList do
                                ---@diagnostic disable-next-line: need-check-nil
                                slotRewardList[j] = slotRewardList[j] * 2
                            end
                        end

                        weaponCombinationCostList[index][achievementIndex][i] = slotCostList
                        weaponCombinationRewardList[index][achievementIndex][i] = slotRewardList
                    end
                end
            end
        end
    end

    ---@type CrestAchievementCostData[]
    local achievementCost = {}
    for achievementIndex, achievementData in ipairs(achievementDatas) do
        local armorCosts = 0
        for _, slotCost in ipairs(armorSlotUpgradeCost[achievementIndex]) do
            armorCosts = armorCosts + slotCost
        end

        local minWeaponCost = math_huge
        for _, combinationCost in ipairs(weaponCombinationUpgradeCost) do
            local weaponCosts = 0
            for _, slotCost in ipairs(combinationCost[achievementIndex]) do
                weaponCosts = weaponCosts + slotCost
            end

            if weaponCosts < minWeaponCost then
                minWeaponCost = weaponCosts
            end
        end

        local totalCost = armorCosts + minWeaponCost

        if not achievementData.isAverageItemLevel then
            achievementCost[achievementIndex] = {
                totalCost = totalCost,
            }
        elseif achievementStatus[achievementIndex] == 'completed' then
            achievementCost[achievementIndex] = {
                totalCost = totalCost,
                minCost = 0,
                vaildMinCost = 0,
            }
        else
            ---@class CrestAchievementUpgradePlan
            ---@field weaponCombinationIndex number
            ---@field weaponSlotCount number
            ---@field itemLevel number
            ---@field costs number[][]
            ---@field rewards number[][]

            ---@type CrestAchievementUpgradePlan[]
            local plans = {}
            ---@type CrestAchievementUpgradePlan[]
            local vaildPlans = {}

            for index, weaponCombination in ipairs(weaponCombinations) do
                local itemLevel = armorSlotItemLevel + weaponCombinationItemLevel[index]
                local costs = {}
                local rewards = {}
                local vaildCosts = {}
                local vaildRewards = {}

                for i = 1, #weaponCombination.slots do
                    table_insert(costs, weaponCombinationCostList[index][achievementIndex][i])
                    table_insert(rewards, weaponCombinationRewardList[index][achievementIndex][i])

                    if weaponCombinationHasVaildItem[index][achievementIndex][i] then
                        table_insert(vaildCosts, weaponCombinationCostList[index][achievementIndex][i])
                        table_insert(vaildRewards, weaponCombinationRewardList[index][achievementIndex][i])
                    else
                        table_insert(vaildCosts, {})
                        table_insert(vaildRewards, {})
                    end
                end

                for i = 1, #armorSlots do
                    table_insert(costs, armorCostList[achievementIndex][i])
                    table_insert(rewards, armorRewardList[achievementIndex][i])

                    if armorSlotHasVaildItem[achievementIndex][i] then
                        table_insert(vaildCosts, armorCostList[achievementIndex][i])
                        table_insert(vaildRewards, armorRewardList[achievementIndex][i])
                    else
                        table_insert(vaildCosts, {})
                        table_insert(vaildRewards, {})
                    end
                end

                table_insert(plans, {
                    weaponCombinationIndex = index,
                    itemLevel = itemLevel,
                    costs = costs,
                    rewards = rewards,
                })

                table_insert(vaildPlans, {
                    weaponCombinationIndex = index,
                    itemLevel = itemLevel,
                    costs = vaildCosts,
                    rewards = vaildRewards,
                })
            end

            local targetItemLevel = achievementData.achievementItemLevel * 16

            local minCost = math_huge
            ---@type SlotUpgradeCount[]
            local minCostSlotUpgradeCount = {}
            for _, plan in ipairs(plans) do
                local cost, slotUpgradeCount = self:GetUpgradeMinCost(plan.itemLevel, targetItemLevel, plan.costs, plan.rewards)
                if cost < minCost then
                    minCost = cost

                    wipe(minCostSlotUpgradeCount)
                    local weaponCombination = weaponCombinations[plan.weaponCombinationIndex]
                    local weaponSlotCount = #weaponCombination.slots
                    for slotIndex = 1, #plan.costs do
                        if slotUpgradeCount[slotIndex] then
                            local slotName = slotIndex <= weaponSlotCount and weaponCombination.slots[slotIndex].name or armorSlots[slotIndex - weaponSlotCount].name
                            table_insert(minCostSlotUpgradeCount, { slotName = slotName, times = slotUpgradeCount[slotIndex] })
                        end
                    end
                end
            end

            ---@type number?
            local vaildMinCost = math_huge
            ---@type SlotUpgradeCount[]?
            local vaildMinCostSlotUpgradeCount = {}
            for _, plan in ipairs(vaildPlans) do
                local cost, slotUpgradeCount = self:GetUpgradeMinCost(plan.itemLevel, targetItemLevel, plan.costs, plan.rewards)
                if cost < vaildMinCost then
                    vaildMinCost = cost

                    wipe(vaildMinCostSlotUpgradeCount)
                    local weaponCombination = weaponCombinations[plan.weaponCombinationIndex]
                    local weaponSlotCount = #weaponCombination.slots
                    for slotIndex = 1, #plan.costs do
                        if slotUpgradeCount[slotIndex] then
                            local slotName = slotIndex <= weaponSlotCount and weaponCombination.slots[slotIndex].name or armorSlots[slotIndex - weaponSlotCount].name
                            table_insert(vaildMinCostSlotUpgradeCount, { slotName = slotName, times = slotUpgradeCount[slotIndex] })
                        end
                    end
                end
            end

            if vaildMinCost == math_huge then
                vaildMinCost = nil
                vaildMinCostSlotUpgradeCount = nil
            end

            achievementCost[achievementIndex] = {
                totalCost = totalCost,
                minCost = minCost,
                minCostSlotUpgradeCount = minCostSlotUpgradeCount,
                vaildMinCost = vaildMinCost,
                vaildMinCostSlotUpgradeCount = vaildMinCostSlotUpgradeCount,
            }
        end
    end

    return achievementStatus, achievementCost, armorSlotItemLevelDisplay, armorSlotUpgradeCost, armorSlotHasVaildItem, weaponCombinationItemLevelDisplay, weaponCombinationUpgradeCost, weaponCombinationHasVaildItem
end

function CA:UpdateFrame()
    local achievementStatus, achievementCost, armorSlotItemLevelDisplay, armorSlotUpgradeCost, armorSlotHasVaildItem, weaponCombinationItemLevelDisplay, weaponCombinationUpgradeCost, weaponCombinationHasVaildItem = self:GetItemUpgradeData()

    for i, row in ipairs(self.window.armorRows) do
        row.cells[2]:SetText(armorSlotItemLevelDisplay[i])
    end

    for i, rows in ipairs(self.window.weaponRows) do
        for j, row in ipairs(rows) do
            row.cells[2]:SetText(weaponCombinationItemLevelDisplay[i][j])
        end
    end

    for achievementIndex, achievementData in ipairs(achievementDatas) do
        local cellIndex = achievementIndex + 2

        if achievementStatus[achievementIndex] == 'completed' then
            self.window.statusRow.cells[cellIndex]:SetText(atlasReady)
        elseif achievementStatus[achievementIndex] == 'incompleted' then
            self.window.statusRow.cells[cellIndex]:SetText(atlasDecline)
        else
            self.window.statusRow.cells[cellIndex]:SetText(atlasWarband)
        end

        local isAllHasVaildItem = true

        for i, row in ipairs(self.window.armorRows) do
            local cost = armorSlotUpgradeCost[achievementIndex][i]
            local hasVaildItem = armorSlotHasVaildItem[achievementIndex][i]
            if cost <= 0 then
                row.cells[cellIndex]:SetText(atlasReady)
            else
                row.cells[cellIndex]:SetText(string_format('%d %s', cost, hasVaildItem and atlasReady or atlasDecline))
            end

            if not hasVaildItem then
                isAllHasVaildItem = false
            end
        end

        for i, rows in ipairs(self.window.weaponRows) do
            local isWeaponCombinationHasVaildItem = true

            for j, row in ipairs(rows) do
                local cost = weaponCombinationUpgradeCost[i][achievementIndex][j]
                local hasVaildItem = weaponCombinationHasVaildItem[i][achievementIndex][j]
                if cost <= 0 then
                    row.cells[cellIndex]:SetText(atlasReady)
                else
                    row.cells[cellIndex]:SetText(string_format('%d %s', cost, hasVaildItem and atlasReady or atlasDecline))
                end

                if not hasVaildItem then
                    isWeaponCombinationHasVaildItem = false
                end
            end

            if not isWeaponCombinationHasVaildItem then
                isAllHasVaildItem = false
            end
        end

        local achievementCostData = achievementCost[achievementIndex]

        if not achievementData.isAverageItemLevel then
            if achievementCostData.totalCost <= 0 then
                self.window.achievementCostRow.cells[cellIndex]:SetText(0)
            else
                self.window.achievementCostRow.cells[cellIndex]:SetText(string_format('%d %s', achievementCostData.totalCost, isAllHasVaildItem and atlasReady or atlasDecline))
            end
        elseif achievementCostData.minCost <= 0 then
            local cell = self.window.achievementCostRow.cells[cellIndex]
            cell:SetText(0)

            wipe(cell.tooltipLines)
        elseif not achievementCostData.vaildMinCost then
            local cell = self.window.achievementCostRow.cells[cellIndex]
            cell:SetText(string_format('%d %s', achievementCostData.minCost, atlasDecline))

            wipe(cell.tooltipLines)
            table_insert(cell.tooltipLines, { '最优方案', string_format('%d %s', achievementCostData.minCost, atlasDecline) })
            for _, data in pairs(achievementCostData.minCostSlotUpgradeCount) do
                table_insert(cell.tooltipLines, { data.slotName, string_format('升级 %d 次', data.times) })
            end
        elseif achievementCostData.minCost >= achievementCostData.vaildMinCost then
            local cell = self.window.achievementCostRow.cells[cellIndex]
            cell:SetText(string_format('%d %s', achievementCostData.vaildMinCost, atlasReady))

            wipe(cell.tooltipLines)
            table_insert(cell.tooltipLines, { '可行方案', string_format('%d %s', achievementCostData.vaildMinCost, atlasReady) })
            for _, data in pairs(achievementCostData.vaildMinCostSlotUpgradeCount) do
                table_insert(cell.tooltipLines, { data.slotName, string_format('升级 %d 次', data.times) })
            end
        else
            local cell = self.window.achievementCostRow.cells[cellIndex]
            cell:SetText(string_format('%d (%d)', achievementCostData.vaildMinCost, achievementCostData.minCost))

            wipe(cell.tooltipLines)

            table_insert(cell.tooltipLines, { '可行方案', string_format('%d %s', achievementCostData.vaildMinCost, atlasReady) })
            for _, data in pairs(achievementCostData.vaildMinCostSlotUpgradeCount) do
                table_insert(cell.tooltipLines, { data.slotName, string_format('升级 %d 次', data.times) })
            end

            table_insert(cell.tooltipLines, { '最优方案', string_format('%d %s', achievementCostData.minCost, atlasDecline) })
            for _, data in pairs(achievementCostData.minCostSlotUpgradeCount) do
                table_insert(cell.tooltipLines, { data.slotName, string_format('升级 %d 次', data.times) })
            end
        end

        self.window.totalCostRow.cells[cellIndex]:SetText(achievementCostData.totalCost)

        local info = C_CurrencyInfo_GetCurrencyInfo(achievementData.currencyID)
        if info.useTotalEarnedForMaxQty and info.maxQuantity > 0 then
            local maxAmount = info.maxQuantity - info.totalEarned + info.quantity
            self.window.hasAmountRow.cells[cellIndex]:SetText(string_format('%d/%d', info.quantity, maxAmount))
        else
            self.window.hasAmountRow.cells[cellIndex]:SetText(info.quantity)
        end
    end

    self.window:Show()
end

do
    ---@param self CrestAchievementCellFrame
    local function OnEnter(self)
        local parent = self:GetParent()
        local parentOnEnter = parent and parent:GetScript('OnEnter')
        if parentOnEnter then
            parentOnEnter(parent)
        end

        if #self.tooltipLines > 0 then
            _G.GameTooltip:Hide()
            _G.GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            _G.GameTooltip:ClearLines()

            for _, line in ipairs(self.tooltipLines) do
                _G.GameTooltip:AddDoubleLine(line[1], line[2], nil, nil, nil, 1, 1, 1)
            end

            _G.GameTooltip:Show()
        end
    end

    ---@param self CrestAchievementCellFrame
    local function OnLeave(self)
        local parent = self:GetParent()
        local parentOnLeave = parent and parent:GetScript('OnLeave')
        if parentOnLeave then
            parentOnLeave(parent)
        end

        _G.GameTooltip:Hide()
    end

    ---@param self CrestAchievementCellFrame
    ---@param text string | number | nil
    local function SetText(self, text)
        self.text:SetText(text)
    end

    ---@param parent CrestAchievementRowFrame
    ---@param index number
    function CA:CreateCellFrame(parent, index)
        ---@class CrestAchievementCellFrame: Frame
        local cellFrame = CreateFrame('Frame', nil, parent)
        cellFrame:SetSize(80, 24)
        cellFrame:SetPoint('LEFT', (index - 1) * 80, 0)

        cellFrame:SetScript('OnEnter', OnEnter)
        cellFrame:SetScript('OnLeave', OnLeave)

        local text = cellFrame:CreateFontString(nil, 'ARTWORK')
        text:FontTemplate(nil, 14)
        text:ClearAllPoints()
        text:SetPoint('CENTER')
        text:SetJustifyH('CENTER')
        text:SetWordWrap(false)
        cellFrame.text = text

        cellFrame.SetText = SetText

        ---@type [string, string][]
        cellFrame.tooltipLines = {}

        return cellFrame
    end
end

do
    ---@param self CrestAchievementRowFrame
    local function OnEnter(self)
        self.highlight:Show()
    end

    ---@param self CrestAchievementRowFrame
    local function OnLeave(self)
        self.highlight:Hide()
    end

    ---@param parent CrestAchievementWindow
    ---@param index number
    ---@param columns number
    function CA:CreateRowFrame(parent, index, columns)
        ---@class CrestAchievementRowFrame: Frame
        local rowFrame = CreateFrame('Frame', nil, parent)
        rowFrame:SetSize(columns * 80, 24)
        rowFrame:SetPoint('TOP', 0, -(index + 1) * 24)

        if index > 0 then
            rowFrame:SetScript('OnEnter', OnEnter)
            rowFrame:SetScript('OnLeave', OnLeave)
        end

        local highlight = rowFrame:CreateTexture(nil, 'OVERLAY')
        highlight:ClearAllPoints()
        highlight:SetAllPoints()
        highlight:SetTexture(E.Media.Textures.White8x8)
        highlight:SetVertexColor(1, 1, 1, 0.03)
        highlight:Hide()
        rowFrame.highlight = highlight

        local background = rowFrame:CreateTexture(nil, 'BACKGROUND')
        background:ClearAllPoints()
        background:SetAllPoints()
        background:SetTexture(E.Media.Textures.White8x8)
        rowFrame.background = background

        if index == 0 then -- Header
            background:SetVertexColor(0, 0, 0, 0.3)
        elseif index % 2 == 1 then
            background:SetVertexColor(0, 0, 0, 0.1)
        else
            background:SetVertexColor(0, 0, 0, 0.02)
        end

        ---@type CrestAchievementCellFrame[]
        rowFrame.cells = {}
        for cellIndex = 1, columns do
            rowFrame.cells[cellIndex] = self:CreateCellFrame(rowFrame, cellIndex)
        end

        return rowFrame
    end
end

function CA:CreateWindow()
    local columns = 2 + #achievementDatas
    local rows = 1 -- header
        + 1 -- status row
        + 1 -- armor slots label
        + #armorSlots -- armor slots
        + 1 -- achievement cost
        + 1 -- total cost
        + 1 -- has amount
    for _, weaponCombination in ipairs(weaponCombinations) do
        rows = rows
            + 1 -- weapon combination label
            + #weaponCombination.slots -- weapon combination slots
    end

    ---@class CrestAchievementWindow: Frame
    local window = CreateFrame('Frame', 'RhythmBoxCrestAchievementWindow', E.UIParent, 'BackdropTemplate')

    window:SetTemplate('Transparent', true)
    window:SetFrameStrata('DIALOG')
    window:SetPoint('CENTER')
    window:SetSize(columns * 80, (rows + 1) * 24)
    window:Hide()
    self.window = window

    table_insert(_G.UISpecialFrames, 'RhythmBoxCrestAchievementWindow')

    local closeButton = CreateFrame('Button', nil, window)
    closeButton:SetSize(32, 32)
    closeButton:SetPoint('TOPRIGHT', 1, 1)
    closeButton:SetScript('OnClick', function()
        window:Hide()
    end)
    S:HandleCloseButton(closeButton)

    local titleText = window:CreateFontString(nil, 'ARTWORK')
    titleText:FontTemplate(nil, 14)
    titleText:SetTextColor(1, 1, 1, 1)
    titleText:SetPoint('TOP', window, 'TOP', 0, -5)
    titleText:SetJustifyH('CENTER')
    titleText:SetText("纹章成就")

    local header = self:CreateRowFrame(window, 0, columns)
    header.cells[1]:SetText("部位")
    header.cells[2]:SetText("装等")
    for achievementIndex, achievementData in ipairs(achievementDatas) do
        local _, achievementName = GetAchievementInfo(achievementData.achievementID)
        header.cells[achievementIndex + 2]:SetText(achievementName)
    end

    window.statusRow = self:CreateRowFrame(window, 1, columns)
    window.statusRow.cells[1]:SetText("完成情况")

    local basicSlotsLabel = self:CreateRowFrame(window, 2, columns)
    basicSlotsLabel.cells[1]:SetText("护甲")

    ---@type CrestAchievementRowFrame[]
    window.armorRows = {}
    for index, data in ipairs(armorSlots) do
        local rowFrame = self:CreateRowFrame(window, index + 2, columns)
        rowFrame.cells[1]:SetText(data.name)

        window.armorRows[index] = rowFrame
    end

    ---@type CrestAchievementRowFrame[][]
    window.weaponRows = {}

    local rowIndex = 2 + #armorSlots + 1
    for index, data in ipairs(weaponCombinations) do
        window.weaponRows[index] = {}

        local label = self:CreateRowFrame(window, rowIndex, columns)
        label.cells[1]:SetText(data.label)
        rowIndex = rowIndex + 1

        for i, slotData in ipairs(data.slots) do
            local slotRow = self:CreateRowFrame(window, rowIndex, columns)
            slotRow.cells[1]:SetText(slotData.name)
            rowIndex = rowIndex + 1

            window.weaponRows[index][i] = slotRow
        end
    end

    window.achievementCostRow = self:CreateRowFrame(window, rows - 3, columns)
    window.achievementCostRow.cells[1]:SetText("成就用量")

    window.totalCostRow = self:CreateRowFrame(window, rows - 2, columns)
    window.totalCostRow.cells[1]:SetText("总计用量")

    window.hasAmountRow = self:CreateRowFrame(window, rows - 1, columns)
    window.hasAmountRow.cells[1]:SetText("持有数量")
end

function CA:Initialize()
    self:CreateWindow()

    local buttonOpen = CreateFrame('Button', nil, _G.CharacterFrame, 'UIPanelButtonTemplate')
    buttonOpen:ClearAllPoints()
    buttonOpen:SetPoint('BOTTOMLEFT', _G.CharacterFrame, 'TOPLEFT', 0, 2)
    buttonOpen:SetSize(80, 22)
    buttonOpen:SetText("纹章成就")
    buttonOpen:SetScript('OnClick', function()
        self:UpdateFrame()
    end)
    S:HandleButton(buttonOpen)
end

R:RegisterModule(CA:GetName())
