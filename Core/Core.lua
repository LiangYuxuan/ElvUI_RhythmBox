local R, E, L, V, P, G = unpack((select(2, ...)))

-- Lua functions
local tinsert = tinsert

-- WoW API / Variables

_G.BINDING_HEADER_RHYTHM = R.Title

local registeredModules = {}

local OnInitialize = function(self)
    for _, data in ipairs(self.pipelines) do
        xpcall(data[1], R.ErrorHandler, self, unpack(data, 2))
    end
    self.pipelines = nil

    self.initialized = true
end

local RegisterPipeline = function(self, callback, ...)
    if self.initialized then
        xpcall(callback, R.ErrorHandler, self, ...)
    else
        tinsert(self.pipelines, { callback, ... })
    end
end

function R:RegisterModule(moduleName)
    local module = self:GetModule(moduleName)
    module.pipelines = {}
    module.RegisterPipeline = RegisterPipeline

    if self.initialized then
        if module.Initialize then
            xpcall(module.Initialize, R.ErrorHandler, module)
        end
        xpcall(OnInitialize, R.ErrorHandler, module)
    else
        tinsert(registeredModules, moduleName)
    end
end

function R:InitializeModules()
    for _, moduleName in ipairs(registeredModules) do
        local module = self:GetModule(moduleName)
        if module.Initialize then
            xpcall(module.Initialize, R.ErrorHandler, module)
        end
        xpcall(OnInitialize, R.ErrorHandler, module)
    end
end
