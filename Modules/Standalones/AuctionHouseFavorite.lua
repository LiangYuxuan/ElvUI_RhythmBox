local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local AHF = R:NewModule('AuctionHouseFavorite', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local ipairs, pairs, tinsert, tremove, wipe = ipairs, pairs, tinsert, tremove, wipe

-- WoW API / Variables
local C_AuctionHouse_FavoritesAreAvailable = C_AuctionHouse.FavoritesAreAvailable
local C_AuctionHouse_SetFavoriteItem = C_AuctionHouse.SetFavoriteItem
local GetItemInfo = GetItemInfo

local Item = Item

function AHF:SetFavoriteItem(itemKey, isFav)
    for index, data in ipairs(E.db.RhythmBox.AuctionHouseFavorite.FavoriteList) do
        local matched = true
        for key, value in pairs(itemKey) do
            if data[key] ~= value then
                matched = false
                break
            end
        end
        if matched then
            if not isFav then
                tremove(E.db.RhythmBox.AuctionHouseFavorite.FavoriteList, index)
                self:UpdateOptionList()
            end
            return
        end
    end
    if isFav then
        tinsert(E.db.RhythmBox.AuctionHouseFavorite.FavoriteList, itemKey)
        self:UpdateOptionList()
    end
end

function AHF:UpdateOptionList()
    if not self.optionLoaded then return end

    wipe(E.Options.args.RhythmBox.args.AuctionHouseFavorite.args.FavoriteList.values)
    for _, data in ipairs(E.db.RhythmBox.AuctionHouseFavorite.FavoriteList) do
        local itemName = GetItemInfo(data.itemID)
        if itemName then
            E.Options.args.RhythmBox.args.AuctionHouseFavorite.args.FavoriteList.values[data.itemID] = itemName
        else
            local item = Item:CreateFromItemID(data.itemID)
            item:ContinueOnItemLoad(function()
                item:GetItemName()
                E.Options.args.RhythmBox.args.AuctionHouseFavorite.args.FavoriteList.values[data.itemID] = itemName
            end)
        end
    end
end

function AHF:LoadFavorite()
    if not C_AuctionHouse_FavoritesAreAvailable() then
        self:ScheduleTimer('LoadFavorite', 10)
        return
    end

    for _, data in ipairs(E.db.RhythmBox.AuctionHouseFavorite.FavoriteList) do
        C_AuctionHouse_SetFavoriteItem(data, true)
    end

    self:SecureHook(_G.C_AuctionHouse, 'SetFavoriteItem')
end

P["RhythmBox"]["AuctionHouseFavorite"] = {
    ["FavoriteList"] = {},
}

local function AuctionHouseFavoriteOptions()
    E.Options.args.RhythmBox.args.AuctionHouseFavorite = {
        order = 21,
        type = 'group',
        name = "拍卖行收藏",
        get = function(info) return E.db.RhythmBox.AuctionHouseFavorite[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.AuctionHouseFavorite[ info[#info] ] = value end,
        args = {
            FavoriteList = {
                order = 1,
                type = 'multiselect',
                name = "拍卖行收藏列表",
                get = function() return true end,
                values = {},
                disabled = true,
            },
        },
    }
    for _, data in ipairs(E.db.RhythmBox.AuctionHouseFavorite.FavoriteList) do
        local itemName = GetItemInfo(data.itemID)
        if itemName then
            E.Options.args.RhythmBox.args.AuctionHouseFavorite.args.FavoriteList.values[data.itemID] = itemName
        else
            local item = Item:CreateFromItemID(data.itemID)
            item:ContinueOnItemLoad(function()
                item:GetItemName()
                E.Options.args.RhythmBox.args.AuctionHouseFavorite.args.FavoriteList.values[data.itemID] = itemName
            end)
        end
    end
    AHF.optionLoaded = true
end
tinsert(R.Config, AuctionHouseFavoriteOptions)

function AHF:Initialize()
    self:LoadFavorite()
end

R:RegisterModule(AHF:GetName())
