local R, E, L, V, P, G = unpack(select(2, ...))

-- Lua functions
local ipairs, loadstring, pairs, setfenv, tinsert, xpcall = ipairs, loadstring, pairs, setfenv, tinsert, xpcall

-- WoW API / Variables

-- GLOBALS: BINDING_HEADER_RHYTHM

BINDING_HEADER_RHYTHM = "|cFF70B8FFRhythm Box|r"

local reloadSetting = {
    ['E.private.skins.parchmentRemover.enable'] = 'true',
    ['E.private.general.chatBubbles'] = '"disabled"',
}

local restartSetting = {
    ['E.private.general.dmgfont'] = '"GothamNarrowUltra"',
    ['E.private.general.namefont'] = '"Naowh"',
}

function R:PrivateSettings()
    local reloadRequired, restartRequired
    local env = { E = E }

    for index, setting in ipairs({reloadSetting, restartSetting}) do
        for var, value in pairs(setting) do
            local func, err = loadstring('return ' .. var .. ' == ' .. value)
            if err then
                R.ErrorHandler(err)
            else
                setfenv(func, env)
                local status, result = xpcall(func, R.ErrorHandler)
                if status and not result then
                    local func, err = loadstring(var .. ' = ' .. value)
                    if err then
                        R.ErrorHandler(err)
                    else
                        setfenv(func, env)
                        local status = xpcall(func, R.ErrorHandler)
                        if status then
                            R:Print("已设定 %s 为 %s 。", var, value)
                            if index == 1 then
                                reloadRequired = true
                            else
                                restartRequired = true
                            end
                        end
                    end
                end
            end
        end
    end

    if restartRequired then
        R:Print("以上设定需要重新启动游戏才生效。")
    elseif reloadRequired then
        R:Print("以上设定需要重新加载界面才成效。")
    end
end

function R:Initialize()
    tinsert(E.ConfigModeLayouts, #(E.ConfigModeLayouts) + 1, 'RHYTHMBOX')
    E.ConfigModeLocalizedStrings['RHYTHMBOX'] = "|cFF70B8FFRhythm Box|r"

    self:PrivateSettings()

    self:ToolboxInitialize()
end
