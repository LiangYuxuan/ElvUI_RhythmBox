import { DBDParser } from '@rhyster/wow-casc-dbc';

import { registerTask } from '../../task.ts';
import { getItemData } from '../../api.ts';

registerTask({
    key: 'QuickMacroHearthstone',
    version: 1,
    fileDataIDs: [
        1139939,
        969941,
        3177687,
        988200,
    ],
    handler: async (readers) => {
        const [
            spellCategories,
            itemEffect,
            itemXItemEffect,
            toy,
        ] = await Promise.all(readers.map(async (reader) => DBDParser.parse(reader)));
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

        const itemIDs = itemXItemEffect.getAllIDs().reduce<number[]>((acc, id) => {
            const row = itemXItemEffect.getRowData(id);
            if (
                row
                && effects.includes(row.ItemEffectID as number)
                && toyItemIDs.includes(row.ItemID as number)
            ) {
                acc.push(row.ItemID as number);
            }
            return acc;
        }, []);

        const itemIDMaxLength = Math.max(...itemIDs.map((id) => id.toString().length));

        const lines = (
            await Promise.all(itemIDs.map(async (id) => {
                const { name } = await getItemData(id).catch(() => ({ name: undefined }));

                if (!name) {
                    return undefined;
                }

                const idText = id.toString();
                return `${idText}, ${' '.repeat(itemIDMaxLength - idText.length)}-- ${name}`;
            }))
        ).filter((line): line is string => !!line);
        const text = lines.join('\n');

        return text;
    },
});
