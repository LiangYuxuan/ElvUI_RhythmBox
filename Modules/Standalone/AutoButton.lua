local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local AB = R:NewModule('AutoButton', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local gsub, ipairs, pairs, select, sort = gsub, ipairs, pairs, select, sort
local tinsert, type, tonumber, wipe = tinsert, type, tonumber, wipe

-- WoW API / Variables
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_TaskQuest_GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsForPlayerByMapID
local CreateFrame = CreateFrame
local GetBindingKey = GetBindingKey
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetInventoryItemID = GetInventoryItemID
local GetItemCooldown = GetItemCooldown
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetItemSpell = GetItemSpell
local GetMinimapZoneText = GetMinimapZoneText
local GetNumQuestWatches = GetNumQuestWatches
local GetQuestLogIndexByID = GetQuestLogIndexByID
local GetQuestLogSpecialItemCooldown = GetQuestLogSpecialItemCooldown
local GetQuestLogSpecialItemInfo = GetQuestLogSpecialItemInfo
local GetQuestWatchInfo = GetQuestWatchInfo
local GetSpecializationInfo = GetSpecializationInfo
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local IsItemInRange = IsItemInRange

local CooldownFrame_Set = CooldownFrame_Set

local LE_UNIT_STAT_STRENGTH = LE_UNIT_STAT_STRENGTH
local LE_UNIT_STAT_AGILITY = LE_UNIT_STAT_AGILITY
local LE_UNIT_STAT_INTELLECT = LE_UNIT_STAT_INTELLECT

AB.mineItems = {
    118897, -- Miner's Coffee
    118903, -- Preserved Mining Pick
}
AB.yardItems = {
    114116, -- Bag of Salvaged Goods
    114119, -- Crate of Salvage
    114120, -- Big Crate of Salvage
    120301, -- Armor Enhancement Token
    120302, -- Weapon Enhancement Token
}
AB.blackList = {
    [169064] = true, -- Mountebank's Colorful Cloak
}
AB.whiteList = {
    -- General
    -- [itemID] = true or 99, -- item sample
    -- Smart
    ['Repair'] = function()
        local inInstance, instanceType = IsInInstance()
        if not inInstance or (instanceType ~= 'party' and instanceType ~= 'raid') then return end

        local count = GetItemCount(49040) -- Jeeves
        if count and count > 0 then
            local _, duration, enable = GetItemCooldown(49040) -- Jeeves
            if duration == 0 and enable == 1 then
                return 49040, true -- Jeeves
            end
        end
        count = GetItemCount(132514) -- Auto-Hammer
        if count and count > 0 then
            return 132514, true -- Auto-Hammer
        end
    end,
    ['Glider Kit'] = function()
        local itemList = {
            167861, -- Alliance Glider Kit
            167862, -- Horde Glider Kit
            109076, -- Goblin Glider Kit
        }
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType ~= 'pvp' then return end

        for _, itemID in ipairs(itemList) do
            local count = GetItemCount(itemID)
            if count and count > 0 then
                return itemID, true
            end
        end
    end,
    ['Drum'] = function()
        local itemList = {
            164978, -- Mallet of Thunderous Skins
            120257, -- Drums of Fury
            142406, -- Drums of the Mountain
            154167, -- Drums of the Maelstrom
        }
        local inInstance, instanceType = IsInInstance()
        if not inInstance or (instanceType ~= 'party' and instanceType ~= 'raid') then return end

        for _, itemID in ipairs(itemList) do
            local count = GetItemCount(itemID)
            if count and count > 0 then
                return itemID, 99
            end
        end
    end,
    ['Flask'] = function()
        local repeatable = 147707 -- Repurposed Fel Focuser
        local preferRepeatable = true

        local inInstance, instanceType = IsInInstance()
        if not inInstance or (instanceType ~= 'party' and instanceType ~= 'raid') then
            local count = GetItemCount(repeatable)
            if count and count > 0 then
                return repeatable, 2
            end
            return
        end

        if preferRepeatable then
            local count = GetItemCount(repeatable)
            if count and count > 0 then
                local _, duration, enable = GetItemCooldown(repeatable)
                if duration == 0 and enable == 1 then
                    return repeatable, 2
                end
            end
        end

        local primaryStat = select(7, GetSpecializationInfo(E.myspec))
        local itemList = {
            [LE_UNIT_STAT_STRENGTH] = {
                152641, -- Flask of the Undertow
                168654, -- Greater Flask of the Undertow
                repeatable,
            },
            [LE_UNIT_STAT_AGILITY] = {
                152638, -- Flask of the Currents
                168651, -- Greater Flask of the Currents
                repeatable,
            },
            [LE_UNIT_STAT_INTELLECT] = {
                152639, -- Flask of Endless Fathoms
                168652, -- Greater Flask of Endless Fathoms
                repeatable,
            },
        }
        for _, itemID in ipairs(itemList[primaryStat]) do
            local count = GetItemCount(itemID)
            if count and count > 0 then
                return itemID, 2
            end
        end
    end,
    ['Rune'] = function()
        if E.mylevel >= 120 then return end

        local count = GetItemCount(153023)
        if count and count > 0 then
            return 153023, true
        end
    end,
    -- use this in future
    -- ['Potion'] = function()
    -- end,

    -- Legion
    [142117] = true, -- Potion of Prolonged Power
}

AB.maxButton = 12
AB.buttonTypes = {
    ['Quest'] = "自动任务物品按键",
    ['Slot'] = "自动装备饰品按键",
}

-- Binding Variables
for buttonType, buttonName in pairs(AB.buttonTypes) do
    _G['BINDING_HEADER_Auto'.. buttonType .. 'Button'] = "|cFF70B8FFRhythm Box|r" .. buttonName
    for i = 1, AB.maxButton do
        _G['BINDING_NAME_CLICK Auto' .. buttonType .. 'Button' .. i .. ':LeftButton'] = buttonName .. i
    end
end

local function itemCompare(left, right)
    local leftPriority = AB.itemPriorities[left] or 1
    local rightPriority = AB.itemPriorities[right] or 1

    if leftPriority ~= rightPriority then
        return leftPriority > rightPriority
    else
        local leftType = select(7, GetItemInfo(left))
        local rightType = select(7, GetItemInfo(right))
        if leftType and rightType and leftType ~= rightType then
            return leftType > rightType
        end
    end

    return left > right
end

local function ButtonOnEnter(self)
    if not self.slotID and not self.itemID then return end

    _G.GameTooltip:Hide()
    _G.GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 0, -2)
    _G.GameTooltip:ClearLines()

    if self.slotID then
        _G.GameTooltip:SetInventoryItem('player', self.slotID)
    else
        _G.GameTooltip:SetItemByID(self.itemID)
    end

    _G.GameTooltip:Show()
end

local function ButtonOnLeave(self)
    _G.GameTooltip:Hide()
end

local function ButtonOnUpdate(self)
    if not self.slotID and not self.itemID then return end

    local start, duration, enable
    if self.questLogIndex then
        start, duration, enable = GetQuestLogSpecialItemCooldown(self.questLogIndex)
    elseif self.slotID then
        start, duration, enable = GetInventoryItemCooldown('player', self.slotID)
    else
        start, duration, enable = GetItemCooldown(self.itemID)
    end

    CooldownFrame_Set(self.cooldown, start, duration, enable)

    if duration > 0 and enable == 0 then
        self.icon:SetVertexColor(.4, .4, .4)
    elseif not self.slotID and not IsItemInRange(self.itemID, 'target') then
        self.icon:SetVertexColor(1, 0, 0)
    else
        self.icon:SetVertexColor(1, 1, 1)
    end
end

function AB:HideBar()
    for buttonType in pairs(self.buttonTypes) do
        for i = 1, self.maxButton do
            local button = self.buttonPool[buttonType] and self.buttonPool[buttonType][i]
            if not button then break end
            button:Hide()
        end
    end
end

function AB:UpdateItem()
    wipe(self.items)
    wipe(self.itemPriorities)

    local zone = GetMinimapZoneText()
    if zone == '坠月挖掘场' or zone == '霜壁矿井' then
        for _, itemID in ipairs(self.mineItems) do
            local count = GetItemCount(itemID)
            if count and count > 0 then
                tinsert(self.items, itemID)
            end
        end
    elseif zone == '废品站' then
        for _, itemID in ipairs(self.yardItems) do
            local count = GetItemCount(itemID)
            if count and count > 0 then
                tinsert(self.items, itemID)
            end
        end
    else
        for itemID, priority in pairs(self.whiteList) do
            if type(itemID) ~= 'number' then
                itemID, priority = priority()
            end
            if priority then
                local count = GetItemCount(itemID)
                if count and count > 0 then
                    tinsert(self.items, itemID)
                    if type(priority) == 'number' then
                        self.itemPriorities[itemID] = priority
                    end
                end
            end
        end
    end

    if not self.firstCalling then
        self:UpdateAutoButton()
    end
end

function AB:UpdateInventory()
    wipe(self.inventory)

    local length = 0
    for slotID = 1, 19 do
        local itemID = GetInventoryItemID('player', slotID)
        if itemID and not self.blackList[itemID] then
            local spellID = GetItemSpell(itemID)
            if spellID then
                local _, _, rarity, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
                length = length + 1
                self.inventory[length] = {
                    slotID = slotID,
                    rarity = rarity,
                    itemIcon = itemIcon,
                }
                if length == E.db.RhythmBox.AutoButton.SlotNum then break end
            end
        end
    end

    if not self.firstCalling then
        self:UpdateAutoButton()
    end
end

function AB:UpdateQuestItem()
    wipe(self.questItems)

    -- update world quest item
    local mapID = C_Map_GetBestMapForUnit()
    local questInfo = C_TaskQuest_GetQuestsForPlayerByMapID(mapID)
    if questInfo and #questInfo > 0 then
        for _, info in pairs(questInfo) do
            local questLogIndex = GetQuestLogIndexByID(info.questId)
            if questLogIndex then
                local itemLink = GetQuestLogSpecialItemInfo(questLogIndex)
                if itemLink then
                    local itemID = tonumber(itemLink:match(':(%d+):'))
                    self.questItems[itemID] = questLogIndex
                end
            end
        end
    end

    -- update normal quest item
    for i = 1, GetNumQuestWatches() do
        local _, _, questLogIndex, _, _, isComplete = GetQuestWatchInfo(i)
        if questLogIndex then
            local itemLink, _, _, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
            if itemLink and (not showItemWhenComplete or not isComplete) then
                local itemID = tonumber(itemLink:match(':(%d+):'))
                self.questItems[itemID] = questLogIndex
            end
        end
    end

    if not self.firstCalling then
        self:UpdateAutoButton()
    end
end

function AB:UpdateAutoButton(event)
    if event == 'PLAYER_REGEN_ENABLED' and not self.requireUpdate then return end

    if InCombatLockdown() then
        self.requireUpdate = true
        return
    end
    self.requireUpdate = nil

    self:HideBar()

    local pending = {}
    for _, itemID in ipairs(self.items) do
        tinsert(pending, itemID)
    end
    for itemID in pairs(self.questItems) do
        tinsert(pending, itemID)
    end

    sort(pending, itemCompare)

    for i = 1, E.db.RhythmBox.AutoButton.QuestNum do
        local itemID = pending[i]
        if not itemID then break end
        local itemName, _, rarity, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
        local count = GetItemCount(itemID)

        local button = self.buttonPool.Quest[i]

        local r, g, b = GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)
        button:SetBackdropBorderColor(r, g, b)
        button.icon:SetTexture(itemIcon)
        if count and count > 1 then
            button.count:SetText(count)
        else
            button.count:SetText("")
        end

        button.itemID = itemID
        button.questLogIndex = self.questItems[itemID]
        button:SetAttribute('type', 'item')
        button:SetAttribute('item', itemName)
        button:Show()
    end

    for i = 1, E.db.RhythmBox.AutoButton.SlotNum do
        local button = self.buttonPool.Slot[i]
        local tbl = self.inventory[i]

        local r, g, b = GetItemQualityColor((tbl.rarity and tbl.rarity > 1 and tbl.rarity) or 1)
        button:SetBackdropBorderColor(r, g, b)
        button.icon:SetTexture(tbl.itemIcon)

        button.slotID = tbl.slotID
        button:SetAttribute('type', 'macro')
        button:SetAttribute('macrotext', '/use ' .. tbl.slotID)
        button:Show()
    end
end

function AB:UPDATE_BINDINGS()
    for buttonType in pairs(self.buttonTypes) do
        local buttonNum = E.db.RhythmBox.AutoButton[buttonType .. 'Num']
        for i = 1, buttonNum do
            local button = self.buttonPool[buttonType][i]

            local bindButton = 'CLICK Auto' .. buttonType .. 'Button' .. i .. ':LeftButton'
            local bindText = GetBindingKey(bindButton)

            if not bindText then
                bindText = ''
            else
                bindText = gsub(bindText, 'SHIFT--', 'S')
                bindText = gsub(bindText, 'CTRL--', 'C')
                bindText = gsub(bindText, 'ALT--', 'A')
            end

            if button then
                button.bind:SetText(bindText)
            end
        end
    end
end

function AB:UpdateItemCount()
    -- we don't have to update slot button, they don't have count
    for i = 1, E.db.RhythmBox.AutoButton.QuestNum do
        local button = self.buttonPool.Quest[i]
        if button and button.itemID then
            local count = GetItemCount(button.itemID, nil, true)
            if count and count > 1 then
                button.count:SetText(count)
            else
                button.count:SetText("")
            end
        end
    end
end

function AB:Toggle()
    self:UnregisterAllEvents()

    if E.db.RhythmBox.AutoButton.Enable then
        self.items = {}
        self.itemPriorities = {}
        self.inventory = {}
        self.questItems = {}

        if E.db.RhythmBox.AutoButton.SlotNum > 0 then
            self:RegisterEvent('UNIT_INVENTORY_CHANGED', 'UpdateInventory')
        end

        if E.db.RhythmBox.AutoButton.QuestNum > 0 then
            self:RegisterEvent('BAG_UPDATE_DELAYED', 'UpdateItem')
            self:RegisterEvent('ZONE_CHANGED', 'UpdateItem')
            self:RegisterEvent('ZONE_CHANGED_INDOORS', 'UpdateItem')
            self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', 'UpdateItem')

            self:RegisterEvent('QUEST_LOG_UPDATE', 'UpdateQuestItem')
            self:RegisterEvent('QUEST_WATCH_LIST_CHANGED', 'UpdateQuestItem')
            self:RegisterEvent('QUEST_ACCEPTED', 'UpdateQuestItem')
            self:RegisterEvent('QUEST_TURNED_IN', 'UpdateQuestItem')
        end

        self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateAutoButton')

        self:RegisterEvent('UPDATE_BINDINGS')

        if not self.timer then
            self.timer = self:ScheduleRepeatingTimer('UpdateItemCount', .5)
        end

        self.firstCalling = true
        if E.db.RhythmBox.AutoButton.SlotNum > 0 then
            self:UpdateInventory()
        end
        if E.db.RhythmBox.AutoButton.QuestNum > 0 then
            self:UpdateItem()
            self:UpdateQuestItem()
        end
        self.firstCalling = nil

        self.requireUpdate = nil
        self:UpdateAutoButton()
        self:UpdateBind()
    else
        if self.timer then
            self:CancelTimer(self.timer)
            self.timer = nil
        end

        self:HideBar()
    end
end

function AB:CreateButton(buttonType, index, size)
    local buttonSize = E.db.RhythmBox.AutoButton[buttonType .. 'Size']

    if not self.buttonPool[buttonType] then self.buttonPool[buttonType] = {} end

    local button = self.buttonPool[buttonType][index]
    if not button then
        local buttonName = 'Auto' .. buttonType .. 'Button' .. index

        -- Create Button
        button = CreateFrame('Button', buttonName, E.UIParent, 'SecureActionButtonTemplate')
        button:Hide()
        button:SetScript('OnEnter', ButtonOnEnter)
        button:SetScript('OnLeave', ButtonOnLeave)
        button:SetScript('OnUpdate', ButtonOnUpdate)

        button:SetTemplate('Default')
        button:StyleButton()
        button:EnableMouse(true)
        button:RegisterForClicks('AnyUp')

        -- Icon
        button.icon = button:CreateTexture(nil, 'OVERLAY')
        button.icon:Point('TOPLEFT', button, 'TOPLEFT', 2, -2)
        button.icon:Point('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -2, 2)
        button.icon:SetTexCoord(.1, .9, .1, .9)

        -- Count
        button.count = button:CreateFontString(nil, 'OVERLAY')
        button.count:SetTextColor(1, 1, 1, 1)
        button.count:Point('BOTTOMRIGHT', button, 'BOTTOMRIGHT', .5 ,0)
        button.count:SetJustifyH('CENTER')

        -- Binding Text
        button.bind = button:CreateFontString(nil, 'OVERLAY')
        button.bind:SetTextColor(.6, .6, .6)
        button.bind:Point('TOPRIGHT', button, 'TOPRIGHT', 1 ,-3)
        button.bind:SetJustifyH('RIGHT')

        -- Cooldown
        button.cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
        button.cooldown:Point('TOPLEFT', button, 'TOPLEFT', 2, -2)
        button.cooldown:Point('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -2, 2)
        button.cooldown:SetSwipeColor(0, 0, 0, 0)
        button.cooldown:SetDrawBling(false)
        E:RegisterCooldown(button.cooldown)

        E.FrameLocks[buttonName] = true

        self.buttonPool[buttonType][index] = button
    end

    button:Size(buttonSize)
    button.bind:FontTemplate(nil, E.db.RhythmBox.AutoButton.BindFontSize, 'OUTLINE')
    button.count:FontTemplate(nil, E.db.RhythmBox.AutoButton.CountFontSize, 'OUTLINE')
    return button
end

function AB:UpdateLayout()
    for buttonType in pairs(self.buttonTypes) do
        local buttonPerRow = E.db.RhythmBox.AutoButton[buttonType .. 'PerRow']
        local buttonNum = E.db.RhythmBox.AutoButton[buttonType .. 'Num']
        for i = 1, buttonNum do
            local button = self:CreateButton(buttonType, i)
            if i == 1 then -- first button
                button:Point('LEFT', self.ABQuestItemAnchor)
            elseif (i - 1) % buttonPerRow then -- first button in a row
                button:Point('TOP', self.buttonPool[buttonType][i - buttonPerRow], 'BOTTOM', 0, -3)
            else
                button:Point('LEFT', self.buttonPool[buttonType][i - 1], 'RIGHT', 3, 0)
            end
        end
    end
end

P["RhythmBox"]["AutoButton"] = {
    ["Enable"] = true,
    ["QuestNum"] = 5,
    ["QuestPerRow"] = 5,
    ["QuestSize"] = 40,
    ["SlotNum"] = 5,
    ["SlotPerRow"] = 5,
    ["SlotSize"] = 40,
    ["CountFontSize"] = 18,
    ["BindFontSize"] = 18,
}

local function AutoButtonOptions()
    E.Options.args.RhythmBox.args.AutoButton = {
        order = 6,
        type = 'group',
        name = "增强鼠标提示",
        get = function(info) return E.db.RhythmBox.AutoButton[info[#info]] end,
        set = function(info, value) E.db.RhythmBox.AutoButton[info[#info]] = value; AB:UpdateLayout() end,
        args = {
            Enable = {
                order = 1,
                type = 'toggle',
                name = "启用",
                set = function(info, value) E.db.RhythmBox.AutoButton[info[#info]] = value; AB:Toggle() end,
            },
            BindFontSize = {
                order = 2,
                type = 'range',
                min = 4, max = 40, step = 1,
                name = "键位文字字体尺寸",
            },
            CountFontSize = {
                order = 3,
                type = "range",
                min = 4, max = 40, step =1,
                name = "物品数量字体尺寸",
            },
            Space1 = {
                order = 4,
                type = 'description',
                name = "",
                width = 'full',
            },
            QuestNum = {
                order = 5,
                type = 'range',
                name = "任务物品按钮数量",
                min = 0, max = AB.maxButton, step = 1,
                set = function(info, value) E.db.RhythmBox.AutoButton[info[#info]] = value; AB:UpdateLayout(); AB:Toggle() end,
            },
            QuestPerRow = {
                order = 6,
                type = 'range',
                name = "每行按钮数",
                min = 1, max = AB.maxButton, step = 1,
            },
            QuestSize = {
                order = 7,
                type = 'range',
                name = "尺寸",
                min = 10, max = 100, step = 1,
            },
            Space2 = {
                order = 8,
                type = 'description',
                name = "",
                width = 'full',
            },
            SlotNum = {
                order = 8,
                type = 'range',
                name = "装备按钮数量",
                min = 0, max = AB.maxButton, step = 1,
                set = function(info, value) E.db.RhythmBox.AutoButton[info[#info]] = value; AB:UpdateLayout(); AB:Toggle() end,
            },
            SlotPerRow = {
                order = 9,
                type = 'range',
                name = "每行按钮数",
                min = 1, max = AB.maxButton, step = 1,
            },
            SlotSize = {
                order = 10,
                type = 'range',
                name = "尺寸",
                min = 10, max = 100, step = 1,
            },
        },
    }
end
tinsert(R.Config, AutoButtonOptions)

function AB:Initialize()
    self.buttonPool = {}

    local ABQuestItemAnchor = CreateFrame('Frame', 'ABQuestItemAnchor', _G.UIParent)
    ABQuestItemAnchor:SetClampedToScreen(true)
    ABQuestItemAnchor:Point('BOTTOMLEFT', _G.RightChatPanel or _G.LeftChatPanel, 'TOPLEFT', 0, 4)
    ABQuestItemAnchor:Size(
        E.db.RhythmBox.AutoButton.QuestSize * (E.db.RhythmBox.AutoButton.QuestNum or 1),
        E.db.RhythmBox.AutoButton.QuestSize
    )
    E:CreateMover(
        ABQuestItemAnchor, 'ABQuestItemAnchorMover', "自动任务物品按键", nil, nil, nil, 'ALL,ACTIONBARS',
        function() return E.db.RhythmBox.AutoButton.Enable end
    )
    self.ABQuestItemAnchor = ABQuestItemAnchor

    local ABSlotItemAnchor = CreateFrame('Frame', 'ABSlotItemAnchor', _G.UIParent)
    ABSlotItemAnchor:SetClampedToScreen(true)
    ABSlotItemAnchor:Point('BOTTOMLEFT', _G.RightChatPanel or _G.LeftChatPanel, 'TOPLEFT', 0, 48)
    ABSlotItemAnchor:Size(
        E.db.RhythmBox.AutoButton.SlotSize * (E.db.RhythmBox.AutoButton.SlotNum or 1),
        E.db.RhythmBox.AutoButton.SlotSize
    )
    E:CreateMover(
        ABSlotItemAnchor, 'ABSlotItemAnchorMover', "自动装备饰品按键", nil, nil, nil, 'ALL,ACTIONBARS',
        function() return E.db.RhythmBox.AutoButton.Enable end
    )
    self.ABSlotItemAnchor = ABSlotItemAnchor

    self:UpdateLayout()
    self:Toggle()
end

R:RegisterModule(AB:GetName())
