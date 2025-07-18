import { MODULE_ADDRESS_FROM_ABI, surfClientMarketplace } from "@/lib/aptos";
import { getLogger } from "./logger";
import { Address } from "./types/market";
import { MarketType } from "./types/market";

export interface AvailableMarketplacesResponse {
  data: { key: Address; value: Address }[];
}

export interface AvailableMarketplace {
  address: Address;
  typeArgument: `${string}::${string}::${MarketType}`;
}

export const getAvailableMarketplaces = async (marketplaceType: 'switchboard_asset' | 'event_category' = 'switchboard_asset'): Promise<
  AvailableMarketplace[]
> => {
  const logger = getLogger();

  try {
    // Get the marketplace address for AptosCoin
    const marketplaceAddress = await surfClientMarketplace.view
      .get_marketplace_address({
        typeArguments: ["0x1::aptos_coin::AptosCoin"],
        functionArguments: [],
      })
      .catch((error) => {
        logger.error("Error getting marketplace address:", error);
        return null;
      });

    if (marketplaceAddress && marketplaceAddress[0]) {
      // Return our known marketplace
      return [{
        address: marketplaceAddress[0] as Address,
        typeArgument: "0x1::aptos_coin::AptosCoin" as `${string}::${string}::${MarketType}`,
      }];
    }
  } catch (error) {
    logger.error("Error in getAvailableMarketplaces:", error);
  }

  // Fallback: return empty array if marketplace not found
  return [];
};
