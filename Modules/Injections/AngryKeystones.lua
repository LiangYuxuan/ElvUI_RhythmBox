local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G
local format, ipairs = format, ipairs

-- WoW API / Variables
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_MythicPlus_GetCurrentAffixes = C_MythicPlus.GetCurrentAffixes
local C_MythicPlus_GetOwnedKeystoneChallengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID
local C_MythicPlus_GetOwnedKeystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel
local C_MythicPlus_RequestMapInfo = C_MythicPlus.RequestMapInfo
local C_MythicPlus_RequestCurrentAffixes = C_MythicPlus.RequestCurrentAffixes

local ChatEdit_GetActiveWindow = ChatEdit_GetActiveWindow
local ChatEdit_InsertLink = ChatEdit_InsertLink
local ChatFrame_OpenChat = ChatFrame_OpenChat

local CHALLENGE_MODE_KEYSTONE_HYPERLINK = CHALLENGE_MODE_KEYSTONE_HYPERLINK
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

-- Good to have: Keystone, Schedule

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

-- the level that corresponding affix should take place
local affixLevel = {2, 4, 7, 10}

local function SendCurrentKeystone(self)
    local keystoneMapID, keystoneLevel = RI:GetModifiedKeystone()

	local message = '0'
	if keystoneMapID and keystoneLevel then
		message = format('%d:%d', keystoneMapID, keystoneLevel)
	end

	self:SendAddOnComm(message, 'PARTY')
end

function RI:AngryKeystones_Update()
    _G.AngryKeystones.Schedule:SendCurrentKeystone()
end

function RI:InsertChatLink()
    local keystoneMapID, keystoneLevel = RI:GetModifiedKeystone()

    if keystoneMapID and keystoneLevel then
        local affix = ""
        local affixes = C_MythicPlus_GetCurrentAffixes()
        for index, tbl in ipairs(affixes) do
            if affixLevel[index] > keystoneLevel then break end
            affix = affix .. ":" .. tbl.id
        end

        local itemLink = format("|cffa335ee|Hkeystone:158923:%d:%d%s|h[" .. CHALLENGE_MODE_KEYSTONE_HYPERLINK .. "]|h|r",
            keystoneMapID, keystoneLevel, affix, C_ChallengeMode_GetMapUIInfo(keystoneMapID), keystoneLevel
        )
        if ChatEdit_GetActiveWindow() then
            ChatEdit_InsertLink(itemLink)
        else
            ChatFrame_OpenChat(itemLink, DEFAULT_CHAT_FRAME)
        end
    end
end

function RI:GetModifiedKeystone()
    return E.db.RhythmBox.Injections.AngryKeystones.ChallengeMapID > 0 and
        E.db.RhythmBox.Injections.AngryKeystones.ChallengeMapID or C_MythicPlus_GetOwnedKeystoneChallengeMapID(),
        E.db.RhythmBox.Injections.AngryKeystones.Level > 0 and
        E.db.RhythmBox.Injections.AngryKeystones.Level or C_MythicPlus_GetOwnedKeystoneLevel()
end

function RI:AngryKeystones()
    _G.AngryKeystones.Schedule.SendCurrentKeystone = SendCurrentKeystone

    C_MythicPlus_RequestMapInfo()
    C_MythicPlus_RequestCurrentAffixes()
end

RI:RegisterInjection(RI.AngryKeystones, 'AngryKeystones')
