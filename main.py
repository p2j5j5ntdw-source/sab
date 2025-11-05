import asyncio
import threading
import time
from datetime import datetime

from discord import listener
from src.roblox import roblox_main


if __name__ == "__main__":
    print("=" * 60)
    print("  ROBLOX SERVER MONITORING SYSTEM")
    print("  Automated Base Finder & Notification Service")
    print("=" * 60)
    print()
    print(f"⏰ Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("📊 Status: Initializing...")
    print()
    print("━" * 60)
    print("  FEATURES:")
    print("  ✅ Real-time server monitoring")
    print("  ✅ Smart filtering system")
    print("  ✅ Discord webhook notifications")
    print("  ✅ Mobile-friendly join links")
    print("  ✅ Auto-join capability")
    print("━" * 60)
    print()
    print("⚡ Launching in 2 seconds...")
    print()

    time.sleep(2)

    threading.Thread(target=roblox_main, daemon=True).start()
    asyncio.run(listener())