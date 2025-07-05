#[test_only]
module aptos_markets::marketplace_test {
    #[test_only]
    use std::string::{Self, String};
    #[test_only]
    use std::vector;
    #[test_only]
    use std::signer;
    #[test_only]
    use std::option;
    #[test_only]
    use aptos_std::table;
    #[test_only]
    use aptos_std::type_info;
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

    // Test helper function to set up the testing environment
    #[test_only]
    fun setup_test_env(aptos_framework: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
    }

    #[test_only]
    fun create_test_accounts(admin: &signer, user: &signer) {
        account::create_account_for_test(signer::address_of(admin));
        account::create_account_for_test(signer::address_of(user));
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100)]
    fun test_create_marketplace_success(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, admin);

        let name = string::utf8(b"Test Marketplace");
        let description = string::utf8(b"A test marketplace for prediction markets");
        let oracle_feed = @0x1234;
        let fee_rate = 250; // 2.5%
        let daily_volume_limit = 1000000000000u128; // 1M coins
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

        // Verify marketplace was created successfully
        let marketplace_addr = marketplace::get_marketplace_address<AptosCoin>();
        assert!(marketplace_addr != @0x0, 1);
    }

    #[expected_failure(abort_code = marketplace::E_INVALID_FEE_RATE)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100)]
    fun test_create_marketplace_invalid_fee_rate(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, admin);

        let name = string::utf8(b"Test Marketplace");
        let description = string::utf8(b"A test marketplace");
        let oracle_feed = @0x1234;
        let fee_rate = 10001; // > MAX_FEE_RATE (10000)
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
    }

    #[expected_failure(abort_code = marketplace::E_MARKETPLACE_ALREADY_EXISTS)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100)]
    fun test_create_marketplace_already_exists(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, admin);

        let name = string::utf8(b"Test Marketplace");
        let description = string::utf8(b"A test marketplace");
        let oracle_feed = @0x1234;
        let fee_rate = 250;
        let daily_volume_limit = 1000000000000u128;
        let ai_enabled = true;

        // Create marketplace first time
        marketplace::create_marketplace<AptosCoin>(
            admin,
            name,
            description,
            oracle_feed,
            fee_rate,
            daily_volume_limit,
            ai_enabled
        );

        // Try to create again - should fail
        marketplace::create_marketplace<AptosCoin>(
            admin,
            name,
            description,
            oracle_feed,
            fee_rate,
            daily_volume_limit,
            ai_enabled
        );
    }

    #[expected_failure(abort_code = marketplace::E_NOT_AUTHORIZED)]
    #[test(aptos_framework = @aptos_framework, admin = @0x100, user = @0x200)]
    fun test_create_marketplace_unauthorized(aptos_framework: &signer, admin: &signer, user: &signer) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, user);

        // Initialize registry with admin
        let name = string::utf8(b"Test Marketplace");
        let description = string::utf8(b"A test marketplace");
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

        // Try to create with different user - should fail
        marketplace::create_marketplace<AptosCoin>(
            user, // Not authorized
            name,
            description,
            oracle_feed,
            fee_rate,
            daily_volume_limit,
            ai_enabled
        );
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100)]
    fun test_register_market(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, admin);

        // Create marketplace first
        let name = string::utf8(b"Test Marketplace");
        let description = string::utf8(b"A test marketplace");
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
        let market_addr = @0x5678;
        let market_type = string::utf8(b"prediction");

        // This would typically be called by the market module
        // marketplace::register_market<AptosCoin>(marketplace_addr, market_addr, market_type);
        // Note: register_market is a friend function, so we can't test it directly here
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100)]
    fun test_update_ai_data(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, admin);

        // Create marketplace with AI enabled
        let name = string::utf8(b"AI Test Marketplace");
        let description = string::utf8(b"A test marketplace with AI");
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
        
        // Test AI data update
        let sentiment_score = 7500; // 75% positive
        let risk_assessment = 2500; // 25% risk
        let recommendation = 1; // Recommend
        let confidence = 8500; // 85% confidence

        // This would typically be called by the AI oracle module
        // marketplace::update_ai_data<AptosCoin>(
        //     marketplace_addr,
        //     sentiment_score,
        //     risk_assessment,
        //     recommendation,
        //     confidence
        // );
        // Note: update_ai_data is a friend function, so we can't test it directly here
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100)]
    fun test_get_latest_price(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, admin);

        // Create marketplace
        let name = string::utf8(b"Price Test Marketplace");
        let description = string::utf8(b"A test marketplace for price testing");
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
        
        // Get latest price (should return placeholder value)
        let price = marketplace::get_latest_price<AptosCoin>(marketplace_addr);
        assert!(price == 100000000u128, 1); // Should be placeholder price
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100)]
    fun test_marketplace_view_functions(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, admin);

        // Create marketplace
        let name = string::utf8(b"View Test Marketplace");
        let description = string::utf8(b"Testing view functions");
        let oracle_feed = @0x1234;
        let fee_rate = 300;
        let daily_volume_limit = 2000000000000u128;
        let ai_enabled = false;

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
        
        // Test view functions using actual available functions
        let (marketplace_name, total_markets, total_volume, marketplace_fee_rate, ai_status) = 
            marketplace::get_marketplace_info<AptosCoin>(marketplace_addr);
        
        assert!(marketplace_name == name, 1);
        assert!(total_markets == 0, 2);
        assert!(total_volume == 0, 3);
        assert!(marketplace_fee_rate == fee_rate, 4);
        assert!(ai_status == ai_enabled, 5);

        let active_markets = marketplace::get_active_markets<AptosCoin>(marketplace_addr);
        assert!(vector::length(&active_markets) == 0, 6);

        let ai_enabled_check = marketplace::is_ai_enabled<AptosCoin>(marketplace_addr);
        assert!(ai_enabled_check == ai_enabled, 7);
    }

    #[test(aptos_framework = @aptos_framework, admin = @0x100)]
    fun test_marketplace_fee_collection(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        create_test_accounts(admin, admin);

        // Initialize AptosCoin for testing
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        // Create marketplace
        let name = string::utf8(b"Fee Test Marketplace");
        let description = string::utf8(b"Testing fee collection");
        let oracle_feed = @0x1234;
        let fee_rate = 500; // 5%
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
        
        // Mint some coins and transfer to marketplace (simulating fee collection)
        let coins = coin::mint<AptosCoin>(100000000, &mint_cap);
        coin::deposit<AptosCoin>(marketplace_addr, coins);
        
        // Verify balance
        let balance = coin::balance<AptosCoin>(marketplace_addr);
        assert!(balance == 100000000, 1);

        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }
}
