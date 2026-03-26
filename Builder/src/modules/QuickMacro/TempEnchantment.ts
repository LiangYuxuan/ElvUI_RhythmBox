import assert from 'node:assert';

import { versions, latestVersion } from '../../client.ts';

import type { Task } from '../../task.ts';
import type { DBDParser } from '@rhyster/wow-casc-dbc';

interface BasicCreateItemData {
    createSpellID: number,
    itemID: number,
    qualityID?: number,
}

interface TempEnchantmentData extends BasicCreateItemData {
    equippedItemSubclass: number,
    equippedItemInvTypes: number,
}

const itemEquipLocMap = new Map<number, string>([
    [0, 'INVTYPE_NON_EQUIP_IGNORE'],
    [1, 'INVTYPE_HEAD'],
    [2, 'INVTYPE_NECK'],
    [3, 'INVTYPE_SHOULDER'],
    [4, 'INVTYPE_BODY'],
    [5, 'INVTYPE_CHEST'],
    [6, 'INVTYPE_WAIST'],
    [7, 'INVTYPE_LEGS'],
    [8, 'INVTYPE_FEET'],
    [9, 'INVTYPE_WRIST'],
    [10, 'INVTYPE_HAND'],
    [11, 'INVTYPE_FINGER'],
    [12, 'INVTYPE_TRINKET'],
    [13, 'INVTYPE_WEAPON'],
    [14, 'INVTYPE_SHIELD'],
    [15, 'INVTYPE_RANGED'],
    [16, 'INVTYPE_CLOAK'],
    [17, 'INVTYPE_2HWEAPON'],
    [18, 'INVTYPE_BAG'],
    [19, 'INVTYPE_TABARD'],
    [20, 'INVTYPE_ROBE'],
    [21, 'INVTYPE_WEAPONMAINHAND'],
    [22, 'INVTYPE_WEAPONOFFHAND'],
    [23, 'INVTYPE_HOLDABLE'],
    [24, 'INVTYPE_AMMO'],
    [25, 'INVTYPE_THROWN'],
    [26, 'INVTYPE_RANGEDRIGHT'],
    [27, 'INVTYPE_QUIVER'],
    [28, 'INVTYPE_RELIC'],
    [29, 'INVTYPE_PROFESSION_TOOL'],
    [30, 'INVTYPE_PROFESSION_GEAR'],
    [31, 'INVTYPE_EQUIPABLESPELL_OFFENSIVE'],
    [32, 'INVTYPE_EQUIPABLESPELL_UTILITY'],
    [33, 'INVTYPE_EQUIPABLESPELL_DEFENSIVE'],
    [34, 'INVTYPE_EQUIPABLESPELL_WEAPON'],
]);

const extractBits = (input: number): number[] => {
    const bits = [];

    let value = input;
    let index = 0;
    while (value > 0) {
        // eslint-disable-next-line no-bitwise
        if (value & 1) {
            bits.push(index);
        }
        index += 1;
        // eslint-disable-next-line no-bitwise
        value >>= 1;
    }

    return bits;
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
    key: 'QuickMacroTempEnchantment',
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
        1140011, // dbfilesclient/spellequippeditems.db2
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
        spellEquippedItems,
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

        const tempEnchantment: TempEnchantmentData[] = [];
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

                if (itemClassID === 0 && itemSubClassID === 8) {
                    const spellEquippedItemsIndex = spellEquippedItems
                        .getAllIDs()
                        .find((id) => {
                            const req = spellEquippedItems.getRowData(id);
                            const spell = req?.SpellID as number;
                            return spell === itemSpellID;
                        });

                    if (spellEquippedItemsIndex !== undefined) {
                        const equipRequirement = spellEquippedItems
                            .getRowData(spellEquippedItemsIndex);
                        assert(equipRequirement, `No equipRequirement found for spellID ${itemSpellID.toString()}`);

                        const equippedItemClass = equipRequirement
                            .EquippedItemClass as number;
                        const equippedItemSubclass = equipRequirement
                            .EquippedItemSubclass as number;
                        const equippedItemInvTypes = equipRequirement
                            .EquippedItemInvTypes as number;

                        if (equippedItemClass === 2) {
                            tempEnchantment.push({
                                ...itemData,
                                equippedItemSubclass,
                                equippedItemInvTypes,
                            });
                        }
                    }
                }
            });
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

        const content = tempEnchantment
            .sort(compare)
            .map(({
                itemID,
                qualityID,
                equippedItemInvTypes,
                equippedItemSubclass,
            }) => {
                const row = itemSparse.getRowData(itemID);
                if (!row) {
                    return undefined;
                }

                const idText = itemID.toString();
                const display = row.Display_lang as string | undefined;
                const itemName = typeof display === 'string' ? display : idText;

                let text = `{\n    itemID = ${itemID.toString()}, -- ${itemName}`;
                if (qualityID !== undefined) {
                    text += ` (Tier ${(qualityID > 10 ? qualityID - 12 : qualityID).toString()})`;
                }
                if (equippedItemInvTypes > 0) {
                    const itemEquipLocBits = extractBits(equippedItemInvTypes);
                    const itemEquipLocValues = itemEquipLocBits
                        .map((bit) => {
                            const itemEquipLocValue = itemEquipLocMap.get(bit);
                            assert(itemEquipLocValue !== undefined, `No item equip loc value found for bit ${bit.toString()}`);

                            return `'${itemEquipLocValue}'`;
                        });
                    text += `\n    equippedItemInvTypes = {\n        ${itemEquipLocValues.join(',\n        ')},\n    },`;
                }
                if (equippedItemSubclass > 0) {
                    text += `\n    equippedItemSubclass = {${extractBits(equippedItemSubclass).join(', ')}},`;
                }
                text += '\n},';

                return text;
            })
            .join('\n');

        return content;
    },
};

export default task;
