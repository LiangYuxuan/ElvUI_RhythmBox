local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G
local pairs, next = pairs, next

-- WoW API / Variables
local C_AddOns_GetAddOnEnableState = C_AddOns.GetAddOnEnableState
local C_AddOns_IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

local addonList = {
    ['Blizzard_ChallengesUI'] = true,
    ['RaiderIO'] = true,
}

local function handlePoints()
    local MP = R:GetModule('MythicPlus')
    local dialog = _G.PremadeGroupsFilterDialog
    local anchor = _G.RaiderIO_ProfileTooltipAnchor

    if dialog then
        dialog:HookScript('OnShow', function()
            anchor:ClearAllPoints()
            anchor:SetPoint('TOPLEFT', dialog, 'TOPRIGHT', -16, 0)
        end)

        dialog:HookScript('OnHide', function()
            if not _G.ChallengesFrame:IsShown() and _G.PVEFrame:IsShown() then
                _G.PVEFrame:Hide()
                _G.PVEFrame:Show()
            end
        end)
    end

    _G.ChallengesFrame:HookScript('OnShow', function()
        anchor:ClearAllPoints()
        anchor:SetPoint('TOPLEFT', MP.boardContainer, 'TOPRIGHT', -16, 0)
    end)

    _G.ChallengesFrame:HookScript('OnHide', function()
        if not dialog or not dialog:IsShown() then
            anchor:ClearAllPoints()
            anchor:SetPoint('TOPLEFT', _G.PVEFrame, 'TOPRIGHT', -16, 0)
        else
            anchor:ClearAllPoints()
            anchor:SetPoint('TOPLEFT', dialog, 'TOPRIGHT', -16, 0)
        end
    end)

    hooksecurefunc(anchor, 'SetPoint', function(_, _, parent)
        if _G.ChallengesFrame:IsShown() and parent ~= MP.boardContainer then
            anchor:ClearAllPoints()
            anchor:SetPoint('TOPLEFT', MP.boardContainer, 'TOPRIGHT', -16, 0)
        end
    end)
end

function RI:RaiderIO()
    if C_AddOns_GetAddOnEnableState('RaiderIO', E.myname) ~= 2 then
        return
    end

    if C_AddOns_GetAddOnEnableState('PremadeGroupsFilter', E.myname) == 2 then
        addonList['PremadeGroupsFilter'] = true
    end

    for addonName in pairs(addonList) do
        if C_AddOns_IsAddOnLoaded(addonName) then
            addonList[addonName] = nil
        end
    end

    if not next(addonList) then
        handlePoints()
    else
        local eventFrame = CreateFrame('Frame')
        eventFrame:RegisterEvent('ADDON_LOADED')
        eventFrame:SetScript('OnEvent', function(_, _, addonName)
            addonList[addonName] = nil
            if not next(addonList) then
                eventFrame:UnregisterEvent('ADDON_LOADED')
                handlePoints()
            end
        end)
    end
end

RI:RegisterInjection(RI.RaiderIO)
