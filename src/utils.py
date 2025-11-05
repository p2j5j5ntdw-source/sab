from config import DATA_SOURCE_CHANNELS
import platform

if platform.system() == "Windows":
    import ctypes

def check_channel(channel_id: str):
    """Check if a channel ID belongs to monitored data sources"""
    for tier, ids in DATA_SOURCE_CHANNELS.items():
        if channel_id in ids:
            return True, tier
    return False, None


def parse_money(value: str) -> float:
    value = value.strip("*$ /s")
    if value.endswith("K"):
        return round(float(value[:-1]) / 1000, 3)
    elif value.endswith("M"):
        return round(float(value[:-1]), 3)
    elif value.endswith("B"):
        return round(float(value[:-1]) * 1000, 3)
    else:
        return 0.0


def extract_server_info(event: dict):
    result = {"name": None, "money": None, "script": None, "job_id": None, "players": None, "join_link": None, "place_id": None}

    try:
        embeds = event["d"].get("embeds", [])
        if not embeds:
            return result

        embed = embeds[0]
        
        # Check for join link in embed URL field (Discord's proper URL field)
        if embed.get("url") and "join-server.pages.dev" in embed.get("url", ""):
            result["join_link"] = embed["url"]
        
        # Check for join link in embed description (sometimes Chilli Hub puts it there)
        description = embed.get("description", "")
        if "join-server.pages.dev" in description and not result["join_link"]:
            # Extract the join link from description
            # Format: https://join-server.pages.dev/?DISCORD-DOT-GG-SLASH-SAMMY-EXCLUSIVE-BASE-FINDER-[encoded_data]&Encrypt=true
            import re
            # First try to extract from markdown format [text](url)
            markdown_match = re.search(r'\[([^\]]+)\]\((https://join-server\.pages\.dev/[^)]+)\)', description)
            if markdown_match:
                result["join_link"] = markdown_match.group(2)
            else:
                # Match everything from https:// including the complete URL
                # This pattern captures the URL even if it spans multiple "words" due to Discord formatting
                link_match = re.search(r'(https://join-server\.pages\.dev/\?[^\s\)\]<>]*)', description)
                if link_match:
                    result["join_link"] = link_match.group(1)

        fields = embed.get("fields", [])
        for field in fields:
            name = field.get("name", "").strip()
            value = field.get("value", "").strip()

            if name.startswith("🏷️ Name") or name.startswith("Name"):
                result["name"] = value.strip("*")

            elif name.startswith("💰 Money per sec") or name.startswith("Money"):
                result["money"] = parse_money(value.strip("*"))

            elif name.startswith("📜 Join Script (PC)") or name.startswith("Join Script"):
                result["script"] = value.strip("`")
                # Extract Place ID from script for verification
                if result["script"] and "TeleportToPlaceInstance" in result["script"]:
                    import re
                    place_id_match = re.search(r'TeleportToPlaceInstance\((\d+)', result["script"])
                    if place_id_match:
                        result["place_id"] = place_id_match.group(1)

            elif name.startswith("Job ID (PC)") or name.startswith("Job ID"):
                result["job_id"] = value.strip("`")

            elif name.startswith("👥 Players") or name.startswith("Players"):
                players_str = value.strip("*")
                if "/" in players_str:
                    current, _ = players_str.split("/")
                    result["players"] = current
                else:
                    result["players"] = players_str

            # Check for join link in fields
            elif ("join" in name.lower() or "link" in name.lower()) and not result["join_link"]:
                # Extract join-server.pages.dev link
                # Format: https://join-server.pages.dev/?DISCORD-DOT-GG-SLASH-SAMMY-EXCLUSIVE-BASE-FINDER-[encoded_data]&Encrypt=true
                if "join-server.pages.dev" in value:
                    import re
                    # First try markdown format [text](url)
                    markdown_match = re.search(r'\[([^\]]+)\]\((https://join-server\.pages\.dev/[^)]+)\)', value)
                    if markdown_match:
                        result["join_link"] = markdown_match.group(2)
                    else:
                        # Match the complete URL
                        link_match = re.search(r'(https://join-server\.pages\.dev/\?[^\s\)\]<>]*)', value)
                        if link_match:
                            result["join_link"] = link_match.group(1)

    except Exception as e:
        #print(f"Error parsing message: {e}")
        pass

    return result

def set_console_title(title: str):
    """Set console window title on Windows systems"""
    if platform.system() == "Windows":
        ctypes.windll.kernel32.SetConsoleTitleW(title)
    return

# Professional server monitoring utilities
