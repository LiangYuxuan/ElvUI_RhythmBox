local R, E, L, V, P, G = unpack(select(2, ...))
local C = E:GetModule('RhythmBox_Chat')

local handleMessageGroup = {'SAY', 'YELL', 'EMOTE'}

function C:UpdateFilter()
    local func = IsResting() and ChatFrame_RemoveMessageGroup or ChatFrame_AddMessageGroup
    for _, v in ipairs(handleMessageGroup) do
        func(ChatFrame1, v)
    end
end

function C:HandleAD()
    if E.db.RhythmBox.chat.adFilter then
        self:UpdateFilter()
        self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateFilter')
        self:RegisterEvent('PLAYER_UPDATE_RESTING', 'UpdateFilter')
    else
        self:UnregisterAllEvents()
        for _, v in ipairs(handleMessageGroup) do
            ChatFrame_AddMessageGroup(ChatFrame1, v)
        end
    end
end
