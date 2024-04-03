/* eslint-disable no-bitwise */

import { registerTask } from '../../task.ts';

interface Enchantment {
    id: number,
    displayName: string,
    spellId?: number,
    spellIcon: string,
    tokenizedName: string,
    equipRequirements?: {
        itemClass: number,
        itemSubClassMask: number,
        invTypeMask: number,
    },
    categoryId?: number,
    categoryName?: string,
    itemId?: number,
    itemName?: string,
    itemIcon?: string,
    quality?: number,
    expansion?: number,
    slot?: string,
    socketType?: number,
    stats?: {
        type: string
        amount: number
    }[],
    itemLimitCategory?: {
        id: number
        name: string
        quantity: number
        flags: number
    },
    unique?: number,
    craftingQuality?: number,
    baseDisplayName?: string,
}

const armorSlots = [
    { invSlotID: 1, invType: 1, itemEquipLoc: 'Head' },
    { invSlotID: 2, invType: 2, itemEquipLoc: 'Neck' },
    { invSlotID: 3, invType: 3, itemEquipLoc: 'Shoulder' },
    { invSlotID: 5, invType: 5, itemEquipLoc: 'Chest' },
    { invSlotID: 6, invType: 6, itemEquipLoc: 'Waist' },
    { invSlotID: 7, invType: 7, itemEquipLoc: 'Legs' },
    { invSlotID: 8, invType: 8, itemEquipLoc: 'Feet' },
    { invSlotID: 9, invType: 9, itemEquipLoc: 'Wrist' },
    { invSlotID: 10, invType: 10, itemEquipLoc: 'Hands' },
    { invSlotID: 11, invType: 11, itemEquipLoc: 'Finger0' },
    { invSlotID: 12, invType: 11, itemEquipLoc: 'Finger1' },
    { invSlotID: 13, invType: 12, itemEquipLoc: 'Trinket0' },
    { invSlotID: 14, invType: 12, itemEquipLoc: 'Trinket1' },
    { invSlotID: 15, invType: 16, itemEquipLoc: 'Back' },
] as const;

const isBetter = (a: Enchantment, b: Enchantment): boolean => {
    if (a.craftingQuality && b.craftingQuality) {
        if (a.spellId && b.spellId && a.spellId === b.spellId) {
            // created by the same trade skill
            // compare crafting quality
            return a.craftingQuality > b.craftingQuality;
        }

        if (a.itemName && b.itemName && a.itemName === b.itemName) {
            // same item name, maybe same trade skill
            // compare crafting quality
            return a.craftingQuality > b.craftingQuality;
        }
    }

    const aStats = a.stats;
    const bStats = b.stats;

    if (!aStats || !bStats) {
        // not same trade skill
        // and no stats to compare
        return false;
    }

    const aEquip = a.equipRequirements;
    const bEquip = b.equipRequirements;

    if (aEquip?.itemClass !== bEquip?.itemClass) {
        // enchantments for different item classes
        return false;
    }

    if (
        (
            (aEquip?.itemSubClassMask ?? 0) !== 0
            && (bEquip?.itemSubClassMask ?? 0) === 0
        )
        || (
            aEquip?.itemSubClassMask
            && bEquip?.itemSubClassMask
            // eslint-disable-next-line no-bitwise
            && (aEquip.itemSubClassMask | bEquip.itemSubClassMask) !== aEquip.itemSubClassMask
        )
    ) {
        // enchantments for different item sub classes
        return false;
    }

    if (
        (
            (aEquip?.invTypeMask ?? 0) !== 0
            && (bEquip?.invTypeMask ?? 0) === 0
        )
        || (
            aEquip?.invTypeMask
            && bEquip?.invTypeMask
            // eslint-disable-next-line no-bitwise
            && (aEquip.invTypeMask | bEquip.invTypeMask) !== aEquip.invTypeMask
        )
    ) {
        // enchantments for different inventory types
        return false;
    }

    return bStats.every((stat) => {
        const other = aStats.find((oStat) => oStat.type === stat.type);
        return other && stat.amount < other.amount;
    });
};

const extractBits = (input: number): number[] => {
    const bits = [];

    let value = input;
    let index = 0;
    while (value > 0) {
        if (value & 1) {
            bits.push(index);
        }
        index += 1;
        value >>= 1;
    }

    return bits;
};

registerTask({
    key: 'InfoItemLevelEnchantments',
    version: 1,
    fileDataIDs: undefined,
    handler: async () => {
        const data = await (await fetch('https://www.raidbots.com/static/data/live/enchantments.json')).json() as Enchantment[];

        const newEnchantments = data.filter(({ slot, expansion }) => {
            if (slot === 'socket') {
                // not an enchantment
                return false;
            }

            if (expansion && expansion < 9) {
                // old expansion, discard
                return false;
            }

            return true;
        });

        const bestEnchantments = newEnchantments.filter((enc) => {
            const hasBetter = newEnchantments.some((other) => isBetter(other, enc));
            return !hasBetter;
        });

        const armor = armorSlots.map(({ invSlotID, invType, itemEquipLoc }) => {
            const slotEnchantments = bestEnchantments
                .filter(({ equipRequirements }) => equipRequirements?.itemClass === 4
                    && (
                        equipRequirements.invTypeMask === 0
                        || ((equipRequirements.invTypeMask & (1 << invType)) > 0)
                    ))
                .map(({
                    id, itemName, displayName, craftingQuality, equipRequirements,
                }) => ({
                    id,
                    name: `${itemName ?? displayName}${craftingQuality ? ` (Tier ${craftingQuality.toString()})` : ''}`,
                    itemSubClasses: equipRequirements && equipRequirements.itemSubClassMask > 0
                        ? extractBits(equipRequirements.itemSubClassMask)
                        : undefined,
                }));

            return {
                invSlotID,
                itemEquipLoc,
                enchantments: slotEnchantments.length > 0 ? slotEnchantments : undefined,
            };
        });

        let armorEnchantments = 'local armorEnchantments = {\n';
        armorEnchantments += armor
            .map(({ invSlotID, itemEquipLoc, enchantments }) => {
                if (!enchantments) {
                    return `    [${invSlotID.toString()}] = false, -- ${itemEquipLoc}`;
                }
                const content = enchantments
                    .map((enchantment) => {
                        const subClasses = enchantment.itemSubClasses ? `{${enchantment.itemSubClasses.join(', ')}}` : 'true';
                        return `        [${enchantment.id.toString()}] = ${subClasses}, -- ${enchantment.name}`;
                    })
                    .join('\n');
                return `    [${invSlotID.toString()}] = { -- ${itemEquipLoc}\n${content}\n    },`;
            }).join('\n');
        armorEnchantments += '\n}';

        const weapon = bestEnchantments
            .filter(({ equipRequirements }) => equipRequirements?.itemClass === 2)
            .map(({
                id, itemName, displayName, craftingQuality, equipRequirements,
            }) => ({
                id,
                name: `${itemName ?? displayName}${craftingQuality ? ` (Tier ${craftingQuality.toString()})` : ''}`,
                itemSubClasses: equipRequirements && equipRequirements.itemSubClassMask > 0
                    ? extractBits(equipRequirements.itemSubClassMask)
                    : undefined,
            }));

        let weaponEnchantments = 'local weaponEnchantments = {\n';
        weaponEnchantments += weapon
            .map((enchantment) => {
                const subClasses = enchantment.itemSubClasses ? `{${enchantment.itemSubClasses.join(', ')}}` : 'true';
                return `    [${enchantment.id.toString()}] = ${subClasses}, -- ${enchantment.name}`;
            }).join('\n');
        weaponEnchantments += '\n}';

        return `${armorEnchantments}\n\n${weaponEnchantments}`;
    },
});
