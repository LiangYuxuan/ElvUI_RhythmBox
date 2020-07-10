local R, E, L, V, P, G = unpack(select(2, ...))
local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G

-- WoW API / Variables

function RI:WowLua()
    _G.WowLuaFrameOutput:FontTemplate(nil, 14, '')
end

RI:RegisterInjection(RI.WowLua, 'WowLua')
