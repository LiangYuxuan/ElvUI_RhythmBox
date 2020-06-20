local R, E, L, V, P, G = unpack(select(2, ...))

-- Lua functions
local _G = _G

-- WoW API / Variables

P["RhythmBox"] = {}

local function CoreOptions()
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
            ZenTrackerRestart = {
                order = 0.3,
                type = 'execute',
                name = "重新加载ZenTracker",
                func = function()
                    local ZT = _G.WeakAuras.GetSanitizedGlobal('ZenTracker_AuraEnv')
                    local prefix = _G.IsInRaid() and 'raid' or 'party'
                    local length = prefix == 'party' and _G.GetNumSubgroupMembers() or _G.GetNumGroupMembers()
                    local start = prefix == 'party' and 0 or 1
                    for i = start, length do
                        local unitID = (prefix == 'party' and i == 0) and 'player' or (prefix .. i)
                        local unitGUID = _G.UnitGUID(unitID)
                        if unitGUID then
                            local info = ZT.inspectLib:GetCachedInfo(unitGUID)
                            if info then
                                ZT:libInspectUpdate("Init", unitGUID, unitID, info)
                            else
                                ZT.inspectLib:Rescan(unitGUID)
                            end
                        end
                    end
                    ZT:resetEncounterCDs()
                end,
                hidden = function() return not _G.WeakAuras or not _G.WeakAuras.GetSanitizedGlobal('ZenTracker_AuraEnv') end,
            },
        },
    }
end
tinsert(R.Config, CoreOptions)
