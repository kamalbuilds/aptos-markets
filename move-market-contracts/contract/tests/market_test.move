#[test_only]
module aptos_markets::market_test {
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
    use aptos_markets::market;

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
        let name = string::utf8(b"Test Marketplace");
        let description = string::utf8(b"Test marketplace for markets");
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
    fun init_coins_for_users(aptos_framework: &signer, user1: &signer, user2: &signer) {
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        let coins1 = coin::mint<AptosCoin>(1000000000, &mint_cap); // 10 APT
        let coins2 = coin::mint<AptosCoin>(2000000000, &mint_cap); // 20 APT
        
        aptos_account::deposit_coins(signer::address_of(user1), coins1);
        aptos_account::deposit_coins(signer::address_of(user2), coins2);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200)]
    fun test_create_market_success(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user1);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user1);

        let title = string::utf8(b"Will APT reach $10?");
        let description = string::utf8(b"Prediction market for APT price target");
        let category = string::utf8(b"crypto");
        let current_time = timestamp::now_seconds();
        let start_time = current_time + 3600; // 1 hour from now
        let end_time = start_time + 86400; // 24 hours market duration
        let initial_liquidity = 100000000; // 1 APT

        market::create_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            start_time,
            end_time,
            initial_liquidity
        );

        // Verify the market was created
        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        assert!(vector::length(&active_markets) == 1, 1);
        
        let market_addr = *vector::borrow(&active_markets, 0);
        let (market_title, status, created_time, end_timestamp, total_vol, is_resolved) = 
            market::get_market_info<AptosCoin>(market_addr);
        
        assert!(market_title == title, 2);
        assert!(status == 0, 3); // MARKET_PENDING
        assert!(created_time == current_time, 4);
        assert!(end_timestamp == end_time, 5);
        assert!(total_vol == 0, 6); // No bets yet
        assert!(is_resolved == false, 7);
    }

    #[expected_failure(abort_code = market::E_MARKET_NOT_STARTED)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200)]
    fun test_create_market_invalid_start_time(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user1);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user1);

        let title = string::utf8(b"Will APT reach $10?");
        let description = string::utf8(b"Prediction market for APT price target");
        let category = string::utf8(b"crypto");
        let current_time = timestamp::now_seconds();
        let start_time = current_time - 1; // Invalid: in the past
        let end_time = current_time + 86400;
        let initial_liquidity = 100000000;

        market::create_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            start_time,
            end_time,
            initial_liquidity
        );
    }

    #[expected_failure(abort_code = market::E_MARKET_ENDED)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200)]
    fun test_create_market_invalid_end_time(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user1);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user1);

        let title = string::utf8(b"Will APT reach $10?");
        let description = string::utf8(b"Prediction market");
        let category = string::utf8(b"crypto");
        let current_time = timestamp::now_seconds();
        let start_time = current_time + 3600;
        let end_time = start_time - 1; // Invalid: before start time
        let initial_liquidity = 100000000;

        market::create_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            start_time,
            end_time,
            initial_liquidity
        );
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200)]
    fun test_start_market(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user1);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user1);

        let title = string::utf8(b"Will APT reach $10?");
        let description = string::utf8(b"Prediction market");
        let category = string::utf8(b"crypto");
        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100; // Soon
        let end_time = start_time + 86400;
        let initial_liquidity = 100000000;

        market::create_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            start_time,
            end_time,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let market_addr = *vector::borrow(&active_markets, 0);

        // Fast forward to start time
        timestamp::fast_forward_seconds(100);

        // Start the market
        market::start_market<AptosCoin>(user1, market_addr);

        // Verify market is now active
        let (_, status, _, _, _, _) = market::get_market_info<AptosCoin>(market_addr);
        assert!(status == 1, 1); // MARKET_ACTIVE
        assert!(market::is_market_active<AptosCoin>(market_addr), 2);
    }

    #[expected_failure(abort_code = market::E_NOT_AUTHORIZED)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_start_market_unauthorized(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user2);

        let title = string::utf8(b"Will APT reach $10?");
        let description = string::utf8(b"Prediction market");
        let category = string::utf8(b"crypto");
        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 86400;
        let initial_liquidity = 100000000;

        market::create_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            start_time,
            end_time,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let market_addr = *vector::borrow(&active_markets, 0);

        timestamp::fast_forward_seconds(100);

        // Try to start market with wrong user - should fail
        market::start_market<AptosCoin>(user2, market_addr);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_place_bet_success(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user2);

        // Create and start market
        let title = string::utf8(b"Will APT reach $10?");
        let description = string::utf8(b"Prediction market");
        let category = string::utf8(b"crypto");
        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 86400;
        let initial_liquidity = 100000000;

        market::create_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            start_time,
            end_time,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let market_addr = *vector::borrow(&active_markets, 0);

        timestamp::fast_forward_seconds(100);
        market::start_market<AptosCoin>(user1, market_addr);

        // Place bets
        let bet_amount = 50000000; // 0.5 APT
        market::place_bet<AptosCoin>(user1, market_addr, 1, bet_amount); // Yes
        market::place_bet<AptosCoin>(user2, market_addr, 0, bet_amount); // No

        // Check betting pools
        let (yes_pool, no_pool, total_volume) = market::get_betting_pools<AptosCoin>(market_addr);
        assert!(yes_pool == (bet_amount as u128), 1);
        assert!(no_pool == (bet_amount as u128), 2);
        assert!(total_volume == (bet_amount * 2 as u128), 3);

        // Check user balances decreased
        assert!(coin::balance<AptosCoin>(signer::address_of(user1)) < 1000000000, 4);
        assert!(coin::balance<AptosCoin>(signer::address_of(user2)) < 2000000000, 5);
    }

    #[expected_failure(abort_code = market::E_MARKET_NOT_STARTED)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_place_bet_market_not_active(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user2);

        // Create market but don't start it
        let title = string::utf8(b"Will APT reach $10?");
        let description = string::utf8(b"Prediction market");
        let category = string::utf8(b"crypto");
        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 86400;
        let initial_liquidity = 100000000;

        market::create_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            start_time,
            end_time,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let market_addr = *vector::borrow(&active_markets, 0);

        // Try to bet on inactive market - should fail
        let bet_amount = 50000000;
        market::place_bet<AptosCoin>(user2, market_addr, 1, bet_amount);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_resolve_market(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user2);

        // Create, start, and bet on market
        let title = string::utf8(b"Will APT reach $10?");
        let description = string::utf8(b"Prediction market");
        let category = string::utf8(b"crypto");
        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 1000; // Short market for testing
        let initial_liquidity = 100000000;

        market::create_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            start_time,
            end_time,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let market_addr = *vector::borrow(&active_markets, 0);

        timestamp::fast_forward_seconds(100);
        market::start_market<AptosCoin>(user1, market_addr);

        // Place bets
        let bet_amount = 50000000;
        market::place_bet<AptosCoin>(user1, market_addr, 1, bet_amount); // Yes
        market::place_bet<AptosCoin>(user2, market_addr, 0, bet_amount * 2); // No (more)

        // Fast forward past end time
        timestamp::fast_forward_seconds(1000);

        // Resolve market - No wins (outcome 0)
        let resolution_source = string::utf8(b"Oracle price feed");
        market::resolve_market<AptosCoin>(admin, market_addr, 0, resolution_source);

        // Check market is resolved
        let (_, _, _, _, _, is_resolved) = market::get_market_info<AptosCoin>(market_addr);
        assert!(is_resolved == true, 1);

        // Check that winner (user2) has more balance than before
        // Note: Exact calculations depend on fee structure
        assert!(coin::balance<AptosCoin>(signer::address_of(user2)) > 2000000000 - (bet_amount * 2), 2);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200)]
    fun test_market_ai_data(
        aptos_framework: &signer, 
        admin: &signer, 
        user1: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user1);
        let marketplace_addr = init_marketplace(admin);
        init_coins_for_users(aptos_framework, user1, user1);

        // Create market
        let title = string::utf8(b"AI Enhanced Market");
        let description = string::utf8(b"Testing AI features");
        let category = string::utf8(b"ai");
        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 86400;
        let initial_liquidity = 100000000;

        market::create_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            start_time,
            end_time,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let market_addr = *vector::borrow(&active_markets, 0);

        // Check initial AI data
        let (sentiment, confidence, recommendation, last_update) = 
            market::get_market_ai_data<AptosCoin>(market_addr);
        
        assert!(sentiment == 5000, 1); // Neutral start
        assert!(confidence == 0, 2); // No confidence initially
        assert!(recommendation == 0, 3); // No recommendation
        assert!(last_update == current_time, 4);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200)]
    fun test_market_view_functions(
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
        let current_time = timestamp::now_seconds();
        let start_time = current_time + 100;
        let end_time = start_time + 86400;
        let initial_liquidity = 100000000;

        market::create_market<AptosCoin>(
            user1,
            marketplace_addr,
            title,
            description,
            category,
            start_time,
            end_time,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let market_addr = *vector::borrow(&active_markets, 0);

        // Test all view functions
        let (market_title, status, created_time, end_timestamp, total_vol, is_resolved) = 
            market::get_market_info<AptosCoin>(market_addr);
        
        assert!(market_title == title, 1);
        assert!(status == 0, 2); // MARKET_PENDING
        assert!(created_time == current_time, 3);
        assert!(end_timestamp == end_time, 4);
        assert!(total_vol == 0, 5);
        assert!(is_resolved == false, 6);

        let (yes_pool, no_pool, total_volume) = market::get_betting_pools<AptosCoin>(market_addr);
        assert!(yes_pool == 0, 7);
        assert!(no_pool == 0, 8);
        assert!(total_volume == 0, 9);

        assert!(market::is_market_active<AptosCoin>(market_addr) == false, 10); // Not started yet
    }
}
