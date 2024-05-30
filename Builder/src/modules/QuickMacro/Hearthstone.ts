import { mapSeries } from 'async';

import { registerTask } from '../../task.ts';
import { getItemData } from '../../api.ts';

registerTask({
    key: 'QuickMacroHearthstone',
    version: 1,
    fileDataIDs: [
        1139939, // dbfilesclient/spellcategories.db2
        969941, // dbfilesclient/itemeffect.db2
        3177687, // dbfilesclient/itemxitemeffect.db2
        988200, // dbfilesclient/toy.db2
    ],
    handler: async ([
        spellCategories,
        itemEffect,
        itemXItemEffect,
        toy,
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
                return row?.Category === 1176 ? (row.SpellID as number) : undefined;
            })
            .filter((v): v is number => !!v);

        const effects = itemEffect
            .getAllIDs()
            .map((id) => {
                const row = itemEffect.getRowData(id);

                if (row && spellIDs.includes(row.SpellID as number)) {
                    return row.ID as number;
                }

                if (row?.SpellCategoryID === 1176) {
                    return row.ID as number;
                }

                return undefined;
            })
            .filter((v): v is number => !!v);

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
            .filter((v): v is number => !!v);

        const itemIDMaxLength = Math.max(...itemIDs.map((id) => id.toString().length));

        const lines = (
            await mapSeries(itemIDs, async (id: number) => {
                const res = await getItemData(id);

                if (!res) {
                    return undefined;
                }

                const idText = id.toString();
                return `${idText}, ${' '.repeat(itemIDMaxLength - idText.length)}-- ${res.name}`;
            })
        ).filter((line): line is string => !!line);
        const text = lines.join('\n');

        return text;
    },
});
