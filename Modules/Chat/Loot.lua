local R, E, L, V, P, G = unpack(select(2, ...))
local C = R:GetModule('Chat')

-- Lua functions
local format, ipairs, select, strmatch = format, ipairs, select, strmatch

-- WoW API / Variables
local GetItemInfo = GetItemInfo
local UnitClass = UnitClass

local ChatFrame_AddMessageEventFilter = ChatFrame_AddMessageEventFilter
local ChatFrame_RemoveMessageEventFilter = ChatFrame_RemoveMessageEventFilter
local WrapTextInColorCode = WrapTextInColorCode

local LE_ITEM_CLASS_ARMOR = LE_ITEM_CLASS_ARMOR
local LE_ITEM_CLASS_CONSUMABLE = LE_ITEM_CLASS_CONSUMABLE
local LE_ITEM_CLASS_WEAPON = LE_ITEM_CLASS_WEAPON
local YOU = YOU

local pattens = {LOOT_ITEM, LOOT_ITEM_BONUS_ROLL, LOOT_ITEM_PUSHED}
local templates = {LOOT_ITEM, LOOT_ITEM_BONUS_ROLL, LOOT_ITEM_PUSHED}
for index, value in ipairs(pattens) do
    pattens[index] = gsub(value, '%%[ds]', '(.+)')
end

local function filterFunc(self, _, message, ...)
    local name, item = strmatch(message, pattens[1])
    if name then
        if name == YOU then
            return false, message, ...
        end

        local _, _, itemRarity, _, _, _, _, _, _, _, _, itemClassID, _, bindType = GetItemInfo(item)

        if
            -- epic equipment
            (itemRarity == 4 and (itemClassID == LE_ITEM_CLASS_WEAPON or itemClassID == LE_ITEM_CLASS_ARMOR)) or
            -- rare bop consumable (like battle pet in raid)
            (itemRarity == 3 and itemClassID == LE_ITEM_CLASS_CONSUMABLE and bindType == 1)
        then
            local classFilename = select(2, UnitClass(name))
            local classColor = R:ClassColorCode(classFilename)

            local playerLink = format("|Hplayer:%s|h[%s]|h", name, classColor and WrapTextInColorCode(name, classColor) or name)
            return false, format(templates[1], playerLink, item), ...
        end
    end

    for index, patten in ipairs(pattens) do
        local name, item = strmatch(message, patten)
        if name then
            if name == YOU then break end

            local classFilename = select(2, UnitClass(name))
            local classColor = R:ClassColorCode(classFilename)
            message = format(templates[index], classColor and WrapTextInColorCode(name, classColor) or name, item)
            break
        end
    end

    return false, message, ...
end

function C:Loot()
    if E.db.RhythmBox.Chat.EnhancedLoot then
        ChatFrame_AddMessageEventFilter('CHAT_MSG_LOOT', filterFunc)
    else
        ChatFrame_RemoveMessageEventFilter('CHAT_MSG_LOOT', filterFunc)
    end
end
