local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:GetModule('MythicPlus')

-- Lua functions
local _G = _G
local ipairs = ipairs

-- WoW API / Variables
local C_Spell_RequestLoadSpellData = C_Spell.RequestLoadSpellData
local C_MythicPlus_GetRunHistory = C_MythicPlus.GetRunHistory
local CreateFrame = CreateFrame
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsSpellKnown = IsSpellKnown
local UnitName = UnitName

local SecondsToTime = SecondsToTime

local READY = READY
local SPELL_FAILED_NOT_KNOWN = SPELL_FAILED_NOT_KNOWN
local TELEPORT_TO_DUNGEON = TELEPORT_TO_DUNGEON

local DungeonButtonOnUpdate
local KeystoneButtonOnUpdate

local DungeonButtonOnEnter = function(self)
    _G.ChallengesDungeonIconMixin.OnEnter(self.parent)

    local GameTooltip = _G.GameTooltip

    local allRuns = C_MythicPlus_GetRunHistory(true, true)
    local weekRuns = C_MythicPlus_GetRunHistory(false, true)
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

    if IsSpellKnown(self.spellID) then
        local spellName = GetSpellInfo(self.spellID)
        local start, duration = GetSpellCooldown(self.spellID)

        GameTooltip:AddLine(' ')
        GameTooltip:AddLine(spellName or TELEPORT_TO_DUNGEON)

        if start == 0 then
            GameTooltip:AddLine(READY, 0, 1, 0)
        else
            GameTooltip:AddLine(SecondsToTime(start + duration - GetTime()), 1, 0, 0)

            self.elapsed = 5
            self:SetScript('OnUpdate', DungeonButtonOnUpdate)
        end
    else
        GameTooltip:AddLine(' ')
        GameTooltip:AddLine(TELEPORT_TO_DUNGEON)
        GameTooltip:AddLine(SPELL_FAILED_NOT_KNOWN, 1, 0, 0)
    end

    GameTooltip:Show()
end

local DungeonButtonOnLeave = function(self)
    self:SetScript('OnUpdate', nil)

    _G.GameTooltip:Hide()
end

DungeonButtonOnUpdate = function(self, elapsed)
    self.elapsed = self.elapsed - elapsed
    if self.elapsed > 0 then return end
    self.elapsed = 5

    DungeonButtonOnEnter(self)
end

local KeystoneButtonOnEnter = function(self)
    if not self.spellID then return end

    local GameTooltip = _G.GameTooltip

    GameTooltip:Hide()
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT', 0, -2)
    GameTooltip:ClearLines()

    if IsSpellKnown(self.spellID) then
        local spellName = GetSpellInfo(self.spellID)
        local start, duration = GetSpellCooldown(self.spellID)

        GameTooltip:AddLine(spellName or TELEPORT_TO_DUNGEON)

        if start == 0 then
            GameTooltip:AddLine(READY, 0, 1, 0)
        else
            GameTooltip:AddLine(SecondsToTime(start + duration - GetTime()), 1, 0, 0)

            self.elapsed = 5
            self:SetScript('OnUpdate', KeystoneButtonOnUpdate)
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

KeystoneButtonOnUpdate = function(self, elapsed)
    self.elapsed = self.elapsed - elapsed
    if self.elapsed > 0 then return end
    self.elapsed = 5

    KeystoneButtonOnEnter(self)
end

local buttons = {}

function MP:UpdatePortalButton()
    if InCombatLockdown() then return end

    for _, dungeonIcon in ipairs(_G.ChallengesFrame.DungeonIcons) do
        local mapID = dungeonIcon.mapID
        local spellID = self.database[mapID] and self.database[mapID][4]

        if spellID then
            if not buttons[dungeonIcon] then
                local button = CreateFrame('Button', nil, dungeonIcon, 'InsecureActionButtonTemplate')
                button:SetAllPoints(dungeonIcon)
                button:RegisterForClicks('AnyUp', 'AnyDown')
                button:SetAttribute('type', 'spell')
                button:SetAttribute('spell', spellID)
                button:SetScript('OnEnter', DungeonButtonOnEnter)
                button:SetScript('OnLeave', DungeonButtonOnLeave)

                button.parent = dungeonIcon

                buttons[dungeonIcon] = button
            end

            buttons[dungeonIcon].mapID = mapID
            buttons[dungeonIcon].spellID = spellID
            buttons[dungeonIcon]:SetAttribute('spell', spellID)

            C_Spell_RequestLoadSpellData(spellID)
        end
    end

    for index, entry in ipairs(self.partyEntry) do
        if not entry.button then
            local button = CreateFrame('Button', nil, entry, 'InsecureActionButtonTemplate')
            button:SetAllPoints(entry)
            button:RegisterForClicks('AnyUp', 'AnyDown')
            button:SetAttribute('type', 'spell')
            button:SetAttribute('spell', 0)
            button:SetScript('OnEnter', KeystoneButtonOnEnter)
            button:SetScript('OnLeave', KeystoneButtonOnLeave)

            entry.button = button
        end

        if index == 1 then
            local spellID = self.currentKeystoneMapID and self.database[self.currentKeystoneMapID] and self.database[self.currentKeystoneMapID][4]
            entry.button.spellID = spellID
            entry.button:SetAttribute('spell', spellID)
        else
            local name, realm = UnitName('party' .. (index - 1))
            if name then
                local fullName
                if not realm or realm == "" then
                    fullName = name .. '-' .. E.myrealm
                else
                    fullName = name .. '-' .. realm
                end

                if not self.unitKeystones[fullName] then
                    entry.button.spellID = nil
                    entry.button:SetAttribute('spell', nil)
                elseif self.unitKeystones[fullName] == 0 then
                    entry.button.spellID = nil
                    entry.button:SetAttribute('spell', nil)
                else
                    local mapID = self.unitKeystones[fullName][1]
                    local spellID = self.database[mapID] and self.database[mapID][4]
                    entry.button.spellID = spellID
                    entry.button:SetAttribute('spell', spellID)
                end
            end
        end
    end
end
