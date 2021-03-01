local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local TR = R:NewModule('Training', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local gsub, pairs, wipe = gsub, pairs, wipe

-- WoW API / Variables
local C_QuestLog_IsOnQuest = C_QuestLog.IsOnQuest
local ClearOverrideBindings = ClearOverrideBindings
local CreateFrame = CreateFrame
local GetPlayerAuraBySpellID = GetPlayerAuraBySpellID
local GetSpellInfo = GetSpellInfo
local InCombatLockdown = InCombatLockdown
local SetOverrideBinding = SetOverrideBinding

local C_Timer_After = C_Timer.After

local MESSAGE = 'Stand in circle and spam <8> to complete!'
local BUTTON = 'ACTIONBUTTON%d'
local trainerName = '训练师伊卡洛斯'

local actionBuff
local actionMessages = {}
local actionResetSpells = {}
local spells = {
    [321842] = {
        [321843] = 1, -- Strike
        [321844] = 2, -- Sweep
        [321847] = 3, -- Parry
    },
    [341925] = {
        [341931] = 1, -- Slash
        [341928] = 2, -- Bash
        [341929] = 3, -- Block
    },
    [341985] = {
        [342000] = 1, -- Jab
        [342001] = 2, -- Kick
        [342002] = 3, -- Dodge
    },
}

function TR:UNIT_SPELLCAST_SUCCEEDED(_, unitID, _, spellID)
    if unitID ~= 'player' then return end

    if actionResetSpells[spellID] then
        ClearOverrideBindings(self.frame)

        -- bind to something useless to avoid spamming jump
        SetOverrideBinding(self.frame, true, '8', BUTTON:format(4))
    end
end

function TR:CHAT_MSG_MONSTER_SAY(_, msg, sender)
    if sender ~= trainerName then return end

    local actionID = actionMessages[gsub(msg, '[%.。]', '')]
    if not actionID then return end

    C_Timer_After(.5, function()
        -- wait a split second to get "Perfect"
        ClearOverrideBindings(self.frame)
        SetOverrideBinding(self.frame, true, '8', BUTTON:format(actionID))
    end)
end

function TR:PLAYER_REGEN_ENABLED()
    ClearOverrideBindings(self.frame)
    self:UnregisterEvent('PLAYER_REGEN_ENABLED')
end

function TR:Message()
    for _ = 1, 2 do
        _G.UIErrorsFrame:AddMessage(E.InfoColor .. MESSAGE)
    end
end

function TR:Uncontrol()
    actionBuff = nil

    self:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED')
    self:UnregisterEvent('CHAT_MSG_MONSTER_SAY')

    if InCombatLockdown() then
        self:RegisterEvent('PLAYER_REGEN_ENABLED')
    else
        ClearOverrideBindings(self.frame)
    end
end

function TR:Control(buff, spellSet)
    if actionBuff == buff then return end

    wipe(actionMessages)
    wipe(actionResetSpells)
    for spellID, actionIndex in pairs(spellSet) do
        actionMessages[GetSpellInfo(spellID)] = actionIndex
        actionResetSpells[spellID] = true
    end

    -- bind to something useless to avoid spamming jump
    SetOverrideBinding(self.frame, true, '8', BUTTON:format(4))

    self:Message()

    self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
    self:RegisterEvent('CHAT_MSG_MONSTER_SAY')
end

function TR:UNIT_AURA(_, unitID)
    if unitID ~= 'player' then return end

    for buff, spellSet in pairs(spells) do
        local name = GetPlayerAuraBySpellID(buff)
        if name then
            return self:Control(buff, spellSet)
        end
    end

    self:Uncontrol()
end

function TR:Unwatch()
    self:UnregisterEvent('QUEST_REMOVED')
    self:UnregisterEvent('UNIT_AURA')
    self:Uncontrol()
end

function TR:Watch()
    self:RegisterEvent('QUEST_REMOVED')
    self:RegisterEvent('UNIT_AURA')
end

function TR:QUEST_REMOVED(_, questID)
    if questID == 59585 then
        self:Unwatch()
    end
end

function TR:QUEST_ACCEPTED(_, questID)
    if questID == 59585 then
        self:Watch()
    end
end

function TR:QUEST_LOG_UPDATE()
    if C_QuestLog_IsOnQuest(59585) then
        self:Watch()
    else
        self:Unwatch()
    end
end

function TR:Initialize()
    self.frame = CreateFrame('Frame')

    self:RegisterEvent('QUEST_LOG_UPDATE')
    self:RegisterEvent('QUEST_ACCEPTED')
end

R:RegisterModule(TR:GetName())
