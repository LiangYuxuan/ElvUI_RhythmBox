import assert from 'node:assert';

import { versions, latestVersion } from '../../client.ts';

import type { Task } from '../../task.ts';
import type { DBDParser } from '@rhyster/wow-casc-dbc';

interface ItemGroupIlvlScalingEntryData {
    achievementID: number,
    achievementName: string,
    achievementItemLevel: number,
    currencyID: number,
    currencyName: string,
    maxItemLevel: number,
    minItemLevel: number,
    isAverageItemLevel: boolean,
    conditionalCostScaling: number,
    maxCurrencyCount: number,
    upgradePath: {
        itemLevel: number,
        currencyCount: number,
        totalCurrencyCount: number,
        label: string,
        sequenceValue: number,
        itemBonusListID: number,
    }[],
}

interface ItemGroupIlvlScalingData {
    id: number,
    entries: ItemGroupIlvlScalingEntryData[],
}

interface BasicItemGroupIlvlScalingData {
    id: number,
    entries: number[],
}

interface ItemBonusListGroupEntryData {
    itemBonusListGroupEntryID: number,
    itemBonusListID: number,
    itemLevel: number,
    label: string,
    sequenceValue: number,
    itemExtendedCostID: number,
    currencyID: number,
    currencyCount: number,
}

const isAverageItemLevelCriteriaID = [
    112994,
];

const getItemGroupIlvlScalingData = (
    itemGroupIlvlScalingEntry: DBDParser,
    playerCondition: DBDParser,
    achievement: DBDParser,
    criteriaTree: DBDParser,
    currencyTypes: DBDParser,
    length: number,
): ItemGroupIlvlScalingData[] => {
    const itemGroupIlvlScalingEntryXScalingID = new Map<number, BasicItemGroupIlvlScalingData>();
    itemGroupIlvlScalingEntry.wdc.relationships.forEach((value, key) => {
        if (!itemGroupIlvlScalingEntryXScalingID.has(value)) {
            itemGroupIlvlScalingEntryXScalingID.set(value, {
                id: value,
                entries: [],
            });
        }

        itemGroupIlvlScalingEntryXScalingID.get(value)?.entries.push(key);
    });

    const basicDatas = [...itemGroupIlvlScalingEntryXScalingID.values()]
        .sort((a, b) => b.id - a.id)
        .slice(0, length);

    const result = basicDatas.map((data): ItemGroupIlvlScalingData => {
        const entries = data.entries
            .map((id): ItemGroupIlvlScalingEntryData | undefined => {
                const row = itemGroupIlvlScalingEntry.getRowData(id);
                const currencyTypeID = row?.CurrencyTypeID as number;
                const playerConditionID = row?.PlayerConditionID as number;
                const conditionalCostScaling = row?.ConditionalCostScaling as number;

                if (playerConditionID > 0) {
                    const playerConditionRow = playerCondition.getRowData(playerConditionID);
                    const achievementIDs = playerConditionRow?.Achievement as number[];

                    const achievementID = achievementIDs[0];
                    assert(achievementID > 0, `Invalid achievement ID ${achievementID.toString()} for PlayerCondition ${playerConditionID.toString()}`);

                    const achievementRow = achievement.getRowData(achievementID);
                    const criteriaTreeID = achievementRow?.Criteria_tree as number;
                    const title = achievementRow?.Title_lang;
                    assert(typeof title === 'string', `Missing title for achievement ID ${achievementID.toString()}`);

                    let achievementItemLevel: number | undefined;
                    let isAverageItemLevel = false;
                    criteriaTree.getAllIDs().some((i) => {
                        const criteriaTreeRow = criteriaTree.getRowData(i);
                        const parent = criteriaTreeRow?.Parent as number;
                        const amount = criteriaTreeRow?.Amount as number;
                        const criteriaID = criteriaTreeRow?.CriteriaID as number;

                        if (parent === criteriaTreeID) {
                            achievementItemLevel = amount;
                            isAverageItemLevel = isAverageItemLevelCriteriaID.includes(criteriaID);
                            return true;
                        }
                        return false;
                    });
                    assert(typeof achievementItemLevel === 'number', `Failed to get max item level for achievement ID ${achievementID.toString()}`);

                    const currencyRow = currencyTypes.getRowData(currencyTypeID);
                    const currencyName = currencyRow?.Name_lang;
                    assert(typeof currencyName === 'string', `Missing name for currency ID ${currencyTypeID.toString()}`);

                    return {
                        achievementID,
                        achievementName: title,
                        achievementItemLevel,
                        currencyID: currencyTypeID,
                        currencyName,
                        maxItemLevel: 0,
                        minItemLevel: 0,
                        isAverageItemLevel,
                        conditionalCostScaling,
                        maxCurrencyCount: 0,
                        upgradePath: [],
                    };
                }

                return undefined;
            })
            .filter((entry): entry is ItemGroupIlvlScalingEntryData => !!entry)
            .sort((a, b) => a.achievementItemLevel - b.achievementItemLevel);

        return {
            id: data.id,
            entries,
        };
    });

    return result;
};

const task: Task = {
    key: 'CrestAchievement',
    version: 1,
    fileDataIDs: [
        5015219, // dbfilesclient/itemgroupilvlscalingentry.db2
        1045411, // dbfilesclient/playercondition.db2
        1260179, // dbfilesclient/achievement.db2
        1263818, // dbfilesclient/criteriatree.db2
        1095531, // dbfilesclient/currencytypes.db2
        3755382, // dbfilesclient/itembonuslistgroup.db2
        3025306, // dbfilesclient/itembonuslistgroupentry.db2
        959070, // dbfilesclient/itembonus.db2
        801681, // dbfilesclient/itemextendedcost.db2
        7322705, // dbfilesclient/itemscalingconfig.db2
        4620073, // dbfilesclient/sharedstring.db2
    ],
    handler: async ([
        itemGroupIlvlScalingEntry,
        playerCondition,
        achievement,
        criteriaTree,
        currencyTypes,
        itemBonusListGroup,
        itemBonusListGroupEntry,
        itemBonus,
        itemExtendedCost,
        itemScalingConfig,
        sharedString,
    ]) => {
        const liveMajor = versions[0].semver?.major;
        const liveMinor = versions[0].semver?.minor;
        const livePatch = versions[0].semver?.patch;
        const latestMajor = latestVersion.semver.major;
        const latestMinor = latestVersion.semver.minor;
        assert(typeof liveMajor === 'number', 'Missing major version for live');
        assert(typeof liveMinor === 'number', 'Missing minor version for live');
        assert(typeof livePatch === 'number', 'Missing patch version for live');

        const itemBonusListGroupEntryXGroupID = new Map<number, number[]>();
        itemBonusListGroupEntry.wdc.relationships.forEach((value, key) => {
            if (!itemBonusListGroupEntryXGroupID.has(value)) {
                itemBonusListGroupEntryXGroupID.set(value, []);
            }

            itemBonusListGroupEntryXGroupID.get(value)?.push(key);
        });

        const itemBonusList2ItemBonus = new Map<number, number[]>();
        itemBonus.getAllIDs().forEach((id) => {
            const itemBonusListID = itemBonus.wdc.getRowRelationship(id);
            if (itemBonusListID !== undefined) {
                if (!itemBonusList2ItemBonus.has(itemBonusListID)) {
                    itemBonusList2ItemBonus.set(itemBonusListID, []);
                }

                itemBonusList2ItemBonus.get(itemBonusListID)?.push(id);
            }
        });

        const itemGroupIlvlScalingDatas = getItemGroupIlvlScalingData(
            itemGroupIlvlScalingEntry,
            playerCondition,
            achievement,
            criteriaTree,
            currencyTypes,
            (latestMajor > liveMajor || latestMinor > liveMinor) ? 2 : 1,
        );

        itemGroupIlvlScalingDatas.forEach((data) => {
            const itemBonusListGroupIDs = itemBonusListGroup
                .getAllIDs()
                .filter((id) => {
                    const row = itemBonusListGroup.getRowData(id);
                    const itemGroupIlvlScalingID = row?.ItemGroupIlvlScalingID as number;
                    return itemGroupIlvlScalingID === data.id;
                });

            itemBonusListGroupIDs.forEach((itemBonusListGroupID) => {
                const itemBonusListGroupEntryIDs = itemBonusListGroupEntryXGroupID
                    .get(itemBonusListGroupID);
                assert(itemBonusListGroupEntryIDs !== undefined, `Missing entries for ItemBonusListGroupID ${itemBonusListGroupID.toString()}`);

                const itemBonusListGroupEntryDatas = itemBonusListGroupEntryIDs
                    .map((itemBonusListGroupEntryID): ItemBonusListGroupEntryData | undefined => {
                        const row = itemBonusListGroupEntry.getRowData(itemBonusListGroupEntryID);
                        const itemBonusListID = row?.ItemBonusListID as number;
                        const sequenceValue = row?.SequenceValue as number;
                        const itemExtendedCostID = row?.ItemExtendedCostID as number;
                        const flags = row?.Flags as number;

                        // eslint-disable-next-line no-bitwise
                        if ((flags & 0x01) === 0) { // not disabled
                            assert(itemBonusListID > 0, `Invalid ItemBonusListID ${itemBonusListID.toString()} for ItemBonusListGroupEntry ${itemBonusListGroupEntryID.toString()}`);

                            let scalingItemLevel: number | undefined;
                            let label: string | undefined;

                            const itemBonusIDs = itemBonusList2ItemBonus.get(itemBonusListID);
                            itemBonusIDs?.forEach((itemBonusID) => {
                                const itemBonusRow = itemBonus.getRowData(itemBonusID);
                                const values = itemBonusRow?.Value as number[];
                                const type = itemBonusRow?.Type as number;
                                if (type === 49) { // Scaling Config and Req Level
                                    const configRow = itemScalingConfig.getRowData(values[0]);
                                    const itemLevel = configRow?.ItemLevel as number;

                                    scalingItemLevel = itemLevel;
                                } else if (type === 34) { // ItemBonusListGroupID
                                    const stringRow = sharedString.getRowData(values[1]);
                                    const string = stringRow?.String_lang;
                                    assert(typeof string === 'string', `Missing string for shared string ID ${values[1].toString()}`);

                                    label = string;
                                }
                            });

                            if (scalingItemLevel === undefined || label === undefined) {
                                // some entries are not actually used,
                                // and don't have itemLevel or label, skip them
                                return undefined;
                            }

                            let currencyID = 0;
                            let currencyCount = 0;

                            if (itemExtendedCostID > 0) {
                                const costRow = itemExtendedCost.getRowData(itemExtendedCostID);
                                const currencyIDs = costRow?.CurrencyID as number[];
                                const currencyCounts = costRow?.CurrencyCount as number[];

                                [currencyID] = currencyIDs;
                                [currencyCount] = currencyCounts;
                            }

                            return {
                                itemBonusListGroupEntryID,
                                itemBonusListID,
                                itemLevel: scalingItemLevel,
                                label,
                                sequenceValue,
                                itemExtendedCostID,
                                currencyID,
                                currencyCount,
                            };
                        }

                        return undefined;
                    })
                    .filter((entry): entry is ItemBonusListGroupEntryData => !!entry)
                    .sort((a, b) => a.sequenceValue - b.sequenceValue);

                if (itemBonusListGroupEntryDatas.length > 0) {
                    const { length } = itemBonusListGroupEntryDatas;
                    const last = itemBonusListGroupEntryDatas[length - 1];

                    assert(length === last.sequenceValue, `Missing sequence values for ItemBonusListGroupID ${itemBonusListGroupID.toString()} with last sequence value ${last.sequenceValue.toString()} and length ${length.toString()}`);

                    const currencyID = itemBonusListGroupEntryDatas.reduce((prev, entry) => {
                        if (entry.currencyID > 0) {
                            assert(prev === 0 || prev === entry.currencyID, `Multiple currency IDs found for ItemBonusListGroupID ${itemBonusListGroupID.toString()}`);
                            return entry.currencyID;
                        }
                        return prev;
                    }, 0);
                    const entry = data.entries.find((e) => e.currencyID === currencyID);
                    assert(entry, `No matching entry found for ItemBonusListGroupID ${itemBonusListGroupID.toString()} with currency ID ${currencyID.toString()}`);

                    entry.minItemLevel = itemBonusListGroupEntryDatas[0].itemLevel;
                    entry.maxItemLevel = last.itemLevel;

                    let totalCurrencyCount = 0;
                    itemBonusListGroupEntryDatas.forEach((e) => {
                        entry.upgradePath.push({
                            itemLevel: e.itemLevel,
                            currencyCount: e.currencyCount,
                            totalCurrencyCount: 0,
                            label: e.label,
                            sequenceValue: e.sequenceValue,
                            itemBonusListID: e.itemBonusListID,
                        });

                        totalCurrencyCount += e.currencyCount;
                    });

                    entry.maxCurrencyCount = totalCurrencyCount;

                    entry.upgradePath = entry.upgradePath.map((e) => {
                        totalCurrencyCount -= e.currencyCount;

                        return {
                            ...e,
                            totalCurrencyCount,
                        };
                    });
                }
            });
        });

        const texts = itemGroupIlvlScalingDatas.map((data) => {
            let text = `-- ItemGroupIlvlScalingID ${data.id.toString()}`;
            data.entries.forEach((entry) => {
                text += '\n{\n';
                text += `    achievementID = ${entry.achievementID.toString()}, -- ${entry.achievementName}\n`;
                text += `    achievementItemLevel = ${entry.achievementItemLevel.toString()},\n`;
                text += `    currencyID = ${entry.currencyID.toString()}, -- ${entry.currencyName}\n`;
                text += `    maxItemLevel = ${entry.maxItemLevel.toString()},\n`;
                text += `    minItemLevel = ${entry.minItemLevel.toString()},\n`;
                text += `    isAverageItemLevel = ${entry.isAverageItemLevel.toString()},\n`;
                text += `    conditionalCostScaling = ${entry.conditionalCostScaling.toString()},\n`;
                text += `    maxCurrencyCount = ${entry.maxCurrencyCount.toString()},\n`;

                text += '    upgradePath = {\n';
                entry.upgradePath.forEach((path) => {
                    text += `        ${path.itemLevel.toString()}, -- ${path.label} ${path.sequenceValue.toString()}/${entry.upgradePath.length.toString()}\n`;
                });
                text += '    },\n';

                const maxCurrencyCountTextLength = entry.upgradePath.reduce((max, path) => {
                    const currencyCountTextLength = path.currencyCount.toString().length;
                    return currencyCountTextLength > max ? currencyCountTextLength : max;
                }, 0);

                text += '    upgradePathCost = {\n';
                entry.upgradePath.forEach((path) => {
                    const currencyCountText = path.currencyCount.toString();
                    text += `        [${path.itemLevel.toString()}] = ${currencyCountText}, ${' '.repeat(maxCurrencyCountTextLength - currencyCountText.length)}-- ${path.label} ${path.sequenceValue.toString()}/${entry.upgradePath.length.toString()}\n`;
                });
                text += '    },\n';

                const maxTotalCurrencyCountTextLength = entry.upgradePath.reduce((max, path) => {
                    const totalCurrencyCountTextLength = path.totalCurrencyCount.toString().length;
                    return totalCurrencyCountTextLength > max ? totalCurrencyCountTextLength : max;
                }, 0);

                text += '    itemLevelXCost = {\n';
                entry.upgradePath.forEach((path) => {
                    const totalCurrencyCountText = path.totalCurrencyCount.toString();
                    text += `        [${path.itemLevel.toString()}] = ${totalCurrencyCountText}, ${' '.repeat(maxTotalCurrencyCountTextLength - totalCurrencyCountText.length)}-- ${path.label} ${path.sequenceValue.toString()}/${entry.upgradePath.length.toString()}\n`;
                });
                text += '    },\n';

                text += '    itemBonusLists = {\n';
                entry.upgradePath.forEach((path) => {
                    const totalCurrencyCountText = path.totalCurrencyCount.toString();
                    text += `        [${path.itemBonusListID.toString()}] = ${totalCurrencyCountText}, ${' '.repeat(maxTotalCurrencyCountTextLength - totalCurrencyCountText.length)}-- ${path.label} ${path.sequenceValue.toString()}/${entry.upgradePath.length.toString()}\n`;
                });
                text += '    },\n';
                text += '},';
            });
            return text;
        });

        return texts.join('\n');
    },
};

export default task;
