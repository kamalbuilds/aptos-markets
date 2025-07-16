import { Aptos, AptosConfig, Network } from "@aptos-labs/ts-sdk";
import { createSurfClient } from "@thalalabs/surf";
import { ABI as MarketplaceAbi } from "./marketplace-abi";
import { ABI as MarketAbi } from "./market-abi";
import { ABI as EventMarketAbi } from "./event-market-abi";
import { Address } from "./types/market";
import { TxnBuilderTypes } from "aptos";
import { APTOS_CONFIG, NODE_URL, CONTRACT_ADDRESS } from "./config";

// Production Aptos Configuration
const config = new AptosConfig({
  network: Network.TESTNET,
  fullnode: NODE_URL,
  // Use Nodit if API key is available, otherwise fallback to default
  ...(process.env.NEXT_PUBLIC_NODIT_API_KEY && {
    fullnode: `https://aptos-testnet.nodit.io/${process.env.NEXT_PUBLIC_NODIT_API_KEY}/v1`,
    indexer: `https://aptos-testnet.nodit.io/${process.env.NEXT_PUBLIC_NODIT_API_KEY}/v1/graphql`,
  }),
});

export const aptos = new Aptos(config);

// Create Surf clients with updated ABIs
export const surfClientMarketplace = createSurfClient(aptos).useABI(MarketplaceAbi);
export const surfClientMarket = createSurfClient(aptos).useABI(MarketAbi);
export const surfClientEventMarket = createSurfClient(aptos).useABI(EventMarketAbi);

// Use the deployed contract address
export const MODULE_ADDRESS_FROM_ABI: Address = CONTRACT_ADDRESS;

// Export ABIs for use in the app
export const MARKET_ABI = MarketAbi;
export const MARKETPLACE_ABI = MarketplaceAbi;
export const EVENT_MARKET_ABI = EventMarketAbi;

// Export configuration
export const APTOS_NETWORK = APTOS_CONFIG.network;
export const MAX_GAS_AMOUNT = APTOS_CONFIG.maxGasAmount;
export const GAS_UNIT_PRICE = APTOS_CONFIG.gasUnitPrice;

export const getExplorerObjectLink = (
  objectId: string,
  isTestnet = true // Default to testnet for production deployment
): string => {
  return `https://explorer.aptoslabs.com/object/${objectId}${
    isTestnet ? "?network=testnet" : ""
  }`;
};

export const getExplorerAccountLink = (
  objectId: string,
  isTestnet = true // Default to testnet for production deployment
): string => {
  return `https://explorer.aptoslabs.com/account/${objectId}${
    isTestnet ? "?network=testnet" : ""
  }`;
};

export const getExplorerTxLink = (
  txHash: string,
  isTestnet = true
): string => {
  return `https://explorer.aptoslabs.com/txn/${txHash}${
    isTestnet ? "?network=testnet" : ""
  }`;
};

export const isValidAddress = (address: string): boolean => {
  try {
    return TxnBuilderTypes.AccountAddress.isValid(address);
  } catch (err: unknown) {
    return false;
  }
};

export const octasToApt = (input: number): number => {
  return input / 10 ** 8;
};

export const aptToOctas = (input: number): number => {
  return input * 10 ** 8;
};
