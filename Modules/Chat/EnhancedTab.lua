local R, E, L, V, P, G = unpack(select(2, ...))
local C = E:GetModule('RhythmBox_Chat')

-- WHISPER and CHANNEL are not in this cycle
-- use SAY as their next
local typeCycle = {
    {
        chatType = 'SAY',
        allowFunc = function() return true end,
    },
    {
        chatType = 'PARTY',
        allowFunc = function() return GetNumSubgroupMembers() > 0 end,
    },
    {
        chatType = 'INSTANCE_CHAT',
        allowFunc = function() return R.Retail and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and IsInInstance() end,
    },
    {
        chatType = 'BATTLEGROUND',
        allowFunc = function() return R.Retail and GetNumBattlefieldScores() > 0 end,
    },
    {
        chatType = 'RAID',
        allowFunc = function() return GetNumGroupMembers() > 0 and IsInRaid() end,
    },
    {
        chatType = 'GUILD',
        allowFunc = function() return IsInGuild() end,
    },
    {
        chatType = 'OFFICER',
        allowFunc = function() return E.db.RhythmBox.Chat.UseOfficer and CanEditOfficerNote() end,
    },
}

function ChatEdit_CustomTabPressed(self)
    if not E.db.RhythmBox.Chat.EnhancedTab then return end

    if strsub(tostring(self:GetText()), 1, 1) == '/' then return end

    local chatType = self:GetAttribute('chatType')
    if chatType == 'CHANNEL' then
        self:SetAttribute('chatType', 'SAY');
        ChatEdit_UpdateHeader(self);
    elseif chatType == 'WHISPER' then
        if not E.db.RhythmBox.Chat.WhisperCycle then
            self:SetAttribute('chatType', 'SAY');
            ChatEdit_UpdateHeader(self);
        end
    else
        local length = #typeCycle
        for index, tbl in pairs(typeCycle) do
            if chatType == tbl.chatType then
                local step = IsShiftKeyDown() and -1 or 1
                local curr = index + length
                local ending = curr + length * step
                curr = curr + step
                while curr ~= ending do
                    if typeCycle[mod(curr, length)].allowFunc() then
                        self:SetAttribute('chatType', typeCycle[mod(curr, length)].chatType);
                        ChatEdit_UpdateHeader(self);
                        break
                    end
                    curr = curr + step
                end
                break
            end
        end
    end
end