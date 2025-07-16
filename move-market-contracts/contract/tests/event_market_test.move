#[test_only]
module aptos_markets::event_market_test {
    #[test_only]
    use std::string::{Self, String};
    #[test_only]
    use std::option;
    #[test_only]
    use std::vector;
    #[test_only]
    use std::signer;
    #[test_only]
    use aptos_framework::account;
    #[test_only]
    use aptos_framework::timestamp;
    #[test_only]
    use aptos_framework::aptos_coin::{Self, AptosCoin};
    #[test_only]
    use aptos_framework::coin;
    #[test_only]
    use aptos_framework::aptos_account;
    #[test_only]
    use aptos_framework::object;
    #[test_only]
    use aptos_markets::marketplace;
    #[test_only]
    use aptos_markets::event_market;

    // Test helper functions
    #[test_only]
    fun setup_test_env(aptos_framework: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
    }

    #[test_only]
    fun create_test_accounts(admin: &signer, user1: &signer, user2: &signer) {
        account::create_account_for_test(signer::address_of(admin));
        account::create_account_for_test(signer::address_of(user1));
        account::create_account_for_test(signer::address_of(user2));
    }

    #[test_only]
    fun init_marketplace(admin: &signer): address {
        // Legacy wrapper - just initialize global resources
        marketplace::init_for_test(admin);
        
        let name = string::utf8(b"Test Marketplace");
        let description = string::utf8(b"Test marketplace for event markets");
        let oracle_feed = @0x1234;
        let fee_rate = 250;
        let daily_volume_limit = 1000000000000u128;
        let ai_enabled = true;

        marketplace::create_marketplace<AptosCoin>(
            admin,
            name,
            description,
            oracle_feed,
            fee_rate,
            daily_volume_limit,
            ai_enabled
        );

        marketplace::get_marketplace_address<AptosCoin>()
    }

    #[test_only]
    fun init_marketplace_with_aptos_coin(aptos_framework: &signer, admin: &signer): (address, coin::BurnCapability<AptosCoin>, coin::MintCapability<AptosCoin>) {
        // Initialize AptosCoin AND global resources
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        marketplace::init_for_test(admin);
        
        let name = string::utf8(b"Test Marketplace");
        let description = string::utf8(b"Test marketplace for event markets");
        let oracle_feed = @0x1234;
        let fee_rate = 250;
        let daily_volume_limit = 1000000000000u128;
        let ai_enabled = true;

        marketplace::create_marketplace<AptosCoin>(
            admin,
            name,
            description,
            oracle_feed,
            fee_rate,
            daily_volume_limit,
            ai_enabled
        );

        let marketplace_addr = marketplace::get_marketplace_address<AptosCoin>();
        (marketplace_addr, burn_cap, mint_cap)
    }

    #[test_only]
    fun init_coins_for_users(aptos_framework: &signer, user1: &signer, user2: &signer) {
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        let coins1 = coin::mint<AptosCoin>(1000000000, &mint_cap); // 10 APT
        let coins2 = coin::mint<AptosCoin>(2000000000, &mint_cap); // 20 APT
        
        aptos_account::deposit_coins(signer::address_of(user1), coins1);
        aptos_account::deposit_coins(signer::address_of(user2), coins2);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @aptos_framework, admin = @aptos_markets, user1 = @0x200)]
    fun test_create_event_market_success(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user1);
        let (marketplace_addr, burn_cap, mint_cap) = init_marketplace_with_aptos_coin(aptos_framework, admin);
        
        // Mint coins for users using the already-initialized capabilities
        let coins1 = coin::mint<AptosCoin>(1000000000, &mint_cap); // 10 APT
        aptos_account::deposit_coins(signer::address_of(user1), coins1);

        let title = string::utf8(b"Who will win the election?");
        let description = string::utf8(b"Multi-outcome prediction market for election results");
        let category = string::utf8(b"politics");
        let outcome_names = vector::empty<String>();
        vector::push_back(&mut outcome_names, string::utf8(b"Candidate A"));
        vector::push_back(&mut outcome_names, string::utf8(b"Candidate B"));
        vector::push_back(&mut outcome_names, string::utf8(b"Candidate C"));

        let current_time = timestamp::now_seconds();
        let start_time = current_time + 3600; // 1 hour from now
        let end_time = start_time + 86400; // 24 hours market duration
        let resolution_deadline = end_time + 7200; // 2 hours to resolve
        let initial_liquidity = 100000000; // 1 APT

        event_market::create_event_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            outcome_names,
            start_time,
            end_time,
            resolution_deadline,
            initial_liquidity
        );

        // Verify the event market was created
        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        assert!(vector::length(&active_markets) == 1, 1);
        
        let event_addr = *vector::borrow(&active_markets, 0);
        let (event_title, status, outcome_count, outcome_prices, total_vol, is_resolved) = 
            event_market::get_event_info<AptosCoin>(event_addr);
        
        assert!(event_title == title, 2);
        assert!(status == 0, 3); // EVENT_PENDING
        assert!(outcome_count == 3, 4); // Three candidates
        assert!(vector::length(&outcome_prices) == 3, 5);
        assert!(total_vol == 0, 6); // No bets yet
        assert!(is_resolved == false, 7);
        
        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[expected_failure(abort_code = event_market::E_EVENT_NOT_STARTED)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200)]
    fun test_create_event_market_invalid_start_time(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user1);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user1);

        let title = string::utf8(b"Invalid Time Event");
        let description = string::utf8(b"Testing invalid timing");
        let category = string::utf8(b"test");
        let outcome_names = vector::empty<String>();
        vector::push_back(&mut outcome_names, string::utf8(b"Yes"));
        vector::push_back(&mut outcome_names, string::utf8(b"No"));

        let current_time = timestamp::now_seconds();
        let start_time = current_time - 1; // Invalid: in the past
        let end_time = current_time + 86400;
        let resolution_deadline = end_time + 7200;
        let initial_liquidity = 100000000;

        event_market::create_event_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            outcome_names,
            start_time,
            end_time,
            resolution_deadline,
            initial_liquidity
        );
    }

    #[expected_failure(abort_code = event_market::E_EVENT_ENDED)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200)]
    fun test_create_event_market_invalid_end_time(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user1);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user1);

        let title = string::utf8(b"Invalid End Time Event");
        let description = string::utf8(b"Testing invalid end time");
        let category = string::utf8(b"test");
        let outcome_names = vector::empty<String>();
        vector::push_back(&mut outcome_names, string::utf8(b"Yes"));
        vector::push_back(&mut outcome_names, string::utf8(b"No"));

        let current_time = timestamp::now_seconds();
        let start_time = current_time + 3600;
        let end_time = start_time - 1; // Invalid: before start time
        let resolution_deadline = end_time + 7200;
        let initial_liquidity = 100000000;

        event_market::create_event_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            outcome_names,
            start_time,
            end_time,
            resolution_deadline,
            initial_liquidity
        );
    }

    #[expected_failure(abort_code = event_market::E_INVALID_OUTCOME_COUNT)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200)]
    fun test_create_event_market_invalid_outcome_count(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user1);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user1);

        let title = string::utf8(b"Invalid Outcomes");
        let description = string::utf8(b"Testing invalid outcome count");
        let category = string::utf8(b"test");
        let outcome_names = vector::empty<String>(); // Empty - invalid

        let current_time = timestamp::now_seconds();
        let start_time = current_time + 3600;
        let end_time = start_time + 86400;
        let resolution_deadline = end_time + 7200;
        let initial_liquidity = 100000000;

        event_market::create_event_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            outcome_names,
            start_time,
            end_time,
            resolution_deadline,
            initial_liquidity
        );
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200)]
    fun test_start_event_market(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user1);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user1);

        let title = string::utf8(b"Sports Match Outcome");
        let description = string::utf8(b"Who will win the match?");
        let category = string::utf8(b"sports");
        let outcome_names = vector::empty<String>();
        vector::push_back(&mut outcome_names, string::utf8(b"Team A"));
        vector::push_back(&mut outcome_names, string::utf8(b"Team B"));
        vector::push_back(&mut outcome_names, string::utf8(b"Draw"));

        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100; // Soon
        let end_time = start_time + 86400;
        let resolution_deadline = end_time + 7200;
        let initial_liquidity = 100000000;

        event_market::create_event_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            outcome_names,
            start_time,
            end_time,
            resolution_deadline,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let event_addr = *vector::borrow(&active_markets, 0);

        // Fast forward to start time
        timestamp::fast_forward_seconds(100);

        // Start the event market
        event_market::start_event_market<AptosCoin>(user1, event_addr);

        // Verify event market is now active
        let (_, status, _, _, _, _) = event_market::get_event_info<AptosCoin>(event_addr);
        assert!(status == 1, 1); // EVENT_ACTIVE
        assert!(event_market::is_event_active<AptosCoin>(event_addr), 2);
    }

    #[expected_failure(abort_code = event_market::E_NOT_AUTHORIZED)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_start_event_market_unauthorized(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user2);

        let title = string::utf8(b"Unauthorized Test");
        let description = string::utf8(b"Testing unauthorized start");
        let category = string::utf8(b"test");
        let outcome_names = vector::empty<String>();
        vector::push_back(&mut outcome_names, string::utf8(b"Yes"));
        vector::push_back(&mut outcome_names, string::utf8(b"No"));

        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 86400;
        let resolution_deadline = end_time + 7200;
        let initial_liquidity = 100000000;

        event_market::create_event_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            outcome_names,
            start_time,
            end_time,
            resolution_deadline,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let event_addr = *vector::borrow(&active_markets, 0);

        timestamp::fast_forward_seconds(100);

        // Try to start event with wrong user - should fail
        event_market::start_event_market<AptosCoin>(user2, event_addr);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_place_event_bet_success(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user2);

        // Create and start event market
        let title = string::utf8(b"Crypto Price Prediction");
        let description = string::utf8(b"Which crypto will perform best?");
        let category = string::utf8(b"crypto");
        let outcome_names = vector::empty<String>();
        vector::push_back(&mut outcome_names, string::utf8(b"Bitcoin"));
        vector::push_back(&mut outcome_names, string::utf8(b"Ethereum"));
        vector::push_back(&mut outcome_names, string::utf8(b"Aptos"));

        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 86400;
        let resolution_deadline = end_time + 7200;
        let initial_liquidity = 100000000;

        event_market::create_event_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            outcome_names,
            start_time,
            end_time,
            resolution_deadline,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let event_addr = *vector::borrow(&active_markets, 0);

        timestamp::fast_forward_seconds(100);
        event_market::start_event_market<AptosCoin>(user1, event_addr);

        // Place bets on different outcomes
        let bet_amount = 50000000; // 0.5 APT
        event_market::place_event_bet<AptosCoin>(user1, event_addr, 0, bet_amount); // Bitcoin
        event_market::place_event_bet<AptosCoin>(user2, event_addr, 2, bet_amount); // Aptos

        // Check outcome pools
        let outcome_pools = event_market::get_outcome_pools<AptosCoin>(event_addr);
        assert!(vector::length(&outcome_pools) == 3, 1);
        assert!(*vector::borrow(&outcome_pools, 0) == (bet_amount as u128), 2); // Bitcoin pool
        assert!(*vector::borrow(&outcome_pools, 1) == 0, 3); // Ethereum pool (empty)
        assert!(*vector::borrow(&outcome_pools, 2) == (bet_amount as u128), 4); // Aptos pool

        // Check total volume
        let (_, _, _, _, total_vol, _) = event_market::get_event_info<AptosCoin>(event_addr);
        assert!(total_vol == (bet_amount * 2 as u128), 5);

        // Check user balances decreased
        assert!(coin::balance<AptosCoin>(signer::address_of(user1)) < 1000000000, 6);
        assert!(coin::balance<AptosCoin>(signer::address_of(user2)) < 2000000000, 7);
    }

    #[expected_failure(abort_code = event_market::E_EVENT_NOT_STARTED)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_place_bet_event_not_active(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user2);

        // Create event market but don't start it
        let title = string::utf8(b"Inactive Event");
        let description = string::utf8(b"Testing inactive event betting");
        let category = string::utf8(b"test");
        let outcome_names = vector::empty<String>();
        vector::push_back(&mut outcome_names, string::utf8(b"Yes"));
        vector::push_back(&mut outcome_names, string::utf8(b"No"));

        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 86400;
        let resolution_deadline = end_time + 7200;
        let initial_liquidity = 100000000;

        event_market::create_event_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            outcome_names,
            start_time,
            end_time,
            resolution_deadline,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let event_addr = *vector::borrow(&active_markets, 0);

        // Try to bet on inactive event - should fail
        let bet_amount = 50000000;
        event_market::place_event_bet<AptosCoin>(user2, event_addr, 0, bet_amount);
    }

    #[expected_failure(abort_code = event_market::E_INVALID_OUTCOME)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_place_bet_invalid_outcome(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user2);

        // Create and start event market
        let title = string::utf8(b"Binary Event");
        let description = string::utf8(b"Simple yes/no event");
        let category = string::utf8(b"test");
        let outcome_names = vector::empty<String>();
        vector::push_back(&mut outcome_names, string::utf8(b"Yes"));
        vector::push_back(&mut outcome_names, string::utf8(b"No"));

        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 86400;
        let resolution_deadline = end_time + 7200;
        let initial_liquidity = 100000000;

        event_market::create_event_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            outcome_names,
            start_time,
            end_time,
            resolution_deadline,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let event_addr = *vector::borrow(&active_markets, 0);

        timestamp::fast_forward_seconds(100);
        event_market::start_event_market<AptosCoin>(user1, event_addr);

        // Try to bet on invalid outcome (only 0 and 1 are valid) - should fail
        let bet_amount = 50000000;
        event_market::place_event_bet<AptosCoin>(user2, event_addr, 2, bet_amount);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_event_market_governance(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user2);

        // Create, start, and bet on event market
        let title = string::utf8(b"Governance Test Event");
        let description = string::utf8(b"Testing governance features");
        let category = string::utf8(b"governance");
        let outcome_names = vector::empty<String>();
        vector::push_back(&mut outcome_names, string::utf8(b"Option A"));
        vector::push_back(&mut outcome_names, string::utf8(b"Option B"));

        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 1000; // Short event for testing
        let resolution_deadline = end_time + 1000;
        let initial_liquidity = 100000000;

        event_market::create_event_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            outcome_names,
            start_time,
            end_time,
            resolution_deadline,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let event_addr = *vector::borrow(&active_markets, 0);

        timestamp::fast_forward_seconds(100);
        event_market::start_event_market<AptosCoin>(user1, event_addr);

        // Place bets
        let bet_amount = 50000000;
        event_market::place_event_bet<AptosCoin>(user1, event_addr, 0, bet_amount); // Option A
        event_market::place_event_bet<AptosCoin>(user2, event_addr, 1, bet_amount); // Option B

        // Add validators for governance
        let stake_amount = 10000000; // 0.1 APT stake
        event_market::add_validator<AptosCoin>(admin, event_addr, signer::address_of(admin), stake_amount);
        event_market::add_validator<AptosCoin>(admin, event_addr, signer::address_of(user1), stake_amount);

        // Fast forward past event end time
        timestamp::fast_forward_seconds(1000);

        // Validators can vote on the outcome
        event_market::submit_validator_vote<AptosCoin>(admin, event_addr, 0); // Vote for Option A
        event_market::submit_validator_vote<AptosCoin>(user1, event_addr, 0); // Vote for Option A

        // Fast forward past resolution deadline
        timestamp::fast_forward_seconds(1000);

        // Resolve event market - Option A wins (outcome 0)
        let resolution_source = string::utf8(b"Validator consensus");
        event_market::resolve_event_market<AptosCoin>(admin, event_addr, 0, resolution_source);

        // Check event is resolved
        let (_, _, _, _, _, is_resolved) = event_market::get_event_info<AptosCoin>(event_addr);
        assert!(is_resolved == true, 1);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200)]
    fun test_event_ai_data(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user1);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user1);

        // Create event market
        let title = string::utf8(b"AI Enhanced Event");
        let description = string::utf8(b"Testing AI features");
        let category = string::utf8(b"ai");
        let outcome_names = vector::empty<String>();
        vector::push_back(&mut outcome_names, string::utf8(b"Outcome 1"));
        vector::push_back(&mut outcome_names, string::utf8(b"Outcome 2"));
        vector::push_back(&mut outcome_names, string::utf8(b"Outcome 3"));

        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 86400;
        let resolution_deadline = end_time + 7200;
        let initial_liquidity = 100000000;

        event_market::create_event_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            outcome_names,
            start_time,
            end_time,
            resolution_deadline,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let event_addr = *vector::borrow(&active_markets, 0);

        // Check initial AI data
        let (predictions, confidence, sentiment_scores, last_update) = 
            event_market::get_event_ai_data<AptosCoin>(event_addr);
        
        assert!(vector::length(&predictions) == 3, 1); // One prediction per outcome
        assert!(confidence == 0, 2); // No confidence initially
        assert!(vector::length(&sentiment_scores) == 3, 3); // One sentiment per outcome
        assert!(last_update == current_time, 4);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200)]
    fun test_event_view_functions(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user1);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user1);

        let title = string::utf8(b"View Functions Test");
        let description = string::utf8(b"Testing all view functions");
        let category = string::utf8(b"test");
        let outcome_names = vector::empty<String>();
        vector::push_back(&mut outcome_names, string::utf8(b"Red"));
        vector::push_back(&mut outcome_names, string::utf8(b"Blue"));
        vector::push_back(&mut outcome_names, string::utf8(b"Green"));

        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 86400;
        let resolution_deadline = end_time + 7200;
        let initial_liquidity = 100000000;

        event_market::create_event_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            outcome_names,
            start_time,
            end_time,
            resolution_deadline,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let event_addr = *vector::borrow(&active_markets, 0);

        // Test all view functions
        let (event_title, status, outcome_count, outcome_prices, total_vol, is_resolved) = 
            event_market::get_event_info<AptosCoin>(event_addr);
        
        assert!(event_title == title, 1);
        assert!(status == 0, 2); // EVENT_PENDING
        assert!(outcome_count == 3, 3);
        assert!(vector::length(&outcome_prices) == 3, 4);
        assert!(total_vol == 0, 5);
        assert!(is_resolved == false, 6);

        let outcome_pools = event_market::get_outcome_pools<AptosCoin>(event_addr);
        assert!(vector::length(&outcome_pools) == 3, 7);
        assert!(*vector::borrow(&outcome_pools, 0) == 0, 8);
        assert!(*vector::borrow(&outcome_pools, 1) == 0, 9);
        assert!(*vector::borrow(&outcome_pools, 2) == 0, 10);

        assert!(event_market::is_event_active<AptosCoin>(event_addr) == false, 11); // Not started yet
    }
}
