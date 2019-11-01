local R, E, L, V, P, G = unpack(select(2, ...))
local C = R:GetModule('Chat')

-- Lua functions
local pairs, strsub, tostring = pairs, strsub, tostring

-- WoW API / Variables
local C_GuildInfo_CanEditOfficerNote = C_GuildInfo.CanEditOfficerNote
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local IsInGuild = IsInGuild
local IsInGroup = IsInGroup
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local IsShiftKeyDown = IsShiftKeyDown

local ChatEdit_UpdateHeader = ChatEdit_UpdateHeader

local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE

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
        allowFunc = function() return E.db.RhythmBox.Chat.UseOfficer and C_GuildInfo_CanEditOfficerNote() end,
    },
}

function C:ChatEdit_CustomTabPressed(editBox)
    if strsub(tostring(editBox:GetText()), 1, 1) == '/' then return end

    local chatType = editBox:GetAttribute('chatType')
    if chatType == 'CHANNEL' then
        editBox:SetAttribute('chatType', 'SAY')
        ChatEdit_UpdateHeader(editBox)
    elseif chatType == 'WHISPER' then
        if not E.db.RhythmBox.Chat.WhisperCycle then
            editBox:SetAttribute('chatType', 'SAY')
            ChatEdit_UpdateHeader(editBox)
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
                        editBox:SetAttribute('chatType', typeCycle[curr].chatType)
                        ChatEdit_UpdateHeader(editBox)
                        break
                    end
                    curr = curr + step
                end
                break
            end
        end
    end
end

function C:EnhancedTab()
    if E.db.RhythmBox.Chat.EnhancedTab then
        self:RawHook('ChatEdit_CustomTabPressed', true)
    elseif self.hooking then
        self:Unhook('ChatEdit_CustomTabPressed')
    end
end
