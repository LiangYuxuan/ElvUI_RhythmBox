local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local IG = R:NewModule('ItemGlance', 'AceEvent-3.0')
local StdUi = LibStub('StdUi')

-- Lua functions

-- WoW API / Variables

local coreCharacter = {
    '小只大萌德 - 拉文凯斯',
    '小只污妖王 - 拉文凯斯',
    '小只萌猎手 - 拉文凯斯',
    '冲钅释放 - 拉文凯斯',
    '卡登斯邃光 - 拉文凯斯',
    '小只大萌贼 - 拉文凯斯',
}

local itemList = {
    -- Flask
    [168654] = { -- Greater Flask of the Undertow
        ['小只污妖王 - 拉文凯斯'] = {
            itemCount = 5,
            percent = .20,
        },
        ['冲钅释放 - 拉文凯斯'] = {
            itemCount = 5,
            percent = .20,
        },
    },
    [168651] = { -- Greater Flask of the Currents
        ['小只萌猎手 - 拉文凯斯'] = {
            itemCount = 3,
            percent = .35,
        },
        ['小只大萌贼 - 拉文凯斯'] = {
            itemCount = 3,
            percent = .35,
        },
    },
    [168652] = { -- Greater Flask of Endless Fathoms
        ['小只大萌德 - 拉文凯斯'] = {
            itemCount = 4,
            percent = .25,
        },
        ['卡登斯邃光 - 拉文凯斯'] = {
            itemCount = 4,
            percent = .25,
        },
    },

    -- Healing Potion
    [169451] = true, -- Abyssal Healing Potion

    -- Combat Potion
    [152497] = { -- Lightfoot Potion
        ['小只污妖王 - 拉文凯斯'] = true,
        ['冲钅释放 - 拉文凯斯'] = true,
        ['小只萌猎手 - 拉文凯斯'] = {
            itemCount = 10,
        },
        ['小只大萌贼 - 拉文凯斯'] = {
            itemCount = 10,
        },
    },
    [152561] = {
        ['小只大萌德 - 拉文凯斯'] = true,
    },
    [116268] = true,

    -- Food
    [168313] = {
        ['小只污妖王 - 拉文凯斯'] = true,
        ['冲钅释放 - 拉文凯斯'] = true,
        ['卡登斯邃光 - 拉文凯斯'] = true,
    },
    [168310] = {
        ['小只大萌德 - 拉文凯斯'] = true,
        ['小只污妖王 - 拉文凯斯'] = true,
        ['冲钅释放 - 拉文凯斯'] = true,
        ['小只大萌贼 - 拉文凯斯'] = true,
    },
    [168311] = {
        ['卡登斯邃光 - 拉文凯斯'] = true,
    },
    [168314] = {
        ['小只污妖王 - 拉文凯斯'] = true,
        ['小只萌猎手 - 拉文凯斯'] = true,
        ['冲钅释放 - 拉文凯斯'] = true,
        ['卡登斯邃光 - 拉文凯斯'] = true,
    },

    -- Useful Item
    [109076] = true,
    [141446] = {
        itemCount = 30,
    },
    [132514] = {
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
}

function IG:GetItemRequirment(itemConfig, fullName, itemStackCount)
    if type(itemConfig) == 'boolean' or type(itemConfig[fullName]) == 'boolean' then
        return itemStackCount, floor(itemStackCount * .3)
    elseif itemConfig[fullName] then
        local itemCount = itemConfig[fullName].itemCount or itemStackCount
        local percent = itemConfig[fullName].percent or .3
        return itemCount, floor(itemCount * percent)
    end
end

function IG:LoadData()
    local data = {}

    for itemID, itemConfig in pairs(itemList) do
        local itemName, _, _, _, _, _, _, itemStackCount, _, itemIcon = GetItemInfo(itemID)
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
            itemData[unitName] = itemCount
        end
        tinsert(data, itemData)
    end

    self.itemTable:SetData(data)
end

function IG:BuildWindow()
    local itemWindow = StdUi:Window(_G.UIParent, 320 + 80 * #coreCharacter, 500, "物品速览")
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

    local itemCountColorFunc = function(table, value, rowData, columnData)
        local itemMin = rowData.itemMin and rowData.itemMin[columnData.index]
        if itemMin and tonumber(value) < itemMin then
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
                OnEnter = function(_, cellFrame, rowFrame, rowData, columnData, rowIndex)
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
        },
    }
    if tContains(coreCharacter, E.mynameRealm) then
        tinsert(cols, {
            name     = E.myname,
            width    = 80,
            align    = 'LEFT',
            index    = E.mynameRealm,
            format   = 'string',
            color    = itemCountColorFunc,
            sortable = false,
        })
    end
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
    self:BuildWindow()

    for itemID in pairs(itemList) do
        C_Item.RequestLoadItemDataByID(itemID)
    end

    if IsAddOnLoaded('BagSync') then
        self:BuildDatabase()
    else
        self:RegisterEvent('ADDON_LOADED')
    end
end

R:RegisterModule(IG:GetName())
