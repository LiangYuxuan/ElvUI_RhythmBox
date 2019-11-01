local E, L, V, P, G = unpack(ElvUI)
local EP = LibStub('LibElvUIPlugin-1.0')
local addon, Engine = ...

-- Lua functions
local pairs = pairs

-- WoW API / Variables

local R = E.Libs.AceAddon:NewAddon(addon, 'AceEvent-3.0')
Engine[1] = R
Engine[2] = E
Engine[3] = L
Engine[4] = V
Engine[5] = P
Engine[6] = G
_G[addon] = Engine

R.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
R.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

R.Config = {}
R.RegisteredModules = {}

function R:RegisterModule(name)
    if self.initialized then
        local module = self:GetModule(name)
        if (module and module.Initialize) then
            module:Initialize()
        end
    else
        self.RegisteredModules[#self.RegisteredModules + 1] = name
    end
end

function R:InitializeModules()
    for _, moduleName in pairs(R.RegisteredModules) do
        local module = self:GetModule(moduleName)
        if module.Initialize then
            module:Initialize()
        else
            R:Print("Module <" .. moduleName .. "> is not loaded.")
        end
    end
end

function R:AddOptions()
    for _, func in pairs(R.Config) do
        func()
    end
end

function R:Init()
    self.initialized = true
    self:Initialize()
    self:InitializeModules()
    EP:RegisterPlugin(addon, self.AddOptions)
end

E.Libs.EP:HookInitialize(R, R.Init)
