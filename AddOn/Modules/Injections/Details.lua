local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G

-- WoW API / Variables

local function OnDetailsEvent(self, _, instance, segment)
    self:UnregisterEvent('DETAILS_INSTANCE_CHANGESEGMENT')

    local instanceID = instance:GetInstanceId()

    local index = 1
    while true do
        local window = _G.Details:GetWindow(index)
        if not window then break end

        if instanceID ~= window:GetInstanceId() and segment ~= window:GetSegment() then
            local attributeId, subAttributeId = window:GetDisplay()
            window:SetDisplay(segment, attributeId, subAttributeId)
        end
        index = index + 1
    end

    self:RegisterEvent('DETAILS_INSTANCE_CHANGESEGMENT')
end

local function Details()
    R:RegisterAddOnLoad('Details', function()
        local EventListener = _G.Details:CreateEventListener()
        EventListener:RegisterEvent('DETAILS_INSTANCE_CHANGESEGMENT')
        EventListener.OnDetailsEvent = OnDetailsEvent
    end)
end

RI:RegisterPipeline(Details)
