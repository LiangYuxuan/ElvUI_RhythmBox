local R, E, L, V, P, G = unpack(select(2, ...))

local RI = R:GetModule('Injections')
local LOP = LibStub('LibObjectiveProgress-1.0')

-- Lua functions

-- WoW API / Variables

local ChallengeMapIDs = {
    -- dungeonIndex is used in MethodDungeonTools
    -- [keystoneMapID] = dungeonIndex,
    [244] = 15, -- Atal'Dazar
    [245] = 16, -- Freehold
    [246] = 23, -- Tol Dagor
    [247] = 21, -- The MOTHERLODE!!
    [248] = 24, -- Waycrest Manor
    [249] = 17, -- Kings' Rest
    [250] = 20, -- Temple of Sethraliss
    [251] = 22, -- The Underrot
    [252] = 18, -- Shrine of the Storm
    [353] = 19, -- Siege of Boralus
    [369] = 25, -- Operation: Mechagon - Junkyard
    [370] = 26, -- Operation: Mechagon - Workshop
}

-- modified version of MethodDungeonTools:GetEnemyForces
local function GetEnemyForces(npcID, keystoneMapID, isTeeming)
    local dungeonIndex = ChallengeMapIDs[keystoneMapID]
    if not dungeonIndex then return end

    local dungeonData = MethodDungeonTools and MethodDungeonTools.dungeonEnemies and MethodDungeonTools.dungeonEnemies[dungeonIndex]
    if dungeonData then
        for _, enemyData in pairs(dungeonData) do
            if enemyData.id == npcID then
                if isTeeming then
                    return enemyData.teemingCount, MethodDungeonTools.dungeonTotalCount[dungeonIndex].teeming
                else
                    return enemyData.count, MethodDungeonTools.dungeonTotalCount[dungeonIndex].normal
                end
            end
        end
    end
end

function RI:GottaGoFast()
    local GottaGoFast = _G.GottaGoFast

    function GottaGoFast.AddMobPointsToTooltip()
        local keystoneMapID = GottaGoFast.CurrentCM.CmID
        -- local keystoneMapID = C_ChallengeMode.GetActiveChallengeMapID()
        if keystoneMapID then
            local unitGUID = UnitGUID('mouseover')
            if not unitGUID then return end

            local npcID = select(6, strsplit('-', unitGUID))
            npcID = npcID and tonumber(npcID)
            if not npcID then return end

            local activeAffixIDs = select(2, C_ChallengeMode.GetActiveKeystoneInfo())
            local isTeeming = activeAffixIDs and tContains(activeAffixIDs, 5)

            local appendString
            if GottaGoFast.GetUseMdt() and MethodDungeonTools then
                local count, total = GetEnemyForces(npcID, keystoneMapID, isTeeming)
                if not count then return end

                if GottaGoFast.GetMobPoints() then
                    appendString = format(" (%.2f%% - %d)", count / total * 100, count)
                else
                    appendString = format(" (%.2f%%)", count / total * 100)
                end
            else
                local isAlternate = GottaGoFast.IsAlternate(keystoneMapID, GottaGoFast.CurrentCM.ZoneID)
                local weightPercent = LOP:GetNPCWeightByMap(GottaGoFast.CurrentCM.ZoneID, npcID, isTeeming, isAlternate)
                if not weightPercent then return end

                if GottaGoFast.GetMobPoints() then
                    local weight = GottaGoFast.CalculateIndividualMobPointsWrapper(weightPercent)
                    appendString = format(" (%.2f%% - %.2f)", weightPercent, weight)
                else
                    appendString = format(" (%.2f%%)", weightPercent)
                end
            end

            _G.GameTooltip:AppendText(appendString)
        end
    end
end

RI:RegisterInjection(RI.GottaGoFast, 'GottaGoFast')
