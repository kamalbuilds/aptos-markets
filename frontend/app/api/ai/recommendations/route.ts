import { NextRequest, NextResponse } from 'next/server';
import { AIService } from '@/lib/ai/ai-service';
import { MarketData, EventMarketData, Address } from '@/lib/types/market';

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

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { userId, userHistory, availableMarkets } = body;

    if (!userId) {
      return NextResponse.json(
        { error: 'User ID is required' },
        { status: 400 }
      );
    }

    // Default empty arrays if not provided
    const history = userHistory || [];
    const markets = availableMarkets || [];

    // Generate personalized recommendations
    const recommendations = await aiService.generateUserRecommendations(
      userId as Address,
      history,
      markets
    );

    return NextResponse.json({
      success: true,
      data: recommendations,
      timestamp: Date.now(),
      userId
    });

  } catch (error) {
    console.error('AI Recommendations API Error:', error);
    return NextResponse.json(
      { 
        error: 'Failed to generate AI recommendations',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get('userId');
    const limit = parseInt(searchParams.get('limit') || '10');

    if (!userId) {
      return NextResponse.json(
        { error: 'User ID is required' },
        { status: 400 }
      );
    }

    // Mock user history and available markets for demo
    const mockHistory = [
      {
        marketId: '0x123...',
        action: 'BUY_UP',
        amount: 100,
        timestamp: Date.now() - 86400000,
        outcome: 'WIN'
      },
      {
        marketId: '0x456...',
        action: 'BUY_DOWN',
        amount: 50,
        timestamp: Date.now() - 172800000,
        outcome: 'LOSS'
      }
    ];

    const mockMarkets: MarketData[] = [
      {
        name: 'BTC Price Prediction',
        address: '0x1111111111111111111111111111111111111111' as Address,
        tradingPair: { one: 'BTC', two: 'USD' },
        creator: '0x2222222222222222222222222222222222222222' as Address,
        createdAt: Date.now() - 86400000,
        startPrice: 50000,
        startTime: Date.now() - 86400000,
        resolvedAt: null,
        endTime: Date.now() + 86400000,
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
      },
      {
        name: 'ETH Price Prediction',
        address: '0x3333333333333333333333333333333333333333' as Address,
        tradingPair: { one: 'ETH', two: 'USD' },
        creator: '0x2222222222222222222222222222222222222222' as Address,
        createdAt: Date.now() - 172800000,
        startPrice: 3000,
        startTime: Date.now() - 172800000,
        resolvedAt: null,
        endTime: Date.now() + 172800000,
        endPrice: null,
        minBet: 1,
        upBetsSum: 500,
        downBetsSum: 600,
        fee: 5,
        upBets: new Map(),
        downBets: new Map(),
        userVotes: new Map(),
        upVotesSum: 5,
        downVotesSum: 6,
        upWinFactor: 2.2,
        downWinFactor: 1.83
      }
    ];

    // Generate recommendations with mock data
    const recommendations = await aiService.generateUserRecommendations(
      userId as Address,
      mockHistory,
      mockMarkets.slice(0, limit)
    );

    return NextResponse.json({
      success: true,
      data: recommendations,
      timestamp: Date.now(),
      userId,
      limit
    });

  } catch (error) {
    console.error('AI Recommendations GET API Error:', error);
    return NextResponse.json(
      { 
        error: 'Failed to fetch AI recommendations',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}

// Risk assessment endpoint
export async function PUT(request: NextRequest) {
  try {
    const body = await request.json();
    const { userId, marketId, betAmount, action } = body;

    if (!userId || !marketId || !betAmount || !action) {
      return NextResponse.json(
        { error: 'Missing required parameters: userId, marketId, betAmount, action' },
        { status: 400 }
      );
    }

    // Mock risk assessment
    const riskAssessment = {
      userId,
      marketId,
      proposedAction: action,
      proposedAmount: betAmount,
      riskScore: Math.random() * 100,
      recommendation: Math.random() > 0.5 ? 'PROCEED' : 'REDUCE_BET_SIZE',
      maxRecommendedBet: betAmount * (0.5 + Math.random() * 0.5),
      confidenceLevel: 0.7 + Math.random() * 0.3,
      riskFactors: [
        'High market volatility',
        'Low liquidity in this market',
        'Recent trend reversal signals'
      ].slice(0, Math.floor(Math.random() * 3) + 1),
      timestamp: Date.now()
    };

    return NextResponse.json({
      success: true,
      data: riskAssessment,
      timestamp: Date.now()
    });

  } catch (error) {
    console.error('AI Risk Assessment API Error:', error);
    return NextResponse.json(
      { 
        error: 'Failed to assess risk',
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
      'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
} 