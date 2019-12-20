local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G
local format = format

-- WoW API / Variables
local C_MythicPlus_GetOwnedKeystoneChallengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID
local C_MythicPlus_GetOwnedKeystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel
local C_MythicPlus_RequestMapInfo = C_MythicPlus.RequestMapInfo

-- Good to have: Keystone, Schedule
-- Angry Keystones WTF!!!
-- From wowhead, this is correct!
--[[
local affixScheduleText = {
	{"Fortified", "Bolstering", "Grievous"},
	{"Tyrannical", "Raging", "Explosive"},
	{"Fortified", "Sanguine", "Grievous"},
	{"Tyrannical", "Teeming", "Volcanic"},
	{"Fortified", "Bolstering", "Skittish"},
	{"Tyrannical", "Bursting", "Necrotic"},
	{"Fortified", "Sanguine", "Quaking"},
	{"Tyrannical", "Bolstering", "Explosive"},
	{"Fortified", "Bursting", "Volcanic"},
	{"Tyrannical", "Raging", "Necrotic"},
	{"Fortified", "Teeming", "Quaking"},
	{"Tyrannical", "Bursting", "Skittish"},
}
]]--

RI.ChallengeMapIDs = {
    -- MOP
    2,   -- Temple of the Jade Serpent
    56,  -- Stormstout Brewery
    57,  -- Gate of the Setting Sun
    58,  -- Shado-Pan Monastery
    59,  -- Siege of Niuzao Temple
    60,  -- Mogu'shan Palace
    76,  -- Scholomance
    77,  -- Scarlet Halls
    78,  -- Scarlet Monastery

    -- WoD
    161, -- Skyreach
    163, -- Bloodmaul Slag Mines
    164, -- Auchindoun
    165, -- Shadowmoon Burial Grounds
    166, -- Grimrail Depot
    167, -- Upper Blackrock Spire
    168, -- The Everbloom
    169, -- Iron Docks

    -- LEG
    197, -- Eye of Azshara
    198, -- Darkheart Thicket
    199, -- Black Rook Hold
    200, -- Halls of Valor
    206, -- Neltharion's Lair
    207, -- Vault of the Wardens
    208, -- Maw of Souls
    209, -- The Arcway
    210, -- Court of Stars
    227, -- Return to Karazhan: Lower
    233, -- Cathedral of Eternal Night
    234, -- Return to Karazhan: Upper
    239, -- Seat of the Triumvirate

    -- BfA
    244, -- Atal'Dazar
    245, -- Freehold
    246, -- Tol Dagor
    247, -- The MOTHERLODE!!
    248, -- Waycrest Manor
    249, -- Kings' Rest
    250, -- Temple of Sethraliss
    251, -- The Underrot
    252, -- Shrine of the Storm
    353, -- Siege of Boralus
    -- 369, -- Operation: Mechagon - Junkyard
    -- 370, -- Operation: Mechagon - Workshop
}

local function SendCurrentKeystone(self)
    local keystoneMapID = E.db.RhythmBox.Injections.AngryKeystones.ChallengeMapID > 0 and
        E.db.RhythmBox.Injections.AngryKeystones.ChallengeMapID or C_MythicPlus_GetOwnedKeystoneChallengeMapID()
	local keystoneLevel = E.db.RhythmBox.Injections.AngryKeystones.Level > 0 and
        E.db.RhythmBox.Injections.AngryKeystones.Level or C_MythicPlus_GetOwnedKeystoneLevel()

	local message = '0'
	if keystoneLevel and keystoneMapID then
		message = format('%d:%d', keystoneMapID, keystoneLevel)
	end

	self:SendAddOnComm(message, 'PARTY')
end

function RI:AngryKeystones_Update()
    _G.AngryKeystones.Schedule:SendCurrentKeystone()
end

function RI:AngryKeystones()
    _G.AngryKeystones.Schedule.SendCurrentKeystone = SendCurrentKeystone

    C_MythicPlus_RequestMapInfo()
end

RI:RegisterInjection(RI.AngryKeystones, 'AngryKeystones')
