local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local IG = R:NewModule('ItemGlance', 'AceEvent-3.0')
local StdUi = LibStub('StdUi')

-- Lua functions
local _G = _G
local floor, ipairs, next, pairs, strfind, strmatch = floor, ipairs, next, pairs, strfind, strmatch
local strsplit, tinsert, tonumber, tostring, type = strsplit, tinsert, tonumber, tostring, type

-- WoW API / Variables
local C_Item_RequestLoadItemDataByID = C_Item.RequestLoadItemDataByID
local GetItemInfo = GetItemInfo
local IsAddOnLoaded = IsAddOnLoaded

local Item = Item

local coreCharacter = {
    '小只大萌德 - 拉文凯斯',
    '小只萌猎手 - 拉文凯斯',
    '卡登斯邃光 - 拉文凯斯',
    '小只污妖王 - 拉文凯斯',
}

local itemList = {
    -- Flask
    [171276] = { -- Spectral Flask of Power
        itemCount = 3,
        percent = .35,

        ['小只大萌德 - 拉文凯斯'] = {
            itemCount = 5,
            percent = .3,
        },
    },

    -- Healing Potion
    [171267] = true, -- Spiritual Healing Potion

    -- Combat Potion
    [171273] = { -- Potion of Spectral Intellect
        ['小只大萌德 - 拉文凯斯'] = true,
        ['卡登斯邃光 - 拉文凯斯'] = true,
    },

    -- Oil / Stone
    [171285] = { -- Shadowcore Oil
        itemCount = 20,

        ['小只萌猎手 - 拉文凯斯'] = false,
        ['小只污妖王 - 拉文凯斯'] = false,
    },
    [171437] = { -- Shaded Sharpening Stone
        ['小只萌猎手 - 拉文凯斯'] = true,
    },
    [171439] = { -- Shaded Weightstone
        ['小只污妖王 - 拉文凯斯'] = true,
    },

    -- Armor Kit
    [172347] = { -- Heavy Desolate Armor Kit
        ['小只大萌德 - 拉文凯斯'] = true,
        ['小只萌猎手 - 拉文凯斯'] = true,
        ['卡登斯邃光 - 拉文凯斯'] = true,
        ['小只污妖王 - 拉文凯斯'] = true,
    },

    -- Food
    [172045] = { -- Tenebrous Crown Roast Aspic
        ['小只大萌德 - 拉文凯斯'] = true,
        ['卡登斯邃光 - 拉文凯斯'] = true,
        ['小只污妖王 - 拉文凯斯'] = true,
    },
    [172051] = { -- Steak a la Mode
        ['小只萌猎手 - 拉文凯斯'] = true,
    },

    -- Useful Item
    [109076] = true, -- Goblin Glider Kit
    [132514] = { -- Auto-Hammer
        itemCount = 10,
        percent = .5,

        ['卡登斯邃光 - 拉文凯斯'] = false,
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
        local itemName, _, _, _, _, _, _, itemStackCount, _, itemIcon = GetItemInfo(itemID)
        if itemName then
            tinsert(data, self:LoadItem(itemID, itemName, itemIcon, itemStackCount, itemConfig))
        else
            local item = Item:CreateFromItemID(itemID)
            inProgress[item] = true

            item:ContinueOnItemLoad(function()
                inProgress[item] = nil
                local itemName, _, _, _, _, _, _, itemStackCount, _, itemIcon = GetItemInfo(itemID)
                tinsert(data, self:LoadItem(itemID, itemName, itemIcon, itemStackCount, itemConfig))

                if not next(inProgress) then
                    self.itemTable:SetData(data)
                end
            end)
        end
    end

    for itemID in pairs(itemRemoveList) do
        if self.database[E.mynameRealm][itemID] then
            local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
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
                    local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
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
        IG:LoadData()
    end)

    local refreshButton = StdUi:Button(itemWindow, 100, 24, "刷新物品列表")
    StdUi:GlueTop(refreshButton, itemWindow, 0, -40)
    refreshButton:SetScript('OnClick', function()
        IG:BuildDatabase()
        IG:LoadData()
    end)

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

                    _G.GameTooltip:SetOwner(cellFrame)
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

    R:ToolboxRegisterSubWindow(itemWindow, "物品速览")
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

function IG:ADDON_LOADED(_, addonName)
    if addonName == 'BagSync' then
        self:UnregisterEvent('ADDON_LOADED')
        self:BuildDatabase()
    end
end

function IG:Initialize()
    if not E:IsAddOnEnabled('BagSync') then return end

    self:BuildWindow()

    for itemID in pairs(itemList) do
        C_Item_RequestLoadItemDataByID(itemID)
    end

    if IsAddOnLoaded('BagSync') then
        self:BuildDatabase()
    else
        self:RegisterEvent('ADDON_LOADED')
    end
end

R:RegisterModule(IG:GetName())
