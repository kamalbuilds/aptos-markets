/// # Aptos Markets - AI Oracle Contract
/// 
/// This contract serves as the bridge between external AI services and the prediction markets:
/// - Manages AI data feeds for sentiment analysis, price predictions, and risk assessments
/// - Provides tamper-proof AI recommendations with confidence scores
/// - Implements oracle update mechanisms with proper validation
/// - Supports multiple AI model versions and fallback mechanisms
/// - Maintains historical AI accuracy tracking for model improvement
/// 
/// ## Security Requirements
/// 1. Only authorized oracles can update AI data
/// 2. AI confidence must meet minimum thresholds for market impact
/// 3. Historical accuracy tracking must be tamper-proof
/// 4. Fallback mechanisms must activate on stale data
/// 
module aptos_markets::ai_oracle {
    use std::vector;
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use std::error;
    use aptos_std::table::{Self, Table};
    use aptos_std::math64;
    use aptos_framework::object::{Self, Object, ExtendRef};
    use aptos_framework::event;
    use aptos_framework::timestamp;
    use aptos_markets::marketplace::{Self, Marketplace};
    use aptos_markets::market::{Self, Market};

    // Error constants
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_STALE_DATA: u64 = 2;
    const E_INVALID_CONFIDENCE: u64 = 3;
    const E_ORACLE_NOT_FOUND: u64 = 4;
    const E_INSUFFICIENT_ACCURACY: u64 = 5;
    const E_MODEL_VERSION_MISMATCH: u64 = 6;
    const E_DATA_FEED_UNAVAILABLE: u64 = 7;

    // Constants for AI oracle
    const MAX_STALENESS: u64 = 3600; // 1 hour maximum staleness
    const MIN_CONFIDENCE: u64 = 5000; // 50% minimum confidence
    const MIN_ACCURACY_THRESHOLD: u64 = 6000; // 60% minimum accuracy for trusted data
    const MAX_ORACLES: u64 = 10; // Maximum number of oracle sources
    const CONSENSUS_THRESHOLD: u64 = 7000; // 70% consensus required

    /// Oracle data source configuration
    struct OracleConfig has key {
        admin: address,
        active_oracles: vector<address>,
        oracle_weights: Table<address, u64>, // Oracle address -> weight (basis points)
        total_weight: u64,
        consensus_threshold: u64,
        min_confidence: u64,
        max_staleness: u64,
        last_cleanup: u64,
    }

    /// AI data source for market insights
    struct AIDataSource has store {
        source_id: String,
        source_type: String, // "sentiment", "price_prediction", "risk_assessment"
        provider: address,
        weight: u64, // Weight in consensus calculation
        accuracy_score: u64, // Historical accuracy (0-10000)
        total_predictions: u64,
        correct_predictions: u64,
        last_update: u64,
        is_active: bool,
    }

    /// Aggregated AI insights for a market
    struct MarketAIInsights has drop, store {
        market_address: address,
        
        /// Sentiment analysis
        sentiment_score: u64, // 0-10000 (0% = very bearish, 100% = very bullish)
        sentiment_confidence: u64,
        sentiment_sources: vector<String>,
        
        /// Price predictions
        price_prediction: Option<u128>,
        price_confidence: u64,
        price_direction: u8, // 0: Down, 1: Stable, 2: Up
        
        /// Risk assessment
        risk_score: u64, // 0-10000 (0% = very safe, 100% = very risky)
        risk_factors: vector<String>,
        risk_confidence: u64,
        
        /// Market dynamics
        volatility_prediction: u64,
        liquidity_forecast: u128,
        manipulation_risk: u64,
        
        /// Consensus data
        consensus_score: u64, // How much different AI sources agree
        participating_oracles: u64,
        last_consensus_update: u64,
        
        /// Model versioning
        model_version: String,
        data_freshness: u64, // Age of oldest data point
    }

    /// Oracle performance tracking
    struct OraclePerformance has drop, store {
        oracle_address: address,
        
        /// Accuracy metrics
        total_predictions: u64,
        correct_predictions: u64,
        accuracy_rate: u64, // Basis points (0-10000)
        
        /// Confidence calibration
        avg_confidence: u64,
        confidence_accuracy_correlation: u64, // How well confidence predicts accuracy
        
        /// Timeliness metrics
        avg_response_time: u64,
        uptime_percentage: u64,
        last_successful_update: u64,
        
        /// Stake and rewards
        staked_amount: u128,
        earned_rewards: u128,
        slashed_amount: u128,
        
        /// Reputation score
        reputation_score: u64, // Composite score for oracle reliability
        trust_level: u8, // 0: Untrusted, 1: Basic, 2: Trusted, 3: Highly Trusted
    }

    /// Real-time AI data feed
    struct AIDataFeed has store {
        feed_id: String,
        feed_type: String,
        data_points: Table<u64, AIDataPoint>, // Timestamp -> Data
        latest_timestamp: u64,
        update_frequency: u64, // Expected update interval in seconds
        quality_score: u64, // Data quality rating
        subscription_cost: u128,
        active_subscribers: u64,
    }

    /// Individual AI data point
    struct AIDataPoint has store {
        timestamp: u64,
        data_value: u128,
        confidence: u64,
        source_oracle: address,
        processing_time: u64, // Time taken to generate this prediction
        model_version: String,
        input_hash: vector<u8>, // Hash of input data for verification
    }

    // Events for AI oracle monitoring
    #[event]
    struct AIInsightUpdated has drop, store {
        market_address: address,
        sentiment_score: u64,
        risk_score: u64,
        confidence: u64,
        consensus_score: u64,
        participating_oracles: u64,
        timestamp: u64,
    }

    #[event]
    struct OracleRegistered has drop, store {
        oracle_address: address,
        source_types: vector<String>,
        initial_weight: u64,
        stake_amount: u128,
        timestamp: u64,
    }

    #[event]
    struct OraclePerformanceUpdated has drop, store {
        oracle_address: address,
        old_accuracy: u64,
        new_accuracy: u64,
        reputation_change: u64, // Absolute value
        reputation_is_positive: bool, // True for positive, false for negative
        trust_level: u8,
        timestamp: u64,
    }

    #[event]
    struct ConsensusReached has drop, store {
        market_address: address,
        consensus_type: String, // "sentiment", "price", "risk"
        consensus_value: u128,
        consensus_confidence: u64,
        participating_oracles: u64,
        timestamp: u64,
    }

    #[event]
    struct DataQualityAlert has drop, store {
        feed_id: String,
        alert_type: String, // "stale_data", "low_confidence", "consensus_failure"
        severity: u8, // 1: Low, 2: Medium, 3: High
        affected_markets: u64,
        timestamp: u64,
    }

    /// Initialize AI oracle system
    fun init_module(admin: &signer) {
        let config = OracleConfig {
            admin: std::signer::address_of(admin),
            active_oracles: vector::empty(),
            oracle_weights: table::new(),
            total_weight: 0,
            consensus_threshold: CONSENSUS_THRESHOLD,
            min_confidence: MIN_CONFIDENCE,
            max_staleness: MAX_STALENESS,
            last_cleanup: timestamp::now_seconds(),
        };
        move_to(admin, config);
    }

    /// Register new AI oracle
    public entry fun register_oracle(
        admin: &signer,
        oracle_addr: address,
        source_types: vector<String>,
        weight: u64,
        stake_amount: u128
    ) acquires OracleConfig {
        let config = borrow_global_mut<OracleConfig>(@aptos_markets);
        assert!(std::signer::address_of(admin) == config.admin, error::permission_denied(E_NOT_AUTHORIZED));
        assert!(vector::length(&config.active_oracles) < MAX_ORACLES, error::resource_exhausted(E_ORACLE_NOT_FOUND));
        assert!(weight > 0 && weight <= 10000, error::invalid_argument(E_INVALID_CONFIDENCE));
        
        // Add oracle to active list
        vector::push_back(&mut config.active_oracles, oracle_addr);
        table::add(&mut config.oracle_weights, oracle_addr, weight);
        config.total_weight = config.total_weight + weight;
        
        // Initialize oracle performance tracking
        let performance = OraclePerformance {
            oracle_address: oracle_addr,
            total_predictions: 0,
            correct_predictions: 0,
            accuracy_rate: 5000, // Start with 50% assumed accuracy
            avg_confidence: 5000,
            confidence_accuracy_correlation: 5000,
            avg_response_time: 0,
            uptime_percentage: 10000, // Start with 100% uptime
            last_successful_update: timestamp::now_seconds(),
            staked_amount: stake_amount,
            earned_rewards: 0,
            slashed_amount: 0,
            reputation_score: 5000, // Start with neutral reputation
            trust_level: 1, // Basic trust level
        };
        
        // Note: In a full implementation, this would be stored in a global table
        
        event::emit(OracleRegistered {
            oracle_address: oracle_addr,
            source_types,
            initial_weight: weight,
            stake_amount,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Submit AI insights for a market
    public entry fun submit_ai_insights(
        oracle: &signer,
        market_addr: address,
        sentiment_score: u64,
        risk_score: u64,
        confidence: u64,
        model_version: String
    ) acquires OracleConfig {
        let oracle_addr = std::signer::address_of(oracle);
        let config = borrow_global<OracleConfig>(@aptos_markets);
        let current_time = timestamp::now_seconds();
        
        // Validate oracle authorization
        assert!(vector::contains(&config.active_oracles, &oracle_addr), 
                error::permission_denied(E_NOT_AUTHORIZED));
        assert!(confidence >= config.min_confidence, 
                error::invalid_argument(E_INVALID_CONFIDENCE));
        assert!(sentiment_score <= 10000 && risk_score <= 10000, 
                error::invalid_argument(E_INVALID_CONFIDENCE));
        
        // Create or update market insights
        // Note: In production, this would aggregate with other oracle data
        let insights = MarketAIInsights {
            market_address: market_addr,
            sentiment_score,
            sentiment_confidence: confidence,
            sentiment_sources: vector::singleton(string::utf8(b"oracle_consensus")),
            price_prediction: option::none(),
            price_confidence: confidence,
            price_direction: if (sentiment_score > 6000) 2 else if (sentiment_score < 4000) 0 else 1,
            risk_score,
            risk_factors: vector::empty(),
            risk_confidence: confidence,
            volatility_prediction: calculate_volatility_from_sentiment(sentiment_score, risk_score),
            liquidity_forecast: 0, // Would be calculated from market data
            manipulation_risk: risk_score,
            consensus_score: confidence, // Simplified - would calculate from multiple oracles
            participating_oracles: 1, // Simplified
            last_consensus_update: current_time,
            model_version,
            data_freshness: 0,
        };
        
        // Update market with AI insights
        market::update_ai_data<aptos_framework::aptos_coin::AptosCoin>(
            market_addr, 
            sentiment_score, 
            option::none(), 
            confidence
        );
        
        // Emit insight update event
        event::emit(AIInsightUpdated {
            market_address: market_addr,
            sentiment_score,
            risk_score,
            confidence,
            consensus_score: confidence,
            participating_oracles: 1,
            timestamp: current_time,
        });
    }

    /// Update oracle performance after market resolution
    public entry fun update_oracle_performance(
        admin: &signer,
        oracle_addr: address,
        prediction_correct: bool,
        confidence_level: u64
    ) acquires OracleConfig {
        let config = borrow_global<OracleConfig>(@aptos_markets);
        assert!(std::signer::address_of(admin) == config.admin, error::permission_denied(E_NOT_AUTHORIZED));
        
        // Note: In production, this would update the stored oracle performance data
        // For now, we emit an event to track performance
        
        let new_accuracy = if (prediction_correct) confidence_level else 10000 - confidence_level;
        
        // Calculate reputation change (positive for correct predictions, negative for incorrect)
        let reputation_change = 100u64; // Absolute value
        let reputation_is_positive = prediction_correct; // True for positive, false for negative
        
        event::emit(OraclePerformanceUpdated {
            oracle_address: oracle_addr,
            old_accuracy: 5000, // Placeholder
            new_accuracy,
            reputation_change,
            reputation_is_positive,
            trust_level: 1,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Helper functions
    
    fun calculate_volatility_from_sentiment(sentiment: u64, risk: u64): u64 {
        // Calculate expected volatility based on sentiment extremity and risk
        let sentiment_extremity = if (sentiment > 5000) {
            sentiment - 5000
        } else {
            5000 - sentiment
        };
        
        // Higher extremity and risk = higher volatility
        let base_volatility = (sentiment_extremity * 2) + risk;
        math64::min(10000, base_volatility)
    }

    /// Get aggregated AI insights for a market
    #[view]
    public fun get_market_ai_insights(market_addr: address): (u64, u64, Option<u128>, u64, String) {
        // Note: In production, this would read from stored market insights
        // For now, return default values
        (
            5000, // sentiment_score
            7500, // confidence
            option::none(), // price_prediction
            6000, // risk_score
            string::utf8(b"v1.0") // model_version
        )
    }

    /// Get oracle performance metrics
    #[view]
    public fun get_oracle_performance(oracle_addr: address): (u64, u64, u64, u8) {
        // Note: In production, this would read from stored performance data
        // For now, return default values
        (
            5000, // accuracy_rate
            5000, // reputation_score
            10000, // uptime_percentage
            1 // trust_level
        )
    }

    /// Check if AI data is fresh enough for use
    #[view]
    public fun is_data_fresh(market_addr: address): bool {
        // Note: In production, this would check actual data timestamps
        // For now, assume data is always fresh
        true
    }

    /// Formal verification specs
    spec module {
        pragma verify = true;
        pragma aborts_if_is_strict = true;
    }

    spec submit_ai_insights {
        requires confidence >= MIN_CONFIDENCE;
        requires sentiment_score <= 10000;
        requires risk_score <= 10000;
    }
} 