local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local MP = R:GetModule('MythicPlus')

-- Lua functions
local _G = _G
local format, ipairs, strmatch, strsub, tonumber = format, ipairs, strmatch, strsub, tonumber

-- WoW API / Variables
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_ChatInfo_SendAddonMessage = C_ChatInfo.SendAddonMessage
local C_ChatInfo_RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix
local C_MythicPlus_GetCurrentAffixes = C_MythicPlus.GetCurrentAffixes
local C_MythicPlus_GetOwnedKeystoneChallengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID
local C_MythicPlus_GetOwnedKeystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel
local IsInGroup = IsInGroup

local ChatEdit_GetActiveWindow = ChatEdit_GetActiveWindow
local ChatEdit_InsertLink = ChatEdit_InsertLink
local ChatFrame_OpenChat = ChatFrame_OpenChat

local CHALLENGE_MODE_KEYSTONE_HYPERLINK = CHALLENGE_MODE_KEYSTONE_HYPERLINK
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME

local AKPrefix = 'Schedule|'

do
    local keystoneLinks = {}
    for itemID in pairs(MP.keystoneItemIDs) do
        tinsert(keystoneLinks, '|Hitem:' .. itemID .. ':')
    end

    function MP:CHAT_MSG_LOOT(lootString, _, _, _, unitName)
        for _, itemLink in ipairs(keystoneLinks) do
            if strmatch(lootString, itemLink) then
                if E.myname == unitName then
                    self:CheckKeystone()
                else
                    self:DelayedRequestPartyKeystone()
                end
                return
            end
        end
    end
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
    local affixLevel = {2, 4, 7, 10}

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
    self:RegisterEvent('BAG_UPDATE_DELAYED', 'CheckKeystone')
    self:RegisterEvent('GROUP_ROSTER_UPDATE', 'DelayedRequestPartyKeystone')

    self:RegisterSignal('CHALLENGE_MODE_START', 'DeepCheckKeystone')
    self:RegisterSignal('CHALLENGE_MODE_COMPLETED', 'DeepCheckKeystone')

    self:RegisterSignal('CHAT_MSG_ADDON_ANGRY_KEYSTONES', 'ReceiveMessage')
    C_ChatInfo_RegisterAddonMessagePrefix('AngryKeystones')

    self:DelayedRequestPartyKeystone()
    self:CheckKeystone()
end
