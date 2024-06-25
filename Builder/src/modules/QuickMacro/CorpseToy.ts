import assert from 'node:assert';

import { registerTask } from '../../task.ts';

interface ToyXSpellID {
    itemID: number,
    spellID: number,
}

const corpseVaildTarget = [
    21, // TARGET_UNIT_TARGET_ALLY
    25, // TARGET_UNIT_TARGET_ANY
    35, // TARGET_UNIT_TARGET_PARTY
    57, // TARGET_UNIT_TARGET_RAID
    118, // TARGET_UNIT_TARGET_ALLY_OR_RAID
    119, // TARGET_CORPSE_SRC_AREA_RAID
    121, // TARGET_CORPSE_TARGET_ALLY
];

registerTask({
    key: 'QuickMacroCorpseToy',
    version: 1,
    fileDataIDs: [
        988200, // dbfilesclient/toy.db2
        3177687, // dbfilesclient/itemxitemeffect.db2
        969941, // dbfilesclient/itemeffect.db2
        1003144, // dbfilesclient/spellmisc.db2
        1140088, // dbfilesclient/spelleffect.db2
        1572924, // dbfilesclient/itemsparse.db2
    ],
    handler: ([
        toy,
        itemXItemEffect,
        itemEffect,
        spellMisc,
        spellEffect,
        itemSparse,
    ]) => {
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

        const toyItemIDs = toy
            .getAllIDs()
            .map((id) => {
                const row = toy.getRowData(id);
                return row?.ItemID as number;
            });

        const toyXSpellID = itemXItemEffect
            .getAllIDs()
            .map((id) => {
                const itemID = itemXItemEffect.wdc.getRowRelationship(id);

                if (itemID && toyItemIDs.includes(itemID)) {
                    const row = itemXItemEffect.getRowData(id);
                    const itemEffectID = row?.ItemEffectID as number;

                    const effectRow = itemEffect.getRowData(itemEffectID);
                    assert(effectRow, `No row found for itemEffectID ${itemEffectID.toString()}`);

                    return {
                        itemID,
                        spellID: effectRow.SpellID as number,
                    };
                }
                return undefined;
            })
            .filter((v): v is ToyXSpellID => !!v);

        const spellID2SpellMiscID = new Map<number, number>();
        spellMisc
            .getAllIDs()
            .forEach((id) => {
                const spellID = spellMisc.wdc.getRowRelationship(id);
                if (spellID) {
                    spellID2SpellMiscID.set(spellID, id);
                }
            });

        const corpseToys = toyXSpellID
            .filter(({ spellID }) => {
                const spellMiscID = spellID2SpellMiscID.get(spellID);
                if (!spellMiscID) {
                    return false;
                }

                const spellMiscRow = spellMisc.getRowData(spellMiscID);
                const attributes = spellMiscRow?.Attributes as number[];

                if (
                    // eslint-disable-next-line no-bitwise
                    (attributes[2] & 0x1) === 0 // Allow Dead Target
                    // eslint-disable-next-line no-bitwise
                    || (attributes[3] & 0x100000) === 0 // Allow Aura While Dead
                ) {
                    return false;
                }

                const spellEffectIDs = spellID2SpellEffectIDs.get(spellID);
                if (!spellEffectIDs) {
                    return false;
                }

                const effects = spellEffectIDs.map((effectID) => {
                    const row = spellEffect.getRowData(effectID);
                    const effect = row?.Effect as number;
                    const implicitTarget = row?.ImplicitTarget as number[];

                    return {
                        effect,
                        implicitTarget,
                    };
                });

                const hasCorpseEffect = effects.some((effect) => {
                    if (effect.effect === 3 || effect.effect === 6) {
                        return effect.implicitTarget
                            .some((target) => corpseVaildTarget.includes(target));
                    }
                    return false;
                });

                return hasCorpseEffect;
            });

        const itemIDMaxLength = Math.max(
            ...corpseToys.map(({ itemID }) => itemID.toString().length),
        );

        const lines = corpseToys
            .map(({ itemID }) => {
                const row = itemSparse.getRowData(itemID);
                if (!row) {
                    return undefined;
                }

                const idText = itemID.toString();
                const display = row.Display_lang as string | undefined;
                const name = typeof display === 'string' ? display : idText;

                return `${idText}, ${' '.repeat(itemIDMaxLength - idText.length)}-- ${name}`;
            })
            .filter((v): v is string => !!v);
        const text = lines.join('\n');

        return text;
    },
});
