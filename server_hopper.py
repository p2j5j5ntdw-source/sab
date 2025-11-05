"""
Auto Server Hopper for Roblox
Automatically fetches and joins different servers for the brainrot game
"""
import asyncio
import aiohttp
import json
import subprocess
import time
import random
from datetime import datetime

# Configuration
PLACE_ID = "109983668079237"  # Steal A Brainrot Place ID
ROBLOX_API_URL = f"https://games.roblox.com/v1/games/{PLACE_ID}/servers/Public?sortOrder=Asc&limit=100"
JOIN_DELAY = 5  # Seconds to wait between joins
MIN_PLAYERS = 0  # Minimum players on server
MAX_PLAYERS = 8  # Maximum players on server (skip if more)

class ServerHopper:
    def __init__(self):
        self.visited_servers = set()
        self.session = None
        
    async def fetch_servers(self):
        """Fetch available servers from Roblox API"""
        try:
            async with self.session.get(ROBLOX_API_URL) as response:
                if response.status == 200:
                    data = await response.json()
                    return data.get('data', [])
                else:
                    print(f"❌ API Error: {response.status}")
                    return []
        except Exception as e:
            print(f"❌ Error fetching servers: {e}")
            return []
    
    def filter_servers(self, servers):
        """Filter servers based on player count"""
        filtered = []
        for server in servers:
            player_count = server.get('playing', 0)
            max_players = server.get('maxPlayers', 50)
            
            # Check player count
            if MIN_PLAYERS <= player_count <= MAX_PLAYERS:
                server_id = server.get('id')
                if server_id and server_id not in self.visited_servers:
                    filtered.append(server)
        
        return filtered
    
    def join_server(self, server):
        """Join a Roblox server using job ID"""
        server_id = server.get('id')
        if not server_id:
            return False
        
        try:
            # Create join URL
            join_url = f"roblox://experiences/start?placeId={PLACE_ID}&gameInstanceId={server_id}"
            
            # Open Roblox with join URL (Windows)
            subprocess.Popen(['start', join_url], shell=True)
            
            print(f"✅ Joining server: {server_id[:20]}... ({server.get('playing', 0)}/{server.get('maxPlayers', 50)} players)")
            self.visited_servers.add(server_id)
            return True
            
        except Exception as e:
            print(f"❌ Error joining server: {e}")
            return False
    
    async def hop_servers(self):
        """Main server hopping loop"""
        print("=" * 60)
        print("  ROBLOX AUTO SERVER HOPPER")
        print("=" * 60)
        print(f"📍 Place ID: {PLACE_ID}")
        print(f"👥 Player Range: {MIN_PLAYERS}-{MAX_PLAYERS}")
        print(f"⏱️  Join Delay: {JOIN_DELAY}s")
        print("=" * 60)
        print()
        
        self.session = aiohttp.ClientSession()
        
        try:
            while True:
                print(f"\n🔍 Fetching servers... ({datetime.now().strftime('%H:%M:%S')})")
                
                servers = await self.fetch_servers()
                
                if not servers:
                    print("❌ No servers found, retrying in 10 seconds...")
                    await asyncio.sleep(10)
                    continue
                
                print(f"📊 Found {len(servers)} servers")
                
                # Filter servers
                filtered = self.filter_servers(servers)
                
                if not filtered:
                    print(f"⚠️  No suitable servers (all visited or wrong player count)")
                    print("🔄 Waiting 30 seconds before retry...")
                    await asyncio.sleep(30)
                    continue
                
                # Join a random server from filtered list
                server = random.choice(filtered)
                self.join_server(server)
                
                # Wait before next hop
                print(f"⏳ Waiting {JOIN_DELAY} seconds before next hop...")
                await asyncio.sleep(JOIN_DELAY)
                
        except KeyboardInterrupt:
            print("\n\n⚠️  Stopped by user")
        finally:
            if self.session:
                await self.session.close()

async def main():
    hopper = ServerHopper()
    await hopper.hop_servers()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n👋 Server hopper stopped")

