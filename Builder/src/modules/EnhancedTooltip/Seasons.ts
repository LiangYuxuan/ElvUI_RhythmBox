import assert from 'node:assert';

import { versions, latestVersion } from '../../client.ts';

import type { Task } from '../../task.ts';
import type { DBDParser } from '@rhyster/wow-casc-dbc';

interface SeasonData {
    id: number,
    expansionID: number,
    name: string,
    achievements: {
        id: number,
        amount: number,
    }[],
}

const blackListAchievements = new Set([
    18542, // Dragonflight Keystone Master: Season Two (Character-Specific)
]);

const expansionAbbrMap = new Map<number, string>([
    [8, 'SL'],
    [9, 'DF'],
    [10, 'TWW'],
]);

const criteriaCacheMap = new Map<number, number>();

const parseCriteria = (
    criteria: DBDParser,
    modifierTree: DBDParser,
    criteriaID: number,
): number => {
    const cache = criteriaCacheMap.get(criteriaID);
    if (cache !== undefined) {
        return cache;
    }

    const row = criteria.getRowData(criteriaID);
    assert(row, `Criteria ID ${criteriaID.toString()} not found`);

    const type = row.Type as number;
    const modifierTreeID = row.Modifier_tree_ID as number;
    if (type === 230 || type === 216) {
        // 230 ((Player) Mythic+ Rating "{#DungeonScore}" attained)
        // 216 (Mythic Plus Completed)
        let season = 0;
        const isInvalid = modifierTree.getAllIDs().some((id) => {
            const modifierTreeRow = modifierTree.getRowData(id);
            const modifierTreeParent = modifierTreeRow?.Parent as number;
            const modifierTreeType = modifierTreeRow?.Type as number;

            if (modifierTreeParent === modifierTreeID) {
                if (modifierTreeType === 250) { // MYTHIC_SEASON_DISPLAY
                    season = modifierTreeRow?.Asset as number;
                }

                if (modifierTreeType === 249) { // KEYSTONE_DUNGEON
                    return true;
                }
            }

            return false;
        });

        if (isInvalid) {
            criteriaCacheMap.set(criteriaID, 0);
            return 0;
        }

        criteriaCacheMap.set(criteriaID, season);
        return season;
    }

    criteriaCacheMap.set(criteriaID, 0);
    return 0;
};

const parseCriteriaTree = (
    criteriaTree: DBDParser,
    criteria: DBDParser,
    modifierTree: DBDParser,
    criteriaTreeID: number,
) => {
    let amount = 0;
    let criteriaID: number | undefined;

    criteriaTree.getAllIDs().some((id) => {
        const row = criteriaTree.getRowData(id);
        const parent = row?.Parent as number;
        if (parent === criteriaTreeID) {
            amount = row?.Amount as number;
            criteriaID = row?.CriteriaID as number;
            return true;
        }
        return false;
    });

    if (criteriaID !== undefined && criteriaID !== 0) {
        const season = parseCriteria(criteria, modifierTree, criteriaID);
        if (season) {
            return { amount, season };
        }
    }

    return undefined;
};

const getSeasonsForExpansion = (displaySeason: DBDParser, expansion: number): SeasonData[] => {
    const abbr = expansionAbbrMap.get(expansion);
    assert(abbr !== undefined, `Failed to find abbreviation for Expansion ${expansion.toString()}`);

    const seasons: SeasonData[] = [];
    displaySeason.getAllIDs().forEach((id) => {
        const row = displaySeason.getRowData(id);
        const season = row?.Season as number;
        const expansionID = row?.ExpansionID as number;
        if (expansionID === expansion) {
            seasons.push({
                id: season,
                expansionID,
                name: `${abbr}S${(seasons.length + 1).toString()}`,
                achievements: [],
            });
        }
    });
    return seasons;
};

const task: Task = {
    key: 'EnhancedTooltipSeasons',
    version: 5,
    fileDataIDs: [
        4279827, // dbfilesclient/displayseason.db2
        1260179, // dbfilesclient/achievement.db2
        1263818, // dbfilesclient/criteriatree.db2
        1263817, // dbfilesclient/criteria.db2
        1267645, // dbfilesclient/modifiertree.db2
    ],
    handler: ([
        displaySeason,
        achievement,
        criteriaTree,
        criteria,
        modifierTree,
    ]) => {
        const liveMajor = versions[0].semver?.major;
        const liveMinor = versions[0].semver?.minor;
        const latestMajor = latestVersion.semver.major;
        assert(typeof liveMajor === 'number', 'Missing major version for live');
        assert(typeof liveMinor === 'number', 'Missing minor version for live');

        const seasons = getSeasonsForExpansion(displaySeason, latestMajor - 1);
        if (liveMajor < latestMajor || liveMinor < 1) {
            seasons.unshift(...getSeasonsForExpansion(displaySeason, latestMajor - 2));
        }
        if (seasons.length <= 1) {
            const oldSeasons = getSeasonsForExpansion(displaySeason, latestMajor - 2);
            seasons.unshift(oldSeasons[oldSeasons.length - 1]);
        }

        achievement.getAllIDs().forEach((id) => {
            if (blackListAchievements.has(id)) {
                return;
            }

            const row = achievement.getRowData(id);
            const category = row?.Category as number;
            const criteriaTreeID = row?.Criteria_tree as number;

            if (category === 15272) {
                const res = parseCriteriaTree(criteriaTree, criteria, modifierTree, criteriaTreeID);
                if (res) {
                    const season = seasons.find((s) => s.id === res.season);
                    if (season) {
                        season.achievements.push({
                            id,
                            amount: res.amount,
                        });
                    }
                }
            }
        });

        const texts = seasons.map(({ name, achievements }) => {
            achievements.sort((a, b) => a.amount - b.amount);
            return `{\n    name = '${name}',\n    achievements = {${achievements.map(({ id }) => id).join(', ')}},\n},`;
        });

        return texts.join('\n');
    },
};

export default task;
