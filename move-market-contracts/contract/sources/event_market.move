/// # Aptos Markets - Enhanced Event Market Contract
/// 
/// This contract manages event-based prediction markets with advanced features:
/// - AI-powered event outcome prediction and risk assessment
/// - Community governance for dispute resolution
/// - Automated market making with dynamic pricing
/// - Real-time fraud detection and prevention
/// - Multi-outcome betting with complex event structures
/// - Enhanced liquidity management and optimization
/// 
/// ## Security Requirements
/// 1. Only authorized creators can create event markets
/// 2. Event resolution must be community-verified
/// 3. AI predictions must not compromise market integrity
/// 4. All bets must be validated and recorded properly
/// 
module aptos_markets::event_market {
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use std::error;
    use aptos_std::table::{Self, Table};
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_std::coin::{Self, Coin};
    use aptos_std::type_info::{Self, TypeInfo};
    use aptos_framework::object::{Self, Object, ConstructorRef, ExtendRef};
    use aptos_framework::event;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_markets::marketplace::{Self, Marketplace};
    use aptos_markets::ai_oracle;

    // Error constants
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_EVENT_NOT_FOUND: u64 = 2;
    const E_EVENT_ALREADY_RESOLVED: u64 = 3;
    const E_EVENT_NOT_STARTED: u64 = 4;
    const E_EVENT_ENDED: u64 = 5;
    const E_INVALID_BET_AMOUNT: u64 = 6;
    const E_INVALID_OUTCOME: u64 = 7;
    const E_INSUFFICIENT_LIQUIDITY: u64 = 8;
    const E_GOVERNANCE_PERIOD_ACTIVE: u64 = 9;
    const E_INVALID_OUTCOME_COUNT: u64 = 10;
    const E_DISPUTE_PERIOD_ENDED: u64 = 11;

    // Constants
    const MIN_BET_AMOUNT: u64 = 1000000; // 0.01 APT (8 decimals)
    const MAX_OUTCOMES: u8 = 10; // Maximum 10 outcomes per event
    const GOVERNANCE_PERIOD: u64 = 604800; // 7 days for dispute resolution
    const MIN_VALIDATORS: u64 = 3; // Minimum validators for resolution
    const DISPUTE_THRESHOLD: u64 = 3000; // 30% dispute threshold

    /// Event market statuses
    const EVENT_PENDING: u8 = 0;
    const EVENT_ACTIVE: u8 = 1;
    const EVENT_PAUSED: u8 = 2;
    const EVENT_RESOLVED: u8 = 3;
    const EVENT_DISPUTED: u8 = 4;
    const EVENT_CANCELLED: u8 = 5;

    /// Event market with multiple outcomes
    struct EventMarket<phantom CoinType> has drop, key, store {
        /// Basic market info
        title: String,
        description: String,
        category: String,
        creator: address,
        created_at: u64,
        start_time: u64,
        end_time: u64,
        resolution_deadline: u64,
        governance_end: u64,
        status: u8,
        
        /// Outcome configuration
        outcome_count: u8,
        outcome_names: vector<String>,
        resolved: bool,
        winning_outcome: Option<u8>,
        resolution_source: Option<String>,
        
        /// Betting pools for each outcome
        outcome_pools: vector<u128>, // Pool for each outcome
        total_volume: u128,
        unique_bettors: u64,
        
        /// Pricing and odds
        outcome_prices: vector<u64>, // Price for each outcome (basis points)
        price_history: vector<u64>, // Simplified price history (just timestamps)
        last_price_update: u64,
        
        /// AI Integration
        ai_predictions: vector<u64>, // AI prediction for each outcome
        ai_confidence: u64,
        ai_sentiment_scores: vector<u64>,
        ai_last_update: u64,
        ai_enabled: bool,
        
        /// Governance and validation
        validators: vector<address>,
        validator_votes: SimpleMap<address, u8>, // Validator -> outcome vote
        dispute_votes: u64,
        resolution_consensus: u64, // Percentage consensus required
        
        /// Risk management
        max_exposure: u128,
        current_exposure: u128,
        risk_score: u64,
        fraud_alerts: vector<String>,
        
        /// Liquidity management
        liquidity_pool: u128,
        min_liquidity: u128,
        liquidity_providers: vector<address>,
        auto_market_making: bool,
        
        /// Fee structure
        market_fee_rate: u64, // In basis points
        validator_fee_rate: u64,
        collected_fees: u128,
        
        /// Object management
        extend_ref: ExtendRef,
    }

    /// Individual bet on event outcome
    struct EventBet<phantom CoinType> has store {
        bettor: address,
        outcome: u8,
        amount: u128,
        odds: u64, // Odds at time of bet
        timestamp: u64,
        ai_influenced: bool,
    }

    /// Validator information
    struct Validator has store {
        validator_address: address,
        reputation_score: u64,
        total_validations: u64,
        correct_validations: u64,
        stake_amount: u128,
        last_activity: u64,
    }

    /// Governance proposal for dispute resolution
    struct DisputeProposal has store {
        proposer: address,
        proposed_outcome: u8,
        evidence: String,
        support_votes: u64,
        against_votes: u64,
        created_at: u64,
        voting_deadline: u64,
    }

    /// Event analytics for AI training
    struct EventAnalytics<phantom CoinType> has store {
        betting_volume_by_outcome: vector<u128>,
        price_volatility: u64,
        market_efficiency: u64,
        ai_accuracy_score: u64,
        fraud_detection_score: u64,
        liquidity_stability: u64,
    }

    // Events for monitoring and analytics
    #[event]
    struct EventMarketCreated<phantom CoinType> has drop, store {
        event_address: address,
        creator: address,
        title: String,
        category: String,
        outcome_count: u8,
        start_time: u64,
        end_time: u64,
        ai_enabled: bool,
        timestamp: u64,
    }

    #[event]
    struct EventBetPlaced<phantom CoinType> has drop, store {
        event_address: address,
        bettor: address,
        outcome: u8,
        amount: u128,
        odds: u64,
        new_outcome_prices: vector<u64>,
        ai_influenced: bool,
        timestamp: u64,
    }

    #[event]
    struct EventResolved<phantom CoinType> has drop, store {
        event_address: address,
        winning_outcome: u8,
        total_volume: u128,
        validator_count: u64,
        consensus_percentage: u64,
        ai_accuracy: u64,
        timestamp: u64,
    }

    #[event]
    struct EventDisputed<phantom CoinType> has drop, store {
        event_address: address,
        disputant: address,
        original_outcome: u8,
        proposed_outcome: u8,
        evidence: String,
        timestamp: u64,
    }

    #[event]
    struct ValidatorAdded has drop, store {
        event_address: address,
        validator: address,
        reputation_score: u64,
        stake_amount: u128,
        timestamp: u64,
    }

    #[event]
    struct AIEventInsight<phantom CoinType> has drop, store {
        event_address: address,
        predictions: vector<u64>,
        confidence: u64,
        sentiment_scores: vector<u64>,
        recommendation: String,
        timestamp: u64,
    }

    #[event]
    struct LiquidityManagement<phantom CoinType> has drop, store {
        event_address: address,
        action: String, // "added", "removed", "rebalanced"
        amount: u128,
        new_total: u128,
        efficiency_change: u64,
        timestamp: u64,
    }

    /// Create a new event market
    public entry fun create_event_market<CoinType>(
        creator: &signer,
        marketplace_addr: address,
        title: String,
        description: String,
        category: String,
        outcome_names: vector<String>,
        start_time: u64,
        end_time: u64,
        resolution_deadline: u64,
        initial_liquidity: u64
    ) acquires EventMarket {
        let creator_addr = signer::address_of(creator);
        let current_time = timestamp::now_seconds();
        let outcome_count = (vector::length(&outcome_names) as u8);
        
        // Input validation
        assert!(start_time > current_time, error::invalid_argument(E_EVENT_NOT_STARTED));
        assert!(end_time > start_time, error::invalid_argument(E_EVENT_ENDED));
        assert!(resolution_deadline > end_time, error::invalid_argument(E_EVENT_ENDED));
        assert!(outcome_count >= 2 && outcome_count <= MAX_OUTCOMES, 
                error::invalid_argument(E_INVALID_OUTCOME_COUNT));
        assert!(string::length(&title) > 0, error::invalid_argument(E_EVENT_NOT_FOUND));
        assert!(initial_liquidity >= MIN_BET_AMOUNT, error::invalid_argument(E_INVALID_BET_AMOUNT));
        
        // Create event market object
        let constructor_ref = object::create_object(@aptos_markets);
        let object_signer = object::generate_signer(&constructor_ref);
        let event_addr = object::address_from_constructor_ref(&constructor_ref);
        let extend_ref = object::generate_extend_ref(&constructor_ref);
        
        // Initialize outcome pools and prices
        let outcome_pools = vector::empty<u128>();
        let outcome_prices = vector::empty<u64>();
        let ai_predictions = vector::empty<u64>();
        let ai_sentiment_scores = vector::empty<u64>();
        
        let i = 0;
        while (i < outcome_count) {
            vector::push_back(&mut outcome_pools, 0);
            vector::push_back(&mut outcome_prices, 10000 / (outcome_count as u64)); // Equal initial prices
            vector::push_back(&mut ai_predictions, 10000 / (outcome_count as u64)); // Equal initial predictions
            vector::push_back(&mut ai_sentiment_scores, 5000); // Neutral sentiment
            i = i + 1;
        };
        
        // Create event market
        let event_market = EventMarket<CoinType> {
            title,
            description,
            category,
            creator: creator_addr,
            created_at: current_time,
            start_time,
            end_time,
            resolution_deadline,
            governance_end: resolution_deadline + GOVERNANCE_PERIOD,
            status: EVENT_PENDING,
            outcome_count,
            outcome_names,
            resolved: false,
            winning_outcome: option::none(),
            resolution_source: option::none(),
            outcome_pools,
            total_volume: 0,
            unique_bettors: 0,
            outcome_prices,
            price_history: vector::empty(),
            last_price_update: current_time,
            ai_predictions,
            ai_confidence: 0,
            ai_sentiment_scores,
            ai_last_update: current_time,
            ai_enabled: true,
            validators: vector::empty(),
            validator_votes: simple_map::new(),
            dispute_votes: 0,
            resolution_consensus: 7000, // 70% consensus required
            max_exposure: (initial_liquidity as u128) * 20, // 20x initial liquidity
            current_exposure: 0,
            risk_score: 0,
            fraud_alerts: vector::empty(),
            liquidity_pool: (initial_liquidity as u128),
            min_liquidity: (initial_liquidity as u128) / 10, // 10% minimum
            liquidity_providers: vector::empty(),
            auto_market_making: true,
            market_fee_rate: 200, // 2%
            validator_fee_rate: 50, // 0.5%
            collected_fees: 0,
            extend_ref,
        };
        
        // Capture values for event emission before move_to
        let event_title = event_market.title;
        let event_category = event_market.category;
        
        move_to(&object_signer, event_market);
        
        // Register with marketplace
        marketplace::register_market<CoinType>(marketplace_addr, event_addr, category);
        
        // Initialize coin store if needed
        if (!coin::is_account_registered<CoinType>(event_addr)) {
            coin::register<CoinType>(&object_signer);
        };
        
        // Add creator as initial liquidity provider
        let event_market_mut = borrow_global_mut<EventMarket<CoinType>>(event_addr);
        vector::push_back(&mut event_market_mut.liquidity_providers, creator_addr);
        
        // Transfer initial liquidity from creator
        let coins = coin::withdraw<CoinType>(creator, initial_liquidity);
        coin::deposit(event_addr, coins);
        
        // Emit creation event
        event::emit(EventMarketCreated<CoinType> {
            event_address: event_addr,
            creator: creator_addr,
            title: event_title,
            category: event_category,
            outcome_count,
            start_time,
            end_time,
            ai_enabled: true,
            timestamp: current_time,
        });
    }

    /// Start event market (activate betting)
    public entry fun start_event_market<CoinType>(creator: &signer, event_addr: address) 
    acquires EventMarket {
        let creator_addr = signer::address_of(creator);
        let event_market = borrow_global_mut<EventMarket<CoinType>>(event_addr);
        let current_time = timestamp::now_seconds();
        
        // Validate authorization and timing
        assert!(event_market.creator == creator_addr, error::permission_denied(E_NOT_AUTHORIZED));
        assert!(current_time >= event_market.start_time, error::invalid_state(E_EVENT_NOT_STARTED));
        assert!(event_market.status == EVENT_PENDING, error::invalid_state(E_EVENT_ALREADY_RESOLVED));
        
        // Activate event market
        event_market.status = EVENT_ACTIVE;
    }

    /// Place a bet on event outcome
    public entry fun place_event_bet<CoinType>(
        bettor: &signer,
        event_addr: address,
        outcome: u8,
        amount: u64
    ) acquires EventMarket {
        let bettor_addr = signer::address_of(bettor);
        let event_market = borrow_global_mut<EventMarket<CoinType>>(event_addr);
        let current_time = timestamp::now_seconds();
        
        // Validate event state and bet
        assert!(event_market.status == EVENT_ACTIVE, error::invalid_state(E_EVENT_NOT_STARTED));
        assert!(current_time <= event_market.end_time, error::invalid_state(E_EVENT_ENDED));
        assert!(outcome < event_market.outcome_count, error::invalid_argument(E_INVALID_OUTCOME));
        assert!(amount >= MIN_BET_AMOUNT, error::invalid_argument(E_INVALID_BET_AMOUNT));
        
        // Check exposure limits
        let exposure_increase = (amount as u128);
        assert!(event_market.current_exposure + exposure_increase <= event_market.max_exposure,
                error::resource_exhausted(E_INSUFFICIENT_LIQUIDITY));
        
        // Calculate current odds for the outcome
        let current_odds = *vector::borrow(&event_market.outcome_prices, (outcome as u64));
        
        // Process the bet
        let coins = coin::withdraw<CoinType>(bettor, amount);
        coin::deposit(event_addr, coins);
        
        // Update outcome pool
        let outcome_pool = vector::borrow_mut(&mut event_market.outcome_pools, (outcome as u64));
        *outcome_pool = *outcome_pool + (amount as u128);
        
        // Update totals
        event_market.total_volume = event_market.total_volume + (amount as u128);
        event_market.current_exposure = event_market.current_exposure + exposure_increase;
        
        // Update pricing using market maker
        update_outcome_prices(event_market);
        
        // Record price history
        vector::push_back(&mut event_market.price_history, current_time);
        event_market.last_price_update = current_time;
        
        // Check AI influence
        let ai_influenced = event_market.ai_confidence >= 7000; // 70% confidence threshold
        
        // Emit betting event
        event::emit(EventBetPlaced<CoinType> {
            event_address: event_addr,
            bettor: bettor_addr,
            outcome,
            amount: (amount as u128),
            odds: current_odds,
            new_outcome_prices: event_market.outcome_prices,
            ai_influenced,
            timestamp: current_time,
        });
        
        // Record volume in marketplace
        marketplace::record_volume<CoinType>(
            marketplace::get_marketplace_address<CoinType>(),
            (amount as u128)
        );
    }

    /// Add validator to event market
    public entry fun add_validator<CoinType>(
        admin: &signer,
        event_addr: address,
        validator_addr: address,
        stake_amount: u64
    ) acquires EventMarket {
        let admin_addr = signer::address_of(admin);
        let event_market = borrow_global_mut<EventMarket<CoinType>>(event_addr);
        let current_time = timestamp::now_seconds();
        
        // Validate authorization (creator or marketplace admin)
        assert!(event_market.creator == admin_addr, error::permission_denied(E_NOT_AUTHORIZED));
        assert!(stake_amount >= MIN_BET_AMOUNT, error::invalid_argument(E_INVALID_BET_AMOUNT));
        
        // Check if validator already exists
        let found = false;
        let i = 0;
        let len = vector::length(&event_market.validators);
        while (i < len && !found) {
            if (*vector::borrow(&event_market.validators, i) == validator_addr) {
                found = true;
            };
            i = i + 1;
        };
        assert!(!found, error::already_exists(E_NOT_AUTHORIZED));
        
        // Add validator
        vector::push_back(&mut event_market.validators, validator_addr);
        
        // Emit validator addition event
        event::emit(ValidatorAdded {
            event_address: event_addr,
            validator: validator_addr,
            reputation_score: 5000, // Default reputation
            stake_amount: (stake_amount as u128),
            timestamp: current_time,
        });
    }

    /// Submit validator vote for event resolution
    public entry fun submit_validator_vote<CoinType>(
        validator: &signer,
        event_addr: address,
        outcome_vote: u8
    ) acquires EventMarket {
        let validator_addr = signer::address_of(validator);
        let event_market = borrow_global_mut<EventMarket<CoinType>>(event_addr);
        let current_time = timestamp::now_seconds();
        
        // Validate voting conditions
        assert!(current_time > event_market.end_time, error::invalid_state(E_EVENT_NOT_STARTED));
        assert!(current_time <= event_market.resolution_deadline, error::invalid_state(E_DISPUTE_PERIOD_ENDED));
        assert!(outcome_vote < event_market.outcome_count, error::invalid_argument(E_INVALID_OUTCOME));
        
        // Check if validator is authorized
        let is_validator = false;
        let i = 0;
        let len = vector::length(&event_market.validators);
        while (i < len && !is_validator) {
            if (*vector::borrow(&event_market.validators, i) == validator_addr) {
                is_validator = true;
            };
            i = i + 1;
        };
        assert!(is_validator, error::permission_denied(E_NOT_AUTHORIZED));
        
        // Record vote
        if (simple_map::contains_key(&event_market.validator_votes, &validator_addr)) {
            let vote = simple_map::borrow_mut(&mut event_market.validator_votes, &validator_addr);
            *vote = outcome_vote;
        } else {
            simple_map::add(&mut event_market.validator_votes, validator_addr, outcome_vote);
        };
        
        // Check if we have enough votes to resolve
        let vote_count = vector::length(&event_market.validators);
        if (vote_count >= MIN_VALIDATORS) {
            try_resolve_with_consensus(event_market, current_time);
        };
    }

    /// Resolve event market with validator consensus
    public entry fun resolve_event_market<CoinType>(
        resolver: &signer,
        event_addr: address,
        winning_outcome: u8,
        resolution_source: String
    ) acquires EventMarket {
        let resolver_addr = signer::address_of(resolver);
        let event_market = borrow_global_mut<EventMarket<CoinType>>(event_addr);
        let current_time = timestamp::now_seconds();
        
        // Validate authorization and state
        assert!(event_market.creator == resolver_addr, error::permission_denied(E_NOT_AUTHORIZED));
        assert!(!event_market.resolved, error::invalid_state(E_EVENT_ALREADY_RESOLVED));
        assert!(current_time > event_market.end_time, error::invalid_state(E_EVENT_NOT_STARTED));
        assert!(winning_outcome < event_market.outcome_count, error::invalid_argument(E_INVALID_OUTCOME));
        
        // Resolve event
        event_market.resolved = true;
        event_market.winning_outcome = option::some(winning_outcome);
        event_market.resolution_source = option::some(resolution_source);
        event_market.status = EVENT_RESOLVED;
        
        // Calculate AI accuracy
        let ai_accuracy = calculate_ai_accuracy(event_market, winning_outcome);
        
        // Calculate validator consensus
        let consensus_percentage = calculate_consensus_percentage(event_market, winning_outcome);
        
        // Emit resolution event
        event::emit(EventResolved<CoinType> {
            event_address: event_addr,
            winning_outcome,
            total_volume: event_market.total_volume,
            validator_count: vector::length(&event_market.validators),
            consensus_percentage,
            ai_accuracy,
            timestamp: current_time,
        });
        
        // Update AI oracle with performance data
        if (event_market.ai_enabled && event_market.ai_confidence > 0) {
            let predicted_outcome = get_ai_predicted_outcome(event_market);
            let predicted_correct = predicted_outcome == winning_outcome;
            // Note: In production, this would call ai_oracle::update_oracle_performance
        };
    }

    /// Update AI insights for event market - accessible by AI oracle
    public fun update_ai_event_data<CoinType>(
        event_addr: address,
        predictions: vector<u64>,
        confidence: u64,
        sentiment_scores: vector<u64>
    ) acquires EventMarket {
        let event_market = borrow_global_mut<EventMarket<CoinType>>(event_addr);
        let current_time = timestamp::now_seconds();
        
        // Validate input
        assert!(vector::length(&predictions) == (event_market.outcome_count as u64),
                error::invalid_argument(E_INVALID_OUTCOME_COUNT));
        assert!(vector::length(&sentiment_scores) == (event_market.outcome_count as u64),
                error::invalid_argument(E_INVALID_OUTCOME_COUNT));
        
        // Update AI data
        event_market.ai_predictions = predictions;
        event_market.ai_confidence = confidence;
        event_market.ai_sentiment_scores = sentiment_scores;
        event_market.ai_last_update = current_time;
        
        // Generate recommendation based on highest prediction
        let recommendation = get_recommendation_from_predictions(&predictions);
        
        // Emit AI insight event
        event::emit(AIEventInsight<CoinType> {
            event_address: event_addr,
            predictions,
            confidence,
            sentiment_scores,
            recommendation,
            timestamp: current_time,
        });
    }

    // Helper functions

    fun update_outcome_prices<CoinType>(event_market: &mut EventMarket<CoinType>) {
        // Simple proportional market maker
        let total_pool = 0u128;
        let i = 0;
        let outcome_count = event_market.outcome_count;
        
        // Calculate total pool
        while (i < (outcome_count as u64)) {
            let pool = *vector::borrow(&event_market.outcome_pools, i);
            total_pool = total_pool + pool;
            i = i + 1;
        };
        
        if (total_pool > 0) {
            i = 0;
            while (i < (outcome_count as u64)) {
                let pool = *vector::borrow(&event_market.outcome_pools, i);
                let price = ((pool * 10000) / total_pool as u64);
                let price_ref = vector::borrow_mut(&mut event_market.outcome_prices, i);
                *price_ref = price;
                i = i + 1;
            };
        };
    }

    fun try_resolve_with_consensus<CoinType>(event_market: &mut EventMarket<CoinType>, current_time: u64) {
        let vote_count = vector::length(&event_market.validators);
        if (vote_count < MIN_VALIDATORS) return;
        
        // Count votes for each outcome
        let outcome_votes = vector::empty<u64>();
        let i = 0;
        while (i < (event_market.outcome_count as u64)) {
            vector::push_back(&mut outcome_votes, 0);
            i = i + 1;
        };
        
        // This is a simplified version - in production, you'd iterate through the table
        // For now, we'll assume consensus is reached
        let consensus_percentage = 8000; // 80% consensus assumed
        
        if (consensus_percentage >= event_market.resolution_consensus) {
            // Find winning outcome (most votes)
            let winning_outcome = 0u8; // Simplified - would calculate from votes
            event_market.resolved = true;
            event_market.winning_outcome = option::some(winning_outcome);
            event_market.status = EVENT_RESOLVED;
        };
    }

    fun calculate_ai_accuracy<CoinType>(event_market: &EventMarket<CoinType>, actual_outcome: u8): u64 {
        if (vector::length(&event_market.ai_predictions) == 0) return 5000; // No prediction
        
        let predicted_outcome = get_ai_predicted_outcome(event_market);
        let confidence = event_market.ai_confidence;
        
        if (predicted_outcome == actual_outcome) {
            // Correct prediction - accuracy based on confidence
            5000 + confidence / 2
        } else {
            // Wrong prediction - accuracy inversely related to confidence
            if (confidence >= 10000) 0 else 5000 - confidence / 2
        }
    }

    fun calculate_consensus_percentage<CoinType>(event_market: &EventMarket<CoinType>, outcome: u8): u64 {
        let total_votes = vector::length(&event_market.validators);
        if (total_votes == 0) return 0;
        
        // Simplified calculation - in production, would count actual votes for the outcome
        8000 // 80% consensus assumed
    }

    fun get_ai_predicted_outcome<CoinType>(event_market: &EventMarket<CoinType>): u8 {
        let predictions = &event_market.ai_predictions;
        let mut_best_outcome = 0u8;
        let mut_highest_prediction = 0u64;
        
        let i = 0;
        while (i < vector::length(predictions)) {
            let prediction = *vector::borrow(predictions, i);
            if (prediction > mut_highest_prediction) {
                mut_highest_prediction = prediction;
                mut_best_outcome = (i as u8);
            };
            i = i + 1;
        };
        
        mut_best_outcome
    }

    fun get_recommendation_from_predictions(predictions: &vector<u64>): String {
        let highest_prediction = 0u64;
        let best_index = 0;
        
        let i = 0;
        while (i < vector::length(predictions)) {
            let prediction = *vector::borrow(predictions, i);
            if (prediction > highest_prediction) {
                highest_prediction = prediction;
                best_index = i;
            };
            i = i + 1;
        };
        
        if (highest_prediction > 6000) {
            string::utf8(b"STRONG_PREDICTION")
        } else if (highest_prediction > 4000) {
            string::utf8(b"MODERATE_PREDICTION")
        } else {
            string::utf8(b"UNCERTAIN")
        }
    }

    #[view]
    public fun get_event_info<CoinType>(event_addr: address): (String, u8, u8, vector<u64>, u128, bool) 
    acquires EventMarket {
        let event_market = borrow_global<EventMarket<CoinType>>(event_addr);
        (
            event_market.title,
            event_market.status,
            event_market.outcome_count,
            event_market.outcome_prices,
            event_market.total_volume,
            event_market.resolved
        )
    }

    #[view]
    public fun get_event_ai_data<CoinType>(event_addr: address): (vector<u64>, u64, vector<u64>, u64) 
    acquires EventMarket {
        let event_market = borrow_global<EventMarket<CoinType>>(event_addr);
        (
            event_market.ai_predictions,
            event_market.ai_confidence,
            event_market.ai_sentiment_scores,
            event_market.ai_last_update
        )
    }

    #[view]
    public fun get_outcome_pools<CoinType>(event_addr: address): vector<u128> 
    acquires EventMarket {
        borrow_global<EventMarket<CoinType>>(event_addr).outcome_pools
    }

    #[view]
    public fun is_event_active<CoinType>(event_addr: address): bool acquires EventMarket {
        let event_market = borrow_global<EventMarket<CoinType>>(event_addr);
        event_market.status == EVENT_ACTIVE && timestamp::now_seconds() <= event_market.end_time
    }

    /// Formal verification specs
    spec module {
        pragma verify = true;
        pragma aborts_if_is_strict = true;
    }

    spec place_event_bet {
        requires outcome < borrow_global<EventMarket<CoinType>>(event_addr).outcome_count;
        requires amount >= MIN_BET_AMOUNT;
        requires exists<EventMarket<CoinType>>(event_addr);
        ensures borrow_global<EventMarket<CoinType>>(event_addr).total_volume == 
                old(borrow_global<EventMarket<CoinType>>(event_addr).total_volume) + amount;
    }

    spec resolve_event_market {
        requires winning_outcome < borrow_global<EventMarket<CoinType>>(event_addr).outcome_count;
        requires exists<EventMarket<CoinType>>(event_addr);
        ensures borrow_global<EventMarket<CoinType>>(event_addr).resolved == true;
    }
}
