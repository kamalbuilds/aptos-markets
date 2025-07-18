import { MODULE_ADDRESS_FROM_ABI, surfClientMarketplace } from "@/lib/aptos";
import { getLogger } from "./logger";
import { Address, MarketType } from "./types/market";

export interface AvailableMarketplace {
  address: Address;
  typeArgument: string;
}

export const getAvailableMarketplaces = async (): Promise<
  AvailableMarketplace[]
> => {
  console.log("getAvailableMarketplaces called");
  console.log("MODULE_ADDRESS_FROM_ABI:", MODULE_ADDRESS_FROM_ABI);
  
  const logger = getLogger();
  const availableMarketplaces: AvailableMarketplace[] = [];

  const allCoinTypes = ["0x1::aptos_coin::AptosCoin"];
  console.log("Checking coin types:", allCoinTypes);

  for (const coinType of allCoinTypes) {
    console.log(`Fetching marketplace for coin type: ${coinType}`);
    
    try {
      console.log("About to call surfClientMarketplace.view.get_marketplace_address...");
      
      const result = await surfClientMarketplace.view.get_marketplace_address({
        typeArguments: [coinType],
        functionArguments: [],
      });
      
      console.log(`Raw marketplace result for ${coinType}:`, result);
      console.log(`Result type: ${typeof result}`);
      console.log(`Result is array: ${Array.isArray(result)}`);
      
      if (result && typeof result === 'string') {
        const marketplaceAddress = result as Address;
        console.log(`Found marketplace address: ${marketplaceAddress}`);
        
        availableMarketplaces.push({
          address: marketplaceAddress,
          typeArgument: coinType,
        });
      } else if (Array.isArray(result) && result.length > 0) {
        const marketplaceAddress = result[0] as Address;
        console.log(`Found marketplace address (array): ${marketplaceAddress}`);
        
        availableMarketplaces.push({
          address: marketplaceAddress,
          typeArgument: coinType,
        });
      } else {
        console.log(`No marketplace found for ${coinType}. Result was:`, result);
      }
    } catch (error) {
      console.error(`Error fetching marketplace for ${coinType}:`, error);
      console.error("Error details:", {
        message: error instanceof Error ? error.message : 'Unknown error',
        stack: error instanceof Error ? error.stack : 'No stack trace',
        name: error instanceof Error ? error.name : 'Unknown',
      });
      logger.error(error);
    }
  }

  console.log("Final availableMarketplaces:", availableMarketplaces);
  
  // Fallback: Use the known marketplace address from our deployment
  if (availableMarketplaces.length === 0) {
    console.log("No marketplaces found via view function, using known marketplace address as fallback");
    const knownMarketplaceAddress = "0x578b651041ff91b290ff5eb6eddc16ad3b5e886d11c12d753baea1547f59dc58";
    
    availableMarketplaces.push({
      address: knownMarketplaceAddress as Address,
      typeArgument: "0x1::aptos_coin::AptosCoin",
    });
    
    console.log("Added fallback marketplace:", availableMarketplaces);
  }
  
  return availableMarketplaces;
};
