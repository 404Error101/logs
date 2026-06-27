-- ADVANCED ENVIRONMENT LOGGER & CODE RECONSTRUCTOR
-- Comprehensive detection, logging, and analysis system
-- Outputs ONLY reconstructed code with inline detection
local process = require("@lune/process")
local fs = require("@lune/fs")

local scriptPath = process.args[1]
if not scriptPath then
    print("Usage: lune run advanced_env_logger.lua <script_path>")
    process.exit(1)
end

local scriptContent = fs.readFile(scriptPath)

-- ═══════════════════════════════════════════════════════════════════════
-- SETTINGS & CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════
local settings = {
    -- Core features
    hookOp = process.env.SETTING_HOOKOP == "1",
    explore_funcs = process.env.SETTING_EXPLORE_FUNCS == "1",
    spyexeconly = process.env.SETTING_SPYEXECONLY == "1",
    no_string_limit = process.env.SETTING_NO_STRING_LIMIT == "1",
    minifier = process.env.SETTING_MINIFIER == "1",
    comments = process.env.SETTING_COMMENTS == "1",
    ui_detection = process.env.SETTING_UI_DETECTION == "1",
    
    -- Advanced detection
    detect_webhooks = process.env.SETTING_DETECT_WEBHOOKS ~= "0",
    detect_loadstring = process.env.SETTING_DETECT_LOADSTRING ~= "0",
    detect_obfuscation = process.env.SETTING_DETECT_OBFUSCATION ~= "0",
    detect_injection = process.env.SETTING_DETECT_INJECTION ~= "0",
    detect_exfiltration = process.env.SETTING_DETECT_EXFILTRATION ~= "0",
    detect_metamethods = process.env.SETTING_DETECT_METAMETHODS ~= "0",
    detect_pcall_hooks = process.env.SETTING_DETECT_PCALL_HOOKS ~= "0",
    detect_coroutines = process.env.SETTING_DETECT_COROUTINES ~= "0",
    
    -- Network & fetch
    allow_fetch = process.env.SETTING_ALLOW_FETCH == "1",
    fetch_timeout = tonumber(process.env.SETTING_FETCH_TIMEOUT) or 10,
    fetch_retries = tonumber(process.env.SETTING_FETCH_RETRIES) or 1,
    fetch_follow_redirects = process.env.SETTING_FETCH_FOLLOW_REDIRECTS ~= "0",
    cache_enabled = process.env.SETTING_FETCH_CACHE == "1",
    cache_dir = process.env.SETTING_FETCH_CACHE_DIR or ".fetch_cache",
    
    -- Analysis & output
    verbose = process.env.SETTING_VERBOSE == "1",
    output_file = process.env.SETTING_OUTPUT_FILE or nil,
    inline_output = process.env.SETTING_INLINE_OUTPUT ~= "0",
    track_stack = process.env.SETTING_TRACK_STACK ~= "0",
    log_environment_changes = process.env.SETTING_LOG_ENV_CHANGES ~= "0"
}

-- Parse CLI arguments
for i = 2, #process.args do
    local a = process.args[i]
    if a == "--allow-fetch" then settings.allow_fetch = true end
    if a == "--no-fetch" then settings.allow_fetch = false end
    if a:match("^--fetch-timeout=") then settings.fetch_timeout = tonumber(a:match("^--fetch-timeout=(%d+)")) or settings.fetch_timeout end
    if a:match("^--fetch-retries=") then settings.fetch_retries = tonumber(a:match("^--fetch-retries=(%d+)")) or settings.fetch_retries end
    if a == "--verbose" then settings.verbose = true end
    if a == "--inline" then settings.inline_output = true end
    local out = a:match("^--output=(.+)$")
    if out then settings.output_file = out end
    local cache = a:match("^--cache-dir=(.+)$")
    if cache then settings.cache_dir = cache end
end

-- ═══════════════════════════════════════════════════════════════════════
-- DETECTION & TRACKING SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

local detections = {
    webhooks = {},
    loadstrings = {},
    obfuscation = {},
    injections = {},
    exfiltrations = {},
    metamethods = {},
    pcall_hooks = {},
    coroutines = {},
    http_requests = {},
    file_operations = {},
    environment_changes = {},
    suspicious_patterns = {}
}

local detection_stats = {
    total_detections = 0,
    webhooks_found = 0,
    loadstrings_found = 0,
    suspicious_patterns_found = 0,
    http_calls = 0,
    file_ops = 0
}

-- ═══════════════════════════════════════════════════════════════════════
-- URL DETECTION & ANALYSIS
-- ═══════════════════════════════════════════════════════════════════════

local url_patterns = {
    webhook = "discord%.com/api/webhooks",
    slack = "hooks%.slack%.com",
    telegram = "api%.telegram%.org",
    webhook_generic = "webhook",
    http_url = "https?://[%w%.%-_/:%?&=#]+",
    ip_address = "%d+%.%d+%.%d+%.%d+",
    localhost = "localhost:%d+",
    ngrok = "ngrok%.io",
    pastebin = "pastebin%.com",
    hastebin = "hastebin%.com"
}

local function detect_url_type(url)
    url = tostring(url):lower()
    
    if url:match(url_patterns.webhook) then
        return "discord_webhook"
    elseif url:match(url_patterns.slack) then
        return "slack_webhook"
    elseif url:match(url_patterns.telegram) then
        return "telegram_api"
    elseif url:match(url_patterns.webhook_generic) then
        return "generic_webhook"
    elseif url:match(url_patterns.ngrok) then
        return "ngrok_tunnel"
    elseif url:match(url_patterns.pastebin) then
        return "pastebin_fetch"
    elseif url:match(url_patterns.hastebin) then
        return "hastebin_fetch"
    elseif url:match(url_patterns.ip_address) then
        return "ip_address"
    elseif url:match(url_patterns.localhost) then
        return "localhost"
    elseif url:match(url_patterns.http_url) then
        return "http_url"
    end
    
    return "unknown_url"
end

local function analyze_url(url, context)
    local url_type = detect_url_type(url)
    local detection_info = {
        url = url,
        type = url_type,
        context = context,
        timestamp = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    table.insert(detections.http_requests, detection_info)
    detection_stats.http_calls = detection_stats.http_calls + 1
    detection_stats.total_detections = detection_stats.total_detections + 1
    
    if url_type == "discord_webhook" or url_type == "slack_webhook" or url_type == "telegram_api" then
        detection_stats.webhooks_found = detection_stats.webhooks_found + 1
        table.insert(detections.webhooks, detection_info)
    end
    
    return detection_info
end

-- ══════════════════════════════════════════════════════════���════════════
-- OBFUSCATION DETECTION
-- ═══════════════════════════════════════════════════════════════════════

local obfuscation_patterns = {
    xor_ops = "XOR%s*%(%s*",
    base64 = "base64",
    hex_encoding = "%x%x%x%x",
    string_rotation = "string%.rot",
    bitwise_ops = "bit%.bxor|bit%.band|bit%.bor",
    char_codes = "string%.char%s*%(",
    table_unpacking = "unpack%s*%(",
    load_variants = "load%s*%(",
    unicode_escape = "\\u%x+",
    hex_escape = "\\x%x+",
}

local function detect_obfuscation(code)
    local score = 0
    local techniques = {}
    
    if code:match(obfuscation_patterns.char_codes) then
        score = score + 10
        table.insert(techniques, "char_code_obfuscation")
    end
    
    if code:match(obfuscation_patterns.bitwise_ops) then
        score = score + 15
        table.insert(techniques, "bitwise_operations")
    end
    
    if code:match(obfuscation_patterns.table_unpacking) then
        score = score + 5
        table.insert(techniques, "table_unpacking")
    end
    
    if code:match(obfuscation_patterns.load_variants) then
        score = score + 20
        table.insert(techniques, "dynamic_loading")
    end
    
    if code:match(obfuscation_patterns.unicode_escape) or code:match(obfuscation_patterns.hex_escape) then
        score = score + 12
        table.insert(techniques, "escape_sequence_encoding")
    end
    
    local long_var_names = code:match("%a%w%w%w%w%w%w%w%w%w%w+")
    if long_var_names then
        score = score + 3
    end
    
    local minimal_spacing = code:match("=[^=][^%s]")
    if minimal_spacing then
        score = score + 5
        table.insert(techniques, "minimal_formatting")
    end
    
    return {
        score = score,
        level = score >= 40 and "high" or score >= 20 and "medium" or "low",
        techniques = techniques
    }
end

-- ═══════════════════════════════════════════════════════════════════════
-- INJECTION & HOOKING DETECTION
-- ═══════════════════════════════════════════════════════════════════════

local function detect_injection_attempts(code)
    local injections = {}
    
    -- Detect hook attempts
    if code:match("hookfunction") or code:match("hook_func") then
        table.insert(injections, {type = "function_hook", method = "hookfunction"})
    end
    
    if code:match("hookmetamethod") then
        table.insert(injections, {type = "metamethod_hook", method = "hookmetamethod"})
    end
    
    if code:match("setfenv") or code:match("getfenv") then
        table.insert(injections, {type = "environment_manipulation", method = "fenv"})
    end
    
    if code:match("debug%.setlocal") or code:match("debug%.getlocal") then
        table.insert(injections, {type = "debug_manipulation", method = "debug_api"})
    end
    
    if code:match("rawset") then
        table.insert(injections, {type = "raw_table_modification", method = "rawset"})
    end
    
    if code:match("setmetatable") and not code:match("--") then
        table.insert(injections, {type = "metatable_modification", method = "setmetatable"})
    end
    
    if code:match("getconnections") or code:match("firesignal") then
        table.insert(injections, {type = "signal_injection", method = "firesignal"})
    end
    
    return injections
end

-- ═══════════════════════════════════════════════════════════════════════
-- DATA EXFILTRATION DETECTION
-- ═══════════════════════════════════════════════════════════════════════

local exfiltration_patterns = {
    send_data = "HttpPost|HttpGet|request|fetch",
    clipboard = "setclipboard",
    file_write = "writefile|delfolder",
    game_objects = "game%.Players|workspace%..*|script%.Parent",
    local_player = "game%.Players%.LocalPlayer",
    character = "Character|Humanoid|Backpack",
    exploit_env = "getgenv|getreg|getgc|getinstances"
}

local function detect_exfiltration(code)
    local exfils = {}
    
    if code:match(exfiltration_patterns.send_data) then
        table.insert(exfils, {type = "data_transmission", methods = {"http", "request"}})
    end
    
    if code:match(exfiltration_patterns.clipboard) then
        table.insert(exfils, {type = "clipboard_write", vector = "system_clipboard"})
    end
    
    if code:match(exfiltration_patterns.local_player) then
        table.insert(exfils, {type = "player_data_access", target = "LocalPlayer"})
    end
    
    if code:match(exfiltration_patterns.character) then
        table.insert(exfils, {type = "character_data_access", target = "Character"})
    end
    
    if code:match(exfiltration_patterns.exploit_env) then
        table.insert(exfils, {type = "environment_enumeration", method = "exploit_functions"})
    end
    
    return exfils
end

-- ═══════════════════════════════════════════════════════════════════════
-- CODE RECONSTRUCTION BUFFER & UTILITIES
-- ═══════════════════════════════════════════════════════════════════════

local codeLines = {}
local stackTrace = {}

local function truncateString(str, maxLen)
    if settings.no_string_limit or #str <= maxLen then
        return str
    end
    local remaining = #str - maxLen
    return str:sub(1, maxLen) .. "...(" .. remaining .. " bytes left)"
end

local function addCode(code, meta)
    if settings.inline_output then
        if meta then
            table.insert(codeLines, code .. " --[[" .. meta .. "]]")
        else
            table.insert(codeLines, code)
        end
    else
        table.insert(codeLines, code)
    end
end

local function addComment(comment)
    if settings.comments then
        table.insert(codeLines, "-- " .. comment)
    end
end

local function addDetection(detection_type, data)
    local meta = detection_type .. ": " .. (type(data) == "string" and data or "detected")
    if settings.inline_output then
        table.insert(codeLines, "--[[ DETECTION: " .. meta .. " ]]")
    end
    detection_stats.total_detections = detection_stats.total_detections + 1
end

local function pushStack(context)
    if settings.track_stack then
        table.insert(stackTrace, {
            context = context,
            timestamp = os.date("%H:%M:%S"),
            line_count = #codeLines
        })
    end
end

local function popStack()
    if settings.track_stack and #stackTrace > 0 then
        table.remove(stackTrace)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- ENVIRONMENT SETUP
-- ═══════════════════════════════════════════════════════════════════════

local env = {}
local instanceCounter = 0
local instances = {}
local functionCounter = 0
local trackedFunctions = {}

-- ═══════════════════════════════════════════════════════════════════════
-- PRINT & WARN WITH LOGGING
-- ═══════════════════════════════════════════════════════════════════════

env.print = function(...)
    local args = {...}
    local strs = {}
    for i, v in ipairs(args) do
        if type(v) == "string" then
            strs[i] = '"' .. truncateString(tostring(v), 256) .. '"'
        else
            strs[i] = tostring(v)
        end
    end
    addCode("print(" .. table.concat(strs, ", ") .. ")")
end

env.warn = function(...)
    local args = {...}
    local strs = {}
    for i, v in ipairs(args) do
        if type(v) == "string" then
            strs[i] = '"' .. truncateString(tostring(v), 256) .. '"'
        else
            strs[i] = tostring(v)
        end
    end
    addCode("warn(" .. table.concat(strs, ", ") .. ")")
end

-- ═══════════════════════════════════════════════════════════════════════
-- MOCK INSTANCES & EVENTS
-- ═══════════════════════════════════════════════════════════════════════

local function createEvent()
    return setmetatable({}, {
        __index = function(t, k)
            if k == "Wait" or k == "wait" then
                return function() return nil end
            elseif k == "Connect" or k == "connect" or k == "ConnectParallel" then
                return function(self, callback)
                    return setmetatable({
                        Connected = true,
                        Disconnect = function(self) self.Connected = false end,
                        disconnect = function(self) self.Connected = false end
                    }, {
                        __tostring = function() return "RBXScriptConnection" end
                    })
                end
            elseif k == "Fire" or k == "fire" or k == "FireServer" then
                return function() end
            end
            return createEvent()
        end,
        __call = function(t, ...)
            return nil
        end,
        __tostring = function() return "RBXScriptSignal" end
    })
end

local function createGenericProxy(name)
    return setmetatable({__name = name}, {
        __index = function(t, k)
            return function(...) return createEvent() end
        end,
        __newindex = function(t, k, v) end,
        __call = function(t, ...) return createEvent() end,
        __tostring = function() return name end
    })
end

local function createMockInstance(className, varName)
    local mock = {
        __className = className,
        __varName = varName,
        Name = className,
        Parent = nil
    }
    
    return setmetatable(mock, {
        __index = function(t, k)
            if k == "WaitForChild" or k == "FindFirstChild" or k == "FindFirstChildOfClass" then
                return function(self, childName)
                    return createMockInstance(childName or "Child", childName or "Child")
                end
            elseif k == "GetChildren" or k == "GetDescendants" then
                return function() return {} end
            elseif k == "GetPropertyChangedSignal" then
                return function(self, propName) return createEvent() end
            elseif k == "Destroy" or k == "destroy" then
                return function() end
            elseif k == "Clone" or k == "clone" then
                return function() return createMockInstance(className, varName .. "_Clone") end
            elseif k == "Connect" then
                return function(self, callback) return createEvent() end
            elseif k == "IsA" then
                return function(self, typeName) return typeName == className end
            elseif k:match("Click") or k:match("Input") or k:match("Changed") or k:match("beat") or k:match("Added") or k:match("Removing") or k:match("Enter") or k:match("Leave") then
                return createEvent()
            else
                return createEvent()
            end
        end,
        __newindex = function(t, k, v)
            local valueStr
            if type(v) == "string" then
                valueStr = '"' .. v .. '"'
            elseif type(v) == "number" or type(v) == "boolean" then
                valueStr = tostring(v)
            elseif type(v) == "table" then
                if v.__varName then
                    valueStr = v.__varName
                else
                    local mt = getmetatable(v)
                    if mt and mt.__tostring then
                        valueStr = tostring(v)
                    else
                        valueStr = "table"
                    end
                end
            else
                valueStr = tostring(v)
            end
            addCode(varName .. "." .. k .. " = " .. valueStr)
        end,
        __call = function(t, ...)
            return createEvent()
        end,
        __tostring = function()
            return varName
        end
    })
end

-- ═══════════════════════════════════════════════════════════════════════
-- INSTANCE TRACKING & CREATION
-- ═══════════════════════════════════════════════════════════════════════

env.Instance = {
    new = function(className, parent)
        instanceCounter = instanceCounter + 1
        local varName = "Instance" .. instanceCounter
        instances[varName] = className
        
        if parent then
            addCode("local " .. varName .. ' = Instance.new("' .. className .. '", ' .. tostring(parent) .. ")")
        else
            addCode("local " .. varName .. ' = Instance.new("' .. className .. '")')
        end
        
        if settings.log_environment_changes then
            addDetection("instance_creation", className)
        end
        
        return createMockInstance(className, varName)
    end
}

-- ═══════════════════════════════════════════════════════════════════════
-- MATH TYPES (Vector3, Color3, UDim, etc.)
-- ═══════════════════════════════════════════════════════════════════════

env.Vector3 = {
    new = function(x, y, z)
        return setmetatable({}, {
            __tostring = function() return string.format("Vector3.new(%g, %g, %g)", x or 0, y or 0, z or 0) end
        })
    end
}

env.Color3 = {
    fromRGB = function(r, g, b)
        return setmetatable({}, {
            __tostring = function() return string.format("Color3.fromRGB(%d, %d, %d)", r, g, b) end
        })
    end,
    new = function(r, g, b)
        return setmetatable({}, {
            __tostring = function() return string.format("Color3.new(%g, %g, %g)", r, g, b) end
        })
    end,
    fromHSV = function(h, s, v)
        return setmetatable({}, {
            __tostring = function() return string.format("Color3.fromHSV(%g, %g, %g)", h, s, v) end
        })
    end
}

env.UDim = {
    new = function(s, o)
        return setmetatable({}, {
            __tostring = function() return string.format("UDim.new(%g, %g)", s, o) end
        })
    end
}

env.UDim2 = {
    new = function(xs, xo, ys, yo)
        return setmetatable({}, {
            __tostring = function() return string.format("UDim2.new(%g, %g, %g, %g)", xs, xo, ys, yo) end
        })
    end
}

env.Vector2 = {
    new = function(x, y)
        return setmetatable({}, {
            __tostring = function() return string.format("Vector2.new(%g, %g)", x, y) end
        })
    end
}

env.BrickColor = {
    new = function(name)
        return setmetatable({}, {
            __tostring = function() return 'BrickColor.new("' .. name .. '")' end
        })
    end
}

env.NumberRange = {
    new = function(...)
        local args = {...}
        return setmetatable({}, {
            __tostring = function() return "NumberRange.new(" .. table.concat(args, ", ") .. ")" end
        })
    end
}

env.NumberSequence = {
    new = function(...)
        return setmetatable({}, {
            __tostring = function() return "NumberSequence.new(...)" end
        })
    end
}

env.NumberSequenceKeypoint = {
    new = function(...)
        return setmetatable({}, {
            __tostring = function() return "NumberSequenceKeypoint.new(...)" end
        })
    end
}

env.ColorSequence = {
    new = function(...)
        return setmetatable({}, {
            __tostring = function() return "ColorSequence.new(...)" end
        })
    end
}

env.ColorSequenceKeypoint = {
    new = function(...)
        return setmetatable({}, {
            __tostring = function() return "ColorSequenceKeypoint.new(...)" end
        })
    end
}

env.TweenInfo = {
    new = function(...)
        return setmetatable({}, {
            __tostring = function() return "TweenInfo.new(...)" end
        })
    end
}

-- ═══════════════════════════════════════════════════════════════════════
-- TIMING FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

env.tick = function() return os.clock() end

env.wait = function(t)
    if t then
        addCode("wait(" .. t .. ")")
    else
        addCode("wait()")
    end
    return 0
end

env.delay = function(t, f)
    addCode("delay(" .. (t or 0) .. ", function() end)")
    return 0
end

env.spawn = function(f)
    pushStack("spawn")
    addCode("spawn(function() end)")
    if type(f) == "function" then
        pcall(f)
    end
    popStack()
end

-- ═══════════════════════════════════════════════════════════════════════
-- ENUM SYSTEM
-- ═════════════════════════��═════════════════════════════════════════════

env.Enum = setmetatable({}, {
    __index = function(t, k)
        return setmetatable({}, {
            __index = function(t2, v)
                return setmetatable({}, {
                    __tostring = function() return "Enum." .. k .. "." .. v end
                })
            end
        })
    end
})

-- ═══════════════════════════════════════════════════════════════════════
-- GAME & SERVICES WITH ADVANCED DETECTION
-- ═══════════════════════════════════════════════════════════════════════

local services = {}
env.game = setmetatable({}, {
    __index = function(t, k)
        if k == "GetService" then
            return function(self, name)
                if not services[name] then
                    services[name] = createMockInstance(name, 'game:GetService("' .. name .. '")')
                    
                    if name == "Players" then
                        services[name].LocalPlayer = createMockInstance("Player", "LocalPlayer")
                        services[name].LocalPlayer.Character = createMockInstance("Character", "Character")
                        services[name].LocalPlayer.CharacterAdded = createEvent()
                        if settings.log_environment_changes then
                            addDetection("player_access", "LocalPlayer")
                        end
                    elseif name == "TweenService" then
                        services[name].Create = function(self, obj, info, props)
                            addCode('TweenService:Create(...)')
                            return setmetatable({}, {
                                __index = {
                                    Play = function() addCode("Tween:Play()") end,
                                    Cancel = function() addCode("Tween:Cancel()") end,
                                    Pause = function() addCode("Tween:Pause()") end
                                }
                            })
                        end
                    elseif name == "TeleportService" then
                        services[name].Teleport = function(self, placeId)
                            addCode("TeleportService:Teleport(" .. placeId .. ")")
                            addDetection("teleport_attempt", placeId)
                        end
                        services[name].TeleportToPlaceInstance = function(self, placeId, instanceId)
                            addCode("TeleportService:TeleportToPlaceInstance(...)")
                            addDetection("teleport_attempt", placeId)
                        end
                    elseif name == "MarketplaceService" then
                        services[name].PromptGamePassPurchase = function()
                            addCode("MarketplaceService:PromptGamePassPurchase(...)")
                            addDetection("purchase_attempt", "gamepass")
                        end
                        services[name].PromptProductPurchase = function()
                            addCode("MarketplaceService:PromptProductPurchase(...)")
                            addDetection("purchase_attempt", "product")
                        end
                    elseif name == "HttpService" then
                        services[name].PostAsync = function(self, url, data)
                            analyze_url(url, "HttpService:PostAsync")
                            addCode('HttpService:PostAsync("' .. url .. '", data)')
                            addDetection("http_post", url)
                        end
                        services[name].GetAsync = function(self, url)
                            analyze_url(url, "HttpService:GetAsync")
                            addCode('HttpService:GetAsync("' .. url .. '")')
                            addDetection("http_get", url)
                        end
                        services[name].RequestAsync = function(self, options)
                            if type(options) == "table" and options.Url then
                                analyze_url(options.Url, "HttpService:RequestAsync")
                                addDetection("http_request", options.Url)
                            end
                        end
                    end
                end
                return services[name]
            end
        end
        if k == "HttpGet" or k == "HttpGetAsync" then
            return env.HttpGet
        end
        return createEvent()
    end,
    __tostring = function() return "game" end
})

env.workspace = createMockInstance("Workspace", "workspace")
env.script = createMockInstance("Script", "script")

-- ═══════════════════════════════════════════════════════════════════════
-- HTTP FUNCTIONS WITH WEBHOOK DETECTION
-- ═══════════════════════════════════════════════════════════════════════

local function createMockResponse(body)
    return {
        Body = body or "Mock Response",
        StatusCode = 200,
        StatusMessage = "OK",
        Headers = {["Content-Type"] = "application/json"},
        Success = true
    }
end

env.HttpGet = function(url)
    url = tostring(url)
    analyze_url(url, "HttpGet")
    addCode('HttpGet("' .. url .. '")')
    addDetection("http_get", url)
    return "Mock Response"
end

env.HttpGetAsync = env.HttpGet

env.request = function(options)
    local url = type(options) == "table" and options.Url or tostring(options)
    local method = type(options) == "table" and options.Method or "GET"
    analyze_url(url, "request")
    addCode('request({Url = "' .. url .. '", Method = "' .. method .. '"})')
    addDetection("http_request", url)
    return createMockResponse()
end

env.http_request = env.request
env.syn = { request = env.request }

-- ═══════════════════════════════════════════════════════════════════════
-- FILE OPERATIONS WITH LOGGING
-- ═══════════════════════════════════════════════════════════════════════

env.writefile = function(filename, content)
    addCode('writefile("' .. filename .. '", [content])')
    addDetection("file_write", filename)
    detection_stats.file_ops = detection_stats.file_ops + 1
    table.insert(detections.file_operations, {type = "write", filename = filename, size = #content})
end

env.readfile = function(filename)
    addCode('readfile("' .. filename .. '")')
    addDetection("file_read", filename)
    detection_stats.file_ops = detection_stats.file_ops + 1
    table.insert(detections.file_operations, {type = "read", filename = filename})
    return ""
end

env.isfile = function(filename) return true end

env.delfile = function(filename)
    addCode('delfile("' .. filename .. '")')
    addDetection("file_delete", filename)
    detection_stats.file_ops = detection_stats.file_ops + 1
    table.insert(detections.file_operations, {type = "delete", filename = filename})
end

env.listfiles = function(folder)
    addCode('listfiles("' .. folder .. '")')
    addDetection("file_list", folder)
    return {}
end

env.makefolder = function(folder)
    addCode('makefolder("' .. folder .. '")')
    addDetection("folder_create", folder)
end

env.delfolder = function(folder)
    addCode('delfolder("' .. folder .. '")')
    addDetection("folder_delete", folder)
end

-- ═══════════════════════════════════════════════════════════════════════
-- LOADSTRING WITH ADVANCED DETECTION
-- ═══════════════════════════════════════════════════════════════════════

env.loadstring = function(code, chunkname)
    if settings.detect_loadstring then
        local obf_analysis = detect_obfuscation(code)
        addDetection("loadstring", "obfuscation_level:" .. obf_analysis.level)
        detection_stats.loadstrings_found = detection_stats.loadstrings_found + 1
        
        table.insert(detections.loadstrings, {
            code_preview = truncateString(code, 200),
            obfuscation = obf_analysis,
            chunk_name = chunkname
        })
        
        if settings.inline_output then
            addCode("local func = loadstring([[" .. truncateString(code, 100) .. "]])")
        else
            addCode("loadstring([[code]])")
        end
    else
        addCode("loadstring([[code]])")
    end
    
    addComment("[SECURITY] loadstring NOT executed")
    
    return function(...)
        addComment("loadstring function called")
        return nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- EXPLOIT ENVIRONMENT DETECTION
-- ═══════════════════════════════════════════════════════════════════════

env.getgenv = function()
    if settings.detect_injection then
        addDetection("exploit_env", "getgenv")
    end
    return env
end

env.getrenv = function()
    if settings.detect_injection then
        addDetection("exploit_env", "getrenv")
    end
    return env
end

env.getreg = function()
    if settings.detect_injection then
        addDetection("exploit_env", "getreg")
    end
    return {}
end

env.getgc = function()
    if settings.detect_injection then
        addDetection("exploit_env", "getgc")
    end
    return {}
end

env.getinstances = function()
    if settings.detect_injection then
        addDetection("exploit_env", "getinstances")
    end
    return {}
end

env.getnilinstances = function()
    if settings.detect_injection then
        addDetection("exploit_env", "getnilinstances")
    end
    return {}
end

env.getloadedmodules = function()
    if settings.detect_injection then
        addDetection("exploit_env", "getloadedmodules")
    end
    return {}
end

env.getconnections = function()
    if settings.detect_injection then
        addDetection("exploit_env", "getconnections")
    end
    return {}
end

-- ═══════════════════════════════════════════════════════════════════════
-- HOOKING & INJECTION FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

env.firesignal = function(signal, ...)
    addCode("firesignal(...)")
    if settings.detect_injection then
        addDetection("signal_injection", "firesignal")
        table.insert(detections.injections, {type = "signal_fire", method = "firesignal"})
    end
end

env.fireclickdetector = function(part)
    addCode("fireclickdetector(" .. tostring(part) .. ")")
    if settings.detect_injection then
        addDetection("input_injection", "fireclickdetector")
    end
end

env.firetouchinterest = function(part)
    addCode("firetouchinterest(" .. tostring(part) .. ")")
    if settings.detect_injection then
        addDetection("input_injection", "firetouchinterest")
    end
end

env.fireproximityprompt = function(prompt)
    addCode("fireproximityprompt(" .. tostring(prompt) .. ")")
    if settings.detect_injection then
        addDetection("input_injection", "fireproximityprompt")
    end
end

env.setreadonly = function(t, val) end
env.isreadonly = function(t) return false end

env.setclipboard = function(text)
    local preview = tostring(text):sub(1, 50)
    addCode('setclipboard("' .. preview .. '")')
    if settings.detect_exfiltration then
        addDetection("clipboard_exfiltration", preview)
        table.insert(detections.exfiltrations, {type = "clipboard", data_preview = preview})
    end
end

env.checkcaller = function() return true end
env.newcclosure = function(f) return f end
env.clonefunction = function(f) return f end

-- ═══════════════════════════════════════════════════════════════════════
-- HOOKING FUNCTIONS WITH METAMETHOD DETECTION
-- ═══════════════════════════════════════════════════════════════════════

env.hookfunction = function(original, hook)
    addCode("hookfunction([function], [hook])")
    if settings.detect_metamethods then
        addDetection("function_hook", "hookfunction")
        table.insert(detections.metamethods, {type = "function_hook", method = "hookfunction"})
    end
    return original
end

env.hookmetamethod = function(obj, method, hook)
    addCode('hookmetamethod([obj], "' .. tostring(method) .. '", [hook])')
    if settings.detect_metamethods then
        addDetection("metamethod_hook", method)
        table.insert(detections.metamethods, {type = "metamethod_hook", method = method})
    end
    return function() end
end

-- ═══════════════════════════════════════════════════════════════════════
-- DRAWING API
-- ═══════════════════════════════════════════════════════════════════════

env.Drawing = {
    new = function(drawingType)
        instanceCounter = instanceCounter + 1
        local varName = "Drawing" .. instanceCounter
        addCode('local ' .. varName .. ' = Drawing.new("' .. drawingType .. '")')
        
        if settings.log_environment_changes then
            addDetection("drawing_creation", drawingType)
        end
        
        return setmetatable({__varName = varName}, {
            __index = function(t, k) return nil end,
            __newindex = function(t, k, v)
                addCode(varName .. "." .. k .. " = " .. tostring(v))
            end,
            __tostring = function() return varName end
        })
    end
}

-- ═══════════════════════════════════════════════════════════════════════
-- TASK & COROUTINE MANAGEMENT WITH DETECTION
-- ═══════════════════════════════════════════════════════════════════════

env.task = {
    wait = function(t)
        addCode("task.wait(" .. (t or 0) .. ")")
        return 0
    end,
    spawn = function(func)
        addCode("task.spawn(function() end)")
        if settings.detect_coroutines then
            addDetection("async_spawn", "task.spawn")
        end
        if type(func) == "function" then
            pushStack("task.spawn")
            pcall(func)
            popStack()
        end
    end,
    delay = function(t, func)
        addCode("task.delay(" .. t .. ", function() end)")
        if settings.detect_coroutines then
            addDetection("async_delay", t)
        end
    end,
    defer = function(func)
        addCode("task.defer(function() end)")
        if type(func) == "function" then
            pcall(func)
        end
    end
}

-- ═══════════════════════════════════════════════════════════════════════
-- COROUTINE WITH DETECTION
-- ═══════════════════════════════════════════════════════════════════════

local original_coroutine = coroutine
env.coroutine = setmetatable({}, {
    __index = function(t, k)
        if k == "create" then
            return function(func)
                if settings.detect_coroutines then
                    addDetection("coroutine_create", "coroutine.create")
                end
                addCode("coroutine.create(function() end)")
                return original_coroutine.create(func)
            end
        elseif k == "resume" then
            return function(co, ...)
                if settings.detect_coroutines then
                    addDetection("coroutine_resume", "coroutine.resume")
                end
                addCode("coroutine.resume(...)")
                return original_coroutine.resume(co, ...)
            end
        else
            return original_coroutine[k]
        end
    end
})

-- ═══════════════════════════════════════════════════════════════════════
-- STANDARD GLOBALS
-- ═══════════════════════════════════════════════════════��═══════════════

env.type = type
env.typeof = type
env.tostring = tostring
env.tonumber = tonumber
env.pairs = pairs
env.ipairs = ipairs
env.next = next
env.pcall = pcall
env.xpcall = xpcall
env.assert = assert
env.error = error
env.select = select
env.unpack = unpack
env.getmetatable = getmetatable
env.setmetatable = setmetatable
env.rawget = rawget
env.rawset = rawset
env.rawequal = rawequal

-- ═══════════════════════════════════════════════════════════════════════
-- LIBRARIES
-- ═══════════════════════════════════════════════════════════════════════

env.math = math
env.table = table
env.string = string
env.coroutine = coroutine
env.os = os
env.bit32 = bit32
env.utf8 = utf8

-- ═══════════════════════════════════════════════════════════════════════
-- OPERATION TRACKING (HOOKOP)
-- ═══════════════════════════════════════════════════════════════════════

if settings.hookOp then
    local function createTrackedNumber(value)
        return setmetatable({__value = value}, {
            __add = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                if settings.comments then
                    addComment("Op: " .. av .. " + " .. bv)
                end
                return createTrackedNumber(av + bv)
            end,
            __sub = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                if settings.comments then
                    addComment("Op: " .. av .. " - " .. bv)
                end
                return createTrackedNumber(av - bv)
            end,
            __mul = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                return createTrackedNumber(av * bv)
            end,
            __div = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                return createTrackedNumber(av / bv)
            end,
            __mod = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                return createTrackedNumber(av % bv)
            end,
            __pow = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                return createTrackedNumber(av ^ bv)
            end,
            __unm = function(a)
                local av = type(a) == "table" and a.__value or a
                return createTrackedNumber(-av)
            end,
            __eq = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                return av == bv
            end,
            __lt = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                return av < bv
            end,
            __le = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                return av <= bv
            end,
            __tostring = function(self)
                return tostring(self.__value)
            end,
            __tonumber = function(self)
                return self.__value
            end
        })
    end
    
    local original_tonumber = env.tonumber
    env.tonumber = function(...)
        local result = original_tonumber(...)
        if result then
            return createTrackedNumber(result)
        end
        return result
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- ENVIRONMENT & GLOBALS
-- ═══════════════════════════════════════════════════════════════════════

env._G = env
env.shared = {}
env._VERSION = "Lua 5.1"
env.getfenv = function() return env end
env.setfenv = function(f, t) return f end

setmetatable(env, {
    __index = function(t, k)
        return nil
    end
})

-- ═══════════════════════════════════════════════════════════════════════
-- SCRIPT EXECUTION & CODE ANALYSIS
-- ═══════════════════════════════════════════════════════════════════════

-- Pre-execution analysis
if settings.detect_obfuscation then
    local obf_result = detect_obfuscation(scriptContent)
    if obf_result.score > 0 then
        addComment("OBFUSCATION DETECTED - Level: " .. obf_result.level .. " (Score: " .. obf_result.score .. ")")
        for _, technique in ipairs(obf_result.techniques) do
            addComment("  Technique: " .. technique)
        end
        detection_stats.suspicious_patterns_found = detection_stats.suspicious_patterns_found + 1
    end
end

if settings.detect_injection then
    local injections = detect_injection_attempts(scriptContent)
    if #injections > 0 then
        addComment("INJECTION ATTEMPTS DETECTED")
        for _, injection in ipairs(injections) do
            addComment("  Type: " .. injection.type .. " (Method: " .. injection.method .. ")")
            table.insert(detections.injections, injection)
        end
        detection_stats.suspicious_patterns_found = detection_stats.suspicious_patterns_found + 1
    end
end

if settings.detect_exfiltration then
    local exfils = detect_exfiltration(scriptContent)
    if #exfils > 0 then
        addComment("DATA EXFILTRATION PATTERNS DETECTED")
        for _, exfil in ipairs(exfils) do
            addComment("  Type: " .. exfil.type .. " (Target: " .. (exfil.target or exfil.vector or exfil.method or "unknown") .. ")")
            table.insert(detections.exfiltrations, exfil)
        end
        detection_stats.suspicious_patterns_found = detection_stats.suspicious_patterns_found + 1
    end
end

-- Execute script
local chunk, err = loadstring(scriptContent, "@script")
if not chunk then
    addComment("Error: " .. tostring(err))
    process.exit(1)
end

setfenv(chunk, env)
local success, result = pcall(chunk)

if not success then
    addComment("Runtime error: " .. tostring(result))
end

-- Handle returned functions (VM obfuscators)
if success and type(result) == "function" then
    setfenv(result, env)
    pcall(result)
end

-- ═══════════════════════════════════════════════════════════════════════
-- INLINE CODE OUTPUT WITH DETECTION METADATA
-- ═══════════════════════════════════════════════════════════════════════

local output_lines = {}

-- Header with inline statistics
table.insert(output_lines, "--[[ ════════════════════════════════════════════════════════════")
table.insert(output_lines, "    ADVANCED ENVIRONMENT LOGGER - CODE RECONSTRUCTION")
table.insert(output_lines, "    Script: " .. scriptPath)
table.insert(output_lines, "    Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"))
table.insert(output_lines, "    ════════════════════════════════════════════════════════════ ]]")
table.insert(output_lines, "")

-- Detection summary inline
table.insert(output_lines, "--[[ DETECTION SUMMARY:")
table.insert(output_lines, "     Total Detections: " .. detection_stats.total_detections)
table.insert(output_lines, "     Webhooks Found: " .. detection_stats.webhooks_found)
table.insert(output_lines, "     Loadstrings Found: " .. detection_stats.loadstrings_found)
table.insert(output_lines, "     HTTP Calls: " .. detection_stats.http_calls)
table.insert(output_lines, "     File Operations: " .. detection_stats.file_ops)
table.insert(output_lines, "     Suspicious Patterns: " .. detection_stats.suspicious_patterns_found .. " ]]")
table.insert(output_lines, "")

-- URLs detected inline
if #detections.webhooks > 0 then
    table.insert(output_lines, "--[[ WEBHOOKS DETECTED:")
    for i, webhook in ipairs(detections.webhooks) do
        table.insert(output_lines, "     [" .. i .. "] " .. webhook.type .. ": " .. webhook.url)
    end
    table.insert(output_lines, "]]")
    table.insert(output_lines, "")
end

-- HTTP requests inline
if #detections.http_requests > 0 then
    table.insert(output_lines, "--[[ HTTP REQUESTS:")
    for i, req in ipairs(detections.http_requests) do
        table.insert(output_lines, "     [" .. i .. "] " .. req.type .. ": " .. req.url)
    end
    table.insert(output_lines, "]]")
    table.insert(output_lines, "")
end

-- Add reconstructed code
for _, line in ipairs(codeLines) do
    table.insert(output_lines, line)
end

-- Footer with inline analysis
table.insert(output_lines, "")
table.insert(output_lines, "--[[ ════════════════════════════════════════════════════════════")
table.insert(output_lines, "    END OF RECONSTRUCTED CODE")
table.insert(output_lines, "    ════════════════════════════════════════════════════════════ ]]")

-- Output inline
for _, line in ipairs(output_lines) do
    print(line)
end

-- Optional file dump
if settings.output_file then
    local output_content = table.concat(output_lines, "\n")
    fs.writeFile(settings.output_file, output_content)
end
