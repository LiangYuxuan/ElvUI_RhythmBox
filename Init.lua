local E, L, V, P, G = unpack(ElvUI)
local EP = E.Libs.EP
local addon, Engine = ...

-- Lua functions
local _G = _G

-- WoW API / Variables

local R = E.Libs.AceAddon:NewAddon(addon, 'AceEvent-3.0')
Engine[1] = R
Engine[2] = E
Engine[3] = L
Engine[4] = V
Engine[5] = P
Engine[6] = G
_G[addon] = Engine

R.IsTWW = select(4, GetBuildInfo()) >= 110000

R.Title = '|cFF70B8FFRhythm Box|r'

R.ErrorHandler = function(error)
    return _G.geterrorhandler()(error)
end

function R:Initialize()
    self.initialized = true
    self:InitializeModules()
    EP:RegisterPlugin(addon, self.PopulateOptions)
end

EP:HookInitialize(R, R.Initialize)
