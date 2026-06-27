import discord
from discord.ui import Button, View
import os
import subprocess
import requests
import tempfile
import sys
import json
import asyncio
from pathlib import Path
from aiohttp import web

intents = discord.Intents.default()
intents.message_content = True
client = discord.Client(intents=intents)

# ==================== SETTINGS ====================
SETTINGS_FILE = Path("bot_settings.json")

DEFAULT_SETTINGS = {
    "hookOp": False,
    "explore_funcs": True,
    "spyexeconly": False,
    "no_string_limit": False,
    "minifier": False,
    "comments": True,
    "ui_detection": False,
    "notify_scamblox": False,
    "constant_collection": False,
    "duplicate_searcher": False,
    "neverNester": False
}

SETTING_DESCRIPTIONS = {
    "hookOp": "Hook operations (repeat, while, if, comparisons)",
    "explore_funcs": "Show full function bodies",
    "spyexeconly": "Only spy executor variables",
    "no_string_limit": "No string truncation",
    "minifier": "Minify/inline output",
    "comments": "Show helpful comments",
    "ui_detection": "Detect UI libraries [EXPERIMENTAL]",
    "notify_scamblox": "Notify scam detection (Premium only)",
    "constant_collection": "Collect all strings",
    "duplicate_searcher": "Search for duplicate files",
    "neverNester": "Prevent nested if checks"
}

def load_settings():
    if SETTINGS_FILE.exists():
        try:
            with open(SETTINGS_FILE, 'r') as f:
                return json.load(f)
        except:
            return {}
    return {}

def save_settings(settings):
    with open(SETTINGS_FILE, 'w') as f:
        json.dump(settings, f, indent=2)

def get_user_settings(user_id):
    all_settings = load_settings()
    user_id_str = str(user_id)
    if user_id_str not in all_settings:
        all_settings[user_id_str] = DEFAULT_SETTINGS.copy()
        save_settings(all_settings)
    return all_settings[user_id_str]

def update_user_setting(user_id, setting_name, value):
    all_settings = load_settings()
    user_id_str = str(user_id)
    if user_id_str not in all_settings:
        all_settings[user_id_str] = DEFAULT_SETTINGS.copy()
    all_settings[user_id_str][setting_name] = value
    save_settings(all_settings)

# ==================== HELP ====================
def create_help_embed():
    embed = discord.Embed(
        title="Lune Env Logger - Help",
        description="Commands:\n"
                    ".l - Log and reconstruct Lua script\n"
                    ".cfg - Open settings menu\n"
                    ".help - Show this help",
        color=discord.Color.blue()
    )
    embed.add_field(
        name="Usage",
        value="Reply to a message and type .l\n"
              "Or attach a file + .l\n"
              "Or paste code / URL + .l",
        inline=False
    )
    return embed

# ==================== SETTINGS VIEW ====================
class SettingsView(View):
    def __init__(self, user_id, settings):
        super().__init__(timeout=300)
        self.user_id = user_id
        self.settings = settings
        self.create_buttons()

    def create_buttons(self):
        self.clear_items()
        for setting_name, description in SETTING_DESCRIPTIONS.items():
            is_enabled = self.settings.get(setting_name, False)
            button = Button(
                label=f"{'ON' if is_enabled else 'OFF'} {setting_name}",
                style=discord.ButtonStyle.success if is_enabled else discord.ButtonStyle.secondary,
                custom_id=setting_name
            )
            button.callback = self.create_callback(setting_name)
            self.add_item(button)

    def create_callback(self, setting_name):
        async def callback(interaction: discord.Interaction):
            if interaction.user.id != self.user_id:
                await interaction.response.send_message("These are not your settings!", ephemeral=True)
                return
            
            current = self.settings.get(setting_name, False)
            new_value = not current
            update_user_setting(self.user_id, setting_name, new_value)
            self.settings[setting_name] = new_value
            self.create_buttons()
            embed = create_settings_embed(self.settings)
            await interaction.response.edit_message(embed=embed, view=self)
        return callback

def create_settings_embed(settings):
    embed = discord.Embed(
        title="Lune Env Logger - Settings",
        description="Toggle your preferences below",
        color=discord.Color.blue()
    )
    for name, desc in SETTING_DESCRIPTIONS.items():
        status = "ON" if settings.get(name, False) else "OFF"
        embed.add_field(name=name, value=f"{desc}\nStatus: {status}", inline=False)
    return embed

# ==================== KEEP ALIVE ====================
async def keep_alive():
    async def handler(request):
        return web.Response(text="Lune Env Logger is running")
    app = web.Application()
    app.router.add_get('/', handler)
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, '0.0.0.0', 8080)
    await site.start()
    print("Keep-alive server running on port 8080")

# ==================== LOG COMMAND ====================
@client.event
async def on_ready():
    print(f'Logged in as {client.user}')
    await keep_alive()

@client.event
async def on_message(message: discord.Message):
    if message.author == client.user:
        return

    content = message.content.strip().lower()

    if content == ".help":
        await message.channel.send(embed=create_help_embed())
        return

    if content == ".cfg":
        user_settings = get_user_settings(message.author.id)
        embed = create_settings_embed(user_settings)
        view = SettingsView(message.author.id, user_settings)
        await message.channel.send(embed=embed, view=view)
        return

    if content.startswith(".l"):
        await handle_log_command(message)

async def handle_log_command(message: discord.Message):
    code_to_run = ""

    # Reply support
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

    # Attachment support
    if not code_to_run and message.attachments:
        try:
            resp = requests.get(message.attachments[0].url)
            code_to_run = resp.text
        except Exception as e:
            await message.channel.send(f"Error reading attachment: {e}")
            return

    # URL support
    if not code_to_run:
        for word in message.content.split():
            if word.startswith(("http://", "https://")):
                try:
                    resp = requests.get(word)
                    code_to_run = resp.text
                    break
                except:
                    pass

    # Code from message
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
            code_to_run = message.content[2:].strip()  # remove .l

    if not code_to_run:
        await message.channel.send("Please provide code, reply to a message, attach a file, or give a URL.")
        return

    try:
        user_settings = get_user_settings(message.author.id)

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
        env = os.environ.copy()
        for setting, value in user_settings.items():
            env[f"SETTING_{setting.upper()}"] = "1" if value else "0"

        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30, env=env)
        os.remove(tmp_path)

        output = result.stdout
        if result.stderr:
            output += "\n-- STDERR --\n" + result.stderr
        if not output.strip():
            output = "-- No output from reconstructor --"

        # Save output as logged.lua
        with tempfile.NamedTemporaryFile(mode='w', suffix='.lua', delete=False, encoding='utf-8') as log_file:
            log_file.write(output)
            log_file_path = log_file.name

        await message.channel.send("done son!", file=discord.File(log_file_path, "logged.lua"))
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
