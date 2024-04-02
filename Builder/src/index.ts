import { executeTasks } from './task.ts';

import './modules/QuickMacro/Hearthstone.ts';

executeTasks()
    .catch((err: unknown) => {
        // eslint-disable-next-line no-console
        console.error(err);
        process.exit(1);
    });
