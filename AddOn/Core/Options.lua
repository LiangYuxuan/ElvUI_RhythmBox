local R, E, L, V, P, G = unpack((select(2, ...)))

-- Lua functions
local _G = _G
local ipairs, tinsert = ipairs, tinsert

-- WoW API / Variables

P["RhythmBox"] = {}
G["RhythmBox"] = {}

tinsert(E.ConfigModeLayouts, 'RHYTHMBOX')
E.ConfigModeLocalizedStrings['RHYTHMBOX'] = R.Title

local registeredOptions = {
    function()
        E.Options.args.RhythmBox = {
            order = 6,
            type = 'group',
            childGroups = 'tab',
            name = 'Rhythm Box',
            get = function(info) return E.db.RhythmBox.General[ info[#info] ] end,
            set = function(info, value) E.db.RhythmBox.General[ info[#info] ] = value; end,
            args = {
                InstallAll = {
                    order = 0.1,
                    type = 'execute',
                    name = "全部设置",
                    func = function()
                        R:GetModule('ActionBars'):InstallActionBars();
                        R:GetModule('Chat'):InstallChat();
                        R:GetModule('Misc'):ConfigCVar()
                    end,
                },
                DeveloperConsole = {
                    order = 0.2,
                    type = 'execute',
                    name = "显示/隐藏控制台",
                    func = function() _G.DeveloperConsole:Toggle() end,
                },
            },
        }
    end,
}

function R:RegisterOptions(callback)
    tinsert(registeredOptions, callback)
end

function R:PopulateOptions()
    for _, callback in ipairs(registeredOptions) do
        callback()
    end
end
