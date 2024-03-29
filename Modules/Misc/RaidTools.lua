local R, E, L, V, P, G = unpack((select(2, ...)))
local RT = R:NewModule('RaidTools', 'AceEvent-3.0', 'AceTimer-3.0')
local RU = E:GetModule('RaidUtility')

-- Lua functions
local _G = _G
local print, select = print, select

-- WoW API / Variables
local C_ChatInfo_SendAddonMessage = C_ChatInfo.SendAddonMessage
local C_PartyInfo_DoCountdown = C_PartyInfo.DoCountdown
local GetInstanceInfo = GetInstanceInfo
local GetNumGroupMembers = GetNumGroupMembers
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local SendChatMessage = SendChatMessage
local UnitExists = UnitExists
local UnitIsEnemy = UnitIsEnemy
local UnitIsGroupAssistant = UnitIsGroupAssistant
local UnitIsGroupLeader = UnitIsGroupLeader
local UnitName = UnitName

local RaidWarningFrame_OnEvent = RaidWarningFrame_OnEvent

local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE

function RT:SmartChat(msg)
    if IsInRaid() then
        if UnitIsGroupLeader('player') or UnitIsGroupAssistant('player') then
            SendChatMessage(msg, 'RAID_WARNING')
        else
            SendChatMessage(msg, 'RAID')
        end
    elseif GetNumGroupMembers() > 1 then
        SendChatMessage(msg, IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and 'INSTANCE_CHAT' or 'PARTY')
    else
        RaidWarningFrame_OnEvent(_G.RaidWarningFrame, 'CHAT_MSG_RAID_WARNING', msg)
        print(msg)
    end
end

function RT:RepeatChat(firstMsg)
    if self.restTime == 0 then
        self:SmartChat(">>> 开始战斗 <<<")
        self.restTime = nil
        self:CancelTimer(self.timer)
        return
    end

    if firstMsg or self.restTime % 5 == 0 or self.restTime == 7 or self.restTime < 5 then
        self:SmartChat("战斗倒计时 " .. self.restTime .. " 秒")
    end
    self.restTime = self.restTime - 1
end

function RT:SendAddOnTimers(pullTime)
    local isInInstance = IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
    local isInParty = IsInGroup()
    local isInRaid = IsInRaid()
    local playerName = nil
    local chat_type = (isInInstance and 'INSTANCE_CHAT') or (isInRaid and 'RAID') or (isInParty and 'PARTY')
    if not chat_type then
        chat_type = 'WHISPER'
        playerName = UnitName('player')
    end
    local mapID = select(8, GetInstanceInfo())
    local targetName = (UnitExists('target') and UnitIsEnemy('player', 'target')) and UnitName('target') or nil
    C_ChatInfo_SendAddonMessage('BigWigs', 'P^Pull^' .. pullTime, chat_type, playerName)
    if targetName then
        C_ChatInfo_SendAddonMessage('D4', ('PT\t%d\t%d\t%s'):format(pullTime, mapID or -1, targetName), chat_type, playerName)
    else
        C_ChatInfo_SendAddonMessage('D4', ('PT\t%d\t%d'):format(pullTime, mapID or -1), chat_type, playerName)
    end
end

function RT:GetTimeToPull()
    local _, instanceType, difficultyID = GetInstanceInfo()
    if difficultyID == 8 then
        return 3
    elseif instanceType == 'party' then
        return 7
    else
        return 7
    end
end

function RT:Initialize()
    _G.RaidUtility_RaidCountdownButton:SetScript('OnMouseUp', function()
        if RU:CheckRaidStatus() then
            if RT.restTime then
                -- Cancel Pull Timer
                RT.restTime = nil
                C_PartyInfo_DoCountdown(0)
                RT:SendAddOnTimers(0)
                if E.db.RhythmBox.Misc.PullTimerSendToChat then
                    RT:CancelTimer(RT.timer)
                    RT:SmartChat(">>> 取消 <<<")
                end
            else
                -- Launch Pull Timer
                RT.restTime = RT:GetTimeToPull()
                C_PartyInfo_DoCountdown(RT.restTime)
                RT:SendAddOnTimers(RT.restTime)
                if E.db.RhythmBox.Misc.PullTimerSendToChat then
                    RT.timer = RT:ScheduleRepeatingTimer('RepeatChat', 1)
                    RT:RepeatChat(true)
                end
            end
        end
    end)

    RU.CheckRaidStatus = function()
        if (UnitIsGroupLeader('player') or UnitIsGroupAssistant('player')) or (IsInGroup() and not IsInRaid()) then
            local _, instanceType = GetInstanceInfo()
            return instanceType ~= 'pvp' and instanceType ~= 'arena'
        end
    end
end

R:RegisterModule(RT:GetName())
