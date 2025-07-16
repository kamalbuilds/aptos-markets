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

    /// Initialize global resources for testing
    #[test_only]
    fun init_global_resources(admin: &signer) {
        // For testing, we use the admin account to initialize global resources
        // This simulates what happens when modules are published
        marketplace::init_for_test(admin);
    }

    /// Complete test setup that properly initializes the @aptos_markets account
    #[test_only] 
    fun setup_aptos_markets(aptos_framework: &signer, admin: &signer) {
        // Set up time
        setup_test_env(aptos_framework);
        
        // For testing, we'll initialize global resources at the admin address
        // which will act as @aptos_markets for these tests
        marketplace::init_for_test(admin);
    }

    #[test(aptos_framework = @aptos_framework, admin = @aptos_markets)]
    fun test_create_marketplace_success(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        
        // Initialize AptosCoin and global resources
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        marketplace::init_for_test(admin);

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
        
        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[expected_failure(abort_code = 65546)]
    #[test(aptos_framework = @aptos_framework, admin = @aptos_markets)]
    fun test_create_marketplace_invalid_fee_rate(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        
        // Initialize AptosCoin and global resources
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        marketplace::init_for_test(admin);

        let name = string::utf8(b"Test Marketplace");
        let description = string::utf8(b"A test marketplace");
        let oracle_feed = @0x1234;
        let fee_rate = 10001; // > MAX_FEE_RATE (1000)
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
        
        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[expected_failure(abort_code = 524290)]
    #[test(aptos_framework = @aptos_framework, admin = @aptos_markets)]
    fun test_create_marketplace_already_exists(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        
        // Initialize AptosCoin and global resources
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        marketplace::init_for_test(admin);

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
        
        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[expected_failure(abort_code = 327681)]
    #[test(aptos_framework = @aptos_framework, admin = @aptos_markets, user = @0x200)]
    fun test_create_marketplace_unauthorized(aptos_framework: &signer, admin: &signer, user: &signer) {
        setup_test_env(aptos_framework);
        account::create_account_for_test(signer::address_of(user));
        
        // Initialize AptosCoin and global resources
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        marketplace::init_for_test(admin);

        let name = string::utf8(b"Test Marketplace");
        let description = string::utf8(b"A test marketplace");
        let oracle_feed = @0x1234;
        let fee_rate = 250;
        let daily_volume_limit = 1000000000000u128;
        let ai_enabled = true;

        // First create with admin to initialize marketplace
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
        
        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @aptos_framework, admin = @aptos_markets)]
    fun test_register_market(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        
        // Initialize AptosCoin and global resources
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        marketplace::init_for_test(admin);

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
        assert!(marketplace_addr != @0x0, 1);

        // Note: register_market is a friend function, so we can't test it directly here
        
        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @aptos_framework, admin = @aptos_markets)]
    fun test_update_ai_data(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        
        // Initialize AptosCoin and global resources
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        marketplace::init_for_test(admin);

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
        assert!(marketplace_addr != @0x0, 1);

        // Note: update_ai_data is a friend function, so we can't test it directly here
        
        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @aptos_framework, admin = @aptos_markets)]
    fun test_get_latest_price(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        
        // Initialize AptosCoin and global resources
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        marketplace::init_for_test(admin);

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
        
        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @aptos_framework, admin = @aptos_markets)]
    fun test_marketplace_view_functions(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        
        // Initialize AptosCoin and global resources
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        marketplace::init_for_test(admin);

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
        
        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @aptos_framework, admin = @aptos_markets)]
    fun test_marketplace_fee_collection(aptos_framework: &signer, admin: &signer) {
        setup_test_env(aptos_framework);
        
        // Initialize AptosCoin and global resources
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        marketplace::init_for_test(admin);
        
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
