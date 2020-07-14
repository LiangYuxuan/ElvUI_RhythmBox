local R, E, L, V, P, G = unpack(select(2, ...))

-- Lua functions
local ipairs, loadstring, pairs, setfenv, tinsert, xpcall = ipairs, loadstring, pairs, setfenv, tinsert, xpcall

-- WoW API / Variables

-- GLOBALS: BINDING_HEADER_RHYTHM

BINDING_HEADER_RHYTHM = "|cFF70B8FFRhythm Box|r"

function R:Initialize()
    tinsert(E.ConfigModeLayouts, #(E.ConfigModeLayouts) + 1, 'RHYTHMBOX')
    E.ConfigModeLocalizedStrings['RHYTHMBOX'] = "|cFF70B8FFRhythm Box|r"

    self:ToolboxInitialize()
end
