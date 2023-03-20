local R, E, L, V, P, G = unpack((select(2, ...)))
local C = R:GetModule('Chat')

-- Lua functions
local _G = _G
local ipairs = ipairs

-- WoW API / Variables
local IsResting = IsResting

local ChatFrame_AddMessageGroup = ChatFrame_AddMessageGroup
local ChatFrame_RemoveMessageGroup = ChatFrame_RemoveMessageGroup

local handleMessageGroup = {'SAY', 'YELL', 'EMOTE'}

function C:UpdateFilter()
    local func = IsResting() and ChatFrame_RemoveMessageGroup or ChatFrame_AddMessageGroup
    for _, v in ipairs(handleMessageGroup) do
        func(_G.ChatFrame1, v)
    end
end

function C:ADFilter()
    if E.db.RhythmBox.Chat.ADFilter then
        self:UpdateFilter()
        self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateFilter')
        self:RegisterEvent('PLAYER_UPDATE_RESTING', 'UpdateFilter')
    else
        self:UnregisterEvent('PLAYER_ENTERING_WORLD')
        self:UnregisterEvent('PLAYER_UPDATE_RESTING')
        for _, v in ipairs(handleMessageGroup) do
            ChatFrame_AddMessageGroup(_G.ChatFrame1, v)
        end
    end
end
