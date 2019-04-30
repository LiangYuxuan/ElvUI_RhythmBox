local R, E, L, V, P, G = unpack(select(2, ...))
local RS = R.Skin

-- Season Two
local conqueror = 13448
local master = 13449

function RS:ChallengesFrame_Update()
    local crits, numCrits = {}, GetAchievementNumCriteria(master)
    for i = 1, numCrits do
        local name, _, _, complete = GetAchievementCriteriaInfo(master, i)
        if complete then
            crits[name] = 15
        else
            name, _, _, complete = GetAchievementCriteriaInfo(conqueror, i)
            if complete then
                crits[name] = 10
            end
        end
    end

    for i, icon in pairs(ChallengesFrame.DungeonIcons) do
        local name = C_ChallengeMode.GetMapUIInfo(icon.mapID)
        if not icon.tex then
            local tex = icon:CreateTexture()
            tex:SetWidth(24)
            tex:SetHeight(24)
            tex:ClearAllPoints()
            tex:SetPoint('BOTTOM', icon, 0, 3)
            icon.tex = tex
            icon:HookScript('OnEnter', function()
                    GameTooltip_AddBlankLineToTooltip(GameTooltip);
                    GameTooltip:AddLine("\124TInterface/Minimap/ObjectIconsAtlas:16:16:0:0:1024:512:575:607:205:237\124t 10+ Timed")
                    GameTooltip:AddLine("\124TInterface/Minimap/ObjectIconsAtlas:16:16:0:0:1024:512:575:607:239:271\124t 15+ Timed")
                    GameTooltip:Show()
            end)
        end
        icon.tex:Show()
        if crits[name] == 15 then
            icon.tex:SetAtlas('VignetteKillElite')
        elseif crits[name] == 10 then
            icon.tex:SetAtlas('VignetteKill')
        else
            icon.tex:Hide()
        end
    end
end
