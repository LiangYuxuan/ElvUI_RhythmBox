local R, E, L, V, P, G = unpack(select(2, ...))
local ATM = R:NewModule('AutoTankMisdirect', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local format = format

-- WoW API / Variables
local CreateFrame = CreateFrame
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetSpellInfo = GetSpellInfo
local GetSpellLink = GetSpellLink
local InCombatLockdown = InCombatLockdown
local IsInRaid = IsInRaid
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitGUID = UnitGUID
local UnitName = UnitName

local UNKNOWN = UNKNOWN

local button, spellID, spellName, lastTank
local template = '/cast [target=%s,exists][help,raid][target=targettarget,help,raid][] %s'

function ATM:UpdateMacro(unitID)
    if not spellName then
        spellName = GetSpellInfo(spellID)
        if not spellName then
            R.ErrorHandler("Unknown Spell " .. spellID)

            self:ScheduleTimer('FindTank', 1)
            return
        end
    end

    button:SetAttribute('macrotext', format(template, unitID, spellName))

    local unitGUID = UnitGUID(unitID)
    if not lastTank or lastTank ~= unitGUID then
        lastTank = unitGUID

        local spellLink = GetSpellLink(spellID)
        R:Print("自动误导：%s选择目标%s(%s)", spellLink, UnitName(unitID) or UNKNOWN, unitID)
    end
end

function ATM:FindTank()
    if InCombatLockdown() then
        self:RegisterEvent('PLAYER_REGEN_ENABLED', 'FindTank')
        return
    end

    self:UnregisterEvent('PLAYER_REGEN_ENABLED')

    local prefix = IsInRaid() and 'raid' or 'party'
    local length = prefix == 'party' and GetNumSubgroupMembers() or GetNumGroupMembers()
    local start = prefix == 'party' and 0 or 1
    for i = start, length do
        local unitID = (prefix == 'party' and i == 0) and 'player' or (prefix .. i)
        if UnitGroupRolesAssigned(unitID) == 'TANK' then
            self:UpdateMacro(unitID)
            return
        end
    end

    self:UpdateMacro('pet')
end

function ATM:Initialize()
    if E.myclass ~= 'HUNTER' and E.myclass ~= 'ROGUE' then return end

    spellID = E.myclass == 'HUNTER' and 34477 or 57934
    spellName = GetSpellInfo(spellID)
    button = CreateFrame('Button', 'RhythmBoxAutoTankMisdirect', _G.UIParent, 'SecureActionButtonTemplate')
    button:SetAttribute('type', 'macro')

    self:RegisterEvent('GROUP_ROSTER_UPDATE', 'FindTank')

    self:FindTank()
end

R:RegisterModule(ATM:GetName())
