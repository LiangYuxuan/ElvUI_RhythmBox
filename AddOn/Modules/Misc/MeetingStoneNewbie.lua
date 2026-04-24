local R, E, L, V, P, G = unpack((select(2, ...)))
local MSN = R:NewModule('MeetingStoneNewbie', 'AceEvent-3.0', 'AceTimer-3.0', 'AceHook-3.0', 'AceComm-3.0', 'AceSerializer-3.0')

-- Lua functions
local _G = _G
local ipairs, issecretvalue, pairs, random, tostring = ipairs, issecretvalue, pairs, random, tostring
local string_find = string.find
local table_concat = table.concat
local table_insert = table.insert

-- WoW API / Variables
local C_AutoComplete_GetAutoCompleteRealms = C_AutoComplete.GetAutoCompleteRealms
local C_LFGList_GetApplicantInfo = C_LFGList.GetApplicantInfo
local C_LFGList_GetApplicantMemberInfo = C_LFGList.GetApplicantMemberInfo
local C_LFGList_GetApplicants = C_LFGList.GetApplicants
local C_LFGList_GetSearchResultInfo = C_LFGList.GetSearchResultInfo
local GetTime = GetTime
local IsShiftKeyDown = IsShiftKeyDown
local UnitIsPlayer = UnitIsPlayer
local UnitName = UnitName
local UnitTokenFromGUID = UnitTokenFromGUID

local TooltipDataProcessor_AddTooltipPostCall = TooltipDataProcessor.AddTooltipPostCall

local Enum_TooltipDataType_Unit = Enum.TooltipDataType.Unit

---@class LocomotiveData
---@field isNewbie boolean
---@field remain number
---@field updateTime number
---@field expireTime number

---@type table<string, LocomotiveData>
local playerData = {}

---@type table<string, true>
local requestQueue = {}

local function HandleTooltip(tooltip, name)
    local data = MSN:GetLocomotiveData(name)
    if not IsShiftKeyDown() then return end

    if not data then
        tooltip:AddDoubleLine('帐号类型', '未知', nil, nil, nil, 1, 1, 1)
    elseif data.isNewbie then
        tooltip:AddDoubleLine('帐号类型', '新兵', nil, nil, nil, 163 / 255, 215 / 255, 138 / 255)
    else
        tooltip:AddDoubleLine('帐号类型', '老兵', nil, nil, nil, 255 / 255, 147 / 255, 126 / 255)
    end

    tooltip:Show()
end

local function HandleUnitTooltip(tooltip)
    if tooltip ~= _G.GameTooltip then return end
    if not tooltip or tooltip:IsForbidden() or not tooltip.NumLines or tooltip:NumLines() == 0 then return end

    local tooltipData = tooltip:GetPrimaryTooltipData()
    local guid = tooltipData.guid
    if not guid or issecretvalue(guid) then return end

    local unitID = UnitTokenFromGUID(guid)
    if not unitID or issecretvalue(unitID) then return end

    local isPlayer = UnitIsPlayer(unitID)
    if not isPlayer then return end

    local name, realm = UnitName(unitID)
    local fullName = name and (name .. '-' .. (realm or E.myrealm))
    if not fullName or issecretvalue(fullName) then return end

    HandleTooltip(tooltip, fullName)
end

local function HandleApplicantTooltip(self)
    local parent = self:GetParent()
    local applicantID = parent and parent.applicantID
    local memberIdx = self.memberIdx
    if not applicantID or not memberIdx then return end

    local name = C_LFGList_GetApplicantMemberInfo(applicantID, memberIdx)
    if not name then return end

    HandleTooltip(_G.GameTooltip, name)
end

local function HandleSearchTooltip(self)
    local resultID = self.resultID
    if not resultID then return end

    local searchResultData = C_LFGList_GetSearchResultInfo(resultID)
    if not searchResultData then return end

    local leaderName = searchResultData.leaderName
    if not leaderName then return end

    HandleTooltip(_G.GameTooltip, leaderName)
end

function MSN:GetLocomotiveData(playerName)
    local playerFullName = playerName
    if not string_find(playerFullName, '-') then
        playerFullName = playerFullName .. '-' .. E.myrealm
    end

    if not playerData[playerFullName] then
        requestQueue[playerFullName] = true
        return
    end

    local now = GetTime()
    if playerData[playerFullName].expireTime < now then
        playerData[playerFullName] = nil
        requestQueue[playerFullName] = true
        return
    end

    return playerData[playerFullName]
end

function MSN:FlushRequestQueue()
    if not self.target then return end

    local data = {}
    for playerFullName in pairs(requestQueue) do
        table_insert(data, playerFullName)
    end

    if #data > 0 then
        self:SendCommMessage(self.prefix, self:Serialize('CQGLIB', table_concat(data, ',')), 'WHISPER', self.target)
    end
end

function MSN:ConnectServer()
    self:SendCommMessage(self.prefix, self:Serialize('NETEASE_CONNECT', self.connectKey), 'WHISPER', self.connectTarget)
end

function MSN:OnCommReceived(prefix, text, _, sender)
    if prefix ~= self.prefix then return end

    local ok, cmd, payload = self:Deserialize(text)
    if not ok then return end

    if cmd == 'NETEASE_CONNECT_SUCCESS' then
        if self.connectKey == payload then
            self:CancelTimer(self.retryConnectServerTimer)
            self.retryConnectServerTimer = nil

            self.target = sender
        end
        return
    end

    if sender ~= self.target and sender ~= self.connectTarget then return end

    if cmd == 'SQGLIB' then
        local now = GetTime()

        for playerFullName, data in pairs(payload) do
            local newbieFlag = data['n'] or 0
            local remainCount = data['r'] or 0

            local isNewbie = newbieFlag == 1
            local expireTime = now + (isNewbie and (remainCount * 30 * 60) or (24 * 60 * 60))

            playerData[playerFullName] = {
                isNewbie = isNewbie,
                remain = remainCount,
                updateTime = now,
                expireTime = expireTime,
            }

            requestQueue[playerFullName] = nil
        end
    end
end

function MSN:LFG_LIST_APPLICANT_LIST_UPDATED()
    local applicants = C_LFGList_GetApplicants()
    for _, applicantID in ipairs(applicants) do
        local applicantData = C_LFGList_GetApplicantInfo(applicantID)
        for memberIndex = 1, applicantData.numMembers do
            local name = C_LFGList_GetApplicantMemberInfo(applicantID, memberIndex)
            if name then
                self:GetLocomotiveData(name)
            end
        end
    end

    self:FlushRequestQueue()
end

function MSN:Initialize()
    if E:IsAddOnEnabled('MeetingStone') then return end

    local realmNames = C_AutoComplete_GetAutoCompleteRealms()
    local realmName = realmNames and realmNames[1] or E.myrealm

    self.prefix = 'NERB'
    self.connectTarget = 'S1' .. E.myfaction .. (realmName ~= E.myrealm and ('-' .. realmName) or '')
    self.connectKey = tostring(random(0x100000, 0xFFFFFF))

    self:RegisterComm(self.prefix, 'OnCommReceived')

    self:ConnectServer()
    self.retryConnectServerTimer = self:ScheduleRepeatingTimer('ConnectServer', 3)

    self:RegisterEvent('LFG_LIST_APPLICANT_LIST_UPDATED')
    self:ScheduleRepeatingTimer('FlushRequestQueue', 5)

    TooltipDataProcessor_AddTooltipPostCall(Enum_TooltipDataType_Unit, HandleUnitTooltip)
    self:SecureHook('LFGListApplicantMember_OnEnter', HandleApplicantTooltip)
    self:SecureHook('LFGListSearchEntry_OnEnter', HandleSearchTooltip)
end

R:RegisterModule(MSN:GetName())
