local R, E, L, V, P, G = unpack(select(2, ...))

local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G

-- WoW API / Variables

local EventListener

function RI:OnDetailsEvent(_, instance, segment)
    -- self here is not RI, this function is called from EventListener
    -- only allow one hook in progress
    EventListener:UnregisterEvent('DETAILS_INSTANCE_CHANGESEGMENT')

    local instanceID = instance:GetInstanceId()

    local index = 1
    while true do
        local window = _G.Details:GetWindow(index)
        if not window then break end

        if instanceID ~= window:GetInstanceId() and segment ~= window:GetSegment() then
            window:SetDisplay(segment)
        end
        index = index + 1
    end

    EventListener:RegisterEvent('DETAILS_INSTANCE_CHANGESEGMENT')
end

function RI:Details()
    EventListener = _G.Details:CreateEventListener()
    EventListener:RegisterEvent('DETAILS_INSTANCE_CHANGESEGMENT')
    EventListener.OnDetailsEvent = self.OnDetailsEvent
end

RI:RegisterInjection(RI.Details, 'Details')
