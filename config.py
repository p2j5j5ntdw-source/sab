
# Roblox Brainrot Base Finder - Configuration File
# Custom solution for automated server discovery and notifications


DISCORD_TOKEN = "MTQzMTc0MjUzNzU3OTYzMDcwNA.GPk84F.FD076vWQNdwKytpVbWcLEDywsOUEjOiMZeMGBM"
# Your Discord account token for monitoring
# How to get: Discord Settings → Advanced → Developer Mode → Console


DISCORD_WEBHOOK_1M_10M = "https://discord.com/api/webhooks/1432090724140056637/k3sl5Gq0UuI9rt3VmlLQfqqBoT776GIGY8bvx91jFPXIbinZGoAHEA_rNgMq4Bvy6exa"  # Webhook for 1M-10M tier
DISCORD_WEBHOOK_10M_PLUS = "https://discord.com/api/webhooks/1432099374929940540/AQWfRwiho8V3YdJ9okc2eYHN5gw2Tu0SGNlFwejk30p42Hc_LC-6GE-dV9gHD1Lld6mr"  # Webhook for 10M+ tier
# Notification destinations for different value tiers
# Create webhooks: Server Settings → Integrations → Webhooks → New Webhook
# Separate channels recommended for better organization


MONEY_THRESHOLD = (1.0, 1999.0)  # Minimum and maximum earnings threshold (in millions)
# Only notify for targets within this range
# Example: (3.0, 10.0) = only 3M-10M earnings per second


PLAYER_TRESHOLD = 8  # Maximum players on server
# Skip servers with more than this number of players for easier access


IGNORE_UNKNOWN = True  # True / False
# Ignore unidentified targets


IGNORE_LIST = [""]  # Blacklist specific targets by name
# Example: ["Graipuss Medussi", "La Grande Combinasion"]


FILTER_BY_NAME = False, ["Graipuss Medussi", "La Grande Combinasion"]  # Whitelist mode
# Set to True to ONLY notify for specific targets in the list
# Example: True, ["Graipuss Medussi", "La Grande Combinasion"]


BYPASS_10M = True  # True / False
# Enable special handling for high-value 10M+ targets


ROBLOX_PLACE_ID = "109983668079237"  # Target Roblox game Place ID (Steal A Brainrot - Lolobonds)
# Change this if monitoring a different game

CUSTOM_JOINER_URL = "https://stealabrainrot-rho-two.vercel.app"  # Custom joiner page URL (no trailing slash!)
# Mobile-friendly server joiner hosted on Vercel
# Leave empty to use direct Roblox links instead


READ_CHANNELS = ['1m-10m', "10m_plus"]  # Active monitoring channels
# Which data channels to monitor (must match keys in DATA_SOURCE_CHANNELS below)





# ============================================================================
# ADVANCED SETTINGS - Do not modify unless you know what you're doing
# ============================================================================

WEBSOCKET_PORT = 51948  # Local WebSocket port for in-game automation
DISCORD_WS_URL = "wss://gateway.discord.gg/?encoding=json&v=9"  # Discord Gateway

# Data source channel configuration
DATA_SOURCE_SERVER_ID = "1401550662335991908"  # Primary data source Discord server
DATA_SOURCE_CHANNELS = {
    "1m-10m": ["1404759535293431849"],      # Standard tier channels
    "10m_plus": ["1404759584450678865"],    # Premium tier channels
    "under_500k": ["1401774863974268959"],  # Low tier (archived)
    "500k_1m": ["1401775012083404931"],     # Mid tier (archived)
}

# ============================================================================
# End of Configuration
# ============================================================================