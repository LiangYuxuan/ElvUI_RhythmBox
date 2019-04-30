local R, E, L, V, P, G = unpack(select(2, ...))
local C = R.Chat

local handleMessageGroup = {'SAY', 'YELL', 'EMOTE'}

function C:PLAYER_UPDATE_RESTING(restone)
    local func = (IsResting() and not restone) and ChatFrame_RemoveMessageGroup or ChatFrame_AddMessageGroup
    for _, v in ipairs(handleMessageGroup) do
        func(ChatFrame1, v)
    end
end

function C:HandleAD()
    if E.db.RhythmBox.chat.adFilter then
        self:RegisterEvent('PLAYER_UPDATE_RESTING')
    else
        self:UnregisterAllEvents()
    end
    self:PLAYER_UPDATE_RESTING(not E.db.RhythmBox.chat.adFilter)
end
