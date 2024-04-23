import assert from 'node:assert';

import 'dotenv/config';

const { CLIENT_ID, CLIENT_SECRET } = process.env;
assert(CLIENT_ID, 'CLIENT_ID is required');
assert(CLIENT_SECRET, 'CLIENT_SECRET is required');

interface AccessTokenResponseSuccess {
    access_token: string,
    token_type: string,
    expires_in: number,
    sub: string,
}

interface AccessTokenResponseError {
    error: string,
    error_description: string,
}

type AccessTokenResponse = AccessTokenResponseSuccess | AccessTokenResponseError;

let accessToken: string;
const getAccessToken = async () => {
    if (accessToken) {
        return accessToken;
    }

    const auth = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64');
    const req = await fetch('https://oauth.battle.net/token', {
        method: 'POST',
        body: new URLSearchParams({
            grant_type: 'client_credentials',
        }),
        headers: {
            Authorization: `Basic ${auth}`,
            'Content-Type': 'application/x-www-form-urlencoded',
        },
    });
    const res = await req.json() as AccessTokenResponse;

    if ('error' in res) {
        throw new Error(`Failed to get access token: ${res.error} ${res.error_description}`);
    }

    return res.access_token;
};

interface APIError {
    code: number,
    type: string,
    detail: string,
}

interface ItemData {
    _links: {
        self: {
            href: string,
        },
    },
    id: number,
    name: string,
    quality: {
        type: string,
        name: string,
    },
    level: number,
    required_level: number,
    media: {
        key: {
            href: string,
        },
        id: number,
    },
    item_class: {
        key: {
            href: string,
        },
        name: string,
        id: number,
    },
    item_subclass: {
        key: {
            href: string,
        },
        name: string,
        id: number,
    },
    inventory_type: {
        type: string,
        name: string,
    },
    purchase_price: number,
    sell_price: number,
    max_count: number,
    is_equippable: boolean,
    is_stackable: boolean,
    description: string,
    preview_item: {
        item: {
            key: {
                href: string,
            },
            id: number,
        },
        quality: {
            type: string,
            name: string,
        },
        name: string,
        media: {
            key: {
                href: string,
            },
            id: number,
        },
        item_class: {
            key: {
                href: string,
            },
            name: string,
            id: number,
        },
        item_subclass: {
            key: {
                href: string,
            },
            name: string,
            id: number,
        },
        inventory_type: {
            type: string,
            name: string,
        },
        binding: {
            type: string,
            name: string,
        },
        spells: {
            spell: {
                key: {
                    href: string,
                },
                name: string,
                id: number,
            },
            description: string,
        }[],
        description: string,
        is_subclass_hidden: boolean,
        toy: string,
    },
    purchase_quantity: number,
}

// eslint-disable-next-line import/prefer-default-export
export const getItemData = async (itemID: number, region = 'us', locale = 'en_US') => {
    const token = await getAccessToken();

    const req = await fetch(`https://${region}.api.blizzard.com/data/wow/item/${itemID.toString()}?namespace=static-${region}&locale=${locale}`, {
        headers: {
            Authorization: `Bearer ${token}`,
        },
    });
    const res = await req.json() as ItemData | APIError;

    if ('code' in res) {
        if (res.code === 404) {
            return undefined;
        }
        throw new Error(`Failed to get item data: ${res.code.toString()} ${res.type} ${res.detail}`);
    }

    return res;
};
