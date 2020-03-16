local R, E, L, V, P, G = unpack(select(2, ...))
local RS = R:NewModule('Skins', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')

-- Lua functions
local ipairs, pairs, pcall, tinsert = ipairs, pairs, pcall, tinsert

-- WoW API / Variables
local IsAddOnLoaded = IsAddOnLoaded

RS.Pipeline = {}
RS.OnDemand = {}

function RS:RegisterSkin(skinFunc, addonName)
    if self.initialized then
        if not addonName then
            xpcall(function() skinFunc(self) end, R.ErrorHandler)
        elseif IsAddOnLoaded(addonName) then
            xpcall(function() skinFunc(self) end, R.ErrorHandler)
        else
            self.OnDemand[addonName] = skinFunc
        end
    else
        if not addonName then
            tinsert(self.Pipeline, skinFunc)
        else
            self.OnDemand[addonName] = skinFunc
        end
    end
end

function RS:ADDON_LOADED(_, addonName)
    if self.OnDemand[addonName] then
        xpcall(function() self.OnDemand[addonName](self) end, R.ErrorHandler)
        self.OnDemand[addonName] = nil
    end
end

function RS:Initialize()
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

R:RegisterModule(RS:GetName())
