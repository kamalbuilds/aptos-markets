export const ABI = {
  "address": "0xbf2557e1fca3bf80953a61e49cd2a7b114c28432015978207ab5666d524dbc62",
  "name": "marketplace",
  "friends": [
    "0xbf2557e1fca3bf80953a61e49cd2a7b114c28432015978207ab5666d524dbc62::event_market",
    "0xbf2557e1fca3bf80953a61e49cd2a7b114c28432015978207ab5666d524dbc62::market"
  ],
  "exposed_functions": [
    {
      "name": "create_marketplace",
      "visibility": "public",
      "is_entry": true,
      "is_view": false,
      "generic_type_params": [{"constraints": []}],
      "params": ["&signer", "0x1::string::String", "0x1::string::String", "address", "u64", "u128", "bool"],
      "return": []
    },
    {
      "name": "get_marketplace_address",
      "visibility": "public",
      "is_entry": false,
      "is_view": true,
      "generic_type_params": [{"constraints": []}],
      "params": [],
      "return": ["address"]
    },
    {
      "name": "get_active_markets",
      "visibility": "public",
      "is_entry": false,
      "is_view": true,
      "generic_type_params": [{"constraints": []}],
      "params": ["address"],
      "return": ["vector<address>"]
    },
    {
      "name": "get_marketplace_info",
      "visibility": "public",
      "is_entry": false,
      "is_view": true,
      "generic_type_params": [{"constraints": []}],
      "params": ["address"],
      "return": ["0x1::string::String", "u64", "u128", "u64", "bool"]
    },
    {
      "name": "is_ai_enabled",
      "visibility": "public",
      "is_entry": false,
      "is_view": true,
      "generic_type_params": [{"constraints": []}],
      "params": ["address"],
      "return": ["bool"]
    },
    {
      "name": "register_market",
      "visibility": "friend",
      "is_entry": false,
      "is_view": false,
      "generic_type_params": [{"constraints": []}],
      "params": ["address", "address", "0x1::string::String"],
      "return": []
    },
    {
      "name": "record_volume",
      "visibility": "friend",
      "is_entry": false,
      "is_view": false,
      "generic_type_params": [{"constraints": []}],
      "params": ["address", "u128"],
      "return": []
    },
    {
      "name": "get_latest_price",
      "visibility": "public",
      "is_entry": false,
      "is_view": false,
      "generic_type_params": [{"constraints": []}],
      "params": ["address"],
      "return": ["u128"]
    }
  ],
  "structs": [
    {
      "name": "Marketplace",
      "is_native": false,
      "is_event": false,
      "abilities": ["key"],
      "generic_type_params": [{"constraints": []}],
      "fields": [
        {"name": "name", "type": "0x1::string::String"},
        {"name": "description", "type": "0x1::string::String"},
        {"name": "admin", "type": "address"},
        {"name": "fee_rate", "type": "u64"},
        {"name": "total_volume", "type": "u128"},
        {"name": "total_markets_created", "type": "u64"},
        {"name": "active_markets", "type": "vector<address>"},
        {"name": "ai_enabled", "type": "bool"},
        {"name": "cached_price", "type": "0x1::option::Option<u128>"},
        {"name": "last_price_update", "type": "u64"},
        {"name": "daily_volume_limit", "type": "u128"},
        {"name": "daily_volume_used", "type": "u128"},
        {"name": "last_volume_reset", "type": "u64"},
        {"name": "extend_ref", "type": "0x1::object::ExtendRef"}
      ]
    }
  ]
} as const
