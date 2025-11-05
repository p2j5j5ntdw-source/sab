import asyncio
import websockets
import websockets.exceptions
import json
import random
import aiohttp

from src.logger.logger import setup_logger
from config import (DISCORD_WS_URL, DISCORD_TOKEN, MONEY_THRESHOLD,
                    IGNORE_UNKNOWN, PLAYER_TRESHOLD, BYPASS_10M,
                    FILTER_BY_NAME, IGNORE_LIST, READ_CHANNELS, 
                    DISCORD_WEBHOOK_1M_10M, DISCORD_WEBHOOK_10M_PLUS, ROBLOX_PLACE_ID,
                    CUSTOM_JOINER_URL, DATA_SOURCE_SERVER_ID, DATA_SOURCE_CHANNELS)
from src.roblox import server
from src.utils import check_channel, extract_server_info, set_console_title

logger = setup_logger()

# Professional monitoring system for Roblox server discovery

async def send_webhook_notification(parsed: dict):
    """Send a Discord webhook notification with the found brainrot server info"""
    # Choose the correct webhook based on money value
    if parsed['money'] >= 10.0:
        webhook_url = DISCORD_WEBHOOK_10M_PLUS
        category_text = "10M+ 💎"
        color = 0xFF00FF  # Purple for 10M+
    else:
        webhook_url = DISCORD_WEBHOOK_1M_10M
        category_text = "1M-10M 💰"
        color = 0x00FF00  # Green for 1M-10M
    
    if not webhook_url:
        logger.warning("Webhook URL is not set in config.py! Skipping webhook notification.")
        return
    
    try:
        # Determine the job ID to use
        job_id = None
        
        # Priority 1: Try to extract job ID from Chilli Hub's encrypted link
        if parsed.get('join_link') and 'join-server.pages.dev' in parsed['join_link']:
            # For now, we'll skip the encrypted link since it redirects to Discord
            # and try to get the job ID from other fields
            logger.debug("Found Chilli Hub encrypted link, but extracting job ID instead...")
        
        # Priority 2: Get job ID from the job_id field
        if parsed.get('job_id'):
            job_id = parsed['job_id']
            logger.debug(f"Using job ID from field: {job_id[:20]}...")
        
        # Priority 3: Extract job ID from script
        elif parsed.get('script') and 'TeleportToPlaceInstance' in parsed['script']:
            parts = parsed['script'].split('"')
            if len(parts) >= 4:
                job_id = parts[3]
                logger.debug(f"Extracted job ID from script: {job_id[:20]}...")
        
        # If we still don't have a job ID, error out
        if not job_id:
            logger.warning("Could not find job ID in any field!")
            return
        
        # Create multiple join links for better reliability
        if CUSTOM_JOINER_URL:
            # Primary: Custom Vercel joiner
            primary_link = f"{CUSTOM_JOINER_URL}/?placeId={ROBLOX_PLACE_ID}&jobId={job_id}"
            # Backup: Direct Roblox web link
            backup_link = f"https://www.roblox.com/games/{ROBLOX_PLACE_ID}/?gameInstanceId={job_id}"
            # Mobile: Deep link
            mobile_link = f"roblox://experiences/start?placeId={ROBLOX_PLACE_ID}&gameInstanceId={job_id}"
            logger.info(f"✅ Generated multiple join links")
        else:
            # Primary: Direct Roblox web link
            primary_link = f"https://www.roblox.com/games/{ROBLOX_PLACE_ID}/?gameInstanceId={job_id}"
            # Mobile: Deep link
            mobile_link = f"roblox://experiences/start?placeId={ROBLOX_PLACE_ID}&gameInstanceId={job_id}"
            backup_link = None
            logger.info(f"✅ Generated Roblox links")
        
        # Build join links field
        join_links_value = f"[🔗 Primary Link]({primary_link})"
        if backup_link:
            join_links_value += f"\n[🔗 Backup Link (Web)]({backup_link})"
        if mobile_link:
            join_links_value += f"\n[📱 Mobile Deep Link]({mobile_link})"
        
        # Create the webhook embed
        embed = {
            "title": f"🧠 Brainrot Base Found! [{category_text}]",
            "description": f"Found a valuable brainrot base! **⚠️ Servers expire quickly - join ASAP!**",
            "color": color,
            "fields": [
                {
                    "name": "🏷️ Name",
                    "value": parsed['name'],
                    "inline": True
                },
                {
                    "name": "💰 Money per sec",
                    "value": f"{parsed['money']}M/s",
                    "inline": True
                },
                {
                    "name": "👥 Players",
                    "value": parsed['players'],
                    "inline": True
                },
                {
                    "name": "🔗 Join Links (Try all if first fails)",
                    "value": join_links_value,
                    "inline": False
                },
                {
                    "name": "⚠️ Important",
                    "value": "Servers may close before you join. If links don't work, the server expired. Try the backup link or join the game manually.",
                    "inline": False
                }
            ],
            "footer": {
                "text": "Roblox AutoJoiner"
            },
            "timestamp": None  # Will be set by Discord automatically
        }
        
        payload = {
            "embeds": [embed]
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(webhook_url, json=payload) as resp:
                if resp.status == 204:
                    logger.info(f"✅ Webhook sent successfully for {parsed['name']} ({parsed['money']}M/s)")
                else:
                    logger.error(f"Failed to send webhook: HTTP {resp.status}")
    
    except Exception as e:
        logger.error(f"Error sending webhook notification: {e}")

async def heartbeat(ws, interval):
    """Send periodic heartbeat to keep connection alive"""
    while True:
        await asyncio.sleep(interval)
        try:
            heartbeat_payload = {"op": 1, "d": None}
            await ws.send(json.dumps(heartbeat_payload))
            logger.debug("💓 Heartbeat sent")
        except Exception as e:
            logger.error(f"Failed to send heartbeat: {e}")
            break

async def identify(ws):
    identify_payload = {
        "op": 2,
        "d": {
            "token": DISCORD_TOKEN,
            "properties": {
                "os": "Windows", "browser": "Chrome", "device": "", "system_locale": "en-US",
                "browser_user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
                "referrer": "https://discord.com/", "referring_domain": "discord.com"
            }
        }
    }

    await ws.send(json.dumps(identify_payload))
    logger.info("✅ Client authenticated successfully")

    # Subscribe to data source server for real-time updates
    payload = {
        "op": 37,  # Discord Gateway opcode for Guild Subscriptions
        "d": {
            "subscriptions": {
                DATA_SOURCE_SERVER_ID: {
                    "typing": True, 
                    "threads": True, 
                    "activities": True, 
                    "members": [], 
                    "member_updates": False, 
                    "channels": {}, 
                    "thread_member_lists": []
                }
            }
        }
    }
    await ws.send(json.dumps(payload))
    
    logger.info("✅ Connected to data source server")
    logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    logger.info("📡 Monitoring active - Waiting for new targets...")
    logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

async def message_check(event):
    channel_id = event['d']['channel_id']
    result, category = check_channel(channel_id)
    if result:
        try:
            parsed = extract_server_info(event)
            if not parsed: return

            if parsed['money'] < MONEY_THRESHOLD[0] or parsed['money'] > MONEY_THRESHOLD[1]:
                return

            if category not in READ_CHANNELS:
                # logger.warning(f"Skipped brainrot channel {category} not in READ_CHANNELS")
                return

            if parsed['name'] == "Unknown" and IGNORE_UNKNOWN:
                logger.warning("Skipped unknown brainrot")
                return

            if int(parsed['players']) >= PLAYER_TRESHOLD:
                logger.warning(f"Skipped server {parsed['players']} >= {PLAYER_TRESHOLD} players")
                return

            if FILTER_BY_NAME[0]:
                if parsed['name'] not in FILTER_BY_NAME[1]:
                    logger.warning(f"Skip brainrot {parsed['name']} not in filter by name list")
                    return

            if parsed['name'] in IGNORE_LIST:
                logger.warning(f"Skip brainrot {parsed['name']} in ignore list")
                return


            if parsed['money'] >= 10.0:
                if not BYPASS_10M:
                    logger.warning("Skip 10m+ server because bypass turned off")
                    return

                await server.broadcast(parsed['job_id'])
            else:
                await server.broadcast(parsed['script'])
            
            # Send webhook notification
            await send_webhook_notification(parsed)
            
            # Log Place ID for verification
            if parsed.get('place_id'):
                logger.info(f"📍 Detected Place ID from script: {parsed['place_id']}")
            
            logger.info(f"✅ Target processed: {parsed['name']} | {category} | {parsed['money']}M/s")
        except Exception as e:
            logger.debug(f"Failed to check message: {e}")

async def message_listener(ws, heartbeat_task=None):
    logger.info("Listening new messages...")
    while True:
        event = json.loads(await ws.recv())
        #logger.info(f"Получил ивент: {str(event)[:2000]}")
        op_code = event.get("op", None)

        if op_code == 10: # Hello - Start heartbeat
            heartbeat_interval = event['d']['heartbeat_interval'] / 1000.0  # Convert ms to seconds
            logger.debug(f"Received Hello. Starting heartbeat every {heartbeat_interval}s")
            if heartbeat_task:
                heartbeat_task.cancel()
            heartbeat_task = asyncio.create_task(heartbeat(ws, heartbeat_interval))

        elif op_code == 11: # Heartbeat ACK
            logger.debug("💚 Heartbeat acknowledged")

        elif op_code == 0: # Dispatch
            #last_sequence = event.get("s", None)
            event_type = event.get("t")

            if event_type == "MESSAGE_CREATE" and not server.paused:
                await message_check(event) # nоtasnek

        elif op_code == 9: # Invalid Session
            logger.warning("⚠️ Session expired - reconnecting...")
            await identify(ws)


async def listener():
    set_console_title(f"Server Monitor | Status: Active")
    while True:
        try:
            async with websockets.connect(DISCORD_WS_URL, max_size=None) as ws:
                await identify(ws)
                await message_listener(ws)

        except websockets.exceptions.ConnectionClosed as e:
            logger.error(f"❌ Connection lost: {e}")
            logger.info("🔄 Reconnecting in 3 seconds...")
            await asyncio.sleep(3)
            continue

# Custom Roblox server monitoring solution