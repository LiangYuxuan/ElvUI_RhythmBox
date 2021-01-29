local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local LO = R:NewModule('Loh', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local pairs = pairs

-- WoW API / Variables
local C_QuestLog_IsOnQuest = C_QuestLog.IsOnQuest
local ClearOverrideBindings = ClearOverrideBindings
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local SetOverrideBinding = SetOverrideBinding
local UnitAura = UnitAura

local MESSAGE = 'Spam <8> to complete!'
local BUTTON = 'ACTIONBUTTON%d'

local quests = {
    [51632] = { -- Make Loh Go (Tiragarde Sound)
        [0] = {3, 2},
        [1] = {1, 2, 3, 2, 2},
        [2] = {1, 2, 1, 2, 2},
        [3] = {1, 2, 3, 2},
        [4] = {3, 2, 2, 2},
        [5] = {3, 2, 2},
        [6] = {3, 2, 1, 2, 2, 1, 2, 3, 2, 2},
    },
    [51633] = { -- Make Loh Go (Stormsong Valley)
        [0] = {3, 2},
        [1] = {1, 2, 3, 2, 2},
        [2] = {2, 1, 2, 2},
        [3] = {2, 2, 1, 2},
        [4] = {3, 2},
        [5] = {3, 2, 3, 2, 1, 2},
        [6] = {1, 2, 3, 2, 2},
        [7] = {3, 2, 1, 2, 2},
    },
    [51635] = { -- Make Loh Go (Vol'dun)
        [0] = {2, 3, 2, 3, 2, 1, 2, 1, 2},
        [1] = {1, 2, 3, 2},
        [2] = {1, 2},
        [3] = {2, 1, 2, 1, 2, 3, 2},
        [4] = {3, 2, 3, 2, 2, 2},
        [5] = {2, 2, 2, 2},
    },
    [51636] = { -- Make Loh Go (Zuldazar)
        [0] = {2, 2},
        [1] = {1, 2, 2, 1, 2},
        [2] = {2, 2},
        [3] = {1, 2, 2},
        [4] = {1, 2, 2, 2, 2},
        [5] = {2, 3, 2, 1, 2},
        [6] = {3, 2, 2},
        [7] = {2},
    },
}

local currentQuestID
local currentCheckpoint
local nextActionIndex

local actionSpells = {
    [271602] = true, -- 1: Turn Left
    [271600] = true, -- 2: Move Forward
    [271601] = true, -- 3: Turn Right
}

function LO:Next()
    local nextAction = quests[currentQuestID][currentCheckpoint][nextActionIndex]
    SetOverrideBinding(self.frame, true, '8', BUTTON:format(nextAction))
end

function LO:UpdateCheckpoint(_, unitID)
    if unitID ~= 'vehicle' then return end

    local checkpoint = self:GetCheckpoint()
    if checkpoint ~= currentCheckpoint then
        currentCheckpoint = checkpoint
        nextActionIndex = 1

        self:Next()
    end
end

function LO:GetCheckpoint()
    local index = 1
    while true do
        local name, _, count, _, _, _, _, _, _, spellID = UnitAura('vehicle', index, 'HARMFUL')
        if not name then
            return 0
        elseif spellID == 276705 then
            return count
        end

        index = index + 1
    end
end

function LO:UNIT_SPELLCAST_SUCCEEDED(_, unitID, _, spellID)
    if unitID ~= 'vehicle' then return end

    if actionSpells[spellID] then
        ClearOverrideBindings(self.frame)
        nextActionIndex = nextActionIndex + 1
        self:Next()
    end
end

function LO:PLAYER_REGEN_ENABLED()
    ClearOverrideBindings(self.frame)
    self:UnregisterEvent('PLAYER_REGEN_ENABLED')
end

function LO:Message()
    for _ = 1, 2 do
        _G.UIErrorsFrame:AddMessage(E.InfoColor .. MESSAGE)
    end
end

function LO:Uncontrol()
    currentCheckpoint = nil

    self:UnregisterEvent('UNIT_EXITED_VEHICLE')
    self:UnregisterEvent('UNIT_AURA')
    self:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED')

    if InCombatLockdown() then
        self:RegisterEvent('PLAYER_REGEN_ENABLED')
    else
        ClearOverrideBindings(self.frame)
    end
end

function LO:Control()
    self:Message()

    self:RegisterEvent('UNIT_EXITED_VEHICLE', 'Uncontrol')
    self:RegisterEvent('UNIT_AURA', 'UpdateCheckpoint')
    self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
end

function LO:Unwatch()
    currentQuestID = nil

    self:UnregisterEvent('QUEST_REMOVED')
    self:UnregisterEvent('UNIT_ENTERED_VEHICLE')
end

function LO:Watch(questID)
    currentQuestID = questID
    currentCheckpoint = nil

    self:RegisterEvent('QUEST_REMOVED')
    self:RegisterEvent('UNIT_ENTERED_VEHICLE', 'Control')
end

function LO:QUEST_REMOVED(_, questID)
    if quests[questID] then
        self:Unwatch()
    end
end

function LO:QUEST_ACCEPTED(_, questID)
    if quests[questID] then
        self:Watch(questID)
    end
end

function LO:QUEST_LOG_UPDATE()
    for questID in pairs(quests) do
        if C_QuestLog_IsOnQuest(questID) then
            self:Watch(questID)
            if self:GetCheckpoint() > 0 then
                self:Control()
                self:UpdateCheckpoint()
            end
            break
        end
    end

    self:UnregisterEvent('QUEST_LOG_UPDATE')
end

function LO:Initialize()
    self.frame = CreateFrame('Frame')

    self:RegisterEvent('QUEST_LOG_UPDATE')
    self:RegisterEvent('QUEST_ACCEPTED')
end

R:RegisterModule(LO:GetName())
