import type { Task } from '../../task.ts';

const task: Task = {
    key: 'QuickMacroHearthstone',
    version: 2,
    fileDataIDs: [
        1139939, // dbfilesclient/spellcategories.db2
        969941, // dbfilesclient/itemeffect.db2
        3177687, // dbfilesclient/itemxitemeffect.db2
        988200, // dbfilesclient/toy.db2
        1572924, // dbfilesclient/itemsparse.db2
    ],
    handler: ([
        spellCategories,
        itemEffect,
        itemXItemEffect,
        toy,
        itemSparse,
    ]) => {
        const toyItemIDs = toy
            .getAllIDs()
            .map((id) => {
                const row = toy.getRowData(id);
                return row?.ItemID as number;
            });

        const spellIDs = spellCategories
            .getAllIDs()
            .map((id) => {
                const row = spellCategories.getRowData(id);
                const category = row?.Category as number;
                const chargeCategory = row?.ChargeCategory as number;
                const spellID = row?.SpellID as number;

                if (category === 1176 || chargeCategory === 2309) {
                    return spellID;
                }

                return undefined;
            })
            .filter((v): v is number => v !== undefined);

        const effects = itemEffect
            .getAllIDs()
            .filter((id) => {
                const row = itemEffect.getRowData(id);

                if (row && spellIDs.includes(row.SpellID as number)) {
                    return true;
                }

                if (row?.SpellCategoryID === 1176) {
                    return true;
                }

                return false;
            });

        const itemIDs = itemXItemEffect
            .getAllIDs()
            .map((id) => {
                const row = itemXItemEffect.getRowData(id);
                const itemEffectID = row?.ItemEffectID as number;
                const itemID = row?.ItemID as number;

                if (effects.includes(itemEffectID) && toyItemIDs.includes(itemID)) {
                    return itemID;
                }
                return undefined;
            })
            .filter((v): v is number => v !== undefined);

        const itemIDMaxLength = Math.max(...itemIDs.map((id) => id.toString().length));

        const lines = itemIDs
            .map((id) => {
                const row = itemSparse.getRowData(id);
                if (!row) {
                    return undefined;
                }

                const idText = id.toString();
                const display = row.Display_lang as string | undefined;
                const name = typeof display === 'string' ? display : idText;

                return `${idText}, ${' '.repeat(itemIDMaxLength - idText.length)}-- ${name}`;
            })
            .filter((v): v is string => v !== undefined);
        const text = lines.join('\n');

        return text;
    },
};

export default task;
