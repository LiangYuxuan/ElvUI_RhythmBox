local R, E, L, V, P, G = unpack(select(2, ...))
local QM = R:NewModule('QuickMacro', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local format, gsub, ipairs, pairs, tinsert, tonumber = format, gsub, ipairs, pairs, tinsert, tonumber
local select, sort, random, wipe, unpack = select, sort, random, wipe, unpack

-- WoW API / Variables
local BNGetInfo = BNGetInfo
local C_BattleNet_GetAccountInfoByID = C_BattleNet.GetAccountInfoByID
local C_LFGList_GetActivityInfoTable = C_LFGList.GetActivityInfoTable
local C_LFGList_GetActiveEntryInfo = C_LFGList.GetActiveEntryInfo
local C_Map_GetAreaInfo = C_Map.GetAreaInfo
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_Map_GetMapInfo = C_Map.GetMapInfo
local C_MountJournal_GetMountInfoByID = C_MountJournal.GetMountInfoByID
local C_PartyInfo_InviteUnit = C_PartyInfo.InviteUnit
local C_TradeSkillUI_GetItemReagentQualityByItemInfo = C_TradeSkillUI.GetItemReagentQualityByItemInfo
local C_TradeSkillUI_GetItemCraftedQualityByItemInfo = C_TradeSkillUI.GetItemCraftedQualityByItemInfo
local CreateFrame = CreateFrame
local GetBindingKey = GetBindingKey
local GetInventoryItemID = GetInventoryItemID
local GetItemCooldown = GetItemCooldown
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetNumGroupMembers = GetNumGroupMembers
local GetNumShapeshiftForms = GetNumShapeshiftForms
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local InCombatLockdown = InCombatLockdown
local IsAddOnLoaded = IsAddOnLoaded
local IsEveryoneAssistant = IsEveryoneAssistant
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local IsItemInRange = IsItemInRange
local IsModifierKeyDown = IsModifierKeyDown
local IsPlayerSpell = IsPlayerSpell
local IsShiftKeyDown = IsShiftKeyDown
local IsSpellInRange = IsSpellInRange
local IsUsableSpell = IsUsableSpell
local PlayerHasToy = PlayerHasToy
local SendChatMessage = SendChatMessage
local SecureCmdOptionParse = SecureCmdOptionParse
local UnitIsGroupAssistant = UnitIsGroupAssistant
local UnitIsGroupLeader = UnitIsGroupLeader

local CooldownFrame_Set = CooldownFrame_Set
local Item = Item
local RegisterStateDriver = RegisterStateDriver

local Enum_ItemWeaponSubclass_Guns = Enum.ItemWeaponSubclass.Guns
local Enum_ItemWeaponSubclass_Mace1H = Enum.ItemWeaponSubclass.Mace1H
local Enum_ItemWeaponSubclass_Mace2H = Enum.ItemWeaponSubclass.Mace2H
local Enum_ItemWeaponSubclass_Staff = Enum.ItemWeaponSubclass.Staff
local LE_UNIT_STAT_INTELLECT = LE_UNIT_STAT_INTELLECT

local function ItemListUpdateFunc(button)
    local itemList = button.data.itemList
    if itemList and not itemList.macroTemplate then
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
        button.qualityOverlay:SetAtlas(nil)
        button.count:SetText("")
    else
        button.displayType = 'item'
        button.itemID = itemID

        local itemCount = GetItemCount(itemID, nil, true) or 0
        button.count:SetText(itemCount)

        local _, _, rarity, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
        if itemIcon then
            local r, g, b = GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)
            local quality = C_TradeSkillUI_GetItemReagentQualityByItemInfo(itemID) or C_TradeSkillUI_GetItemCraftedQualityByItemInfo(itemID)

            button:SetBackdropBorderColor(r, g, b)
            button.icon:SetTexture(itemIcon)
            if quality then
                button.qualityOverlay:SetAtlas(format('Professions-Icon-Quality-Tier%d-Inv', quality), true)
            else
                button.qualityOverlay:SetAtlas(nil)
            end
        else
            local item = Item:CreateFromItemID(tonumber(itemID))
            item:ContinueOnItemLoad(function()
                local itemID = item:GetItemID()
                local _, _, rarity, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
                local r, g, b = GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)
                local quality = C_TradeSkillUI_GetItemReagentQualityByItemInfo(itemID) or C_TradeSkillUI_GetItemCraftedQualityByItemInfo(itemID)

                button:SetBackdropBorderColor(r, g, b)
                button.icon:SetTexture(itemIcon)
                if quality then
                    button.qualityOverlay:SetAtlas(format('Professions-Icon-Quality-Tier%d-Inv', quality), true)
                else
                    button.qualityOverlay:SetAtlas(nil)
                end
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
                if E.db.RhythmBox.QuickMacro.Hearthstone[itemID] and PlayerHasToy(itemID) then
                    tinsert(list, itemID)
                end
            end
            if #list > 0 then
                hsItemID = list[random(#list)]
                hsItemName = 'item:' .. hsItemID
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

            -- Not in ItemEffect.db2 with correct SpellCategoryID
            142542, -- Tome of Town Portal
        },
    },
    RandomMount = {
        name = "随机坐骑",
        index = 1,
        outCombat = true,
        inCombat = false,

        updateEvent = {
            ['PLAYER_ENTERING_WORLD'] = true,
            ['ZONE_CHANGED_INDOORS'] = true,
            ['PLAYER_SPECIALIZATION_CHANGED'] = true,
        },
        updateFunc = function(button)
            local macroText = ''
            local mountText = ''

            if IsAddOnLoaded('OPie') then
                macroText = macroText .. '/click [mod:shift]ORLOpen x1\n'
                macroText = macroText .. '/stopmacro [mod:shift]\n'
            end

            local uiMapID = C_Map_GetBestMapForUnit('player')
            local inNokhudOffensive = uiMapID == 2093

            local isInDragonIsles = false
            if uiMapID == 1978 or inNokhudOffensive then
                isInDragonIsles = true
            else
                local info = uiMapID and C_Map_GetMapInfo(uiMapID)
                while info and info.parentMapID do
                    if info.parentMapID == 1978 then
                        isInDragonIsles = true
                        break
                    end

                    info = C_Map_GetMapInfo(info.parentMapID)
                end
            end

            local inInstance, instanceType = IsInInstance()
            local isInDragonIslesDungeon = isInDragonIsles and inInstance and instanceType == 'party'

            if E.myclass == 'DRUID' and isInDragonIsles and (not isInDragonIslesDungeon or inNokhudOffensive) then
                button.druidOverride = ''
                button.druidIcon = ''
            elseif E.myclass == 'DRUID' then
                button.druidOverride = ''
                button.druidIcon = ''
                if IsPlayerSpell(783) then -- Travel Form
                    local spellName = GetSpellInfo(783)
                    macroText = macroText .. '/use [nomod, flyable, outdoors]' .. spellName .. '\n'
                    macroText = macroText .. '/stopmacro [nomod, flyable, outdoors]\n'
                    button.druidOverride = button.druidOverride .. '[nomod, flyable, outdoors]783;'
                    button.druidIcon = button.druidIcon .. '[nomod, flyable, outdoors]132144;'
                end

                local groundForm = (not IsInInstance() and IsPlayerSpell(210053) and 210053) or 783 -- Mount Form / Travel Form
                local groundFormIcon = groundForm == 210053 and 1394966 or 132144
                if IsPlayerSpell(groundForm) then
                    local spellName = GetSpellInfo(groundForm)
                    macroText = macroText .. '/use [nomod, outdoors]' .. spellName .. '\n'
                    macroText = macroText .. '/stopmacro [nomod, outdoors]\n'
                    button.druidOverride = button.druidOverride .. '[nomod, outdoors]' .. groundForm .. ';'
                    button.druidIcon = button.druidIcon .. '[nomod, outdoors]' .. groundFormIcon .. ';'
                end

                local moonkin
                for i = 1, GetNumShapeshiftForms() do
                    local spellID = select(4, GetShapeshiftFormInfo(i))
                    if spellID == 24858 then -- Moonkin Form
                        moonkin = i
                        break
                    end
                end

                macroText = macroText .. '/cancelform [nomounted, nocombat, outdoors' ..
                    (moonkin and (', noform:' .. moonkin) or '') .. ']\n'
            end

            button.itemOverride = nil
            for _, itemID in ipairs(button.data.mountItem) do
                local itemCount = GetItemCount(itemID)
                if itemCount and itemCount > 0 then
                    macroText = macroText .. '/use [nomod]item:' .. itemID .. '\n'
                    macroText = macroText .. '/stopmacro [nomod]\n'
                    button.itemOverride = itemID
                    break
                end
            end

            local isCollectedRocket = select(11, C_MountJournal_GetMountInfoByID(382)) -- X-53 Touring Rocket
            local isCollectedYak = select(11, C_MountJournal_GetMountInfoByID(460)) -- Grand Expedition Yak
            if isCollectedRocket then
                mountText = mountText .. '[mod:ctrl]382;'
            end
            if isCollectedYak then
                mountText = mountText .. '[mod:alt]460;'
            end

            mountText = mountText .. '0'

            if inNokhudOffensive then
                local nameNokhudApproach = C_Map_GetAreaInfo(14479)
                macroText = macroText ..
                    '/run if not IsModifierKeyDown() and IsMounted() then C_MountJournal.Dismiss() else if GetSubZoneText() ~= "' ..
                    nameNokhudApproach .. '" then C_MountJournal.SummonByID(SecureCmdOptionParse("' ..
                    mountText .. '")) else C_MountJournal.SummonByID(547) end end'
            elseif isInDragonIslesDungeon then
                macroText = macroText ..
                    '/run if not IsModifierKeyDown() and IsMounted() then C_MountJournal.Dismiss() else C_MountJournal.SummonByID(547)) end'
            else
                macroText = macroText ..
                    '/run if not IsModifierKeyDown() and IsMounted() then C_MountJournal.Dismiss() else C_MountJournal.SummonByID(SecureCmdOptionParse("' ..
                    mountText .. '")) end'
            end

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

            if E.myclass == 'DRUID' and button.druidOverride ~= '' then
                local override = SecureCmdOptionParse(button.druidOverride)
                if override ~= '' then
                    button.displayType = 'spell'
                    button.spellID = override
                    button.itemID = nil

                    button.icon:SetTexture(SecureCmdOptionParse(button.druidIcon))
                    return
                end
            end

            if button.itemOverride and not IsModifierKeyDown() then
                local itemID = button.itemOverride

                button.displayType = 'item'
                button.itemID = itemID
                button.spellID = nil

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
            else
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
                button.itemID = nil

                button.icon:SetTexture(iconID)
            end
        end,

        mountItem = {
            37011,  -- Magic Broom
        },
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
                191380, -- Refreshing Healing Potion (Tier 3)
                191379, -- Refreshing Healing Potion (Tier 2)
                191378, -- Refreshing Healing Potion (Tier 1)

                -- R.DragonflightBeta
                187802, -- Cosmic Healing Potion
                171267, -- Spiritual Healing Potion
            },
            [2] = {
                5512,   -- Healthstone
                191380, -- Refreshing Healing Potion (Tier 3)
                191379, -- Refreshing Healing Potion (Tier 2)
                191378, -- Refreshing Healing Potion (Tier 1)

                -- R.DragonflightBeta
                187802, -- Cosmic Healing Potion
                171267, -- Spiritual Healing Potion
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
                    191365, -- Potion of Frozen Focus (Tier 3)
                    191364, -- Potion of Frozen Focus (Tier 2)
                    191363, -- Potion of Frozen Focus (Tier 1)

                    -- R.DragonflightBeta
                    171272, -- Potion of Spiritual Clarity
                },
                [2] = {
                    191386, -- Aerated Mana Potion (Tier 3)
                    191385, -- Aerated Mana Potion (Tier 2)
                    191384, -- Aerated Mana Potion (Tier 1)

                    -- R.DragonflightBeta
                    171268,  -- Spiritual Mana Potion
                },
                [3] = {
                    113509, -- Conjured Mana Bun
                    194684, -- Azure Leywine

                    -- R.DragonflightBeta
                    177040, -- Ambroria Dew
                },
                macroTemplate = "/use [combat, mod:ctrl]item:%s; [combat]item:%s; item:%s",
                itemTemplate = "[combat, mod:ctrl]%s; [combat]%s; %s",
            },
            ['TANK'] = {
                [1] = {
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

                    -- R.DragonflightBeta
                    171349, -- Potion of Phantom Fire
                    171352, -- Potion of Empowered Exorcisms
                    171351, -- Potion of Deathly Fixation
                    171270, -- Potion of Spectral Agility
                    171273, -- Potion of Spectral Intellect
                    171275, -- Potion of Spectral Strength
                    142117, -- Potion of Prolonged Power (Legion)
                },
                [2] = {
                    113509, -- Conjured Mana Bun
                },
                macroTemplate = "/use [mod:ctrl][combat]item:%s; item:%s",
                itemTemplate = "[mod:ctrl][combat]%s; %s",
            },
            ['DAMAGER'] = {
                [1] = {
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

                    -- R.DragonflightBeta
                    171349, -- Potion of Phantom Fire
                    171352, -- Potion of Empowered Exorcisms
                    171351, -- Potion of Deathly Fixation
                    171270, -- Potion of Spectral Agility
                    171273, -- Potion of Spectral Intellect
                    171275, -- Potion of Spectral Strength
                    142117, -- Potion of Prolonged Power (Legion)
                },
                [2] = {
                    113509, -- Conjured Mana Bun
                },
                macroTemplate = "/use [mod:ctrl][combat]item:%s; item:%s",
                itemTemplate = "[mod:ctrl][combat]%s; %s",
            },
        },
    },
    Consumable = {
        name = "消耗品",
        index = 5,
        outCombat = true,
        inCombat = true,

        updateEvent = {
            ['PLAYER_ENTERING_WORLD'] = true,
            ['BAG_UPDATE_DELAYED'] = true,
            ['PLAYER_SPECIALIZATION_CHANGED'] = true,
            ['PLAYER_EQUIPMENT_CHANGED'] = true,
        },
        updateFunc = function(button)
            if not button.overlay then
                local subFrame = CreateFrame('Frame', nil, button)
                subFrame:ClearAllPoints()
                subFrame:SetPoint('BOTTOM', button, 'TOP')
                subFrame:SetSize(E.db.RhythmBox.QuickMacro.ButtonSize, 3)
                subFrame:Hide()
                subFrame.buttons = {}
                button.subFrame = subFrame

                for index, data in ipairs(button.data.subButtonList) do
                    local prev = index == 1 and subFrame or subFrame.buttons[index - 1]

                    local subButton = QM:UpdateButtonLayout('Consumable' .. index, subFrame)
                    subButton:ClearAllPoints()
                    subButton:SetPoint('BOTTOM', prev, 'TOP', 0, index > 1 and 3 or 0)
                    subButton.data = data

                    tinsert(subFrame.buttons, subButton)
                end

                local overlay = CreateFrame('Button', button:GetName() .. 'Overlay', button, 'SecureHandlerStateTemplate, SecureHandlerClickTemplate')
                overlay:ClearAllPoints()
                overlay:SetAllPoints()
                overlay:SetScript('OnEnter', button:GetScript('OnEnter'))
                overlay:SetScript('OnLeave', button:GetScript('OnLeave'))
                overlay.data = button.data

                overlay:StyleButton()

                overlay:SetFrameRef('subFrame', subFrame)
                overlay:SetAttribute('expanded', false)
                RegisterStateDriver(overlay, 'combat', '[nocombat] 0; 1')
                overlay:SetAttribute('_onstate-combat', button.data.onCombatSnippet)
                overlay:SetAttribute('_onclick', button.data.onClickSnippet)
                button.overlay = overlay
            end

            for _, subButton in ipairs(button.subFrame.buttons) do
                if subButton.data.updateFunc then
                    subButton.data.updateFunc(subButton)
                end

                local macroText = ItemListUpdateFunc(subButton)
                subButton.macroText = macroText
                subButton:SetAttribute('type', 'macro')
                subButton:SetAttribute('macrotext', macroText)

                if macroText and not subButton:IsShown() then
                    subButton:Show()
                elseif not macroText then
                    subButton:Hide()
                end

                ItemDisplayFunc(subButton)
            end

            return ''
        end,
        displayFunc = function(button)
            button.displayType = nil

            button:SetBackdropBorderColor(0, 112 / 255, 221 / 255)
            button.icon:SetTexture(237271)
        end,

        onClickSnippet = [[
            if self:GetAttribute('expanded') then
                self:SetAttribute('expanded', false)
                self:ClearBinding('ESCAPE')
                self:GetFrameRef('subFrame'):Hide()
            else
                self:SetAttribute('expanded', true)
                self:SetBindingClick(0, 'ESCAPE', self:GetName())
                self:GetFrameRef('subFrame'):Show()
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
                    [1] = {
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

                        -- R.DragonflightBeta
                        171276, -- Spectral Flask of Power
                    },
                    macroTemplate = "/use item:%s",
                    itemTemplate = "%s",
                },
            },
            {
                itemList = {
                    [1] = {
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

                        -- R.DragonflightBeta
                        172041, -- Spinefin Souffle and Fries
                        172045, -- Tenebrous Crown Roast Aspic
                        172049, -- Iridescent Ravioli with Apple Sauce
                        172051, -- Steak a la Mode
                    },
                    macroTemplate = "/use item:%s",
                    itemTemplate = "%s",
                },
            },
            {
                -- R.DragonflightBeta
                itemList = {
                    [1] = {
                        172347, -- Heavy Desolate Armor Kit
                    },
                    macroTemplate = "/use item:%s\n/use 5\n/click StaticPopup1Button1",
                    itemTemplate = "%s",
                },
            },
            {
                itemList = {
                    [1] = {
                        201325, -- Draconic Augment Rune

                        -- R.DragonflightBeta
                        181468, -- Veiled Augment Rune
                    },
                    macroTemplate = "/use item:%s",
                    itemTemplate = "%s",
                },
            },
            {
                updateFunc = function(button)
                    local specID, _, _, _, _, primaryStat = GetSpecializationInfo(E.myspec or GetSpecialization())
                    if primaryStat == LE_UNIT_STAT_INTELLECT then
                        button.data.itemList = button.data.oilList
                    elseif specID == 253 or specID == 254 then
                        -- Beast Mastery or Marksmanship
                        local itemID = GetInventoryItemID('player', 16)
                        local subclassID = itemID and select(13, GetItemInfo(itemID))
                        if subclassID == Enum_ItemWeaponSubclass_Guns then
                            button.data.itemList = button.data.gunFireList
                        else
                            button.data.itemList = button.data.bowAmmoList
                        end
                    else
                        local itemID = GetInventoryItemID('player', 16)
                        local subclassID = itemID and select(13, GetItemInfo(itemID))
                        if (
                            subclassID == Enum_ItemWeaponSubclass_Mace1H or
                            subclassID == Enum_ItemWeaponSubclass_Mace2H or
                            subclassID == Enum_ItemWeaponSubclass_Staff
                        ) then
                            button.data.itemList = button.data.balanceStoneList
                        else
                            button.data.itemList = button.data.sharpenStoneList
                        end
                    end
                end,

                sharpenStoneList = {
                    [1] = {
                        191940, -- Primal Whetstone (Tier 3)
                        191939, -- Primal Whetstone (Tier 2)
                        191933, -- Primal Whetstone (Tier 1)

                        -- R.DragonflightBeta
                        171437, -- Shaded Sharpening Stone
                    },
                    macroTemplate = "/click TempEnchant1\n/click ElvUIPlayerBuffsTempEnchant1\n/use item:%s\n/use 16\n/click StaticPopup1Button1",
                    itemTemplate = "%s",
                },
                balanceStoneList = {
                    [1] = {
                        191945, -- Primal Weightstone (Tier 3)
                        191944, -- Primal Weightstone (Tier 2)
                        191943, -- Primal Weightstone (Tier 1)

                        -- R.DragonflightBeta
                        171439, -- Shaded Weightstone
                    },
                    macroTemplate = "/click TempEnchant1\n/click ElvUIPlayerBuffsTempEnchant1\n/use item:%s\n/use 16\n/click StaticPopup1Button1",
                    itemTemplate = "%s",
                },
                bowAmmoList = {
                    [1] = {
                        198165, -- Endless Stack of Needles (Tier 3)
                        198164, -- Endless Stack of Needles (Tier 2)
                        198163, -- Endless Stack of Needles (Tier 1)

                        -- R.DragonflightBeta
                        171285, -- Shadowcore Oil
                    },
                    macroTemplate = "/click TempEnchant1\n/click ElvUIPlayerBuffsTempEnchant1\n/use item:%s\n/use 16\n/click StaticPopup1Button1",
                    itemTemplate = "%s",
                },
                gunFireList = {
                    [1] = {
                        198162, -- Completely Safe Rockets (Tier 3)
                        198161, -- Completely Safe Rockets (Tier 2)
                        198160, -- Completely Safe Rockets (Tier 1)

                        -- R.DragonflightBeta
                        171285, -- Shadowcore Oil
                    },
                    macroTemplate = "/click TempEnchant1\n/click ElvUIPlayerBuffsTempEnchant1\n/use item:%s\n/use 16\n/click StaticPopup1Button1",
                    itemTemplate = "%s",
                },
                oilList = {
                    ['DAMAGER'] = {
                        [1] = {
                            194820, -- Howling Rune (Tier 3)
                            194819, -- Howling Rune (Tier 2)
                            194817, -- Howling Rune (Tier 1)
                            194823, -- Buzzing Rune (Tier 3)
                            194822, -- Buzzing Rune (Tier 2)
                            194821, -- Buzzing Rune (Tier 1)

                            -- R.DragonflightBeta
                            171285, -- Shadowcore Oil
                        },
                        macroTemplate = "/click TempEnchant1\n/click ElvUIPlayerBuffsTempEnchant1\n/use item:%s",
                        itemTemplate = "%s",
                    },
                    ['HEALER'] = {
                        [1] = {
                            194826, -- Chirping Rune (Tier 3)
                            194825, -- Chirping Rune (Tier 2)
                            194824, -- Chirping Rune (Tier 1)
                            194820, -- Howling Rune (Tier 3)
                            194819, -- Howling Rune (Tier 2)
                            194817, -- Howling Rune (Tier 1)
                            194823, -- Buzzing Rune (Tier 3)
                            194822, -- Buzzing Rune (Tier 2)
                            194821, -- Buzzing Rune (Tier 1)

                            -- R.DragonflightBeta
                            171286, -- Embalmer's Oil
                        },
                        macroTemplate = "/click TempEnchant1\n/click ElvUIPlayerBuffsTempEnchant1\n/use item:%s",
                        itemTemplate = "%s",
                    },
                },
            },
            {
                updateFunc = function(button)
                    local itemID = GetInventoryItemID('player', 17)
                    if itemID then
                        local itemType, _, _, _, subclassID = select(9, GetItemInfo(itemID))
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
                                button.data.itemList = button.data.balanceStoneList
                            else
                                button.data.itemList = button.data.sharpenStoneList
                            end

                            return
                        end
                    end

                    button.data.itemList = nil
                end,

                sharpenStoneList = {
                    [1] = {
                        191940, -- Primal Whetstone (Tier 3)
                        191939, -- Primal Whetstone (Tier 2)
                        191933, -- Primal Whetstone (Tier 1)

                        -- R.DragonflightBeta
                        171437, -- Shaded Sharpening Stone
                    },
                    macroTemplate = "/click TempEnchant2\n/click ElvUIPlayerBuffsTempEnchant2\n/use item:%s\n/use 17\n/click StaticPopup1Button1",
                    itemTemplate = "%s",
                },
                balanceStoneList = {
                    [1] = {
                        191945, -- Primal Weightstone (Tier 3)
                        191944, -- Primal Weightstone (Tier 2)
                        191943, -- Primal Weightstone (Tier 1)

                        -- R.DragonflightBeta
                        171439, -- Shaded Weightstone
                    },
                    macroTemplate = "/click TempEnchant2\n/click ElvUIPlayerBuffsTempEnchant2\n/use item:%s\n/use 17\n/click StaticPopup1Button1",
                    itemTemplate = "%s",
                },
            },
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
                    local activityInfo = C_LFGList_GetActivityInfoTable(entryData.activityID)
                    if activityInfo.isMythicPlusActivity or activityInfo.isCurrentRaidActivity then
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
    AltInvite = {
        name = "CD号/小号邀请",
        index = 7,
        outCombat = true,
        inCombat = false,

        updateEvent = {
            ['PLAYER_ENTERING_WORLD'] = true,
            ['BN_FRIEND_INFO_CHANGED'] = true, -- BN_INFO_CHANGED is triggered before info updated
        },
        updateFunc = function(button)
            local toonID = select(3, BNGetInfo())
            if not toonID then return end

            local accountInfo = C_BattleNet_GetAccountInfoByID(toonID)
            if (
                accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.playerGuid and
                accountInfo.gameAccountInfo.characterName and accountInfo.gameAccountInfo.realmName and
                accountInfo.gameAccountInfo.playerGuid ~= E.myguid
            ) then
                button.fullName = accountInfo.gameAccountInfo.characterName .. '-' .. accountInfo.gameAccountInfo.realmName
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

        onClickFunc = function(button)
            if IsModifierKeyDown() then
                SendChatMessage('123', 'WHISPER', nil, button.fullName)
            else
                C_PartyInfo_InviteUnit(button.fullName)
            end
        end,
    },
    MapSpecial = {
        name = "地图特殊物品",
        index = 8,
        outCombat = true,
        inCombat = true,

        updateEvent = {
            ['PLAYER_ENTERING_WORLD'] = true,
            ['ZONE_CHANGED'] = true,
        },
        updateFunc = function(button)
            local uiMapID = C_Map_GetBestMapForUnit('player')
            if uiMapID == 1695 then
                button.itemText = '158149' -- Overtuned Corgi Goggles
                button.count:Hide()
                return '/use item:158149'
            end
        end,
        displayFunc = ItemDisplayFunc,
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

    if self.displayType == 'item' and IsItemInRange(self.itemID, 'target') == false then
        self.icon:SetVertexColor(.8, .1, .1)
    elseif self.displayType == 'spell' or self.displayType == 'mount' then
        local inRange = IsSpellInRange(self.spellID, 'target')
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

    for _, button in pairs(self.external) do
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

function QM:UpdateButtonLayout(buttonName, parent)
    local button
    if not parent or parent == self.container then
        parent = self.container
        button = self.buttons[buttonName]
    else
        button = self.external[buttonName]
    end

    if not button then
        -- Create Button
        button = CreateFrame('Button', 'RhythmBoxQM' .. buttonName, parent, 'SecureActionButtonTemplate, BackdropTemplate')
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
    end

    button:SetSize(E.db.RhythmBox.QuickMacro.ButtonSize, E.db.RhythmBox.QuickMacro.ButtonSize)
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
    self.external = {}

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
