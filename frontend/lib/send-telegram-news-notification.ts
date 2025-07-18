"use server";

import { Bot, InlineKeyboard } from "grammy";
import { createClient } from "./supabase/create-client";

const token = process.env.TELEGRAM_BOT_TOKEN;

if (!token)
  throw new Error("TELEGRAM_BOT_TOKEN environment variable not found.");

const bot = new Bot(token);

export async function sendNewsNotification(
  telegramUserIds: number[],
  newsId: number
) {
  /* Use all users if no telegramUserIds are provided. */
  if (telegramUserIds.length === 0) {
    const supabase = createClient({ isAdmin: true });

    const { data: userIds, error } = await supabase
      .schema("secure_schema")
      .from("telegram_users")
      .select("id");

    if (error) {
      console.error("Error reading telegram users:", error);
      throw new Error("Error reading telegram users: " + error.message);
    }

    if (userIds.length === 0) {
      console.log("No users found");
      throw new Error("No users found");
    }

    telegramUserIds = userIds.map((user) => user.id);
  }

  let messageOne = "";
  let messageTwo = "";
  let imageUrl = "";
  let menuOne = new InlineKeyboard();
  let menuTwo = new InlineKeyboard();

  switch (newsId) {
    case 1: {
      messageOne = `📢 <b>Hey there, Aptos Markets Community!</b> 📢

It's your favorite prediction platform, <b>Aptos Markets</b> 🏛️, bringing you some <strong>BIG news!</strong> 🥳

In the next few weeks, <a href="https://t.me/aptos_markets_bot">Aptos Markets</a> is making the jump to...

<tg-spoiler><u><b>APTOS MAINNET</b></u></tg-spoiler>

Yep, you heard that right. We're taking our AI-powered prediction markets to the next level — bringing lightning-fast predictions to the Aptos ecosystem and <strong>boosting the whole scene</strong> like never before! 🌟

Our team is <i>hustling hard behind the scenes</i>, making sure everything is smooth, sustainable, and ready for the future 🔧 <b>Aptos Markets</b> is making serious progress exciting! 😉

<s>Let's build the future together!</s>
Let's revolutionize prediction markets on Aptos Mainnet! 🔥🚀`;

      imageUrl = "https://aptos-markets.vercel.app/aptos_markets_avatar.jpg";
      menuOne.url(
        "Join our Community Group 🏛️",
        `https://t.me/+82mrySWPp7g5MGM9`
      );
      break;
    }
    case 2: {
      messageOne = `🔍 <b>Behind the Scenes</b> 🔍
<i>How We Ensure Accuracy and Reliability</i>

At Aptos Markets, we're not just building a simple proof of concept—we've packed our very first version with advanced AI technology and non-trivial development to give you a solid and feature-rich platform from day one! 💪 Here's a look at the powerful services we've integrated to ensure the best prediction experience:
`;

      messageTwo = `💡 <b>Why does this matter?</b>      
By combining the power of Switchboard Oracles, NODIT, MEXC, and TradingView with our advanced AI capabilities, we ensure that Aptos Markets provides you with accurate data, real-time updates, historical insights, and intelligent market analysis—all in one platform. This level of integration strengthens our platform's reliability, giving you the best tools to make informed and confident predictions.`;

      imageUrl = "https://aptos-markets.vercel.app/tech_stack_news.png";
      menuOne
        .text("🔮 Switchboard Oracles", "news-2-switchboard")
        .text("pyth price feeds")
        .text("📊 NODIT", "news-2-nodit")
        .row()
        .text("📈 MEXC", "news-2-mexc")
        .text("🖥️ TradingView", "news-2-tradingview");

      menuTwo.url(
        "Join our Community Group 🏛️",
        `https://t.me/+82mrySWPp7g5MGM9`
      );
      break;
    }
    case 3: {
      messageOne = `🔮 <b>Knowledge Transfer Before the Weekend!</b> 🔮

Hey Aptos Markets fam, it's the team 🏛️ here, with some key insights before we roll into the weekend! Let's dive into what we've been working on 🚀

📍 <b>Current State:</b>
You can make predictions with our core AI-powered functionality. In the given time for the Aptos Code Collision Hackathon, we focused on delivering intelligent prediction capabilities with real-time insights ⚡

💡 <b>What are AI-Enhanced Features?</b>
Our AI adds smart functionality. When you make a prediction, our AI analyzes market sentiment, provides risk assessments, and offers personalized recommendations—giving you more intelligent control! 💼

🎯 <b>What's Next:</b>
We're launching on Aptos Mainnet with enhanced AI capabilities for crypto predictions and an optimized UI integrated with Telegram. After that, we'll focus on expanding to real-world events with advanced AI insights 🌍🚀

🎉 That's the update! Have a great weekend from the Aptos Markets team 🍹 Let's build the future again next week! 🏛️🔥
`;

      imageUrl = "https://aptos-markets.vercel.app/aptos_markets_avatar.jpg";

      menuOne.url(
        "Join our Community Group 🏛️",
        `https://t.me/+82mrySWPp7g5MGM9`
      );

      break;
    }
    case 4: {
      messageOne = `📢 <b>Unlocking the Power of AI-Driven Markets!</b> 🏛️🧠

Welcome to the future of predictions, where artificial intelligence meets decentralized finance! Check out our <b>Automated Crypto Market Resolution</b>—powered by Aptos Markets' own AI engine! 🧠⚡

Using <i>decentralized oracles and advanced AI algorithms</i>, we guarantee accurate and fast outcomes for all crypto markets. This also enables us to resolve every prediction automatically in a single transaction, with intelligent risk assessment and fraud detection! 🔄

And if a technical glitch occurs, you can step in and resolve it—thus we keep it decentralized and ensure no single point of failure. 💪✨

Our mission is simple: to make crypto predictions intelligent, reliable, and profitable. So let the AI engine work its magic, and get ready to <b>experience the future</b> with Aptos Markets! 🏛️💡
`;

      imageUrl = "https://aptos-markets.vercel.app/ai_brain.png";

      menuOne.url(
        "Join our Community Group 🏛️",
        `https://t.me/+82mrySWPp7g5MGM9`
      );

      break;
    }
    case 5: {
      messageOne = `🎉 <b>Big News from Aptos Markets!</b> 🎉

We're beyond excited to announce that Aptos Markets is a FINALIST in the <a href="https://aptosfoundation.org/events/code-collision">Aptos Code Collision Hackathon</a>! 🚀 Countless hours of coding, late-night AI algorithm development, and teamwork have brought us to this point, and we're ready to show the world what we've built! 🌐💡

A huge shoutout to <a href="https://dorahacks.io/hackathon/code-collision">DoraHacks</a> and all the mentors who made this possible. Your support has been incredible, and we're pumped to be a part of this journey with you all! 🙏

📅 Mark your calendars! This Friday, <b>Nov 1 at 2:30 PM UTC</b>, we'll be showcasing Aptos Markets LIVE at the Hackathon Demo Day. Catch us and 15 other top teams on YouTube here: <a href="https://youtube.com/live/QbnTo19-i9o">Watch Live</a> 🎥✨

Let's bring it home, team! 🏆 This is just the beginning for Aptos Markets, and we can't wait to share what's next. Stay tuned! 🏛️🔥
`;

      imageUrl = "https://aptos-markets.vercel.app/track_finalists.jpg";

      menuOne.url(
        "Join our Community Group 🏛️",
        `https://t.me/+82mrySWPp7g5MGM9`
      );

      break;
    }
    case 7: {
      messageOne = `🏛️ <b>AMPP Update!</b> 🏛️  
<tg-spoiler><i>Aptos Markets Platform Progress Update</i></tg-spoiler>

Hey everyone! Here's a quick look at what's been happening as we gear up for Aptos Mainnet Launch! 🚀

1. <b>AI Integration Enhancement</b> 🤖 – Big thanks to our developer community and feedback groups for helping us refine our AI-powered features. Advanced sentiment analysis and predictive analytics are now live!

2. <b>Smart Contract Optimization</b> 🔒 – We're optimizing smart contracts for smoother performance and enhanced AI integration. Honestly, <i>Move</i> has stolen our hearts 💜 It lets us build complex AI-enhanced features with incredible security. <s>Object</s> Intelligent ownership for the win! 🏆

3. <b>Ecosystem Partnerships</b> 🌐 – The Aptos ecosystem is truly amazing! So many inspiring projects and AI innovations keep us motivated to push forward.

That's all for now! The Aptos Markets team signing off 🍹 Keep testing and sharing feedback. Next up: <tg-spoiler>AI-POWERED MAINNET LAUNCH</tg-spoiler>! 🏛️🔥
`;

      imageUrl = "https://aptos-markets.vercel.app/ai_analytics.png";

      menuOne.url("Join our CCG 🏛️", `https://t.me/+82mrySWPp7g5MGM9`);

      break;
    }
    case 8: {
      messageOne = `🇺🇸🏛️ <b>AI for President!</b> 🏛️🇺🇸

Jokes aside, the 2024 USA election showcased the power of prediction markets. Polymarket called the election in favor of <b>Donald Trump</b> before any media outlet, showing far greater accuracy than pollsters' 50:50 guesses.

💸 <i>Billions were traded</i> 💸

Unlike traditional media that thrives on suspense, AI-powered prediction markets prioritize <b>accuracy and intelligence</b>, making the call when data and algorithms show clear signals.

That's why we believe in the power and importance of <b>AI-enhanced prediction markets</b>. 🏛️✨
`;

      imageUrl = "https://aptos-markets.vercel.app/Character_MAGA2.jpg";

      menuOne.url(
        "Join our Community Group 🏛️",
        `https://t.me/aptos_markets`
      );

      break;
    }
    default: {
      throw new Error("Invalid newsId: " + newsId);
    }
  }

  telegramUserIds.forEach((telegramUserId) => {
    bot.api
      .sendPhoto(telegramUserId, imageUrl, {
        caption: messageOne,
        parse_mode: "HTML",
        reply_markup: menuOne,
      })
      .then(() => {
        if (messageTwo) {
          bot.api.sendMessage(telegramUserId, messageTwo, {
            parse_mode: "HTML",
            reply_markup: menuTwo,
            link_preview_options: { is_disabled: true },
          });
        }
      });
  });
}
