local R, E, L, V, P, G = unpack((select(2, ...)))
local QM = R:NewModule('QuickMacro', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local date, format, gsub, ipairs, pairs, tinsert = date, format, gsub, ipairs, pairs, tinsert
local random, select, sort, tostring, wipe, unpack = random, select, sort, tostring, wipe, unpack

-- WoW API / Variables
local C_AddOns_LoadAddOn = C_AddOns.LoadAddOn
local C_DateAndTime_GetServerTimeLocal = C_DateAndTime.GetServerTimeLocal
local C_Item_GetItemCooldown = C_Item.GetItemCooldown
local C_Item_GetItemCount = C_Item.GetItemCount
local C_Item_GetItemIconByID = C_Item.GetItemIconByID
local C_Item_GetItemInfo = C_Item.GetItemInfo
local C_Item_GetItemNameByID = C_Item.GetItemNameByID
local C_Item_GetItemQualityByID = C_Item.GetItemQualityByID
local C_Item_GetItemQualityColor = C_Item.GetItemQualityColor
local C_Item_IsItemInRange = C_Item.IsItemInRange
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_MountJournal_GetMountInfoByID = C_MountJournal.GetMountInfoByID
local C_MountJournal_SummonByID = C_MountJournal.SummonByID
local C_Spell_GetSpellCooldown = C_Spell.GetSpellCooldown
local C_Spell_GetSpellName = C_Spell.GetSpellName
local C_Spell_GetSpellTexture = C_Spell.GetSpellTexture
local C_Spell_IsSpellInRange = C_Spell.IsSpellInRange
local C_Spell_IsSpellUsable = C_Spell.IsSpellUsable
local C_TradeSkillUI_GetItemCraftedQualityByItemInfo = C_TradeSkillUI.GetItemCraftedQualityByItemInfo
local C_TradeSkillUI_GetItemReagentQualityByItemInfo = C_TradeSkillUI.GetItemReagentQualityByItemInfo
local C_TradeSkillUI_GetProfessionInfoBySkillLineID = C_TradeSkillUI.GetProfessionInfoBySkillLineID
local CreateFrame = CreateFrame
local GetBindingKey = GetBindingKey
local GetInventoryItemID = GetInventoryItemID
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsShiftKeyDown = IsShiftKeyDown
local PlayerHasToy = PlayerHasToy
local UnitCanAttack = UnitCanAttack

local CooldownFrame_Set = CooldownFrame_Set
local Item = Item
local MenuUtil_CreateContextMenu = MenuUtil.CreateContextMenu
local RegisterStateDriver = RegisterStateDriver

local Enum_ItemWeaponSubclass_Guns = Enum.ItemWeaponSubclass.Guns
local Enum_ItemWeaponSubclass_Mace1H = Enum.ItemWeaponSubclass.Mace1H
local Enum_ItemWeaponSubclass_Mace2H = Enum.ItemWeaponSubclass.Mace2H
local Enum_ItemWeaponSubclass_Staff = Enum.ItemWeaponSubclass.Staff
local LE_UNIT_STAT_INTELLECT = LE_UNIT_STAT_INTELLECT

---@class QuickMacroItemDisplay
---@field ctrl number?
---@field shift number?
---@field alt number?
---@field none number?
---@field ctrlIsToy boolean?
---@field shiftIsToy boolean?
---@field altIsToy boolean?
---@field noneIsToy boolean?

---@class QuickMacroButton: Button
---@field icon Texture
---@field qualityOverlay Texture
---@field count FontString
---@field bind FontString
---@field cooldown QuickMacroButtonCooldown
---@field initialized boolean?
---@field itemDisplay QuickMacroItemDisplay
---@field displayType 'spell' | 'mount' | 'item' | 'toy' | nil
---@field itemID number?
---@field spellID number?
---@field tooltip string?

---@class QuickMacroData
---@field name string
---@field index number
---@field updateEvent table<string, true>
---@field updateFunc fun(button: QuickMacroButton, data: self, inCombat: boolean): boolean
---@field displayFunc fun(button: QuickMacroButton, data: self): nil

---@class QuickMacroItemList
---@field ctrlCombat number[]?
---@field shiftCombat number[]?
---@field altCombat number[]?
---@field combat number[]?
---@field ctrl number[]?
---@field shift number[]?
---@field alt number[]?
---@field none number[]

---@class QuickMacroRoleItemList
---@field TANK QuickMacroItemList
---@field HEALER QuickMacroItemList
---@field DAMAGER QuickMacroItemList

---@class QuickMacroDataItemList: QuickMacroData
---@field itemList QuickMacroItemList | QuickMacroRoleItemList
---@field updateFunc fun(button: QuickMacroButton, data: self, inCombat: boolean): boolean
---@field displayFunc fun(button: QuickMacroButton, data: self): nil

---@class TableContainsItemList
---@field itemList QuickMacroItemList | QuickMacroRoleItemList | nil

---@param self QuickMacroButton
local function ButtonOnEnter(self)
    _G.GameTooltip:Hide()
    _G.GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 0, -2)
    _G.GameTooltip:ClearLines()

    if not self.displayType and self.tooltip then
        _G.GameTooltip:AddLine(self.tooltip)
    elseif self.displayType == 'item' and self.itemID then
        _G.GameTooltip:SetItemByID(self.itemID)
    elseif self.displayType == 'toy' and self.itemID then
        _G.GameTooltip:SetToyByItemID(self.itemID)
    elseif self.displayType == 'spell' and self.spellID then
        _G.GameTooltip:SetSpellByID(self.spellID)
    elseif self.displayType == 'mount' and self.spellID then
        ---@diagnostic disable-next-line: redundant-parameter
        _G.GameTooltip:SetMountBySpellID(self.spellID)
    end

    _G.GameTooltip:Show()
end

---@param self QuickMacroButton
local function ButtonOnLeave(self)
    _G.GameTooltip:Hide()
end

---@param self QuickMacroButton
local function ButtonOnUpdate(self)
    if not self.displayType then return end

    if self.displayType == 'item' or self.displayType == 'toy' or self.displayType == 'spell' then
        local startTime, duration, enable
        if self.displayType == 'item' or self.displayType == 'toy' then
            startTime, duration, enable = C_Item_GetItemCooldown(self.itemID)
        elseif self.displayType == 'spell' then
            local cooldownInfo = C_Spell_GetSpellCooldown(self.spellID)
            startTime, duration, enable = cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.isEnabled
        end

        CooldownFrame_Set(self.cooldown, startTime, duration, enable)

        if duration and duration > 0 and not enable then
            self.icon:SetVertexColor(.4, .4, .4)
            return
        end
    end

    if (
        (self.displayType == 'item' or self.displayType == 'toy') and
        (not InCombatLockdown() or UnitCanAttack('player', 'target')) and
        C_Item_IsItemInRange(self.itemID, 'target') == false
    ) then
        self.icon:SetVertexColor(.8, .1, .1)
    elseif self.displayType == 'spell' or self.displayType == 'mount' then
        local inRange = C_Spell_IsSpellInRange(self.spellID, 'target')
        local usable, noMana = C_Spell_IsSpellUsable(self.spellID)
        if inRange == 0 then
            self.icon:SetVertexColor(.8, .1, .1)
        elseif usable then
            self.icon:SetVertexColor(1, 1, 1)
        elseif noMana then
            self.icon:SetVertexColor(.5, .5, 1)
        else
            self.icon:SetVertexColor(.4, .4, .4)
        end
    else
        self.icon:SetVertexColor(1, 1, 1)
    end
end

local itemListConditions = {
    { 'ctrl', 'ctrlCombat', 'ctrl-', function() return IsControlKeyDown() end },
    { 'shift', 'shiftCombat', 'shift-', function() return IsShiftKeyDown() end },
    { 'alt', 'altCombat', 'alt-', function() return IsAltKeyDown() end },
    { 'none', 'combat', '*', function() return true end },
}

---@param button QuickMacroButton
---@param data TableContainsItemList
---@param inCombat boolean
---@return boolean?
local function ItemListUpdateFunc(button, data, inCombat)
    wipe(button.itemDisplay)

    local itemList = data.itemList and data.itemList[E.myrole] or data.itemList
    ---@cast itemList QuickMacroItemList
    if not itemList then return end

    for _, condition in ipairs(itemListConditions) do
        local key, combatKey, prefix = unpack(condition)
        local slotList = inCombat and itemList[combatKey] or itemList[key]
        if slotList then
            local selected = slotList[1]
            for _, itemID in ipairs(slotList) do
                local itemCount = C_Item_GetItemCount(itemID)
                if itemCount and itemCount > 0 then
                    selected = itemID
                    break
                end
            end

            button:SetAttribute(prefix .. 'type1', 'item')
            button:SetAttribute(prefix .. 'item1', 'item:' .. selected)
            button.itemDisplay[key] = selected
        end
    end

    return true
end

---@param button QuickMacroButton
local function ItemDisplayFunc(button)
    local itemID = button.itemDisplay.none
    local itemIsToy = button.itemDisplay.noneIsToy

    for _, condition in ipairs(itemListConditions) do
        local key, _, _, func = unpack(condition)
        if button.itemDisplay[key] and func() then
            itemID = button.itemDisplay[key]
            itemIsToy = button.itemDisplay[key .. 'IsToy']
            break
        end
    end

    if not itemID then
        button.displayType = nil
        button.itemID = nil

        button:SetBackdropBorderColor(0, 0, 0)
        button.icon:SetTexture(134400) -- INV_Misc_QuestionMark
        ---@diagnostic disable-next-line: param-type-mismatch
        button.qualityOverlay:SetAtlas(nil)
        button.count:SetText("")
    else
        button.displayType = itemIsToy and 'toy' or 'item'
        button.itemID = itemID

        local itemCount = C_Item_GetItemCount(itemID, nil, true) or 0
        button.count:SetText(tostring(itemCount))

        local rarity = C_Item_GetItemQualityByID(itemID)
        local itemIcon = C_Item_GetItemIconByID(itemID)
        if rarity and itemIcon then
            local quality = C_TradeSkillUI_GetItemReagentQualityByItemInfo(itemID) or C_TradeSkillUI_GetItemCraftedQualityByItemInfo(itemID)
            local r, g, b = C_Item_GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)

            button:SetBackdropBorderColor(r, g, b)
            button.icon:SetTexture(itemIcon)
            if quality then
                button.qualityOverlay:SetAtlas(format('Professions-Icon-Quality-Tier%d-Inv', quality), true)
            else
                ---@diagnostic disable-next-line: param-type-mismatch
                button.qualityOverlay:SetAtlas(nil)
            end
        else
            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(function()
                rarity = C_Item_GetItemQualityByID(itemID)
                itemIcon = C_Item_GetItemIconByID(itemID)

                local quality = C_TradeSkillUI_GetItemReagentQualityByItemInfo(itemID) or C_TradeSkillUI_GetItemCraftedQualityByItemInfo(itemID)
                local r, g, b = C_Item_GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)

                button:SetBackdropBorderColor(r, g, b)
                button.icon:SetTexture(itemIcon)
                if quality then
                    button.qualityOverlay:SetAtlas(format('Professions-Icon-Quality-Tier%d-Inv', quality), true)
                else
                    ---@diagnostic disable-next-line: param-type-mismatch
                    button.qualityOverlay:SetAtlas(nil)
                end
            end)
        end
    end
end

---@type table<string, QuickMacroData>
QM.MacroButtons = {}

---@class QuickMacroButtonMount: QuickMacroButton
---@field ctrlSpellID number?
---@field ctrlIconID number?
---@field altSpellID number?
---@field altIconID number?
---@field noneSpellID number?
---@field noneIconID number?
---@field druidIcon number?

---@class QuickMacroDataMount: QuickMacroData
---@field ctrl number?
---@field alt number?
---@field updateFunc fun(button: QuickMacroButtonMount, data: self, inCombat: boolean): boolean
---@field displayFunc fun(button: QuickMacroButtonMount, data: self): nil
---@field clickFunc fun(button: QuickMacroButtonMount, button: string, down: boolean): nil
---@field menuGenerator fun(owner: QuickMacroButtonMount, rootDescription: table): nil
QM.MacroButtons.RandomMount = {
    name = "随机坐骑",
    index = 1,

    updateEvent = {
        ['PLAYER_ENTERING_WORLD'] = true,
        ['ZONE_CHANGED_INDOORS'] = true,
        ['PLAYER_SPECIALIZATION_CHANGED'] = true,
        ['MOUNT_JOURNAL_USABILITY_CHANGED'] = true,
    },
    updateFunc = function(button, data, inCombat)
        if not button.initialized then
            if not _G.MountJournalSummonRandomFavoriteButton then
                C_AddOns_LoadAddOn('Blizzard_Collections')
            end

            local switchStyle = C_Spell_GetSpellName(436854) -- Switch Flight Style
            button:SetAttribute('shift-type1', 'spell')
            button:SetAttribute('shift-spell1', switchStyle)

            if data.ctrl then
                local name, spellID, iconID, _, _, _, _, _, _, _, isCollected = C_MountJournal_GetMountInfoByID(data.ctrl)
                if isCollected then
                    button:SetAttribute('ctrl-type1', 'spell')
                    button:SetAttribute('ctrl-spell1', name)

                    button.ctrlSpellID = spellID
                    button.ctrlIconID = iconID
                end
            end

            if data.alt then
                local name, spellID, iconID, _, _, _, _, _, _, _, isCollected = C_MountJournal_GetMountInfoByID(data.alt)
                if isCollected then
                    button:SetAttribute('alt-type1', 'spell')
                    button:SetAttribute('alt-spell1', name)

                    button.altSpellID = spellID
                    button.altIconID = iconID
                end
            end

            if E.myclass == 'DRUID' then
                local travelForm = C_Spell_GetSpellName(783) -- Travel Form

                button:SetAttribute('*type1', 'spell')
                button:SetAttribute('*spell1', travelForm)

                button.druidIcon = 132144
            else
                local timestamp = C_DateAndTime_GetServerTimeLocal()
                local timeData = date('*t', timestamp)
                local duringHallowsEnd = (
                    (timeData.month == 10 and ((timeData.day > 18) or (timeData.day == 18 and timeData.hour >= 10))) or
                    (timeData.month == 11 and timeData.day == 1 and timeData.hour < 11)
                )
                local name, spellID, iconID, _, _, _, _, _, _, _, isCollected = C_MountJournal_GetMountInfoByID(1799) -- Eve's Ghastly Rider

                if duringHallowsEnd and isCollected then
                    button:SetAttribute('*type1', 'spell')
                    button:SetAttribute('*spell1', name)

                    button.noneSpellID = spellID
                    button.noneIconID = iconID
                else
                    button:SetAttribute('*type1', 'click')
                    button:SetAttribute('*clickbutton1', _G.MountJournalSummonRandomFavoriteButton)
                end
            end

            button:HookScript('OnClick', data.clickFunc)
            button.count:Hide()

            button.initialized = true
        end

        return not inCombat
    end,
    displayFunc = function(button)
        button:SetBackdropBorderColor(0, 112 / 255, 221 / 255)

        if IsShiftKeyDown() then
            local spellIcon = C_Spell_GetSpellTexture(436854)

            button.displayType = 'spell'
            button.spellID = 436854

            button.icon:SetTexture(spellIcon)
        elseif button.ctrlSpellID and button.ctrlIconID and IsControlKeyDown() then
            button.displayType = 'mount'
            button.spellID = button.ctrlSpellID

            button.icon:SetTexture(button.ctrlIconID)
        elseif button.altSpellID and button.altIconID and IsAltKeyDown() then
            button.displayType = 'mount'
            button.spellID = button.altSpellID

            button.icon:SetTexture(button.altIconID)
        elseif button.druidIcon then
            button.displayType = 'spell'
            button.spellID = 783

            button.icon:SetTexture(button.druidIcon)
        elseif button.noneSpellID and button.noneIconID then
            button.displayType = 'mount'
            button.spellID = button.noneSpellID

            button.icon:SetTexture(button.noneIconID)
        else
            button.displayType = 'spell'
            button.spellID = 150544

            button.icon:SetTexture(853211)
        end
    end,

    clickFunc = function(self, button, down)
        if button == 'RightButton' and not down then
            MenuUtil_CreateContextMenu(self, QM.MacroButtons.RandomMount.menuGenerator)
        end
    end,
    menuGenerator = function(_, rootDescription)
        for _, mountID in ipairs(QM.MacroButtons.RandomMount.list) do
            local name, _, iconID, _, _, _, _, _, _, _, isCollected = C_MountJournal_GetMountInfoByID(mountID)
            if isCollected then
                local button = rootDescription:CreateButton(name, C_MountJournal_SummonByID, mountID)
                button:AddInitializer(function(self)
                    local texture = self:AttachTexture()
                    texture:SetPoint('RIGHT')
                    texture:SetSize(16, 16)
                    texture:SetTexture(iconID)
                    texture:SetTexCoord(.1, .9, .1, .9)

                    local fontString = self.fontString
                    fontString:SetPoint('RIGHT', texture, 'LEFT')

                    local width, height = fontString:GetUnboundedStringWidth() + 20, 20
                    return width, height
                end)
            end
        end
    end,
    ctrl = 382, -- X-53 Touring Rocket
    alt = 460, -- Grand Expedition Yak
    list = {
        1039, -- Mighty Caravan Brutosaur
        460, -- Grand Expedition Yak
        E.myfaction == 'Alliance' and 280 or 284, -- Traveler's Tundra Mammoth
        1654, -- Otterworldly Ottuk Carrier
        382, -- X-53 Touring Rocket
        407, -- Sandstone Drake
    },
}

---@class QuickMacroDataHearthstone: QuickMacroData
---@field hearthstoneList number[]
---@field updateFunc fun(button: QuickMacroButton, data: self, inCombat: boolean): boolean
---@field displayFunc fun(button: QuickMacroButton, data: self): nil
---@field clickFunc fun(self: QuickMacroButton, button: string, down: boolean): nil
QM.MacroButtons.RandomHearthstone = {
    name = "随机炉石",
    index = 2,

    updateEvent = {
        ['PLAYER_ENTERING_WORLD'] = true,
    },
    updateFunc = function(button, data, inCombat)
        if not button.initialized then
            if PlayerHasToy(140192) then -- Dalaran Hearthstone
                button:SetAttribute('shift-type1', 'item')
                button:SetAttribute('shift-item1', 'item:140192')
                button.itemDisplay.shift = 140192
                button.itemDisplay.shiftIsToy = true
            end

            if PlayerHasToy(110560) then -- Garrison Hearthstone
                button:SetAttribute('ctrl-type1', 'item')
                button:SetAttribute('ctrl-item1', 'item:110560')
                button.itemDisplay.ctrl = 110560
                button.itemDisplay.ctrlIsToy = true
            end

            if C_Item_GetItemCount(141605) > 0 then -- Flight Master's Whistle
                button:SetAttribute('alt-type1', 'item')
                button:SetAttribute('alt-item1', 'item:141605')
                button.itemDisplay.alt = 141605
                button.itemDisplay.altIsToy = false
            end

            button:SetAttribute('*type1', 'item')
            button:HookScript('OnClick', data.clickFunc)
            button.count:Hide()

            button.initialized = true
        end

        local list = {}
        for _, itemID in ipairs(data.hearthstoneList) do
            if E.db.RhythmBox.QuickMacro.Hearthstone[itemID] and PlayerHasToy(itemID) then
                tinsert(list, itemID)
            end
        end
        if #list > 0 then
            local hsItemID = list[random(#list)]
            button:SetAttribute('*item1', 'item:' .. hsItemID)
            button.itemDisplay.none = hsItemID
            button.itemDisplay.noneIsToy = true
        else
            button:SetAttribute('*item1', 'item:6948')
            button.itemDisplay.none = 6948
            button.itemDisplay.noneIsToy = false
        end

        return not inCombat
    end,
    displayFunc = ItemDisplayFunc,

    clickFunc = function(self, button, down)
        if button == 'RightButton' and not down and not InCombatLockdown() then
            local data = QM.MacroButtons.RandomHearthstone

            local list = {}
            for _, itemID in ipairs(data.hearthstoneList) do
                if E.db.RhythmBox.QuickMacro.Hearthstone[itemID] and PlayerHasToy(itemID) then
                    tinsert(list, itemID)
                end
            end
            if #list > 0 then
                local hsItemID = list[random(#list)]
                self:SetAttribute('*item1', 'item:' .. hsItemID)
                self.itemDisplay.none = hsItemID
                self.itemDisplay.noneIsToy = true
            else
                self:SetAttribute('*item1', 'item:6948')
                self.itemDisplay.none = 6948
                self.itemDisplay.noneIsToy = false
            end

            ItemDisplayFunc(self)
            ButtonOnEnter(self)
        end
    end,
    hearthstoneList = {
        ---AUTO_GENERATED LEADING QuickMacroHearthstone
        54452,  -- Ethereal Portal
        64488,  -- The Innkeeper's Daughter
        93672,  -- Dark Portal
        142542, -- Tome of Town Portal
        162973, -- Greatfather Winter's Hearthstone
        163045, -- Headless Horseman's Hearthstone
        165669, -- Lunar Elder's Hearthstone
        165670, -- Peddlefeet's Lovely Hearthstone
        165802, -- Noble Gardener's Hearthstone
        166746, -- Fire Eater's Hearthstone
        166747, -- Brewfest Reveler's Hearthstone
        168907, -- Holographic Digitalization Hearthstone
        172179, -- Eternal Traveler's Hearthstone
        180290, -- Night Fae Hearthstone
        182773, -- Necrolord Hearthstone
        183716, -- Venthyr Sinstone
        184353, -- Kyrian Hearthstone
        188952, -- Dominated Hearthstone
        190196, -- Enlightened Hearthstone
        190237, -- Broker Translocation Matrix
        193588, -- Timewalker's Hearthstone
        200630, -- Ohn'ir Windsage's Hearthstone
        206195, -- Path of the Naaru
        208704, -- Deepdweller's Earthen Hearthstone
        212337, -- Stone of the Hearth
        210455, -- Draenic Hologem
        209035, -- Hearthstone of the Flame
        ---AUTO_GENERATED TAILING QuickMacroHearthstone
    },
}

---@type QuickMacroDataItemList
QM.MacroButtons.RestoreHealth = {
    name = "回血保命",
    index = 3,

    updateEvent = {
        ['BAG_UPDATE_DELAYED'] = true,
    },
    updateFunc = ItemListUpdateFunc,
    displayFunc = ItemDisplayFunc,

    itemList = {
        ctrl = {
            207039, -- Potion of Withering Dreams (Tier 3)
            207040, -- Potion of Withering Dreams (Tier 2)
            207041, -- Potion of Withering Dreams (Tier 1)
            207023, -- Dreamwalker's Healing Potion (Tier 3)
            207022, -- Dreamwalker's Healing Potion (Tier 2)
            207021, -- Dreamwalker's Healing Potion (Tier 1)
            191380, -- Refreshing Healing Potion (Tier 3)
            191379, -- Refreshing Healing Potion (Tier 2)
            191378, -- Refreshing Healing Potion (Tier 1)
        },
        none = {
            5512,   -- Healthstone
            207039, -- Potion of Withering Dreams (Tier 3)
            207040, -- Potion of Withering Dreams (Tier 2)
            207041, -- Potion of Withering Dreams (Tier 1)
            207023, -- Dreamwalker's Healing Potion (Tier 3)
            207022, -- Dreamwalker's Healing Potion (Tier 2)
            207021, -- Dreamwalker's Healing Potion (Tier 1)
            191380, -- Refreshing Healing Potion (Tier 3)
            191379, -- Refreshing Healing Potion (Tier 2)
            191378, -- Refreshing Healing Potion (Tier 1)
        },
    },
}

---@type QuickMacroDataItemList
QM.MacroButtons.CombatPotion = {
    name = "战斗药水",
    index = 4,

    updateEvent = {
        ['BAG_UPDATE_DELAYED'] = true,
        ['PLAYER_SPECIALIZATION_CHANGED'] = true,
    },
    updateFunc = ItemListUpdateFunc,
    displayFunc = ItemDisplayFunc,

    itemList = {
        ['HEALER'] = {
            combat = {
                191386, -- Aerated Mana Potion (Tier 3)
                191385, -- Aerated Mana Potion (Tier 2)
                191384, -- Aerated Mana Potion (Tier 1)
            },
            ctrl = {
                191365, -- Potion of Frozen Focus (Tier 3)
                191364, -- Potion of Frozen Focus (Tier 2)
                191363, -- Potion of Frozen Focus (Tier 1)
            },
            none = {
                113509, -- Conjured Mana Bun
                197771, -- Delicious Dragon Spittle
                194684, -- Azure Leywine
            },
        },
        ['TANK'] = {
            combat = {
                191914, -- Fleeting Elemental Potion of Ultimate Power (Tier 3)
                191913, -- Fleeting Elemental Potion of Ultimate Power (Tier 2)
                191912, -- Fleeting Elemental Potion of Ultimate Power (Tier 1)
                191907, -- Fleeting Elemental Potion of Power (Tier 3)
                191906, -- Fleeting Elemental Potion of Power (Tier 2)
                191905, -- Fleeting Elemental Potion of Power (Tier 1)
                191383, -- Elemental Potion of Ultimate Power (Tier 3)
                191382, -- Elemental Potion of Ultimate Power (Tier 2)
                191381, -- Elemental Potion of Ultimate Power (Tier 1)
                191389, -- Elemental Potion of Power (Tier 3)
                191388, -- Elemental Potion of Power (Tier 2)
                191387, -- Elemental Potion of Power (Tier 1)

                142117, -- Potion of Prolonged Power (Legion)
            },
            none = {
                113509, -- Conjured Mana Bun
            },
        },
        ['DAMAGER'] = {
            combat = {
                191914, -- Fleeting Elemental Potion of Ultimate Power (Tier 3)
                191913, -- Fleeting Elemental Potion of Ultimate Power (Tier 2)
                191912, -- Fleeting Elemental Potion of Ultimate Power (Tier 1)
                191907, -- Fleeting Elemental Potion of Power (Tier 3)
                191906, -- Fleeting Elemental Potion of Power (Tier 2)
                191905, -- Fleeting Elemental Potion of Power (Tier 1)
                191383, -- Elemental Potion of Ultimate Power (Tier 3)
                191382, -- Elemental Potion of Ultimate Power (Tier 2)
                191381, -- Elemental Potion of Ultimate Power (Tier 1)
                191389, -- Elemental Potion of Power (Tier 3)
                191388, -- Elemental Potion of Power (Tier 2)
                191387, -- Elemental Potion of Power (Tier 1)

                142117, -- Potion of Prolonged Power (Legion)
            },
            none = {
                113509, -- Conjured Mana Bun
            },
        },
    },
}

---@class QuickMacroDataConsumableSubDynamic: QuickMacroData
---@field itemLists table<string, QuickMacroItemList | QuickMacroRoleItemList>
---@field choose fun(itemLists: table<string, QuickMacroItemList | QuickMacroRoleItemList>): nil

---@alias QuickMacroDataConsumableSub TableContainsItemList | QuickMacroDataConsumableSubDynamic

---@class QuickMacroButtonConsumable: QuickMacroButton
---@field subButtons [QuickMacroButton, QuickMacroDataConsumableSub][]

---@class QuickMacroDataConsumable: QuickMacroData
---@field onClickSnippet string
---@field onCombatSnippet string
---@field subButtonList QuickMacroDataConsumableSub[]
---@field updateFunc fun(button: QuickMacroButtonConsumable, data: self, inCombat: boolean): boolean
---@field displayFunc fun(button: QuickMacroButtonConsumable, data: self): nil
---@field clickFunc fun(button: QuickMacroButtonConsumable, button: string, down: boolean): nil
QM.MacroButtons.Consumable = {
    name = "消耗品",
    index = 5,

    updateEvent = {
        ['PLAYER_ENTERING_WORLD'] = true,
        ['BAG_UPDATE_DELAYED'] = true,
        ['PLAYER_SPECIALIZATION_CHANGED'] = true,
        ['PLAYER_EQUIPMENT_CHANGED'] = true,
    },
    updateFunc = function(button, data, inCombat)
        if not button.initialized then
            ---@class QuickMacroConsumableSubFrame: Frame
            local subFrame = CreateFrame('Frame', nil, button)
            subFrame:ClearAllPoints()
            subFrame:SetPoint('BOTTOM', button, 'TOP', 0, -3)
            subFrame:SetSize(4, 4)
            subFrame:Hide()
            subFrame.buttons = {}

            button.subButtons = {}

            ---@type QuickMacroConsumableSubFrame | QuickMacroButton
            local prev = subFrame
            for index, subButtonData in ipairs(data.subButtonList) do
                local subButton = QM:UpdateButtonLayout('Consumable' .. index, subFrame)
                subButton:ClearAllPoints()
                subButton:SetPoint('BOTTOM', prev, 'TOP', 0, 3)
                prev = subButton

                tinsert(button.subButtons, { subButton, subButtonData })
            end

            ---@class QuickMacroConsumableOverlay: Button
            local overlay = CreateFrame('Button', button:GetName() .. 'Overlay', button, 'SecureHandlerStateTemplate, SecureHandlerClickTemplate')
            overlay:ClearAllPoints()
            overlay:SetAllPoints()
            overlay:SetScript('OnEnter', button:GetScript('OnEnter'))
            overlay:SetScript('OnLeave', button:GetScript('OnLeave'))

            overlay:StyleButton()
            overlay:RegisterForClicks('AnyUp', 'AnyDown')

            overlay:SetFrameRef('subFrame', subFrame)
            overlay:SetAttribute('expanded', false)
            RegisterStateDriver(overlay, 'combat', '[nocombat] 0; 1')
            overlay:SetAttribute('_onstate-combat', data.onCombatSnippet)
            overlay:SetAttribute('_onclick', data.onClickSnippet)

            button.initialized = true
        end

        for _, subButtonArray in ipairs(button.subButtons) do
            local subButton, subButtonData = subButtonArray[1], subButtonArray[2]

            if subButtonData.choose then
                subButtonData.choose(subButtonData.itemLists)

                local show = ItemListUpdateFunc(subButton, subButtonData.itemLists, inCombat)
                subButton:SetShown(show)
            else
                ---@cast subButtonData TableContainsItemList
                local show = ItemListUpdateFunc(subButton, subButtonData, inCombat)
                subButton:SetShown(show)
            end
        end

        return true
    end,
    displayFunc = function(button)
        button:SetBackdropBorderColor(0, 112 / 255, 221 / 255)
        button.icon:SetTexture(237271)

        for _, subButtonArray in ipairs(button.subButtons) do
            local subButton = subButtonArray[1]
            ItemDisplayFunc(subButton)
        end
    end,

    onClickSnippet = [[
        if button == 'LeftButton' and not down then
            if self:GetAttribute('expanded') then
                self:SetAttribute('expanded', false)
                self:ClearBinding('ESCAPE')
                self:GetFrameRef('subFrame'):Hide()
            else
                self:SetAttribute('expanded', true)
                self:SetBindingClick(0, 'ESCAPE', self:GetName())
                self:GetFrameRef('subFrame'):Show()
            end
        end
    ]],
    onCombatSnippet = [[
        if newstate == 1 and self:GetAttribute('expanded') then
            self:SetAttribute('expanded', false)
            self:ClearBinding('ESCAPE')
            self:GetFrameRef('subFrame'):Hide()
        end
    ]],
    subButtonList = {
        {
            itemList = {
                none = {
                    191335, -- Phial of Glacial Fury (Tier 3)
                    191334, -- Phial of Glacial Fury (Tier 2)
                    191333, -- Phial of Glacial Fury (Tier 1)
                    191332, -- Phial of Charged Isolation (Tier 3)
                    191331, -- Phial of Charged Isolation (Tier 2)
                    191330, -- Phial of Charged Isolation (Tier 1)
                    -- 191338, -- Phial of Static Empowerment (Tier 3)
                    -- 191337, -- Phial of Static Empowerment (Tier 2)
                    -- 191336, -- Phial of Static Empowerment (Tier 1)
                    191329, -- Iced Phial of Corrupting Rage (Tier 3)
                    191328, -- Iced Phial of Corrupting Rage (Tier 2)
                    191327, -- Iced Phial of Corrupting Rage (Tier 1)
                    191341, -- Phial of Tepid Versatility (Tier 3)
                    191340, -- Phial of Tepid Versatility (Tier 2)
                    191339, -- Phial of Tepid Versatility (Tier 1)
                    191359, -- Phial of Elemental Chaos (Tier 3)
                    191358, -- Phial of Elemental Chaos (Tier 2)
                    191357, -- Phial of Elemental Chaos (Tier 1)
                },
            },
        },
        {
            itemList = {
                none = {
                    204072, -- Deviously Deviled Eggs
                    197782, -- Feisty Fish Sticks
                    197783, -- Aromatic Seafood Platter
                    197784, -- Sizzling Seafood Medley
                    197785, -- Revenge, Served Cold
                    197786, -- Thousandbone Tongueslicer
                    197787, -- Great Cerulean Sea
                    197778, -- Timely Demise
                    197779, -- Filet of Fangs
                    197780, -- Seamoth Surprise
                    197781, -- Salt-Baked Fishcake
                },
            },
        },
        {
            itemList = {
                none = {
                    211495, -- Dreambound Augment Rune
                    201325, -- Draconic Augment Rune
                },
            },
        },
        {
            choose = function(itemLists)
                local specID, _, _, _, _, primaryStat = GetSpecializationInfo(E.myspec or GetSpecialization())
                if primaryStat == LE_UNIT_STAT_INTELLECT then
                    itemLists.itemList = itemLists.oilList
                elseif specID == 253 or specID == 254 then
                    -- Beast Mastery or Marksmanship
                    local itemID = GetInventoryItemID('player', 16)
                    local subclassID = itemID and select(13, C_Item_GetItemInfo(itemID))
                    if subclassID == Enum_ItemWeaponSubclass_Guns then
                        itemLists.itemList = itemLists.gunFireList
                    else
                        itemLists.itemList = itemLists.bowAmmoList
                    end
                else
                    local itemID = GetInventoryItemID('player', 16)
                    local subclassID = itemID and select(13, C_Item_GetItemInfo(itemID))
                    if (
                        subclassID == Enum_ItemWeaponSubclass_Mace1H or
                        subclassID == Enum_ItemWeaponSubclass_Mace2H or
                        subclassID == Enum_ItemWeaponSubclass_Staff
                    ) then
                        itemLists.itemList = itemLists.balanceStoneList
                    else
                        itemLists.itemList = itemLists.sharpenStoneList
                    end
                end
            end,

            itemLists = {
                sharpenStoneList = {
                    none = {
                        191940, -- Primal Whetstone (Tier 3)
                        191939, -- Primal Whetstone (Tier 2)
                        191933, -- Primal Whetstone (Tier 1)
                        194820, -- Howling Rune (Tier 3)
                        194819, -- Howling Rune (Tier 2)
                        194817, -- Howling Rune (Tier 1)
                        194823, -- Buzzing Rune (Tier 3)
                        194822, -- Buzzing Rune (Tier 2)
                        194821, -- Buzzing Rune (Tier 1)
                        204973, -- Hissing Rune (Tier 3)
                        204972, -- Hissing Rune (Tier 2)
                        204971, -- Hissing Rune (Tier 1)
                    },
                },
                balanceStoneList = {
                    none = {
                        191945, -- Primal Weightstone (Tier 3)
                        191944, -- Primal Weightstone (Tier 2)
                        191943, -- Primal Weightstone (Tier 1)
                        194820, -- Howling Rune (Tier 3)
                        194819, -- Howling Rune (Tier 2)
                        194817, -- Howling Rune (Tier 1)
                        194823, -- Buzzing Rune (Tier 3)
                        194822, -- Buzzing Rune (Tier 2)
                        194821, -- Buzzing Rune (Tier 1)
                        204973, -- Hissing Rune (Tier 3)
                        204972, -- Hissing Rune (Tier 2)
                        204971, -- Hissing Rune (Tier 1)
                    },
                },
                bowAmmoList = {
                    none = {
                        198165, -- Endless Stack of Needles (Tier 3)
                        198164, -- Endless Stack of Needles (Tier 2)
                        198163, -- Endless Stack of Needles (Tier 1)
                    },
                },
                gunFireList = {
                    none = {
                        198162, -- Completely Safe Rockets (Tier 3)
                        198161, -- Completely Safe Rockets (Tier 2)
                        198160, -- Completely Safe Rockets (Tier 1)
                    },
                },
                oilList = {
                    ['TANK'] = {
                        none = {
                            194820, -- Howling Rune (Tier 3)
                            194819, -- Howling Rune (Tier 2)
                            194817, -- Howling Rune (Tier 1)
                            194823, -- Buzzing Rune (Tier 3)
                            194822, -- Buzzing Rune (Tier 2)
                            194821, -- Buzzing Rune (Tier 1)
                            204973, -- Hissing Rune (Tier 3)
                            204972, -- Hissing Rune (Tier 2)
                            204971, -- Hissing Rune (Tier 1)
                        },
                    },
                    ['DAMAGER'] = {
                        none = {
                            194820, -- Howling Rune (Tier 3)
                            194819, -- Howling Rune (Tier 2)
                            194817, -- Howling Rune (Tier 1)
                            194823, -- Buzzing Rune (Tier 3)
                            194822, -- Buzzing Rune (Tier 2)
                            194821, -- Buzzing Rune (Tier 1)
                            204973, -- Hissing Rune (Tier 3)
                            204972, -- Hissing Rune (Tier 2)
                            204971, -- Hissing Rune (Tier 1)
                        },
                    },
                    ['HEALER'] = {
                        none = {
                            194826, -- Chirping Rune (Tier 3)
                            194825, -- Chirping Rune (Tier 2)
                            194824, -- Chirping Rune (Tier 1)
                            194820, -- Howling Rune (Tier 3)
                            194819, -- Howling Rune (Tier 2)
                            194817, -- Howling Rune (Tier 1)
                            194823, -- Buzzing Rune (Tier 3)
                            194822, -- Buzzing Rune (Tier 2)
                            194821, -- Buzzing Rune (Tier 1)
                            204973, -- Hissing Rune (Tier 3)
                            204972, -- Hissing Rune (Tier 2)
                            204971, -- Hissing Rune (Tier 1)
                        },
                    },
                },
            },
        },
        {
            choose = function(itemLists)
                local itemID = GetInventoryItemID('player', 17)
                if itemID then
                    local itemType, _, _, _, subclassID = select(9, C_Item_GetItemInfo(itemID))
                    if (itemType and (
                        itemType == 'INVTYPE_WEAPON' or
                        itemType == 'INVTYPE_WEAPONOFFHAND' or
                        itemType == 'INVTYPE_2HWEAPON' or
                        itemType == 'INVTYPE_RANGED' or
                        itemType == 'INVTYPE_RANGEDRIGHT'
                    )) then
                        if (
                            subclassID == Enum_ItemWeaponSubclass_Mace1H or
                            subclassID == Enum_ItemWeaponSubclass_Mace2H or
                            subclassID == Enum_ItemWeaponSubclass_Staff
                        ) then
                            itemLists.itemList = itemLists.balanceStoneList
                        else
                            itemLists.itemList = itemLists.sharpenStoneList
                        end

                        return
                    end
                end

                itemLists.itemList = nil
            end,

            itemLists = {
                sharpenStoneList = {
                    none = {
                        191940, -- Primal Whetstone (Tier 3)
                        191939, -- Primal Whetstone (Tier 2)
                        191933, -- Primal Whetstone (Tier 1)
                        194820, -- Howling Rune (Tier 3)
                        194819, -- Howling Rune (Tier 2)
                        194817, -- Howling Rune (Tier 1)
                        194823, -- Buzzing Rune (Tier 3)
                        194822, -- Buzzing Rune (Tier 2)
                        194821, -- Buzzing Rune (Tier 1)
                    },
                },
                balanceStoneList = {
                    none = {
                        191945, -- Primal Weightstone (Tier 3)
                        191944, -- Primal Weightstone (Tier 2)
                        191943, -- Primal Weightstone (Tier 1)
                        194820, -- Howling Rune (Tier 3)
                        194819, -- Howling Rune (Tier 2)
                        194817, -- Howling Rune (Tier 1)
                        194823, -- Buzzing Rune (Tier 3)
                        194822, -- Buzzing Rune (Tier 2)
                        194821, -- Buzzing Rune (Tier 1)
                    },
                },
            },
        },
    },
}

---@class QuickMacroDataUtilityToyItemDataAuto
---@field type 'auto'
---@field name string
---@field icon number
---@field items table<number, number>

---@class QuickMacroDataUtilityToyItemDataList
---@field type 'list'
---@field name string
---@field icon number
---@field items number[]

---@class QuickMacroDataUtilityToyItemDataSolo
---@field type 'item'
---@field name string
---@field icon number
---@field item number

---@alias QuickMacroDataUtilityToyItemData QuickMacroDataUtilityToyItemDataAuto | QuickMacroDataUtilityToyItemDataList | QuickMacroDataUtilityToyItemDataSolo

---@class QuickMacroButtonUtilityToy: QuickMacroButton
---@field isMOLLEAvailable boolean
---@field mailItemID number
---@field usingIndex number

---@class QuickMacroDataUtilityToy: QuickMacroData
---@field list QuickMacroDataUtilityToyItemData[]
---@field updateFunc fun(button: QuickMacroButtonUtilityToy, data: self, inCombat: boolean): boolean
---@field displayFunc fun(button: QuickMacroButtonUtilityToy, data: self): nil
---@field clickFunc fun(button: QuickMacroButtonUtilityToy, button: string, down: boolean): nil
---@field menuGenerator fun(owner: QuickMacroButtonUtilityToy, rootDescription: table): nil
---@field isSelected fun(index: number): boolean
---@field setSelected fun(index: number): nil
QM.MacroButtons.UtilityToy = {
    name = "实用玩具",
    index = 6,

    updateEvent = {
        ['PLAYER_ENTERING_WORLD'] = true,
        ['ZONE_CHANGED_NEW_AREA'] = true,
    },
    updateFunc = function(button, data)
        if not button.initialized then
            -- item:40768 (MOLL-E)
            local info = C_TradeSkillUI_GetProfessionInfoBySkillLineID(2504)
            local isMOLLEUsable = info and info.skillLevel >= 50
            local isMOLLEAvailable = isMOLLEUsable and PlayerHasToy(40768)
            button.isMOLLEAvailable = isMOLLEAvailable

            -- item:156833 (Katy's Stampwhistle)
            -- item:194885 (Ohuna Perch)
            local mailItemID = PlayerHasToy(156833) and 156833 or 194885
            button.mailItemID = mailItemID

            button:SetAttribute('shift-type1', 'item')
            button:SetAttribute('*type1', 'item')
            button:HookScript('OnClick', data.clickFunc)
            button.usingIndex = 1

            button.itemDisplay.shiftIsToy = true
            button.itemDisplay.noneIsToy = true
            button.count:Hide()

            button.initialized = true
        end

        if button.isMOLLEAvailable then
            local _, duration, enable = C_Item_GetItemCooldown(40768)
            local isMOLLEOffCooldown = enable and duration == 0

            if isMOLLEOffCooldown then
                button:SetAttribute('shift-item1', 'item:40768')
                button.itemDisplay.shift = 40768
            else
                button:SetAttribute('shift-item1', 'item:' .. button.mailItemID)
                button.itemDisplay.shift = button.mailItemID
            end
        else
            button:SetAttribute('shift-item1', 'item:' .. button.mailItemID)
            button.itemDisplay.shift = button.mailItemID
        end

        local usingData = data.list[button.usingIndex]
        if usingData.type == 'auto' then
            local uiMapID = C_Map_GetBestMapForUnit('player')
            local itemID = usingData.items[uiMapID]
            if itemID then
                button:SetAttribute('*item1', 'item:' .. itemID)
                button.itemDisplay.none = itemID

                return true
            else
                usingData = data.list[button.usingIndex + 1]
            end
        end

        -- XXX: auto must be the first one, and plus one will find others
        if usingData.type == 'list' then
            local length = #usingData.items
            for index, itemID in ipairs(usingData.items) do
                if index == length or PlayerHasToy(itemID) then
                    button:SetAttribute('*item1', 'item:' .. itemID)
                    button.itemDisplay.none = itemID
                end
            end
        elseif usingData.type == 'item' then
            local itemID = usingData.item
            button:SetAttribute('*item1', 'item:' .. itemID)
            button.itemDisplay.none = itemID
        end

        return true
    end,
    displayFunc = ItemDisplayFunc,

    clickFunc = function(self, button, down)
        if button == 'RightButton' and not down then
            MenuUtil_CreateContextMenu(self, QM.MacroButtons.UtilityToy.menuGenerator)
        end
    end,
    menuGenerator = function(_, rootDescription)
        local data = QM.MacroButtons.UtilityToy
        for index, entry in ipairs(QM.MacroButtons.UtilityToy.list) do
            local radio = rootDescription:CreateRadio(entry.name, data.isSelected, data.setSelected, index)
            radio:AddInitializer(function(self)
                local texture = self:AttachTexture()
                texture:SetPoint('RIGHT')
                texture:SetSize(16, 16)
                texture:SetTexture(entry.icon)
                texture:SetTexCoord(.1, .9, .1, .9)

                local fontString = self.fontString
                fontString:SetPoint('RIGHT', texture, 'LEFT')

                local width, height = fontString:GetUnboundedStringWidth() + 20, 20
                return width, height
            end)
        end
    end,
    isSelected = function(index)
        return QM.buttons.UtilityToy.usingIndex == index
    end,
    setSelected = function(index)
        local data = QM.MacroButtons.UtilityToy
        local button = QM.buttons.UtilityToy
        ---@cast button QuickMacroButtonUtilityToy

        button.usingIndex = index

        if not InCombatLockdown() then
            data.updateFunc(button, data, false)
            ItemDisplayFunc(button)
        end
    end,
    list = {
        {
            type = 'auto',
            name = "自动",
            icon = 134269,
            items = {
                [1695] = 158149, -- Overtuned Corgi Goggles
            },
        },
        {
            type = 'list',
            name = "阳伞",
            icon = 644385,
            items = {
                182694, -- Stylish Black Parasol
                182695, -- Weathered Purple Parasol
                182696, -- The Countess's Parasol
                212500, -- Delicate Silk Parasol
                212523, -- Delicate Jade Parasol
                212524, -- Delicate Crimson Parasol
                212525, -- Delicate Ebony Parasol
            },
        },
        {
            type = 'list',
            name = "假人",
            icon = 134012,
            items = {
                201933, -- Black Dragon's Challenge Dummy
                199830, -- Tuskarr Training Dummy
                88375, -- Turnip Punching Bag
            },
        },
        {
            type = 'item',
            name = "垂钓翁钓鱼筏",
            icon = 774121,
            item = 85500, -- Eyes For You Only
        },
        {
            type = 'item',
            name = "发条式火车破坏者",
            icon = 134152,
            item = 45057, -- Wind-Up Train Wrecker
        },
        {
            type = 'item',
            name = "眼里只有你",
            icon = 3557126,
            item = 210974, -- Eyes For You Only
        },
        {
            type = 'item',
            name = "柔软的泡沫塑料剑",
            icon = 252282,
            item = 137663, -- Soft Foam Sword
        },
        {
            type = 'item',
            name = "整体缩小仪",
            icon = 801002,
            item = 97919, -- Whole-Body Shrinka'
        },
        {
            type = 'item',
            name = "瞬息全战团地图",
            icon = 237387,
            item = 212174, -- The Warband Map to Everywhere All At Once
        },
    },
}

---@class QuickMacroDataCorpseToy: QuickMacroData
---@field toyList number[]
---@field updateFunc fun(button: QuickMacroButton, data: self, inCombat: boolean): boolean
---@field displayFunc fun(button: QuickMacroButton, data: self): nil
---@field clickFunc fun(self: QuickMacroButton, button: string, down: boolean): nil
QM.MacroButtons.CorpseToy = {
    name = "友军尸体玩具",
    index = 7,

    updateEvent = {
        ['PLAYER_ENTERING_WORLD'] = true,
        ['SPELL_UPDATE_COOLDOWN'] = true,
    },
    updateFunc = function(button, data)
        if not button.initialized then
            button:SetAttribute('*type1', 'item')
            button:HookScript('OnClick', data.clickFunc)
            button.count:Hide()

            button.initialized = true
        end

        local now = GetTime()

        if button.itemDisplay.none then
            local startTime, duration, enable = C_Item_GetItemCooldown(button.itemDisplay.none)
            if enable and (duration == 0 or (now + 5 >= startTime + duration)) then
                return true
            end
        end

        local list = {}
        for _, itemID in ipairs(data.toyList) do
            if PlayerHasToy(itemID) then
                local startTime, duration, enable = C_Item_GetItemCooldown(itemID)
                if enable and (duration == 0 or (now + 5 >= startTime + duration)) then
                    tinsert(list, itemID)
                end
            end
        end

        local itemID = #list > 0 and list[random(#list)] or data.toyList[1]
        button:SetAttribute('*item1', 'item:' .. itemID)
        button.itemDisplay.none = itemID
        button.itemDisplay.noneIsToy = true

        return true
    end,
    displayFunc = ItemDisplayFunc,

    clickFunc = function(self, button, down)
        if button == 'RightButton' and not down and not InCombatLockdown() then
            local data = QM.MacroButtons.CorpseToy
            local now = GetTime()

            local list = {}
            for _, itemID in ipairs(data.toyList) do
                if PlayerHasToy(itemID) then
                    local startTime, duration, enable = C_Item_GetItemCooldown(itemID)
                    if enable and (duration == 0 or (now + 5 >= startTime + duration)) then
                        tinsert(list, itemID)
                    end
                end
            end

            local itemID = #list > 0 and list[random(#list)] or data.toyList[1]
            self:SetAttribute('*item1', 'item:' .. itemID)
            self.itemDisplay.none = itemID
            self.itemDisplay.noneIsToy = true

            data.displayFunc(self, data)
            ButtonOnEnter(self)
        end
    end,
    toyList = {
        ---AUTO_GENERATED LEADING QuickMacroCorpseToy
        88589,  -- Cremating Torch
        90175,  -- Gin-Ji Knife Set
        119163, -- Soul Inhaler
        163740, -- Drust Ritual Knife
        166701, -- Warbeast Kraal Dinner Bell
        166784, -- Narassin's Soul Gem
        187174, -- Shaded Judgment Stone
        194052, -- Forlorn Funeral Pall
        200469, -- Khadgar's Disenchanting Rod
        215145, -- Remembrance Stone
        ---AUTO_GENERATED TRAILING QuickMacroCorpseToy
    },
}

do
    ---@param left string
    ---@param right string
    local function buttonSort(left, right)
        return (QM.MacroButtons[left].index or 0) < (QM.MacroButtons[right].index or 0)
    end
    ---@type string[]
    local pendingButton = {}

    ---@param event string?
    function QM:UpdateButton(event)
        if InCombatLockdown() then return end

        local inCombat = event == 'PLAYER_REGEN_DISABLED'

        wipe(pendingButton)
        local positionUpdate = not event
        for buttonName, button in pairs(self.buttons) do
            local data = self.MacroButtons[buttonName]

            local isShown = button:IsShown()
            local show = isShown
            if (
                not event or
                event == 'PLAYER_REGEN_DISABLED' or
                event == 'PLAYER_REGEN_ENABLED' or
                data.updateEvent[event]
            ) then
                show = data.updateFunc(button, data, inCombat)
            end

            if show then
                positionUpdate = positionUpdate or not isShown
                button:Show()

                tinsert(pendingButton, buttonName)
            elseif isShown and not show then
                positionUpdate = true
                button:Hide()
            end
        end

        if positionUpdate then
            sort(pendingButton, buttonSort)
            local buttonPerRow = E.db.RhythmBox.QuickMacro.ButtonPerRow
            for index, buttonName in ipairs(pendingButton) do
                local button = self.buttons[buttonName]
                button:ClearAllPoints()
                if index == 1 then
                    button:SetPoint('LEFT')
                elseif (index - 1) % buttonPerRow == 0 then -- first button in a row
                    button:SetPoint('TOP', self.buttons[pendingButton[index - buttonPerRow]], 'BOTTOM', 0, -3)
                else
                    button:SetPoint('LEFT', self.buttons[pendingButton[index - 1]], 'RIGHT', 3, 0)
                end
            end
        end

        self:UpdateDisplay()
    end
end

function QM:UpdateDisplay()
    for buttonName, button in pairs(self.buttons) do
        if button:IsShown() then
            local data = self.MacroButtons[buttonName]
            data.displayFunc(button, data)

            if button:IsMouseOver() then
                ButtonOnEnter(button)
            end
        end
    end
end

function QM:UpdateBinding()
    for buttonName, button in pairs(self.buttons) do
        local bindButton = 'CLICK RhythmBoxQM' .. buttonName .. ':LeftButton'
        local bindText = GetBindingKey(bindButton)

        if not bindText then
            bindText = ''
        else
            bindText = gsub(bindText, 'SHIFT--', 'S')
            bindText = gsub(bindText, 'CTRL--', 'C')
            bindText = gsub(bindText, 'ALT--', 'A')
        end

        button.bind:SetText(bindText)
    end
end

function QM:UpdateItemCount()
    for _, button in pairs(self.buttons) do
        if button:IsShown() and button.displayType == 'item' and button.itemID then
            local itemCount = C_Item_GetItemCount(button.itemID, nil, true) or 0
            button.count:SetText(tostring(itemCount))
        end
    end

    for _, button in pairs(self.external) do
        if button:IsShown() and button.displayType == 'item' and button.itemID then
            local itemCount = C_Item_GetItemCount(button.itemID, nil, true) or 0
            button.count:SetText(tostring(itemCount))
        end
    end
end

function QM:Toggle()
    if E.db.RhythmBox.QuickMacro.Enable then
        self.container:Show()

        for _, data in pairs(self.MacroButtons) do
            for event in pairs(data.updateEvent) do
                self:RegisterEvent(event, 'UpdateButton')
            end
        end

        self:RegisterEvent('PLAYER_REGEN_DISABLED', 'UpdateButton')
        self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateButton')
        self:RegisterEvent('MODIFIER_STATE_CHANGED', 'UpdateDisplay')

        self:RegisterEvent('UPDATE_BINDINGS', 'UpdateBinding')
        self:RegisterEvent('BAG_UPDATE', 'UpdateItemCount')

        self:UpdateButton()
        self:UpdateBinding()
    else
        self.container:Hide()
        self:UnregisterAllEvents()
    end
end

---@param buttonName string
---@param parent Frame?
function QM:UpdateButtonLayout(buttonName, parent)
    ---@type QuickMacroButton
    local current
    if not parent or parent == self.container then
        parent = self.container
        current = self.buttons[buttonName]
    else
        current = self.external[buttonName]
    end

    if not current then
        local button = CreateFrame('Button', 'RhythmBoxQM' .. buttonName, parent, 'SecureActionButtonTemplate, BackdropTemplate')
        ---@cast button QuickMacroButton

        button.itemDisplay = {}

        button:SetScript('OnEnter', ButtonOnEnter)
        button:SetScript('OnLeave', ButtonOnLeave)
        button:SetScript('OnUpdate', ButtonOnUpdate)

        button:SetTemplate('Default')
        button:StyleButton()
        button:EnableMouse(true)
        button:RegisterForClicks('AnyUp', 'AnyDown')

        -- Icon
        button.icon = button:CreateTexture(nil, 'OVERLAY')
        button.icon:SetInside(button, 2, 2)
        button.icon:SetTexCoord(.1, .9, .1, .9)

        -- Quality Overlay
        button.qualityOverlay = button:CreateTexture(nil, 'OVERLAY')
        button.qualityOverlay:SetPoint("TOPLEFT", -3, 2)

        -- Count
        button.count = button:CreateFontString(nil, 'OVERLAY')
        button.count:SetTextColor(1, 1, 1, 1)
        button.count:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', .5 ,0)
        button.count:SetJustifyH('CENTER')

        -- Binding Text
        button.bind = button:CreateFontString(nil, 'OVERLAY')
        button.bind:SetTextColor(.6, .6, .6)
        button.bind:SetPoint('TOPRIGHT', button, 'TOPRIGHT', 1 ,-3)
        button.bind:SetJustifyH('RIGHT')

        -- Cooldown
        ---@class QuickMacroButtonCooldown: Cooldown
        button.cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
        button.cooldown:SetInside(button, 2, 2)
        button.cooldown:SetDrawEdge(false)
        button.cooldown.CooldownOverride = 'actionbar'

        E:RegisterCooldown(button.cooldown)
        E:RegisterPetBattleHideFrames(button, parent)

        if parent == self.container then
            self.buttons[buttonName] = button
        else
            self.external[buttonName] = button
        end

        current = button
    end

    current:SetSize(E.db.RhythmBox.QuickMacro.ButtonSize, E.db.RhythmBox.QuickMacro.ButtonSize)
    current.bind:FontTemplate(nil, E.db.RhythmBox.QuickMacro.BindFontSize, 'OUTLINE')
    current.count:FontTemplate(nil, E.db.RhythmBox.QuickMacro.CountFontSize, 'OUTLINE')
    return current
end

function QM:UpdateLayout()
    for buttonName in pairs(self.MacroButtons) do
        self:UpdateButtonLayout(buttonName)
    end

    for buttonName in pairs(self.external) do
        self:UpdateButtonLayout(buttonName)
    end
end

_G['BINDING_HEADER_RhythmBoxQuickMacro'] = "Rhythm Box 快速宏动作条"
for buttonName, data in pairs(QM.MacroButtons) do
    _G['BINDING_NAME_CLICK RhythmBoxQM' .. buttonName .. ':LeftButton'] = data.name
end

P["RhythmBox"]["QuickMacro"] = {
    ["Enable"] = true,
    ["ButtonSize"] = 40,
    ["CountFontSize"] = 18,
    ["BindFontSize"] = 18,
    ["ButtonPerRow"] = 7,
    ["Hearthstone"] = {},
}
for _, itemID in ipairs(QM.MacroButtons.RandomHearthstone.hearthstoneList) do
    P["RhythmBox"]["QuickMacro"]["Hearthstone"][itemID] = true
end

R:RegisterOptions(function()
    local buttonLength = 0
    for _ in pairs(QM.MacroButtons) do
        buttonLength = buttonLength + 1
    end

    E.Options.args.RhythmBox.args.QuickMacro = {
        order = 24,
        type = 'group',
        name = "快速宏动作条",
        get = function(info) return E.db.RhythmBox.QuickMacro[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.QuickMacro[ info[#info] ] = value; QM:UpdateLayout() end,
        args = {
            Enable = {
                order = 1,
                type = 'toggle',
                name = "启用",
                set = function(info, value) E.db.RhythmBox.QuickMacro[info[#info]] = value; QM:Toggle() end,
            },
            Space = {
                order = 10,
                type = 'description',
                name = "",
                width = 'full',
            },
            ButtonSize = {
                order = 11,
                type = 'range',
                name = "按钮尺寸",
                min = 10, max = 100, step = 1,
            },
            ButtonPerRow = {
                order = 12,
                type = 'range',
                name = "每行按钮数",
                min = 1, max = buttonLength, step = 1,
            },
            BindFontSize = {
                order = 13,
                type = 'range',
                min = 4, max = 40, step = 1,
                name = "键位文字字体尺寸",
            },
            CountFontSize = {
                order = 14,
                type = 'range',
                min = 4, max = 40, step = 1,
                name = "物品数量字体尺寸",
            },
            HearthstoneList = {
                order = 20,
                type = 'multiselect',
                name = "随机炉石列表",
                get = function(_, k) return E.db.RhythmBox.QuickMacro.Hearthstone[k] end,
                set = function(_, k, v) E.db.RhythmBox.QuickMacro.Hearthstone[k] = v; QM:UpdateButton() end,
                values = {},
            },
        },
    }

    for _, itemID in ipairs(QM.MacroButtons.RandomHearthstone.hearthstoneList) do
        local itemName = C_Item_GetItemNameByID(itemID)
        if itemName then
            E.Options.args.RhythmBox.args.QuickMacro.args.HearthstoneList.values[itemID] = itemName
        else
            E.Options.args.RhythmBox.args.QuickMacro.args.HearthstoneList.values[itemID] = itemID

            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(function()
                E.Options.args.RhythmBox.args.QuickMacro.args.HearthstoneList.values[itemID] = C_Item_GetItemNameByID(itemID)
            end)
        end
    end
end)

function QM:Initialize()
    ---@type table<string, QuickMacroButton>
    self.buttons = {}
    ---@type table<string, QuickMacroButton>
    self.external = {}

    local frameName = 'RhythmBoxQuickMacroContainer'
    self.container = CreateFrame('Frame', frameName, E.UIParent)
    self.container:ClearAllPoints()
    self.container:SetPoint('BOTTOMLEFT', _G.RightChatPanel or _G.LeftChatPanel, 'TOPLEFT', 0, -40)
    self.container:SetSize(7 * E.db.RhythmBox.QuickMacro.ButtonSize, E.db.RhythmBox.QuickMacro.ButtonSize)
    E:CreateMover(self.container, frameName .. 'Mover', "Rhythm Box 快速宏动作条", nil, nil, nil, 'ALL,RHYTHMBOX')

    self:UpdateLayout()
    self:Toggle()
end

R:RegisterModule(QM:GetName())
