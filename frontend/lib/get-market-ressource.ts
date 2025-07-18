import { MODULE_ADDRESS_FROM_ABI, surfClientMarket } from "./aptos";
import { AvailableMarket } from "./get-available-markets";
import { getLogger } from "./logger";
import { MarketType } from './types/market';

export interface MarketRessource {
  // Basic market info
  title: string;
  description: string;
  category: string;
  creator: string;
  created_at: string;
  start_time: string;
  end_time: string;
  resolution_time: string;
  status: number;
  
  // Resolution details
  resolved: boolean;
  winning_outcome: { vec: string };
  resolution_source: { vec: string[] };
  
  // Betting pools
  total_yes_bets: string;
  total_no_bets: string;
  total_volume: string;
  unique_bettors: string;
  
  // Pricing (basis points: 0-10000)
  current_yes_price: string;
  current_no_price: string;
  price_history: string[];
  last_price_update: string;
  
  // AI Integration
  ai_sentiment_score: string;
  ai_confidence: string;
  ai_recommendation: number;
  ai_last_update: string;
  ai_price_adjustment: boolean;
  
  // Risk management
  max_exposure: string;
  current_exposure: string;
  risk_score: string;
  daily_volume_limit: string;
  daily_volume_used: string;
  last_volume_reset: string;
  
  // Liquidity management
  liquidity_pool: string;
  min_liquidity: string;
  liquidity_providers: string[];
  
  // Fee structure
  market_fee_rate: string;
  creator_fee_rate: string;
  collected_fees: string;
  
  // Object management
  extend_ref: { self: string };
}

export const getMarketRessource = async (
  availableMarket: AvailableMarket<MarketType>
): Promise<MarketRessource> => {
  const logger = getLogger();
  
  // Use the correct coin type based on the market type
  const coinType = availableMarket.type === 'APT' 
    ? '0x1::aptos_coin::AptosCoin' 
    : `${MODULE_ADDRESS_FROM_ABI}::switchboard_asset::${availableMarket.type}`;
  
  console.log(`Fetching market resource for ${availableMarket.address} with type: ${coinType}`);
  
  const market = await surfClientMarket.resource
    .Market({
      account: availableMarket.address,
      typeArguments: [coinType],
    })
    .then((market) => market as unknown as MarketRessource)
    .catch((error) => {
      console.error(`Error fetching market resource for ${availableMarket.address}:`, error);
      logger.error(error);
      throw error;
    });

  return market as unknown as MarketRessource;
};
