local R, E, L, V, P, G = unpack((select(2, ...)))
local C = R:GetModule('Chat')

-- Lua functions
local _G = _G
local ipairs = ipairs

-- WoW API / Variables
local IsResting = IsResting

local handleMessageGroup = {'SAY', 'YELL', 'EMOTE'}

function C:UpdateFilter()
    local isResting = IsResting()
    if isResting then
        for _, v in ipairs(handleMessageGroup) do
            _G.ChatFrame1:RemoveMessageGroup(v)
        end
    else
        for _, v in ipairs(handleMessageGroup) do
            _G.ChatFrame1:AddMessageGroup(v)
        end
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
            _G.ChatFrame1:AddMessageGroup(v)
        end
    end
end

C:RegisterPipeline(C.ADFilter)
