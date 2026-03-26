import assert from 'node:assert';

import { versions, latestVersion } from '../../client.ts';

import type { Task } from '../../task.ts';
import type { DBDParser } from '@rhyster/wow-casc-dbc';

interface BasicCreateItemData {
    createSpellID: number,
    itemID: number,
    qualityID?: number,
}

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

const getSkillLineSpellIDsForExpansion = (
    skillLine: DBDParser,
    skillLineAbility: DBDParser,
    expansion: number,
): number[] => {
    const skillLines = skillLine
        .getAllIDs()
        .filter((id) => {
            const row = skillLine.getRowData(id);
            const categoryID = row?.CategoryID as number;
            const parentTierIndex = row?.ParentTierIndex as number;

            if (
                categoryID === 11
                && parentTierIndex === (expansion + 4)
            ) {
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
    key: 'QuickMacroConsumables',
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
        itemSparse,
    ]) => {
        const liveMajor = versions[0].semver?.major;
        const liveMinor = versions[0].semver?.minor;
        const livePatch = versions[0].semver?.patch;
        const latestMajor = latestVersion.semver.major;
        assert(typeof liveMajor === 'number', 'Missing major version for live');
        assert(typeof liveMinor === 'number', 'Missing minor version for live');
        assert(typeof livePatch === 'number', 'Missing patch version for live');

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

        const skillLineSpellIDs = getSkillLineSpellIDsForExpansion(
            skillLine,
            skillLineAbility,
            latestMajor - 1,
        );

        if (liveMajor < latestMajor || (liveMinor < 1 && livePatch < 1)) {
            skillLineSpellIDs.push(
                ...getSkillLineSpellIDsForExpansion(
                    skillLine,
                    skillLineAbility,
                    latestMajor - 2,
                ),
            );
        }

        const outputDatas = {
            healingPotion: [] as BasicCreateItemData[],
            instantManaPotion: [] as BasicCreateItemData[],
            channelManaPotion: [] as BasicCreateItemData[],
            combatPotion: [] as BasicCreateItemData[],
            flask: [] as BasicCreateItemData[],
            rune: [] as BasicCreateItemData[],
        };
        const outputDataMap: { objectKey: keyof typeof outputDatas, subKey: string }[] = [
            {
                objectKey: 'healingPotion',
                subKey: 'HealingPotions',
            },
            {
                objectKey: 'instantManaPotion',
                subKey: 'InstantManaPotions',
            },
            {
                objectKey: 'channelManaPotion',
                subKey: 'ChannelManaPotions',
            },
            {
                objectKey: 'combatPotion',
                subKey: 'CombatPotions',
            },
            {
                objectKey: 'flask',
                subKey: 'Flasks',
            },
            {
                objectKey: 'rune',
                subKey: 'Runes',
            },
        ];

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

                const itemRow = item.getRowData(itemID);
                assert(itemRow, `No item row found for item ID ${itemID.toString()}`);

                const itemClassID = itemRow.ClassID as number;
                const itemSubClassID = itemRow.SubclassID as number;

                const itemSpellID = getItemSpell(
                    itemID2MapID,
                    itemXItemEffect,
                    itemEffect,
                    itemID,
                );
                if (itemSpellID === undefined) {
                    return;
                }

                if (itemClassID === 0 && itemSubClassID === 3) {
                    // Consumable - Flasks & Phials
                    if (spellID2Labels.get(itemSpellID)?.includes(3104) === true) {
                        // is Vicious Flask
                        return;
                    }

                    const effectIDs = spellID2SpellEffectIDs.get(itemSpellID);
                    const hasProfessionEffect = effectIDs?.some((effectID) => {
                        const row = spellEffect.getRowData(effectID);
                        const effectType = row?.Effect as number;
                        const effectAura = row?.EffectAura as number;

                        return effectType === 6 // APPLY_AURA
                            && effectAura === 511; // APPLY_PROFESSION_EFFECT
                    }) ?? false;
                    if (hasProfessionEffect) {
                        // is Profession Phial
                        return;
                    }

                    outputDatas.flask.push(itemData);
                    return;
                }

                const categoryID = spellID2CategoryID.get(itemSpellID);

                if (categoryID === 30) {
                    outputDatas.healingPotion.push(itemData);
                } else if (categoryID === 4) {
                    const effectIDs = spellID2SpellEffectIDs.get(itemSpellID);
                    const isInstantManaPotion = effectIDs?.every((effectID) => {
                        const row = spellEffect.getRowData(effectID);
                        const effectType = row?.Effect as number;
                        const effectAura = row?.EffectAura as number;

                        return effectType === 30 // ENERGIZE
                            && effectAura === 0; // NONE
                    }) ?? false;
                    if (isInstantManaPotion) {
                        outputDatas.instantManaPotion.push(itemData);
                        return;
                    }

                    const isChannelManaPotion = effectIDs?.every((effectID) => {
                        const row = spellEffect.getRowData(effectID);
                        const effectType = row?.Effect as number;
                        const effectAura = row?.EffectAura as number;

                        return effectType === 6 // APPLY_AURA
                            && effectAura === 24; // PERIODIC_ENERGIZE
                    }) ?? false;
                    if (isChannelManaPotion) {
                        outputDatas.channelManaPotion.push(itemData);
                        return;
                    }

                    outputDatas.combatPotion.push(itemData);
                }
            });
        });

        itemSparse
            .getAllIDs()
            .forEach((itemID) => {
                const row = itemSparse.getRowData(itemID);
                const expansionID = row?.ExpansionID as number;
                const display = row?.Display_lang;
                assert(typeof display === 'string', `Invalid name for item ID ${itemID.toString()}`);

                if (
                    (
                        (expansionID === latestMajor - 1)
                        || (
                            expansionID === latestMajor - 2
                            && (liveMajor < latestMajor || (liveMinor < 1 && livePatch < 1))
                        )
                    )
                    && display.endsWith('Augment Rune')
                ) {
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

                    outputDatas.rune.push({
                        createSpellID: charges === 0 ? 1 : 0, // prefers permanent runes
                        itemID,
                    });
                }
            });

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

        const outputMap = new Map<string, string>();
        outputDataMap.forEach(({ objectKey, subKey }) => {
            const data = outputDatas[objectKey];
            data.sort(compare);

            const content = data.map(({ itemID, qualityID }) => {
                const row = itemSparse.getRowData(itemID);
                if (!row) {
                    return undefined;
                }

                const idText = itemID.toString();
                const display = row.Display_lang as string | undefined;
                const itemName = typeof display === 'string' ? display : idText;

                let text = `${itemID.toString()}, -- ${itemName}`;
                if (qualityID !== undefined) {
                    text += ` (Tier ${(qualityID > 10 ? qualityID - 12 : qualityID).toString()})`;
                }

                return text;
            }).join('\n');

            outputMap.set(subKey, content);
        });

        return outputMap;
    },
};

export default task;
