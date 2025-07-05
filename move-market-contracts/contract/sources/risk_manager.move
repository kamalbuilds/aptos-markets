/// # Aptos Markets - Risk Management Contract
/// 
/// This contract provides comprehensive risk management for prediction markets:
/// - Position size limits to prevent excessive exposure
/// - Real-time fraud detection using AI pattern analysis
/// - Automated circuit breakers for unusual market activity
/// - Dynamic risk scoring based on user behavior and market conditions
/// - Integration with AI oracle for sentiment-based risk assessment
/// - Compliance monitoring and reporting
/// 
/// ## Security Requirements
/// 1. Risk limits must be enforced for all trading activities
/// 2. Fraud detection must trigger immediate protective measures
/// 3. AI risk scores must be regularly updated and validated
/// 4. All risk events must be logged for audit trails
/// 
module aptos_markets::risk_manager {
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
    use aptos_markets::market::{Self, Market};
    use aptos_markets::event_market::{Self, EventMarket};
    use aptos_markets::ai_oracle;

    /// Friend modules for internal access
    friend aptos_markets::market;
    friend aptos_markets::event_market;

    // Error constants
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_RISK_LIMIT_EXCEEDED: u64 = 2;
    const E_FRAUD_DETECTED: u64 = 3;
    const E_INSUFFICIENT_FUNDS: u64 = 4;
    const E_POSITION_TOO_LARGE: u64 = 5;
    const E_MARKET_SUSPENDED: u64 = 6;
    const E_INVALID_RISK_PARAMS: u64 = 7;
    const E_CIRCUIT_BREAKER_ACTIVE: u64 = 8;

    // Constants for risk management
    const MAX_POSITION_RATIO: u64 = 5000; // 50% of total market volume
    const MIN_RISK_SCORE: u64 = 0;
    const MAX_RISK_SCORE: u64 = 10000; // 100%
    const FRAUD_THRESHOLD: u64 = 8000; // 80% fraud score triggers action
    const CIRCUIT_BREAKER_THRESHOLD: u64 = 9000; // 90% extreme activity
    const MAX_DAILY_TRADES: u64 = 100; // Maximum trades per user per day
    const VELOCITY_WINDOW: u64 = 3600; // 1 hour velocity check window

    /// Risk levels
    const RISK_LOW: u8 = 0;
    const RISK_MEDIUM: u8 = 1;
    const RISK_HIGH: u8 = 2;
    const RISK_CRITICAL: u8 = 3;

    /// Global risk management registry
    struct RiskRegistry has key {
        admin: address,
        global_risk_limit: u128,
        total_exposure: u128,
        active_alerts: u64,
        circuit_breaker_active: bool,
        last_update: u64,
    }

    /// User risk profile with comprehensive tracking
    struct UserRiskProfile<phantom CoinType> has key {
        user_address: address,
        
        /// Risk scoring
        base_risk_score: u64, // 0-10000
        current_risk_score: u64,
        ai_risk_score: u64,
        historical_accuracy: u64,
        
        /// Position tracking
        total_exposure: u128,
        max_position_size: u128,
        active_positions: u64,
        largest_position: u128,
        
        /// Trading behavior
        total_trades: u64,
        daily_trades: u64,
        last_trade_time: u64,
        last_daily_reset: u64,
        trading_velocity: u64, // Trades per hour
        
        /// Fraud detection metrics
        suspicious_patterns: vector<String>,
        fraud_score: u64,
        consecutive_losses: u64,
        unusual_activity_count: u64,
        
        /// Compliance and limits
        kyc_verified: bool,
        compliance_score: u64,
        risk_level: u8,
        account_restricted: bool,
        restriction_reason: Option<String>,
        
        /// Historical data
        profit_loss_history: vector<u128>,
        risk_score_history: vector<u64>,
        last_assessment: u64,
    }

    /// Market risk assessment
    struct MarketRiskAssessment<phantom CoinType> has store {
        market_address: address,
        
        /// Market risk metrics
        liquidity_risk: u64,
        concentration_risk: u64,
        volatility_risk: u64,
        manipulation_risk: u64,
        overall_risk_score: u64,
        
        /// Activity monitoring
        unusual_volume: bool,
        rapid_price_changes: bool,
        large_position_alerts: u64,
        
        /// AI integration
        ai_sentiment_risk: u64,
        ai_manipulation_score: u64,
        ai_confidence: u64,
        
        /// Circuit breaker status
        circuit_breaker_triggered: bool,
        circuit_breaker_reason: String,
        circuit_breaker_timestamp: u64,
        
        last_assessment: u64,
    }

    /// Real-time risk monitoring data
    struct RiskMonitor has store {
        monitoring_active: bool,
        alert_threshold: u64,
        auto_action_enabled: bool,
        
        /// Rate limiting
        max_trades_per_hour: u64,
        max_volume_per_hour: u128,
        velocity_violations: u64,
        
        /// Pattern detection
        unusual_patterns: vector<String>,
        pattern_detection_enabled: bool,
        ai_monitoring_enabled: bool,
        
        /// Emergency controls
        emergency_stop_enabled: bool,
        emergency_contact: address,
        escalation_level: u8,
    }

    /// Fraud detection system
    struct FraudDetection has store {
        detection_active: bool,
        
        /// Pattern analysis
        coordinated_activity: bool,
        wash_trading_detected: bool,
        pump_dump_pattern: bool,
        sybil_behavior: bool,
        
        /// Timing analysis
        rapid_fire_trading: bool,
        off_hours_activity: bool,
        synchronized_actions: bool,
        
        /// Volume analysis
        volume_anomalies: bool,
        size_inconsistencies: bool,
        
        /// AI-powered detection
        ai_fraud_score: u64,
        ai_confidence: u64,
        ai_flags: vector<String>,
        
        last_scan: u64,
    }

    // Events for risk monitoring and compliance
    #[event]
    struct RiskAlert<phantom CoinType> has drop, store {
        user_address: address,
        market_address: Option<address>,
        alert_type: String,
        risk_level: u8,
        risk_score: u64,
        description: String,
        auto_action_taken: bool,
        timestamp: u64,
    }

    #[event]
    struct FraudAlert<phantom CoinType> has drop, store {
        user_address: address,
        market_address: Option<address>,
        fraud_type: String,
        fraud_score: u64,
        evidence: vector<String>,
        action_taken: String,
        timestamp: u64,
    }

    #[event]
    struct CircuitBreakerTriggered<phantom CoinType> has drop, store {
        market_address: address,
        trigger_reason: String,
        risk_score: u64,
        trigger_threshold: u64,
        duration: u64,
        timestamp: u64,
    }

    #[event]
    struct PositionLimitExceeded<phantom CoinType> has drop, store {
        user_address: address,
        market_address: address,
        attempted_position: u128,
        max_allowed: u128,
        current_exposure: u128,
        timestamp: u64,
    }

    #[event]
    struct RiskScoreUpdated<phantom CoinType> has drop, store {
        user_address: address,
        old_score: u64,
        new_score: u64,
        factors: vector<String>,
        ai_influenced: bool,
        timestamp: u64,
    }

    /// Initialize risk management system
    fun init_module(admin: &signer) {
        let registry = RiskRegistry {
            admin: signer::address_of(admin),
            global_risk_limit: 1000000000000, // 10M APT equivalent
            total_exposure: 0,
            active_alerts: 0,
            circuit_breaker_active: false,
            last_update: timestamp::now_seconds(),
        };
        move_to(admin, registry);
    }

    /// Create or update user risk profile
    public entry fun initialize_user_risk_profile<CoinType>(user: &signer) {
        let user_addr = signer::address_of(user);
        let current_time = timestamp::now_seconds();
        
        if (exists<UserRiskProfile<CoinType>>(user_addr)) {
            return // Profile already exists
        };
        
        let profile = UserRiskProfile<CoinType> {
            user_address: user_addr,
            base_risk_score: 5000, // 50% starting risk
            current_risk_score: 5000,
            ai_risk_score: 5000,
            historical_accuracy: 5000,
            total_exposure: 0,
            max_position_size: 1000000000, // 10 APT default
            active_positions: 0,
            largest_position: 0,
            total_trades: 0,
            daily_trades: 0,
            last_trade_time: current_time,
            last_daily_reset: current_time,
            trading_velocity: 0,
            suspicious_patterns: vector::empty(),
            fraud_score: 0,
            consecutive_losses: 0,
            unusual_activity_count: 0,
            kyc_verified: false,
            compliance_score: 5000,
            risk_level: RISK_MEDIUM,
            account_restricted: false,
            restriction_reason: option::none(),
            profit_loss_history: vector::empty(),
            risk_score_history: vector::empty(),
            last_assessment: current_time,
        };
        
        move_to(user, profile);
    }

    /// Pre-trade risk check
    public fun pre_trade_risk_check<CoinType>(
        user_addr: address,
        market_addr: address,
        position_size: u128
    ): bool acquires UserRiskProfile, RiskRegistry {
        // Initialize profile if it doesn't exist
        if (!exists<UserRiskProfile<CoinType>>(user_addr)) {
            return false // Must initialize profile first
        };
        
        let profile = borrow_global<UserRiskProfile<CoinType>>(user_addr);
        let registry = borrow_global<RiskRegistry>(@aptos_markets);
        let current_time = timestamp::now_seconds();
        
        // Check global circuit breaker
        if (registry.circuit_breaker_active) {
            return false
        };
        
        // Check account restrictions
        if (profile.account_restricted) {
            return false
        };
        
        // Check position size limits
        if (position_size > profile.max_position_size) {
            emit_position_limit_alert<CoinType>(
                user_addr, 
                market_addr, 
                position_size, 
                profile.max_position_size,
                current_time
            );
            return false
        };
        
        // Check total exposure
        let new_exposure = profile.total_exposure + position_size;
        if (new_exposure > profile.max_position_size * 10) { // 10x leverage limit
            return false
        };
        
        // Check daily trading limits
        if (profile.daily_trades >= MAX_DAILY_TRADES) {
            return false
        };
        
        // Check trading velocity
        let time_diff = current_time - profile.last_trade_time;
        if (time_diff < 60 && profile.trading_velocity > 10) { // Max 10 trades per minute
            return false
        };
        
        // Check fraud score
        if (profile.fraud_score >= FRAUD_THRESHOLD) {
            return false
        };
        
        // Check AI risk assessment
        if (profile.ai_risk_score >= 9000) { // 90% AI risk threshold
            return false
        };
        
        true
    }

    /// Post-trade risk update
    public fun post_trade_risk_update<CoinType>(
        user_addr: address,
        market_addr: address,
        position_size: u128,
        is_buy: bool
    ) acquires UserRiskProfile, RiskRegistry {
        if (!exists<UserRiskProfile<CoinType>>(user_addr)) {
            return // No profile exists
        };
        
        let profile = borrow_global_mut<UserRiskProfile<CoinType>>(user_addr);
        let current_time = timestamp::now_seconds();
        
        // Reset daily counter if new day
        if (current_time - profile.last_daily_reset > 86400) {
            profile.daily_trades = 0;
            profile.last_daily_reset = current_time;
        };
        
        // Update position tracking
        if (is_buy) {
            profile.total_exposure = profile.total_exposure + position_size;
            profile.active_positions = profile.active_positions + 1;
            if (position_size > profile.largest_position) {
                profile.largest_position = position_size;
            };
        } else {
            if (profile.total_exposure >= position_size) {
                profile.total_exposure = profile.total_exposure - position_size;
            } else {
                profile.total_exposure = 0;
            };
            if (profile.active_positions > 0) {
                profile.active_positions = profile.active_positions - 1;
            };
        };
        
        // Update trading metrics
        profile.total_trades = profile.total_trades + 1;
        profile.daily_trades = profile.daily_trades + 1;
        
        // Calculate trading velocity
        let time_since_last = current_time - profile.last_trade_time;
        if (time_since_last > 0) {
            profile.trading_velocity = 3600 / time_since_last; // Trades per hour
        };
        profile.last_trade_time = current_time;
        
        // Update risk scores
        update_risk_scores(profile, current_time);
        
        // Check for suspicious patterns
        detect_suspicious_activity(profile, position_size, current_time);
        
        // Update global exposure
        let registry = borrow_global_mut<RiskRegistry>(@aptos_markets);
        if (is_buy) {
            registry.total_exposure = registry.total_exposure + position_size;
        } else {
            if (registry.total_exposure >= position_size) {
                registry.total_exposure = registry.total_exposure - position_size;
            } else {
                registry.total_exposure = 0;
            };
        };
        registry.last_update = current_time;
    }

    /// Update AI-driven risk assessment
    public fun update_ai_risk_assessment<CoinType>(
        user_addr: address,
        ai_risk_score: u64,
        ai_confidence: u64,
        risk_factors: vector<String>
    ) acquires UserRiskProfile {
        if (!exists<UserRiskProfile<CoinType>>(user_addr)) {
            return
        };
        
        let profile = borrow_global_mut<UserRiskProfile<CoinType>>(user_addr);
        let current_time = timestamp::now_seconds();
        let old_score = profile.current_risk_score;
        
        // Update AI risk score
        profile.ai_risk_score = ai_risk_score;
        
        // Combine AI score with base risk (weighted average)
        let ai_weight = if (ai_confidence >= 7000) 4000 else 2000; // 40% or 20% weight
        profile.current_risk_score = 
            (profile.base_risk_score * (10000 - ai_weight) + ai_risk_score * ai_weight) / 10000;
        
        // Update risk level
        profile.risk_level = if (profile.current_risk_score < 3000) {
            RISK_LOW
        } else if (profile.current_risk_score < 6000) {
            RISK_MEDIUM
        } else if (profile.current_risk_score < 8500) {
            RISK_HIGH
        } else {
            RISK_CRITICAL
        };
        
        // Emit risk score update event
        event::emit(RiskScoreUpdated<CoinType> {
            user_address: user_addr,
            old_score,
            new_score: profile.current_risk_score,
            factors: risk_factors,
            ai_influenced: true,
            timestamp: current_time,
        });
        
        // Check if account should be restricted
        if (profile.current_risk_score >= 9000) {
            profile.account_restricted = true;
            profile.restriction_reason = option::some(string::utf8(b"HIGH_AI_RISK_SCORE"));
            
            event::emit(RiskAlert<CoinType> {
                user_address: user_addr,
                market_address: option::none(),
                alert_type: string::utf8(b"ACCOUNT_RESTRICTED"),
                risk_level: RISK_CRITICAL,
                risk_score: profile.current_risk_score,
                description: string::utf8(b"Account restricted due to high AI risk score"),
                auto_action_taken: true,
                timestamp: current_time,
            });
        };
    }

    /// Fraud detection and response
    public entry fun report_suspicious_activity<CoinType>(
        reporter: &signer,
        user_addr: address,
        activity_type: String,
        evidence: vector<String>
    ) acquires UserRiskProfile {
        if (!exists<UserRiskProfile<CoinType>>(user_addr)) {
            return
        };
        
        let profile = borrow_global_mut<UserRiskProfile<CoinType>>(user_addr);
        let current_time = timestamp::now_seconds();
        
        // Add to suspicious patterns
        vector::push_back(&mut profile.suspicious_patterns, activity_type);
        profile.unusual_activity_count = profile.unusual_activity_count + 1;
        
        // Increase fraud score
        profile.fraud_score = if (profile.fraud_score + 1000 > 10000) {
            10000
        } else {
            profile.fraud_score + 1000
        };
        
        // Check if fraud threshold exceeded
        if (profile.fraud_score >= FRAUD_THRESHOLD) {
            profile.account_restricted = true;
            profile.restriction_reason = option::some(string::utf8(b"FRAUD_DETECTED"));
            
            event::emit(FraudAlert<CoinType> {
                user_address: user_addr,
                market_address: option::none(),
                fraud_type: activity_type,
                fraud_score: profile.fraud_score,
                evidence,
                action_taken: string::utf8(b"ACCOUNT_RESTRICTED"),
                timestamp: current_time,
            });
        };
    }

    /// Emergency circuit breaker
    public entry fun trigger_circuit_breaker<CoinType>(
        admin: &signer,
        reason: String,
        duration: u64
    ) acquires RiskRegistry {
        let registry = borrow_global_mut<RiskRegistry>(@aptos_markets);
        assert!(signer::address_of(admin) == registry.admin, error::permission_denied(E_NOT_AUTHORIZED));
        
        let current_time = timestamp::now_seconds();
        registry.circuit_breaker_active = true;
        registry.last_update = current_time;
        
        event::emit(CircuitBreakerTriggered<CoinType> {
            market_address: @aptos_markets, // Global circuit breaker
            trigger_reason: reason,
            risk_score: 10000, // Maximum risk
            trigger_threshold: CIRCUIT_BREAKER_THRESHOLD,
            duration,
            timestamp: current_time,
        });
    }

    // Helper functions

    fun update_risk_scores<CoinType>(profile: &mut UserRiskProfile<CoinType>, current_time: u64) {
        // Calculate risk based on exposure ratio
        let exposure_ratio = if (profile.max_position_size > 0) {
            ((profile.total_exposure * 10000) / profile.max_position_size as u64)
        } else {
            0u64
        };
        
        // Calculate velocity risk
        let velocity_risk = if (profile.trading_velocity > 20) {
            (profile.trading_velocity - 20) * 100 // Increase risk for high velocity
        } else {
            0u64
        };
        
        // Update base risk score
        profile.base_risk_score = 5000 + // Base 50%
            (exposure_ratio / 2) + // Up to 50% from exposure
            velocity_risk; // Velocity penalty
        
        // Cap at maximum
        if (profile.base_risk_score > 10000) {
            profile.base_risk_score = 10000;
        };
        
        // Store in history
        vector::push_back(&mut profile.risk_score_history, profile.current_risk_score);
        if (vector::length(&profile.risk_score_history) > 100) {
            vector::remove(&mut profile.risk_score_history, 0);
        };
        
        profile.last_assessment = current_time;
    }

    fun detect_suspicious_activity<CoinType>(
        profile: &mut UserRiskProfile<CoinType>, 
        position_size: u128, 
        current_time: u64
    ) {
        // Check for rapid fire trading
        if (profile.trading_velocity > 60) { // More than 1 trade per minute
            vector::push_back(&mut profile.suspicious_patterns, string::utf8(b"RAPID_TRADING"));
        };
        
        // Check for unusually large positions
        if (position_size > profile.max_position_size / 2) {
            vector::push_back(&mut profile.suspicious_patterns, string::utf8(b"LARGE_POSITION"));
        };
        
        // Check for off-hours trading (simplified)
        let hour_of_day = (current_time / 3600) % 24;
        if (hour_of_day < 6 || hour_of_day > 22) { // Outside 6 AM - 10 PM
            vector::push_back(&mut profile.suspicious_patterns, string::utf8(b"OFF_HOURS_TRADING"));
        };
        
        // Increase fraud score if patterns detected
        if (vector::length(&profile.suspicious_patterns) > 10) {
            profile.fraud_score = profile.fraud_score + 500; // +5% fraud score
        };
    }

    fun emit_position_limit_alert<CoinType>(
        user_addr: address,
        market_addr: address,
        attempted: u128,
        max_allowed: u128,
        current_time: u64
    ) {
        event::emit(PositionLimitExceeded<CoinType> {
            user_address: user_addr,
            market_address: market_addr,
            attempted_position: attempted,
            max_allowed,
            current_exposure: 0, // Would calculate from profile
            timestamp: current_time,
        });
    }

    /// View functions
    #[view]
    public fun get_user_risk_profile<CoinType>(user_addr: address): (u64, u64, u8, bool, u64) 
    acquires UserRiskProfile {
        if (!exists<UserRiskProfile<CoinType>>(user_addr)) {
            return (5000, 0, RISK_MEDIUM, false, 0)
        };
        
        let profile = borrow_global<UserRiskProfile<CoinType>>(user_addr);
        (
            profile.current_risk_score,
            (profile.total_exposure as u64),
            profile.risk_level,
            profile.account_restricted,
            profile.fraud_score
        )
    }

    #[view]
    public fun is_circuit_breaker_active(): bool acquires RiskRegistry {
        if (!exists<RiskRegistry>(@aptos_markets)) {
            return false
        };
        borrow_global<RiskRegistry>(@aptos_markets).circuit_breaker_active
    }

    #[view]
    public fun get_global_risk_metrics(): (u128, u64, bool) acquires RiskRegistry {
        if (!exists<RiskRegistry>(@aptos_markets)) {
            return (0, 0, false)
        };
        
        let registry = borrow_global<RiskRegistry>(@aptos_markets);
        (
            registry.total_exposure,
            registry.active_alerts,
            registry.circuit_breaker_active
        )
    }

    /// Admin functions
    public entry fun update_risk_parameters<CoinType>(
        admin: &signer,
        user_addr: address,
        max_position_size: u128
    ) acquires RiskRegistry, UserRiskProfile {
        let registry = borrow_global<RiskRegistry>(@aptos_markets);
        assert!(signer::address_of(admin) == registry.admin, error::permission_denied(E_NOT_AUTHORIZED));
        
        if (exists<UserRiskProfile<CoinType>>(user_addr)) {
            let profile = borrow_global_mut<UserRiskProfile<CoinType>>(user_addr);
            profile.max_position_size = max_position_size;
        };
    }

    public entry fun remove_account_restriction<CoinType>(
        admin: &signer,
        user_addr: address
    ) acquires RiskRegistry, UserRiskProfile {
        let registry = borrow_global<RiskRegistry>(@aptos_markets);
        assert!(signer::address_of(admin) == registry.admin, error::permission_denied(E_NOT_AUTHORIZED));
        
        if (exists<UserRiskProfile<CoinType>>(user_addr)) {
            let profile = borrow_global_mut<UserRiskProfile<CoinType>>(user_addr);
            profile.account_restricted = false;
            profile.restriction_reason = option::none();
            profile.fraud_score = 0; // Reset fraud score
        };
    }

    /// Formal verification specs
    spec module {
        pragma verify = true;
        pragma aborts_if_is_strict = true;
    }

    spec pre_trade_risk_check {
        requires exists<UserRiskProfile<CoinType>>(user_addr);
        requires exists<RiskRegistry>(@aptos_markets);
        ensures result == true ==> position_size <= borrow_global<UserRiskProfile<CoinType>>(user_addr).max_position_size;
    }
} 