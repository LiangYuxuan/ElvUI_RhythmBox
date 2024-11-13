/* eslint-disable import-x/no-unused-modules */

import Raids from './modules/EnhancedTooltip/Raids.ts';
import Seasons from './modules/EnhancedTooltip/Seasons.ts';
import Enchantments from './modules/InfoItemLevel/Enchantments.ts';
import ItemSets from './modules/InfoItemLevel/ItemSets.ts';
import AutoLogging from './modules/Misc/AutoLogging.ts';
import Database from './modules/MythicPlus/Database.ts';
import CorpseToy from './modules/QuickMacro/CorpseToy.ts';
import Hearthstone from './modules/QuickMacro/Hearthstone.ts';
import { executeTasks } from './task.ts';

import type { Task } from './task.ts';

const tasks: Task[] = [
    Raids,
    Seasons,
    Enchantments,
    ItemSets,
    AutoLogging,
    Database,
    CorpseToy,
    Hearthstone,
];

executeTasks(tasks)
    .catch((err: unknown) => {
        console.error(err);
        process.exit(1);
    });
