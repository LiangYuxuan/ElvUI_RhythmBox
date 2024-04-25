import assert from 'node:assert';

import { registerTask } from '../../task.ts';
import { getMythicPlusStaticData } from '../../rio.ts';

interface Dungeon {
    challengeMapID: number,
    name: string,
    mapID: number,
    journalInstanceID: number,
    shortName?: string,
    portalSpellID?: number
}

interface Expansion {
    name: string,
    dungeons: Dungeon[],
}

const overrideMapExpansion = new Map<number, number>([
    [1007, 4], // Scholomance
    [1001, 4], // Scarlet Halls
    [1004, 4], // Scarlet Monastery
]);

const overridePortalSpell = new Map<number, number>([
    [1651, 373262], // Return to Karazhan
]);

registerTask({
    key: 'MythicPlusDatabase',
    version: 1,
    fileDataIDs: [
        1729547, // dbfilesclient/uiexpansiondisplayinfo.db2
        1394440, // dbfilesclient/globalstrings.db2
        1139939, // dbfilesclient/spellcategories.db2
        1140089, // dbfilesclient/spell.db2
        1237438, // dbfilesclient/journalinstance.db2
        1349477, // dbfilesclient/map.db2
        801709, // dbfilesclient/mapchallengemode.db2
    ],
    handler: async ([
        expansions,
        globalStrings,
        spellCategories,
        spell,
        journalInstance,
        map,
        mapChallengeMode,
    ]) => {
        const expansionLength = expansions.getAllIDs().length;
        const expansionNameMap = new Map<number, string>();
        globalStrings.getAllIDs().forEach((id) => {
            const row = globalStrings.getRowData(id);
            const tag = row?.BaseTag;
            const text = row?.TagText_lang;
            if (typeof tag === 'string' && typeof text === 'string') {
                const match = tag.match(/^EXPANSION_NAME(\d+)$/);
                if (match) {
                    const index = parseInt(match[1], 10);
                    expansionNameMap.set(index, text);
                }
            }
        });

        const expansionData: Expansion[] = [];
        for (let i = 0; i < expansionLength; i += 1) {
            const name = expansionNameMap.get(i);
            assert(name, `No expansion name found for index ${i.toString()}`);

            expansionData.push({
                name,
                dungeons: [],
            });
        }

        const shortNames = new Map<number, string>();
        for (let i = 0; i < expansionLength; i += 1) {
            // eslint-disable-next-line no-await-in-loop
            const res = await getMythicPlusStaticData(i);
            if ('seasons' in res) {
                res.seasons.forEach((season) => {
                    season.dungeons.forEach(({ challenge_mode_id, short_name }) => {
                        shortNames.set(challenge_mode_id, short_name);
                    });
                });
                res.dungeons.forEach(({ challenge_mode_id, short_name }) => {
                    shortNames.set(challenge_mode_id, short_name);
                });
            }
        }

        const teleportSpells: number[] = [];
        spellCategories.getAllIDs().forEach((id) => {
            const row = spellCategories.getRowData(id);
            if (row?.Category === 1407) {
                const spellID = row.SpellID;
                assert(typeof spellID === 'number', `Invalid spellID for spellCategories ID ${id.toString()}`);

                teleportSpells.push(spellID);
            }
        });

        const destinationMap = new Map<string, number>(
            teleportSpells.map((spellID) => {
                const row = spell.getRowData(spellID);
                const name = row?.NameSubtext_lang;
                assert(typeof name === 'string', `Invalid name for spell ID ${spellID.toString()}`);

                return [name, spellID] as const;
            }),
        );

        const mapID2JournalInstanceID = new Map<number, number>(
            journalInstance.getAllIDs().map((id) => {
                const row = journalInstance.getRowData(id);
                const mapID = row?.MapID;
                assert(typeof mapID === 'number', `Invalid mapID for journalInstance ID ${id.toString()}`);

                return [mapID, id] as const;
            }),
        );

        mapChallengeMode.getAllIDs().forEach((id) => {
            const row = mapChallengeMode.getRowData(id);
            const name = row?.Name_lang;
            const mapID = row?.MapID;
            assert(typeof name === 'string', `Invalid name for mapChallengeMode ID ${id.toString()}`);
            assert(typeof mapID === 'number', `Invalid mapID for mapChallengeMode ID ${id.toString()}`);

            const mapRow = map.getRowData(mapID);
            const mapName = mapRow?.MapName_lang;
            const expansionID = overrideMapExpansion.get(mapID) ?? mapRow?.ExpansionID;
            assert(typeof mapName === 'string', `Invalid mapName for map ID ${mapID.toString()}`);
            assert(typeof expansionID === 'number', `Invalid expansionID for map ID ${mapID.toString()}`);

            const journalInstanceID = mapID2JournalInstanceID.get(mapID);
            assert(typeof journalInstanceID === 'number', `No journalInstanceID found for mapID ${mapID.toString()}`);

            const shortName = shortNames.get(id);
            const portalSpellID = overridePortalSpell.get(mapID) ?? destinationMap.get(mapName);

            expansionData[expansionID].dungeons.push({
                challengeMapID: id,
                name,
                mapID,
                journalInstanceID,
                shortName,
                portalSpellID,
            });
        });

        const text = expansionData
            .filter(({ dungeons }) => dungeons.length > 0)
            .map(({ name: expansionName, dungeons }) => {
                const dungeonText = dungeons
                    .map(({
                        challengeMapID,
                        name,
                        journalInstanceID,
                        shortName,
                        portalSpellID,
                    }) => {
                        if (shortName && portalSpellID) {
                            return `[${challengeMapID.toString()}] = {${journalInstanceID.toString()}, "${shortName}", ${portalSpellID.toString()}}, -- ${name}`;
                        }
                        if (shortName) {
                            return `[${challengeMapID.toString()}] = {${journalInstanceID.toString()}, "${shortName}"}, -- ${name}`;
                        }
                        if (portalSpellID) {
                            return `[${challengeMapID.toString()}] = {${journalInstanceID.toString()}, nil, ${portalSpellID.toString()}}, -- ${name}`;
                        }
                        return `[${challengeMapID.toString()}] = {${journalInstanceID.toString()}}, -- ${name}`;
                    })
                    .join('\n');

                return `-- ${expansionName}\n${dungeonText}`;
            })
            .join('\n\n');

        return text;
    },
});
