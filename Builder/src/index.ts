import { executeTasks } from './task.ts';

import './modules/QuickMacro/Hearthstone.ts';
import './modules/InfoItemLevel/Enchantments.ts';
import './modules/InfoItemLevel/ItemSets.ts';
import './modules/MythicPlus/Database.ts';
import './modules/Misc/AutoLogging.ts';

executeTasks()
    .catch((err: unknown) => {
        // eslint-disable-next-line no-console
        console.error(err);
        process.exit(1);
    });
