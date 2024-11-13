/* eslint-disable @typescript-eslint/naming-convention */

interface Dungeon {
    id: number,
    challenge_mode_id: number,
    slug: string,
    name: string,
    short_name: string,
}

interface RealmTime {
    us?: string,
    eu?: string,
    tw?: string,
    kr?: string,
    cn?: string,
}

interface SeasonalAffix {
    id: number,
    name: string,
    icon: string,
}

interface VaildMythicPlusExpansionData {
    seasons: {
        slug: string,
        name: string,
        short_name: string,
        seasonal_affix?: SeasonalAffix,
        starts: RealmTime,
        ends: RealmTime,
        dungeons: Dungeon[],
    }[],
    dungeons: Dungeon[],
}

type MythicPlusExpansionData = VaildMythicPlusExpansionData | Record<string, never>;

// eslint-disable-next-line import-x/prefer-default-export
export const getMythicPlusStaticData = async (expansionIndex: number) => {
    const res = await fetch(`https://raider.io/api/v1/mythic-plus/static-data?expansion_id=${expansionIndex.toString()}`);
    const data = await res.json() as MythicPlusExpansionData;

    return data;
};
