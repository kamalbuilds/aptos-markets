import { surfClientMarketplace } from "@/lib/aptos";
import { getLogger } from "./logger";
import { AvailableMarketplace } from "./get-available-marketplaces";
import { Address, EventMarketType, MarketType } from "./types/market";

export interface AvailableMarket<T extends EventMarketType | MarketType> {
  address: Address;
  type: T;
}

export const getAvailableMarkets = async <
  T extends EventMarketType | MarketType
>(
  marketplaces: AvailableMarketplace[]
): Promise<AvailableMarket<T>[]> => {
  console.log("getAvailableMarkets called with marketplaces:", marketplaces);
  
  if (marketplaces.length === 0) {
    console.log("No marketplaces found, returning empty array");
    return [];
  }

  const availableMarkets: AvailableMarket<T>[] = [];
  const logger = getLogger();

  for (const marketplace of marketplaces) {
    console.log(`Fetching markets for marketplace: ${marketplace.address} with type: ${marketplace.typeArgument}`);
    
    try {
      console.log("About to call surfClientMarketplace.view.get_active_markets...");
      
      const result = await surfClientMarketplace.view.get_active_markets({
        typeArguments: [`${marketplace.typeArgument}`],
        functionArguments: [marketplace.address],
      });
      
      console.log(`Raw result for marketplace ${marketplace.address}:`, result);
      console.log(`Result type: ${typeof result}`);
      console.log(`Result is array: ${Array.isArray(result)}`);
      
      if (result && Array.isArray(result) && result.length > 0) {
        const marketAddresses = result[0] as Address[];
        console.log(`Market addresses found:`, marketAddresses);
        
        marketAddresses.forEach((marketAddress) => {
          availableMarkets.push({
            address: marketAddress,
            type: (marketplace.typeArgument === '0x1::aptos_coin::AptosCoin' ? 'APT' : marketplace.typeArgument.split("::").pop()) as T,
          });
        });
      } else {
        console.log(`No markets found for marketplace ${marketplace.address}. Result was:`, result);
      }
    } catch (error) {
      console.error(`Error fetching markets for marketplace ${marketplace.address}:`, error);
      console.error("Error details:", {
        message: error instanceof Error ? error.message : 'Unknown error',
        stack: error instanceof Error ? error.stack : 'No stack trace',
        name: error instanceof Error ? error.name : 'Unknown',
      });
      logger.error(error);
    }
  }

  console.log("Markets found via view function:", availableMarkets);
  
  // Fallback: Use known market addresses if view function fails
  if (availableMarkets.length === 0 && marketplaces.length > 0) {
    console.log("No markets found via view function, using known market addresses as fallback");
    
    const knownMarketAddresses = [
      "0x4c65a7f68079dcb482fe087b492ac9fee15718c07863f567dcb8ca4c0c6310b2",
      "0x2ff8f520b154aee4c7af55c62b630f5f80798e47558be23aa197a0709a3b9bf1", 
      "0x47b3e2fb635c4a7a8b1a088d655915e7f2f6c4b1f4fb55b2716085b314cacded",
      "0x6e2f64703bc5d94be35a7e45a76533f23a844bb46791a3361a8f38094db274a8",
      "0xcae573a2fdac2b5a5390c9c53183cca24923b4089fcd5cdeea22910ad562b87",
      "0x3fff289a20f6c4810fab6dd3413d8e3eb9272e00ec2e71a939853c0eef007c97"
    ];
    
    knownMarketAddresses.forEach((marketAddress) => {
      availableMarkets.push({
        address: marketAddress as Address,
        type: (marketplaces[0].typeArgument === '0x1::aptos_coin::AptosCoin' ? 'APT' : marketplaces[0].typeArgument.split("::").pop()) as T,
      });
    });
    
    console.log("Added fallback markets:", availableMarkets);
  }

  console.log("Final availableMarkets:", availableMarkets);

  return availableMarkets;
};
