-- ADVANCED ROBLOX ENVIRONMENT LOGGER & CODE RECONSTRUCTOR v3.0
-- Ultra-Feature Rich with Auto-Configuration
-- Pure inline reconstruction with raw code output only
local process = require("@lune/process")
local fs = require("@lune/fs")

local scriptPath = process.args[1]
if not scriptPath then
    print("Usage: lune run advanced_env_logger.lua <script_path>")
    process.exit(1)
end

local scriptContent = fs.readFile(scriptPath)

-- ═══════════════════════════════════════════════════════════════════════
-- AUTO-CONFIGURATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════
local function detectScriptFeatures(code)
    local features = {
        uses_http = code:match("HttpGet") ~= nil or code:match("request") ~= nil,
        uses_files = code:match("writefile") ~= nil or code:match("readfile") ~= nil,
        uses_instances = code:match("Instance%.new") ~= nil,
        uses_services = code:match("GetService") ~= nil,
        uses_tasks = code:match("task%.spawn") ~= nil or code:match("task%.wait") ~= nil,
        uses_hooks = code:match("hookfunction") ~= nil or code:match("hookmetamethod") ~= nil,
        uses_exploits = code:match("getgenv") ~= nil or code:match("getreg") ~= nil,
        uses_ui = code:match("Drawing%.new") ~= nil or code:match("UserInputService") ~= nil,
        uses_coroutines = code:match("coroutine%.create") ~= nil or code:match("coroutine%.resume") ~= nil,
        uses_loadstring = code:match("loadstring") ~= nil,
        uses_metamethods = code:match("setmetatable") ~= nil or code:match("getmetatable") ~= nil,
        uses_math = code:match("math%.") ~= nil,
        uses_table = code:match("table%.") ~= nil,
        uses_string = code:match("string%.") ~= nil,
        uses_bit = code:match("bit32%.") ~= nil or code:match("bit%.") ~= nil,
        uses_debug = code:match("debug%.") ~= nil,
        uses_player = code:match("LocalPlayer") ~= nil or code:match("Players") ~= nil,
        uses_humanoid = code:match("Humanoid") ~= nil or code:match("Character") ~= nil,
        uses_tweens = code:match("TweenService") ~= nil or code:match("TweenInfo") ~= nil,
        uses_marketplace = code:match("MarketplaceService") ~= nil,
        uses_clipboard = code:match("setclipboard") ~= nil,
        uses_signals = code:match("firesignal") ~= nil or code:match("Connect") ~= nil,
        uses_movement = code:match("fireclickdetector") ~= nil or code:match("firetouchinterest") ~= nil,
        uses_pcall = code:match("pcall") ~= nil or code:match("xpcall") ~= nil,
        code_length = #code,
    }
    return features
end

local features = detectScriptFeatures(scriptContent)

-- AUTO-CONFIGURATION
local settings = {
    -- Core features (auto-enabled based on script)
    hookOp = features.uses_math or process.env.SETTING_HOOKOP == "1",
    explore_funcs = features.uses_loadstring or features.uses_hooks or process.env.SETTING_EXPLORE_FUNCS == "1",
    spyexeconly = process.env.SETTING_SPYEXECONLY == "1",
    no_string_limit = features.code_length > 100000 or process.env.SETTING_NO_STRING_LIMIT == "1",
    verbose = process.env.SETTING_VERBOSE == "1",
    output_file = process.env.SETTING_OUTPUT_FILE or nil,
    inline_raw = true,
    
    -- Feature toggles
    track_http = features.uses_http,
    track_files = features.uses_files,
    track_instances = features.uses_instances,
    track_services = features.uses_services,
    track_tasks = features.uses_tasks,
    track_hooks = features.uses_hooks,
    track_exploits = features.uses_exploits,
    track_ui = features.uses_ui,
    track_coroutines = features.uses_coroutines,
    track_loadstring = features.uses_loadstring,
    track_metamethods = features.uses_metamethods,
    track_player_data = features.uses_player or features.uses_humanoid,
    track_signals = features.uses_signals,
    track_movement = features.uses_movement,
    track_purchases = features.uses_marketplace,
    track_clipboard = features.uses_clipboard,
    
    -- Network & fetch
    allow_fetch = process.env.SETTING_ALLOW_FETCH == "1",
    fetch_timeout = tonumber(process.env.SETTING_FETCH_TIMEOUT) or 10,
    cache_enabled = process.env.SETTING_FETCH_CACHE == "1",
    cache_dir = process.env.SETTING_FETCH_CACHE_DIR or ".fetch_cache",
    
    -- Advanced features
    track_mutations = true,
    track_stack_depth = process.env.SETTING_TRACK_STACK ~= "0",
    preserve_errors = true,
    unsafe_mode = process.env.SETTING_UNSAFE ~= "0",
    smart_truncate = true,
    function_hooks = true,
    memory_pooling = true,
    call_history = true,
    argument_logging = true,
    return_value_logging = true,
    performance_tracking = true,
    environment_isolation = true,
    state_snapshots = process.env.SETTING_SNAPSHOTS == "1",
}

-- Parse CLI arguments
for i = 2, #process.args do
    local a = process.args[i]
    if a == "--allow-fetch" then settings.allow_fetch = true end
    if a == "--no-fetch" then settings.allow_fetch = false end
    if a == "--unsafe" then settings.unsafe_mode = true end
    if a == "--safe" then settings.unsafe_mode = false end
    if a:match("^--fetch-timeout=") then settings.fetch_timeout = tonumber(a:match("^--fetch-timeout=(%d+)")) or settings.fetch_timeout end
    if a == "--verbose" then settings.verbose = true end
    if a == "--snapshots" then settings.state_snapshots = true end
    local out = a:match("^--output=(.+)$")
    if out then settings.output_file = out end
    local cache = a:match("^--cache-dir=(.+)$")
    if cache then settings.cache_dir = cache end
end

-- ════════════════════════��══════════════════════════════════════════════
-- CODE OUTPUT BUFFER & TRACKING
-- ═══════════════════════════════════════════════════════════════════════
local codeLines = {}
local callStack = {}
local callHistory = {}
local callCount = 0
local stateSnapshots = {}
local performanceMetrics = {}
local functionMetadata = {}
local executionTimeline = {}
local errorLog = {}
local memoryPool = {}

local function addCode(code, lineType)
    table.insert(codeLines, code)
    if settings.call_history then
        callCount = callCount + 1
        table.insert(callHistory, {
            index = callCount,
            code = code,
            type = lineType or "code",
            timestamp = os.clock()
        })
    end
end

local function pushStack(context)
    if settings.track_stack_depth then
        table.insert(callStack, {
            context = context,
            depth = #callStack,
            timestamp = os.clock()
        })
    end
end

local function popStack()
    if settings.track_stack_depth and #callStack > 0 then
        table.remove(callStack)
    end
end

local function truncateString(str, maxLen)
    if settings.no_string_limit or #str <= maxLen then
        return str
    end
    local remaining = #str - maxLen
    return str:sub(1, maxLen) .. "...(" .. remaining .. " bytes left)"
end

local function captureSnapshot(label)
    if settings.state_snapshots then
        table.insert(stateSnapshots, {
            label = label,
            timestamp = os.clock(),
            codeLineCount = #codeLines,
            stackDepth = #callStack,
            callCount = callCount
        })
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
local serviceCache = {}
local eventConnections = {}
local signalFires = {}
local methodCalls = {}
local propertyWrites = {}
local fileOperations = {}

-- ════════════��══════════════════════════════════════════════════════════
-- ADVANCED MOCK EVENT SYSTEM WITH SIGNAL TRACKING
-- ═══════════════════════════════════════════════════════════════════════
local function createEvent()
    local event = {}
    local connections = {}
    
    return setmetatable(event, {
        __index = function(t, k)
            if k == "Wait" or k == "wait" then
                return function() return nil end
            elseif k == "Connect" or k == "connect" or k == "ConnectParallel" then
                return function(self, callback)
                    if settings.track_signals then
                        table.insert(eventConnections, {
                            event = tostring(self),
                            callback = type(callback),
                            timestamp = os.clock()
                        })
                    end
                    return setmetatable({
                        Connected = true,
                        Disconnect = function(self) self.Connected = false end,
                        disconnect = function(self) self.Connected = false end
                    }, {
                        __tostring = function() return "RBXScriptConnection" end
                    })
                end
            elseif k == "Fire" or k == "fire" or k == "FireServer" then
                return function(...)
                    if settings.track_signals then
                        table.insert(signalFires, {
                            event = tostring(event),
                            args = {...},
                            timestamp = os.clock()
                        })
                    end
                end
            elseif k == "Once" then
                return function(self, callback)
                    return createEvent()
                end
            end
            return createEvent()
        end,
        __call = function(t, ...)
            return nil
        end,
        __tostring = function() return "RBXScriptSignal" end
    })
end

-- ═══════════════════════════════════════════════════════════════════════
-- ENHANCED MOCK INSTANCE WITH PROPERTY TRACKING
-- ════════��══════════════════════════════════════════════════════════════
local function createMockInstance(className, varName)
    local mock = {
        __className = className,
        __varName = varName,
        Name = className,
        Parent = nil,
        __properties = {},
        __methods = {}
    }
    
    return setmetatable(mock, {
        __index = function(t, k)
            if k == "WaitForChild" or k == "FindFirstChild" or k == "FindFirstChildOfClass" then
                return function(self, childName, recursive)
                    if settings.track_instances then
                        table.insert(methodCalls, {
                            instance = varName,
                            method = k,
                            args = {childName, recursive},
                            timestamp = os.clock()
                        })
                    end
                    return createMockInstance(childName or "Child", childName or "Child")
                end
            elseif k == "GetChildren" or k == "GetDescendants" then
                return function()
                    if settings.track_instances then
                        table.insert(methodCalls, {
                            instance = varName,
                            method = k,
                            timestamp = os.clock()
                        })
                    end
                    return {}
                end
            elseif k == "GetPropertyChangedSignal" then
                return function(self, propName)
                    return createEvent()
                end
            elseif k == "Destroy" or k == "destroy" then
                return function()
                    if settings.track_instances then
                        table.insert(methodCalls, {
                            instance = varName,
                            method = k,
                            timestamp = os.clock()
                        })
                    end
                end
            elseif k == "Clone" or k == "clone" then
                return function()
                    if settings.track_instances then
                        table.insert(methodCalls, {
                            instance = varName,
                            method = k,
                            timestamp = os.clock()
                        })
                    end
                    return createMockInstance(className, varName .. "_Clone")
                end
            elseif k == "Connect" then
                return function(self, callback)
                    return createEvent()
                end
            elseif k == "IsA" then
                return function(self, typeName)
                    return typeName == className
                end
            elseif k == "GetAttribute" then
                return function(self, attrName)
                    return mock.__properties[attrName] or nil
                end
            elseif k == "SetAttribute" then
                return function(self, attrName, value)
                    mock.__properties[attrName] = value
                end
            elseif k == "AddTag" or k == "RemoveTag" or k == "HasTag" or k == "GetTags" then
                return function(...)
                    return {}
                end
            elseif k:match("Click") or k:match("Input") or k:match("Changed") or k:match("beat") or k:match("Added") or k:match("Removing") or k:match("Enter") or k:match("Leave") or k:match("Touched") or k:match("Detect") then
                return createEvent()
            else
                return createEvent()
            end
        end,
        __newindex = function(t, k, v)
            if k:sub(1, 2) ~= "__" then
                mock.__properties[k] = v
                
                if settings.track_mutations then
                    local valueStr
                    if type(v) == "string" then
                        valueStr = '"' .. v .. '"'
                    elseif type(v) == "number" or type(v) == "boolean" then
                        valueStr = tostring(v)
                    elseif type(v) == "table" then
                        if v.__varName then
                            valueStr = v.__varName
                        else
                            valueStr = "table"
                        end
                    else
                        valueStr = tostring(v)
                    end
                    
                    table.insert(propertyWrites, {
                        instance = varName,
                        property = k,
                        value = valueStr,
                        timestamp = os.clock()
                    })
                    
                    addCode(varName .. "." .. k .. " = " .. valueStr)
                end
            end
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
-- ENHANCED INSTANCE CREATION WITH TRACKING
-- ═══════════════════════════════════════════════════════════════════════
env.Instance = {
    new = function(className, parent)
        instanceCounter = instanceCounter + 1
        local varName = "Instance" .. instanceCounter
        instances[varName] = className
        
        if settings.track_instances then
            table.insert(methodCalls, {
                method = "Instance.new",
                className = className,
                parent = parent and tostring(parent) or "nil",
                varName = varName,
                timestamp = os.clock()
            })
        end
        
        if parent then
            addCode("local " .. varName .. ' = Instance.new("' .. className .. '", ' .. tostring(parent) .. ")")
        else
            addCode("local " .. varName .. ' = Instance.new("' .. className .. '")')
        end
        
        captureSnapshot("Instance.new:" .. className)
        return createMockInstance(className, varName)
    end
}

-- ═══════════════════════════════════════════════════════════════════════
-- MATH & DATATYPE CONSTRUCTORS
-- ═══════════════════════════════════════════════════════════════════════
env.Vector3 = {
    new = function(x, y, z)
        if settings.track_instances then
            table.insert(methodCalls, {
                method = "Vector3.new",
                args = {x, y, z},
                timestamp = os.clock()
            })
        end
        return setmetatable({__type = "Vector3"}, {
            __tostring = function() return string.format("Vector3.new(%g, %g, %g)", x or 0, y or 0, z or 0) end,
            __add = function(a, b) return env.Vector3.new((a.__x or 0) + (b.__x or 0), (a.__y or 0) + (b.__y or 0), (a.__z or 0) + (b.__z or 0)) end,
            __sub = function(a, b) return env.Vector3.new((a.__x or 0) - (b.__x or 0), (a.__y or 0) - (b.__y or 0), (a.__z or 0) - (b.__z or 0)) end,
            __mul = function(a, b) local s = type(b) == "number" and b or 1 return env.Vector3.new((a.__x or 0) * s, (a.__y or 0) * s, (a.__z or 0) * s) end,
        })
    end,
    zero = setmetatable({__type = "Vector3"}, {__tostring = function() return "Vector3.new(0, 0, 0)" end})
}

env.Color3 = {
    fromRGB = function(r, g, b)
        return setmetatable({__type = "Color3", __r = r, __g = g, __b = b}, {
            __tostring = function() return string.format("Color3.fromRGB(%d, %d, %d)", r, g, b) end
        })
    end,
    new = function(r, g, b)
        return setmetatable({__type = "Color3"}, {
            __tostring = function() return string.format("Color3.new(%g, %g, %g)", r, g, b) end
        })
    end,
    fromHSV = function(h, s, v)
        return setmetatable({__type = "Color3"}, {
            __tostring = function() return string.format("Color3.fromHSV(%g, %g, %g)", h, s, v) end
        })
    end
}

env.UDim = {
    new = function(s, o)
        return setmetatable({__type = "UDim"}, {
            __tostring = function() return string.format("UDim.new(%g, %g)", s, o) end
        })
    end
}

env.UDim2 = {
    new = function(xs, xo, ys, yo)
        return setmetatable({__type = "UDim2"}, {
            __tostring = function() return string.format("UDim2.new(%g, %g, %g, %g)", xs, xo, ys, yo) end
        })
    end,
    fromOffset = function(x, y)
        return setmetatable({__type = "UDim2"}, {
            __tostring = function() return string.format("UDim2.fromOffset(%g, %g)", x, y) end
        })
    end,
    fromScale = function(x, y)
        return setmetatable({__type = "UDim2"}, {
            __tostring = function() return string.format("UDim2.fromScale(%g, %g)", x, y) end
        })
    end
}

env.Vector2 = {
    new = function(x, y)
        return setmetatable({__type = "Vector2", __x = x, __y = y}, {
            __tostring = function() return string.format("Vector2.new(%g, %g)", x, y) end,
            __add = function(a, b) return env.Vector2.new((a.__x or 0) + (b.__x or 0), (a.__y or 0) + (b.__y or 0)) end
        })
    end
}

env.BrickColor = {
    new = function(name)
        return setmetatable({__type = "BrickColor"}, {
            __tostring = function() return 'BrickColor.new("' .. name .. '")' end
        })
    end
}

env.NumberRange = {
    new = function(...)
        local args = {...}
        return setmetatable({__type = "NumberRange"}, {
            __tostring = function() return "NumberRange.new(" .. table.concat(args, ", ") .. ")" end
        })
    end
}

env.NumberSequence = {
    new = function(...)
        return setmetatable({__type = "NumberSequence"}, {
            __tostring = function() return "NumberSequence.new(...)" end
        })
    end
}

env.NumberSequenceKeypoint = {
    new = function(...)
        return setmetatable({__type = "NumberSequenceKeypoint"}, {
            __tostring = function() return "NumberSequenceKeypoint.new(...)" end
        })
    end
}

env.ColorSequence = {
    new = function(...)
        return setmetatable({__type = "ColorSequence"}, {
            __tostring = function() return "ColorSequence.new(...)" end
        })
    end
}

env.ColorSequenceKeypoint = {
    new = function(...)
        return setmetatable({__type = "ColorSequenceKeypoint"}, {
            __tostring = function() return "ColorSequenceKeypoint.new(...)" end
        })
    end
}

env.TweenInfo = {
    new = function(duration, easingStyle, easingDirection, repeatCount, reverses, delayTime)
        return setmetatable({__type = "TweenInfo"}, {
            __tostring = function() return "TweenInfo.new(...)" end
        })
    end
}

env.CFrame = {
    new = function(...)
        return setmetatable({__type = "CFrame"}, {
            __tostring = function() return "CFrame.new(...)" end,
            __mul = function(a, b) return env.CFrame.new() end
        })
    end,
    Angles = function(x, y, z)
        return setmetatable({__type = "CFrame"}, {
            __tostring = function() return string.format("CFrame.Angles(%g, %g, %g)", x, y, z) end
        })
    end,
    fromEulerAnglesXYZ = function(x, y, z)
        return env.CFrame.new()
    end
}

-- ═══════════════════════════════════════════════════════════════════════
-- TIMING FUNCTIONS WITH PERFORMANCE TRACKING
-- ═══════════════════════════════════════════════════════════════════════
env.tick = function()
    return os.clock()
end

env.wait = function(t)
    if t then
        addCode("wait(" .. t .. ")")
        if settings.performance_tracking then
            table.insert(performanceMetrics, {
                type = "wait",
                duration = t,
                timestamp = os.clock()
            })
        end
    else
        addCode("wait()")
    end
    return 0
end

env.delay = function(t, f)
    addCode("delay(" .. (t or 0) .. ", function() end)")
    if settings.performance_tracking then
        table.insert(performanceMetrics, {
            type = "delay",
            duration = t,
            timestamp = os.clock()
        })
    end
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
-- ENUM SYSTEM WITH CACHING
-- ═══════════════════════════════════════════════════════════════════════
local enumCache = {}
env.Enum = setmetatable({}, {
    __index = function(t, k)
        if not enumCache[k] then
            enumCache[k] = setmetatable({}, {
                __index = function(t2, v)
                    return setmetatable({}, {
                        __tostring = function() return "Enum." .. k .. "." .. v end
                    })
                end
            })
        end
        return enumCache[k]
    end
})

-- ═══════════════════════════════════════════════════════════════════════
-- PRINT & WARN WITH CALL LOGGING
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
    if settings.argument_logging then
        table.insert(methodCalls, {
            method = "print",
            args = args,
            argCount = #args,
            timestamp = os.clock()
        })
    end
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
-- GAME & SERVICES WITH COMPREHENSIVE TRACKING
-- ═══════════════════════════════════════════════════════════════════════
env.game = setmetatable({}, {
    __index = function(t, k)
        if k == "GetService" then
            return function(self, name)
                if not serviceCache[name] then
                    serviceCache[name] = createMockInstance(name, 'game:GetService("' .. name .. '")')
                    
                    if name == "Players" then
                        serviceCache[name].LocalPlayer = createMockInstance("Player", "LocalPlayer")
                        serviceCache[name].LocalPlayer.Character = createMockInstance("Character", "Character")
                        serviceCache[name].LocalPlayer.CharacterAdded = createEvent()
                        serviceCache[name].LocalPlayer.Humanoid = createMockInstance("Humanoid", "Humanoid")
                        serviceCache[name].LocalPlayer.Backpack = createMockInstance("Backpack", "Backpack")
                        serviceCache[name].PlayerAdded = createEvent()
                        serviceCache[name].PlayerRemoving = createEvent()
                        if settings.track_player_data then
                            table.insert(methodCalls, {method = "GetService", service = "Players"})
                        end
                    elseif name == "TweenService" then
                        serviceCache[name].Create = function(self, obj, info, props)
                            addCode('TweenService:Create(...)')
                            return setmetatable({}, {
                                __index = {
                                    Play = function() addCode("Tween:Play()") end,
                                    Cancel = function() addCode("Tween:Cancel()") end,
                                    Pause = function() addCode("Tween:Pause()") end,
                                    Completed = createEvent()
                                }
                            })
                        end
                    elseif name == "TeleportService" then
                        serviceCache[name].Teleport = function(self, placeId)
                            addCode("TeleportService:Teleport(" .. placeId .. ")")
                            table.insert(methodCalls, {
                                method = "TeleportService:Teleport",
                                placeId = placeId,
                                timestamp = os.clock()
                            })
                        end
                        serviceCache[name].TeleportToPlaceInstance = function(self, placeId, instanceId)
                            addCode("TeleportService:TeleportToPlaceInstance(...)")
                        end
                    elseif name == "MarketplaceService" then
                        serviceCache[name].PromptGamePassPurchase = function(self, player, passId)
                            addCode("MarketplaceService:PromptGamePassPurchase(" .. player .. ", " .. passId .. ")")
                            if settings.track_purchases then
                                table.insert(methodCalls, {
                                    method = "PromptGamePassPurchase",
                                    passId = passId,
                                    timestamp = os.clock()
                                })
                            end
                        end
                        serviceCache[name].PromptProductPurchase = function(self, player, productId)
                            addCode("MarketplaceService:PromptProductPurchase(...)")
                            if settings.track_purchases then
                                table.insert(methodCalls, {
                                    method = "PromptProductPurchase",
                                    productId = productId,
                                    timestamp = os.clock()
                                })
                            end
                        end
                        serviceCache[name].UserOwnsGamePassAsync = function(self, userId, passId)
                            return true
                        end
                    elseif name == "HttpService" then
                        serviceCache[name].PostAsync = function(self, url, data)
                            addCode('HttpService:PostAsync("' .. url .. '", data)')
                            if settings.track_http then
                                table.insert(methodCalls, {
                                    method = "HttpService:PostAsync",
                                    url = url,
                                    timestamp = os.clock()
                                })
                            end
                        end
                        serviceCache[name].GetAsync = function(self, url)
                            addCode('HttpService:GetAsync("' .. url .. '")')
                            if settings.track_http then
                                table.insert(methodCalls, {
                                    method = "HttpService:GetAsync",
                                    url = url,
                                    timestamp = os.clock()
                                })
                            end
                        end
                        serviceCache[name].RequestAsync = function(self, options)
                            if type(options) == "table" and options.Url then
                                addCode('HttpService:RequestAsync({Url = "' .. options.Url .. '"})')
                                if settings.track_http then
                                    table.insert(methodCalls, {
                                        method = "HttpService:RequestAsync",
                                        url = options.Url,
                                        timestamp = os.clock()
                                    })
                                end
                            end
                        end
                        serviceCache[name].JSONEncode = function(self, t)
                            return "{}"
                        end
                        serviceCache[name].JSONDecode = function(self, s)
                            return {}
                        end
                    elseif name == "RunService" then
                        serviceCache[name].RenderStepped = createEvent()
                        serviceCache[name].Stepped = createEvent()
                        serviceCache[name].Heartbeat = createEvent()
                        serviceCache[name].IsClient = function() return true end
                        serviceCache[name].IsServer = function() return false end
                    elseif name == "UserInputService" then
                        serviceCache[name].InputBegan = createEvent()
                        serviceCache[name].InputEnded = createEvent()
                        serviceCache[name].InputChanged = createEvent()
                        serviceCache[name].GetMouseLocation = function() return {X = 0, Y = 0} end
                        serviceCache[name].IsKeyDown = function(self, key) return false end
                    elseif name == "ContextActionService" then
                        serviceCache[name].BindAction = function(self, actionName, func, createTouchButton, ...)
                            addCode('ContextActionService:BindAction("' .. actionName .. '", ...)')
                        end
                        serviceCache[name].UnbindAction = function(self, actionName)
                            addCode('ContextActionService:UnbindAction("' .. actionName .. '")')
                        end
                    elseif name == "CollectionService" then
                        serviceCache[name].AddTag = function(self, instance, tag)
                            addCode('CollectionService:AddTag(...)')
                        end
                        serviceCache[name].RemoveTag = function(self, instance, tag)
                            addCode('CollectionService:RemoveTag(...)')
                        end
                        serviceCache[name].HasTag = function(self, instance, tag)
                            return false
                        end
                        serviceCache[name].GetTagged = function(self, tag)
                            return {}
                        end
                    end
                end
                return serviceCache[name]
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
-- HTTP FUNCTIONS WITH URL TRACKING
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
    addCode('HttpGet("' .. url .. '")')
    if settings.track_http then
        table.insert(methodCalls, {
            method = "HttpGet",
            url = url,
            timestamp = os.clock()
        })
    end
    return "Mock Response"
end

env.HttpGetAsync = env.HttpGet

env.request = function(options)
    local url = type(options) == "table" and options.Url or tostring(options)
    local method = type(options) == "table" and options.Method or "GET"
    addCode('request({Url = "' .. url .. '", Method = "' .. method .. '"})')
    if settings.track_http then
        table.insert(methodCalls, {
            method = "request",
            url = url,
            httpMethod = method,
            timestamp = os.clock()
        })
    end
    return createMockResponse()
end

env.http_request = env.request
env.syn = { request = env.request }

-- ═══════════════════════════════════════════════════════════════════════
-- FILE OPERATIONS WITH TRACKING
-- ═══════════════════════════════════════════════════════════════════════
env.writefile = function(filename, content)
    addCode('writefile("' .. filename .. '", [content])')
    if settings.track_files then
        table.insert(fileOperations, {
            type = "write",
            filename = filename,
            size = #content,
            timestamp = os.clock()
        })
    end
end

env.readfile = function(filename)
    addCode('readfile("' .. filename .. '")')
    if settings.track_files then
        table.insert(fileOperations, {
            type = "read",
            filename = filename,
            timestamp = os.clock()
        })
    end
    return ""
end

env.isfile = function(filename) return true end

env.delfile = function(filename)
    addCode('delfile("' .. filename .. '")')
    if settings.track_files then
        table.insert(fileOperations, {
            type = "delete",
            filename = filename,
            timestamp = os.clock()
        })
    end
end

env.listfiles = function(folder)
    addCode('listfiles("' .. folder .. '")')
    return {}
end

env.makefolder = function(folder)
    addCode('makefolder("' .. folder .. '")')
end

env.delfolder = function(folder)
    addCode('delfolder("' .. folder .. '")')
end

-- ═══════════════════════════════════════════════════════════════════════
-- LOADSTRING WITH SOURCE TRACKING
-- ═══════════════════════════════════════════════════════════════════════
env.loadstring = function(code, chunkname)
    if settings.track_loadstring then
        functionCounter = functionCounter + 1
        local funcName = "loadstring_" .. functionCounter
        
        if settings.explore_funcs then
            addCode("local " .. funcName .. ' = loadstring([[' .. truncateString(code, 150) .. ']])')
            table.insert(trackedFunctions, {
                name = funcName,
                source = truncateString(code, 500),
                chunkname = chunkname,
                timestamp = os.clock()
            })
        else
            addCode("loadstring([[code]])")
        end
    else
        addCode("loadstring([[code]])")
    end
    
    return function(...)
        return nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- EXPLOIT ENVIRONMENT FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════
env.getgenv = function()
    if settings.track_exploits then
        table.insert(methodCalls, {method = "getgenv", timestamp = os.clock()})
    end
    return env
end

env.getrenv = function()
    if settings.track_exploits then
        table.insert(methodCalls, {method = "getrenv", timestamp = os.clock()})
    end
    return env
end

env.getreg = function()
    if settings.track_exploits then
        table.insert(methodCalls, {method = "getreg", timestamp = os.clock()})
    end
    return {}
end

env.getgc = function()
    if settings.track_exploits then
        table.insert(methodCalls, {method = "getgc", timestamp = os.clock()})
    end
    return {}
end

env.getinstances = function()
    if settings.track_exploits then
        table.insert(methodCalls, {method = "getinstances", timestamp = os.clock()})
    end
    return {}
end

env.getnilinstances = function()
    if settings.track_exploits then
        table.insert(methodCalls, {method = "getnilinstances", timestamp = os.clock()})
    end
    return {}
end

env.getloadedmodules = function()
    if settings.track_exploits then
        table.insert(methodCalls, {method = "getloadedmodules", timestamp = os.clock()})
    end
    return {}
end

env.getconnections = function(signal)
    if settings.track_exploits then
        table.insert(methodCalls, {method = "getconnections", signal = tostring(signal), timestamp = os.clock()})
    end
    return {}
end

env.firesignal = function(signal, ...)
    addCode("firesignal(...)")
    if settings.track_movement or settings.track_signals then
        table.insert(methodCalls, {
            method = "firesignal",
            signal = tostring(signal),
            args = {...},
            timestamp = os.clock()
        })
    end
end

env.fireclickdetector = function(part)
    addCode("fireclickdetector(" .. tostring(part) .. ")")
    if settings.track_movement then
        table.insert(methodCalls, {
            method = "fireclickdetector",
            part = tostring(part),
            timestamp = os.clock()
        })
    end
end

env.firetouchinterest = function(part, humanoidPart, state)
    addCode("firetouchinterest(" .. tostring(part) .. ")")
    if settings.track_movement then
        table.insert(methodCalls, {
            method = "firetouchinterest",
            part = tostring(part),
            timestamp = os.clock()
        })
    end
end

env.fireproximityprompt = function(prompt)
    addCode("fireproximityprompt(" .. tostring(prompt) .. ")")
    if settings.track_movement then
        table.insert(methodCalls, {
            method = "fireproximityprompt",
            prompt = tostring(prompt),
            timestamp = os.clock()
        })
    end
end

env.setreadonly = function(t, val) end
env.isreadonly = function(t) return false end

env.setclipboard = function(text)
    local preview = tostring(text):sub(1, 50)
    addCode('setclipboard("' .. preview .. '")')
    if settings.track_clipboard then
        table.insert(methodCalls, {
            method = "setclipboard",
            dataPreview = preview,
            timestamp = os.clock()
        })
    end
end

env.checkcaller = function() return true end
env.newcclosure = function(f) return f end
env.clonefunction = function(f) return f end

-- ═══════════════════════════════════════════════════════════════════════
-- HOOKING FUNCTIONS WITH TRACKING
-- ═══════════════════════════════════════════════════════════════════════
env.hookfunction = function(original, hook)
    addCode("hookfunction([function], [hook])")
    if settings.track_hooks then
        table.insert(methodCalls, {
            method = "hookfunction",
            original = type(original),
            hook = type(hook),
            timestamp = os.clock()
        })
    end
    return original
end

env.hookmetamethod = function(obj, method, hook)
    addCode('hookmetamethod([obj], "' .. tostring(method) .. '", [hook])')
    if settings.track_hooks then
        table.insert(methodCalls, {
            method = "hookmetamethod",
            obj = tostring(obj),
            method_name = method,
            timestamp = os.clock()
        })
    end
    return function() end
end

-- ═══════════════════════════════════════════════════════════════════════
-- DRAWING API WITH UI TRACKING
-- ═══════════════════════════════════════════════════════════════════════
env.Drawing = {
    new = function(drawingType)
        instanceCounter = instanceCounter + 1
        local varName = "Drawing" .. instanceCounter
        addCode('local ' .. varName .. ' = Drawing.new("' .. drawingType .. '")')
        
        if settings.track_ui then
            table.insert(methodCalls, {
                method = "Drawing.new",
                drawingType = drawingType,
                varName = varName,
                timestamp = os.clock()
            })
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
-- TASK & COROUTINE WITH ADVANCED TRACKING
-- ═══════════════════════════════════════════════════════════════════════
env.task = {
    wait = function(t)
        addCode("task.wait(" .. (t or 0) .. ")")
        if settings.track_tasks then
            table.insert(methodCalls, {
                method = "task.wait",
                duration = t,
                timestamp = os.clock()
            })
        end
        return 0
    end,
    spawn = function(func)
        pushStack("task.spawn")
        addCode("task.spawn(function() end)")
        if settings.track_tasks then
            table.insert(methodCalls, {
                method = "task.spawn",
                timestamp = os.clock()
            })
        end
        if type(func) == "function" then
            pcall(func)
        end
        popStack()
    end,
    delay = function(t, func)
        addCode("task.delay(" .. t .. ", function() end)")
        if settings.track_tasks then
            table.insert(methodCalls, {
                method = "task.delay",
                delay = t,
                timestamp = os.clock()
            })
        end
        if type(func) == "function" then
            pcall(func)
        end
    end,
    defer = function(func)
        addCode("task.defer(function() end)")
        if type(func) == "function" then
            pcall(func)
        end
    end,
    cancel = function(task) end
}

local original_coroutine = coroutine
env.coroutine = setmetatable({}, {
    __index = function(t, k)
        if k == "create" then
            return function(func)
                pushStack("coroutine.create")
                addCode("coroutine.create(function() end)")
                if settings.track_coroutines then
                    table.insert(methodCalls, {
                        method = "coroutine.create",
                        timestamp = os.clock()
                    })
                end
                popStack()
                return original_coroutine.create(func)
            end
        elseif k == "resume" then
            return function(co, ...)
                addCode("coroutine.resume(...)")
                if settings.track_coroutines then
                    table.insert(methodCalls, {
                        method = "coroutine.resume",
                        timestamp = os.clock()
                    })
                end
                return original_coroutine.resume(co, ...)
            end
        elseif k == "yield" then
            return function(...)
                if settings.track_coroutines then
                    table.insert(methodCalls, {
                        method = "coroutine.yield",
                        timestamp = os.clock()
                    })
                end
                return original_coroutine.yield(...)
            end
        elseif k == "running" then
            return function()
                return original_coroutine.running()
            end
        elseif k == "status" then
            return function(co)
                return original_coroutine.status(co)
            end
        else
            return original_coroutine[k]
        end
    end
})

-- ═══════════════════════════════════════════════════════════════════════
-- STANDARD GLOBALS
-- ═══════════════════════════════════════════════════════════════════════
env.type = type
env.typeof = type
env.tostring = tostring
env.tonumber = tonumber
env.pairs = pairs
env.ipairs = ipairs
env.next = next
env.pcall = function(func, ...)
    if settings.track_coroutines then
        table.insert(methodCalls, {
            method = "pcall",
            func = type(func),
            timestamp = os.clock()
        })
    end
    return pcall(func, ...)
end
env.xpcall = xpcall
env.assert = assert
env.error = error
env.select = select
env.unpack = unpack
env.getmetatable = getmetatable
env.setmetatable = function(t, mt)
    if settings.track_metamethods then
        table.insert(methodCalls, {
            method = "setmetatable",
            table = type(t),
            metatable = type(mt),
            timestamp = os.clock()
        })
    end
    return setmetatable(t, mt)
end
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
                return createTrackedNumber(av + bv)
            end,
            __sub = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
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
-- SCRIPT EXECUTION WITH ERROR HANDLING
-- ═══════════════════════════════════════════════════════════════════════
captureSnapshot("execution_start")

local chunk, err = loadstring(scriptContent, "@script")
if not chunk then
    if settings.preserve_errors then
        table.insert(errorLog, {
            type = "parse_error",
            message = tostring(err),
            timestamp = os.clock()
        })
    end
    error("Parse error: " .. tostring(err))
    process.exit(1)
end

setfenv(chunk, env)
local success, result = pcall(chunk)

if not success then
    if settings.preserve_errors then
        table.insert(errorLog, {
            type = "runtime_error",
            message = tostring(result),
            timestamp = os.clock()
        })
    end
end

if success and type(result) == "function" then
    setfenv(result, env)
    pcall(result)
end

captureSnapshot("execution_end")

-- ═══════════════════════════════════════════════════════════════════════
-- OUTPUT: RAW RECONSTRUCTED CODE ONLY
-- ═══════════════════════════════════════════════════════════════════════
for _, line in ipairs(codeLines) do
    print(line)
end

-- ═══════════════════════════════════════════════════════════════════════
-- OPTIONAL: SAVE TO FILE
-- ═══════════════════════════════════════════════════════════════════════
if settings.output_file then
    local output_content = table.concat(codeLines, "\n")
    fs.writeFile(settings.output_file, output_content)
end
