import discord
import os
import subprocess
import requests
import tempfile
import sys
import time
from pathlib import Path
from aiohttp import web

intents = discord.Intents.default()
intents.message_content = True
client = discord.Client(intents=intents)

# ==================== CHANNEL WHITELIST ====================
ALLOWED_CHANNELS = [
    1520270151961018519,  # ← Change this to your channel ID
    # Add more channel IDs below if needed
    # 987654321098765432,
]

async def keep_alive():
    async def handler(request):
        return web.Response(text="LUNE ENV LOGGER IS RUNNING -@kvna")
    app = web.Application()
    app.router.add_get('/', handler)
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, '0.0.0.0', 8080)
    await site.start()
    print("Keep-alive server running on port 8080")

@client.event
async def on_ready():
    print(f'Logged in as {client.user}')
    activity = discord.Activity(type=discord.ActivityType.watching, name="Lune Logger | .l")
    await client.change_presence(activity=activity)
    await keep_alive()

@client.event
async def on_message(message: discord.Message):
    if message.author == client.user:
        return

    # Channel Whitelist Check
    if message.channel.id not in ALLOWED_CHANNELS:
        return

    content = message.content.strip().lower()

    if content == ".help":
        help_text = """```inline
Lune Env Logger Help

Commands:
.l    - Log and reconstruct Lua script
.help - Show this help

Usage:
• Reply to a message + .l
• Attach a .lua file + .l
• Paste code or URL + .l
```"""
        await message.channel.send(help_text)
        return

    if content.startswith(".l"):
        await handle_log_command(message)

async def handle_log_command(message: discord.Message):
    start_time = time.time()

    code_to_run = ""

    # Support Reply
    if message.reference and message.reference.resolved:
        replied = message.reference.resolved
        if replied.attachments:
            try:
                resp = requests.get(replied.attachments[0].url)
                code_to_run = resp.text
            except:
                pass
        else:
            code_to_run = replied.content

    # Support Attachment
    if not code_to_run and message.attachments:
        try:
            resp = requests.get(message.attachments[0].url)
            code_to_run = resp.text
        except Exception as e:
            await message.channel.send(f"Error reading attachment: {e}")
            return

    # Support URL
    if not code_to_run:
        for word in message.content.split():
            if word.startswith(("http://", "https://")):
                try:
                    resp = requests.get(word)
                    code_to_run = resp.text
                    break
                except:
                    pass

    # Support direct code
    if not code_to_run:
        if "```" in message.content:
            start = message.content.find("```") + 3
            end = message.content.rfind("```")
            if start < end:
                first_line_end = message.content.find("\n", start)
                if first_line_end != -1 and first_line_end < end:
                    lang = message.content[start:first_line_end].strip()
                    if lang and " " not in lang:
                        start = first_line_end + 1
                code_to_run = message.content[start:end].strip()
        else:
            code_to_run = message.content[2:].strip()

    if not code_to_run:
        await message.channel.send("Please provide code, reply to a message, attach a file, or give a URL.")
        return

    try:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.lua', delete=False, encoding='utf-8') as tmp:
            tmp.write(code_to_run)
            tmp_path = tmp.name

        lune_exec = "lune"
        if os.path.exists("lune.exe"):
            lune_exec = os.path.abspath("lune.exe")
        elif os.path.exists("lune"):
            lune_exec = os.path.abspath("lune")

        logger_path = os.path.join("src", "code_reconstructor.lua")

        cmd = [lune_exec, "run", logger_path, tmp_path]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        os.remove(tmp_path)

        output = result.stdout
        if result.stderr:
            output += "\n-- STDERR --\n" + result.stderr

        if not output.strip():
            output = "-- No output from reconstructor --"

        final_output = "--ts file was generated on aetheria // reversing\n\n" + output

        with tempfile.NamedTemporaryFile(mode='w', suffix='.lua', delete=False, encoding='utf-8') as log_file:
            log_file.write(final_output)
            log_file_path = log_file.name

        ms = int((time.time() - start_time) * 1000)
        await message.channel.send(f"done son! {ms}ms", file=discord.File(log_file_path, "logged.lua"))
        os.remove(log_file_path)

    except subprocess.TimeoutExpired:
        await message.channel.send("Execution timed out.")
    except Exception as e:
        await message.channel.send(f"Error: {e}")

if __name__ == "__main__":
    token = os.environ.get('DISCORD_TOKEN')
    if not token:
        print("DISCORD_TOKEN environment variable not set!")
        sys.exit(1)
    client.run(token)
