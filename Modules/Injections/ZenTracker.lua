local R, E, L, V, P, G = unpack(select(2, ...))
local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G

-- WoW API / Variables
local CreateFrame = CreateFrame
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local utilityMap = {
    [324739] = 1,
    [300728] = 2,
    [310143] = 3,
    [324631] = 4,
}

local abilityMap = {
    ['DEATHKNIGHT'] = {
        [315443] = 4,
        [312202] = 1,
        [311648] = 2,
        [324128] = 3,
    },
    ['DEMONHUNTER'] = {
        [306830] = 1,
        [329554] = 4,
        [323639] = 3,
        [317009] = 2,
    },
    ['DRUID'] = {
        [338142] = 1,
        [326462] = 1,
        [326446] = 1,
        [338035] = 1,
        [338018] = 1,
        [338411] = 1,
        [326434] = 1,
        [325727] = 4,
        [323764] = 3,
        [323546] = 2,
    },
    ['HUNTER'] = {
        [308491] = 1,
        [325028] = 4,
        [328231] = 3,
        [324149] = 2,
    },
    ['MAGE'] = {
        [307443] = 1,
        [324220] = 4,
        [314791] = 3,
        [314793] = 2,
    },
    ['MONK'] = {
        [310454] = 1,
        [325216] = 4,
        [327104] = 3,
        [326860] = 2,
    },
    ['PALADIN'] = {
        [304971] = 1,
        [328204] = 4,
        [328282] = 3,
        [328620] = 3,
        [328622] = 3,
        [328281] = 3,
        [316958] = 2,
    },
    ['PRIEST'] = {
        [325013] = 1,
        [324724] = 4,
        [327661] = 3,
        [323673] = 2,
    },
    ['ROGUE'] = {
        [323547] = 1,
        [328547] = 4,
        [328305] = 3,
        [323654] = 2,
    },
    ['SHAMAN'] = {
        [324519] = 1,
        [324386] = 1,
        [326059] = 4,
        [328923] = 3,
        [320674] = 2,
    },
    ['WARLOCK'] = {
        [312321] = 1,
        [325289] = 4,
        [325640] = 3,
        [321792] = 2,
    },
    ['WARRIOR'] = {
        [307865] = 1,
        [324143] = 4,
        [325886] = 3,
        [330334] = 2,
        [317349] = 2,
        [317488] = 2,
        [330325] = 2,
    },
}

local ZT

local function onEvent(_, event)
    if not ZT then
        ZT = _G.WeakAuras.LoadFunction('return function() return ZenTracker_AuraEnv end')()
    end

    if not ZT or not ZT.members then return end

    if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
        local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()

        if subEvent == 'SPELL_CAST_SUCCESS' and sourceGUID ~= E.myguid and ZT.members[sourceGUID] then
            local member = ZT.members[sourceGUID]
            local classFilename = member.class.name

            local covenantID =
                (classFilename and abilityMap[classFilename] and abilityMap[classFilename][spellID]) or utilityMap[spellID]
            if covenantID and covenantID ~= member.covenantID then
                local memberInfo = {
                    GUID = sourceGUID,
                    covenantID = covenantID,
                }
                ZT:addOrUpdateMember(memberInfo)
            end
        end
    end
end

function RI:WeakAuras()
    local eventFrame = CreateFrame('Frame')
    eventFrame:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
    eventFrame:SetScript('OnEvent', onEvent)
end

RI:RegisterInjection(RI.WeakAuras, 'WeakAuras')
