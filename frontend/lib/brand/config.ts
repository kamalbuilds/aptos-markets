export const BRAND_CONFIG = {
  name: "Aptos Markets",
  tagline: "Where Intelligence Meets Prediction",
  description: "The world's first AI-powered prediction market platform on Aptos",
  domain: "aptosmarkets.ai",
  appUrl: "https://app.aptosmarkets.ai",
  
  // Brand Colors
  colors: {
    primary: {
      // Aptos-inspired gradient
      aptosBlue: "#00D4FF",
      aptosDeep: "#0066CC", 
      aptosNavy: "#1a1f2e",
      white: "#ffffff",
    },
    secondary: {
      gray: "#8892b0",
      darkBlue: "#0d1421",
      steel: "#2a2d3a",
    },
    accent: {
      success: "#00ff88",
      warning: "#ffb020", 
      error: "#ff5555",
      ai: "#9c27b0", // AI purple
      prediction: "#ff6b35", // Prediction orange
    },
    gradients: {
      primary: "linear-gradient(135deg, #1a1f2e 0%, #00D4FF 100%)",
      ai: "linear-gradient(135deg, #9c27b0 0%, #00D4FF 100%)",
      success: "linear-gradient(135deg, #00ff88 0%, #00D4FF 100%)",
      glass: "linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%)",
    }
  },
  
  // Typography
  fonts: {
    primary: "Inter", // Clean, modern for body text
    display: "Satoshi", // Bold headings and titles
    mono: "JetBrains Mono", // Code, data, and technical content
    accent: "Plus Jakarta Sans", // Special UI elements
  },
  
  // Spacing & Layout
  spacing: {
    xs: "0.25rem",
    sm: "0.5rem", 
    md: "1rem",
    lg: "1.5rem",
    xl: "2rem",
    xxl: "3rem",
  },
  
  // Border Radius
  radius: {
    sm: "4px",
    md: "8px", 
    lg: "12px",
    xl: "16px",
    xxl: "24px",
    round: "9999px",
  },
  
  // Shadows
  shadows: {
    sm: "0 2px 8px rgba(0, 212, 255, 0.1)",
    md: "0 8px 32px rgba(0, 212, 255, 0.15)",
    lg: "0 16px 64px rgba(0, 212, 255, 0.25)",
    ai: "0 8px 32px rgba(156, 39, 176, 0.2)",
    glass: "0 8px 32px rgba(0, 0, 0, 0.1)",
  },
  
  // Animation
  animation: {
    fast: "150ms ease-in-out",
    normal: "300ms ease-in-out", 
    slow: "500ms ease-in-out",
    bounce: "cubic-bezier(0.68, -0.55, 0.265, 1.55)",
  },
  
  // Breakpoints
  breakpoints: {
    sm: "640px",
    md: "768px",
    lg: "1024px", 
    xl: "1280px",
    xxl: "1536px",
  },
  
  // Social Links
  social: {
    twitter: "https://twitter.com/AptosMarkets",
    discord: "https://discord.gg/aptosmarkets",
    telegram: "https://t.me/AptosMarkets",
    github: "https://github.com/aptos-markets",
    docs: "https://docs.aptosmarkets.ai",
  },
  
  // AI Features
  ai: {
    models: {
      sentiment: "sentiment-analysis-v1",
      prediction: "market-prediction-v1", 
      risk: "risk-assessment-v1",
      recommendation: "recommendation-engine-v1",
    },
    confidence: {
      high: 0.8,
      medium: 0.6,
      low: 0.4,
    }
  }
} as const;

export type BrandConfig = typeof BRAND_CONFIG; 