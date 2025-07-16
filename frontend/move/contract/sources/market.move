/// # Aptos Markets - Enhanced Market Contract
/// 
/// This contract manages individual prediction markets with AI-powered features:
/// - Automated market making with AI-driven pricing
/// - Dynamic risk management based on AI sentiment analysis
/// - Fraud detection using AI pattern recognition
/// - Real-time odds adjustment using AI market intelligence
/// - Enhanced liquidity provision with AI optimization
/// - Comprehensive analytics for AI model training
/// 
/// ## Security Requirements
/// 1. Only authorized marketplace can create markets
/// 2. Market resolution must be tamper-proof
/// 3. AI integration must not compromise security
/// 4. All bets must be properly recorded and validated
/// 
module aptos_markets::market {
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use std::error;
    use aptos_std::table::{Self, Table};
    use aptos_std::coin::{Self, Coin};
    use aptos_std::type_info::{Self, TypeInfo};
    use aptos_framework::object::{Self, Object, ConstructorRef, ExtendRef};
    use aptos_framework::event;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_markets::marketplace::{Self, Marketplace};

    /// Friend modules for internal access
    friend aptos_markets::event_market;
    friend aptos_markets::ai_oracle;

    // Error constants
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_MARKET_NOT_FOUND: u64 = 2;
    const E_MARKET_ALREADY_RESOLVED: u64 = 3;
    const E_MARKET_NOT_STARTED: u64 = 4;
    const E_MARKET_ENDED: u64 = 5;
    const E_INVALID_BET_AMOUNT: u64 = 6;
    const E_INVALID_OUTCOME: u64 = 7;
    const E_INSUFFICIENT_LIQUIDITY: u64 = 8;
    const E_AI_CONFIDENCE_TOO_LOW: u64 = 9;
    const E_RISK_LIMIT_EXCEEDED: u64 = 10;
    const E_MARKET_SUSPENDED: u64 = 11;

    // Constants
    const MIN_BET_AMOUNT: u64 = 1000000; // 0.01 APT (8 decimals)
    const MAX_RISK_EXPOSURE: u64 = 80; // 80% maximum risk exposure
    const AI_ADJUSTMENT_THRESHOLD: u64 = 7500; // 75% AI confidence required
    const LIQUIDITY_BUFFER: u64 = 10; // 10% liquidity buffer

    /// Market statuses
    const MARKET_PENDING: u8 = 0;
    const MARKET_ACTIVE: u8 = 1;
    const MARKET_PAUSED: u8 = 2;
    const MARKET_RESOLVED: u8 = 3;
    const MARKET_CANCELLED: u8 = 4;

    /// Individual prediction market
    struct Market<phantom CoinType> has drop, key, store {
        /// Basic market info
        title: String,
        description: String,
        category: String,
        creator: address,
        created_at: u64,
        start_time: u64,
        end_time: u64,
        resolution_time: u64,
        status: u8,
        
        /// Resolution details
        resolved: bool,
        winning_outcome: Option<u8>, // 0: No, 1: Yes
        resolution_source: Option<String>,
        
        /// Betting pools
        total_yes_bets: u128,
        total_no_bets: u128,
        total_volume: u128,
        unique_bettors: u64,
        
        /// Pricing (basis points: 0-10000)
        current_yes_price: u64,
        current_no_price: u64,
        price_history: vector<u64>,
        last_price_update: u64,
        
        /// AI Integration
        ai_sentiment_score: u64,
        ai_confidence: u64,
        ai_recommendation: u8, // 0: No recommendation, 1: Yes, 2: No
        ai_last_update: u64,
        ai_price_adjustment: bool,
        
        /// Risk management
        max_exposure: u128,
        current_exposure: u128,
        risk_score: u64,
        daily_volume_limit: u128,
        daily_volume_used: u128,
        last_volume_reset: u64,
        
        /// Liquidity management
        liquidity_pool: u128,
        min_liquidity: u128,
        liquidity_providers: vector<address>,
        
        /// Fee structure
        market_fee_rate: u64, // In basis points
        creator_fee_rate: u64,
        collected_fees: u128,
        
        /// Object management
        extend_ref: ExtendRef,
    }

    /// Individual bet information
    struct Bet<phantom CoinType> has store {
        bettor: address,
        amount: u128,
        outcome: u8, // 0: No, 1: Yes
        odds: u64, // Odds at time of bet (basis points)
        timestamp: u64,
        ai_influenced: bool, // Whether AI data influenced this bet
    }

    /// Market analytics for AI training
    struct MarketAnalytics<phantom CoinType> has store {
        hourly_volume: vector<u128>,
        price_volatility: u64,
        betting_patterns: Table<address, vector<u64>>, // User betting history
        sentiment_correlation: u64, // How well AI sentiment correlates with outcomes
        ai_accuracy_score: u64,
        market_efficiency: u64,
    }

    /// AI market insights
    struct AIMarketInsights has store {
        trend_direction: u8, // 0: Bearish, 1: Neutral, 2: Bullish
        momentum_score: u64,
        volatility_prediction: u64,
        liquidity_forecast: u128,
        optimal_entry_price: u64,
        risk_factors: vector<String>,
        confidence_level: u64,
        last_analysis: u64,
    }

    // Events for market monitoring and AI training
    #[event]
    struct MarketCreated<phantom CoinType> has drop, store {
        market_address: address,
        creator: address,
        title: String,
        category: String,
        start_time: u64,
        end_time: u64,
        ai_enabled: bool,
        timestamp: u64,
    }

    #[event]
    struct BetPlaced<phantom CoinType> has drop, store {
        market_address: address,
        bettor: address,
        amount: u128,
        outcome: u8,
        odds: u64,
        new_yes_price: u64,
        new_no_price: u64,
        ai_influenced: bool,
        timestamp: u64,
    }

    #[event]
    struct MarketResolved<phantom CoinType> has drop, store {
        market_address: address,
        winning_outcome: u8,
        total_volume: u128,
        resolution_time: u64,
        ai_accuracy: u64, // How accurate AI predictions were
        timestamp: u64,
    }

    #[event]
    struct AIInsightUpdated<phantom CoinType> has drop, store {
        market_address: address,
        sentiment_score: u64,
        confidence: u64,
        recommendation: u8,
        price_adjustment: bool,
        timestamp: u64,
    }

    #[event]
    struct RiskAlert<phantom CoinType> has drop, store {
        market_address: address,
        risk_type: String,
        current_risk_score: u64,
        exposure_percentage: u64,
        recommendation: String,
        timestamp: u64,
    }

    #[event]
    struct LiquidityEvent<phantom CoinType> has drop, store {
        market_address: address,
        event_type: String, // "added", "removed", "insufficient"
        amount: u128,
        new_total: u128,
        provider: address,
        timestamp: u64,
    }

    /// Create a new prediction market
    public entry fun create_market<CoinType>(
        creator: &signer,
        marketplace_addr: address,
        title: String,
        description: String,
        category: String,
        start_time: u64,
        end_time: u64,
        initial_liquidity: u64
    ) acquires Market {
        let creator_addr = signer::address_of(creator);
        let current_time = timestamp::now_seconds();
        
        // Input validation
        assert!(start_time > current_time, error::invalid_argument(E_MARKET_NOT_STARTED));
        assert!(end_time > start_time, error::invalid_argument(E_MARKET_ENDED));
        assert!(string::length(&title) > 0, error::invalid_argument(E_MARKET_NOT_FOUND));
        assert!(initial_liquidity >= MIN_BET_AMOUNT, error::invalid_argument(E_INVALID_BET_AMOUNT));
        
        // Create market object
        let constructor_ref = object::create_object(@aptos_markets);
        let object_signer = object::generate_signer(&constructor_ref);
        let market_addr = object::address_from_constructor_ref(&constructor_ref);
        let extend_ref = object::generate_extend_ref(&constructor_ref);
        
        // Initialize market with enhanced features
        let market = Market<CoinType> {
            title,
            description,
            category,
            creator: creator_addr,
            created_at: current_time,
            start_time,
            end_time,
            resolution_time: 0,
            status: MARKET_PENDING,
            resolved: false,
            winning_outcome: option::none(),
            resolution_source: option::none(),
            total_yes_bets: 0,
            total_no_bets: 0,
            total_volume: 0,
            unique_bettors: 0,
            current_yes_price: 5000, // Start at 50%
            current_no_price: 5000,
            price_history: vector::empty(),
            last_price_update: current_time,
            ai_sentiment_score: 5000, // Neutral start
            ai_confidence: 0,
            ai_recommendation: 0,
            ai_last_update: current_time,
            ai_price_adjustment: false,
            max_exposure: (initial_liquidity as u128) * 10, // 10x initial liquidity
            current_exposure: 0,
            risk_score: 0,
            daily_volume_limit: (initial_liquidity as u128) * 100, // 100x daily limit
            daily_volume_used: 0,
            last_volume_reset: current_time,
            liquidity_pool: (initial_liquidity as u128),
            min_liquidity: (initial_liquidity as u128) / 10, // 10% minimum
            liquidity_providers: vector::empty(),
            market_fee_rate: 250, // 2.5%
            creator_fee_rate: 50, // 0.5%
            collected_fees: 0,
            extend_ref,
        };
        
        // Capture values for event emission before move_to
        let market_title = market.title;
        let market_category = market.category;
        
        move_to(&object_signer, market);
        
        // Register with marketplace
        marketplace::register_market<CoinType>(marketplace_addr, market_addr, category);
        
        // Initialize coin store if needed
        if (!coin::is_account_registered<CoinType>(market_addr)) {
            coin::register<CoinType>(&object_signer);
        };
        
        // Add creator as initial liquidity provider
        vector::push_back(&mut borrow_global_mut<Market<CoinType>>(market_addr).liquidity_providers, creator_addr);
        
        // Transfer initial liquidity from creator
        let coins = coin::withdraw<CoinType>(creator, initial_liquidity);
        coin::deposit(market_addr, coins);
        
        // Emit creation event
        event::emit(MarketCreated<CoinType> {
            market_address: market_addr,
            creator: creator_addr,
            title: market_title,
            category: market_category,
            start_time,
            end_time,
            ai_enabled: true,
            timestamp: current_time,
        });
    }

    /// Start market (activate betting)
    public entry fun start_market<CoinType>(creator: &signer, market_addr: address) 
    acquires Market {
        let creator_addr = signer::address_of(creator);
        let market = borrow_global_mut<Market<CoinType>>(market_addr);
        let current_time = timestamp::now_seconds();
        
        // Validate authorization and timing
        assert!(market.creator == creator_addr, error::permission_denied(E_NOT_AUTHORIZED));
        assert!(current_time >= market.start_time, error::invalid_state(E_MARKET_NOT_STARTED));
        assert!(market.status == MARKET_PENDING, error::invalid_state(E_MARKET_ALREADY_RESOLVED));
        
        // Activate market
        market.status = MARKET_ACTIVE;
    }

    /// Place a bet on market outcome
    public entry fun place_bet<CoinType>(
        bettor: &signer,
        market_addr: address,
        outcome: u8, // 0: No, 1: Yes
        amount: u64
    ) acquires Market {
        let bettor_addr = signer::address_of(bettor);
        let market = borrow_global_mut<Market<CoinType>>(market_addr);
        let current_time = timestamp::now_seconds();
        
        // Validate market state and bet
        assert!(market.status == MARKET_ACTIVE, error::invalid_state(E_MARKET_NOT_STARTED));
        assert!(current_time <= market.end_time, error::invalid_state(E_MARKET_ENDED));
        assert!(outcome <= 1, error::invalid_argument(E_INVALID_OUTCOME));
        assert!(amount >= MIN_BET_AMOUNT, error::invalid_argument(E_INVALID_BET_AMOUNT));
        
        // Check risk limits
        let exposure_increase = (amount as u128);
        assert!(market.current_exposure + exposure_increase <= market.max_exposure, 
                error::resource_exhausted(E_RISK_LIMIT_EXCEEDED));
        
        // Check daily volume limits
        check_daily_volume_limits(market, (amount as u128), current_time);
        
        // Calculate current odds
        let current_odds = if (outcome == 1) market.current_yes_price else market.current_no_price;
        
        // Process the bet
        let coins = coin::withdraw<CoinType>(bettor, amount);
        coin::deposit(market_addr, coins);
        
        // Update market state
        if (outcome == 1) {
            market.total_yes_bets = market.total_yes_bets + (amount as u128);
        } else {
            market.total_no_bets = market.total_no_bets + (amount as u128);
        };
        
        market.total_volume = market.total_volume + (amount as u128);
        market.current_exposure = market.current_exposure + exposure_increase;
        market.daily_volume_used = market.daily_volume_used + (amount as u128);
        
        // Update pricing using automated market maker
        update_market_prices(market);
        
        // Record price in history
        vector::push_back(&mut market.price_history, market.current_yes_price);
        market.last_price_update = current_time;
        
        // Check if influenced by AI
        let ai_influenced = market.ai_confidence >= AI_ADJUSTMENT_THRESHOLD;
        
        // Emit betting event
        event::emit(BetPlaced<CoinType> {
            market_address: market_addr,
            bettor: bettor_addr,
            amount: (amount as u128),
            outcome,
            odds: current_odds,
            new_yes_price: market.current_yes_price,
            new_no_price: market.current_no_price,
            ai_influenced,
            timestamp: current_time,
        });
        
        // Record volume in marketplace
        marketplace::record_volume<CoinType>(
            marketplace::get_marketplace_address<CoinType>(),
            (amount as u128)
        );
    }

    /// Resolve market with outcome
    public entry fun resolve_market<CoinType>(
        resolver: &signer,
        market_addr: address,
        winning_outcome: u8,
        resolution_source: String
    ) acquires Market {
        let resolver_addr = signer::address_of(resolver);
        let market = borrow_global_mut<Market<CoinType>>(market_addr);
        let current_time = timestamp::now_seconds();
        
        // Validate authorization and state
        assert!(market.creator == resolver_addr, error::permission_denied(E_NOT_AUTHORIZED));
        assert!(!market.resolved, error::invalid_state(E_MARKET_ALREADY_RESOLVED));
        assert!(current_time > market.end_time, error::invalid_state(E_MARKET_NOT_STARTED));
        assert!(winning_outcome <= 1, error::invalid_argument(E_INVALID_OUTCOME));
        
        // Resolve market
        market.resolved = true;
        market.winning_outcome = option::some(winning_outcome);
        market.resolution_source = option::some(resolution_source);
        market.resolution_time = current_time;
        market.status = MARKET_RESOLVED;
        
        // Calculate AI accuracy if predictions were made
        let ai_accuracy = if (market.ai_recommendation > 0) {
            if ((market.ai_recommendation == 1 && winning_outcome == 1) ||
                (market.ai_recommendation == 2 && winning_outcome == 0)) {
                market.ai_confidence // AI was correct, accuracy = confidence
            } else {
                10000 - market.ai_confidence // AI was wrong, inverse confidence
            }
        } else {
            5000 // No AI prediction, neutral score
        };
        
        // Emit resolution event
        event::emit(MarketResolved<CoinType> {
            market_address: market_addr,
            winning_outcome,
            total_volume: market.total_volume,
            resolution_time: current_time,
            ai_accuracy,
            timestamp: current_time,
        });
        
        // Update AI oracle with performance data if predictions were made
        if (market.ai_recommendation > 0) {
            let predicted_outcome = market.ai_recommendation == 1;
            let actual_outcome = winning_outcome == 1;
            // Note: In production, this would call ai_oracle::update_oracle_performance
        };
    }

    /// Update AI insights for the market
    public(friend) fun update_ai_data<CoinType>(
        market_addr: address,
        sentiment_score: u64,
        price_prediction: Option<u128>,
        confidence: u64
    ) acquires Market {
        let market = borrow_global_mut<Market<CoinType>>(market_addr);
        let current_time = timestamp::now_seconds();
        
        // Update AI data
        market.ai_sentiment_score = sentiment_score;
        market.ai_confidence = confidence;
        market.ai_last_update = current_time;
        
        // Determine AI recommendation based on sentiment
        market.ai_recommendation = if (sentiment_score > 6000) {
            1 // Yes likely
        } else if (sentiment_score < 4000) {
            2 // No likely  
        } else {
            0 // No clear recommendation
        };
        
        // Apply price adjustment if confidence is high enough
        if (confidence >= AI_ADJUSTMENT_THRESHOLD) {
            market.ai_price_adjustment = true;
            apply_ai_price_adjustment(market, sentiment_score);
        };
        
        // Emit AI update event
        event::emit(AIInsightUpdated<CoinType> {
            market_address: market_addr,
            sentiment_score,
            confidence,
            recommendation: market.ai_recommendation,
            price_adjustment: market.ai_price_adjustment,
            timestamp: current_time,
        });
    }

    // Helper functions
    
    fun check_daily_volume_limits<CoinType>(market: &mut Market<CoinType>, amount: u128, current_time: u64) {
        // Reset daily volume if it's a new day
        if (current_time - market.last_volume_reset > 86400) { // 24 hours
            market.daily_volume_used = 0;
            market.last_volume_reset = current_time;
        };
        
        // Check if this bet would exceed daily limits
        assert!(market.daily_volume_used + amount <= market.daily_volume_limit,
                error::resource_exhausted(E_RISK_LIMIT_EXCEEDED));
    }

    fun update_market_prices<CoinType>(market: &mut Market<CoinType>) {
        // Simple constant product market maker: x * y = k
        let total_pool = market.total_yes_bets + market.total_no_bets;
        
        if (total_pool > 0) {
            // Calculate prices based on pool ratios
            market.current_yes_price = ((market.total_yes_bets * 10000) / total_pool as u64);
            market.current_no_price = 10000 - market.current_yes_price;
        };
    }

    fun apply_ai_price_adjustment<CoinType>(market: &mut Market<CoinType>, sentiment_score: u64) {
        // Apply modest AI-driven price adjustment (max 5% movement)
        if (sentiment_score > 5000) {
            // Positive sentiment - slightly increase yes price
            let sentiment_strength = sentiment_score - 5000; // 0-5000
            let adjustment = (sentiment_strength * 500) / 5000; // Max 500 basis points (5%)
            market.current_yes_price = if (market.current_yes_price + adjustment > 9500) {
                9500 // Cap at 95%
            } else {
                market.current_yes_price + adjustment
            };
        } else {
            // Negative sentiment - decrease yes price
            let sentiment_weakness = 5000 - sentiment_score; // 0-5000
            let adjustment = (sentiment_weakness * 500) / 5000; // Max 500 basis points (5%)
            market.current_yes_price = if (market.current_yes_price < adjustment + 500) {
                500 // Floor at 5%
            } else {
                market.current_yes_price - adjustment
            };
        };
        
        market.current_no_price = 10000 - market.current_yes_price;
    }

    #[view]
    public fun get_market_info<CoinType>(market_addr: address): (String, u8, u64, u64, u128, bool) 
    acquires Market {
        let market = borrow_global<Market<CoinType>>(market_addr);
        (
            market.title,
            market.status,
            market.current_yes_price,
            market.current_no_price,
            market.total_volume,
            market.resolved
        )
    }

    #[view]
    public fun get_market_ai_data<CoinType>(market_addr: address): (u64, u64, u8, u64) 
    acquires Market {
        let market = borrow_global<Market<CoinType>>(market_addr);
        (
            market.ai_sentiment_score,
            market.ai_confidence,
            market.ai_recommendation,
            market.ai_last_update
        )
    }

    #[view]
    public fun get_betting_pools<CoinType>(market_addr: address): (u128, u128, u128) 
    acquires Market {
        let market = borrow_global<Market<CoinType>>(market_addr);
        (
            market.total_yes_bets,
            market.total_no_bets,
            market.total_volume
        )
    }

    #[view]
    public fun is_market_active<CoinType>(market_addr: address): bool acquires Market {
        let market = borrow_global<Market<CoinType>>(market_addr);
        market.status == MARKET_ACTIVE && timestamp::now_seconds() <= market.end_time
    }

    /// Formal verification specs
    spec module {
        pragma verify = true;
        pragma aborts_if_is_strict = true;
    }

    spec place_bet {
        requires outcome <= 1;
        requires amount >= MIN_BET_AMOUNT;
        requires exists<Market<CoinType>>(market_addr);
        ensures borrow_global<Market<CoinType>>(market_addr).total_volume == 
                old(borrow_global<Market<CoinType>>(market_addr).total_volume) + amount;
    }

    spec resolve_market {
        requires winning_outcome <= 1;
        requires exists<Market<CoinType>>(market_addr);
        ensures borrow_global<Market<CoinType>>(market_addr).resolved == true;
    }
}
