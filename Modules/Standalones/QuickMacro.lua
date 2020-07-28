local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local QM = R:NewModule('QuickMacro', 'AceEvent-3.0', 'AceTimer-3.0')
local LSR = E.Libs.SpellRange

-- Lua functions
local _G = _G
local format, gsub, ipairs, pairs, tinsert, select = format, gsub, ipairs, pairs, tinsert, select
local sort, random, wipe, unpack = sort, random, wipe, unpack

-- WoW API / Variables
local C_ChallengeMode_GetActiveKeystoneInfo = C_ChallengeMode.GetActiveKeystoneInfo
local C_LFGList_GetActivityInfo = C_LFGList.GetActivityInfo
local C_LFGList_GetActiveEntryInfo = C_LFGList.GetActiveEntryInfo
local C_MountJournal_GetMountInfoByID = C_MountJournal.GetMountInfoByID
local CreateFrame = CreateFrame
local GetBindingKey = GetBindingKey
local GetItemCooldown = GetItemCooldown
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetNumGroupMembers = GetNumGroupMembers
local GetNumShapeshiftForms = GetNumShapeshiftForms
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local GetSpellCooldown = GetSpellCooldown
local InCombatLockdown = InCombatLockdown
local IsAltKeyDown = IsAltKeyDown
local IsAddOnLoaded = IsAddOnLoaded
local IsEveryoneAssistant = IsEveryoneAssistant
local IsInRaid = IsInRaid
local IsItemInRange = IsItemInRange
local IsResting = IsResting
local IsUsableSpell = IsUsableSpell
local PlayerHasToy = PlayerHasToy
local SendChatMessage = SendChatMessage
local SecureCmdOptionParse = SecureCmdOptionParse
local UnitIsGroupAssistant = UnitIsGroupAssistant
local UnitIsGroupLeader = UnitIsGroupLeader

local CooldownFrame_Set = CooldownFrame_Set
local Item = Item
local tContains = tContains

local function ItemListUpdateFunc(button)
    local itemList = button.data.itemList
    if not itemList.macroTemplate then
        itemList = itemList[E.myrole]
    end
    if not itemList then return end

    button.itemCache = wipe(button.itemCache or {})
    for index, slotList in ipairs(itemList) do
        for _, itemID in ipairs(slotList) do
            local itemCount = GetItemCount(itemID)
            if itemCount and itemCount > 0 then
                button.itemCache[index] = itemID
                break
            end
        end
        if not button.itemCache[index] then
            button.itemCache[index] = slotList[0] or slotList[1]
        end
    end

    local macroText = format(itemList.macroTemplate, unpack(button.itemCache))
    local itemText = format(itemList.itemTemplate, unpack(button.itemCache))

    button.itemText = itemText
    return macroText
end

local function ItemDisplayFunc(button)
    local itemID = button and button.itemText and SecureCmdOptionParse(button.itemText)
    if not itemID then
        button.displayType = nil
        button.itemID = nil

        button:SetBackdropBorderColor(0, 0, 0)
        button.icon:SetTexture(134400) -- INV_Misc_QuestionMark
        button.count:SetText("")
    else
        button.displayType = 'item'
        button.itemID = itemID

        local itemCount = GetItemCount(itemID, nil, true) or 0
        button.count:SetText(itemCount)

        local _, _, rarity, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
        if itemIcon then
            local r, g, b = GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)

            button:SetBackdropBorderColor(r, g, b)
            button.icon:SetTexture(itemIcon)
        else
            local item = Item:CreateFromItemID(tonumber(itemID))
            item:ContinueOnItemLoad(function()
                local itemID = item:GetItemID()
                local _, _, rarity, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
                local r, g, b = GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)

                button:SetBackdropBorderColor(r, g, b)
                button.icon:SetTexture(itemIcon)
            end)
        end
    end
end

QM.MacroButtons = {
    RandomHearthstone = {
        name = "随机炉石",
        index = 2,
        outCombat = true,
        inCombat = false,

        updateEvent = {
            ['PLAYER_ENTERING_WORLD'] = true,
            ['NEW_TOY_ADDED'] = true,
        },
        updateFunc = function(button)
            local macroText = ''
            local itemText = ''

            local hasDalaran  = GetItemCount(140192)
            local hasGarrison = GetItemCount(110560)
            local hasWhistle  = GetItemCount(141605)
            if (
                (hasDalaran  and hasDalaran  > 0) or
                (hasGarrison and hasGarrison > 0) or
                (hasWhistle  and hasWhistle  > 0)
            ) then
                macroText = '/use '
                local prevFound
                if hasDalaran > 0 then
                    macroText = macroText .. '[mod:shift]item:140192'
                    itemText = itemText .. '[mod:shift]140192;'
                    prevFound = true
                end
                if hasGarrison > 0 then
                    macroText = macroText .. (prevFound and ';' or '') .. '[mod:ctrl]item:110560'
                    itemText = itemText .. '[mod:ctrl]110560;'
                    prevFound = true
                end
                if hasWhistle > 0 then
                    macroText = macroText .. (prevFound and ';' or '') .. '[mod:alt]item:141605'
                    itemText = itemText .. '[mod:alt]141605;'
                end
                macroText = macroText .. '\n'
            end

            local hsItemName, hsItemID
            local list = {}
            for _, itemID in ipairs(button.data.hearthstoneList) do
                if E.db.RhythmBox.QuickMacro.Hearthstone[itemID] and PlayerHasToy(itemID) and GetItemInfo(itemID) then
                    tinsert(list, itemID)
                end
            end
            if #list > 0 then
                hsItemID = list[random(#list)]
                hsItemName = GetItemInfo(hsItemID)
            else
                hsItemID = '6948'
                hsItemName = 'item:6948'
            end

            macroText = macroText .. '/cast ' .. hsItemName
            itemText = itemText .. hsItemID

            button.itemText = itemText
            button.count:Hide()
            return macroText
        end,
        displayFunc = ItemDisplayFunc,

        hearthstoneList = {
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
        },
    },
    RandomMount = {
        name = "随机坐骑",
        index = 1,
        outCombat = true,
        inCombat = false,

        updateEvent = {
            ['PLAYER_ENTERING_WORLD'] = true,
            ['PLAYER_SPECIALIZATION_CHANGED'] = true,
            ['CHALLENGE_MODE_START'] = true,
            ['CHALLENGE_MODE_COMPLETED'] = true,
        },
        updateFunc = function(button)
            local macroText = ''
            local mountText = ''

            if IsAddOnLoaded('OPie') then
                macroText = macroText .. '/click [mod:shift]ORLOpen x1\n'
                macroText = macroText .. '/stopmacro [mod:shift]\n'
            end

            if E.myclass == 'DRUID' then
                local moonkin
                for i = 1, GetNumShapeshiftForms() do
                    local spellID = select(4, GetShapeshiftFormInfo(i))
                    if spellID == 24858 then -- Moonkin Form
                        moonkin = i
                        break
                    end
                end

                macroText = macroText .. '/cancelform [nomounted,nocombat,outdoors' ..
                    (moonkin and (',noform:' .. moonkin) or '') .. ']\n'
            end

            local broomItemCount = GetItemCount(37011) -- Magic Broom
            if broomItemCount and broomItemCount > 0 then
                macroText = macroText .. '/use [nomod]item:37011\n'
                macroText = macroText .. '/stopmacro [nomod]\n'
            end

            local isCollectedRocket = select(11, C_MountJournal_GetMountInfoByID(382)) -- X-53 Touring Rocket
            local isCollectedYak = select(11, C_MountJournal_GetMountInfoByID(460)) -- Grand Expedition Yak
            if isCollectedRocket then
                mountText = mountText .. '[mod:ctrl]382;'
            end
            if isCollectedYak then
                mountText = mountText .. '[mod:alt]460;'
            end
            local affixes = select(2, C_ChallengeMode_GetActiveKeystoneInfo())
            if affixes and tContains(affixes, 11) and select(11, C_MountJournal_GetMountInfoByID(547)) then -- Hearthsteed
                mountText = mountText .. '547'
            else
                mountText = mountText .. '0'
            end

            macroText = macroText ..
                '/run if not IsModifierKeyDown() and IsMounted() then C_MountJournal.Dismiss() else C_MountJournal.SummonByID(SecureCmdOptionParse("' ..
                mountText .. '")) end'

            button.mountText = mountText
            button.count:Hide()
            return macroText
        end,
        displayFunc = function(button)
            if not button.mountText then return end

            button:SetBackdropBorderColor(0, 112 / 255, 221 / 255)
            if IsShiftKeyDown() and IsAddOnLoaded('OPie') then
                button.displayType = nil
                button.spellID = nil

                button.icon:SetTexture('Interface\\AddOns\\OPie\\gfx\\opie_ring_icon')
                return
            end

            local mountID = SecureCmdOptionParse(button.mountText)
            local spellID, iconID
            if mountID == '0' then
                spellID = 150544
                iconID = 853211
            else
                spellID, iconID = select(2, C_MountJournal_GetMountInfoByID(mountID))
            end
            button.displayType = 'mount'
            button.spellID = spellID

            button.icon:SetTexture(iconID)
        end,
    },
    RestoreHealth = {
        name = "回血保命",
        index = 3,
        outCombat = true,
        inCombat = true,

        updateEvent = {
            ['BAG_UPDATE_DELAYED'] = true,
        },
        updateFunc = ItemListUpdateFunc,
        displayFunc = ItemDisplayFunc,

        itemList = {
            [1] = {
                169451, -- Abyssal Healing Potion
                156634, -- Silas' Vial of Continuous Curing
                166799, -- Emerald of Vigor
                152494, -- Coastal Healing Potion
            },
            [2] = {
                5512,   -- Healthstone
                169451, -- Abyssal Healing Potion
                156634, -- Silas' Vial of Continuous Curing
                166799, -- Emerald of Vigor
                152494, -- Coastal Healing Potion
            },
            macroTemplate = "/use [mod:ctrl]item:%s; item:%s",
            itemTemplate = "[mod:ctrl]%s; %s",
        },
    },
    CombatPotion = {
        name = "战斗药水",
        index = 4,
        outCombat = true,
        inCombat = true,

        updateEvent = {
            ['BAG_UPDATE_DELAYED'] = true,
            ['PLAYER_SPECIALIZATION_CHANGED'] = true,
        },
        updateFunc = ItemListUpdateFunc,
        displayFunc = ItemDisplayFunc,

        itemList = {
            ['HEALER'] = {
                [1] = {
                    152561, -- Potion of Replenishment
                },
                [2] = {
                    152495, -- Coastal Mana Potion
                },
                [3] = {
                    113509, -- Conjured Mana Bun
                    159867, -- Rockskip Mineral Water
                    163784, -- Seafoam Coconut Water
                    163692, -- Scroll of Subsistence
                },
                macroTemplate = "/use [combat, mod:ctrl]item:%s; [combat]item:%s; item:%s",
                itemTemplate = "[combat, mod:ctrl]%s; [combat]%s; %s",
            },
            ['TANK'] = {
                [1] = {
                    168501, -- Superior Steelskin Potion
                    152557, -- Steelskin Potion
                    163082, -- Coastal Rejuvenation Potion
                },
                [2] = {
                    168500, -- Superior Battle Potion of Strength
                    163224, -- Battle Potion of Strength
                    166801, -- Sapphire of Brilliance
                    142117, -- Potion of Prolonged Power
                },
                [3] = {
                    113509, -- Conjured Mana Bun
                },
                macroTemplate = "/use [combat, mod:ctrl]item:%s; [combat]item:%s; item:%s",
                itemTemplate = "[combat, mod:ctrl]%s; [combat]%s; %s",
            },
            ['DAMAGER'] = {
                [1] = {
                    169299, -- Potion of Unbridled Fury
                    166801, -- Sapphire of Brilliance
                    142117, -- Potion of Prolonged Power
                },
                [2] = {
                    113509, -- Conjured Mana Bun
                },
                macroTemplate = "/use [combat]item:%s; item:%s",
                itemTemplate = "[combat]%s; %s",
            },
        },
    },
    SpeedPotion = {
        name = "加速药水",
        index = 5,
        outCombat = true,
        inCombat = true,

        updateEvent = {
            ['BAG_UPDATE_DELAYED'] = true,
        },
        updateFunc = ItemListUpdateFunc,
        displayFunc = ItemDisplayFunc,

        itemList = {
            [1] = {
                152497, -- Lightfoot Potion
                127841, -- Skystep Potion
                2459,   -- Swiftness Potion
            },
            macroTemplate = "/use item:%s",
            itemTemplate = "%s",
        },
    },
    SendYYCode = {
        name = "YY频道号发送",
        index = 6,
        outCombat = true,
        inCombat = false,

        updateEvent = {
            ['LFG_LIST_ACTIVE_ENTRY_UPDATE'] = true,
        },
        updateFunc = function(button)
            if UnitIsGroupLeader('player') or (UnitIsGroupAssistant('player') and not IsEveryoneAssistant()) then
                local entryData = C_LFGList_GetActiveEntryInfo()
                if entryData then
                    local categoryID = select(3, C_LFGList_GetActivityInfo(entryData.activityID))
                    if categoryID == 3 then -- BfA Raid
                        button:SetScript('OnClick', button.data.onClickFunc)
                        return ''
                    end
                end
            end

            button:SetScript('OnClick', nil)
        end,
        displayFunc = function(button)
            button.displayType = nil

            button:SetBackdropBorderColor(0, 112 / 255, 221 / 255)
            button.icon:SetTexture(132161)
        end,

        onClickFunc = function()
            if IsInRaid() then
                SendChatMessage('YY 1453607973', 'RAID')
            elseif GetNumGroupMembers() > 0 then
                SendChatMessage('YY 1453607973', 'PARTY')
            end
        end,
    },
    FetchLockout = {
        name = "CD号申请加入队列",
        index = 7,
        outCombat = true,
        inCombat = false,

        updateEvent = {
            ['PLAYER_ENTERING_WORLD'] = true,
            ['PLAYER_UPDATE_RESTING'] = true,
        },
        updateFunc = function(button)
            if IsResting() and GetNumGroupMembers() == 0 then
                button:SetScript('OnClick', button.data.onClickFunc)
                return ''
            end

            button:SetScript('OnClick', nil)
        end,
        displayFunc = function(button)
            button.displayType = nil

            button:SetBackdropBorderColor(0, 112 / 255, 221 / 255)
            button.icon:SetTexture(413580)
        end,

        onClickFunc = function()
            SendChatMessage('123', 'WHISPER', nil, '小只小猎手-拉文凯斯')
        end,
    },
}

_G['BINDING_HEADER_RhythmBoxQuickMacro'] = "Rhythm Box 快速宏动作条"
for buttonName, data in pairs(QM.MacroButtons) do
    _G['BINDING_NAME_CLICK RhythmBoxQM' .. buttonName .. ':LeftButton'] = data.name
end

local function ButtonOnEnter(self)
    _G.GameTooltip:Hide()
    _G.GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 0, -2)
    _G.GameTooltip:ClearLines()

    if not self.displayType then
        _G.GameTooltip:AddLine(self.data.name)
    elseif self.displayType == 'item' then
        _G.GameTooltip:SetItemByID(self.itemID)
    elseif self.displayType == 'spell' then
        _G.GameTooltip:SetSpellByID(self.spellID)
    elseif self.displayType == 'mount' then
        _G.GameTooltip:SetMountBySpellID(self.spellID)
    end

    _G.GameTooltip:Show()
end

local function ButtonOnLeave(self)
    _G.GameTooltip:Hide()
end

local function ButtonOnUpdate(self)
    if not self.displayType then return end

    if self.displayType == 'item' or self.displayType == 'spell' then
        local start, duration, enable
        if self.displayType == 'item' then
            start, duration, enable = GetItemCooldown(self.itemID)
        elseif self.displayType == 'spell' then
            start, duration, enable = GetSpellCooldown(self.spellID)
        end

        CooldownFrame_Set(self.cooldown, start, duration, enable)

        if duration and enable and duration > 0 and enable == 0 then
            self.icon:SetVertexColor(.4, .4, .4)
            return
        end
    end

    if self.displayType == 'item' and IsItemInRange(self.itemID, 'target') == 0 then
        self.icon:SetVertexColor(.8, .1, .1)
    elseif self.displayType == 'spell' or self.displayType == 'mount' then
        local inRange = LSR.IsSpellInRange(self.spellID, 'target')
        local usable, noMana = IsUsableSpell(self.spellID)
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

do
    local function buttonSort(left, right)
        return (QM.MacroButtons[left].index or 0) < (QM.MacroButtons[right].index or 0)
    end
    local pendingButton = {}

    function QM:UpdateButton(event)
        if not event then
            -- manual call from :Toggle, or option
            event = 'PLAYER_REGEN_ENABLED'
        elseif InCombatLockdown() then
            return
        end

        wipe(pendingButton)
        local positionUpdate
        local combatCheck = event == 'PLAYER_REGEN_DISABLED' and 'inCombat' or 'outCombat'
        for buttonName, button in pairs(self.buttons) do
            local isShown = button:IsShown()
            if button.data[combatCheck] then
                local macroText = button.macroText
                if (
                    event == 'PLAYER_REGEN_DISABLED' or event == 'PLAYER_REGEN_ENABLED' or
                    button.data.updateEvent[event]
                ) then
                    macroText = button.data.updateFunc(button)
                    button.macroText = macroText
                    button:SetAttribute('type', 'macro')
                    button:SetAttribute('macrotext', macroText)
                end

                if macroText then
                    if not isShown then
                        positionUpdate = true
                    end
                    tinsert(pendingButton, buttonName)
                    button:Show()
                elseif isShown then
                    positionUpdate = true
                    button:Hide()
                end
            elseif isShown then
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
    for _, button in pairs(self.buttons) do
        if button:IsShown() and button.data.displayFunc then
            button.data.displayFunc(button)
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
            local itemCount = GetItemCount(button.itemID, nil, true) or 0
            button.count:SetText(itemCount)
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

function QM:UpdateButtonLayout(buttonName)
    local button = self.buttons[buttonName]
    if not button then
        -- Create Button
        button = CreateFrame('Button', 'RhythmBoxQM' .. buttonName, self.container, 'SecureActionButtonTemplate')
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
        E.FrameLocks[buttonName] = true

        self.buttons[buttonName] = button
    end

    button:Size(E.db.RhythmBox.QuickMacro.ButtonSize)
    button.bind:FontTemplate(nil, E.db.RhythmBox.QuickMacro.BindFontSize, 'OUTLINE')
    button.count:FontTemplate(nil, E.db.RhythmBox.QuickMacro.CountFontSize, 'OUTLINE')
    return button
end

function QM:UpdateLayout()
    for buttonName, buttonData in pairs(self.MacroButtons) do
        local button = self:UpdateButtonLayout(buttonName)
        button.data = buttonData
    end
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

local function QuickMacroOptions()
    local buttonLength = 0
    for _ in pairs(QM.MacroButtons) do
        buttonLength = buttonLength + 1
    end

    E.Options.args.RhythmBox.args.QuickMacro = {
        order = 23,
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
        local itemName = GetItemInfo(itemID)
        if itemName then
            E.Options.args.RhythmBox.args.QuickMacro.args.HearthstoneList.values[itemID] = itemName
        else
            E.Options.args.RhythmBox.args.QuickMacro.args.HearthstoneList.values[itemID] = itemID

            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(function()
                local itemID = item:GetItemID()
                local itemName = GetItemInfo(itemID)
                E.Options.args.RhythmBox.args.QuickMacro.args.HearthstoneList.values[itemID] = itemName
            end)
        end
    end
end
tinsert(R.Config, QuickMacroOptions)

function QM:Initialize()
    self.buttons = {}

    local buttonLength = 0
    for _ in pairs(self.MacroButtons) do
        buttonLength = buttonLength + 1
    end

    local frameName = 'RhythmBoxQuickMacroContainer'
    self.container = CreateFrame('Frame', frameName, E.UIParent)
    self.container:ClearAllPoints()
    self.container:SetPoint('BOTTOMLEFT', _G.RightChatPanel or _G.LeftChatPanel, 'TOPLEFT', 0, -40)
    self.container:SetSize(7 * E.db.RhythmBox.QuickMacro.ButtonSize, E.db.RhythmBox.QuickMacro.ButtonSize)
    E:CreateMover(self.container, frameName .. 'Mover', "RhythmBox 快速宏动作条", nil, nil, nil, 'ALL,RHYTHMBOX')

    self:UpdateLayout()
    self:Toggle()
end

R:RegisterModule(QM:GetName())
