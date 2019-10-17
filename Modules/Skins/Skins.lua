local R, E, L, V, P, G = unpack(select(2, ...))
local RS = R:NewModule('Skins', 'AceEvent-3.0', 'AceHook-3.0')

-- Lua functions
local ipairs, pairs, pcall, tinsert = ipairs, pairs, pcall, tinsert

-- WoW API / Variables
local IsAddOnLoaded = IsAddOnLoaded

RS.Pipeline = {}
RS.OnDemand = {}

function RS:RegisterSkin(skinFunc, addonName)
    if not addonName then
        tinsert(self.Pipeline, skinFunc)
    else
        self.OnDemand[addonName] = skinFunc
    end
end

function RS:ADDON_LOADED(_, addonName)
    if self.OnDemand[addonName] then
        pcall(self.OnDemand[addonName], self)
        self.OnDemand[addonName] = nil
    end
end

function RS:Initialize()
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

R:RegisterModule(RS:GetName())
