/* eslint-disable no-bitwise */

import assert from 'node:assert';

import { DBDParser } from '@rhyster/wow-casc-dbc';

import { registerTask } from '../../task.ts';

// base set id and tier id is started from Dragonflight Season 1
const baseSetID = 1525;
const baseTierID = 29;

registerTask({
    key: 'InfoItemLevelItemSets',
    version: 1,
    fileDataIDs: [
        1361031,
        1343609,
        1273408,
    ],
    handler: async (readers) => {
        const [
            chrClasses,
            itemSet,
            itemSearchName,
        ] = await Promise.all(readers.map(async (reader) => DBDParser.parse(reader)));

        const classes = chrClasses
            .getAllIDs()
            .map((id) => {
                const row = chrClasses.getRowData(id);
                const flag = row?.Flags as number;

                return (flag & 0x2) > 0 && (flag & 0x10000) === 0
                    ? { className: row?.Name_lang as string, classID: id }
                    : undefined;
            })
            .filter((v): v is { className: string; classID: number } => !!v);

        const getOnlyForClass = (itemID: number) => {
            const itemInfo = itemSearchName.getRowData(itemID);
            const allow = itemInfo?.AllowableClass as number;
            const log = Math.log2(allow);
            return log % 1 === 0 ? log + 1 : undefined;
        };

        const classTierSets = new Map<number, { itemIDs: number[], name: string }[]>();

        itemSet
            .getAllIDs()
            .filter((id) => id >= baseSetID) // ignore legacy sets
            .forEach((id) => {
                const row = itemSet.getRowData(id);
                const rawItemIDs = row?.ItemID as number[];

                if (rawItemIDs[4] !== 0 && rawItemIDs[5] === 0) {
                    const itemIDs = rawItemIDs.slice(0, 5);

                    const classID = itemIDs.reduce<number | undefined>((acc, itemID) => {
                        if (!acc) {
                            return undefined;
                        }
                        return acc === getOnlyForClass(itemID) ? acc : undefined;
                    }, getOnlyForClass(itemIDs[0]));

                    if (classID) {
                        const sets = classTierSets.get(classID) ?? [];
                        sets.push({ itemIDs, name: row?.Name_lang as string });
                        classTierSets.set(classID, sets);
                    }
                }
            });

        const classSets = classes.map(({ className, classID }) => {
            const tierSets = classTierSets.get(classID);
            assert(tierSets && tierSets.length >= 2, `No sets for class ${className} ${classID.toString()}`);

            const outputSets = tierSets.slice(-2);
            const outputIndex = baseTierID + tierSets.length - 2;

            let result = `    -- ${className}\n`;
            outputSets.forEach(({ itemIDs, name }, index) => {
                result += `    -- ${name}\n   `;
                itemIDs.forEach((itemID) => {
                    result += ` [${itemID.toString()}] = ${(outputIndex + index).toString()},`;
                });
                result += '\n';
            });
            return result;
        });

        return `local tierSetItemIDs = {\n${classSets.join('')}}`;
    },
});
