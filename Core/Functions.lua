local R, E, L, V, P, G = unpack(select(2, ...))

-- Lua functions
local _G = _G

-- WoW API / Variables

function R:Print(...)
    _G.DEFAULT_CHAT_FRAME:AddMessage("|cFF70B8FFElvUI Rhythm Box:|r ", ...)
end
