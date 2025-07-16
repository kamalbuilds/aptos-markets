import type { Metadata } from "next";
import { Inter, Plus_Jakarta_Sans, JetBrains_Mono } from "next/font/google";
import "./globals.css";

import { ThemeProvider } from "@/components/providers/theme-provider";
import { ClientProvider } from "@/components/providers/client-provider";
import { WalletProvider } from "@/components/providers/wallet-provider";
import { AutoConnectProvider } from "@/components/providers/auto-connect-provider";
import { TelegramProvider } from "@/components/providers/telegram-provider";

import { BRAND_CONFIG } from "@/lib/brand/config";

// Load fonts
const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: 'swap',
});

const plusJakartaSans = Plus_Jakarta_Sans({
  subsets: ["latin"],
  variable: "--font-plus-jakarta",
  display: 'swap',
});

const jetBrainsMono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-jetbrains",
  display: 'swap',
});

export const metadata: Metadata = {
  metadataBase: new URL(BRAND_CONFIG.appUrl),
  title: {
    default: `${BRAND_CONFIG.name} - ${BRAND_CONFIG.tagline}`,
    template: `%s | ${BRAND_CONFIG.name}`,
  },
  description: BRAND_CONFIG.description,
  keywords: [
    "aptos",
    "prediction markets",
    "ai trading",
    "blockchain",
    "defi",
    "web3",
    "artificial intelligence",
    "market prediction",
    "smart contracts",
    "decentralized finance"
  ],
  authors: [{ name: BRAND_CONFIG.name }],
  creator: BRAND_CONFIG.name,
  publisher: BRAND_CONFIG.name,
  applicationName: BRAND_CONFIG.name,

  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },

  icons: {
    icon: [
      { url: '/favicon.ico' },
      { url: '/icon-16x16.png', sizes: '16x16', type: 'image/png' },
      { url: '/icon-32x32.png', sizes: '32x32', type: 'image/png' },
    ],
    apple: [
      { url: '/apple-touch-icon.png' },
    ],
    shortcut: '/favicon.ico',
  },

  manifest: '/site.webmanifest',

  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: BRAND_CONFIG.appUrl,
    siteName: BRAND_CONFIG.name,
    title: `${BRAND_CONFIG.name} - ${BRAND_CONFIG.tagline}`,
    description: BRAND_CONFIG.description,
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: `${BRAND_CONFIG.name} - AI-Powered Prediction Markets`,
      },
    ],
  },

  twitter: {
    card: 'summary_large_image',
    title: `${BRAND_CONFIG.name} - ${BRAND_CONFIG.tagline}`,
    description: BRAND_CONFIG.description,
    images: ['/twitter-image.png'],
    creator: '@AptosMarkets',
    site: '@AptosMarkets',
  },

  verification: {
    google: 'your-google-verification-code',
    other: {
      'apple-mobile-web-app-capable': 'yes',
      'apple-mobile-web-app-status-bar-style': 'black-translucent',
    },
  },

  category: 'technology',
  classification: 'DeFi',

  other: {
    'theme-color': BRAND_CONFIG.colors.primary.aptosBlue,
    'color-scheme': 'dark light',
    'mobile-web-app-capable': 'yes',
    'mobile-web-app-status-bar-style': 'default',
    'mobile-web-app-title': BRAND_CONFIG.name,
    'msapplication-TileColor': BRAND_CONFIG.colors.primary.aptosBlue,
    'msapplication-TileImage': '/ms-icon-144x144.png',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        {/* Preconnect to external domains */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />

        {/* Preload critical resources */}
        <link rel="preload" href="/api/market/latest" as="fetch" crossOrigin="anonymous" />

        {/* Additional meta tags for mobile optimization */}
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=5" />
        <meta name="format-detection" content="telephone=no" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        <meta name="apple-mobile-web-app-title" content={BRAND_CONFIG.name} />

        {/* PWA specific meta tags */}
        <meta name="theme-color" content={BRAND_CONFIG.colors.primary.aptosBlue} />
        <meta name="background-color" content={BRAND_CONFIG.colors.primary.aptosNavy} />

        {/* Security headers */}
        <meta httpEquiv="X-Content-Type-Options" content="nosniff" />
        <meta httpEquiv="X-Frame-Options" content="DENY" />
        <meta httpEquiv="X-XSS-Protection" content="1; mode=block" />

        {/* Structured data */}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              "@context": "https://schema.org",
              "@type": "WebApplication",
              "name": BRAND_CONFIG.name,
              "description": BRAND_CONFIG.description,
              "url": BRAND_CONFIG.appUrl,
              "applicationCategory": "FinanceApplication",
              "operatingSystem": "Web Browser",
              "creator": {
                "@type": "Organization",
                "name": BRAND_CONFIG.name,
                "url": BRAND_CONFIG.appUrl,
              },
              "offers": {
                "@type": "Offer",
                "price": "0",
                "priceCurrency": "USD"
              }
            })
          }}
        />
      </head>
      <body
        className={`
          ${inter.variable} 
          ${plusJakartaSans.variable} 
          ${jetBrainsMono.variable} 
          min-h-screen 
          bg-gradient-to-br 
          from-slate-50 
          via-blue-50 
          to-slate-100 
          dark:from-slate-950 
          dark:via-blue-950 
          dark:to-slate-900
          font-inter
          antialiased
        `}
      >
        {/* Global Loading Indicator */}
        <div id="global-loading" className="hidden">
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center">
            <div className="bg-white dark:bg-slate-900 rounded-2xl p-8 shadow-2xl border border-gray-200 dark:border-gray-800">
              <div className="flex items-center gap-4">
                <div className="w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
                <div className="text-lg font-semibold">{BRAND_CONFIG.name}</div>
              </div>
            </div>
          </div>
        </div>

        {/* Provider Stack */}
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange={false}
        >
          <ClientProvider>
            <WalletProvider>
              <AutoConnectProvider>
                <TelegramProvider>
                  {/* Background Pattern */}
                  <div className="fixed inset-0 bg-[url('/grid.svg')] opacity-[0.02] pointer-events-none"></div>

                  {/* Main App Container */}
                  <div className="relative min-h-screen">
                    {children}
                  </div>

                  {/* Performance Metrics Script */}
                  <script
                    dangerouslySetInnerHTML={{
                      __html: `
                        if ('serviceWorker' in navigator) {
                          navigator.serviceWorker.register('/sw.js');
                        }
                        
                        // Track Core Web Vitals
                        if ('web-vital' in window) {
                          window.webVitals.getCLS(console.log);
                          window.webVitals.getFID(console.log);
                          window.webVitals.getLCP(console.log);
                        }
                      `
                    }}
                  />
                </TelegramProvider>
              </AutoConnectProvider>
            </WalletProvider>
          </ClientProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
