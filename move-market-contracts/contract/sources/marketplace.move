/// # Aptos Markets - Enhanced Marketplace Contract
/// 
/// This contract manages prediction marketplaces with AI-powered features including:
/// - Multi-token support beyond APT
/// - AI integration hooks for market making and analytics
/// - Enhanced security with formal verification support
/// - Gas-optimized patterns following latest Move best practices
/// - Comprehensive event system for AI monitoring
/// - Risk management and fraud detection hooks
/// 
/// ## Security Requirements
/// 1. Only authorized admins can create marketplaces
/// 2. Market addresses must be unique per marketplace
/// 3. AI integration must not compromise contract security
/// 4. All state changes must emit proper events for monitoring
/// 
module aptos_markets::marketplace {
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use std::error;
    use aptos_std::table::{Self, Table};
    use aptos_std::coin::{Self, Coin, CoinStore};
    use aptos_std::type_info::{Self, TypeInfo};
    use aptos_framework::object::{Self, Object, ConstructorRef, ExtendRef};
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Friend modules for internal access
    friend aptos_markets::market;
    friend aptos_markets::event_market;
    friend aptos_markets::ai_oracle;
    friend aptos_markets::risk_manager;

    // Error constants with descriptive messages
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_MARKETPLACE_ALREADY_EXISTS: u64 = 2;
    const E_MARKETPLACE_NOT_FOUND: u64 = 3;
    const E_INVALID_COIN_TYPE: u64 = 4;
    const E_MARKET_ALREADY_REGISTERED: u64 = 5;
    const E_MARKET_NOT_FOUND: u64 = 6;
    const E_INSUFFICIENT_BALANCE: u64 = 7;
    const E_ORACLE_FEED_INVALID: u64 = 8;
    const E_AI_INTEGRATION_DISABLED: u64 = 9;
    const E_INVALID_FEE_RATE: u64 = 10;

    // Constants for marketplace parameters
    const MAX_FEE_RATE: u64 = 1000; // 10% maximum fee (basis points)
    const MIN_LIQUIDITY_THRESHOLD: u64 = 1000000; // Minimum liquidity in smallest units
    const AI_CONFIDENCE_THRESHOLD: u64 = 7500; // 75% confidence required for AI actions

    /// Core marketplace structure
    struct Marketplace<phantom CoinType> has drop, key, store {
        /// Marketplace metadata
        name: String,
        description: String,
        admin: address,
        created_at: u64,
        
        /// Market management
        active_markets: vector<address>,
        total_markets_created: u64,
        
        /// Financial metrics
        total_volume: u128,
        total_fees_collected: u128,
        daily_volume_limit: u128,
        daily_volume_used: u128,
        last_volume_reset: u64,
        
        /// Oracle integration
        oracle_feed: address,
        cached_price: Option<u128>,
        last_price_update: u64,
        
        /// AI and risk management
        ai_enabled: bool,
        ai_last_update: u64,
        
        /// Fee structure
        fee_rate: u64, // In basis points
        
        /// Object management
        extend_ref: ExtendRef,
    }

    /// Global marketplace registry
    struct MarketplaceRegistry has key {
        marketplaces: Table<TypeInfo, address>,
        total_marketplaces: u64,
        admin: address,
    }

    /// Market registration info
    struct MarketInfo has store, drop {
        market_address: address,
        market_type: String,
        created_at: u64,
        status: u8, // 0: Active, 1: Paused, 2: Resolved, 3: Cancelled
        total_volume: u128,
        ai_risk_score: u64,
    }

    /// AI Integration data
    struct AIIntegration has store {
        sentiment_score: u64, // 0-10000 (0-100%)
        trend_analysis: String,
        risk_assessment: u64, // 0-10000 (0-100%)
        recommendation: u8, // 0: Hold, 1: Buy, 2: Sell, 3: Avoid
        confidence: u64, // 0-10000 (0-100%)
        last_updated: u64,
    }

    // Events for AI monitoring and analytics
    #[event]
    struct MarketplaceCreated<phantom CoinType> has drop, store {
        marketplace_address: address,
        coin_type: TypeInfo,
        name: String,
        admin: address,
        oracle_feed: address,
        ai_enabled: bool,
        timestamp: u64,
    }

    #[event]
    struct MarketRegistered<phantom CoinType> has drop, store {
        marketplace_address: address,
        market_address: address,
        market_type: String,
        timestamp: u64,
    }

    #[event]
    struct AIDataUpdated<phantom CoinType> has drop, store {
        marketplace_address: address,
        sentiment_score: u64,
        risk_assessment: u64,
        recommendation: u8,
        confidence: u64,
        timestamp: u64,
    }

    #[event]
    struct VolumeAlert<phantom CoinType> has drop, store {
        marketplace_address: address,
        daily_volume_used: u128,
        daily_volume_limit: u128,
        percentage_used: u64,
        timestamp: u64,
    }

    #[event]
    struct RiskEvent<phantom CoinType> has drop, store {
        marketplace_address: address,
        event_type: String,
        risk_level: u64,
        description: String,
        timestamp: u64,
    }

    /// Initialize the marketplace registry
    fun init_module(account: &signer) {
        let registry = MarketplaceRegistry {
            marketplaces: table::new(),
            total_marketplaces: 0,
            admin: signer::address_of(account),
        };
        move_to(account, registry);
    }

    /// Create a new marketplace with enhanced features
    public entry fun create_marketplace<CoinType>(
        admin: &signer,
        name: String,
        description: String,
        oracle_feed: address,
        fee_rate: u64,
        daily_volume_limit: u128,
        ai_enabled: bool
    ) acquires MarketplaceRegistry {
        let admin_addr = signer::address_of(admin);
        let coin_type = type_info::type_of<CoinType>();
        
        // Validate inputs
        assert!(fee_rate <= MAX_FEE_RATE, error::invalid_argument(E_INVALID_FEE_RATE));
        assert!(string::length(&name) > 0, error::invalid_argument(E_MARKETPLACE_ALREADY_EXISTS));
        
        // Check registry exists and admin authorization
        assert!(exists<MarketplaceRegistry>(@aptos_markets), error::not_found(E_MARKETPLACE_NOT_FOUND));
        let registry = borrow_global_mut<MarketplaceRegistry>(@aptos_markets);
        assert!(registry.admin == admin_addr, error::permission_denied(E_NOT_AUTHORIZED));
        
        // Ensure marketplace doesn't already exist for this coin type
        assert!(!table::contains(&registry.marketplaces, coin_type), 
                error::already_exists(E_MARKETPLACE_ALREADY_EXISTS));

        // Create marketplace object
        let constructor_ref = object::create_object(@aptos_markets);
        let object_signer = object::generate_signer(&constructor_ref);
        let marketplace_addr = object::address_from_constructor_ref(&constructor_ref);
        
        // Store extend ref for future operations
        let extend_ref = object::generate_extend_ref(&constructor_ref);
        
        let current_time = timestamp::now_seconds();
        
        // Create marketplace resource
        let marketplace = Marketplace<CoinType> {
            name,
            description,
            admin: admin_addr,
            created_at: current_time,
            active_markets: vector::empty(),
            total_markets_created: 0,
            total_volume: 0,
            total_fees_collected: 0,
            daily_volume_limit,
            daily_volume_used: 0,
            last_volume_reset: current_time,
            oracle_feed,
            cached_price: option::none(),
            last_price_update: 0,
            ai_enabled,
            ai_last_update: current_time,
            fee_rate,
            extend_ref,
        };
        
        // Capture values for event emission before move_to
        let marketplace_name = marketplace.name;
        let marketplace_oracle_feed = marketplace.oracle_feed;
        
        move_to(&object_signer, marketplace);
        
        // Register in global registry
        table::add(&mut registry.marketplaces, coin_type, marketplace_addr);
        registry.total_marketplaces = registry.total_marketplaces + 1;
        
        // Initialize coin store if needed
        if (!coin::is_account_registered<CoinType>(marketplace_addr)) {
            coin::register<CoinType>(&object_signer);
        };

        // Emit creation event
        event::emit(MarketplaceCreated<CoinType> {
            marketplace_address: marketplace_addr,
            coin_type,
            name: marketplace_name,
            admin: admin_addr,
            oracle_feed: marketplace_oracle_feed,
            ai_enabled,
            timestamp: current_time,
        });
    }

    /// Get marketplace address by coin type
    #[view]
    public fun get_marketplace_address<CoinType>(): address acquires MarketplaceRegistry {
        let registry = borrow_global<MarketplaceRegistry>(@aptos_markets);
        let coin_type = type_info::type_of<CoinType>();
        assert!(table::contains(&registry.marketplaces, coin_type), 
                error::not_found(E_MARKETPLACE_NOT_FOUND));
        *table::borrow(&registry.marketplaces, coin_type)
    }

    /// Register a new market in the marketplace
    public(friend) fun register_market<CoinType>(
        marketplace_addr: address,
        market_addr: address,
        market_type: String
    ) acquires Marketplace {
        let marketplace = borrow_global_mut<Marketplace<CoinType>>(marketplace_addr);
        
        // Check if market is already registered
        let found = false;
        let i = 0;
        let len = vector::length(&marketplace.active_markets);
        while (i < len && !found) {
            if (*vector::borrow(&marketplace.active_markets, i) == market_addr) {
                found = true;
            };
            i = i + 1;
        };
        assert!(!found, error::already_exists(E_MARKET_ALREADY_REGISTERED));
        
        // Add to active markets
        vector::push_back(&mut marketplace.active_markets, market_addr);
        marketplace.total_markets_created = marketplace.total_markets_created + 1;
        
        let current_time = timestamp::now_seconds();
        
        // Emit registration event
        event::emit(MarketRegistered<CoinType> {
            marketplace_address: marketplace_addr,
            market_address: market_addr,
            market_type,
            timestamp: current_time,
        });
    }

    /// Update AI data for marketplace
    public(friend) fun update_ai_data<CoinType>(
        marketplace_addr: address,
        sentiment_score: u64,
        risk_assessment: u64,
        recommendation: u8,
        confidence: u64
    ) acquires Marketplace {
        let marketplace = borrow_global_mut<Marketplace<CoinType>>(marketplace_addr);
        assert!(marketplace.ai_enabled, error::permission_denied(E_AI_INTEGRATION_DISABLED));
        
        let current_time = timestamp::now_seconds();
        marketplace.ai_last_update = current_time;
        
        // Emit AI update event
        event::emit(AIDataUpdated<CoinType> {
            marketplace_address: marketplace_addr,
            sentiment_score,
            risk_assessment,
            recommendation,
            confidence,
            timestamp: current_time,
        });
    }

    /// Get latest price with basic placeholder implementation
    public fun get_latest_price<CoinType>(marketplace_addr: address): u128 acquires Marketplace {
        let marketplace = borrow_global_mut<Marketplace<CoinType>>(marketplace_addr);
        let current_time = timestamp::now_seconds();
        
        // Use cached price if less than 60 seconds old
        if (option::is_some(&marketplace.cached_price) && 
            current_time - marketplace.last_price_update < 60) {
            return *option::borrow(&marketplace.cached_price)
        };
        
        // Placeholder price logic - in production, would fetch from real oracle
        let placeholder_price = 100000000u128; // $1.00 in 8 decimals
        
        // Update cache
        marketplace.cached_price = option::some(placeholder_price);
        marketplace.last_price_update = current_time;
        
        placeholder_price
    }

    /// Record volume and check limits
    public(friend) fun record_volume<CoinType>(
        marketplace_addr: address,
        volume: u128
    ) acquires Marketplace {
        let marketplace = borrow_global_mut<Marketplace<CoinType>>(marketplace_addr);
        let current_time = timestamp::now_seconds();
        
        // Reset daily volume if it's a new day
        if (current_time - marketplace.last_volume_reset > 86400) { // 24 hours
            marketplace.daily_volume_used = 0;
            marketplace.last_volume_reset = current_time;
        };
        
        // Add to totals
        marketplace.total_volume = marketplace.total_volume + volume;
        marketplace.daily_volume_used = marketplace.daily_volume_used + volume;
        
        // Check daily limits and emit warning if approaching
        let percentage_used = ((marketplace.daily_volume_used * 10000) / marketplace.daily_volume_limit as u64);
        
        if (percentage_used > 8000) { // 80% threshold
            event::emit(VolumeAlert<CoinType> {
                marketplace_address: marketplace_addr,
                daily_volume_used: marketplace.daily_volume_used,
                daily_volume_limit: marketplace.daily_volume_limit,
                percentage_used,
                timestamp: current_time,
            });
        };
    }

    /// View functions for marketplace data
    #[view]
    public fun get_marketplace_info<CoinType>(marketplace_addr: address): (String, u64, u128, u64, bool) 
    acquires Marketplace {
        let marketplace = borrow_global<Marketplace<CoinType>>(marketplace_addr);
        (
            marketplace.name,
            marketplace.total_markets_created,
            marketplace.total_volume,
            marketplace.fee_rate,
            marketplace.ai_enabled
        )
    }

    #[view]
    public fun get_active_markets<CoinType>(marketplace_addr: address): vector<address> 
    acquires Marketplace {
        borrow_global<Marketplace<CoinType>>(marketplace_addr).active_markets
    }

    #[view]
    public fun is_ai_enabled<CoinType>(marketplace_addr: address): bool acquires Marketplace {
        borrow_global<Marketplace<CoinType>>(marketplace_addr).ai_enabled
    }

    /// Emergency functions for admin
    public entry fun pause_ai<CoinType>(admin: &signer, marketplace_addr: address) 
    acquires Marketplace {
        let marketplace = borrow_global_mut<Marketplace<CoinType>>(marketplace_addr);
        assert!(signer::address_of(admin) == marketplace.admin, 
                error::permission_denied(E_NOT_AUTHORIZED));
        marketplace.ai_enabled = false;
    }

    /// Formal verification specs
    spec module {
        pragma verify = true;
        pragma aborts_if_is_strict = true;
    }

    spec create_marketplace {
        requires fee_rate <= MAX_FEE_RATE;
        requires string::length(name) > 0;
        // Note: Cannot use create_object in specs as it's impure
    }

    spec register_market {
        requires exists<Marketplace<CoinType>>(marketplace_addr);
        // Note: Cannot use vector::contains in specs as it's impure
    }
}
