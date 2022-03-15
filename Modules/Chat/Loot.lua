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

local Enum_ItemClass_Armor = Enum.ItemClass.Armor
local Enum_ItemClass_Consumable = Enum.ItemClass.Consumable
local Enum_ItemClass_Weapon = Enum.ItemClass.Weapon
local YOU = YOU

local patterns = {LOOT_ITEM, LOOT_ITEM_BONUS_ROLL, LOOT_ITEM_PUSHED}
local templates = {LOOT_ITEM, LOOT_ITEM_BONUS_ROLL, LOOT_ITEM_PUSHED}
for index, value in ipairs(patterns) do
    patterns[index] = gsub(value, '%%[ds]', '(.+)')
end

local function filterFunc(self, _, message, ...)
    local name, item = strmatch(message, patterns[1])
    if name then
        if name == YOU then
            return false, message, ...
        end

        local _, _, itemRarity, _, _, _, _, _, _, _, _, itemClassID, _, bindType = GetItemInfo(item)

        if
            -- epic equipment
            (itemRarity == 4 and (itemClassID == Enum_ItemClass_Weapon or itemClassID == Enum_ItemClass_Armor)) or
            -- rare bop consumable (like battle pet in raid)
            (itemRarity == 3 and itemClassID == Enum_ItemClass_Consumable and bindType == 1)
        then
            local classFilename = select(2, UnitClass(name))
            local classColor = E:ClassColor(classFilename)

            local playerLink = format("|Hplayer:%s|h[%s]|h", name, WrapTextInColorCode(name, classColor.colorStr) or name)
            return false, format(templates[1], playerLink, item), ...
        end
    end

    for index, pattern in ipairs(patterns) do
        local name, item = strmatch(message, pattern)
        if name then
            if name == YOU then break end

            local classFilename = select(2, UnitClass(name))
            local classColor = E:ClassColor(classFilename)
            message = format(templates[index], WrapTextInColorCode(name, classColor.colorStr) or name, item)
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
