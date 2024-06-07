import assert from 'node:assert';

import type { DBDParser } from '@rhyster/wow-casc-dbc';

import { registerTask } from '../../task.ts';
import { versions, latestVersion } from '../../client.ts';

interface BasicEnchantmentData {
    applySpellID: number,
    enchantID: number,
    qualityID?: number,
}

interface EnchantmentEffect {
    type: number,
    arg: number,
    value: number,
}

interface EnchantmentData {
    skillLineSpellID: number,
    applySpellID: number,
    enchantID: number,
    qualityID?: number,
    effectComparable: boolean,
    enchantEffect: EnchantmentEffect[],
    equipRequirement: {
        itemClass: number,
        itemSubClassMask: number,
        inventoryTypeMask: number,
        slotIDs: number[],
        itemSubClassIDs: number[],
    },
    hasOldDuplicate?: boolean,
}

const slotID2Name = new Map<number, string>([
    [1, 'Head'],
    [2, 'Neck'],
    [3, 'Shoulder'],
    [5, 'Chest'],
    [6, 'Waist'],
    [7, 'Legs'],
    [8, 'Feet'],
    [9, 'Wrist'],
    [10, 'Hands'],
    [11, 'Finger 1'],
    [12, 'Finger 2'],
    [13, 'Trinket 1'],
    [14, 'Trinket 2'],
    [15, 'Back'],
    [16, 'Main Hand'],
    [17, 'Off Hand'],
]);

const inventoryType2SlotIDs = new Map<number, number[]>([
    [1, [1]], // Head
    [2, [2]], // Neck
    [3, [3]], // Shoulder
    [5, [5]], // Chest
    [6, [6]], // Waist
    [7, [7]], // Legs
    [8, [8]], // Feet
    [9, [9]], // Wrist
    [10, [10]], // Hands
    [11, [11, 12]], // Finger
    [12, [13, 14]], // Trinket
    [13, [16, 17]], // One-Hand
    [14, [17]], // Off Hand
    [15, [16]], // Ranged
    [16, [15]], // Back
    [17, [16]], // Two-Hand
    [21, [16]], // Main Hand
    [22, [16]], // Off Hand
    [23, [17]], // Held In Off-hand
    [25, [16]], // Thrown
    [26, [16]], // Ranged
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

const isMaskIncluded = (base: number, challenger: number): boolean => {
    if (base !== 0 && challenger === 0) {
        return true;
    }

    if (base === 0 && challenger !== 0) {
        return false;
    }

    // eslint-disable-next-line no-bitwise
    return (base | challenger) === challenger;
};

const isEnchantmentBetter = (base: EnchantmentData, challenger: EnchantmentData): boolean => {
    if (
        base.equipRequirement.itemClass === challenger.equipRequirement.itemClass
        && isMaskIncluded(
            base.equipRequirement.itemSubClassMask,
            challenger.equipRequirement.itemSubClassMask,
        )
        && isMaskIncluded(
            base.equipRequirement.inventoryTypeMask,
            challenger.equipRequirement.inventoryTypeMask,
        )
        && base.effectComparable
    ) {
        const atLeastEven = base.enchantEffect.every((baseEffect) => {
            const challengerEffect = challenger.enchantEffect
                .find((effect) => effect.type === baseEffect.type && effect.arg === baseEffect.arg);
            return challengerEffect && baseEffect.value <= challengerEffect.value;
        });
        if (atLeastEven) {
            if (!challenger.effectComparable) {
                return true;
            }

            return challenger.enchantEffect.some((challengerEffect) => {
                const baseEffect = base.enchantEffect
                    .find((effect) => effect.type === challengerEffect.type
                        && effect.arg === challengerEffect.arg);
                return !baseEffect || baseEffect.value < challengerEffect.value;
            });
        }
    }

    return false;
};

const buildEnchantments = (
    spellItemEnchantment: DBDParser,
    spellEquippedItems: DBDParser,
    skillLineSpellID: number,
    { applySpellID, enchantID, qualityID }: BasicEnchantmentData,
): EnchantmentData | undefined => {
    const row = spellItemEnchantment.getRowData(enchantID);
    assert(row, `No row found for enchantID ${enchantID.toString()}`);

    const duration = row.Duration as number;

    if (duration > 0) {
        return undefined;
    }

    const effect = row.Effect as number[];
    const effectArg = row.EffectArg as number[];
    const effectScalingPoints = row.EffectScalingPoints as number[];

    const enchantEffect = effect
        .filter((v) => v > 0)
        .map((v, index) => ({
            type: v,
            arg: effectArg[index],
            value: effectScalingPoints[index],
        }));
    const effectComparable = enchantEffect
        .every((e) => e.type === 2 || e.type === 4 || e.type === 5);

    const spellEquippedItemsIndex = spellEquippedItems
        .getAllIDs()
        .find((id) => {
            const req = spellEquippedItems.getRowData(id);
            const spell = req?.SpellID as number;
            return spell === applySpellID;
        });
    assert(spellEquippedItemsIndex, `No SpellEquippedItems found for spellID ${applySpellID.toString()}`);

    const equipRequirement = spellEquippedItems.getRowData(spellEquippedItemsIndex);
    assert(equipRequirement, `No equipRequirement found for spellID ${applySpellID.toString()}`);

    const equippedItemClass = equipRequirement.EquippedItemClass as number;
    const equippedItemSubclass = equipRequirement.EquippedItemSubclass as number;
    const equippedItemInvTypes = equipRequirement.EquippedItemInvTypes as number;

    if (equippedItemClass !== 2 && equippedItemClass !== 4) {
        return undefined;
    }

    const classIDSlotIDs = equippedItemClass === 2
        ? [16, 17]
        : [1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

    const invTypeSlotIDs = equippedItemInvTypes === 0
        ? classIDSlotIDs
        : extractBits(equippedItemInvTypes)
            .flatMap((invType) => inventoryType2SlotIDs.get(invType) ?? []);

    const slotIDs = classIDSlotIDs.filter((slotID) => invTypeSlotIDs.includes(slotID));

    return {
        skillLineSpellID,
        applySpellID,
        enchantID,
        qualityID,
        effectComparable,
        enchantEffect,
        equipRequirement: {
            itemClass: equippedItemClass,
            itemSubClassMask: equippedItemSubclass,
            inventoryTypeMask: equippedItemInvTypes,
            slotIDs,
            itemSubClassIDs: extractBits(equippedItemSubclass),
        },
    };
};

const getItemSpell = (
    itemID2MapID: Map<number, number>,
    itemXItemEffect: DBDParser,
    itemEffect: DBDParser,
    itemID: number,
): number | undefined => {
    const itemXItemEffectIDs = itemID2MapID.get(itemID);
    if (!itemXItemEffectIDs) {
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

const getSpellApplyEnchantData = (
    spellID2SpellEffectIDs: Map<number, number[]>,
    itemID2MapID: Map<number, number>,
    spellEffect: DBDParser,
    craftingDataEnchantQuality: DBDParser,
    craftingDataItemQuality: DBDParser,
    item: DBDParser,
    itemXItemEffect: DBDParser,
    itemEffect: DBDParser,
    applySpellID: number,
    itemSearchingStack = 0,
    qualityID?: number,
): BasicEnchantmentData | undefined => {
    const reachedStackLimit = itemSearchingStack > 1;

    const effectIDs = spellID2SpellEffectIDs.get(applySpellID);
    if (!effectIDs) {
        return undefined;
    }

    const enchantIDs = effectIDs
        .map((effectID): BasicEnchantmentData | undefined => {
            const row = spellEffect.getRowData(effectID);
            const effectType = row?.Effect as number;
            const effectItemType = row?.EffectItemType as number;
            const effectMiscValue = row?.EffectMiscValue as number[];

            if (effectType === 53) { // Enchant Item
                return {
                    applySpellID,
                    enchantID: effectMiscValue[0],
                    qualityID,
                };
            }

            if (effectType === 24 && !reachedStackLimit) { // Create Item
                const itemSpellID = getItemSpell(
                    itemID2MapID,
                    itemXItemEffect,
                    itemEffect,
                    effectItemType,
                );

                if (itemSpellID) {
                    return getSpellApplyEnchantData(
                        spellID2SpellEffectIDs,
                        itemID2MapID,
                        spellEffect,
                        craftingDataEnchantQuality,
                        craftingDataItemQuality,
                        item,
                        itemXItemEffect,
                        itemEffect,
                        itemSpellID,
                        itemSearchingStack + 1,
                        qualityID,
                    );
                }
                return undefined;
            }

            if (effectType === 301) { // Crafting Enchant
                const craftingID = effectMiscValue[0];
                const craftingEnchant = craftingDataEnchantQuality
                    .getAllIDs()
                    .reduce((previous, id) => {
                        const data = craftingDataEnchantQuality.getRowData(id);
                        const rank = data?.Rank as number;
                        const spellItemEnchantmentID = data?.SpellItemEnchantmentID as number;
                        const craftingDataID = data?.CraftingDataID as number;

                        if (craftingDataID === craftingID && rank > previous.rank) {
                            return {
                                rank,
                                enchantID: spellItemEnchantmentID,
                            };
                        }

                        return previous;
                    }, { rank: 0, enchantID: 0 });

                if (craftingEnchant.enchantID > 0) {
                    return {
                        applySpellID,
                        enchantID: craftingEnchant.enchantID,
                        qualityID: craftingEnchant.rank,
                    };
                }
            }

            if (effectType === 288 && !reachedStackLimit) { // Crafting Item
                const craftingID = effectMiscValue[0];
                const craftingItem = craftingDataItemQuality
                    .getAllIDs()
                    .reduce((previous, id) => {
                        const data = craftingDataItemQuality.getRowData(id);
                        const itemID = data?.ItemID as number;
                        const craftingDataID = data?.CraftingDataID as number;

                        if (craftingDataID === craftingID) {
                            const itemRow = item.getRowData(itemID);
                            if (itemRow) {
                                const craftingQualityID = itemRow.CraftingQualityID as number;
                                if (craftingQualityID > previous.rank) {
                                    return {
                                        rank: craftingQualityID,
                                        itemID,
                                    };
                                }
                            }
                        }

                        return previous;
                    }, { rank: 0, itemID: 0 });

                if (craftingItem.itemID > 0) {
                    const itemSpellID = getItemSpell(
                        itemID2MapID,
                        itemXItemEffect,
                        itemEffect,
                        craftingItem.itemID,
                    );

                    if (itemSpellID) {
                        return getSpellApplyEnchantData(
                            spellID2SpellEffectIDs,
                            itemID2MapID,
                            spellEffect,
                            craftingDataEnchantQuality,
                            craftingDataItemQuality,
                            item,
                            itemXItemEffect,
                            itemEffect,
                            itemSpellID,
                            itemSearchingStack + 1,
                            craftingItem.rank,
                        );
                    }
                }
            }

            return undefined;
        })
        .filter((data): data is BasicEnchantmentData => data !== undefined);

    if (enchantIDs.length > 0) {
        return enchantIDs[0];
    }

    return undefined;
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

            if (categoryID === 11 && parentTierIndex === (expansion + 4)) {
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

const getSkillLineSpellIDsForDK = (
    skillLineAbility: DBDParser,
): number[] => {
    const skillLineSpellIDs = skillLineAbility
        .getAllIDs()
        .map((id) => {
            const row = skillLineAbility.getRowData(id);
            const spellID = row?.Spell as number;
            const skillLine = row?.SkillLine as number;

            if (skillLine === 960) {
                return spellID;
            }

            return undefined;
        })
        .filter((id): id is number => id !== undefined);

    return skillLineSpellIDs;
};

registerTask({
    key: 'InfoItemLevelEnchantments',
    version: 3,
    fileDataIDs: [
        1240935, // dbfilesclient/skillline.db2
        1266278, // dbfilesclient/skilllineability.db2
        1140088, // dbfilesclient/spelleffect.db2
        4659601, // dbfilesclient/craftingdataenchantquality.db2
        4545612, // dbfilesclient/craftingdataitemquality.db2
        841626, // dbfilesclient/item.db2
        3177687, // dbfilesclient/itemxitemeffect.db2
        969941, // dbfilesclient/itemeffect.db2
        1362771, // dbfilesclient/spellitemenchantment.db2
        1140011, // dbfilesclient/spellequippeditems.db2
        1990283, // dbfilesclient/spellname.db2
    ],
    handler: async ([
        skillLine,
        skillLineAbility,
        spellEffect,
        craftingDataEnchantQuality,
        craftingDataItemQuality,
        item,
        itemXItemEffect,
        itemEffect,
        spellItemEnchantment,
        spellEquippedItems,
        spellName,
    ]) => {
        const liveMajor = versions[0].semver?.major;
        const latestMajor = latestVersion.semver.major;
        assert(liveMajor, 'Missing major version for live');

        const spellID2SpellEffectIDs = new Map<number, number[]>();
        spellEffect.getAllIDs().forEach((id) => {
            const spellID = spellEffect.wdc.getRowRelationship(id);
            if (spellID) {
                if (!spellID2SpellEffectIDs.has(spellID)) {
                    spellID2SpellEffectIDs.set(spellID, []);
                }

                spellID2SpellEffectIDs.get(spellID)?.push(id);
            }
        });

        const itemID2MapID = new Map<number, number>();
        itemXItemEffect.getAllIDs().forEach((id) => {
            const itemID = itemXItemEffect.wdc.getRowRelationship(id);
            if (itemID) {
                itemID2MapID.set(itemID, id);
            }
        });

        const skillLineSpellIDs = [
            ...getSkillLineSpellIDsForDK(skillLineAbility),
            ...getSkillLineSpellIDsForExpansion(skillLine, skillLineAbility, latestMajor - 1),
        ];

        if (liveMajor < latestMajor) {
            skillLineSpellIDs.push(
                ...getSkillLineSpellIDsForExpansion(skillLine, skillLineAbility, liveMajor - 1),
            );
        }

        const enchantments: EnchantmentData[] = [];
        skillLineSpellIDs.forEach((skillLineSpellID) => {
            const enchantBasicData = getSpellApplyEnchantData(
                spellID2SpellEffectIDs,
                itemID2MapID,
                spellEffect,
                craftingDataEnchantQuality,
                craftingDataItemQuality,
                item,
                itemXItemEffect,
                itemEffect,
                skillLineSpellID,
            );

            if (enchantBasicData) {
                const enchantment = buildEnchantments(
                    spellItemEnchantment,
                    spellEquippedItems,
                    skillLineSpellID,
                    enchantBasicData,
                );
                if (enchantment) {
                    enchantments.push(enchantment);
                }
            }
        });

        const bestEnchantments = enchantments.filter((enchantment) => {
            const hasBetter = enchantments
                .some((challenger) => isEnchantmentBetter(enchantment, challenger));
            return !hasBetter;
        });

        const slotID2Enchantments = new Map<number, EnchantmentData[]>();
        bestEnchantments.forEach((enchantment) => {
            const { slotIDs } = enchantment.equipRequirement;
            slotIDs.forEach((slotID) => {
                if (!slotID2Enchantments.has(slotID)) {
                    slotID2Enchantments.set(slotID, []);
                }

                slotID2Enchantments.get(slotID)?.push(enchantment);
            });
        });

        const slotEnchantmentsText: string[] = [];
        for (let slotID = 1; slotID <= 17; slotID += 1) {
            const slotEnchantments = slotID2Enchantments.get(slotID);
            if (slotEnchantments) {
                // marks duplicated enchantID
                // likely on new enchants that reuses old enchantID
                // so prefer the old one and also the later in array
                const sorted = slotEnchantments
                    .map((enchantment, index) => {
                        const result = structuredClone(enchantment);

                        result.hasOldDuplicate = !!slotEnchantments
                            .find((other, otherIndex) => other.enchantID === enchantment.enchantID
                                && otherIndex > index);

                        return result;
                    })
                    .sort((a, b) => {
                        if (a.enchantID !== b.enchantID) {
                            return a.enchantID - b.enchantID;
                        }

                        return a.skillLineSpellID - b.skillLineSpellID;
                    });

                const enchantmentsTexts = sorted
                    .map(({
                        enchantID,
                        qualityID,
                        skillLineSpellID,
                        equipRequirement: { itemClass, itemSubClassIDs },
                        hasOldDuplicate,
                    }) => {
                        const name = spellName.getRowData(skillLineSpellID)?.Name_lang;
                        assert(typeof name === 'string', `No name found for spellID ${skillLineSpellID.toString()}`);

                        return `    ${hasOldDuplicate ? '-- ' : ''}[${enchantID.toString()}] = {classID = ${itemClass.toString()}, subClassIDs = {${itemSubClassIDs.join(', ')}}}, -- ${name}${qualityID ? ` (Tier ${qualityID.toString()})` : ''}`;
                    })
                    .join('\n');

                slotEnchantmentsText.push(`[${slotID.toString()}] = { -- ${slotID2Name.get(slotID) ?? slotID.toString()}\n${enchantmentsTexts}\n},`);
            } else if (slotID !== 4) {
                slotEnchantmentsText.push(`[${slotID.toString()}] = false, -- ${slotID2Name.get(slotID) ?? slotID.toString()}`);
            }
        }

        return slotEnchantmentsText.join('\n');
    },
});
