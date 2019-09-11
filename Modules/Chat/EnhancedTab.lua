local R, E, L, V, P, G = unpack(select(2, ...))

-- Lua functions
local pairs, strsub, tostring = pairs, strsub, tostring

-- WoW API / Variables
local CanEditOfficerNote = CanEditOfficerNote
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local IsInGuild = IsInGuild
local IsInGroup = IsInGroup
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local IsShiftKeyDown = IsShiftKeyDown

local ChatEdit_UpdateHeader = ChatFrame_AddMessageGroup

local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE

-- GLOBALS: ChatEdit_CustomTabPressed

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
                local curr = index + step
                while true do
                    if curr == 0 then
                        curr = length
                    elseif curr > length then
                        curr = 1
                    end
                    if typeCycle[curr].allowFunc() then
                        self:SetAttribute('chatType', typeCycle[curr].chatType);
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
