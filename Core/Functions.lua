local R, E, L, V, P, G = unpack((select(2, ...)))

-- Lua functions
local _G = _G
local format, strmatch, tonumber, type = format, strmatch, tonumber, type

-- WoW API / Variables

function R:Print(...)
    _G.DEFAULT_CHAT_FRAME:AddMessage(R.Title .. ": " .. format(...))
end

function R:Debug(object, descText)
    if _G.DevTool and _G.DevTool.AddData then
        _G.DevTool:AddData(object, descText or "RB Debug")
    else
        E:Dump(object, type(object) == 'table')
    end
end

function R:ParseNPCID(unitGUID)
    return tonumber(strmatch(unitGUID or '', '%-(%d-)%-%x-$') or '')
end

do
    local registeredCallbacks = {}

    local eventFrame = CreateFrame('Frame')
    eventFrame:SetScript('OnEvent', function(self, _, addonName)
        if registeredCallbacks[addonName] then
            for _, data in ipairs(registeredCallbacks[addonName]) do
                xpcall(data[1], R.ErrorHandler, unpack(data, 2))
            end
            registeredCallbacks[addonName] = nil
        end
        if not next(registeredCallbacks) then
            eventFrame:UnregisterEvent('ADDON_LOADED')
        end
    end)

    function R:RegisterAddOnLoad(addonName, callback, ...)
        if C_AddOns.IsAddOnLoaded(addonName) then
            xpcall(callback, R.ErrorHandler, ...)
        else
            if not registeredCallbacks[addonName] then
                registeredCallbacks[addonName] = {}
            end
            tinsert(registeredCallbacks[addonName], { callback, ... })

            eventFrame:RegisterEvent('ADDON_LOADED')
        end
    end
end
