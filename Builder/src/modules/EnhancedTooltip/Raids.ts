import assert from 'node:assert';

import type { DBDParser } from '@rhyster/wow-casc-dbc';

import { registerTask } from '../../task.ts';
import { versions, latestVersion } from '../../client.ts';

interface RaidData {
    id: number,
    mapID: number,
    name: string,
}

interface BasicBossData {
    id: number,
    name: string,
    orderIndex: number,
}

interface BossData {
    id: number,
    name: string,
    mythic?: number,
    heroic?: number,
    normal?: number,
    lfr?: number,
}

type Difficulty = 'mythic' | 'heroic' | 'normal' | 'lfr';

interface CriteriaData {
    encounterID: number,
    difficulty: Difficulty,
}

const modifierTreeIDMap = new Map<number, Difficulty>([
    [14716, 'mythic'],
    [16442, 'heroic'],
    [16425, 'normal'],
    [16423, 'lfr'],
]);

const parseCriteria = (
    criteriaTree: DBDParser,
    criteria: DBDParser,
    criteriaTreeID: number,
): CriteriaData => {
    let criteriaID: number | undefined;
    criteriaTree.getAllIDs().some((id) => {
        const row = criteriaTree.getRowData(id);
        const parent = row?.Parent as number;
        if (parent === criteriaTreeID) {
            criteriaID = row?.CriteriaID as number;
            return true;
        }
        return false;
    });
    assert(criteriaID, `Failed to find Criteria for CriteriaTree ${criteriaTreeID.toString()}`);

    const row = criteria.getRowData(criteriaID);
    assert(row, `Criteria ID ${criteriaID.toString()} not found`);

    const asset = row.Asset as number;
    const modifierTreeID = row.Modifier_tree_ID as number;
    const difficulty = modifierTreeIDMap.get(modifierTreeID);
    assert(difficulty, `Failed to find Difficulty for ModifierTree ${modifierTreeID.toString()}`);

    return {
        encounterID: asset,
        difficulty,
    };
};

const getAchievementDataForRaid = (
    achievement: DBDParser,
    criteriaTree: DBDParser,
    criteria: DBDParser,
    bosses: BasicBossData[],
    mapID: number,
): BossData[] => {
    const result: BossData[] = bosses;

    achievement.getAllIDs().forEach((id) => {
        const row = achievement.getRowData(id);
        const instanceID = row?.Instance_ID as number;
        const flags = row?.Flags as number;
        const criteriaTreeID = row?.Criteria_tree as number;

        // eslint-disable-next-line no-bitwise
        if (instanceID === mapID && (flags & 0x1) !== 0) {
            const data = parseCriteria(criteriaTree, criteria, criteriaTreeID);
            const encounter = result.find((b) => b.id === data.encounterID);
            assert(encounter, `Unexpected encounter ID ${data.encounterID.toString()} in Criteria for Achievement ${id.toString()}`);

            encounter[data.difficulty] = id;
        }
    });

    return result;
};

const getBossDataForRaid = (dungeonEncounter: DBDParser, instanceID: number): BasicBossData[] => {
    const bosses: BasicBossData[] = [];
    dungeonEncounter.getAllIDs().forEach((id) => {
        const row = dungeonEncounter.getRowData(id);
        const mapID = row?.MapID as number;
        const orderIndex = row?.OrderIndex as number;
        const name = row?.Name_lang;
        assert(typeof name === 'string', `No name for ${id.toString()}`);

        if (mapID === instanceID) {
            bosses.push({
                id,
                name,
                orderIndex,
            });
        }
    });

    bosses.sort((a, b) => a.orderIndex - b.orderIndex);

    return bosses;
};

const getRaidsForExpansion = (lfgDungeons: DBDParser, expansion: number): RaidData[] => {
    const raids: RaidData[] = [];

    lfgDungeons.getAllIDs().forEach((id) => {
        const row = lfgDungeons.getRowData(id);
        const typeID = row?.TypeID as number;
        const subType = row?.Subtype as number;
        const expansionLevel = row?.ExpansionLevel as number;
        const mapID = row?.MapID as number;
        const difficultyID = row?.DifficultyID as number;
        const name = row?.Name_lang;
        assert(typeof name === 'string', `No name for ${id.toString()}`);

        if (
            typeID === 2
            && subType === 2
            && difficultyID === 14
            && expansionLevel === expansion
        ) {
            raids.push({
                id,
                name,
                mapID,
            });
        }
    });

    return raids;
};

registerTask({
    key: 'EnhancedTooltipRaids',
    version: 2,
    fileDataIDs: [
        1361033, // dbfilesclient/lfgdungeons.db2
        1347279, // dbfilesclient/dungeonencounter.db2
        1260179, // dbfilesclient/achievement.db2
        1263818, // dbfilesclient/criteriatree.db2
        1263817, // dbfilesclient/criteria.db2
    ],
    handler: ([
        lfgDungeons,
        dungeonEncounter,
        achievement,
        criteriaTree,
        criteria,
    ]) => {
        const liveMajor = versions[0].semver?.major;
        const latestMajor = latestVersion.semver.major;
        const latestMinor = latestVersion.semver.minor;
        assert(liveMajor, 'Missing major version for live');

        const raids = getRaidsForExpansion(lfgDungeons, latestMajor - 1);
        if (liveMajor < latestMajor || latestMinor < 1) {
            raids.unshift(...getRaidsForExpansion(lfgDungeons, latestMajor - 2));
        }
        if (raids.length <= 1) {
            const oldRaids = getRaidsForExpansion(lfgDungeons, latestMajor - 2);
            raids.unshift(oldRaids[oldRaids.length - 1]);
        }

        const raidsText = raids
            .map(({ id, mapID, name }) => {
                const bosses = getBossDataForRaid(dungeonEncounter, mapID);
                const data = getAchievementDataForRaid(
                    achievement,
                    criteriaTree,
                    criteria,
                    bosses,
                    mapID,
                );

                const mythic = `    mythic = {\n        ${data.map((b) => b.mythic ?? 'nil').join(', ')},\n    },\n`;
                const heroic = `    heroic = {\n        ${data.map((b) => b.heroic ?? 'nil').join(', ')},\n    },\n`;
                const normal = `    normal = {\n        ${data.map((b) => b.normal ?? 'nil').join(', ')},\n    },\n`;
                const lfr = `    lfr = {\n        ${data.map((b) => b.lfr ?? 'nil').join(', ')},\n    },\n`;

                return `{\n    id = ${id.toString()}, -- ${name}\n${mythic}${heroic}${normal}${lfr}},`;
            })
            .filter((data): data is string => !!data);

        return raidsText.join('\n');
    },
});
