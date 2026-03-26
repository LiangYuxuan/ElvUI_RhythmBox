import assert from 'node:assert';

import type { Task } from '../../task.ts';
import type { DBDParser } from '@rhyster/wow-casc-dbc';

interface BasicCreateItemData {
    createSpellID: number,
    itemID: number,
    qualityID?: number,
}

interface ExtendedItemData extends BasicCreateItemData {
    maxLevel: number,
}

const overrideMaxLevel = new Map<number, number>([
    [188023, 50], // Skaggldrynk
]);

const ignoreItemIDs = new Set<number>([
    3387, // Limited Invulnerability Potion
]);

const getOutputString = (
    itemSparse: DBDParser,
    input: ExtendedItemData[],
) => {
    const compare = (a: BasicCreateItemData, b: BasicCreateItemData): number => {
        if (a.createSpellID !== b.createSpellID) {
            return b.createSpellID - a.createSpellID;
        }

        if (
            a.qualityID !== undefined
            && b.qualityID !== undefined
            && a.qualityID !== b.qualityID
        ) {
            return b.qualityID - a.qualityID;
        }

        return b.itemID - a.itemID;
    };

    const datas = input
        .filter(({ itemID }, index, array) => {
            const firstIndex = array.findIndex((data) => data.itemID === itemID);
            return index === firstIndex;
        })
        .sort(compare);

    const itemIDMaxLength = Math.max(
        ...datas.map(({ itemID }) => itemID.toString().length),
    );

    const content = datas
        .map(({ itemID, qualityID, maxLevel }) => {
            const row = itemSparse.getRowData(itemID);
            if (!row) {
                return undefined;
            }

            const idText = itemID.toString();
            const display = row.Display_lang as string | undefined;
            const itemName = typeof display === 'string' ? display : idText;

            let text = '';
            if (maxLevel > 0) {
                if (maxLevel % 10 === 9) {
                    text += `{${idText}, ${' '.repeat(itemIDMaxLength - idText.length)}'mylevel <  ${(maxLevel + 1).toString()}'}, -- ${itemName}`;
                } else {
                    text += `{${idText}, ${' '.repeat(itemIDMaxLength - idText.length)}'mylevel <= ${maxLevel.toString()}'}, -- ${itemName}`;
                }
            } else {
                text += `{${idText}, ${' '.repeat(itemIDMaxLength - idText.length)}true}, -- ${itemName}`;
            }
            if (qualityID !== undefined) {
                text += ` (Tier ${(qualityID > 10 ? qualityID - 12 : qualityID).toString()})`;
            }

            return text;
        })
        .join('\n');

    return content;
};

const getSpellMaxLevel = (
    spellID2SpellLevelsID: Map<number, number>,
    spellLevels: DBDParser,
    spellID: number,
): number => {
    if (overrideMaxLevel.has(spellID)) {
        const maxLevel = overrideMaxLevel.get(spellID);
        assert(maxLevel !== undefined, `Unexpected undefined override max level for spell ID ${spellID.toString()}`);

        return maxLevel;
    }

    const spellLevelsID = spellID2SpellLevelsID.get(spellID);
    if (spellLevelsID === undefined) {
        return 0;
    }

    const row = spellLevels.getRowData(spellLevelsID);
    const maxLevel = row?.MaxLevel as number;
    const maxPassiveAuraLevel = row?.MaxPassiveAuraLevel as number;

    return maxLevel > 0 ? maxLevel : maxPassiveAuraLevel;
};

const getItemSpell = (
    itemID2MapID: Map<number, number>,
    itemXItemEffect: DBDParser,
    itemEffect: DBDParser,
    itemID: number,
): number | undefined => {
    const itemXItemEffectIDs = itemID2MapID.get(itemID);
    if (itemXItemEffectIDs === undefined) {
        return undefined;
    }

    const mapRow = itemXItemEffect.getRowData(itemXItemEffectIDs);
    const itemEffectID = mapRow?.ItemEffectID as number;

    const row = itemEffect.getRowData(itemEffectID);
    if (!row) {
        return undefined;
    }

    return row.SpellID as number;
};

const getSpellCreateItemData = (
    spellID2SpellEffectIDs: Map<number, number[]>,
    spellEffect: DBDParser,
    craftingData: DBDParser,
    craftingDataItemQuality: DBDParser,
    item: DBDParser,
    createSpellID: number,
): BasicCreateItemData[] => {
    const effectIDs = spellID2SpellEffectIDs.get(createSpellID);
    if (!effectIDs) {
        return [];
    }

    const createdItemIDs = effectIDs
        .flatMap((effectID): BasicCreateItemData[] => {
            const row = spellEffect.getRowData(effectID);
            const effectType = row?.Effect as number;
            const effectItemType = row?.EffectItemType as number;
            const effectMiscValue = row?.EffectMiscValue as number[];

            if (effectType === 24) { // Create Item
                return [
                    {
                        createSpellID,
                        itemID: effectItemType,
                    },
                ];
            }

            if (effectType === 288) { // Crafting Item
                const craftingID = effectMiscValue[0];
                const craftingDataRow = craftingData.getRowData(craftingID);
                const type = craftingDataRow?.Type as number;
                const craftedItemID = craftingDataRow?.CraftedItemID as number;

                if (type === 0 && craftedItemID > 0) {
                    return [
                        {
                            createSpellID,
                            itemID: craftedItemID,
                        },
                    ];
                }

                const craftingItem = craftingDataItemQuality
                    .getAllIDs()
                    .map((id) => {
                        const data = craftingDataItemQuality.getRowData(id);
                        const itemID = data?.ItemID as number;
                        const craftingDataID = data?.CraftingDataID as number;

                        if (craftingDataID === craftingID) {
                            const itemRow = item.getRowData(itemID);
                            if (itemRow) {
                                const craftingQualityID = itemRow.CraftingQualityID as number;

                                return {
                                    createSpellID,
                                    itemID,
                                    qualityID: craftingQualityID,
                                };
                            }
                        }

                        return undefined;
                    })
                    .filter((data): data is NonNullable<typeof data> => data !== undefined);

                return craftingItem;
            }

            return [];
        });

    return createdItemIDs;
};

const getSkillLineSpellIDs = (
    skillLine: DBDParser,
    skillLineAbility: DBDParser,
): number[] => {
    const skillLines = skillLine
        .getAllIDs()
        .filter((id) => {
            const row = skillLine.getRowData(id);
            const categoryID = row?.CategoryID as number;

            if (categoryID === 11) {
                return true;
            }

            return false;
        });

    const skillLineSpellIDs = skillLineAbility
        .getAllIDs()
        .map((id) => {
            const row = skillLineAbility.getRowData(id);
            const spellID = row?.Spell as number;
            const skillupSkillLineID = row?.SkillupSkillLineID as number;

            if (skillLines.includes(skillupSkillLineID)) {
                return spellID;
            }

            return undefined;
        })
        .filter((id): id is number => id !== undefined);

    return skillLineSpellIDs;
};

const task: Task = {
    key: 'AutoButtonSmart',
    version: 1,
    fileDataIDs: [
        1240935, // dbfilesclient/skillline.db2
        1266278, // dbfilesclient/skilllineability.db2
        1140088, // dbfilesclient/spelleffect.db2
        4545611, // dbfilesclient/craftingdata.db2
        4545612, // dbfilesclient/craftingdataitemquality.db2
        841626, // dbfilesclient/item.db2
        3177687, // dbfilesclient/itemxitemeffect.db2
        969941, // dbfilesclient/itemeffect.db2
        1139939, // dbfilesclient/spellcategories.db2
        1347275, // dbfilesclient/spelllabel.db2
        1140079, // dbfilesclient/spelllevels.db2
        1572924, // dbfilesclient/itemsparse.db2
    ],
    handler: async ([
        skillLine,
        skillLineAbility,
        spellEffect,
        craftingData,
        craftingDataItemQuality,
        item,
        itemXItemEffect,
        itemEffect,
        spellCategories,
        spellLabel,
        spellLevels,
        itemSparse,
    ]) => {
        const spellID2SpellEffectIDs = new Map<number, number[]>();
        spellEffect.getAllIDs().forEach((id) => {
            const spellID = spellEffect.wdc.getRowRelationship(id);
            if (spellID !== undefined) {
                if (!spellID2SpellEffectIDs.has(spellID)) {
                    spellID2SpellEffectIDs.set(spellID, []);
                }

                spellID2SpellEffectIDs.get(spellID)?.push(id);
            }
        });

        const itemID2MapID = new Map<number, number>();
        itemXItemEffect.getAllIDs().forEach((id) => {
            const itemID = itemXItemEffect.wdc.getRowRelationship(id);
            if (itemID !== undefined) {
                itemID2MapID.set(itemID, id);
            }
        });

        const spellID2CategoryID = new Map<number, number>(
            spellCategories.getAllIDs().map((id) => {
                const row = spellCategories.getRowData(id);
                const spellID = row?.SpellID as number;
                const categoryID = row?.Category as number;

                return [spellID, categoryID];
            }),
        );

        const spellID2Labels = new Map<number, number[]>();
        spellLabel.getAllIDs().forEach((id) => {
            const row = spellLabel.getRowData(id);
            const spellID = row?.SpellID as number;
            const labelID = row?.LabelID as number;

            if (!spellID2Labels.has(spellID)) {
                spellID2Labels.set(spellID, []);
            }

            spellID2Labels.get(spellID)?.push(labelID);
        });

        const spellID2SpellLevelsID = new Map<number, number>();
        spellLevels.getAllIDs().forEach((id) => {
            const spellID = spellLevels.wdc.getRowRelationship(id);
            if (spellID !== undefined) {
                spellID2SpellLevelsID.set(spellID, id);
            }
        });

        const skillLineSpellIDs = getSkillLineSpellIDs(
            skillLine,
            skillLineAbility,
        );

        const drums: ExtendedItemData[] = [];
        const invisibilityPotions: ExtendedItemData[] = [];

        skillLineSpellIDs.forEach((spellID) => {
            const itemDatas = getSpellCreateItemData(
                spellID2SpellEffectIDs,
                spellEffect,
                craftingData,
                craftingDataItemQuality,
                item,
                spellID,
            );

            itemDatas.forEach((itemData) => {
                const { itemID } = itemData;

                if (ignoreItemIDs.has(itemID)) {
                    return;
                }

                const itemSpellID = getItemSpell(
                    itemID2MapID,
                    itemXItemEffect,
                    itemEffect,
                    itemID,
                );
                if (itemSpellID === undefined) {
                    return;
                }

                if (spellID2Labels.get(itemSpellID)?.includes(615) === true) {
                    const maxLevel = getSpellMaxLevel(
                        spellID2SpellLevelsID,
                        spellLevels,
                        itemSpellID,
                    );

                    drums.push({
                        ...itemData,
                        maxLevel,
                    });
                    return;
                }

                const categoryID = spellID2CategoryID.get(itemSpellID);

                if (categoryID === 37) {
                    const maxLevel = getSpellMaxLevel(
                        spellID2SpellLevelsID,
                        spellLevels,
                        itemSpellID,
                    );

                    invisibilityPotions.push({
                        ...itemData,
                        maxLevel,
                    });
                }
            });
        });

        const runes: ExtendedItemData[] = [];
        itemSparse
            .getAllIDs()
            .forEach((itemID) => {
                const row = itemSparse.getRowData(itemID);
                const display = row?.Display_lang;
                assert(typeof display === 'string', `Invalid name for item ID ${itemID.toString()}`);

                if (display.endsWith('Augment Rune')) {
                    const itemXItemEffectIDs = itemID2MapID.get(itemID);
                    if (itemXItemEffectIDs === undefined) {
                        return;
                    }

                    const mapRow = itemXItemEffect.getRowData(itemXItemEffectIDs);
                    const itemEffectID = mapRow?.ItemEffectID as number;

                    const itemEffectRow = itemEffect.getRowData(itemEffectID);
                    if (!itemEffectRow) {
                        return;
                    }

                    const charges = itemEffectRow.Charges as number;
                    const spellID = itemEffectRow.SpellID as number;

                    if (charges === 0) {
                        const maxLevel = getSpellMaxLevel(
                            spellID2SpellLevelsID,
                            spellLevels,
                            spellID,
                        );

                        runes.push({
                            createSpellID: 0,
                            itemID,
                            maxLevel,
                        });
                    }
                }
            });

        return new Map<string, string>([
            [
                'Drum',
                getOutputString(itemSparse, drums),
            ],
            [
                'Rune',
                getOutputString(itemSparse, runes),
            ],
            [
                'InvisibilityPotions',
                getOutputString(itemSparse, invisibilityPotions),
            ],
        ]);
    },
};

export default task;
