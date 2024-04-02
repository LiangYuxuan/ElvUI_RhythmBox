import { CASCClient } from '@rhyster/wow-casc-dbc';

type Version = NonNullable<Awaited<ReturnType<typeof CASCClient['getProductVersion']>>>;

const region = 'us';
const products = ['wow', 'wowt', 'wowxptr', 'wow_beta'];

export const versions = await Promise.all(products.map(async (product) => {
    const version = await CASCClient.getProductVersion(region, product);
    return {
        product,
        version,
    };
}));

export const latestVersion = versions
    .filter((data): data is { product: string, version: Version } => !!data.version)
    .reduce((prev, data) => {
        const version = data.version.VersionsName;
        const [major, minor, patch, build] = version
            .split('.')
            .map((v) => parseInt(v, 10));
        const [
            prevMajor, prevMinor, prevPatch, prevBuild,
        ] = prev.version.VersionsName.split('.').map((v) => parseInt(v, 10));

        if (major > prevMajor) {
            return data;
        }
        if (major === prevMajor) {
            if (minor > prevMinor) {
                return data;
            }
            if (minor === prevMinor) {
                if (patch > prevPatch) {
                    return data;
                }
                if (patch === prevPatch) {
                    if (build > prevBuild) {
                        return data;
                    }
                }
            }
        }

        return prev;
    });

let client = undefined as CASCClient | undefined;

export const getClient = async () => {
    if (!client) {
        client = new CASCClient(region, latestVersion.product, latestVersion.version);
        await client.init();

        // eslint-disable-next-line no-console
        console.log(new Date().toISOString(), '[INFO]: Loading remote TACT keys');
        await client.loadRemoteTACTKeys();
        // eslint-disable-next-line no-console
        console.log(new Date().toISOString(), '[INFO]: Loaded remote TACT keys');
    }

    return client;
};
