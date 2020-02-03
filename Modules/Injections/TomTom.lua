local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RI = R:GetModule('Injections')

-- Lua functions

-- WoW API / Variables

-- Good to have: Keystone, Schedule

local database = {
    [1527] = { -- Uldum
        {47, 34, 'Consuming Maw'},
        {47, 42, 'Spirit Drinker'},
        {51, 88, 'Summoning Ritual'},
        {67, 68, 'Executor of N\'Zoth'},
        {59, 47, 'Executor of N\'Zoth'},
        {54, 76, 'Call of the Void'},
    },
    [1530] = { -- Vale
        {17, 46, 'Stormchosen Arena'},
        {23, 37, 'Empowered Demolisher'},
        {31, 29, 'Baruk Obliterator'},
        {22, 24, 'Construction Ritual (Underground Right)'},
        {20, 13, 'Goldbough Guardian'},
        {48, 22, 'Zan\'Ti Serpent Cage'},
    },
}

function RI:AddWaypoints()
    for mapFile, points in pairs(database) do
        for _, point in ipairs(points) do
            local x, y, eventTitle = unpack(point)
            _G.TomTom:AddWaypoint(mapFile, x / 100, y / 100, { title = eventTitle })
        end
    end
end

function RI:TomTom()
    StaticPopupDialogs["TOMTOM_REMOVE_ALL_CONFIRM"].OnAccept() -- reset all waypoints
    -- self:AddWaypoints()
end

-- RI:RegisterInjection(RI.TomTom, 'TomTom')
