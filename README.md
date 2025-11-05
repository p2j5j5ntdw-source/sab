# 🧠 Roblox Auto-Joiner & Base Finder

<div align="center">

![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)
![Roblox](https://img.shields.io/badge/Roblox-Lua-orange.svg)
![Discord](https://img.shields.io/badge/Discord-Webhook-5865F2.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**Automated server monitoring and notification system for Roblox games**

[Features](#-features) • [How It Works](#-how-it-works) • [Setup](#-setup) • [Usage](#-usage) • [Vercel App](#-vercel-app-integration)

</div>

---

## 📖 What is This?

This is an **automated monitoring system** designed for the Roblox game **"Steal A Brainrot"** (and similar games). It automatically:

- 🔍 **Scans** game servers for valuable bases/items
- 📱 **Monitors** Discord channels for server announcements
- 🚨 **Sends** real-time notifications when valuable targets are found
- 🎮 **Joins** servers automatically or provides quick-join links
- 📊 **Filters** results by value, player count, and custom criteria

### What is "Steal A Brainrot"?

**Steal A Brainrot** is a popular Roblox game where players can find and collect "brainrot bases" that generate in-game currency (money per second). The most valuable bases can earn millions per second, but they're rare and disappear quickly when servers close.

This tool helps you:
- **Never miss** valuable bases by monitoring 24/7
- **Join faster** with automatic server joining
- **Get notified** instantly via Discord webhooks

---

## ✨ Features

### 🔄 Dual Monitoring System

1. **Discord Monitoring** (Python)
   - Monitors Discord channels for server announcements
   - Parses server information automatically
   - Sends webhook notifications
   - Auto-joins servers via WebSocket

2. **In-Game Scanning** (Lua Script)
   - Scans the game workspace for bases in real-time
   - Detects money values, owners, and coordinates
   - Sends webhooks directly from the game
   - Works independently of Discord monitoring

### 🎯 Smart Filtering

- **Money Threshold**: Filter by earnings per second (e.g., 1M-10M, 10M+)
- **Player Limit**: Skip servers with too many players
- **Whitelist/Blacklist**: Custom base name filtering
- **Unknown Filter**: Ignore unidentified bases

### 📱 Mobile-Friendly

- **Vercel App**: Mobile-optimized server joiner page
- **Deep Links**: Direct Roblox app integration
- **Multiple Links**: Backup join methods for reliability

### 🛠️ Advanced Features

- **WebSocket Server**: Real-time communication between Python and Lua
- **Auto-Execute**: Lua scripts auto-run when game loads
- **Logging System**: Comprehensive logs for debugging
- **Server Hopping**: Automatically join random servers

---

## 🏗️ How It Works

### System Architecture

```
┌─────────────────┐
│  Discord Bot    │ ← Monitors Discord channels
│  (Python)       │   for server announcements
└────────┬────────┘
         │
         ├───► Sends Webhooks
         │     └───► Discord Channel
         │
         └───► WebSocket Server
               └───► Lua Script (in-game)
                     └───► Auto-joins server
```

### Components

1. **`main.py`** - Main entry point, starts Discord listener and WebSocket server
2. **`discord.py`** - Discord WebSocket client, monitors channels, sends webhooks
3. **`BrainrotFinderWebhook.lua`** - In-game Lua script that scans for bases
4. **`server_hopper.py`** - Alternative: Auto-joins random servers via Roblox API
5. **`config.py`** - Configuration file (webhooks, filters, etc.)
6. **Vercel App** - Mobile-friendly web page for joining servers

### Workflow

1. **Discord Monitoring**:
   - Bot connects to Discord via WebSocket
   - Listens to configured channels
   - When a new server is announced, it:
     - Parses the message for server info (Job ID, money, players, etc.)
     - Checks if it meets filter criteria
     - Sends webhook notification to your Discord
     - Optionally broadcasts join command to in-game script

2. **In-Game Scanning**:
   - Lua script runs in Roblox game
   - Scans workspace for bases (Models with money values)
   - Extracts: name, money/sec, owner, coordinates
   - Sends webhook directly to Discord
   - Updates every 10 seconds (configurable)

3. **Auto-Join**:
   - Python script can send join commands via WebSocket
   - Lua script receives command and joins server
   - Or use Vercel app link to join manually

---

## 🚀 Setup

### Prerequisites

- **Python 3.11+** installed
- **Roblox** installed and logged in
- **Discord account** with token
- **Discord webhook URLs** (for notifications)
- **Roblox executor** (Synapse, Krnl, Fluxus, etc.)

### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/roblox-autojoiner.git
cd roblox-autojoiner
```

### Step 2: Install Dependencies

```bash
pip install -r requirements.txt
```

Required packages:
- `websockets` - WebSocket client/server
- `aiohttp` - HTTP client for webhooks
- `keyboard` - Keyboard automation (optional)
- `colorama` - Colored terminal output

### Step 3: Configure Settings

Edit `config.py`:

```python
# Discord Token (get from browser console)
DISCORD_TOKEN = "YOUR_DISCORD_TOKEN"

# Discord Webhooks (create in Discord server settings)
DISCORD_WEBHOOK_1M_10M = "https://discord.com/api/webhooks/..."
DISCORD_WEBHOOK_10M_PLUS = "https://discord.com/api/webhooks/..."

# Money filter (in millions)
MONEY_THRESHOLD = (1.0, 1999.0)  # Min, Max

# Player limit
PLAYER_TRESHOLD = 8  # Skip if more players

# Roblox Place ID
ROBLOX_PLACE_ID = "109983668079237"  # Steal A Brainrot

# Vercel joiner URL (optional)
CUSTOM_JOINER_URL = "https://your-app.vercel.app"
```

### Step 4: Configure Lua Script

Edit `BrainrotFinderWebhook.lua`:

```lua
local CONFIG = {
    -- Discord Webhooks (same as config.py)
    WEBHOOK_1M_10M = "https://discord.com/api/webhooks/...",
    WEBHOOK_10M_PLUS = "https://discord.com/api/webhooks/...",
    
    -- Filters
    MIN_MONEY = 1.0,      -- Minimum M/s
    MAX_MONEY = 1999.0,   -- Maximum M/s
    MAX_PLAYERS = 8,      -- Skip if more players
    
    -- Scanning
    SCAN_INTERVAL = 10,   -- Seconds between scans
}
```

### Step 5: Setup Discord Webhooks

1. Go to your Discord server
2. **Server Settings** → **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Copy the webhook URL
5. Paste into `config.py` and `BrainrotFinderWebhook.lua`

### Step 6: Get Discord Token

1. Open Discord in browser
2. Press `F12` to open Developer Tools
3. Go to **Console** tab
4. Run:
   ```javascript
   window.webpackChunkdiscord_app.push([[''],{},e=>{m=[];for(let c in e.c)m.push(e.c[c])}]),m.find(m=>m?.exports?.default?.getToken!==void 0).exports.default.getToken()
   ```
5. Copy the token and paste into `config.py`

---

## 📱 Usage

### Running the Discord Monitor

```bash
python main.py
```

This will:
- Connect to Discord WebSocket
- Start monitoring configured channels
- Send webhook notifications when servers are found

### Running Server Hopper (Alternative)

If you want to auto-join random servers instead of monitoring Discord:

```bash
python server_hopper.py
```

This will:
- Fetch server list from Roblox API
- Join servers with low player count
- Auto-execute Lua script when game loads

### Using the Lua Script

1. **Copy** `BrainrotFinderWebhook.lua` to your executor's auto-execute folder
   - **Synapse**: `%appdata%\Synapse\Workspace\autoexec`
   - **Krnl**: `%appdata%\Krnl\autoexec`
   - **Fluxus**: `%appdata%\Fluxus\autoexec`

2. **Enable auto-execute** in your executor settings

3. **Join** a Roblox game - script will run automatically

4. **Check console** for scan results:
   ```
   🔍 Scanning workspace for bases...
     📁 Scanning: Workspace
       ✅ Found base: MyBase (20.50M/s) at Workspace.Bases.MyBase
   ```

### Quick Start (Windows)

Use the provided batch files:

```bash
# Setup (first time only)
SETUP_VPS_MUMU.bat

# Start automation
START_AUTOMATION.bat
```

---

## 🌐 Vercel App Integration

### What is the Vercel App?

The **Vercel App** is a mobile-friendly web page that helps you join Roblox servers quickly. Instead of using complex Roblox URLs, you get a simple, clean interface.

### Features

- 📱 **Mobile-optimized** - Works perfectly on phones
- 🎨 **Beautiful UI** - Modern, gradient design
- 🔗 **Deep Links** - Directly opens Roblox app
- 🔄 **Auto-join** - Automatically attempts to join when page loads
- ⚠️ **Error Handling** - Shows helpful messages if join fails

### How It Works

1. **Webhook sends link**:
   ```
   https://your-app.vercel.app/?placeId=109983668079237&jobId=abc123xyz
   ```

2. **Page loads**:
   - Extracts `placeId` and `jobId` from URL
   - Shows loading animation
   - Attempts to open Roblox app

3. **Roblox opens**:
   - Uses deep link: `roblox://experiences/start?placeId=...&gameInstanceId=...`
   - Falls back to web link if app doesn't open

### Setting Up Vercel App

1. **Install Vercel CLI**:
   ```bash
   npm i -g vercel
   ```

2. **Deploy**:
   ```bash
   cd "vercel app"
   vercel
   ```

3. **Configure**:
   - Follow prompts to create/link project
   - Copy the deployment URL
   - Update `CUSTOM_JOINER_URL` in `config.py`

### File Structure

```
vercel app/
├── index.html       # Main joiner page
├── package.json     # Vercel config
└── vercel.json      # Deployment settings
```

### Customization

Edit `index.html` to customize:
- **Colors**: Change gradient colors in CSS
- **Title**: Update `<h1>` text
- **Default Place ID**: Change `placeId` in JavaScript

---

## 🎮 Advanced Usage

### Running on VPS (24/7)

See `VPS_SETUP_MUMU.txt` for detailed instructions on:
- Setting up Windows VPS
- Installing Roblox in MuMu emulator
- Running automation 24/7
- Auto-restart on crashes

### Using with Android (MuMu Emulator)

1. **Install MuMu Player** on VPS
2. **Install Roblox** in emulator
3. **Use** `data/joiner_android.lua` instead of `BrainrotFinderWebhook.lua`
4. **Configure** WebSocket URL to VPS IP address

### WebSocket Communication

The system uses WebSocket for real-time communication:

- **Python** runs WebSocket server on port `51948`
- **Lua script** connects to `ws://127.0.0.1:51948`
- **Commands** sent from Python to Lua:
  - `JOIN_SERVER:job_id` - Join specific server
  - `PING` - Keep-alive check

---

## 📁 Project Structure

```
roblox-autojoiner/
├── main.py                    # Entry point
├── discord.py                 # Discord WebSocket client
├── config.py                  # Configuration
├── server_hopper.py           # Alternative: Auto-join random servers
├── requirements.txt           # Python dependencies
├── BrainrotFinderWebhook.lua  # In-game Lua script
├── data/
│   ├── joiner.lua             # WebSocket client (Windows)
│   └── joiner_android.lua     # WebSocket client (Android/MuMu)
├── src/
│   ├── logger/
│   │   └── logger.py          # Logging system
│   ├── roblox.py              # WebSocket server
│   └── utils.py               # Utility functions
├── vercel app/
│   ├── index.html             # Mobile joiner page
│   ├── package.json
│   └── vercel.json
├── logs/                      # Log files (auto-generated)
└── README.md                  # This file
```

---

## ⚙️ Configuration Options

### Discord Settings

```python
DISCORD_TOKEN = "..."              # Your Discord token
DISCORD_WEBHOOK_1M_10M = "..."    # Webhook for 1M-10M bases
DISCORD_WEBHOOK_10M_PLUS = "..."  # Webhook for 10M+ bases
READ_CHANNELS = ['1m-10m', '10m_plus']  # Channels to monitor
```

### Filtering

```python
MONEY_THRESHOLD = (1.0, 1999.0)    # Min/Max money (millions)
PLAYER_TRESHOLD = 8                # Max players
IGNORE_UNKNOWN = True              # Ignore "Unknown" bases
IGNORE_LIST = ["Base1", "Base2"]   # Blacklist
FILTER_BY_NAME = False, [...]      # Whitelist mode
```

### Game Settings

```python
ROBLOX_PLACE_ID = "109983668079237"  # Game Place ID
CUSTOM_JOINER_URL = "..."            # Vercel app URL
```

---

## 🐛 Troubleshooting

### Discord Bot Not Connecting

- ✅ Check Discord token is valid
- ✅ Enable "Developer Mode" in Discord settings
- ✅ Token might be expired - get a new one

### Webhooks Not Sending

- ✅ Verify webhook URLs are correct
- ✅ Check Discord server has webhook permissions
- ✅ Test webhook manually: `curl -X POST WEBHOOK_URL -d "{\"content\":\"test\"}"`

### Lua Script Not Finding Bases

- ✅ Check console output for scanning messages
- ✅ Verify you're in the correct game
- ✅ Base structure might be different - check game hierarchy
- ✅ Enable debug prints in script

### Auto-Join Not Working

- ✅ Check WebSocket server is running
- ✅ Verify Lua script is connected (`ws://127.0.0.1:51948`)
- ✅ Check firewall allows port `51948`
- ✅ For Android/MuMu: Use VPS IP instead of `127.0.0.1`

### Vercel App Not Opening Roblox

- ✅ Ensure Roblox is installed
- ✅ Check URL format: `?placeId=...&jobId=...`
- ✅ Try manual deep link: `roblox://experiences/start?placeId=...`

---

## 📝 Logs

Logs are automatically saved to `logs/` directory:

- `log-YYYY-MM-DD_HH-MM-SS.txt` - Timestamped logs
- `log.txt` - Latest log file

Check logs for:
- Discord connection status
- Webhook sending results
- Base detection messages
- Error details

---

## 🔒 Security & Privacy

⚠️ **Important Notes**:

- **Discord Token**: Keep it secret! Never share or commit to GitHub
- **Webhook URLs**: Anyone with URL can send messages - regenerate if leaked
- **Config File**: Add `config.py` to `.gitignore` (already included)
- **VPS Access**: Use strong passwords and enable firewall

### Recommended Security Practices

1. Use environment variables for sensitive data:
   ```python
   import os
   DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
   ```

2. Regenerate Discord token if compromised

3. Use separate Discord account for bot (not your main)

4. Limit webhook permissions in Discord server

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Credits

- **Roblox** - Game platform
- **Discord** - Communication platform
- **Vercel** - Hosting platform
- **Python** - Programming language
- **Lua** - Scripting language

---

## ⚠️ Disclaimer

This tool is for educational purposes only. Use at your own risk. Respect Roblox's Terms of Service and Discord's Terms of Service. Automated tools may violate game rules - use responsibly.

---

<div align="center">

**Made with ❤️ for the Roblox community**

⭐ **Star this repo if you find it useful!**

</div>

