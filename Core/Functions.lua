local R, E, L, V, P, G = unpack(select(2, ...))

-- Lua functions
local _G = _G
local format, strmatch, tonumber, type = format, strmatch, tonumber, type

-- WoW API / Variables

function R:Print(...)
    _G.DEFAULT_CHAT_FRAME:AddMessage("|cFF70B8FFElvUI Rhythm Box:|r " .. format(...))
end

function R:Debug(object, descText)
    if _G.ViragDevTool_AddData then
        _G.ViragDevTool_AddData(object, descText or "RB Debug")
    else
        E:Dump(object, type(object) == 'table')
    end
end

function R:ParseNPCID(unitGUID)
    return tonumber(strmatch(unitGUID or '', 'Creature%-.-%-.-%-.-%-.-%-(.-)%-') or '')
end
