local E, L, V, P, G = unpack(ElvUI)
local EP = LibStub('LibElvUIPlugin-1.0')
local addon, Engine = ...

-- Lua functions
local _G = _G
local ipairs, xpcall = ipairs, xpcall

-- WoW API / Variables

local R = E.Libs.AceAddon:NewAddon(addon, 'AceEvent-3.0')
Engine[1] = R
Engine[2] = E
Engine[3] = L
Engine[4] = V
Engine[5] = P
Engine[6] = G
_G[addon] = Engine

R.DragonflightBeta = select(4, GetBuildInfo()) >= 100002

R.Config = {}
R.RegisteredModules = {}

function R.ErrorHandler(err)
    return _G.geterrorhandler()(err)
end

function R:RegisterModule(name)
    if self.initialized then
        local module = self:GetModule(name)
        if module and module.Initialize then
            xpcall(module.Initialize, R.ErrorHandler, module)
        end
    else
        self.RegisteredModules[#self.RegisteredModules + 1] = name
    end
end

function R:InitializeModules()
    for _, moduleName in ipairs(R.RegisteredModules) do
        local module = self:GetModule(moduleName)
        if module.Initialize then
            xpcall(module.Initialize, R.ErrorHandler, module)
        else
            R:Print("Module <" .. moduleName .. "> is not loaded.")
        end
    end
end

function R:AddOptions()
    for _, func in ipairs(R.Config) do
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
