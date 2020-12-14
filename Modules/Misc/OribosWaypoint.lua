local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local OW = R:NewModule('OribosWaypoint', 'AceEvent-3.0')

-- Lua functions

-- WoW API / Variables
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit

function OW:Toggle()
    local uiMapID = C_Map_GetBestMapForUnit('player')

    if uiMapID == 1671 and not self.overrided then
        if C_Map.HasUserWaypoint() then
            self.oldPoint = C_Map.GetUserWaypoint()
            self.isTracked = C_SuperTrack.IsSuperTrackingUserWaypoint()
        end

        C_Map.SetUserWaypoint(self.flightMaster)
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)

        self.overrided = true
    elseif self.overrided then
        C_Map.ClearUserWaypoint()

        if self.oldPoint then
            C_Map.SetUserWaypoint(self.oldPoint)
            C_SuperTrack.SetSuperTrackedUserWaypoint(self.isTracked)

            self.oldPoint = nil
            self.isTracked = nil
        end

        self.overrided = nil
    end
end

function OW:Initialize()
    self.flightMaster = UiMapPoint.CreateFromCoordinates(1550, 0.4701, 0.5113, 0)

    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'Toggle')
    self:RegisterEvent('ZONE_CHANGED', 'Toggle')
    self:RegisterEvent('ZONE_CHANGED_INDOORS', 'Toggle')
end

R:RegisterModule(OW:GetName())
