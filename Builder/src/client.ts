import { CASCClient } from '@rhyster/wow-casc-dbc';

type Version = NonNullable<Awaited<ReturnType<typeof CASCClient['getProductVersion']>>>;
interface Semver {
    major: number,
    minor: number,
    patch: number,
    build: number,
}

const region = 'us';
const products = ['wow', 'wowt', 'wowxptr', 'wow_beta'];

export const versions = await Promise.all(products.map(async (product) => {
    const version = await CASCClient.getProductVersion(region, product);
    if (version) {
        const [major, minor, patch, build] = version.VersionsName
            .split('.')
            .map((v) => parseInt(v, 10));
        const semver: Semver = {
            major,
            minor,
            patch,
            build,
        };
        return {
            product,
            version,
            semver,
        };
    }
    return {
        product,
        version,
    };
}));

export const latestVersion = versions
    .filter((data): data is { product: string, version: Version, semver: Semver } => !!data.version)
    .reduce((prev, data) => {
        const {
            major, minor, patch, build,
        } = data.semver;

        if (major > prev.semver.major) {
            return data;
        }

        if (major === prev.semver.major) {
            if (minor > prev.semver.minor) {
                return data;
            }

            if (minor === prev.semver.minor) {
                if (patch > prev.semver.patch) {
                    return data;
                }

                if (patch === prev.semver.patch) {
                    if (build > prev.semver.build) {
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
