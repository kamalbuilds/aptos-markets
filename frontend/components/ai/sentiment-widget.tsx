"use client";

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import {
    TrendingUp,
    TrendingDown,
    Activity,
    Twitter,
    Globe,
    MessageSquare,
    BarChart3
} from 'lucide-react';
import { SentimentData, SentimentSource } from '@/lib/ai/types';

interface SentimentWidgetProps {
    sentiment: SentimentData;
    isLoading?: boolean;
    showSources?: boolean;
    compact?: boolean;
}

export function SentimentWidget({
    sentiment,
    isLoading = false,
    showSources = true,
    compact = false
}: SentimentWidgetProps) {
    const [animatedValue, setAnimatedValue] = useState(0);

    useEffect(() => {
        if (!isLoading) {
            setAnimatedValue(sentiment.overall);
        }
    }, [sentiment.overall, isLoading]);

    if (isLoading) {
        return <SentimentWidgetSkeleton compact={compact} />;
    }

    const sentimentLabel = getSentimentLabel(sentiment.overall);
    const sentimentColor = getSentimentColor(sentiment.overall);
    const sentimentIcon = getSentimentIcon(sentiment.overall);

    return (
        <Card className={`${compact ? 'p-4' : ''} bg-gradient-to-br from-white to-blue-50 dark:from-slate-900 dark:to-slate-800`}>
            {!compact && (
                <CardHeader className="pb-3">
                    <CardTitle className="flex items-center gap-2 text-lg">
                        <Activity className="w-5 h-5 text-blue-500" />
                        Market Sentiment
                    </CardTitle>
                </CardHeader>
            )}

            <CardContent className={compact ? 'p-0' : ''}>
                <div className="space-y-4">
                    {/* Main Sentiment Display */}
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <motion.div
                                initial={{ scale: 0 }}
                                animate={{ scale: 1 }}
                                className={`p-2 rounded-full ${sentimentColor.bg}`}
                            >
                                {sentimentIcon}
                            </motion.div>
                            <div>
                                <div className={`font-bold text-lg ${sentimentColor.text}`}>
                                    {sentimentLabel}
                                </div>
                                <div className="text-sm text-gray-600 dark:text-gray-400">
                                    Confidence: {Math.abs(sentiment.overall * 100).toFixed(1)}%
                                </div>
                            </div>
                        </div>

                        {sentiment.trending && (
                            <Badge variant="secondary" className="bg-orange-100 text-orange-800">
                                <Activity className="w-3 h-3 mr-1" />
                                Trending
                            </Badge>
                        )}
                    </div>

                    {/* Sentiment Meter */}
                    <div className="space-y-2">
                        <div className="flex justify-between text-sm">
                            <span>Bearish</span>
                            <span>Neutral</span>
                            <span>Bullish</span>
                        </div>
                        <div className="relative h-3 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                            <motion.div
                                initial={{ width: "50%" }}
                                animate={{
                                    width: `${((sentiment.overall + 1) / 2) * 100}%`
                                }}
                                transition={{ duration: 1, ease: "easeOut" }}
                                className={`h-full ${sentiment.overall > 0.3 ? 'bg-green-500' :
                                        sentiment.overall < -0.3 ? 'bg-red-500' : 'bg-gray-400'
                                    }`}
                            />
                            <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-1 h-5 bg-gray-800 dark:bg-gray-200 rounded-full" />
                        </div>
                    </div>

                    {/* Volume Indicator */}
                    {!compact && (
                        <div className="flex items-center justify-between text-sm">
                            <span>Volume: {sentiment.volume.toLocaleString()}</span>
                            <span className="text-gray-600 dark:text-gray-400">
                                {sentiment.keywords.slice(0, 3).join(', ')}
                            </span>
                        </div>
                    )}

                    {/* Source Breakdown */}
                    {showSources && !compact && (
                        <div className="space-y-3">
                            <div className="text-sm font-medium">Source Analysis</div>
                            <div className="grid grid-cols-1 gap-2">
                                {sentiment.sources.map((source, index) => (
                                    <SentimentSourceItem key={index} source={source} />
                                ))}
                            </div>
                        </div>
                    )}

                    {/* News Impact & Social Buzz */}
                    {!compact && (
                        <div className="grid grid-cols-2 gap-4 pt-3 border-t">
                            <div className="text-center">
                                <div className="text-sm text-gray-600 dark:text-gray-400">News Impact</div>
                                <div className="text-lg font-semibold">{(sentiment.newsImpact * 100).toFixed(0)}%</div>
                                <Progress value={sentiment.newsImpact * 100} className="h-1 mt-1" />
                            </div>
                            <div className="text-center">
                                <div className="text-sm text-gray-600 dark:text-gray-400">Social Buzz</div>
                                <div className="text-lg font-semibold">{(sentiment.socialMediaBuzz * 100).toFixed(0)}%</div>
                                <Progress value={sentiment.socialMediaBuzz * 100} className="h-1 mt-1" />
                            </div>
                        </div>
                    )}
                </div>
            </CardContent>
        </Card>
    );
}

// Individual sentiment source component
function SentimentSourceItem({ source }: { source: SentimentSource }) {
    const getSourceIcon = (sourceType: string) => {
        switch (sourceType) {
            case 'twitter': return <Twitter className="w-4 h-4" />;
            case 'news': return <Globe className="w-4 h-4" />;
            case 'reddit':
            case 'telegram':
            case 'discord':
                return <MessageSquare className="w-4 h-4" />;
            default: return <BarChart3 className="w-4 h-4" />;
        }
    };

    const sentimentColor = getSentimentColor(source.sentiment);

    return (
        <div className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
            <div className="flex items-center gap-3">
                <div className={`p-1.5 rounded ${sentimentColor.bg}`}>
                    {getSourceIcon(source.source)}
                </div>
                <div>
                    <div className="text-sm font-medium capitalize">{source.source}</div>
                    <div className="text-xs text-gray-600 dark:text-gray-400">
                        {source.sampleSize.toLocaleString()} samples
                    </div>
                </div>
            </div>

            <div className="text-right">
                <div className={`text-sm font-semibold ${sentimentColor.text}`}>
                    {source.sentiment > 0 ? '+' : ''}{(source.sentiment * 100).toFixed(1)}%
                </div>
                <div className="text-xs text-gray-600 dark:text-gray-400">
                    {(source.confidence * 100).toFixed(0)}% confidence
                </div>
            </div>
        </div>
    );
}

// Loading skeleton
function SentimentWidgetSkeleton({ compact }: { compact: boolean }) {
    return (
        <Card className={`${compact ? 'p-4' : ''} animate-pulse`}>
            {!compact && (
                <CardHeader>
                    <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded w-32"></div>
                </CardHeader>
            )}
            <CardContent className={compact ? 'p-0' : ''}>
                <div className="space-y-4">
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 bg-gray-200 dark:bg-gray-700 rounded-full"></div>
                        <div className="space-y-2">
                            <div className="h-5 bg-gray-200 dark:bg-gray-700 rounded w-20"></div>
                            <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-24"></div>
                        </div>
                    </div>
                    <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded"></div>
                    {!compact && (
                        <div className="space-y-2">
                            <div className="h-16 bg-gray-200 dark:bg-gray-700 rounded"></div>
                            <div className="h-12 bg-gray-200 dark:bg-gray-700 rounded"></div>
                        </div>
                    )}
                </div>
            </CardContent>
        </Card>
    );
}

// Utility functions
function getSentimentLabel(sentiment: number): string {
    if (sentiment > 0.6) return 'Very Bullish';
    if (sentiment > 0.3) return 'Bullish';
    if (sentiment > -0.3) return 'Neutral';
    if (sentiment > -0.6) return 'Bearish';
    return 'Very Bearish';
}

function getSentimentColor(sentiment: number) {
    if (sentiment > 0.3) {
        return {
            text: 'text-green-600 dark:text-green-400',
            bg: 'bg-green-100 dark:bg-green-900'
        };
    }
    if (sentiment < -0.3) {
        return {
            text: 'text-red-600 dark:text-red-400',
            bg: 'bg-red-100 dark:bg-red-900'
        };
    }
    return {
        text: 'text-gray-600 dark:text-gray-400',
        bg: 'bg-gray-100 dark:bg-gray-800'
    };
}

function getSentimentIcon(sentiment: number) {
    if (sentiment > 0.3) {
        return <TrendingUp className="w-5 h-5 text-green-600" />;
    }
    if (sentiment < -0.3) {
        return <TrendingDown className="w-5 h-5 text-red-600" />;
    }
    return <Activity className="w-5 h-5 text-gray-600" />;
} 