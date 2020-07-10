local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local MP = R:GetModule('MythicPlus')

function MP:AddProgress()
    if not self.currentRun or not _G.MDT then return end

    local unitGUID = UnitGUID('mouseover')
    if not unitGUID then return end

    local npcID = select(6, strsplit('-', unitGUID))
    npcID = npcID and tonumber(npcID)
    if not npcID then return end

    local count, total, totalTeeming, countTeeming = _G.MDT:GetEnemyForces(npcID)
    if not count then return end

    local isTeeming = tContains(self.currentRun.affixes, 5)
    if isTeeming then
        _G.GameTooltip:AppendText(format(" (%.2f%% - %d)", countTeeming / totalTeeming * 100, countTeeming))
    else
        _G.GameTooltip:AppendText(format(" (%.2f%% - %d)", count / total * 100, count))
    end
end

function MP:BuildTooltip()
    self:SecureHook(_G.GameTooltip, 'Show', 'AddProgress')
end
