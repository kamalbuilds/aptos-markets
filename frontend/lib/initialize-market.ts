import { DateTime } from "luxon";
import { getMarketRessource } from "./get-market-ressource";
import { AvailableMarket } from "./get-available-markets";
import { calculateWinFactors } from "./utils";
import { Address, MarketData, MarketType } from "@/lib/types/market";

export const initializeMarket = async (
  availableMarket: AvailableMarket<MarketType>
): Promise<MarketData> => {
  const market = await getMarketRessource(availableMarket);

  const creator = market.creator as Address;
  const createdAt = Number(market.created_at);
  const startTime = Number(market.start_time);
  const endTime = Number(market.end_time);
  const minBet = 1000000; // Default min bet (0.01 APT)
  const upBetsSum = Number(market.total_yes_bets);
  const downBetsSum = Number(market.total_no_bets);
  const fee = Number(market.market_fee_rate) / 10000; // Convert from basis points
  const resolvedAt = market.resolved ? Number(market.resolution_time) : null;
  const endPrice = null; // Not available in current structure
  const startPrice = Number(market.current_yes_price) / 100; // Convert from basis points to percentage

  // Initialize empty maps since betting data is not available in current structure
  const upBets = new Map<Address, number>();
  const downBets = new Map<Address, number>();
  const userVotes = new Map<Address, boolean>();

  const upVotesSum = 0; // Not available in current structure
  const downVotesSum = 0; // Not available in current structure

  const name = market.title || `${
    availableMarket.type
  }/USD by ${DateTime.fromSeconds(endTime).toLocaleString()}`;

  const tradingPair = {
    one: availableMarket.type,
    two: "USD",
  };

  const [upWinFactor, downWinFactor] = calculateWinFactors([
    upBetsSum,
    downBetsSum
  ]);

  const newMarketData: MarketData = {
    name,
    address: availableMarket.address,
    tradingPair,
    creator,
    createdAt,
    startPrice,
    startTime,
    endTime,
    minBet,
    upBetsSum,
    downBetsSum,
    fee,
    upBets,
    downBets,
    userVotes,
    upVotesSum,
    downVotesSum,
    upWinFactor,
    downWinFactor,
    resolvedAt,
    endPrice,
  };

  return newMarketData;
};
