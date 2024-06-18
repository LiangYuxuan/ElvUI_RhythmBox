local R, E, L, V, P, G = unpack((select(2, ...)))
local IG = R:NewModule('ItemGlance', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')
local TB = R:GetModule('Toolbox')
local StdUi = LibStub('StdUi')

-- Lua functions
local _G = _G
local floor, format, ipairs, min, next, pairs = floor, format, ipairs, min, next, pairs
local select, strfind, strmatch, strsplit, tinsert = select, strfind, strmatch, strsplit, tinsert
local tonumber, tostring, tremove, type, wipe = tonumber, tostring, tremove, type, wipe
local table_concat = table.concat

-- WoW API / Variables
local C_Container_GetContainerItemID = C_Container.GetContainerItemID
local C_Container_GetContainerNumSlots = C_Container.GetContainerNumSlots
local C_Container_PickupContainerItem = C_Container.PickupContainerItem
local C_Item_GetItemInfo = C_Item.GetItemInfo
local C_Item_GetItemInfoInstant = C_Item.GetItemInfoInstant
local C_Item_RequestLoadItemDataByID = C_Item.RequestLoadItemDataByID
local GetGuildBankItemInfo = GetGuildBankItemInfo
local GetGuildBankItemLink = GetGuildBankItemLink
local GetGuildBankTabInfo = GetGuildBankTabInfo
local GetNumGuildBankTabs = GetNumGuildBankTabs
local PickupGuildBankItem = PickupGuildBankItem
local SplitGuildBankItem = SplitGuildBankItem

local Item = Item
local tContains = tContains

local BACKPACK_CONTAINER = BACKPACK_CONTAINER
local NUM_BAG_SLOTS = NUM_BAG_SLOTS

local coreCharacter = {
    '小只大萌德 - 拉文凯斯',
    '小只饲养员 - 拉文凯斯',
    '小只污妖王 - 拉文凯斯',
}

local itemList = {
    -- Flask
    [171276] = { -- Spectral Flask of Power
        itemCount = 3,
        percent = .35,
    },

    -- Healing Potion
    [187802] = true, -- Cosmic Healing Potion

    -- Combat Potion
    [171270] = { -- Potion of Spectral Agility
        ['小只饲养员 - 拉文凯斯'] = true,
    },
    [171273] = { -- Potion of Spectral Intellect
        ['小只大萌德 - 拉文凯斯'] = true,
    },
    [171266] = { -- Potion of the Hidden Spirit
        itemCount = 20,
        percent = .3,
    },

    -- Oil / Stone
    [171285] = { -- Shadowcore Oil
        itemCount = 20,

        ['小只饲养员 - 拉文凯斯'] = false,
        ['小只污妖王 - 拉文凯斯'] = false,
    },
    [171437] = { -- Shaded Sharpening Stone
        ['小只饲养员 - 拉文凯斯'] = true,
        ['小只污妖王 - 拉文凯斯'] = true,
    },

    -- Armor Kit
    [172347] = true, -- Heavy Desolate Armor Kit

    -- Food
    [172045] = { -- Tenebrous Crown Roast Aspic
        ['小只大萌德 - 拉文凯斯'] = true,
        ['小只饲养员 - 拉文凯斯'] = true,
        ['小只污妖王 - 拉文凯斯'] = true,
    },

    -- Useful Item
    [109076] = true, -- Goblin Glider Kit
    [132514] = { -- Auto-Hammer
        itemCount = 10,
        percent = .5,
    },
}

local itemRemoveList = {
    [138478] = true, -- Feast of Ribs
    [138479] = true, -- Potato Stew Feast

    [152998] = true, -- Carefully Hidden Muffin

    [167893] = true, -- Prismatic Crystal
    [167077] = true, -- Scrying Stone

    [162571] = true, -- Soggy Treasure Map
    [162581] = true, -- Yellowed Treasure Map
    [162584] = true, -- Singed Treasure Map
    [162580] = true, -- Fading Treasure Map

    [174758] = true, -- Voidwarped Relic Fragment
    [174764] = true, -- Tol'vir Relic Fragment
    [174756] = true, -- Aqir Relic Fragment
    [174759] = true, -- Mogu Relic Fragment
    [174760] = true, -- Mantid Relic Fragment
}

function IG:GetItemRequirment(itemConfig, fullName, itemStackCount)
    if type(itemConfig) == 'boolean' then
        return itemStackCount, floor(itemStackCount * .3)
    elseif (
        (itemConfig.itemCount or itemConfig.percent) and
        (itemConfig[fullName] == false)
    ) then
        return
    elseif (
        (itemConfig.itemCount or itemConfig.percent) and
        (not itemConfig[fullName] or type(itemConfig[fullName]) == 'boolean')
    ) then
        local itemCount = itemConfig.itemCount or itemStackCount
        local percent = itemConfig.percent or .3
        return itemCount, floor(itemCount * percent)
    elseif type(itemConfig[fullName]) == 'boolean' then
        return itemStackCount, floor(itemStackCount * .3)
    elseif itemConfig[fullName] then
        local itemCount = itemConfig[fullName].itemCount or itemConfig.itemCount or itemStackCount
        local percent = itemConfig[fullName].percent or itemConfig.percent or .3
        return itemCount, floor(itemCount * percent)
    end
end

function IG:LootItem(tab, slot, delta, targetItemID)
    local slotItemCount = select(2, GetGuildBankItemInfo(tab, slot))

    for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local numSlot = C_Container_GetContainerNumSlots(bagID)
		for slotID = 1, numSlot do
            local itemID = C_Container_GetContainerItemID(bagID, slotID)
            if itemID == targetItemID then
                -- found in bag
                if delta < slotItemCount then
                    SplitGuildBankItem(tab, slot, delta)
                    C_Container_PickupContainerItem(bagID, slotID)
                    return delta
                else
                    PickupGuildBankItem(tab, slot)
                    C_Container_PickupContainerItem(bagID, slotID)
                    return slotItemCount
                end
            end
        end
    end

    -- not found in bag, find a empty slot
    for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local numSlot = C_Container_GetContainerNumSlots(bagID)
		for slotID = 1, numSlot do
            local itemID = C_Container_GetContainerItemID(bagID, slotID)
            if not itemID then
                if delta < slotItemCount then
                    SplitGuildBankItem(tab, slot, delta)
                    C_Container_PickupContainerItem(bagID, slotID)
                    return delta
                else
                    PickupGuildBankItem(tab, slot)
                    C_Container_PickupContainerItem(bagID, slotID)
                    return slotItemCount
                end
            end
        end
    end
end

function IG:LootItemNext()
    if self.atGuildBank and #self.pendingMove > 0 then
        local data = tremove(self.pendingMove, 1)

        if data then
            local delta = data.delta
            local itemID = data.itemID
            local recvItemCount = IG:LootItem(data.tab, data.slot, delta, itemID)
            if not recvItemCount then
                R:Print("背包缺少空位以提取物品：" .. C_Item_GetItemInfo(itemID))
                self.pendingItem[itemID] = (self.pendingItem[itemID] or 0) + delta
            else
                if recvItemCount < delta then
                    self.pendingItem[itemID] = (self.pendingItem[itemID] or 0) + delta - recvItemCount
                end
                self.database[E.mynameRealm][itemID] = (self.database[E.mynameRealm][itemID] or 0) + recvItemCount
            end
        end
    end

    if not self.atGuildBank or #self.pendingMove == 0 then
        if #self.pendingMove > 0 then
            for _, data in ipairs(self.pendingMove) do
                self.pendingItem[data.itemID] = (self.pendingItem[data.itemID] or 0) + data.delta
            end
        end

        if self.timer then
            self:CancelTimer(self.timer)
            self.timer = nil
        end

        if next(self.pendingItem) then
            wipe(self.pendingItemName)
            for itemID in pairs(self.pendingItem) do
                local itemName = C_Item_GetItemInfo(itemID)
                tinsert(self.pendingItemName, itemName)
            end
            R:Print("物品已补充完毕，以下物品未得到完全补充：%s", table_concat(self.pendingItemName, ', '))
        else
            R:Print("全部物品已补充完毕")
        end

        self:LoadData()
        _G.BagSync:GetModule('Events'):GUILDBANKFRAME_OPENED() -- force BagSync refresh

        self.grabButton:SetText("提取物品")
        return
    end

    self:LoadData()

    self.currentMove = self.currentMove + 1
    self.grabButton:SetText(format("%d/%d", self.currentMove, self.totalMove))
end

function IG:GrabItems()
    wipe(self.pendingMove)
    wipe(self.pendingItem)

    for itemID, itemConfig in pairs(itemList) do
        local itemStackCount = select(8, C_Item_GetItemInfo(itemID))
        local itemMax = self:GetItemRequirment(itemConfig, E.mynameRealm, itemStackCount) or 0
        local itemCount = self.database[E.mynameRealm][itemID] or 0

        if itemMax > itemCount then
            self.pendingItem[itemID] = itemMax - itemCount
        end
    end

    if not next(self.pendingItem) then
        R:Print("全部物品已补充完毕")
        return
    end

    local numTabs = GetNumGuildBankTabs()
    for tab = 1, numTabs do
        local _, _, isViewable, _, _, remainingWithdrawals = GetGuildBankTabInfo(tab)
        if isViewable and (remainingWithdrawals > 0 or remainingWithdrawals == -1) then
            for slot = 98, 1, -1 do
                local itemLink = GetGuildBankItemLink(tab, slot)
                if itemLink then
                    local itemID = C_Item_GetItemInfoInstant(itemLink)
                    if self.pendingItem[itemID] then
                        local slotItemCount = select(2, GetGuildBankItemInfo(tab, slot))
                        local itemCount = min(self.pendingItem[itemID], slotItemCount)
                        self.pendingItem[itemID] = self.pendingItem[itemID] - itemCount
                        if self.pendingItem[itemID] == 0 then
                            self.pendingItem[itemID] = nil
                        end
                        tinsert(self.pendingMove, {
                            tab = tab,
                            slot = slot,
                            delta = itemCount,
                            itemID = itemID,
                        })
                    end
                end
            end
        end
    end

    self.currentMove = 0
    self.totalMove = #self.pendingMove
    self.grabButton:SetText(format("%d/%d", self.currentMove, self.totalMove))
    self.grabButton:Disable()

    self.timer = self:ScheduleRepeatingTimer('LootItemNext', 1)
    self:LootItemNext()
end

function IG:LoadItem(itemID, itemName, itemIcon, itemStackCount, itemConfig)
    local itemData = {
        itemID = itemID,
        itemIcon = itemIcon,
        itemName = itemName,
        itemMax = {},
        itemMin = {},
    }
    for _, unitName in ipairs(coreCharacter) do
        local itemCount = self.database[unitName][itemID]
        local itemMax, itemMin = self:GetItemRequirment(itemConfig, unitName, itemStackCount)
        itemData.itemMax[unitName] = itemMax
        itemData.itemMin[unitName] = itemMin

        if not itemCount then
            if itemMax then
                itemCount = 0
            else
                itemCount = ''
            end
        end
        itemData[unitName] = tostring(itemCount)
    end
    if not itemData[E.mynameRealm] then
        itemData[E.mynameRealm] = ''
    end
    return itemData
end

function IG:LoadData()
    local data = {}
    local inProgress = {}

    for itemID, itemConfig in pairs(itemList) do
        local itemName, _, _, _, _, _, _, itemStackCount, _, itemIcon = C_Item_GetItemInfo(itemID)
        if itemName then
            tinsert(data, self:LoadItem(itemID, itemName, itemIcon, itemStackCount, itemConfig))
        else
            local item = Item:CreateFromItemID(itemID)
            inProgress[item] = true

            item:ContinueOnItemLoad(function()
                inProgress[item] = nil
                local itemName, _, _, _, _, _, _, itemStackCount, _, itemIcon = C_Item_GetItemInfo(itemID)
                tinsert(data, self:LoadItem(itemID, itemName, itemIcon, itemStackCount, itemConfig))

                if not next(inProgress) then
                    self.itemTable:SetData(data)
                end
            end)
        end
    end

    for itemID in pairs(itemRemoveList) do
        if self.database[E.mynameRealm][itemID] then
            local itemName, _, _, _, _, _, _, _, _, itemIcon = C_Item_GetItemInfo(itemID)
            if itemName then
                local itemData = {
                    itemID = itemID,
                    itemIcon = itemIcon,
                    itemName = itemName,
                    itemRemove = true,
                    itemMax = {},
                }
                itemData.itemMax[E.mynameRealm] = 0
                itemData[E.mynameRealm] = tostring(self.database[E.mynameRealm][itemID])
                tinsert(data, itemData)
            else
                local item = Item:CreateFromItemID(itemID)
                inProgress[item] = true

                item:ContinueOnItemLoad(function()
                    inProgress[item] = nil
                    local itemName, _, _, _, _, _, _, _, _, itemIcon = C_Item_GetItemInfo(itemID)
                    local itemData = {
                        itemID = itemID,
                        itemIcon = itemIcon,
                        itemName = itemName,
                        itemRemove = true,
                        itemMax = {},
                    }
                    itemData.itemMax[E.mynameRealm] = 0
                    itemData[E.mynameRealm] = tostring(self.database[E.mynameRealm][itemID])
                    tinsert(data, itemData)

                    if not next(inProgress) then
                        self.itemTable:SetData(data)
                    end
                end)
            end
        end
    end

    if not next(inProgress) then
        self.itemTable:SetData(data)
    end
end

function IG:BuildWindow()
    local itemWindow = StdUi:Window(E.UIParent, 400 + 80 * #coreCharacter, 500, "物品速览")
    itemWindow:SetPoint('CENTER')
    itemWindow:SetScript('OnShow', function()
        IG:BuildDatabase()
        IG:LoadData()
    end)
    self.itemWindow = itemWindow

    local refreshButton = StdUi:Button(itemWindow, 100, 24, "刷新物品列表")
    StdUi:GlueTop(refreshButton, itemWindow, -60, -40)
    refreshButton:SetScript('OnClick', function()
        IG:BuildDatabase()
        IG:LoadData()
    end)

    local grabButton = StdUi:Button(itemWindow, 100, 24, "提取物品")
    grabButton:Disable()
    StdUi:GlueTop(grabButton, itemWindow, 60, -40)
    grabButton:SetScript('OnClick', function()
        IG:GrabItems()
    end)
    self.grabButton = grabButton

    local itemCountColorFunc = function(_, value, rowData, columnData)
        local itemMin = rowData.itemMin and rowData.itemMin[columnData.index]
        local itemMax = rowData.itemMax and rowData.itemMax[columnData.index]
        if (itemMin and tonumber(value) < itemMin) or (itemMax and tonumber(value) > itemMax) then
            return {r = 1, g = 0, b = 0, a = 1}
        end
        return {r = 1, g = 1, b = 1, a = 1}
    end
    local cols = {
        {
            name     = "图标",
            width    = 40,
            align    = 'LEFT',
            index    = 'itemIcon',
            format   = 'icon',
            sortable = false,
            events   = {
                OnEnter = function(_, cellFrame, _, rowData)
                    if not rowData.itemID then return end

                    _G.GameTooltip:SetOwner(cellFrame, 'ANCHOR_NONE')
                    _G.GameTooltip:ClearAllPoints()
                    _G.GameTooltip:SetPoint('RIGHT')
                    _G.GameTooltip:ClearLines()
                    _G.GameTooltip:SetItemByID(rowData.itemID)
                    _G.GameTooltip:Show()
                end,
                OnLeave = function()
                    _G.GameTooltip:Hide()
                end,
            },
        },
        {
            name     = "名称",
            width    = 200,
            align    = 'LEFT',
            index    = 'itemName',
            format   = 'string',
            color    = function(_, _, rowData)
                if rowData.itemRemove then
                    return {r = 1, g = 0, b = 0, a = 1}
                end
                return {r = 1, g = 1, b = 1, a = 1}
            end
        },
    }
    tinsert(cols, {
        name     = E.myname,
        width    = 80,
        align    = 'LEFT',
        index    = E.mynameRealm,
        format   = 'string',
        color    = itemCountColorFunc,
        sortable = false,
    })
    for _, unitName in ipairs(coreCharacter) do
        if unitName ~= E.mynameRealm then
            local characterName = strsplit(' - ', unitName)
            tinsert(cols, {
                name     = characterName,
                width    = 80,
                align    = 'LEFT',
                index    = unitName,
                format   = 'string',
                color    = itemCountColorFunc,
                sortable = false,
            })
        end
    end

    local st = StdUi:ScrollTable(itemWindow, cols, 14, 24)
    st:EnableSelection(true)
    StdUi:GlueTop(st, itemWindow, 0, -100)
    self.itemTable = st

    TB:RegisterSubWindow(itemWindow, "物品速览")
end

function IG:BuildDatabase()
    self.database = {}
    local allowRegion = {'bag', 'bank', 'reagents'}
    for realmName, realmData in pairs(_G.BagSyncDB) do
        if not strmatch(realmName, '§*') then
            for unitName, unitData in pairs(realmData) do
                if not strfind(unitName, '©*') then
                    local fullName = unitName .. ' - ' .. realmName
                    if not self.database[fullName] then
                        self.database[fullName] = {}
                    end
                    for _, region in ipairs(allowRegion) do
                        if unitData[region] then
                            for _, bagData in pairs(unitData[region]) do
                                for _, itemInfo in ipairs(bagData) do
                                    local itemID, count = strsplit(';', itemInfo)
                                    itemID = itemID and tonumber(itemID)
                                    count = count and tonumber(count) or 1
                                    if itemID then
                                        if not self.database[fullName][itemID] then
                                            self.database[fullName][itemID] = 0
                                        end
                                        self.database[fullName][itemID] = self.database[fullName][itemID] + count
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function IG:BAG_UPDATE_DELAYED()
    if self.itemWindow:IsShown() then
        self:BuildDatabase()
        self:LoadData()
    end
end

function IG:BagSyncSaveGuildBank()
    if not _G.BagSync:GetModule('Scanner').isScanningGuild and self.atGuildBank and tContains(coreCharacter, E.mynameRealm) then
        self.grabButton:Enable()
    end
end

function IG:GUILDBANKFRAME_CLOSED()
    self.atGuildBank = nil
    self.grabButton:Disable()
end

function IG:GUILDBANKFRAME_OPENED()
    self.atGuildBank = true
end

function IG:Initialize()
    if not E:IsAddOnEnabled('BagSync') then return end

    self.pendingMove = {}
    self.pendingItem = {}
    self.pendingItemName = {}

    self:BuildWindow()

    self:RegisterEvent('BAG_UPDATE_DELAYED')
    self:RegisterEvent('GUILDBANKFRAME_OPENED')
    self:RegisterEvent('GUILDBANKFRAME_CLOSED')

    for itemID in pairs(itemList) do
        C_Item_RequestLoadItemDataByID(itemID)
    end

    R:RegisterAddOnLoad('BagSync', function()
        self:BuildDatabase()
        self:SecureHook(_G.BagSync:GetModule('Scanner'), 'SaveGuildBank', 'BagSyncSaveGuildBank')
    end)
end

R:RegisterModule(IG:GetName())
