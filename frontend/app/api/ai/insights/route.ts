import { NextRequest, NextResponse } from 'next/server';
import { AIService } from '@/lib/ai/ai-service';
import { MarketData, EventMarketData, MarketType } from '@/lib/types/market';

// Initialize AI Service
const aiService = new AIService({
  models: {
    sentiment: 'sentiment-analysis-v1',
    prediction: 'market-prediction-v1',
    risk: 'risk-assessment-v1',
    recommendation: 'recommendation-engine-v1'
  },
  endpoints: {
    sentiment: process.env.SENTIMENT_API_ENDPOINT || 'https://api.sentiment.ai',
    news: process.env.NEWS_API_ENDPOINT || 'https://newsapi.org/v2',
    social: process.env.SOCIAL_API_ENDPOINT || 'https://api.social.ai',
    market: process.env.MARKET_API_ENDPOINT || 'https://api.market.ai'
  },
  apiKey: process.env.AI_API_KEY
});

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const marketId = searchParams.get('marketId');
    const type = searchParams.get('type') || 'market';

    if (!marketId) {
      return NextResponse.json(
        { error: 'Market ID is required' },
        { status: 400 }
      );
    }

    // Mock market data - replace with actual data fetching
    const mockMarketData: MarketData = {
      name: `Market ${marketId.slice(0, 8)}`,
      address: marketId as `0x${string}`,
      tradingPair: {
        one: 'BTC' as MarketType,
        two: 'USD'
      },
      creator: '0x1234567890abcdef1234567890abcdef12345678' as `0x${string}`,
      createdAt: Date.now() - 86400000, // 1 day ago
      startPrice: 50000,
      startTime: Date.now() - 86400000,
      resolvedAt: null,
      endTime: Date.now() + 86400000, // 1 day from now
      endPrice: null,
      minBet: 1,
      upBetsSum: 1000,
      downBetsSum: 800,
      fee: 5,
      upBets: new Map(),
      downBets: new Map(),
      userVotes: new Map(),
      upVotesSum: 10,
      downVotesSum: 8,
      upWinFactor: 1.8,
      downWinFactor: 2.25
    };

    // Generate AI insights
    const insights = await aiService.generateMarketInsights(mockMarketData);

    return NextResponse.json({
      success: true,
      data: insights,
      timestamp: Date.now(),
      marketId
    });

  } catch (error) {
    console.error('AI Insights API Error:', error);
    return NextResponse.json(
      { 
        error: 'Failed to generate AI insights',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { markets, userId } = body;

    if (!markets || !Array.isArray(markets)) {
      return NextResponse.json(
        { error: 'Markets array is required' },
        { status: 400 }
      );
    }

    // Generate insights for multiple markets
    const insights = await Promise.all(
      markets.map(async (market: MarketData | EventMarketData) => {
        try {
          return await aiService.generateMarketInsights(market);
        } catch (error) {
          console.error(`Failed to generate insights for market ${market.address}:`, error);
          return null;
        }
      })
    );

    // Filter out failed insights
    const validInsights = insights.filter(insight => insight !== null);

    return NextResponse.json({
      success: true,
      data: validInsights,
      processed: validInsights.length,
      total: markets.length,
      timestamp: Date.now()
    });

  } catch (error) {
    console.error('Batch AI Insights API Error:', error);
    return NextResponse.json(
      { 
        error: 'Failed to generate batch AI insights',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}

// Add CORS headers
export async function OPTIONS(request: NextRequest) {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
} 