local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G

-- WoW API / Variables
local hooksecurefunc = hooksecurefunc

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

local function RaiderIO()
    R:RegisterAddOnLoad('RaiderIO', function()
        R:RegisterAddOnLoad('Blizzard_ChallengesUI', function()
            if E:IsAddOnEnabled('PremadeGroupsFilter') then
                R:RegisterAddOnLoad('PremadeGroupsFilter', handlePoints)
            else
                handlePoints()
            end
        end)
    end)
end

RI:RegisterPipeline(RaiderIO)
