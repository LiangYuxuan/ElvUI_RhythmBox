local R, E, L, V, P, G = unpack(select(2, ...))
local AB = R:NewModule('AutoButton', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local gsub, ipairs, loadstring, pairs, pcall, select = gsub, ipairs, loadstring, pairs, pcall, select
local setfenv, sort, strmatch, tinsert, type = setfenv, sort, strmatch, tinsert, type
local tonumber, tostring, wipe, unpack = tonumber, tostring, wipe, unpack

-- WoW API / Variables
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_QuestLog_GetNumQuestLogEntries = C_QuestLog.GetNumQuestLogEntries
local C_QuestLog_GetNumQuestWatches = C_QuestLog.GetNumQuestWatches
local C_QuestLog_GetLogIndexForQuestID = C_QuestLog.GetLogIndexForQuestID
local C_QuestLog_GetQuestIDForLogIndex = C_QuestLog.GetQuestIDForLogIndex
local C_QuestLog_GetQuestIDForQuestWatchIndex = C_QuestLog.GetQuestIDForQuestWatchIndex
local C_QuestLog_IsComplete = C_QuestLog.IsComplete
local C_QuestLog_IsWorldQuest = C_QuestLog.IsWorldQuest
local CreateFrame = CreateFrame
local GetBindingKey = GetBindingKey
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerNumSlots = GetContainerNumSlots
local GetInstanceInfo = GetInstanceInfo
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetInventoryItemID = GetInventoryItemID
local GetItemCooldown = GetItemCooldown
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetItemSpell = GetItemSpell
local GetQuestLogSpecialItemCooldown = GetQuestLogSpecialItemCooldown
local GetQuestLogSpecialItemInfo = GetQuestLogSpecialItemInfo
local GetSpecializationInfo = GetSpecializationInfo
local InCombatLockdown = InCombatLockdown
local IsItemInRange = IsItemInRange

local CooldownFrame_Set = CooldownFrame_Set

local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local LE_ITEM_CLASS_QUESTITEM = LE_ITEM_CLASS_QUESTITEM
local LE_UNIT_STAT_STRENGTH = LE_UNIT_STAT_STRENGTH
local LE_UNIT_STAT_AGILITY = LE_UNIT_STAT_AGILITY
local LE_UNIT_STAT_INTELLECT = LE_UNIT_STAT_INTELLECT

AB.blackList = {
    -- Don't use
    [169064] = true, -- Mountebank's Colorful Cloak

    -- Ignore for shorter length
    -- General
    [52252]  = true, -- Tabard of the Lightbringer
    [63379]  = true, -- Baradin's Wardens Tabard
}
AB.whiteList = R.Retail and
{ -- Retail
    -- General
    -- [itemID] = true or 99, -- item sample
    -- Smart
    ['Repair'] = {
        [0] = 'party or raid',
        {49040,  'ready'}, -- Jeeves
        {132514, true}, -- Auto-Hammer
    },
    ['Glider Kit'] = {
        [0] = 'none or pvp or difficultyID == 167',
        {167861, true}, -- Alliance Glider Kit
        {167862, true}, -- Horde Glider Kit
        {109076, true}, -- Goblin Glider Kit
    },
    ['Drum'] = {
        [0] = 'party or raid',
        {164978, 'mylevel <= 50'}, -- Mallet of Thunderous Skins
        {172233, true}, -- Drums of Deathly Ferocity
        {154167, true}, -- Drums of the Maelstrom
        {142406, true}, -- Drums of the Mountain
        {120257, true}, -- Drums of Fury
    },
    ['Flask'] = {
        {147707, 'none or ready', 2}, -- Repurposed Fel Focuser
        {171276, true, 2}, -- Spectral Flask of Power
        {168654, 'strength', 2}, -- Greater Flask of the Undertow
        {152641, 'strength', 2}, -- Flask of the Undertow
        {168651, 'agility', 2}, -- Greater Flask of the Currents
        {152638, 'agility', 2}, -- Flask of the Currents
        {168652, 'intellect', 2}, -- Greater Flask of Endless Fathoms
        {152639, 'intellect', 2}, -- Flask of Endless Fathoms
        {147707, true, 2}, -- Repurposed Fel Focuser (fallback)
    },
    ['Rune'] = {
        {174906, 'mylevel < 60'}, -- Lightning-Forged Augment Rune
        {153023, 'mylevel < 50'}, -- Lightforged Augment Rune
    },
    ['Invisibility Potion'] = {
        [0] = 'party',
        {171266, true}, -- Potion of the Hidden Spirit
        {152496, 'mylevel <= 50'}, -- Demitri's Draught of Deception
        {127840, 'mylevel <  50'}, -- Skaggldrynk
        {116268, 'mylevel <  50'}, -- Draenic Invisibility Potion
    },
    ['Phantasma'] = {
        {184652, 'difficultyID == 167', 3}, -- Phantasmic Infuser
    },

    -- Legion
    [142117] = true, -- Potion of Prolonged Power
} or
{ -- Classic
    -- Empty
}

-- change binding xml when changing this
AB.maxButton = 12
AB.buttonTypes = {
    ['Quest'] = "自动任务物品按键",
    ['Slot'] = "自动装备饰品按键",
}
AB.buttonTypesOrder = {'Quest', 'Slot'}

-- Binding Variables
for buttonType, buttonName in pairs(AB.buttonTypes) do
    _G['BINDING_HEADER_Auto'.. buttonType .. 'Button'] = buttonName
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
    if self.questLogIndex and self.questLogIndex > 0 then
        start, duration, enable = GetQuestLogSpecialItemCooldown(self.questLogIndex)
    elseif self.slotID then
        start, duration, enable = GetInventoryItemCooldown('player', self.slotID)
    else
        start, duration, enable = GetItemCooldown(self.itemID)
    end

    CooldownFrame_Set(self.cooldown, start, duration, enable)

    if duration and enable and duration > 0 and enable == 0 then
        self.icon:SetVertexColor(.4, .4, .4)
    elseif not self.slotID and IsItemInRange(self.itemID, 'target') == 0 then
        self.icon:SetVertexColor(.8, .1, .1)
    else
        self.icon:SetVertexColor(1, 1, 1)
    end
end

function AB:BuildEnv()
    local _, instanceType, difficultyID, _, maxPlayers, _, _, instanceID = GetInstanceInfo()
    local specID, _, _, _, role, primaryStat = GetSpecializationInfo(E.myspec)

    local env = {
        -- ElvUI Constants
        myfaction = E.myfaction,
        mylevel   = E.mylevel,
        myclass   = E.myclass,
        myClassID = E.myClassID,
        myrace    = E.myrace,
        myname    = E.myname,
        myrealm   = E.myrealm,
        myspec    = E.myspec,

        -- Specialization Info
        specID      = specID,
        role        = role,
        primaryStat = primaryStat,

        -- Instance Info
        instanceType = instanceType,
        difficultyID = difficultyID,
        maxPlayers   = maxPlayers,
        instanceID   = instanceID,

        -- Zone Info
        uiMapID = E.MapInfo.mapID or C_Map_GetBestMapForUnit('player'),
    }

    env.tank      = role == 'TANK'
    env.healer    = role == 'HEALER'
    env.damager   = role == 'DAMAGER'
    env.strength  = primaryStat == LE_UNIT_STAT_STRENGTH
    env.agility   = primaryStat == LE_UNIT_STAT_AGILITY
    env.intellect = primaryStat == LE_UNIT_STAT_INTELLECT

    env.none     = instanceType == 'none'
    env.pvp      = instanceType == 'pvp'
    env.arena    = instanceType == 'arena'
    env.party    = instanceType == 'party'
    env.raid     = instanceType == 'raid'
    env.scenario = instanceType == 'scenario'

    return env
end

do
    local funcCache = {}
    function AB:CheckCondition(env, exp, itemID)
        if itemID then
            local itemCount = GetItemCount(itemID)
            if not itemCount or itemCount == 0 then return end
            env.itemCount = itemCount

            local _, duration, enable = GetItemCooldown(itemID)
            env.ready = duration == 0 and enable == 1
        end

        if exp == true or exp == 'true' then return true end

        local err
        local func = funcCache[exp]
        if not func then
            func, err = loadstring('return ' .. exp)
            if err then
                R.ErrorHandler(err)
                return
            end
            funcCache[exp] = func
        end
        setfenv(func, env)
        local status, result = pcall(func)
        if status then
            if type(result) == 'boolean' then
                return result
            else
                R.ErrorHandler("Error in Rhythm Box AutoButton Smart Condition: Did not evaluate to boolean, but to '" .. tostring(result) .. "' of type " .. type(result))
            end
        else
            R.ErrorHandler("Error in Rhythm Box AutoButton Smart Condition: " .. result)
        end
    end
end

function AB:UpdateItem()
    wipe(self.items)
    wipe(self.itemPriorities)

    local smartEnv = self:BuildEnv()
    for key, value in pairs(self.whiteList) do
        local itemID, priority = key, value
        if type(key) ~= 'number' then
            if type(value) == 'function' then
                itemID, priority = value()
            elseif type(value) == 'table' then
                if value[0] then
                    priority = self:CheckCondition(smartEnv, value[0])
                end
                if priority then
                    for _, data in ipairs(value) do
                        local smartItemID, exp, smartPriority = unpack(data)
                        priority = self:CheckCondition(smartEnv, exp, smartItemID)
                        if priority then
                            itemID = smartItemID
                            if smartPriority then
                                priority = smartPriority
                            end
                            break
                        end
                    end
                end
            else
                R.ErrorHandler("Error in Rhythm Box AutoButton Smart Item: " .. key)
                priority = nil
            end
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

    if R.Classic then
        -- Update Quest Item (Classic Fallback)
        wipe(self.questItems)

        for bagID = 0, NUM_BAG_SLOTS do
            for slot = 1, GetContainerNumSlots(bagID) do
                local itemID = select(10, GetContainerItemInfo(bagID, slot))
                if itemID then
                    local itemClassID = select(12, GetItemInfo(itemID))
                    if itemClassID == LE_ITEM_CLASS_QUESTITEM and GetItemSpell(itemID) then
                        self.questItems[itemID] = -1 -- fake quest log index
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
    local numEntries = C_QuestLog_GetNumQuestLogEntries()
    for questLogIndex = 1, numEntries do
        local questID = C_QuestLog_GetQuestIDForLogIndex(questLogIndex)
        if questID and C_QuestLog_IsWorldQuest(questID) then
            local itemLink = GetQuestLogSpecialItemInfo(questLogIndex)
            if itemLink then
                local itemID = tonumber(strmatch(itemLink, ':(%d+):'))
                self.questItems[itemID] = questLogIndex
            end
        end
    end

    -- update normal quest item
    for i = 1, C_QuestLog_GetNumQuestWatches() do
        local questID = C_QuestLog_GetQuestIDForQuestWatchIndex(i)
        local questLogIndex = questID and C_QuestLog_GetLogIndexForQuestID(questID)
        if questLogIndex then
            local isComplete = C_QuestLog_IsComplete(questID)
            local itemLink, _, _, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
            if itemLink and (showItemWhenComplete or not isComplete) then
                local itemID = tonumber(strmatch(itemLink, ':(%d+):'))
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
    sort(pending, itemCompare)

    for itemID in pairs(self.questItems) do
        tinsert(pending, 1, itemID)
    end

    for i = 1, E.db.RhythmBox.AutoButton.QuestNum do
        local itemID = pending[i]
        if not itemID then break end

        local _, _, rarity, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
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
        button:SetAttribute('item', 'item:' .. itemID)
        button:Show()
    end

    for i = 1, E.db.RhythmBox.AutoButton.SlotNum do
        local tbl = self.inventory[i]
        if not tbl then break end

        local button = self.buttonPool.Slot[i]
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

function AB:HideBar()
    for buttonType in pairs(self.buttonTypes) do
        for i = 1, self.maxButton do
            local button = self.buttonPool[buttonType] and self.buttonPool[buttonType][i]
            if not button then break end
            button:Hide()
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
            self:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', 'UpdateInventory')
        end

        if E.db.RhythmBox.AutoButton.QuestNum > 0 then
            self:RegisterEvent('BAG_UPDATE_DELAYED', 'UpdateItem')
            self:RegisterEvent('BAG_UPDATE_COOLDOWN', 'UpdateItem')

            self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'UpdateItem')

            if R.Retail then
                self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', 'UpdateItem')

                self:RegisterEvent('QUEST_LOG_UPDATE', 'UpdateQuestItem')
                self:RegisterEvent('QUEST_WATCH_LIST_CHANGED', 'UpdateQuestItem')
                self:RegisterEvent('QUEST_ACCEPTED', 'UpdateQuestItem')
                self:RegisterEvent('QUEST_TURNED_IN', 'UpdateQuestItem')
            end
        end

        self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateAutoButton')

        self:RegisterEvent('UPDATE_BINDINGS')
        self:RegisterEvent('BAG_UPDATE', 'UpdateItemCount')

        self.firstCalling = true
        if E.db.RhythmBox.AutoButton.SlotNum > 0 then
            self:UpdateInventory()
        end
        if E.db.RhythmBox.AutoButton.QuestNum > 0 then
            self:UpdateItem()

            if R.Retail then
                self:UpdateQuestItem()
            end
        end
        self.firstCalling = nil

        self.requireUpdate = nil
        self:UpdateAutoButton()
        self:UPDATE_BINDINGS()
    else
        self:HideBar()
    end
end

function AB:CreateButton(buttonType, index)
    local buttonSize = E.db.RhythmBox.AutoButton[buttonType .. 'Size']

    if not self.buttonPool[buttonType] then self.buttonPool[buttonType] = {} end

    local button = self.buttonPool[buttonType][index]
    if not button then
        local buttonName = 'Auto' .. buttonType .. 'Button' .. index

        -- Create Button
        button = CreateFrame('Button', buttonName, E.UIParent, 'SecureActionButtonTemplate, BackdropTemplate')
        button:Hide()
        button:SetParent(self.anchors[buttonType])
        button:SetScript('OnEnter', ButtonOnEnter)
        button:SetScript('OnLeave', ButtonOnLeave)
        button:SetScript('OnUpdate', ButtonOnUpdate)

        button:SetTemplate('Default')
        button:StyleButton()
        button:EnableMouse(true)
        button:RegisterForClicks('AnyUp')

        -- Icon
        button.icon = button:CreateTexture(nil, 'OVERLAY')
        button.icon:SetInside(button, 2, 2)
        button.icon:SetTexCoord(.1, .9, .1, .9)

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
        button.cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
        button.cooldown:SetInside(button, 2, 2)
        button.cooldown:SetDrawEdge(false)
        button.cooldown.CooldownOverride = 'actionbar'

        E:RegisterCooldown(button.cooldown)
        E:RegisterPetBattleHideFrames(button, E.UIParent)

        self.buttonPool[buttonType][index] = button
    end

    button:SetSize(buttonSize, buttonSize)
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
            button:ClearAllPoints()
            if i == 1 then -- first button
                button:SetPoint('LEFT', button:GetParent())
            elseif (i - 1) % buttonPerRow == 0 then -- first button in a row
                button:SetPoint('TOP', self.buttonPool[buttonType][i - buttonPerRow], 'BOTTOM', 0, -3)
            else
                button:SetPoint('LEFT', self.buttonPool[buttonType][i - 1], 'RIGHT', 3, 0)
            end
        end
    end
end

P["RhythmBox"]["AutoButton"] = {
    ["Enable"] = true,
    ["QuestNum"] = 7,
    ["QuestPerRow"] = 7,
    ["QuestSize"] = 40,
    ["SlotNum"] = 7,
    ["SlotPerRow"] = 7,
    ["SlotSize"] = 40,
    ["CountFontSize"] = 18,
    ["BindFontSize"] = 18,
}

local function AutoButtonOptions()
    E.Options.args.RhythmBox.args.AutoButton = {
        order = 11,
        type = 'group',
        name = "自动按键条",
        get = function(info) return E.db.RhythmBox.AutoButton[info[#info]] end,
        set = function(info, value) E.db.RhythmBox.AutoButton[info[#info]] = value; AB:UpdateLayout() end,
        args = {
            Enable = {
                order = 1,
                type = 'toggle',
                name = "启用",
                set = function(info, value) E.db.RhythmBox.AutoButton[info[#info]] = value; AB:Toggle() end,
            },
            Space = {
                order = 10,
                type = 'description',
                name = "",
                width = 'full',
            },
            BindFontSize = {
                order = 11,
                type = 'range',
                min = 4, max = 40, step = 1,
                name = "键位文字字体尺寸",
            },
            CountFontSize = {
                order = 12,
                type = "range",
                min = 4, max = 40, step =1,
                name = "物品数量字体尺寸",
            },
            GroupQuestItem = {
                order = 20,
                type = 'group',
                name = "任务物品按钮",
                guiInline = true,
                args = {
                    QuestNum = {
                        order = 21,
                        type = 'range',
                        name = "按钮数量",
                        min = 0, max = AB.maxButton, step = 1,
                        set = function(info, value) E.db.RhythmBox.AutoButton[info[#info]] = value; AB:UpdateLayout(); AB:Toggle() end,
                    },
                    QuestPerRow = {
                        order = 22,
                        type = 'range',
                        name = "每行按钮数",
                        min = 1, max = AB.maxButton, step = 1,
                    },
                    QuestSize = {
                        order = 23,
                        type = 'range',
                        name = "尺寸",
                        min = 10, max = 100, step = 1,
                    },
                },
            },
            GroupSlot = {
                order = 20,
                type = 'group',
                name = "装备按钮",
                guiInline = true,
                args = {
                    SlotNum = {
                        order = 31,
                        type = 'range',
                        name = "按钮数量",
                        min = 0, max = AB.maxButton, step = 1,
                        set = function(info, value) E.db.RhythmBox.AutoButton[info[#info]] = value; AB:UpdateLayout(); AB:Toggle() end,
                    },
                    SlotPerRow = {
                        order = 32,
                        type = 'range',
                        name = "每行按钮数",
                        min = 1, max = AB.maxButton, step = 1,
                    },
                    SlotSize = {
                        order = 33,
                        type = 'range',
                        name = "尺寸",
                        min = 10, max = 100, step = 1,
                    },
                },
            },
        },
    }
end
tinsert(R.Config, AutoButtonOptions)

function AB:Initialize()
    self.buttonPool = {}
    self.anchors = {}

    local enableFunc = function() return E.db.RhythmBox.AutoButton.Enable end
    local chatPanel = _G.RightChatPanel or _G.LeftChatPanel
    local yOffset = 4
    for _, buttonType in ipairs(self.buttonTypesOrder) do
        local buttonName = self.buttonTypes[buttonType]
        local anchorName = 'AB' .. buttonType .. 'ItemAnchor'
        local buttonSize = E.db.RhythmBox.AutoButton[buttonType .. 'Size']

        local frame = CreateFrame('Frame', anchorName, _G.UIParent)
        frame:SetClampedToScreen(true)
        frame:SetPoint('BOTTOMLEFT', chatPanel, 'TOPLEFT', 0, yOffset)
        frame:SetSize(buttonSize * (E.db.RhythmBox.AutoButton[buttonType .. 'Num'] or 1), buttonSize)
        E:CreateMover(frame, anchorName .. 'Mover', buttonName, nil, nil, nil, 'ALL,ACTIONBARS,RHYTHMBOX', enableFunc)
        self.anchors[buttonType] = frame

        yOffset = yOffset + buttonSize + 4
    end

    self:UpdateLayout()
    self:ScheduleTimer('Toggle', 2) -- Delay for loading
end

R:RegisterModule(AB:GetName())
