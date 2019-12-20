local R, E, L, V, P, G = unpack(select(2, ...))
local RI = R:NewModule('Injections', 'AceEvent-3.0', 'AceHook-3.0')

-- Lua functions
local ipairs, pairs, pcall, tinsert = ipairs, pairs, pcall, tinsert

-- WoW API / Variables
local IsAddOnLoaded = IsAddOnLoaded

RI.Pipeline = {}
RI.OnDemand = {}

function RI:RegisterInjection(injectFunc, addonName)
    if not addonName then
        tinsert(self.Pipeline, injectFunc)
    else
        self.OnDemand[addonName] = injectFunc
    end
end

function RI:ADDON_LOADED(_, addonName)
    if self.OnDemand[addonName] then
        pcall(self.OnDemand[addonName], self)
        self.OnDemand[addonName] = nil
    end
end

function RI:Initialize()
    for _, func in pairs(self.Pipeline) do
        pcall(func, self)
    end

    for addonName, func in ipairs(self.OnDemand) do
        if IsAddOnLoaded(addonName) then
            pcall(func, self)
            func = nil
        end
    end

    self:RegisterEvent('ADDON_LOADED')
end

R:RegisterModule(RI:GetName())
