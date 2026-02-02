local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:GetModule('MythicPlus')

-- Lua functions
local _G = _G
local ipairs = ipairs

-- WoW API / Variables
local C_MythicPlus_GetRunHistory = C_MythicPlus.GetRunHistory
local C_Spell_GetSpellCooldown = C_Spell.GetSpellCooldown
local C_Spell_GetSpellName = C_Spell.GetSpellName
local C_Spell_RequestLoadSpellData = C_Spell.RequestLoadSpellData
local C_SpellBook_IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook
local CreateFrame = CreateFrame
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local UnitName = UnitName

local SecondsToTime = SecondsToTime

local NONE = NONE
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR
local READY = READY
local SPELL_FAILED_NOT_KNOWN = SPELL_FAILED_NOT_KNOWN
local TELEPORT_TO_DUNGEON = TELEPORT_TO_DUNGEON
local UNKNOWN = UNKNOWN

local DungeonButtonOnEnter = function(self)
    _G.ChallengesDungeonIconMixin.OnEnter(self.parent)

    local GameTooltip = _G.GameTooltip

    local allRuns = C_MythicPlus_GetRunHistory(true, true, true)
    local weekRuns = C_MythicPlus_GetRunHistory(false, true, true)
    local allRunsCount = 0
    local weekRunsCount = 0
    for _, run in ipairs(allRuns) do
        if run.mapChallengeModeID == self.mapID then
            allRunsCount = allRunsCount + 1
        end
    end
    for _, run in ipairs(weekRuns) do
        if run.mapChallengeModeID == self.mapID then
            weekRunsCount = weekRunsCount + 1
        end
    end

    GameTooltip:AddLine(' ')
    GameTooltip:AddLine("赛季")
    GameTooltip:AddLine(allRunsCount .. "次", 1, 1, 1)
    GameTooltip:AddLine(' ')
    GameTooltip:AddLine("本周")
    GameTooltip:AddLine(weekRunsCount .. "次", 1, 1, 1)
    GameTooltip:AddLine(' ')

    if C_SpellBook_IsSpellInSpellBook(self.spellID) then
        local spellName = C_Spell_GetSpellName(self.spellID)
        local cooldownInfo = C_Spell_GetSpellCooldown(self.spellID)

        GameTooltip:AddLine(spellName or TELEPORT_TO_DUNGEON)

        if cooldownInfo.duration == 0 and cooldownInfo.isEnabled then
            GameTooltip:AddLine(READY, 0, 1, 0)
        else
            GameTooltip:AddLine(SecondsToTime(cooldownInfo.startTime + cooldownInfo.duration - GetTime()), 1, 0, 0)
        end
    else
        GameTooltip:AddLine(TELEPORT_TO_DUNGEON)
        GameTooltip:AddLine(SPELL_FAILED_NOT_KNOWN, 1, 0, 0)
    end

    GameTooltip:Show()
end

local DungeonButtonOnLeave = function(self)
    self:SetScript('OnUpdate', nil)

    _G.GameTooltip:Hide()
end

local KeystoneButtonOnEnter = function(self)
    local GameTooltip = _G.GameTooltip

    GameTooltip:Hide()
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT', 0, -2)
    GameTooltip:ClearLines()

    if self.fullName then
        local keystoneData = MP:GetPartyMemberKeystoneAllSource(self.fullName)
        for _, source in ipairs(MP.KeystoneSources) do
            local mapID = keystoneData and keystoneData[source] and keystoneData[source].mapID
            local level = keystoneData and keystoneData[source] and keystoneData[source].level
            if not mapID then
                GameTooltip:AddDoubleLine(
                    source, UNKNOWN,
                    NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b,
                    1, 1, 1
                )
            elseif mapID == 0 then
                GameTooltip:AddDoubleLine(
                    source, NONE,
                    NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b,
                    1, 1, 1
                )
            else
                GameTooltip:AddDoubleLine(
                    source, MP:GetKeystoneText(mapID, level),
                    NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b,
                    1, 1, 1
                )
            end
        end

        GameTooltip:AddLine(' ')
    end

    if self.spellID and C_SpellBook_IsSpellInSpellBook(self.spellID) then
        local spellName = C_Spell_GetSpellName(self.spellID)
        local cooldownInfo = C_Spell_GetSpellCooldown(self.spellID)

        GameTooltip:AddLine(spellName or TELEPORT_TO_DUNGEON)

        if cooldownInfo.duration == 0 and cooldownInfo.isEnabled then
            GameTooltip:AddLine(READY, 0, 1, 0)
        else
            GameTooltip:AddLine(SecondsToTime(cooldownInfo.startTime + cooldownInfo.duration - GetTime()), 1, 0, 0)
        end
    else
        GameTooltip:AddLine(TELEPORT_TO_DUNGEON)
        GameTooltip:AddLine(SPELL_FAILED_NOT_KNOWN, 1, 0, 0)
    end

    GameTooltip:Show()
end

local KeystoneButtonOnLeave = function(self)
    self:SetScript('OnUpdate', nil)

    _G.GameTooltip:Hide()
end

---@type table<Frame, DungeonPortalButton>
local buttons = {}

function MP:UpdatePortalButton()
    if InCombatLockdown() then return end

    for _, dungeonIcon in ipairs(_G.ChallengesFrame.DungeonIcons) do
        local mapID = dungeonIcon.mapID
        local spellID = self.database[mapID] and self.database[mapID][4]

        if spellID then
            if not buttons[dungeonIcon] then
                ---@class DungeonPortalButton: Button
                ---@field parent Frame
                ---@field mapID number
                ---@field spellID number
                local button = CreateFrame('Button', nil, dungeonIcon, 'InsecureActionButtonTemplate')
                button:SetAllPoints(dungeonIcon)
                button:RegisterForClicks('AnyUp', 'AnyDown')
                button:SetAttribute('*type1', 'spell')
                button:SetAttribute('*spell1', spellID)
                button:SetScript('OnEnter', DungeonButtonOnEnter)
                button:SetScript('OnLeave', DungeonButtonOnLeave)

                button.parent = dungeonIcon

                buttons[dungeonIcon] = button
            end

            buttons[dungeonIcon].mapID = mapID
            buttons[dungeonIcon].spellID = spellID
            buttons[dungeonIcon]:SetAttribute('*spell1', spellID)

            C_Spell_RequestLoadSpellData(spellID)
        end
    end

    for index, entry in ipairs(self.partyEntry) do
        if not entry.button then
            ---@class PortalButton: Button
            ---@field spellID number|nil
            ---@field fullName string
            local button = CreateFrame('Button', nil, entry, 'InsecureActionButtonTemplate')
            button:SetAllPoints(entry)
            button:RegisterForClicks('AnyUp', 'AnyDown')
            button:SetAttribute('*type1', 'spell')
            button:SetScript('OnEnter', KeystoneButtonOnEnter)
            button:SetScript('OnLeave', KeystoneButtonOnLeave)

            entry.button = button
        end

        if index == 1 then
            local spellID = self.currentKeystoneMapID and self.database[self.currentKeystoneMapID] and self.database[self.currentKeystoneMapID][4]
            entry.button.spellID = spellID
            entry.button:SetAttribute('*spell1', spellID)
        else
            local name, realm = UnitName('party' .. (index - 1))
            if name then
                local fullName = name .. '-' .. (realm or E.myrealm)
                local mapID = self:GetPartyMemberKeystone(fullName)

                if not mapID then
                    entry.button.spellID = nil
                    entry.button:SetAttribute('*spell1', nil)
                elseif mapID == 0 then
                    entry.button.spellID = nil
                    entry.button:SetAttribute('*spell1', nil)
                else
                    local spellID = self.database[mapID] and self.database[mapID][4]
                    entry.button.spellID = spellID
                    entry.button:SetAttribute('*spell1', spellID)
                end

                entry.button.fullName = fullName
            end
        end
    end
end
