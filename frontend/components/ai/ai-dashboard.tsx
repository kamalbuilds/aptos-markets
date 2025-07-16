"use client";

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Progress } from '@/components/ui/progress';
import {
    TrendingUp,
    TrendingDown,
    Brain,
    Target,
    Shield,
    Zap,
    Eye,
    AlertTriangle,
    CheckCircle,
    Clock,
    Bot,
    BarChart3,
    PieChart,
    LineChart
} from 'lucide-react';
import { BRAND_CONFIG } from '@/lib/brand/config';
import { AIMarketInsights, UserRecommendations, SentimentData } from '@/lib/ai/types';
import { MarketData, EventMarketData } from '@/lib/types/market';

interface AIDashboardProps {
    userAddress?: string;
    markets: (MarketData | EventMarketData)[];
    insights?: AIMarketInsights[];
    recommendations?: UserRecommendations;
}

export function AIDashboard({
    userAddress,
    markets,
    insights = [],
    recommendations
}: AIDashboardProps) {
    const [activeTab, setActiveTab] = useState('insights');
    const [isLoading, setIsLoading] = useState(true);
    const [aiProcessing, setAiProcessing] = useState(false);

    useEffect(() => {
        // Simulate AI processing
        setIsLoading(true);
        const timer = setTimeout(() => setIsLoading(false), 2000);
        return () => clearTimeout(timer);
    }, [markets]);

    if (isLoading) {
        return <AIDashboardSkeleton />;
    }

    return (
        <div className="space-y-6">
            {/* Header Section */}
            <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 p-8 text-white">
                <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-10"></div>
                <div className="relative">
                    <div className="flex items-center gap-3 mb-4">
                        <div className="p-3 rounded-full bg-gradient-to-r from-blue-400 to-purple-500">
                            <Brain className="w-6 h-6 text-white" />
                        </div>
                        <div>
                            <h1 className="text-3xl font-bold">{BRAND_CONFIG.name} AI</h1>
                            <p className="text-blue-200">{BRAND_CONFIG.tagline}</p>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mt-6">
                        <AIMetricCard
                            icon={<Target className="w-5 h-5" />}
                            label="Prediction Accuracy"
                            value="87.3%"
                            trend="+5.2%"
                            positive={true}
                        />
                        <AIMetricCard
                            icon={<Shield className="w-5 h-5" />}
                            label="Risk Score"
                            value="Low"
                            trend="Stable"
                            positive={true}
                        />
                        <AIMetricCard
                            icon={<Zap className="w-5 h-5" />}
                            label="Active Insights"
                            value={insights.length.toString()}
                            trend={`${markets.length} markets`}
                            positive={true}
                        />
                        <AIMetricCard
                            icon={<Eye className="w-5 h-5" />}
                            label="Market Confidence"
                            value="High"
                            trend="92.1%"
                            positive={true}
                        />
                    </div>
                </div>
            </div>

            {/* Main Dashboard Tabs */}
            <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
                <TabsList className="grid w-full grid-cols-5 bg-slate-100 dark:bg-slate-800">
                    <TabsTrigger value="insights" className="flex items-center gap-2">
                        <Brain className="w-4 h-4" />
                        AI Insights
                    </TabsTrigger>
                    <TabsTrigger value="recommendations" className="flex items-center gap-2">
                        <Target className="w-4 h-4" />
                        Recommendations
                    </TabsTrigger>
                    <TabsTrigger value="sentiment" className="flex items-center gap-2">
                        <BarChart3 className="w-4 h-4" />
                        Sentiment
                    </TabsTrigger>
                    <TabsTrigger value="risk" className="flex items-center gap-2">
                        <Shield className="w-4 h-4" />
                        Risk Analysis
                    </TabsTrigger>
                    <TabsTrigger value="chat" className="flex items-center gap-2">
                        <Bot className="w-4 h-4" />
                        AI Assistant
                    </TabsTrigger>
                </TabsList>

                <TabsContent value="insights">
                    <MarketInsightsPanel insights={insights} />
                </TabsContent>

                <TabsContent value="recommendations">
                    <RecommendationsPanel recommendations={recommendations} />
                </TabsContent>

                <TabsContent value="sentiment">
                    <SentimentAnalysisPanel insights={insights} />
                </TabsContent>

                <TabsContent value="risk">
                    <RiskAnalysisPanel insights={insights} />
                </TabsContent>

                <TabsContent value="chat">
                    <AIChatPanel userAddress={userAddress} />
                </TabsContent>
            </Tabs>
        </div>
    );
}

// AI Metric Card Component
function AIMetricCard({
    icon,
    label,
    value,
    trend,
    positive
}: {
    icon: React.ReactNode;
    label: string;
    value: string;
    trend: string;
    positive: boolean;
}) {
    return (
        <motion.div
            whileHover={{ scale: 1.02 }}
            className="bg-white/10 backdrop-blur-lg rounded-xl p-4 border border-white/20"
        >
            <div className="flex items-center gap-3 mb-2">
                <div className="text-blue-300">{icon}</div>
                <span className="text-sm font-medium text-blue-100">{label}</span>
            </div>
            <div className="text-2xl font-bold text-white mb-1">{value}</div>
            <div className={`text-sm flex items-center gap-1 ${positive ? 'text-green-300' : 'text-red-300'
                }`}>
                {positive ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
                {trend}
            </div>
        </motion.div>
    );
}

// Market Insights Panel
function MarketInsightsPanel({ insights }: { insights: AIMarketInsights[] }) {
    return (
        <div className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {insights.slice(0, 4).map((insight, index) => (
                    <motion.div
                        key={insight.marketId}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: index * 0.1 }}
                    >
                        <Card className="bg-gradient-to-br from-white to-blue-50 dark:from-slate-900 dark:to-slate-800 border-blue-200 dark:border-blue-800">
                            <CardHeader className="pb-3">
                                <div className="flex items-center justify-between">
                                    <CardTitle className="text-lg">{insight.marketId.slice(0, 8)}...</CardTitle>
                                    <Badge
                                        variant={insight.recommendedAction === 'BUY_UP' ? 'default' :
                                            insight.recommendedAction === 'BUY_DOWN' ? 'destructive' :
                                                'secondary'}
                                        className="font-medium"
                                    >
                                        {insight.recommendedAction.replace('_', ' ')}
                                    </Badge>
                                </div>
                            </CardHeader>
                            <CardContent className="space-y-4">
                                {/* Prediction Confidence */}
                                <div>
                                    <div className="flex justify-between text-sm mb-2">
                                        <span>Prediction Confidence</span>
                                        <span className="font-medium">{(insight.predictionConfidence * 100).toFixed(1)}%</span>
                                    </div>
                                    <Progress
                                        value={insight.predictionConfidence * 100}
                                        className="h-2"
                                    />
                                </div>

                                {/* Risk Score */}
                                <div>
                                    <div className="flex justify-between text-sm mb-2">
                                        <span>Risk Score</span>
                                        <span className={`font-medium ${insight.riskScore < 30 ? 'text-green-600' :
                                                insight.riskScore < 70 ? 'text-yellow-600' : 'text-red-600'
                                            }`}>
                                            {insight.riskScore.toFixed(0)}/100
                                        </span>
                                    </div>
                                    <Progress
                                        value={insight.riskScore}
                                        className="h-2"
                                    />
                                </div>

                                {/* Sentiment Indicator */}
                                <div className="flex items-center justify-between">
                                    <span className="text-sm">Market Sentiment</span>
                                    <div className="flex items-center gap-2">
                                        {insight.marketSentiment.overall > 0.3 ? (
                                            <TrendingUp className="w-4 h-4 text-green-500" />
                                        ) : insight.marketSentiment.overall < -0.3 ? (
                                            <TrendingDown className="w-4 h-4 text-red-500" />
                                        ) : (
                                            <div className="w-4 h-4 rounded-full bg-gray-400" />
                                        )}
                                        <span className="text-sm font-medium">
                                            {insight.marketSentiment.overall > 0.3 ? 'Bullish' :
                                                insight.marketSentiment.overall < -0.3 ? 'Bearish' : 'Neutral'}
                                        </span>
                                    </div>
                                </div>

                                {/* Price Targets */}
                                {insight.priceTarget && (
                                    <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3">
                                        <div className="text-sm font-medium mb-2">AI Price Targets</div>
                                        <div className="grid grid-cols-3 gap-2 text-xs">
                                            <div className="text-center">
                                                <div className="text-green-600 font-medium">{insight.priceTarget.high}</div>
                                                <div>High</div>
                                            </div>
                                            <div className="text-center">
                                                <div className="text-blue-600 font-medium">{insight.priceTarget.expected}</div>
                                                <div>Expected</div>
                                            </div>
                                            <div className="text-center">
                                                <div className="text-red-600 font-medium">{insight.priceTarget.low}</div>
                                                <div>Low</div>
                                            </div>
                                        </div>
                                    </div>
                                )}
                            </CardContent>
                        </Card>
                    </motion.div>
                ))}
            </div>
        </div>
    );
}

// Recommendations Panel
function RecommendationsPanel({ recommendations }: { recommendations?: UserRecommendations }) {
    if (!recommendations) {
        return (
            <Card className="p-8 text-center">
                <Bot className="w-12 h-12 mx-auto mb-4 text-blue-500" />
                <h3 className="text-lg font-semibold mb-2">Connect Your Wallet</h3>
                <p className="text-gray-600 dark:text-gray-400">
                    Connect your wallet to receive personalized AI recommendations
                </p>
            </Card>
        );
    }

    return (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Suggested Markets */}
            <Card>
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Target className="w-5 h-5 text-blue-500" />
                        Suggested Markets
                    </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                    {recommendations.suggestedMarkets.slice(0, 3).map((market, index) => (
                        <div key={market.marketId} className="border rounded-lg p-4">
                            <div className="flex justify-between items-start mb-2">
                                <div className="text-sm font-medium">{market.marketId.slice(0, 12)}...</div>
                                <Badge variant={
                                    market.riskLevel === 'LOW' ? 'default' :
                                        market.riskLevel === 'MEDIUM' ? 'secondary' : 'destructive'
                                }>
                                    {market.riskLevel} RISK
                                </Badge>
                            </div>
                            <div className="text-sm text-gray-600 dark:text-gray-400 mb-2">
                                Expected Return: {(market.expectedReturn * 100).toFixed(1)}%
                            </div>
                            <Progress value={market.relevanceScore * 100} className="h-2" />
                        </div>
                    ))}
                </CardContent>
            </Card>

            {/* Personalized Insights */}
            <Card>
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Brain className="w-5 h-5 text-purple-500" />
                        Personal Insights
                    </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                    {recommendations.personalizedInsights.slice(0, 3).map((insight, index) => (
                        <div key={index} className="border rounded-lg p-4">
                            <div className="flex items-start gap-3">
                                {insight.type === 'OPPORTUNITY' && <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />}
                                {insight.type === 'WARNING' && <AlertTriangle className="w-5 h-5 text-yellow-500 mt-0.5" />}
                                {insight.type === 'EDUCATION' && <Brain className="w-5 h-5 text-blue-500 mt-0.5" />}
                                <div className="flex-1">
                                    <div className="font-medium text-sm">{insight.title}</div>
                                    <div className="text-xs text-gray-600 dark:text-gray-400 mt-1">
                                        {insight.description}
                                    </div>
                                </div>
                            </div>
                        </div>
                    ))}
                </CardContent>
            </Card>
        </div>
    );
}

// Sentiment Analysis Panel  
function SentimentAnalysisPanel({ insights }: { insights: AIMarketInsights[] }) {
    const avgSentiment = insights.reduce((sum, insight) => sum + insight.marketSentiment.overall, 0) / insights.length || 0;

    return (
        <div className="space-y-6">
            <Card>
                <CardHeader>
                    <CardTitle>Overall Market Sentiment</CardTitle>
                </CardHeader>
                <CardContent>
                    <div className="flex items-center justify-center p-8">
                        <div className="text-center">
                            <div className={`text-6xl font-bold mb-4 ${avgSentiment > 0.3 ? 'text-green-500' :
                                    avgSentiment < -0.3 ? 'text-red-500' : 'text-gray-500'
                                }`}>
                                {avgSentiment > 0.3 ? '📈' : avgSentiment < -0.3 ? '📉' : '➡️'}
                            </div>
                            <div className="text-2xl font-bold">
                                {avgSentiment > 0.3 ? 'Bullish' :
                                    avgSentiment < -0.3 ? 'Bearish' : 'Neutral'}
                            </div>
                            <div className="text-gray-600 dark:text-gray-400">
                                Confidence: {(Math.abs(avgSentiment) * 100).toFixed(1)}%
                            </div>
                        </div>
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}

// Risk Analysis Panel
function RiskAnalysisPanel({ insights }: { insights: AIMarketInsights[] }) {
    const avgRisk = insights.reduce((sum, insight) => sum + insight.riskScore, 0) / insights.length || 0;

    return (
        <div className="space-y-6">
            <Card>
                <CardHeader>
                    <CardTitle>Portfolio Risk Assessment</CardTitle>
                </CardHeader>
                <CardContent>
                    <div className="space-y-4">
                        <div className="text-center">
                            <div className={`text-4xl font-bold mb-2 ${avgRisk < 30 ? 'text-green-500' :
                                    avgRisk < 70 ? 'text-yellow-500' : 'text-red-500'
                                }`}>
                                {avgRisk.toFixed(0)}/100
                            </div>
                            <div className="text-lg font-medium">
                                {avgRisk < 30 ? 'Low Risk' :
                                    avgRisk < 70 ? 'Medium Risk' : 'High Risk'}
                            </div>
                        </div>
                        <Progress value={avgRisk} className="h-4" />
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}

// AI Chat Panel
function AIChatPanel({ userAddress }: { userAddress?: string }) {
    return (
        <Card className="h-96">
            <CardHeader>
                <CardTitle className="flex items-center gap-2">
                    <Bot className="w-5 h-5 text-blue-500" />
                    AI Market Assistant
                </CardTitle>
            </CardHeader>
            <CardContent className="flex items-center justify-center h-full">
                <div className="text-center">
                    <Bot className="w-16 h-16 mx-auto mb-4 text-blue-500" />
                    <h3 className="text-lg font-semibold mb-2">AI Assistant Coming Soon</h3>
                    <p className="text-gray-600 dark:text-gray-400">
                        Our AI-powered market assistant will help you make better trading decisions
                    </p>
                </div>
            </CardContent>
        </Card>
    );
}

// Loading Skeleton
function AIDashboardSkeleton() {
    return (
        <div className="space-y-6 animate-pulse">
            <div className="h-48 bg-gradient-to-br from-slate-200 to-slate-300 dark:from-slate-800 dark:to-slate-700 rounded-2xl"></div>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {[...Array(4)].map((_, i) => (
                    <div key={i} className="h-64 bg-slate-200 dark:bg-slate-800 rounded-xl"></div>
                ))}
            </div>
        </div>
    );
} 