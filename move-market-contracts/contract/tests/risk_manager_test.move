#[test_only]
module aptos_markets::risk_manager_test {
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
    use aptos_markets::marketplace;
    #[test_only]
    use aptos_markets::market;
    #[test_only]
    use aptos_markets::risk_manager;

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
    fun init_marketplace_and_market(admin: &signer, user: &signer): (address, address) {
        // Create marketplace
        let marketplace_name = string::utf8(b"Risk Test Marketplace");
        let description = string::utf8(b"Test marketplace for risk manager testing");
        let oracle_feed = @0x1234;
        let fee_rate = 250;
        let daily_volume_limit = 1000000000000u128;
        let ai_enabled = true;

        marketplace::create_marketplace<AptosCoin>(
            admin,
            marketplace_name,
            description,
            oracle_feed,
            fee_rate,
            daily_volume_limit,
            ai_enabled
        );

        let marketplace_addr = marketplace::get_marketplace_address<AptosCoin>();

        // Create a market for testing
        let title = string::utf8(b"Risk Test Market");
        let market_description = string::utf8(b"Test market for risk manager functionality");
        let category = string::utf8(b"test");
        let current_time = timestamp::now_seconds();
        let start_time = current_time + 3600;
        let end_time = start_time + 86400;
        let initial_liquidity = 100000000;

        market::create_market<AptosCoin>(
            user,
            marketplace_addr,
            title,
            market_description,
            category,
            start_time,
            end_time,
            initial_liquidity
        );

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        let market_addr = *vector::borrow(&active_markets, 0);

        (marketplace_addr, market_addr)
    }

    #[test_only]
    fun init_coins_for_users(aptos_framework: &signer, user1: &signer, user2: &signer) {
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        let coins1 = coin::mint<AptosCoin>(1000000000, &mint_cap); // 10 APT
        let coins2 = coin::mint<AptosCoin>(1000000000, &mint_cap); // 10 APT
        
        aptos_account::deposit_coins(signer::address_of(user1), coins1);
        aptos_account::deposit_coins(signer::address_of(user2), coins2);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_initialize_user_risk_profile(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // Risk manager auto-initializes on first use

        // Initialize user risk profile
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);

        // Verify profile was created with correct defaults
        let (risk_score, exposure, risk_level, restricted, fraud_score) = 
            risk_manager::get_user_risk_profile<AptosCoin>(signer::address_of(user1));
        
        assert!(risk_score == 5000, 1); // 50% default risk
        assert!(exposure == 0, 2); // No exposure initially
        assert!(risk_level == 1, 3); // RISK_MEDIUM = 1
        assert!(restricted == false, 4); // Not restricted
        assert!(fraud_score == 0, 5); // No fraud initially
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_initialize_profile_twice(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // Risk manager auto-initializes on first use

        // Initialize user risk profile
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);

        // Try to initialize again - should not error, just return early
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);

        // Verify profile still exists with same values
        let (risk_score, exposure, risk_level, restricted, fraud_score) = 
            risk_manager::get_user_risk_profile<AptosCoin>(signer::address_of(user1));
        
        assert!(risk_score == 5000, 1);
        assert!(exposure == 0, 2);
        assert!(restricted == false, 3);
        assert!(fraud_score == 0, 4);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_pre_trade_risk_check_success(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes and create market
        let (_, market_addr) = init_marketplace_and_market(admin, user1);

        // Initialize user risk profile
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);

        // Test pre-trade risk check with reasonable position
        let position_size = 50000000u128; // 0.5 APT
        let check_passed = risk_manager::pre_trade_risk_check<AptosCoin>(
            signer::address_of(user1),
            market_addr,
            position_size
        );

        assert!(check_passed == true, 1); // Should pass all checks
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_pre_trade_check_no_profile(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes and create market
        let (_, market_addr) = init_marketplace_and_market(admin, user1);

        // DON'T initialize user risk profile - test should fail
        let position_size = 50000000u128;
        let check_passed = risk_manager::pre_trade_risk_check<AptosCoin>(
            signer::address_of(user1),
            market_addr,
            position_size
        );

        assert!(check_passed == false, 1); // Should fail without profile
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_pre_trade_check_position_too_large(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes and create market
        let (_, market_addr) = init_marketplace_and_market(admin, user1);

        // Initialize user risk profile
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);

        // Test with position larger than max allowed (default is 10 APT = 1000000000)
        let position_size = 2000000000u128; // 20 APT - too large
        let check_passed = risk_manager::pre_trade_risk_check<AptosCoin>(
            signer::address_of(user1),
            market_addr,
            position_size
        );

        assert!(check_passed == false, 1); // Should fail due to size limit
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_post_trade_risk_update(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes and create market
        let (_, market_addr) = init_marketplace_and_market(admin, user1);

        // Initialize user risk profile
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);

        // Simulate a buy trade
        let position_size = 100000000u128; // 1 APT
        risk_manager::post_trade_risk_update<AptosCoin>(
            signer::address_of(user1),
            market_addr,
            position_size,
            true // is_buy
        );

        // Verify profile was updated
        let (risk_score, exposure, risk_level, restricted, fraud_score) = 
            risk_manager::get_user_risk_profile<AptosCoin>(signer::address_of(user1));
        
        assert!(exposure == 100000000, 1); // Should have 1 APT exposure
        assert!(risk_score >= 5000, 2); // Risk score may have increased
        assert!(restricted == false, 3); // Still not restricted
        assert!(fraud_score == 0, 4); // No fraud yet

        // Simulate a sell trade
        risk_manager::post_trade_risk_update<AptosCoin>(
            signer::address_of(user1),
            market_addr,
            50000000u128, // 0.5 APT
            false // is_sell
        );

        // Verify exposure decreased
        let (_, exposure_after_sell, _, _, _) = 
            risk_manager::get_user_risk_profile<AptosCoin>(signer::address_of(user1));
        
        assert!(exposure_after_sell == 50000000, 5); // Should have 0.5 APT exposure remaining
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_update_ai_risk_assessment(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes and user profile
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);

        // Update AI risk assessment
        let ai_risk_score = 7500; // 75% AI risk
        let ai_confidence = 9000; // 90% confidence
        let risk_factors = vector::empty<String>();
        vector::push_back(&mut risk_factors, string::utf8(b"high_volatility"));
        vector::push_back(&mut risk_factors, string::utf8(b"market_manipulation"));

        risk_manager::update_ai_risk_assessment<AptosCoin>(
            signer::address_of(user1),
            ai_risk_score,
            ai_confidence,
            risk_factors
        );

        // Verify risk score was updated (AI weighted in)
        let (risk_score, _, _, _, _) = 
            risk_manager::get_user_risk_profile<AptosCoin>(signer::address_of(user1));
        
        // Risk score should be influenced by AI assessment
        assert!(risk_score > 5000, 1); // Should be higher than default due to high AI risk
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_report_suspicious_activity(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes and user profile
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);

        // Report suspicious activity
        let activity_type = string::utf8(b"WASH_TRADING");
        let evidence = vector::empty<String>();
        vector::push_back(&mut evidence, string::utf8(b"Repeated buy/sell patterns"));
        vector::push_back(&mut evidence, string::utf8(b"Same user, multiple accounts"));

        risk_manager::report_suspicious_activity<AptosCoin>(
            user2, // Reporter
            signer::address_of(user1), // Target user
            activity_type,
            evidence
        );

        // Verify fraud score increased
        let (_, _, _, _, fraud_score) = 
            risk_manager::get_user_risk_profile<AptosCoin>(signer::address_of(user1));
        
        assert!(fraud_score == 1000, 1); // Should have increased by 1000 (10%)
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_multiple_fraud_reports_trigger_restriction(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes and user profile
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);

        // Report multiple suspicious activities to trigger fraud threshold
        let activity_types = vector::empty<String>();
        vector::push_back(&mut activity_types, string::utf8(b"WASH_TRADING"));
        vector::push_back(&mut activity_types, string::utf8(b"PUMP_DUMP"));
        vector::push_back(&mut activity_types, string::utf8(b"FRONT_RUNNING"));
        vector::push_back(&mut activity_types, string::utf8(b"MARKET_MANIPULATION"));
        vector::push_back(&mut activity_types, string::utf8(b"INSIDER_TRADING"));
        vector::push_back(&mut activity_types, string::utf8(b"COLLUSION"));
        vector::push_back(&mut activity_types, string::utf8(b"SPOOFING"));
        vector::push_back(&mut activity_types, string::utf8(b"LAYERING"));

        let evidence = vector::empty<String>();
        vector::push_back(&mut evidence, string::utf8(b"Suspicious pattern detected"));

        // Report 8 different types of fraud (8 * 1000 = 8000 fraud score, should trigger restriction)
        let i = 0;
        while (i < vector::length(&activity_types)) {
            risk_manager::report_suspicious_activity<AptosCoin>(
                user2,
                signer::address_of(user1),
                *vector::borrow(&activity_types, i),
                evidence
            );
            i = i + 1;
        };

        // Verify account was restricted due to high fraud score
        let (_, _, _, restricted, fraud_score) = 
            risk_manager::get_user_risk_profile<AptosCoin>(signer::address_of(user1));
        
        assert!(fraud_score >= 8000, 1); // Should have high fraud score
        assert!(restricted == true, 2); // Account should be restricted
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_trigger_circuit_breaker(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes

        // Verify circuit breaker is initially inactive
        assert!(risk_manager::is_circuit_breaker_active() == false, 1);

        // Trigger circuit breaker
        let reason = string::utf8(b"Market volatility exceeded threshold");
        let duration = 3600; // 1 hour
        risk_manager::trigger_circuit_breaker<AptosCoin>(admin, reason, duration);

        // Verify circuit breaker is now active
        assert!(risk_manager::is_circuit_breaker_active() == true, 2);

        // Test that pre-trade checks fail when circuit breaker is active
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);
        let (_, market_addr) = init_marketplace_and_market(admin, user1);
        
        let check_passed = risk_manager::pre_trade_risk_check<AptosCoin>(
            signer::address_of(user1),
            market_addr,
            50000000u128
        );
        
        assert!(check_passed == false, 3); // Should fail due to circuit breaker
    }

    #[expected_failure(abort_code = risk_manager::E_NOT_AUTHORIZED)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_trigger_circuit_breaker_unauthorized(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes

        // Try to trigger circuit breaker with non-admin user - should fail
        let reason = string::utf8(b"Unauthorized attempt");
        let duration = 3600;
        risk_manager::trigger_circuit_breaker<AptosCoin>(user1, reason, duration);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_update_risk_parameters(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes and user profile
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);

        // Update user's risk parameters (increase position limit)
        let new_max_position = 2000000000u128; // 20 APT
        risk_manager::update_risk_parameters<AptosCoin>(
            admin,
            signer::address_of(user1),
            new_max_position
        );

        // Verify the user can now place larger positions
        let (_, market_addr) = init_marketplace_and_market(admin, user1);
        let large_position = 1500000000u128; // 15 APT
        let check_passed = risk_manager::pre_trade_risk_check<AptosCoin>(
            signer::address_of(user1),
            market_addr,
            large_position
        );

        assert!(check_passed == true, 1); // Should pass with increased limits
    }

    #[expected_failure(abort_code = risk_manager::E_NOT_AUTHORIZED)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_update_risk_parameters_unauthorized(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes and user profile
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);

        // Try to update risk parameters with non-admin user - should fail
        let new_max_position = 2000000000u128;
        risk_manager::update_risk_parameters<AptosCoin>(
            user2, // Not admin - should fail
            signer::address_of(user1),
            new_max_position
        );
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_remove_account_restriction(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes and user profile
        risk_manager::initialize_user_risk_profile<AptosCoin>(user1);

        // First, restrict the account by reporting fraud
        let activity_type = string::utf8(b"MAJOR_FRAUD");
        let evidence = vector::empty<String>();
        vector::push_back(&mut evidence, string::utf8(b"Clear evidence of fraud"));

        // Report fraud multiple times to trigger restriction
        let i = 0;
        while (i < 8) { // 8 * 1000 = 8000 fraud score
            risk_manager::report_suspicious_activity<AptosCoin>(
                user2,
                signer::address_of(user1),
                activity_type,
                evidence
            );
            i = i + 1;
        };

        // Verify account is restricted
        let (_, _, _, restricted_before, _) = 
            risk_manager::get_user_risk_profile<AptosCoin>(signer::address_of(user1));
        assert!(restricted_before == true, 1);

        // Remove restriction
        risk_manager::remove_account_restriction<AptosCoin>(
            admin,
            signer::address_of(user1)
        );

        // Verify account is no longer restricted
        let (_, _, _, restricted_after, _) = 
            risk_manager::get_user_risk_profile<AptosCoin>(signer::address_of(user1));
        assert!(restricted_after == false, 2);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_get_global_risk_metrics(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes

        // Check initial global metrics
        let (total_exposure, active_alerts, circuit_breaker_active) = 
            risk_manager::get_global_risk_metrics();
        
        assert!(total_exposure == 0, 1); // No exposure initially
        assert!(active_alerts == 0, 2); // No alerts initially
        assert!(circuit_breaker_active == false, 3); // Circuit breaker inactive

        // Trigger circuit breaker and check again
        risk_manager::trigger_circuit_breaker<AptosCoin>(
            admin,
            string::utf8(b"Test circuit breaker"),
            3600
        );

        let (_, _, circuit_breaker_after) = risk_manager::get_global_risk_metrics();
        assert!(circuit_breaker_after == true, 4); // Circuit breaker should be active
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100, user1 = @0x200, user2 = @0x300)]
    fun test_view_functions_no_profile(
        aptos_framework: &signer,
        admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user1, user2);
        init_coins_for_users(aptos_framework, user1, user2);

        // System auto-initializes but don't create user profile

        // Test view functions with non-existent profile
        let (risk_score, exposure, risk_level, restricted, fraud_score) = 
            risk_manager::get_user_risk_profile<AptosCoin>(signer::address_of(user1));
        
        // Should return default values
        assert!(risk_score == 5000, 1); // Default risk
        assert!(exposure == 0, 2); // No exposure
        assert!(risk_level == 1, 3); // Medium risk level
        assert!(restricted == false, 4); // Not restricted
        assert!(fraud_score == 0, 5); // No fraud
    }
} 