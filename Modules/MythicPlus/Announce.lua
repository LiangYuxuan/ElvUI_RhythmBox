local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:GetModule('MythicPlus')
local LOR = LibStub('LibOpenRaid-1.0')

-- Lua functions
local _G = _G
local format, ipairs, strfind, strmatch, strsub, tonumber = format, ipairs, strfind, strmatch, strsub, tonumber

-- WoW API / Variables
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_ChatInfo_SendAddonMessage = C_ChatInfo.SendAddonMessage
local C_ChatInfo_RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix
local C_MythicPlus_GetCurrentAffixes = C_MythicPlus.GetCurrentAffixes
local C_MythicPlus_GetOwnedKeystoneChallengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID
local C_MythicPlus_GetOwnedKeystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid

local ChatEdit_GetActiveWindow = ChatEdit_GetActiveWindow
local ChatEdit_InsertLink = ChatEdit_InsertLink
local ChatFrame_OpenChat = ChatFrame_OpenChat

local CHALLENGE_MODE_KEYSTONE_HYPERLINK = CHALLENGE_MODE_KEYSTONE_HYPERLINK
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME

local AKPrefix = 'Schedule|'

do
    local fullName = E.myname .. '-' .. E.myrealm
    local keystoneLinks = {}
    for itemID in pairs(MP.keystoneItemIDs) do
        tinsert(keystoneLinks, '|Hitem:' .. itemID .. ':')
    end

    function MP:CHAT_MSG_LOOT(_, lootString, _, _, _, unitName)
        for _, itemLink in ipairs(keystoneLinks) do
            if strmatch(lootString, itemLink) then
                if unitName == fullName then
                    self:ScheduleTimer('CheckKeystone', 2)
                else
                    self:DelayedRequestPartyKeystone()
                end
                return
            end
        end
    end
end

function MP:BAG_UPDATE_DELAYED()
    self:ScheduleTimer('CheckKeystone', 2)
end

function MP:DeepCheckKeystone()
    self:CheckKeystone()
    self:ScheduleTimer('CheckKeystone', 2)
    self:DelayedRequestPartyKeystone()
end

function MP:CheckKeystone()
    local keystoneMapID = C_MythicPlus_GetOwnedKeystoneChallengeMapID()
	local keystoneLevel = C_MythicPlus_GetOwnedKeystoneLevel()

	if keystoneMapID ~= self.currentKeystoneMapID or keystoneLevel ~= self.currentKeystoneLevel then
		self.currentKeystoneMapID = keystoneMapID
        self.currentKeystoneLevel = keystoneLevel
        self:SendKeystone()
        self:SendSignal('MYTHIC_KEYSTONE_UPDATE')
    end
end

function MP:FlushPartyKeystone()
    if self.partyKeystoneDirty then
        self:RequestPartyKeystone()
    end
end

function MP:DelayedRequestPartyKeystone()
    if _G.ChallengesFrame and _G.ChallengesFrame:IsVisible() then
        self:SendSignal('MYTHIC_KEYSTONE_UPDATE')
        self:RequestPartyKeystone()
        return
    end
    self.partyKeystoneDirty = true
end

function MP:RequestPartyKeystone()
    self.partyKeystoneDirty = nil
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then return end

    C_ChatInfo_SendAddonMessage('AngryKeystones', AKPrefix .. 'request', 'PARTY')

    -- origin Angry Keystones replys to self 'request' message,
    -- but sends message too often! so we don't reply to them,
    -- but sends ours to let party member known.
    self:SendKeystone()

    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        LOR.RequestKeystoneDataFromRaid()
    else
        LOR.RequestKeystoneDataFromParty()
    end
end

function MP:SendKeystone()
    local keystoneMapID, keystoneLevel = self:GetModifiedKeystone()

	local text = '0'
	if keystoneMapID and keystoneLevel then
		text = keystoneMapID .. ':' .. keystoneLevel
    end

    C_ChatInfo_SendAddonMessage('AngryKeystones', AKPrefix .. text, 'PARTY')
end

do
    -- the level that corresponding affix should take place
    local affixLevel = {2, 7, 14}

    function MP:InsertChatLink()
        local keystoneMapID, keystoneLevel = self:GetModifiedKeystone()

        if keystoneMapID and keystoneLevel then
            local affix = ''
            local affixes = C_MythicPlus_GetCurrentAffixes()
            for index, tbl in ipairs(affixes) do
                if affixLevel[index] > keystoneLevel then break end
                affix = affix .. ':' .. tbl.id
            end

            local itemLink = format('|cffa335ee|Hkeystone:%d:%d:%d%s|h[' .. CHALLENGE_MODE_KEYSTONE_HYPERLINK .. ']|h|r',
                self.currentKeystone, keystoneMapID, keystoneLevel, affix, C_ChallengeMode_GetMapUIInfo(keystoneMapID), keystoneLevel
            )
            if ChatEdit_GetActiveWindow() then
                ChatEdit_InsertLink(itemLink)
            else
                ChatFrame_OpenChat(itemLink, DEFAULT_CHAT_FRAME)
            end
        end
    end
end

function MP:GetModifiedKeystone()
    return E.db.RhythmBox.MythicPlus.ChallengeMapID > 0 and
        E.db.RhythmBox.MythicPlus.ChallengeMapID or self.currentKeystoneMapID,
        E.db.RhythmBox.MythicPlus.Level > 0 and
        E.db.RhythmBox.MythicPlus.Level or self.currentKeystoneLevel
end

do
    local playerFullName = E.myname .. '-' .. E.myrealm
    function MP:ReceiveMessage(_, text, sender)
        if sender == playerFullName then return end

        if strsub(text, 1, #AKPrefix) == AKPrefix then
            local message = strsub(text, #AKPrefix + 1)

            if message == 'request' then
                self:SendKeystone()
            elseif message == '0' then
                if self.unitKeystones[sender] ~= 0 then
                    self.unitKeystones[sender] = 0
                    self:SendSignal('MYTHIC_KEYSTONE_UPDATE')
                end
            else
                local arg1, arg2 = strmatch(message, '^(%d+):(%d+)$')
                local keystoneMapID = arg1 and tonumber(arg1)
                local keystoneLevel = arg2 and tonumber(arg2)
                if keystoneMapID and keystoneLevel and (
                    not self.unitKeystones[sender] or self.unitKeystones[sender] == 0 or
                    self.unitKeystones[sender][1] ~= keystoneMapID or self.unitKeystones[sender][2] ~= keystoneLevel
                ) then
                    self.unitKeystones[sender] = {keystoneMapID, keystoneLevel}
                    self:SendSignal('MYTHIC_KEYSTONE_UPDATE')
                end
            end
        end
    end
end

function MP:BuildAnnounce()
    self.unitKeystones = {}

    self:RegisterEvent('CHAT_MSG_LOOT')
    self:RegisterEvent('BAG_UPDATE_DELAYED')
    self:RegisterEvent('GROUP_ROSTER_UPDATE', 'DelayedRequestPartyKeystone')

    self:RegisterSignal('CHALLENGE_MODE_START', 'DeepCheckKeystone')
    self:RegisterSignal('CHALLENGE_MODE_COMPLETED', 'DeepCheckKeystone')

    self:RegisterSignal('CHAT_MSG_ADDON_ANGRY_KEYSTONES', 'ReceiveMessage')
    C_ChatInfo_RegisterAddonMessagePrefix('AngryKeystones')

    self:DelayedRequestPartyKeystone()
    self:CheckKeystone()

    local handler = {
        OnKeystoneUpdate = function(sender, keystoneInfo)
            if not strfind(sender, '-') then
                sender = sender .. '-' .. E.myrealm
            end

            local keystoneMapID, keystoneLevel = keystoneInfo.mythicPlusMapID, keystoneInfo.level
            if keystoneMapID == 0 then
                if MP.unitKeystones[sender] ~= 0 then
                    MP.unitKeystones[sender] = 0
                    MP:SendSignal('MYTHIC_KEYSTONE_UPDATE')
                end
            elseif keystoneMapID and keystoneLevel and (
                not MP.unitKeystones[sender] or MP.unitKeystones[sender] == 0 or
                MP.unitKeystones[sender][1] ~= keystoneMapID or MP.unitKeystones[sender][2] ~= keystoneLevel
            ) then
                MP.unitKeystones[sender] = {keystoneMapID, keystoneLevel}
                MP:SendSignal('MYTHIC_KEYSTONE_UPDATE')
            end
        end,
    }
    LOR.RegisterCallback(handler, 'KeystoneUpdate', 'OnKeystoneUpdate')
end
