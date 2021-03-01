local R, E, L, V, P, G = unpack(select(2, ...))
local RI = R:GetModule('Injections')
local LDBI = LibStub('LibDBIcon-1.0')

-- Lua functions
local _G = _G

-- WoW API / Variables

function RI:Plater()
    local SMB = R:GetModule('MinimapButtons')
    tinsert(SMB.PartialIgnore, 'Plater')

    _G.PlaterDBChr.minimap = _G.PlaterDBChr.minimap or {}
    _G.PlaterDBChr.minimap.hide = true
    LDBI:Refresh('Plater', _G.PlaterDBChr.minimap)
end

RI:RegisterInjection(RI.Plater, 'Plater')
