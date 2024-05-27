import assert from 'node:assert';

import { registerTask } from '../../task.ts';
import { versions, latestVersion } from '../../client.ts';

interface MapData {
    mapID: number,
    mapName: string,
}

registerTask({
    key: 'AutoLogging',
    version: 1,
    fileDataIDs: [
        1237438, // dbfilesclient/journalinstance.db2
        1349477, // dbfilesclient/map.db2
    ],
    handler: async ([
        journalInstance,
        map,
    ]) => {
        const liveMajor = versions[0].semver?.major;
        const latestMajor = latestVersion.semver.major;
        assert(liveMajor, 'Missing major version for live');

        const normalMapIDs = new Set<number>();
        journalInstance.getAllIDs().forEach((id) => {
            const row = journalInstance.getRowData(id);
            const mapID = row?.MapID as number;
            const flags = row?.Flags as number;

            // eslint-disable-next-line no-bitwise
            if (mapID > 0 && (flags & 0x2) === 0) {
                normalMapIDs.add(mapID);
            }
        });

        const dungeons: MapData[] = [];
        const raids: MapData[] = [];
        normalMapIDs.forEach((mapID) => {
            const row = map.getRowData(mapID);
            const expansionID = row?.ExpansionID as number;
            const instanceType = row?.InstanceType as number;
            const mapName = row?.MapName_lang;
            assert(typeof mapName === 'string', `No map name for map ${mapID.toString()}`);

            if (expansionID === (liveMajor - 1) || expansionID === (latestMajor - 1)) {
                if (instanceType === 1) {
                    dungeons.push({ mapID, mapName });
                } else if (instanceType === 2) {
                    raids.push({ mapID, mapName });
                }
            }
        });

        dungeons.sort((a, b) => a.mapID - b.mapID);
        raids.sort((a, b) => a.mapID - b.mapID);

        const dungeonsText = dungeons.map(({ mapID, mapName }) => `    [${mapID.toString()}] = true, -- ${mapName}`).join('\n');
        const raidsText = raids.map(({ mapID, mapName }) => `    [${mapID.toString()}] = true, -- ${mapName}`).join('\n');

        return `local dungeons = {\n${dungeonsText}\n}\n\nlocal raids = {\n${raidsText}\n}`;
    },
});
