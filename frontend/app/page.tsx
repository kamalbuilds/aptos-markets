"use client";

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
    Brain,
    Target,
    TrendingUp,
    Shield,
    Zap,
    Users,
    BarChart3,
    Bot,
    Sparkles,
    ArrowRight,
    Play,
    CheckCircle,
    Star,
    Globe,
    Activity,
    DollarSign
} from 'lucide-react';

import { BRAND_CONFIG } from '@/lib/brand/config';
import { LogoHero, Logo } from '@/components/sidenav/logo';

export default function LandingPage() {
    const [activeFeature, setActiveFeature] = useState(0);
    const [isVisible, setIsVisible] = useState(false);

    useEffect(() => {
        setIsVisible(true);
        const interval = setInterval(() => {
            setActiveFeature((prev) => (prev + 1) % 4);
        }, 3000);
        return () => clearInterval(interval);
    }, []);

    const features = [
        {
            icon: <Brain className="w-6 h-6" />,
            title: "AI Market Intelligence",
            description: "Advanced algorithms analyze market trends and sentiment"
        },
        {
            icon: <Target className="w-6 h-6" />,
            title: "Personalized Recommendations",
            description: "Get tailored market suggestions based on your trading history"
        },
        {
            icon: <Shield className="w-6 h-6" />,
            title: "Risk Assessment",
            description: "AI-powered risk analysis for every trade decision"
        },
        {
            icon: <Bot className="w-6 h-6" />,
            title: "AI Assistant",
            description: "Chat with our AI to get market insights and trading advice"
        }
    ];

    return (
        <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-slate-100 dark:from-slate-950 dark:via-blue-950 dark:to-slate-900">
            {/* Header */}
            <header className="sticky top-0 z-50 backdrop-blur-lg bg-white/80 dark:bg-slate-900/80 border-b border-gray-200 dark:border-gray-800">
                <div className="container mx-auto px-6 py-4">
                    <div className="flex items-center justify-between">
                        <Logo size="md" />
                        <nav className="hidden md:flex items-center space-x-8">
                            <Link href="#features" className="text-gray-600 hover:text-blue-600 transition-colors">
                                Features
                            </Link>
                            <Link href="#markets" className="text-gray-600 hover:text-blue-600 transition-colors">
                                Markets
                            </Link>
                            <Link href="#about" className="text-gray-600 hover:text-blue-600 transition-colors">
                                About
                            </Link>
                        </nav>
                        <div className="flex items-center gap-4">
                            <Button variant="ghost" asChild>
                                <Link href="/dashboard">Dashboard</Link>
                            </Button>
                            <Button asChild>
                                <Link href="/dashboard">
                                    <Play className="w-4 h-4 mr-2" />
                                    Get Started
                                </Link>
                            </Button>
                        </div>
                    </div>
                </div>
            </header>

            {/* Hero Section */}
            <section className="relative overflow-hidden py-20 lg:py-32">
                <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-[0.02]"></div>
                <div className="absolute top-1/4 left-1/4 w-72 h-72 bg-blue-400/20 rounded-full blur-3xl"></div>
                <div className="absolute bottom-1/4 right-1/4 w-72 h-72 bg-purple-400/20 rounded-full blur-3xl"></div>

                <div className="container mx-auto px-6 relative">
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
                        <motion.div
                            initial={{ opacity: 0, x: -50 }}
                            animate={{ opacity: isVisible ? 1 : 0, x: isVisible ? 0 : -50 }}
                            transition={{ duration: 0.8 }}
                            className="space-y-8"
                        >
                            <div>
                                <motion.div
                                    initial={{ opacity: 0, y: 20 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    transition={{ delay: 0.2 }}
                                    className="flex items-center gap-2 mb-4"
                                >
                                    <Badge variant="secondary" className="bg-blue-100 text-blue-800">
                                        <Sparkles className="w-3 h-3 mr-1" />
                                        AI-Powered
                                    </Badge>
                                    <Badge variant="outline">Built on Aptos</Badge>
                                </motion.div>

                                <h1 className="text-5xl lg:text-7xl font-bold leading-tight">
                                    <span className="bg-gradient-to-r from-blue-600 via-purple-600 to-blue-800 bg-clip-text text-transparent">
                                        Aptos Markets
                                    </span>
                                </h1>
                                <p className="text-2xl lg:text-3xl text-gray-600 dark:text-gray-300 mt-4">
                                    {BRAND_CONFIG.tagline}
                                </p>
                            </div>

                            <p className="text-xl text-gray-600 dark:text-gray-400 leading-relaxed">
                                Experience the future of prediction markets with cutting-edge AI technology.
                                Get intelligent insights, personalized recommendations, and real-time analysis
                                to make smarter trading decisions on the Aptos blockchain.
                            </p>

                            <div className="flex flex-wrap gap-4">
                                <Button size="lg" asChild className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700">
                                    <Link href="/dashboard">
                                        <Brain className="w-5 h-5 mr-2" />
                                        Start Trading with AI
                                        <ArrowRight className="w-4 h-4 ml-2" />
                                    </Link>
                                </Button>
                                <Button size="lg" variant="outline" asChild>
                                    <Link href="#features">
                                        <Play className="w-4 h-4 mr-2" />
                                        Watch Demo
                                    </Link>
                                </Button>
                            </div>

                            {/* Quick Stats */}
                            <div className="grid grid-cols-3 gap-6 pt-8 border-t border-gray-200 dark:border-gray-700">
                                <div className="text-center">
                                    <div className="text-2xl font-bold text-gray-900 dark:text-white">$2.4M+</div>
                                    <div className="text-sm text-gray-600 dark:text-gray-400">Volume</div>
                                </div>
                                <div className="text-center">
                                    <div className="text-2xl font-bold text-gray-900 dark:text-white">87.3%</div>
                                    <div className="text-sm text-gray-600 dark:text-gray-400">AI Accuracy</div>
                                </div>
                                <div className="text-center">
                                    <div className="text-2xl font-bold text-gray-900 dark:text-white">8.2K+</div>
                                    <div className="text-sm text-gray-600 dark:text-gray-400">Users</div>
                                </div>
                            </div>
                        </motion.div>

                        <motion.div
                            initial={{ opacity: 0, x: 50 }}
                            animate={{ opacity: isVisible ? 1 : 0, x: isVisible ? 0 : 50 }}
                            transition={{ duration: 0.8, delay: 0.2 }}
                            className="relative"
                        >
                            <LogoHero />
                        </motion.div>
                    </div>
                </div>
            </section>

            {/* Features Section */}
            <section id="features" className="py-20 bg-white/50 dark:bg-slate-900/50">
                <div className="container mx-auto px-6">
                    <motion.div
                        initial={{ opacity: 0, y: 50 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        className="text-center mb-16"
                    >
                        <h2 className="text-4xl font-bold mb-4">
                            AI-Powered Trading Features
                        </h2>
                        <p className="text-xl text-gray-600 dark:text-gray-400 max-w-3xl mx-auto">
                            Harness the power of artificial intelligence to make smarter predictions
                            and maximize your trading potential.
                        </p>
                    </motion.div>

                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
                        {/* Feature List */}
                        <div className="space-y-6">
                            {features.map((feature, index) => (
                                <motion.div
                                    key={index}
                                    initial={{ opacity: 0, x: -30 }}
                                    whileInView={{ opacity: 1, x: 0 }}
                                    viewport={{ once: true }}
                                    transition={{ delay: index * 0.1 }}
                                    className={`p-6 rounded-xl border-2 transition-all cursor-pointer ${activeFeature === index
                                            ? 'border-blue-500 bg-blue-50 dark:bg-blue-950/50'
                                            : 'border-gray-200 dark:border-gray-700 hover:border-gray-300'
                                        }`}
                                    onClick={() => setActiveFeature(index)}
                                >
                                    <div className="flex items-start gap-4">
                                        <div className={`p-3 rounded-lg ${activeFeature === index
                                                ? 'bg-blue-500 text-white'
                                                : 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400'
                                            }`}>
                                            {feature.icon}
                                        </div>
                                        <div>
                                            <h3 className="text-xl font-semibold mb-2">{feature.title}</h3>
                                            <p className="text-gray-600 dark:text-gray-400">{feature.description}</p>
                                        </div>
                                    </div>
                                </motion.div>
                            ))}
                        </div>

                        {/* Feature Preview */}
                        <motion.div
                            key={activeFeature}
                            initial={{ opacity: 0, scale: 0.9 }}
                            animate={{ opacity: 1, scale: 1 }}
                            transition={{ duration: 0.5 }}
                            className="relative"
                        >
                            <Card className="bg-gradient-to-br from-white to-blue-50 dark:from-slate-900 dark:to-slate-800 shadow-2xl">
                                <CardHeader>
                                    <CardTitle className="flex items-center gap-3">
                                        <div className="p-2 bg-blue-500 rounded-lg text-white">
                                            {features[activeFeature].icon}
                                        </div>
                                        {features[activeFeature].title}
                                    </CardTitle>
                                </CardHeader>
                                <CardContent className="space-y-4">
                                    <FeaturePreview featureIndex={activeFeature} />
                                </CardContent>
                            </Card>
                        </motion.div>
                    </div>
                </div>
            </section>

            {/* Markets Section */}
            <section id="markets" className="py-20">
                <div className="container mx-auto px-6">
                    <motion.div
                        initial={{ opacity: 0, y: 50 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        className="text-center mb-16"
                    >
                        <h2 className="text-4xl font-bold mb-4">Available Markets</h2>
                        <p className="text-xl text-gray-600 dark:text-gray-400">
                            Trade on various prediction markets with AI-powered insights
                        </p>
                    </motion.div>

                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {[
                            { name: 'Bitcoin (BTC)', price: '$67,234', change: '+5.2%', trend: 'up' },
                            { name: 'Ethereum (ETH)', price: '$3,456', change: '+3.1%', trend: 'up' },
                            { name: 'Aptos (APT)', price: '$12.34', change: '+8.7%', trend: 'up' },
                            { name: 'Solana (SOL)', price: '$89.12', change: '-2.1%', trend: 'down' },
                            { name: 'USDC', price: '$1.00', change: '0.0%', trend: 'stable' },
                            { name: 'Sports Events', price: 'Various', change: 'Live', trend: 'live' }
                        ].map((market, index) => (
                            <motion.div
                                key={index}
                                initial={{ opacity: 0, y: 30 }}
                                whileInView={{ opacity: 1, y: 0 }}
                                viewport={{ once: true }}
                                transition={{ delay: index * 0.1 }}
                            >
                                <Card className="hover:shadow-lg transition-shadow cursor-pointer">
                                    <CardContent className="p-6">
                                        <div className="flex items-center justify-between mb-4">
                                            <h3 className="font-semibold">{market.name}</h3>
                                            <Badge variant={
                                                market.trend === 'up' ? 'default' :
                                                    market.trend === 'down' ? 'destructive' :
                                                        market.trend === 'live' ? 'secondary' : 'outline'
                                            }>
                                                {market.change}
                                            </Badge>
                                        </div>
                                        <div className="text-2xl font-bold mb-2">{market.price}</div>
                                        <div className="flex items-center gap-2">
                                            {market.trend === 'up' && <TrendingUp className="w-4 h-4 text-green-500" />}
                                            {market.trend === 'down' && <TrendingUp className="w-4 h-4 text-red-500 transform rotate-180" />}
                                            {market.trend === 'live' && <Activity className="w-4 h-4 text-blue-500" />}
                                            <span className="text-sm text-gray-600 dark:text-gray-400">
                                                {market.trend === 'live' ? 'Live Events' : '24h Change'}
                                            </span>
                                        </div>
                                    </CardContent>
                                </Card>
                            </motion.div>
                        ))}
                    </div>
                </div>
            </section>

            {/* CTA Section */}
            <section className="py-20 bg-gradient-to-br from-blue-900 via-purple-900 to-slate-900 text-white">
                <div className="container mx-auto px-6 text-center">
                    <motion.div
                        initial={{ opacity: 0, y: 50 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        className="max-w-4xl mx-auto"
                    >
                        <h2 className="text-4xl lg:text-5xl font-bold mb-6">
                            Ready to Start Trading with AI?
                        </h2>
                        <p className="text-xl text-blue-200 mb-8">
                            Join thousands of traders using AI-powered insights to make smarter predictions
                        </p>
                        <div className="flex flex-wrap justify-center gap-4">
                            <Button size="lg" asChild className="bg-white text-blue-900 hover:bg-blue-50">
                                <Link href="/dashboard">
                                    <Sparkles className="w-5 h-5 mr-2" />
                                    Get Started Now
                                    <ArrowRight className="w-4 h-4 ml-2" />
                                </Link>
                            </Button>
                            <Button size="lg" variant="outline" className="border-white text-white hover:bg-white/10">
                                Learn More
                            </Button>
                        </div>
                    </motion.div>
                </div>
            </section>

            {/* Footer */}
            <footer className="py-12 bg-slate-900 text-white">
                <div className="container mx-auto px-6">
                    <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
                        <div>
                            <Logo size="sm" />
                            <p className="text-gray-400 mt-4">
                                The world's first AI-powered prediction market platform on Aptos.
                            </p>
                        </div>
                        <div>
                            <h4 className="font-semibold mb-4">Product</h4>
                            <ul className="space-y-2 text-gray-400">
                                <li><Link href="/dashboard" className="hover:text-white">Dashboard</Link></li>
                                <li><Link href="/markets" className="hover:text-white">Markets</Link></li>
                                <li><Link href="/ai" className="hover:text-white">AI Features</Link></li>
                            </ul>
                        </div>
                        <div>
                            <h4 className="font-semibold mb-4">Company</h4>
                            <ul className="space-y-2 text-gray-400">
                                <li><Link href="/about" className="hover:text-white">About</Link></li>
                                <li><Link href="/docs" className="hover:text-white">Documentation</Link></li>
                                <li><Link href="/support" className="hover:text-white">Support</Link></li>
                            </ul>
                        </div>
                        <div>
                            <h4 className="font-semibold mb-4">Community</h4>
                            <ul className="space-y-2 text-gray-400">
                                <li><Link href={BRAND_CONFIG.social.twitter} className="hover:text-white">Twitter</Link></li>
                                <li><Link href={BRAND_CONFIG.social.discord} className="hover:text-white">Discord</Link></li>
                                <li><Link href={BRAND_CONFIG.social.telegram} className="hover:text-white">Telegram</Link></li>
                            </ul>
                        </div>
                    </div>
                    <div className="border-t border-gray-800 mt-8 pt-8 text-center text-gray-400">
                        <p>&copy; 2024 {BRAND_CONFIG.name}. All rights reserved.</p>
                    </div>
                </div>
            </footer>
        </div>
    );
}

// Feature Preview Component
function FeaturePreview({ featureIndex }: { featureIndex: number }) {
    const previews = [
        // AI Market Intelligence
        <div key="intelligence" className="space-y-4">
            <div className="flex items-center justify-between">
                <span>Market Sentiment</span>
                <Badge variant="default" className="bg-green-100 text-green-800">Bullish</Badge>
            </div>
            <div className="bg-blue-100 dark:bg-blue-900 rounded-lg p-4">
                <div className="text-sm text-blue-800 dark:text-blue-200">
                    "AI detected strong bullish sentiment across 15 data sources with 87% confidence"
                </div>
            </div>
        </div>,

        // Personalized Recommendations
        <div key="recommendations" className="space-y-4">
            <div className="border rounded-lg p-3">
                <div className="flex items-center gap-2 mb-2">
                    <Target className="w-4 h-4 text-green-500" />
                    <span className="font-medium">Recommended: BTC Long</span>
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">
                    Based on your 92% accuracy in crypto markets
                </div>
            </div>
        </div>,

        // Risk Assessment
        <div key="risk" className="space-y-4">
            <div className="flex items-center justify-between">
                <span>Risk Level</span>
                <Badge variant="secondary" className="bg-yellow-100 text-yellow-800">Medium</Badge>
            </div>
            <div className="space-y-2">
                <div className="flex justify-between text-sm">
                    <span>Portfolio Risk</span>
                    <span>45/100</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                    <div className="bg-yellow-500 h-2 rounded-full" style={{ width: '45%' }}></div>
                </div>
            </div>
        </div>,

        // AI Assistant
        <div key="assistant" className="space-y-4">
            <div className="bg-gray-100 dark:bg-gray-800 rounded-lg p-3">
                <div className="text-sm">
                    <strong>You:</strong> Should I buy BTC now?
                </div>
            </div>
            <div className="bg-blue-100 dark:bg-blue-900 rounded-lg p-3">
                <div className="text-sm">
                    <strong>AI:</strong> Based on current trends and your risk profile, I recommend waiting for a dip below $66,000 for optimal entry.
                </div>
            </div>
        </div>
    ];

    return previews[featureIndex];
} 