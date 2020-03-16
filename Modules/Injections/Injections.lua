local R, E, L, V, P, G = unpack(select(2, ...))
local RI = R:NewModule('Injections', 'AceEvent-3.0', 'AceHook-3.0')

-- Lua functions
local ipairs, pairs, tinsert, xpcall = ipairs, pairs, tinsert, xpcall

-- WoW API / Variables
local IsAddOnLoaded = IsAddOnLoaded

RI.Pipeline = {}
RI.OnDemand = {}

function RI:RegisterInjection(injectFunc, addonName)
    if self.initialized then
        if not addonName then
            xpcall(function() injectFunc(self) end, R.ErrorHandler)
        elseif IsAddOnLoaded(addonName) then
            xpcall(function() injectFunc(self) end, R.ErrorHandler)
        else
            self.OnDemand[addonName] = injectFunc
        end
    else
        if not addonName then
            tinsert(self.Pipeline, injectFunc)
        else
            self.OnDemand[addonName] = injectFunc
        end
    end
end

function RI:ADDON_LOADED(_, addonName)
    if self.OnDemand[addonName] then
        xpcall(function() self.OnDemand[addonName](self) end, R.ErrorHandler)
        self.OnDemand[addonName] = nil
    end
end

function RI:Initialize()
    for _, func in ipairs(self.Pipeline) do
        xpcall(function() func(self) end, R.ErrorHandler)
    end

    for addonName, func in pairs(self.OnDemand) do
        if IsAddOnLoaded(addonName) then
            xpcall(function() func(self) end, R.ErrorHandler)
            self.OnDemand[addonName] = nil
        end
    end

    self:RegisterEvent('ADDON_LOADED')
    self.initialized = true
end

R:RegisterModule(RI:GetName())
