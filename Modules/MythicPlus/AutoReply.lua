local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:GetModule('MythicPlus')

-- Lua functions
local format, next, pairs, wipe = format, next, pairs, wipe

-- WoW API / Variables
local Ambiguate = Ambiguate
local BNGetFriendIndex = BNGetFriendIndex
local BNIsSelf = BNIsSelf
local BNSendWhisper = BNSendWhisper
local C_BattleNet_GetGameAccountInfoByGUID = C_BattleNet.GetGameAccountInfoByGUID
local C_BattleNet_GetFriendGameAccountInfo = C_BattleNet.GetFriendGameAccountInfo
local C_BattleNet_GetFriendNumGameAccounts = C_BattleNet.GetFriendNumGameAccounts
local C_FriendList_IsFriend = C_FriendList.IsFriend
local GetTime = GetTime
local IsGuildMember = IsGuildMember
local SendChatMessage = SendChatMessage
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid

local throttle = {}
local throttleBN = {}

function MP:SendCompletedMessage()
    if not self.currentRun then return end
    if not next(throttle) and not next(throttleBN) then return end

    local replyString = format(
        '已完成史诗钥石 +%d %s %s/%s',
        self.currentRun.level, self.currentRun.mapName,
        self:FormatTime(self:GetElapsedTime() or 0), self:FormatTime(self.currentRun.timeLimit)
    )

    for sender in pairs(throttle) do
        SendChatMessage(replyString, 'WHISPER', nil, sender)
    end

    for bnSenderID in pairs(throttleBN) do
        BNSendWhisper(bnSenderID, replyString)
    end

    wipe(throttle)
    wipe(throttleBN)
end

function MP:GetReplyString()
    if not self.currentRun or not self.currentRun.inProgress then return end

    local bossKilled = 0
    for _, value in pairs(self.currentRun.bossStatus) do
        if value then
            bossKilled = bossKilled + 1
        end
    end

    return format(
        '正在进行史诗钥石 +%d %s %s/%s 已击败首领%d/%d 敌方部队%.0f%%',
        self.currentRun.level, self.currentRun.mapName,
        self:FormatTime(self:GetElapsedTime() or 0), self:FormatTime(self.currentRun.timeLimit),
        bossKilled, #self.currentRun.bossName,
        self.currentRun.enemyCurrent / self.currentRun.enemyTotal * 100
    )
end

function MP:CHAT_MSG_WHISPER(_, _, sender, _, _, _, flag, _, _, _, _, _, guid)
    if flag == 'GM' or flag == 'DEV' then return end

    local currTime = GetTime()
    if throttle[sender] and currTime - throttle[sender] < 60 then return end

    if (
        not C_BattleNet_GetGameAccountInfoByGUID(guid) and
        not IsGuildMember(guid) and
        not C_FriendList_IsFriend(guid)
    ) then
        return
    end

    local trimmedPlayer = Ambiguate(sender, 'none')
    if UnitInRaid(trimmedPlayer) or UnitInParty(trimmedPlayer) then return end

    local replyString = self:GetReplyString()
    if not replyString then return end

    throttle[sender] = currTime
    SendChatMessage(replyString, 'WHISPER', nil, sender)
end

function MP:CHAT_MSG_BN_WHISPER(_, _, _, _, _, _, _, _, _, _, _, _, _, bnSenderID)
    if BNIsSelf(bnSenderID) then return end

    local currTime = GetTime()
    if throttleBN[bnSenderID] and currTime - throttleBN[bnSenderID] < 60 then return end

    local index = BNGetFriendIndex(bnSenderID)
    local numGameAccounts = C_BattleNet_GetFriendNumGameAccounts(index)
    for i = 1, numGameAccounts do
        local gameAccountInfo = C_BattleNet_GetFriendGameAccountInfo(index, i)
        if (
            gameAccountInfo and gameAccountInfo.clientProgram == 'WoW' and
            gameAccountInfo.realmName and gameAccountInfo.characterName
        ) then
            local playerName = gameAccountInfo.characterName
            if gameAccountInfo.realmName ~= E.myrealm then
                playerName = playerName .. '-' .. gameAccountInfo.realmName
            end
            if UnitInRaid(playerName) or UnitInParty(playerName) then
                return
            end
        end
    end

    local replyString = self:GetReplyString()
    if not replyString then return end

    throttleBN[bnSenderID] = currTime
    BNSendWhisper(bnSenderID, replyString)
end

function MP:UpdateAutoReply()
    if self.currentRun and self.currentRun.inProgress then
        self:RegisterEvent('CHAT_MSG_WHISPER')
        self:RegisterEvent('CHAT_MSG_BN_WHISPER')
    else
        self:UnregisterEvent('CHAT_MSG_WHISPER')
        self:UnregisterEvent('CHAT_MSG_BN_WHISPER')

        self:SendCompletedMessage()
    end
end

function MP:BuildAutoReply()
    self:RegisterSignal('CHALLENGE_MODE_START', 'UpdateAutoReply')
    self:RegisterSignal('CHALLENGE_MODE_COMPLETED', 'UpdateAutoReply')
end
