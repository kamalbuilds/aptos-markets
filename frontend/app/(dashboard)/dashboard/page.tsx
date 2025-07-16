"use client";

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useWallet } from '@aptos-labs/wallet-adapter-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Brain,
  TrendingUp,
  Target,
  Shield,
  Zap,
  BarChart3,
  Users,
  DollarSign,
  Activity,
  Sparkles,
  ArrowRight,
  Play
} from 'lucide-react';

import { BRAND_CONFIG } from '@/lib/brand/config';
import { AIDashboard } from '@/components/ai/ai-dashboard';
import { SentimentWidget } from '@/components/ai/sentiment-widget';
import { DashboardContent } from '@/components/dashboard/dashboard-content';
import { Logo, LogoHero } from '@/components/sidenav/logo';

// Mock data for demonstration
const mockMarkets = [
  {
    address: '0x1111111111111111111111111111111111111111',
    name: 'BTC Price Prediction',
    tradingPair: { one: 'BTC', two: 'USD' },
    creator: '0x2222222222222222222222222222222222222222',
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
  }
];

const mockSentiment = {
  overall: 0.65,
  sources: [
    {
      source: 'news' as const,
      sentiment: 0.7,
      volume: 1500,
      confidence: 0.85,
      sampleSize: 1500
    },
    {
      source: 'twitter' as const,
      sentiment: 0.6,
      volume: 3200,
      confidence: 0.78,
      sampleSize: 3200
    }
  ],
  volume: 4700,
  trending: true,
  keywords: ['bitcoin', 'bullish', 'institutional', 'adoption'],
  newsImpact: 0.8,
  socialMediaBuzz: 0.75
};

export default function DashboardPage() {
  const { connected, account } = useWallet();
  const [activeView, setActiveView] = useState('overview');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Simulate loading
    const timer = setTimeout(() => setIsLoading(false), 1500);
    return () => clearTimeout(timer);
  }, []);

  if (isLoading) {
    return <DashboardSkeleton />;
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-slate-100 dark:from-slate-950 dark:via-blue-950 dark:to-slate-900">
      <div className="container mx-auto p-6 space-y-8">
        {/* Hero Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-blue-900 via-purple-900 to-slate-900 p-8 text-white"
        >
          {/* Background Pattern */}
          <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-10"></div>
          <div className="absolute top-0 right-0 w-64 h-64 bg-gradient-to-bl from-blue-400/20 to-transparent rounded-full blur-3xl"></div>
          <div className="absolute bottom-0 left-0 w-48 h-48 bg-gradient-to-tr from-purple-400/20 to-transparent rounded-full blur-3xl"></div>

          <div className="relative">
            <div className="flex flex-col lg:flex-row items-start justify-between gap-8">
              <div className="flex-1">
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.2 }}
                  className="flex items-center gap-4 mb-6"
                >
                  <div className="p-3 bg-gradient-to-r from-blue-500 to-purple-600 rounded-2xl shadow-2xl">
                    <Brain className="w-8 h-8 text-white" />
                  </div>
                  <div>
                    <h1 className="text-4xl font-bold bg-gradient-to-r from-white to-blue-200 bg-clip-text text-transparent">
                      Welcome to {BRAND_CONFIG.name}
                    </h1>
                    <p className="text-xl text-blue-200 mt-2">
                      {BRAND_CONFIG.tagline}
                    </p>
                  </div>
                </motion.div>

                <motion.p
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.4 }}
                  className="text-lg text-blue-100 mb-8 max-w-2xl leading-relaxed"
                >
                  Experience the future of prediction markets powered by advanced AI.
                  Get intelligent insights, personalized recommendations, and real-time
                  market analysis to make smarter trading decisions.
                </motion.p>

                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.6 }}
                  className="flex flex-wrap gap-4"
                >
                  <Button
                    size="lg"
                    className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700 text-white border-0 shadow-xl shadow-blue-500/25"
                  >
                    <Sparkles className="w-5 h-5 mr-2" />
                    Explore AI Features
                    <ArrowRight className="w-4 h-4 ml-2" />
                  </Button>

                  {!connected && (
                    <Button
                      variant="outline"
                      size="lg"
                      className="border-white/20 text-white hover:bg-white/10"
                    >
                      Connect Wallet
                    </Button>
                  )}
                </motion.div>
              </div>

              {/* Stats Grid */}
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.8 }}
                className="grid grid-cols-2 gap-4 min-w-[300px]"
              >
                <StatCard
                  icon={<BarChart3 className="w-5 h-5" />}
                  label="Active Markets"
                  value="24"
                  trend="+12%"
                />
                <StatCard
                  icon={<Users className="w-5 h-5" />}
                  label="Total Users"
                  value="8.2K"
                  trend="+23%"
                />
                <StatCard
                  icon={<DollarSign className="w-5 h-5" />}
                  label="Volume 24h"
                  value="$2.4M"
                  trend="+18%"
                />
                <StatCard
                  icon={<Target className="w-5 h-5" />}
                  label="AI Accuracy"
                  value="87.3%"
                  trend="+5.2%"
                />
              </motion.div>
            </div>
          </div>
        </motion.div>

        {/* Navigation Tabs */}
        <Tabs value={activeView} onValueChange={setActiveView} className="space-y-6">
          <TabsList className="grid w-full grid-cols-4 bg-white/50 dark:bg-slate-800/50 backdrop-blur-lg border border-gray-200 dark:border-gray-700">
            <TabsTrigger value="overview" className="flex items-center gap-2">
              <Activity className="w-4 h-4" />
              Overview
            </TabsTrigger>
            <TabsTrigger value="ai-dashboard" className="flex items-center gap-2">
              <Brain className="w-4 h-4" />
              AI Dashboard
            </TabsTrigger>
            <TabsTrigger value="markets" className="flex items-center gap-2">
              <BarChart3 className="w-4 h-4" />
              Markets
            </TabsTrigger>
            <TabsTrigger value="portfolio" className="flex items-center gap-2">
              <Shield className="w-4 h-4" />
              Portfolio
            </TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-6">
            <OverviewContent connected={connected} />
          </TabsContent>

          <TabsContent value="ai-dashboard" className="space-y-6">
            <AIDashboard
              userAddress={account?.address}
              markets={mockMarkets}
              insights={[]}
            />
          </TabsContent>

          <TabsContent value="markets" className="space-y-6">
            <DashboardContent />
          </TabsContent>

          <TabsContent value="portfolio" className="space-y-6">
            <PortfolioContent connected={connected} />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}

// Overview Content Component
function OverviewContent({ connected }: { connected: boolean }) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Market Sentiment */}
      <div className="lg:col-span-2">
        <SentimentWidget sentiment={mockSentiment} />
      </div>

      {/* Quick Stats */}
      <Card className="bg-gradient-to-br from-white to-blue-50 dark:from-slate-900 dark:to-slate-800">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap className="w-5 h-5 text-yellow-500" />
            Quick Stats
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600 dark:text-gray-400">Your Accuracy</span>
            <Badge variant="secondary">92.1%</Badge>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600 dark:text-gray-400">Total Bets</span>
            <Badge variant="outline">47</Badge>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600 dark:text-gray-400">Profit/Loss</span>
            <Badge variant="default" className="bg-green-100 text-green-800">+$234</Badge>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600 dark:text-gray-400">Streak</span>
            <Badge variant="secondary">🔥 5 wins</Badge>
          </div>
        </CardContent>
      </Card>

      {/* AI Insights Preview */}
      <Card className="lg:col-span-3 bg-gradient-to-br from-purple-50 to-blue-50 dark:from-purple-950/50 dark:to-blue-950/50">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Brain className="w-5 h-5 text-purple-500" />
            AI Market Insights
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <InsightCard
              title="BTC Outlook"
              prediction="Bullish"
              confidence={87}
              icon="📈"
            />
            <InsightCard
              title="Market Volatility"
              prediction="Moderate"
              confidence={76}
              icon="📊"
            />
            <InsightCard
              title="Best Entry"
              prediction="Next 2h"
              confidence={91}
              icon="⏰"
            />
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// Portfolio Content Component
function PortfolioContent({ connected }: { connected: boolean }) {
  if (!connected) {
    return (
      <Card className="text-center p-8">
        <div className="flex flex-col items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center">
            <Shield className="w-8 h-8 text-blue-500" />
          </div>
          <h3 className="text-xl font-semibold">Connect Your Wallet</h3>
          <p className="text-gray-600 dark:text-gray-400 max-w-md">
            Connect your wallet to view your portfolio, track performance, and get personalized AI recommendations.
          </p>
          <Button className="mt-4">
            <Play className="w-4 h-4 mr-2" />
            Connect Wallet
          </Button>
        </div>
      </Card>
    );
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <Card>
        <CardHeader>
          <CardTitle>Portfolio Overview</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8">
            <p className="text-gray-600 dark:text-gray-400">Portfolio features coming soon...</p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Recent Activity</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8">
            <p className="text-gray-600 dark:text-gray-400">Activity tracking coming soon...</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// Helper Components
function StatCard({ icon, label, value, trend }: {
  icon: React.ReactNode;
  label: string;
  value: string;
  trend: string;
}) {
  return (
    <motion.div
      whileHover={{ scale: 1.02 }}
      className="bg-white/10 backdrop-blur-lg rounded-xl p-4 border border-white/20"
    >
      <div className="flex items-center gap-2 mb-2">
        <div className="text-blue-300">{icon}</div>
        <span className="text-sm font-medium text-blue-100">{label}</span>
      </div>
      <div className="text-2xl font-bold text-white mb-1">{value}</div>
      <div className="text-sm text-green-300 flex items-center gap-1">
        <TrendingUp className="w-3 h-3" />
        {trend}
      </div>
    </motion.div>
  );
}

function InsightCard({ title, prediction, confidence, icon }: {
  title: string;
  prediction: string;
  confidence: number;
  icon: string;
}) {
  return (
    <div className="bg-white/50 dark:bg-slate-800/50 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
      <div className="flex items-center gap-3 mb-3">
        <span className="text-2xl">{icon}</span>
        <div>
          <div className="font-medium text-sm">{title}</div>
          <div className="text-lg font-bold">{prediction}</div>
        </div>
      </div>
      <div className="flex items-center justify-between text-sm">
        <span className="text-gray-600 dark:text-gray-400">Confidence</span>
        <span className="font-medium">{confidence}%</span>
      </div>
    </div>
  );
}

function DashboardSkeleton() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-slate-100 dark:from-slate-950 dark:via-blue-950 dark:to-slate-900">
      <div className="container mx-auto p-6 space-y-8 animate-pulse">
        <div className="h-64 bg-gradient-to-br from-slate-200 to-slate-300 dark:from-slate-800 dark:to-slate-700 rounded-3xl"></div>
        <div className="h-12 bg-slate-200 dark:bg-slate-800 rounded-xl"></div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 h-64 bg-slate-200 dark:bg-slate-800 rounded-xl"></div>
          <div className="h-64 bg-slate-200 dark:bg-slate-800 rounded-xl"></div>
        </div>
      </div>
    </div>
  );
}

