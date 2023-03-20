local R, E, L, V, P, G = unpack((select(2, ...)))
local MCC = R:NewModule('MiddleClickCast', 'AceEvent-3.0', 'AceHook-3.0')
local UF = E:GetModule('UnitFrames')

-- Lua functions
local format, type, unpack = format, type, unpack

-- WoW API / Variables
local GetSpellInfo = GetSpellInfo

local unitType = {
    player = true,
    party = true,
    raid1 = true,
    raid2 = true,
    raid3 = true,
}

-- [class] = {dispel, battleRez, rez}
local allClassSpells = {
    DEATHKNIGHT = {nil, 61999}, -- NONE, Raise Ally
    DRUID = {2782, 20484, 50769}, -- Remove Corruption, Rebirth, Revive
    EVOKER = {365585, nil, 361227}, -- Expunge, NONE, Return
    MAGE = {475}, -- Remove Curse
    MONK = {218164, nil, 115178}, -- Detox, NONE, Resuscitate
    PALADIN = {213644, 391054, 7328}, -- Cleanse Toxins, Intercession, Redemption
    PRIEST = {213634, nil, 2006}, -- Purify Disease, NONE, Resurrection
    SHAMAN = {51886, nil, 2008}, -- Cleanse Spirit, NONE, Ancestral Spirit
    WARLOCK = {'烧灼驱魔(恶魔掌控技能)', 20707}, -- NONE, Soulstone
}
local classSpell = allClassSpells[E.myclass]

function MCC:UpdateClicks(_, frame)
    if unitType[frame.unitframeType] and not frame.isChild then
        frame:SetAttribute('type3', 'macro')
        frame:SetAttribute('macrotext3', self.macroText)
    end
end

function MCC:Initialize()
    if not classSpell then return end

    local dispel, battleRez, rez = unpack(classSpell)
    local dispelName = dispel and (type(dispel) == 'number' and GetSpellInfo(dispel) or dispel)
    local battleRezName = battleRez and GetSpellInfo(battleRez)
    local rezName = rez and GetSpellInfo(rez)

    if dispel and battleRez and rez then
        local template = '/cast [@mouseover, nodead] %s; [@mouseover, dead, combat] %s; [@mouseover, dead, nocombat] %s'
        self.macroText = format(template, dispelName, battleRezName, rezName)
    elseif dispel and rez then
        local template = '/cast [@mouseover, nodead] %s; [@mouseover, dead, nocombat] %s'
        self.macroText = format(template, dispelName, rezName)
    elseif dispel and battleRez then
        local template = '/cast [@mouseover, nodead] %s; [@mouseover, dead] %s'
        self.macroText = format(template, dispelName, battleRezName)
    elseif dispel then
        local template = '/cast [@mouseover, nodead] %s'
        self.macroText = format(template, dispelName)
    elseif battleRez then
        local template = '/cast [@mouseover, dead] %s'
        self.macroText = format(template, battleRezName)
    -- else: no class with rez but without dispel
    end

    self:SecureHook(UF, 'RegisterForClicks', 'UpdateClicks')
end

R:RegisterModule(MCC:GetName())
