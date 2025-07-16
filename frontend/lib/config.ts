// Aptos Markets Production Configuration
export const APTOS_CONFIG = {
  // Network Configuration
  network: "testnet" as const,
  nodeUrl: "https://fullnode.testnet.aptoslabs.com",
  faucetUrl: "https://faucet.testnet.aptoslabs.com",
  
  // Deployed Contract Addresses (Production - Testnet)
  contractAddress: "0xbf2557e1fca3bf80953a61e49cd2a7b114c28432015978207ab5666d524dbc62" as const,
  
  // Module Names
  modules: {
    marketplace: "aptos_markets::marketplace",
    market: "aptos_markets::market", 
    eventMarket: "aptos_markets::event_market",
    aiOracle: "aptos_markets::ai_oracle",
    riskManager: "aptos_markets::risk_manager",
  },
  
  // Transaction Configuration
  maxGasAmount: 10000,
  gasUnitPrice: 100,
  
  // Feature Flags
  features: {
    aiEnabled: true,
    riskManagement: true,
    eventMarkets: true,
    telegramIntegration: true,
  }
} as const;

export const MARKET_CONFIG = {
  // Betting Configuration
  minBetAmount: 1000000, // 0.01 APT (8 decimals)
  maxRiskExposure: 80, // 80% maximum risk exposure
  aiAdjustmentThreshold: 7500, // 75% AI confidence required
  liquidityBuffer: 10, // 10% liquidity buffer
  
  // Fee Structure (in basis points)
  fees: {
    marketFee: 250, // 2.5%
    creatorFee: 50, // 0.5%
    platformFee: 100, // 1%
  },
  
  // Market Statuses
  status: {
    PENDING: 0,
    ACTIVE: 1,
    PAUSED: 2,
    RESOLVED: 3,
    CANCELLED: 4,
  } as const,
  
  // Categories
  categories: [
    "Crypto",
    "Sports", 
    "Politics",
    "Entertainment",
    "Technology",
    "Weather",
    "Economics",
    "AI & ML",
  ] as const,
} as const;

export const API_CONFIG = {
  // External APIs (replace with your production endpoints)
  baseUrl: process.env.NEXT_PUBLIC_API_BASE_URL || "https://api.aptosmarkets.com",
  websocketUrl: process.env.NEXT_PUBLIC_WEBSOCKET_URL || "wss://ws.aptosmarkets.com",
  
  // Price Feeds
  coingeckoApi: "https://api.coingecko.com/api/v3",
  binanceApi: "https://api.binance.com/api/v3",
  
  // AI Services
  openaiApiKey: process.env.OPENAI_API_KEY,
  coingeckoApiKey: process.env.COINGECKO_API_KEY,
} as const;

export const TELEGRAM_CONFIG = {
  botToken: process.env.TELEGRAM_BOT_TOKEN,
  webhookSecret: process.env.TELEGRAM_WEBHOOK_SECRET,
  botUsername: "@AptosMarketsBot",
} as const;

export const SUPABASE_CONFIG = {
  url: process.env.NEXT_PUBLIC_SUPABASE_URL,
  anonKey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
} as const;

// Utility Functions
export const getContractAddress = (module: keyof typeof APTOS_CONFIG.modules) => {
  return APTOS_CONFIG.contractAddress;
};

export const getModuleName = (module: keyof typeof APTOS_CONFIG.modules) => {
  return APTOS_CONFIG.modules[module];
};

export const isFeatureEnabled = (feature: keyof typeof APTOS_CONFIG.features) => {
  return APTOS_CONFIG.features[feature];
};

// Export commonly used values
export const {
  contractAddress: CONTRACT_ADDRESS,
  network: NETWORK,
  nodeUrl: NODE_URL,
} = APTOS_CONFIG;

export const {
  minBetAmount: MIN_BET_AMOUNT,
  maxRiskExposure: MAX_RISK_EXPOSURE,
  categories: MARKET_CATEGORIES,
} = MARKET_CONFIG; 