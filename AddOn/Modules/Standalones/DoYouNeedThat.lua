local R, E, L, V, P, G = unpack((select(2, ...)))
local DY = R:NewModule('DoYouNeedThat', 'AceEvent-3.0', 'AceTimer-3.0')
local StdUi = LibStub('StdUi')

-- Lua functions
local _G = _G
local format, gsub, ipairs, select, strfind, strmatch, strsplit, tinsert, type, wipe = format, gsub, ipairs, select, strfind, strmatch, strsplit, tinsert, type, wipe

-- WoW API / Variables
local C_Item_DoesItemContainSpec = C_Item.DoesItemContainSpec
local C_Item_GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo
local C_Item_GetItemInfo = C_Item.GetItemInfo
local C_Item_GetItemInfoInstant = C_Item.GetItemInfoInstant
local C_Item_IsEquippableItem = C_Item.IsEquippableItem
local C_Item_RequestLoadItemDataByID = C_Item.RequestLoadItemDataByID
local CanInspect = CanInspect
local GetInventoryItemID = GetInventoryItemID
local GetInventoryItemLink = GetInventoryItemLink
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetSpecializationInfo = GetSpecializationInfo
local GetTime = GetTime
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local NotifyInspect = NotifyInspect
local SendChatMessage = SendChatMessage
local UnitGUID = UnitGUID
local UnitIsUnit = UnitIsUnit
local UnitTokenFromGUID = UnitTokenFromGUID

local Enum_ItemClass_Armor = Enum.ItemClass.Armor
local Enum_ItemClass_Weapon = Enum.ItemClass.Weapon
local INVSLOT_FIRST_EQUIPPED = INVSLOT_FIRST_EQUIPPED
local INVSLOT_LAST_EQUIPPED = INVSLOT_LAST_EQUIPPED
local YOU = YOU

local pattern = gsub(LOOT_ITEM, '%%[ds]', '(.+)')

local itemEquipLocToInvSlotID = {
    INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2,
    INVTYPE_SHOULDER = 3,
    INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5,
    INVTYPE_WAIST = 6,
    INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8,
    INVTYPE_WRIST = 9,
    INVTYPE_HAND = 10,
    INVTYPE_FINGER = {11, 12},
    INVTYPE_TRINKET = {13, 14},
    INVTYPE_WEAPON = {16, 17},
    INVTYPE_SHIELD = 17,
    INVTYPE_RANGED = 16,
    INVTYPE_CLOAK = 15,
    INVTYPE_2HWEAPON = 16,
    INVTYPE_TABARD = 19,
    INVTYPE_ROBE = 5,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_WEAPONOFFHAND = 16,
    INVTYPE_HOLDABLE = 17,
    INVTYPE_THROWN = 16,
    INVTYPE_RANGEDRIGHT = 16,
}

local itemEquipLocToName = {
    INVTYPE_HEAD = '头',
    INVTYPE_NECK = '项链',
    INVTYPE_SHOULDER = '肩膀',
    INVTYPE_CHEST = '胸',
    INVTYPE_WAIST = '腰带',
    INVTYPE_LEGS = '腿',
    INVTYPE_FEET = '鞋子',
    INVTYPE_WRIST = '护腕',
    INVTYPE_HAND = '手',
    INVTYPE_FINGER = '戒指',
    INVTYPE_TRINKET = 'SP',
    INVTYPE_WEAPON = '武器',
    INVTYPE_SHIELD = '盾牌',
    INVTYPE_RANGED = '武器',
    INVTYPE_CLOAK = '披风',
    INVTYPE_2HWEAPON = '武器',
    INVTYPE_ROBE = '胸',
    INVTYPE_WEAPONMAINHAND = '武器',
    INVTYPE_WEAPONOFFHAND = '武器',
    INVTYPE_HOLDABLE = '副手',
    INVTYPE_THROWN = '武器',
    INVTYPE_RANGEDRIGHT = '武器',
}

function DY:AddEntry(itemLink, looterName)
    if not C_Item_IsEquippableItem(itemLink) then return end

    local _, _, itemRarity, _, _, _, _, _, itemEquipLoc, itemIcon, _, itemClassID = C_Item_GetItemInfo(itemLink)
    if itemRarity ~= 4 or (itemClassID ~= Enum_ItemClass_Weapon and itemClassID ~= Enum_ItemClass_Armor) then return end

    local itemCanEquip = C_Item_DoesItemContainSpec(itemLink, E.myClassID)
    local itemCanDrop = C_Item_DoesItemContainSpec(itemLink, E.myClassID, (GetSpecializationInfo(E.myspec)))
    if not itemCanEquip then return end

    local looterFullName
    if strfind(looterName, '-') then
        looterFullName = looterName
        looterName = strsplit('-', looterName)
    else
        looterFullName = looterName .. '-' .. E.myrealm
    end

    local looterGUID = UnitGUID(looterName)
    local looterGear = {}
    if looterGUID and self.partyMember[looterGUID] and self.partyMember[looterGUID].gear then
        local gear = self.partyMember[looterGUID].gear
        local invSlotID = itemEquipLocToInvSlotID[itemEquipLoc]
        if type(invSlotID) == 'table' then
            for _, slotID in ipairs(invSlotID) do
                if gear[slotID] then
                    local itemLevel = C_Item_GetDetailedItemLevelInfo(gear[slotID])
                    local icon = select(5, C_Item_GetItemInfoInstant(gear[slotID]))
                    tinsert(looterGear, (gsub(gear[slotID], '%[(.*)%]', format('|T%d:16|t%s', icon, itemLevel))))
                end
            end
        elseif gear[invSlotID] then
            local itemLevel = C_Item_GetDetailedItemLevelInfo(gear[invSlotID])
            local icon = select(5, C_Item_GetItemInfoInstant(gear[invSlotID]))
            tinsert(looterGear, (gsub(gear[invSlotID], '%[(.*)%]', format('|T%d:16|t%s', icon, itemLevel))))
        end
    end

    local itemLevel = C_Item_GetDetailedItemLevelInfo(itemLink)
    local itemIconLink = gsub(itemLink, '%[(.*)%]', format('|T%d:16|t', itemIcon))
    local itemLinkILvl = gsub(itemLink, '%[(.*)%]', format('[%d:%%1]', itemLevel))

    tinsert(self.lootItemList, {
        itemIcon = itemIconLink,
        itemLink = itemLinkILvl,

        looterName = looterName,
        looterFullName = looterFullName,
        looterGear1 = looterGear[1],
        looterGear2 = looterGear[2],

        itemRefName = itemEquipLocToName[itemEquipLoc] or itemLink,
        wantButton = itemCanDrop and '需求' or '贪婪',
    })

    self.itemTable:SetData(self.lootItemList)
    self.itemWindow:Show()
end

function DY:ClearEntries()
    wipe(self.lootItemList)
    self.itemTable:SetData(self.lootItemList)
end

function DY:CHAT_MSG_LOOT(_, text, _, _, _, looter)
    local name, itemLink = strmatch(text, pattern)
    if not itemLink or name == YOU then return end

    self:AddEntry(itemLink, looter)
end

function DY:INSPECT_READY(_, unitGUID)
    local unitID = UnitTokenFromGUID(unitGUID)
    if not unitID then return end

    if not self.partyMember[unitGUID] then
        self.partyMember[unitGUID] = {
            gear = {},
        }
    end

    local isAllReady = true
    for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local itemID = GetInventoryItemID(unitID, i)
        local itemLink = GetInventoryItemLink(unitID, i)

        if itemLink then
            self.partyMember[unitGUID].gear[i] = itemLink
        elseif itemID then
            isAllReady = false
            C_Item_RequestLoadItemDataByID(itemID)
        end
    end

    self.partyMember[unitGUID].expiredTime = GetTime() + (isAllReady and 600 or 30)
end

function DY:InspectPartyMember()
    local now = GetTime()

    local prefix = IsInRaid() and 'raid' or 'party'
    local length = prefix == 'party' and GetNumSubgroupMembers() or GetNumGroupMembers()
    for i = 1, length do
        local unitID = prefix .. i
        local unitGUID = UnitGUID(unitID)
        if unitGUID and (prefix ~= 'raid' or not UnitIsUnit(unitID, 'player')) and CanInspect(unitID) then
            local expiredTime = self.partyMember[unitGUID] and self.partyMember[unitGUID].expiredTime
            if not expiredTime or expiredTime < now then
                self:RegisterEvent('INSPECT_READY')
                NotifyInspect(unitID)
                return
            end
        end
    end

    self:UnregisterEvent('INSPECT_READY')
end

function DY:CHALLENGE_MODE_COMPLETED()
    self:ClearEntries()
end

function DY:PLAYER_ENTERING_WORLD()
    local inInstance = IsInInstance()
    if inInstance then
        self:RegisterEvent('CHAT_MSG_LOOT')

        if self.timer then
            self:CancelTimer(self.timer)
        end
        self.timer = self:ScheduleRepeatingTimer('InspectPartyMember', 7)
    else
        self:UnregisterEvent('CHAT_MSG_LOOT')

        if self.timer then
            self:CancelTimer(self.timer)
            self.timer = nil
        end
    end
end

do
    local function ItemCellOnEnter(_, cellFrame, _, rowData, columnData)
        local itemLink = rowData[columnData.index]
        if not itemLink then return end

        _G.GameTooltip:SetOwner(cellFrame, 'ANCHOR_NONE')
        _G.GameTooltip:ClearAllPoints()
        _G.GameTooltip:SetPoint('RIGHT')
        _G.GameTooltip:ClearLines()
        _G.GameTooltip:SetHyperlink(itemLink)
        _G.GameTooltip:Show()
    end

    local function ItemCellOnLeave()
        _G.GameTooltip:Hide()
    end

    local function WantButtonOnClick(_, _, _, rowData)
        if not rowData.wantButton then return end

        SendChatMessage(format('请问%s要吗？', rowData.itemRefName), 'WHISPER', nil, rowData.looterFullName)

        rowData.wantButton = nil
    end

    function DY:BuildFrame()
        local itemWindow = StdUi:Window(E.UIParent, 560, 200, "毛装助手")
        itemWindow:SetPoint('CENTER', 350, 0)
        itemWindow:SetFrameStrata('HIGH')
        itemWindow:Hide()
        itemWindow:SetScript('OnHide', function()
            DY:ClearEntries()
        end)
        self.itemWindow = itemWindow

        local cols = {
            {
                name     = "",
                width    = 30,
                align    = 'CENTER',
                index    = 'itemIcon',
                format   = 'text',
                sortable = false,
                events   = {
                    OnEnter = ItemCellOnEnter,
                    OnLeave = ItemCellOnLeave,
                },
            },
            {
                name     = "装备",
                width    = 200,
                align    = 'LEFT',
                index    = 'itemLink',
                format   = 'text',
                sortable = false,
                events   = {
                    OnEnter = ItemCellOnEnter,
                    OnLeave = ItemCellOnLeave,
                },
            },
            {
                name     = "拾取者",
                width    = 100,
                align    = 'LEFT',
                index    = 'looterName',
                format   = 'text',
            },
            {
                name     = "",
                width    = 60,
                align    = 'CENTER',
                index    = 'looterGear1',
                format   = 'text',
                sortable = false,
                events   = {
                    OnEnter = ItemCellOnEnter,
                    OnLeave = ItemCellOnLeave,
                },
            },
            {
                name     = "",
                width    = 60,
                align    = 'CENTER',
                index    = 'looterGear2',
                format   = 'text',
                sortable = false,
                events   = {
                    OnEnter = ItemCellOnEnter,
                    OnLeave = ItemCellOnLeave,
                },
            },
            {
                name     = "",
                width    = 40,
                align    = 'CENTER',
                index    = 'wantButton',
                format   = 'text',
                events   = {
                    OnClick = WantButtonOnClick,
                },
            },
        }

        local st = StdUi:ScrollTable(itemWindow, cols, 4, 24)
        StdUi:GlueTop(st, itemWindow, 0, -70)
        self.itemTable = st
    end
end

function DY:Initialize()
    self.lootItemList = {}
    self.partyMember = {}

    self:BuildFrame()

    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('CHALLENGE_MODE_COMPLETED')
end

R:RegisterModule(DY:GetName())
