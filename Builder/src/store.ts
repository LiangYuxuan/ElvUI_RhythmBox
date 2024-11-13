import fs from 'node:fs/promises';

const replacer = (key: string, value: unknown) => {
    if (value instanceof Map) {
        return {
            dataType: 'Map',
            value: [...value],
        };
    }
    return value;
};

const reviver = (key: string, value: unknown) => {
    if (typeof value === 'object' && value !== null) {
        const mapObject = value as { dataType: string, value: [unknown, unknown][] };
        if (mapObject.dataType === 'Map') {
            return new Map(mapObject.value);
        }
    }
    return value;
};

export default class Store<T> {
    private data: T | undefined;

    private dataFile: string;

    private promise: Promise<void>;

    constructor(dataFile: string) {
        this.dataFile = dataFile;

        this.promise = new Promise((resolve) => {
            fs
                .readFile(dataFile, 'utf-8')
                .then((file) => {
                    this.data = JSON.parse(file, reviver) as T;
                    resolve();
                })
                .catch(() => {
                    resolve();
                });
        });
    }

    public async get(): Promise<T | undefined> {
        await this.promise;
        return this.data;
    }

    public async set(data?: T): Promise<void> {
        await this.promise;

        if (data !== undefined) {
            this.data = data;
        }

        await fs.writeFile(
            this.dataFile,
            this.data !== undefined
                ? JSON.stringify(this.data, replacer, 4)
                : '',
            'utf-8',
        );
    }
}
