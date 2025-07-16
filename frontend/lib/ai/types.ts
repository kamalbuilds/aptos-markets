import { MarketType, EventMarketType, Address } from "../types/market";

// AI Prediction Interfaces
export interface AIMarketInsights {
  marketId: string;
  predictionConfidence: number; // 0-1
  trendAnalysis: TrendData[];
  riskScore: number; // 0-100
  marketSentiment: SentimentData;
  recommendedAction: 'BUY_UP' | 'BUY_DOWN' | 'HOLD' | 'AVOID';
  priceTarget?: {
    high: number;
    low: number;
    expected: number;
  };
  aiModelVersion: string;
  timestamp: number;
}

export interface TrendData {
  timeframe: '1h' | '4h' | '1d' | '7d' | '30d';
  direction: 'UP' | 'DOWN' | 'SIDEWAYS';
  strength: number; // 0-1
  confidence: number; // 0-1
  indicators: TechnicalIndicator[];
}

export interface TechnicalIndicator {
  name: string;
  value: number;
  signal: 'BULLISH' | 'BEARISH' | 'NEUTRAL';
  weight: number;
}

export interface SentimentData {
  overall: number; // -1 to 1
  sources: SentimentSource[];
  volume: number;
  trending: boolean;
  keywords: string[];
  newsImpact: number;
  socialMediaBuzz: number;
}

export interface SentimentSource {
  source: 'news' | 'twitter' | 'reddit' | 'telegram' | 'discord';
  sentiment: number; // -1 to 1
  volume: number;
  confidence: number;
  sampleSize: number;
}

// User Recommendation System
export interface UserRecommendations {
  userId: Address;
  suggestedMarkets: MarketRecommendation[];
  riskProfile: RiskProfile;
  optimalBetSizes: BetSizeRecommendation[];
  marketTiming: TimingRecommendation[];
  personalizedInsights: PersonalizedInsight[];
  learningProgress: LearningMetrics;
}

export interface MarketRecommendation {
  marketId: string;
  marketType: MarketType | EventMarketType;
  relevanceScore: number; // 0-1
  reasoningFactors: string[];
  expectedReturn: number;
  riskLevel: 'LOW' | 'MEDIUM' | 'HIGH';
  timeHorizon: string;
  confidenceLevel: number;
}

export interface RiskProfile {
  overallRisk: 'CONSERVATIVE' | 'MODERATE' | 'AGGRESSIVE';
  riskTolerance: number; // 0-1
  preferredMarkets: (MarketType | EventMarketType)[];
  maxBetSize: number;
  diversificationScore: number;
  historicalPerformance: PerformanceMetrics;
}

export interface BetSizeRecommendation {
  marketId: string;
  optimalAmount: number;
  maxAmount: number;
  kellyPercentage: number;
  riskAdjustedSize: number;
  reasoning: string;
}

export interface TimingRecommendation {
  marketId: string;
  entryTiming: 'IMMEDIATE' | 'WAIT' | 'MONITOR';
  optimalEntryWindow: {
    start: number;
    end: number;
  };
  priceTargets: number[];
  volatilityForecast: number;
}

export interface PersonalizedInsight {
  type: 'OPPORTUNITY' | 'WARNING' | 'EDUCATION' | 'ACHIEVEMENT';
  title: string;
  description: string;
  actionable: boolean;
  priority: 'HIGH' | 'MEDIUM' | 'LOW';
  relatedMarkets?: string[];
}

// AI Market Making
export interface AIMarketMaker {
  marketId: string;
  dynamicOdds: OddsCalculation;
  liquidityProvision: LiquidityStrategy;
  priceDiscovery: PriceDiscoveryModel;
  marketEfficiency: EfficiencyMetrics;
  arbitrageOpportunities: ArbitrageOpportunity[];
}

export interface OddsCalculation {
  currentOdds: number[];
  fairValueOdds: number[];
  adjustment: number;
  confidence: number;
  factors: PricingFactor[];
}

export interface LiquidityStrategy {
  requiredLiquidity: number;
  providedLiquidity: number;
  spread: number;
  depthScore: number;
  incentiveRate: number;
}

export interface PriceDiscoveryModel {
  fairValue: number;
  marketPrice: number;
  mispricing: number;
  correctionProbability: number;
  timeToCorrection: number;
}

export interface EfficiencyMetrics {
  priceEfficiency: number; // 0-1
  liquidityEfficiency: number;
  informationEfficiency: number;
  overallScore: number;
  improvementSuggestions: string[];
}

export interface ArbitrageOpportunity {
  markets: string[];
  expectedProfit: number;
  riskLevel: number;
  executionComplexity: 'LOW' | 'MEDIUM' | 'HIGH';
  timeWindow: number;
}

// Fraud Detection
export interface FraudDetection {
  userId: Address;
  marketId: string;
  suspiciousActivityScore: number; // 0-100
  manipulationRisk: RiskLevel;
  botDetectionResult: BotDetectionResult;
  marketIntegrity: IntegrityScore;
  anomalies: AnomalyDetection[];
  actionRecommendation: FraudAction;
}

export interface BotDetectionResult {
  isBotLikely: boolean;
  confidence: number;
  behaviorPatterns: string[];
  humanLikelihood: number;
  accountAge: number;
  activityPatterns: ActivityPattern[];
}

export interface IntegrityScore {
  overall: number; // 0-100
  tradingPatterns: number;
  timing: number;
  volumeAnalysis: number;
  correlationAnalysis: number;
}

export interface AnomalyDetection {
  type: 'VOLUME_SPIKE' | 'TIMING_ANOMALY' | 'PATTERN_BREAK' | 'COORDINATION';
  severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  description: string;
  evidence: string[];
  confidence: number;
}

export type RiskLevel = 'MINIMAL' | 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
export type FraudAction = 'MONITOR' | 'FLAG' | 'RESTRICT' | 'SUSPEND' | 'INVESTIGATE';

// Performance Metrics
export interface PerformanceMetrics {
  totalTrades: number;
  winRate: number;
  avgReturn: number;
  sharpeRatio: number;
  maxDrawdown: number;
  profitFactor: number;
  bestTrade: number;
  worstTrade: number;
  timeframe: string;
}

export interface LearningMetrics {
  accuracyImprovement: number;
  marketKnowledge: number;
  riskManagement: number;
  overallProgress: number;
  achievementLevel: 'NOVICE' | 'INTERMEDIATE' | 'ADVANCED' | 'EXPERT';
  nextMilestone: string;
}

export interface ActivityPattern {
  timeOfDay: number[];
  dayOfWeek: number[];
  frequency: number;
  consistency: number;
  typical: boolean;
}

export interface PricingFactor {
  factor: string;
  impact: number; // -1 to 1
  confidence: number;
  source: string;
}

// AI Chat Assistant
export interface AIChatMessage {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: number;
  context?: ChatContext;
  suggestions?: string[];
  relatedMarkets?: string[];
}

export interface ChatContext {
  marketId?: string;
  topic: 'MARKET_ANALYSIS' | 'RISK_ASSESSMENT' | 'STRATEGY' | 'EDUCATION' | 'GENERAL';
  userIntent: 'QUESTION' | 'REQUEST_ANALYSIS' | 'SEEK_ADVICE' | 'LEARN';
  complexity: 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED';
}

// Automated Market Creation
export interface AutoMarketCreation {
  topicId: string;
  viabilityScore: number; // 0-1
  marketTemplate: MarketTemplate;
  eventDetection: EventDetectionResult;
  trendingScore: number;
  expectedParticipation: number;
  creationRecommendation: 'CREATE' | 'MONITOR' | 'REJECT';
}

export interface MarketTemplate {
  title: string;
  description: string;
  category: MarketType | EventMarketType;
  duration: number;
  minBet: number;
  expectedVolume: number;
  tags: string[];
  difficulty: 'EASY' | 'MEDIUM' | 'HARD';
}

export interface EventDetectionResult {
  eventType: 'SPORTS' | 'POLITICS' | 'CRYPTO' | 'TECH' | 'ENTERTAINMENT';
  eventName: string;
  startTime: number;
  endTime: number;
  participants?: string[];
  sources: string[];
  reliability: number;
  resolutionCriteria: string;
} 