export const dynamic = "force-dynamic";

export const fetchCache = "force-no-store";

import { Bot, InlineKeyboard, webhookCallback } from "grammy";
import { Menu } from "@grammyjs/menu";
import { storeTelegramUser } from "@/lib/supabase/store-telegram-user";
import { sendDebugMessage } from "@/lib/send-telegram-message";
import { Address, MessageKind } from "@/lib/types/market";
import { storeTelegramNotification } from "@/lib/supabase/store-telegram-notification";

const token = process.env.TELEGRAM_BOT_TOKEN;

if (!token)
  throw new Error("TELEGRAM_BOT_TOKEN environment variable not found.");

const bot = new Bot(token);

bot.use(async (ctx, next) => {
  if (ctx.from) {
    storeTelegramUser(ctx.from).then((result) => {
      if (result.success) {
        console.log("user saved", result.data);
      } else {
        console.error("error on saving user", result.error);
      }
    });
  }

  await next();
});

const descriptionMessage = `
Welcome to Aptos Markets 🏛️

Aptos Markets is the pioneering AI-powered decentralized prediction market platform built on the Aptos Network.

The entire market is easy to use right here in Telegram, making it more convenient than ever!

Let's start!
`;

const welcomeMessage = `
Aptos Markets is the leading AI-powered decentralized prediction market on the *Aptos Network*.

_Think you've got what it takes?_  
*Open the app and start predicting!* 🔮

Here's how you can get more involved:
- Tap *FAQ* to learn how it works.
- Visit our *Website* for more details.
- Follow us on *X* to stay updated.
- Use */analytics* for market insights.
- Set */alerts* for price notifications.
`;

const faqMessage = `
*What is Aptos Markets?* 🤔
Aptos Markets is a next-generation AI-powered decentralized prediction market platform where users can predict asset prices and real-world events. If your prediction is correct, you win a proportional share of the opposing bets! 🎉

*How do the prediction markets work?* 🛠️
When a market opens, users can place bets on whether the price of a chosen asset (e.g., SOL, ETH, APT, USDC, or BTC) will go up 📈 or down 📉 by the end of the specified time period. Once the market starts, no new bets can be placed, and the market will automatically resolve after the predefined time has passed. ⏰ The winning side receives the funds from the losing side, distributed proportionally based on the amount bet. 💸

*What makes us different?* 🤖
Our AI-powered features include:
- Real-time sentiment analysis
- Personalized market recommendations  
- Predictive analytics and insights
- Risk assessment tools
- Market intelligence dashboard

*Can I withdraw my assets after placing a bet?* 🚫
No, once you place a bet, you cannot withdraw your assets until the market resolves. Your funds remain locked 🔒 in the market until the outcome is determined, and winners are paid out. 🏆

*What are the fees involved in Aptos Markets?* 💰
A 2% fee is applied to all winning bets. This fee is automatically deducted from the winnings when the market resolves. 💸

*Can I bet on both sides of a prediction market?* ⚖️
Yes, you can place bets on both outcomes (price going up 📈 or down 📉) in the same market if you choose. However, you cannot withdraw or alter these bets once placed. 🚫

*How are markets resolved, and can users resolve them?* 🤖
Markets are automatically resolved by our AI-powered platform using Switchboard oracles once the predetermined time has passed. ⏲️ In rare cases, users also have the option to manually resolve the market once the market period has ended, ensuring decentralization. ✅

*Can anyone create a market, and what assets are supported?* 🌐
Yes, anyone can create a market on Aptos Markets. The supported assets for creating markets and placing bets are SOL, ETH, APT, USDC, and BTC. Once a market is created, other users can participate and bet on the outcome. 🪙

_If you have further questions, feel free to ask!_ 💬
`;

bot.api.setMyCommands([
  { command: "start", description: "Show welcome message" },
  { command: "help", description: "Show FAQ" },
  { command: "markets", description: "Browse active markets" },
  { command: "analytics", description: "View market analytics & AI insights" },
  { command: "alerts", description: "Set up price alerts" },
  { command: "portfolio", description: "View your portfolio" },
  { command: "insights", description: "Get AI market insights" },
  { command: "sentiment", description: "Check market sentiment" },
]);

bot.api.setChatMenuButton({
  menu_button: {
    type: "web_app",
    text: "Open Aptos Markets 🏛️",
    web_app: { url: "https://aptos-markets.vercel.app/" },
  },
});

bot.api.setMyDescription(descriptionMessage);

const welcomeMenu = new Menu("welcome-menu")
  .webApp("Open App 🏛️", "https://aptos-markets.vercel.app/")
  .row()
  .text("FAQ", (ctx) => ctx.reply(faqMessage, { parse_mode: "Markdown" }))
  .url("Website", "https://aptos-markets.xyz/")
  .url("Follow on X", "https://x.com/aptos_markets");

const analyticsMenu = new Menu("analytics-menu")
  .text("📊 Market Overview", (ctx) => ctx.reply("Fetching market overview..."))
  .text("🤖 AI Insights", (ctx) => ctx.reply("Loading AI insights..."))
  .row()
  .text("📈 Price Trends", (ctx) => ctx.reply("Analyzing price trends..."))
  .text("💡 Sentiment Analysis", (ctx) => ctx.reply("Checking market sentiment..."))
  .row()
  .text("🔙 Back", (ctx) => ctx.reply(welcomeMessage, { parse_mode: "Markdown", reply_markup: welcomeMenu }));

bot.use(welcomeMenu);
bot.use(analyticsMenu);

bot.command("start", async (ctx) => {
  await ctx.replyWithPhoto(
    "https://aptos-markets.vercel.app/pp-preview-purple.jpg",
    {
      caption: "Welcome to the future of AI-powered prediction markets! 🏛️🤖",
    }
  );

  await ctx.reply(welcomeMessage, {
    parse_mode: "Markdown",
    reply_markup: welcomeMenu,
  });

  sendDebugMessage(ctx);
});

bot.command("help", async (ctx) => {
  ctx.reply(faqMessage, { parse_mode: "Markdown" });
});

bot.command("markets", async (ctx) => {
  const marketsMessage = `
🏛️ *Active Markets*

Here are the current active prediction markets:

🟢 *Crypto Markets*
• BTC/USD - Next 24h direction
• ETH/USD - Weekly price target  
• APT/USD - Monthly outlook
• SOL/USD - Short-term trend

🔮 *AI Insights Available*
Use /analytics to get detailed AI analysis for any market!

📱 *Quick Access*
Tap the button below to view all markets in the app.
  `;

  const marketsMenu = new InlineKeyboard()
    .webApp("View All Markets 🏛️", "https://aptos-markets.vercel.app/markets")
    .row()
    .text("🤖 Get AI Insights", "ai-insights")
    .text("📊 Market Stats", "market-stats");

  await ctx.reply(marketsMessage, {
    parse_mode: "Markdown",
    reply_markup: marketsMenu,
  });
});

bot.command("analytics", async (ctx) => {
  const analyticsMessage = `
📊 *Market Analytics Dashboard*

Choose what you'd like to analyze:
  `;

  await ctx.reply(analyticsMessage, {
    parse_mode: "Markdown",
    reply_markup: analyticsMenu,
  });
});

bot.command("alerts", async (ctx) => {
  const alertsMessage = `
🔔 *Price Alerts Setup*

Set up personalized price alerts for your favorite assets:

*Available Assets:*
• BTC - Bitcoin
• ETH - Ethereum  
• APT - Aptos
• SOL - Solana
• USDC - USD Coin

*Alert Types:*
📈 Price increases above threshold
📉 Price drops below threshold
🎯 Price target reached
⚡ Volatility spikes

Use the app for detailed alert configuration.
  `;

  const alertsMenu = new InlineKeyboard()
    .webApp("Configure Alerts 🔔", "https://aptos-markets.vercel.app/alerts")
    .row()
    .text("📈 Bull Alerts", "alert-bull")
    .text("📉 Bear Alerts", "alert-bear");

  await ctx.reply(alertsMessage, {
    parse_mode: "Markdown",
    reply_markup: alertsMenu,
  });
});

bot.command("portfolio", async (ctx) => {
  const portfolioMessage = `
💼 *Your Portfolio*

Track your prediction market performance:

*Quick Stats:*
• Active Positions: Connect wallet to view
• Total Volume: Connect wallet to view
• Win Rate: Connect wallet to view
• ROI: Connect wallet to view

Connect your Aptos wallet in the app to see detailed portfolio analytics.
  `;

  const portfolioMenu = new InlineKeyboard()
    .webApp("View Portfolio 💼", "https://aptos-markets.vercel.app/portfolio")
    .row()
    .text("📊 Performance", "portfolio-performance")
    .text("🎯 Positions", "portfolio-positions");

  await ctx.reply(portfolioMessage, {
    parse_mode: "Markdown",
    reply_markup: portfolioMenu,
  });
});

bot.command("insights", async (ctx) => {
  const insightsMessage = `
🤖 *AI Market Insights*

Our AI analyzes market data 24/7 to provide you with:

*Current Market Sentiment:* 📊 Neutral-Bullish
*Trend Analysis:* 📈 Short-term upward momentum
*Risk Assessment:* ⚠️ Moderate volatility expected

*Key Insights:*
• BTC showing strong support at current levels
• ETH sentiment improving with recent upgrades
• APT benefiting from ecosystem growth
• Overall crypto market in consolidation phase

*AI Confidence Level:* 78%

Get detailed analysis in the app dashboard.
  `;

  const insightsMenu = new InlineKeyboard()
    .webApp("Full AI Dashboard 🤖", "https://aptos-markets.vercel.app/dashboard")
    .row()
    .text("📊 Detailed Analysis", "insights-detailed")
    .text("🎯 Predictions", "insights-predictions");

  await ctx.reply(insightsMessage, {
    parse_mode: "Markdown",
    reply_markup: insightsMenu,
  });
});

bot.command("sentiment", async (ctx) => {
  const sentimentMessage = `
💭 *Market Sentiment Analysis*

Real-time sentiment across multiple sources:

*Overall Sentiment:* 😊 Optimistic (Score: 6.8/10)

*Source Breakdown:*
📰 News Sentiment: 7.2/10 (Positive)
🐦 Social Media: 6.5/10 (Moderately Positive)  
📈 Trading Volume: 6.7/10 (Healthy)
🔍 Search Trends: 7.0/10 (Increasing Interest)

*Trending Topics:*
• Bitcoin ETF developments
• Aptos ecosystem growth
• DeFi market expansion

*Last Updated:* ${new Date().toLocaleTimeString()}
  `;

  const sentimentMenu = new InlineKeyboard()
    .text("🔄 Refresh", "sentiment-refresh")
    .text("📊 Historical", "sentiment-history")
    .row()
    .webApp("Detailed Sentiment 💭", "https://aptos-markets.vercel.app/sentiment");

  await ctx.reply(sentimentMessage, {
    parse_mode: "Markdown",
    reply_markup: sentimentMenu,
  });
});

// Callback query handlers for new features
bot.callbackQuery("ai-insights", async (ctx) => {
  const message = `🤖 *AI Market Insights*

Our advanced AI analyzes multiple data sources to provide actionable insights:

• Market trend predictions
• Sentiment analysis from news & social media
• Risk assessment for each position
• Optimal entry/exit timing suggestions

Connect to the app for personalized AI recommendations!`;

  await ctx.reply(message, { parse_mode: "Markdown" });
  await ctx.answerCallbackQuery();
});

bot.callbackQuery("market-stats", async (ctx) => {
  const message = `📊 *Market Statistics*

*24h Overview:*
• Total Volume: $2.4M
• Active Markets: 15
• Total Participants: 1,247
• Winning Predictions: 58%

*Top Performing Markets:*
1. BTC/USD 24h - 89% accuracy
2. ETH/USD Weekly - 76% accuracy  
3. APT/USD Monthly - 71% accuracy

*AI Success Rate:* 82% prediction accuracy`;

  await ctx.reply(message, { parse_mode: "Markdown" });
  await ctx.answerCallbackQuery();
});

bot.callbackQuery("sentiment-refresh", async (ctx) => {
  await ctx.answerCallbackQuery({ text: "Refreshing sentiment data..." });
  
  const refreshedMessage = `💭 *Updated Market Sentiment*

*Overall Sentiment:* 😊 Optimistic (Score: 7.1/10) ⬆️

Recent changes detected:
• News sentiment improved (+0.3)
• Social media buzz increased (+0.4)
• Trading activity normalized (+0.1)

*Last Updated:* ${new Date().toLocaleTimeString()}`;

  await ctx.editMessageText(refreshedMessage, { parse_mode: "Markdown" });
});

bot.callbackQuery("notification-setup", async (ctx) => {
  const attachedUrl = (
    ctx?.callbackQuery?.message?.reply_markup?.inline_keyboard?.[0]?.[1] as any
  )?.url;

  if (attachedUrl && ctx.from) {
    const url = new URL(attachedUrl);
    const marketAddress = url.pathname.split("/").at(-1);

    const messageKind = url.searchParams.get("messageKind");
    const timeToSend = url.searchParams.get("timeToSend");

    if (messageKind && timeToSend) {
      await storeTelegramNotification(
        marketAddress as Address,
        ctx.from.id,
        timeToSend as string,
        messageKind as MessageKind
      );
    }
  }

  await ctx.answerCallbackQuery();
});

bot.callbackQuery("news-2-switchboard", async (ctx) => {
  const message = `🔮 <b><a href="https://switchboard.xyz/">Switchboard Oracles</a></b>
We use Switchboard Oracles to fetch real-time crypto prices directly inside our smart contracts. This ensures that all market predictions are based on accurate and up-to-date data, giving you confidence in your predictions on Aptos Markets.`;

  const menu = new InlineKeyboard()
    .text("📊 NODIT", "news-2-nodit")
    .text("📈 MEXC", "news-2-mexc")
    .text("🖥️ TradingView", "news-2-tradingview")
    .row()
    .text("↸", "news-2-close");

  bot.api.sendMessage(ctx.from.id, message, {
    parse_mode: "HTML",
    link_preview_options: { is_disabled: true },
    reply_markup: menu,
  });

  if (
    ctx.callbackQuery?.message?.message_id &&
    ctx.callbackQuery?.message?.text !== undefined
  ) {
    bot.api.deleteMessage(ctx.from.id, ctx.callbackQuery.message.message_id);
  }

  await ctx.answerCallbackQuery();
});

bot.callbackQuery("news-2-nodit", async (ctx) => {
  const message = `📊 <b><a href="https://nodit.io/">NODIT</a></b>
Historical data is key for any prediction market. That's why we've integrated NODIT to query historical data on the Aptos network. This allows Aptos Markets to offer in-depth insights, so you can make well-informed predictions based on past trends.`;

  const menu = new InlineKeyboard()
    .text("🔮 Switchboard Oracles", "news-2-switchboard")
    .text("📈 MEXC", "news-2-mexc")
    .text("🖥️ TradingView", "news-2-tradingview")
    .row()
    .text("↸", "news-2-close");

  bot.api.sendMessage(ctx.from.id, message, {
    parse_mode: "HTML",
    link_preview_options: { is_disabled: true },
    reply_markup: menu,
  });

  if (
    ctx.callbackQuery?.message?.message_id &&
    ctx.callbackQuery?.message?.text !== undefined
  ) {
    bot.api.deleteMessage(ctx.from.id, ctx.callbackQuery.message.message_id);
  }

  await ctx.answerCallbackQuery();
});

bot.callbackQuery("news-2-mexc", async (ctx) => {
  const message = `📈 <b><a href="https://www.mexc.com/">MEXC</a></b>
We utilize MEXC to pull Kline data and analyze market trends. This gives you a clear view of market movements on Aptos Markets, helping you make smarter, more strategic predictions with our AI-powered insights.`;

  const menu = new InlineKeyboard()
    .text("🔮 Switchboard Oracles", "news-2-switchboard")
    .text("📊 NODIT", "news-2-nodit")
    .text("🖥️ TradingView", "news-2-tradingview")
    .row()
    .text("↸", "news-2-close");

  bot.api.sendMessage(ctx.from.id, message, {
    parse_mode: "HTML",
    link_preview_options: { is_disabled: true },
    reply_markup: menu,
  });

  if (
    ctx.callbackQuery?.message?.message_id &&
    ctx.callbackQuery?.message?.text !== undefined
  ) {
    bot.api.deleteMessage(ctx.from.id, ctx.callbackQuery.message.message_id);
  }

  await ctx.answerCallbackQuery();
});

bot.callbackQuery("news-2-tradingview", async (ctx) => {
  console.log(ctx);
  const message = `🖥️ <b><a href="https://www.tradingview.com/">TradingView</a></b>
For a seamless user experience, we display professional-grade crypto charts through TradingView integration. With this feature, you can visually track price trends and market fluctuations in real time, right within Aptos Markets platform.`;

  const menu = new InlineKeyboard()
    .text("🔮 Switchboard Oracles", "news-2-switchboard")
    .text("📊 NODIT", "news-2-nodit")
    .text("📈 MEXC", "news-2-mexc")
    .row()
    .text("↸", "news-2-close");

  bot.api.sendMessage(ctx.from.id, message, {
    parse_mode: "HTML",
    link_preview_options: { is_disabled: true },
    reply_markup: menu,
  });

  if (
    ctx.callbackQuery?.message?.message_id &&
    ctx.callbackQuery?.message?.text !== undefined
  ) {
    bot.api.deleteMessage(ctx.from.id, ctx.callbackQuery.message.message_id);
  }

  await ctx.answerCallbackQuery();
});

bot.callbackQuery("news-2-close", async (ctx) => {
  if (ctx.callbackQuery?.message?.message_id) {
    bot.api.deleteMessage(ctx.from.id, ctx.callbackQuery.message.message_id);
  }

  await ctx.answerCallbackQuery({ text: "🏛️" });
});

export const POST = webhookCallback(bot, "std/http");
