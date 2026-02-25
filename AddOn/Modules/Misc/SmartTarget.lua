local R, E, L, V, P, G = unpack((select(2, ...)))
local ST = R:NewModule('SmartTarget', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local format, unpack = format, unpack

-- WoW API / Variables
local C_Spell_GetSpellLink = C_Spell.GetSpellLink
local C_Spell_GetSpellName = C_Spell.GetSpellName
local C_Spell_RequestLoadSpellData = C_Spell.RequestLoadSpellData
local CreateFrame = CreateFrame
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local InCombatLockdown = InCombatLockdown
local IsInRaid = IsInRaid
local UnitExists = UnitExists
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitName = UnitName

local UNKNOWN = UNKNOWN

local template = '/cast [target=%s, exists, nodead][help, raid, nodead][target=targettarget, help, raid, nodead][] %s'

local map = {
    ['HUNTER'] = {34477, 'TANK'}, -- Misdirection
    ['ROGUE']  = {57934, 'TANK'}, -- Tricks of the Trade
    ['DRUID']  = {29166, 'HEALER'}, -- Innervate
    ['EVOKER']  = {360827, 'TANK'}, -- Blistering Scales
}

function ST:UpdateMacro(unitID)
    if not self.spellName then
        self.spellName = C_Spell_GetSpellName(self.spellID)
        if not self.spellName then
            R.ErrorHandler("Unknown Spell " .. self.spellID)

            self:ScheduleTimer('FindTarget', 1)
            return
        end
    end

    self.button:SetAttribute('macrotext', format(template, unitID, self.spellName))

    if not UnitExists(unitID) and self.lastTarget then
        self.lastTarget = unitID

        local spellLink = C_Spell_GetSpellLink(self.spellID)
        R:Print("自动目标：%s选择缺省目标", spellLink)
    elseif self.lastTarget ~= unitID then
        self.lastTarget = unitID

        local spellLink = C_Spell_GetSpellLink(self.spellID)
        R:Print("自动目标：%s选择目标%s(%s)", spellLink, UnitName(unitID) or UNKNOWN, unitID)
    end
end

function ST:FindTarget(event)
    if InCombatLockdown() then
        self:RegisterEvent('PLAYER_REGEN_ENABLED', 'FindTarget')
        return
    end

    if event == 'PLAYER_REGEN_ENABLED' then
        self:UnregisterEvent('PLAYER_REGEN_ENABLED')
    end

    local prefix = IsInRaid() and 'raid' or 'party'
    local length = prefix == 'party' and GetNumSubgroupMembers() or GetNumGroupMembers()
    local start = prefix == 'party' and 0 or 1
    for i = start, length do
        local unitID = (prefix == 'party' and i == 0) and 'player' or (prefix .. i)
        if UnitGroupRolesAssigned(unitID) == self.targetRole then
            self:UpdateMacro(unitID)
            return
        end
    end

    self:UpdateMacro('pet')
end

function ST:Initialize()
    if not map[E.myclass] then return end

    C_Spell_RequestLoadSpellData(map[E.myclass][1])

    self.spellID, self.targetRole = unpack(map[E.myclass])

    self.button = CreateFrame('Button', 'RhythmBoxSmartTarget', _G.UIParent, 'SecureActionButtonTemplate')
    self.button:SetAttribute('type', 'macro')

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'FindTarget')
    self:RegisterEvent('GROUP_ROSTER_UPDATE', 'FindTarget')
end

R:RegisterModule(ST:GetName())
