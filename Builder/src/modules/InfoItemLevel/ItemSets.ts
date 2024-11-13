import assert from 'node:assert';

import type { Task } from '../../task.ts';

// base set id is started from Dragonflight Season 1
const baseSetID = 1525;

const task: Task = {
    key: 'InfoItemLevelItemSets',
    version: 3,
    fileDataIDs: [
        1361031, // dbfilesclient/chrclasses.db2
        1343609, // dbfilesclient/itemset.db2
        1572924, // dbfilesclient/itemsparse.db2
    ],
    handler: ([
        chrClasses,
        itemSet,
        itemSparse,
    ]) => {
        const classes = chrClasses
            .getAllIDs()
            .map((classID) => {
                const row = chrClasses.getRowData(classID);
                const flag = row?.Flags as number;
                const className = row?.Name_lang;
                assert(typeof className === 'string', `No class name for class ${classID.toString()}`);

                // eslint-disable-next-line no-bitwise
                return (flag & 0x2) > 0 && (flag & 0x10000) === 0
                    ? { className, classID }
                    : undefined;
            })
            .filter((v): v is { className: string; classID: number } => !!v);

        const getOnlyForClass = (itemID: number) => {
            const itemInfo = itemSparse.getRowData(itemID);
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
                const name = row?.Name_lang;

                if (rawItemIDs[4] !== 0 && rawItemIDs[5] === 0) {
                    const itemIDs = rawItemIDs.slice(0, 5);
                    const classID = getOnlyForClass(itemIDs[0]);
                    const isVaild = classID !== undefined && itemIDs.slice(1)
                        .every((itemID) => getOnlyForClass(itemID) === classID);

                    if (classID !== undefined && isVaild) {
                        assert(typeof name === 'string', `No name for set ${id.toString()}`);

                        const sets = classTierSets.get(classID) ?? [];
                        sets.push({ itemIDs, name });
                        classTierSets.set(classID, sets);
                    }
                }
            });

        const classSets = classes.flatMap(({ className, classID }) => {
            const tierSets = classTierSets.get(classID);
            assert(tierSets && tierSets.length >= 2, `No sets for class ${className} ${classID.toString()}`);

            return [
                `-- ${className}`,
                ...tierSets.slice(-2).flatMap(({ itemIDs, name }, index) => [
                    `-- ${name}`,
                    itemIDs.map((itemID) => `[${itemID.toString()}] = ${(index + 1).toString()},`).join(' '),
                ]),
            ];
        });

        return classSets.join('\n');
    },
};

export default task;
