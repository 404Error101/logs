-- PURE CODE RECONSTRUCTOR
-- Outputs ONLY reconstructed code, nothing else
local process = require("@lune/process")
local fs = require("@lune/fs")

local scriptPath = process.args[1]
if not scriptPath then
    print("Usage: lune run code_reconstructor.lua <script_path>")
    process.exit(1)
end

local scriptContent = fs.readFile(scriptPath)

-- Read settings from environment variables
local settings = {
    hookOp = process.env.SETTING_HOOKOP == "1",
    explore_funcs = process.env.SETTING_EXPLORE_FUNCS == "1",
    spyexeconly = process.env.SETTING_SPYEXECONLY == "1",
    no_string_limit = process.env.SETTING_NO_STRING_LIMIT == "1",
    minifier = process.env.SETTING_MINIFIER == "1",
    comments = process.env.SETTING_COMMENTS == "1",
    ui_detection = process.env.SETTING_UI_DETECTION == "1",
    notify_scamblox = process.env.SETTING_NOTIFY_SCAMBLOX == "1",
    constant_collection = process.env.SETTING_CONSTANT_COLLECTION == "1",
    duplicate_searcher = process.env.SETTING_DUPLICATE_SEARCHER == "1",
    neverNester = process.env.SETTING_NEVERNESTER == "1",

    -- New settings (can be overridden by env or CLI)
    allow_fetch = process.env.SETTING_ALLOW_FETCH == "1",
    fetch_timeout = tonumber(process.env.SETTING_FETCH_TIMEOUT) or 10,
    fetch_retries = tonumber(process.env.SETTING_FETCH_RETRIES) or 1,
    fetch_follow_redirects = process.env.SETTING_FETCH_FOLLOW_REDIRECTS ~= "0",
    cache_enabled = process.env.SETTING_FETCH_CACHE == "1",
    cache_dir = process.env.SETTING_FETCH_CACHE_DIR or ".fetch_cache",
    verbose = process.env.SETTING_VERBOSE == "1",
    output_file = process.env.SETTING_OUTPUT_FILE or nil,
    execution_timeout = tonumber(process.env.SETTING_EXEC_TIMEOUT) or 5 -- seconds for sandbox
}

-- Parse simple CLI flags (overrides env settings)
for i = 2, #process.args do
    local a = process.args[i]
    if a == "--allow-fetch" then settings.allow_fetch = true end
    if a == "--no-fetch" then settings.allow_fetch = false end
    if a:match("^--fetch-timeout=") then settings.fetch_timeout = tonumber(a:match("^--fetch-timeout=(%d+)")) or settings.fetch_timeout end
    if a:match("^--fetch-retries=") then settings.fetch_retries = tonumber(a:match("^--fetch-retries=(%d+)")) or settings.fetch_retries end
    if a == "--verbose" then settings.verbose = true end
    local out = a:match("^--output=(.+)$")
    if out then settings.output_file = out end
    local cache = a:match("^--cache-dir=(.+)$")
    if cache then settings.cache_dir = cache end
    if a:match("^--exec-timeout=(%d+)") then settings.execution_timeout = tonumber(a:match("^--exec-timeout=(%d+)")) end
end

-- Code reconstruction buffer
local codeLines = {}

-- Additional collectors
local collected_constants = {}
local function collectConstant(v)
    if not settings.constant_collection then return end
    local t = type(v)
    if t == "string" or t == "number" or t == "boolean" then
        collected_constants[vostring(v)] = (collected_constants[vostring(v)] or 0) + 1
    end
end

local function vostring(v)
    if type(v) == "string" then return v end
    return tostring(v)
end

-- String truncation helper
local function truncateString(str, maxLen)
    if settings.no_string_limit or #str <= maxLen then
        return str
    end
    local remaining = #str - maxLen
    return str:sub(1, maxLen) .. "...(" .. remaining .. " bytes left)"
end

-- Simple logging that only captures executable code
local function addCode(code)
    table.insert(codeLines, code)
end

-- Add comment helper
local function addComment(comment)
    if settings.comments then
        table.insert(codeLines, "-- " .. comment)
    end
end

-- Minimal environment
local env = {}

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

-- Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â Helpers & Mocks Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

-- Create event/signal mock
local function createEvent()
    return setmetatable({}, {
        __index = function(t, k)
            if k == "Wait" or k == "wait" then
                return function() return nil end
            elseif k == "Connect" or k == "connect" or k == "ConnectParallel" then
                return function(self, callback) 
                    -- Return a connection object
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

-- Create generic proxy that returns events/mocks
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

-- Enhanced mock instance creation
local function createMockInstance(className, varName)
    local mock = {
        __className = className,
        __varName = varName,
        Name = className,
        Parent = nil
    }
    
    return setmetatable(mock, {
        __index = function(t, k)
            -- Common methods that return mocks
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
            -- Common events
            elseif (type(k) == "string") and (k:match("Click") or k:match("Input") or k:match("Changed") or k:match("beat") or k:match("Added") or k:match("Removing") or k:match("Enter") or k:match("Leave")) then
                return createEvent()
            -- Return event for unknown properties
            else
                return createEvent()
            end
        end,
        __newindex = function(t, k, v)
            -- Log property assignment as code
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
            -- If instance is called directly, return event
            return createEvent()
        end,
        __tostring = function()
            return varName
        end
    })
end

-- INSTANCE TRACKING
local instanceCounter = 0
local instances = {}

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
        
        return createMockInstance(className, varName)
    end
}

-- Math types (unchanged, with safe tostring)
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

env.tick = function() return os.clock() end
env.wait = function(t) return 0 end
env.delay = function(t, f) return 0 end
env.spawn = function(f) f() end

-- Enum
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

-- Game/Services with additional mocks (RunService/UserInputService/ContentProvider)
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
                        services[name].Teleport = function(self, placeId) addCode("TeleportService:Teleport(" .. tostring(placeId) .. ")") end
                        services[name].TeleportToPlaceInstance = function(self, placeId, instanceId) addCode("TeleportService:TeleportToPlaceInstance(...)") end
                    elseif name == "MarketplaceService" then
                        services[name].PromptGamePassPurchase = function() addCode("MarketplaceService:PromptGamePassPurchase(...)") end
                        services[name].PromptProductPurchase = function() addCode("MarketplaceService:PromptProductPurchase(...)") end
                    elseif name == "RunService" then
                        services[name].Stepped = createEvent()
                        services[name].Heartbeat = createEvent()
                        services[name].RenderStepped = createEvent()
                    elseif name == "UserInputService" then
                        services[name].InputBegan = createEvent()
                        services[name].InputEnded = createEvent()
                    elseif name == "ContentProvider" then
                        services[name].PreloadAsync = function() addCode("ContentProvider:PreloadAsync(...)") end
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

-- HTTP Mock Response
local function createMockResponse(body)
    return {
        Body = body or "Mock Response",
        StatusCode = 200,
        StatusMessage = "OK",
        Headers = {["Content-Type"] = "application/json"},
        Success = true
    }
end

-- HTTP Functions (basic)
env.HttpGet = function(url)
    addCode('HttpGet("' .. tostring(url) .. '")')
    return "Mock Response"
end

env.HttpGetAsync = env.HttpGet

env.request = function(options)
    local url = type(options) == "table" and options.Url or tostring(options)
    local method = type(options) == "table" and options.Method or "GET"
    addCode('request({Url = "' .. url .. '", Method = "' .. method .. '"})')
    return createMockResponse()
end

env.http_request = env.request
env.syn = { request = env.request }

-- File operations
env.writefile = function(filename, content)
    addCode('writefile("' .. filename .. '", [content])')
end

env.readfile = function(filename)
    addCode('readfile("' .. filename .. '")')
    return ""
end

env.isfile = function(filename) return true end
env.delfile = function(filename) addCode('delfile("' .. filename .. '")') end
env.listfiles = function(folder) return {} end
env.makefolder = function(folder) addCode('makefolder("' .. folder .. '")') end
env.delfolder = function(folder) addCode('delfolder("' .. folder .. '")') end

-- Loadstring (enhanced placeholder)
env.loadstring = function(code)
    addCode("loadstring([code])")
    return function() end
end

-- Exploit Environment
env.getgenv = function() return env end
env.getrenv = function() return env end
env.getreg = function() return {} end
env.getgc = function() return {} end
env.getinstances = function() return {} end
env.getnilinstances = function() return {} end
env.getloadedmodules = function() return {} end
env.getconnections = function() return {} end
env.firesignal = function(signal, ...) addCode("firesignal(...)") end
env.fireclickdetector = function(part) addCode("fireclickdetector(" .. tostring(part) .. ")") end
env.firetouchinterest = function(part) addCode("firetouchinterest(" .. tostring(part) .. ")") end
env.fireproximityprompt = function(prompt) addCode("fireproximityprompt(" .. tostring(prompt) .. ")") end
env.setreadonly = function(t, val) end
env.isreadonly = function(t) return false end
env.setclipboard = function(text)
    local preview = tostring(text):sub(1, 50)
    addCode('setclipboard("' .. preview .. '")')
end

env.checkcaller = function() return true end
env.newcclosure = function(f) return f end
env.clonefunction = function(f) return f end

-- Exploit functions
env.hookfunction = function(original, hook)
    addCode("hookfunction([function], [hook])")
    return original
end

env.hookmetamethod = function(obj, method, hook)
    addCode('hookmetamethod([obj], "' .. tostring(method) .. '", [hook])')
    return function() end
end

env.Drawing = {
    new = function(drawingType)
        instanceCounter = instanceCounter + 1
        local varName = "Drawing" .. instanceCounter
        addCode('local ' .. varName .. ' = Drawing.new("' .. drawingType .. '")')
        
        return setmetatable({__varName = varName}, {
            __index = function(t, k) return nil end,
            __newindex = function(t, k, v)
                addCode(varName .. "." .. k .. " = " .. tostring(v))
            end,
            __tostring = function() return varName end
        })
    end
}

-- Wait/Task
env.wait = function(t)
    if t then
        addCode("wait(" .. t .. ")")
    else
        addCode("wait()")
    end
    return 0
end

env.task = {
    wait = function(t)
        addCode("task.wait(" .. (t or "") .. ")")
        return 0
    end,
    spawn = function(func)
        addCode("task.spawn(function() end)")
    end,
    delay = function(t, func)
        addCode("task.delay(" .. t .. ", function() end)")
    end
}

-- Standard globals
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

-- Libraries
env.math = math
env.table = table
env.string = string
env.coroutine = coroutine
env.os = os
env.bit32 = bit32
env.utf8 = utf8

-- HOOKOP - OPERATION TRACKING
if settings.hookOp then
    local function createTrackedNumber(value)
        return setmetatable({__value = value}, {
            __add = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                if settings.comments then addComment("Operation: " .. av .. " + " .. bv .. " = " .. (av + bv)) end
                return createTrackedNumber(av + bv)
            end,
            __sub = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                if settings.comments then addComment("Operation: " .. av .. " - " .. bv .. " = " .. (av - bv)) end
                return createTrackedNumber(av - bv)
            end,
            __mul = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                if settings.comments then addComment("Operation: " .. av .. " * " .. bv .. " = " .. (av * bv)) end
                return createTrackedNumber(av * bv)
            end,
            __div = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                if settings.comments then addComment("Operation: " .. av .. " / " .. bv .. " = " .. (av / bv)) end
                return createTrackedNumber(av / bv)
            end,
            __mod = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                if settings.comments then addComment("Operation: " .. av .. " % " .. bv .. " = " .. (av % bv)) end
                return createTrackedNumber(av % bv)
            end,
            __pow = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                if settings.comments then addComment("Operation: " .. av .. " ^ " .. bv .. " = " .. (av ^ bv)) end
                return createTrackedNumber(av ^ bv)
            end,
            __unm = function(a)
                local av = type(a) == "table" and a.__value or a
                if settings.comments then addComment("Operation: -" .. av .. " = " .. (-av)) end
                return createTrackedNumber(-av)
            end,
            __eq = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                local result = av == bv
                addComment("Comparison: " .. av .. " == " .. bv .. " -> " .. tostring(result))
                return result
            end,
            __lt = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                local result = av < bv
                addComment("Comparison: " .. av .. " < " .. bv .. " -> " .. tostring(result))
                return result
            end,
            __le = function(a, b)
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                local result = av <= bv
                addComment("Comparison: " .. av .. " <= " .. bv .. " -> " .. tostring(result))
                return result
            end,
            __tostring = function(self) return tostring(self.__value) end,
            __tonumber = function(self) return self.__value end
        })
    end
    
    local original_tonumber = env.tonumber
    env.tonumber = function(...)
        local result = original_tonumber(...)
        if result and settings.hookOp then
            return createTrackedNumber(result)
        end
        return result
    end
end

-- Environment
env._G = env
env.shared = {}
env._VERSION = "Lua 5.1"
env.getfenv = function() return env end
env.setfenv = function(f, t) return f end

-- Catch undefined globals
setmetatable(env, {
    __index = function(t, k)
        return nil
    end
})

-- ADVANCED FUNCTION RECONSTRUCTION
local functionCounter = 0
local trackedFunctions = {}

-- Smart value serializer for reconstruction
local function serializeValue(value, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    
    local valueType = type(value)
    
    if valueType == "nil" then
        return "nil"
    elseif valueType == "boolean" then
        collectConstant(value)
        return tostring(value)
    elseif valueType == "number" then
        collectConstant(value)
        return tostring(value)
    elseif valueType == "string" then
        collectConstant(value)
        return '"' .. truncateString(value:gsub('"', '\\"'), 256) .. '"'
    elseif valueType == "table" then
        if value.__varName then
            return value.__varName
        elseif value.__className then
            return value.__className
        elseif value.__tostring then
            return tostring(value)
        else
            local parts = {}
            local count = 0
            for k, v in pairs(value) do
                count = count + 1
                if count > 5 then
                    table.insert(parts, "...")
                    break
                end
                if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    table.insert(parts, k .. " = " .. serializeValue(v, depth + 1))
                else
                    table.insert(parts, "[" .. serializeValue(k, depth + 1) .. "] = " .. serializeValue(v, depth + 1))
                end
            end
            return "{" .. table.concat(parts, ", ") .. "}"
        end
    elseif valueType == "function" then
        if trackedFunctions[value] then
            return trackedFunctions[value].name
        else
            return "function() end"
        end
    else
        return tostring(value)
    end
end

-- Extract function parameters using debug info (if available) or fallback
local function getFunctionParams(func)
    local hasDebug, debugInfo = pcall(debug.getinfo, func, "u")
    if hasDebug and debugInfo then
        local paramCount = debugInfo.nparams or 0
        local params = {}
        for i = 1, paramCount do
            params[i] = "arg" .. i
        end
        if debugInfo.isvararg then
            table.insert(params, "...")
        end
        return params
    end
    return {"..."}
end

-- Wrap function to track calls and reconstruct
local function wrapFunction(func, funcName, params)
    if not settings.explore_funcs then
        return function(...)
            addComment("Function " .. funcName .. " called (explore_funcs disabled)")
            return nil
        end
    end
    
    trackedFunctions[func] = {
        name = funcName,
        params = params,
        calls = 0
    }
    
    return function(...)
        local args = {...}
        trackedFunctions[func].calls = trackedFunctions[func].calls + 1
        
        local argStrs = {}
        for i, arg in ipairs(args) do
            argStrs[i] = serializeValue(arg)
        end
        
        local callStr = funcName .. "(" .. table.concat(argStrs, ", ") .. ")"
        
        if settings.comments then
            addComment("Function call: " .. callStr)
        end
        
        local results = {pcall(func, ...)}
        local success = table.remove(results, 1)
        
        if success then
            if settings.comments and #results > 0 then
                addComment("Returned: " .. serializeValue(results[1]))
            end
            return unpack(results)
        else
            if settings.comments then
                addComment("Function errored: " .. tostring(results[1]))
            end
            return nil
        end
    end
end

-- Track function definitions through setfenv wrapping
local function trackFunctionDefinition(func, name)
    functionCounter = functionCounter + 1
    local funcName = name or ("func" .. functionCounter)
    local params = getFunctionParams(func)
    
    if settings.explore_funcs then
        local paramStr = table.concat(params, ", ")
        addCode("local function " .. funcName .. "(" .. paramStr .. ")")
        addComment("Function body execution tracked below")
        addCode("end")
    else
        addCode("local function " .. funcName .. "(...) --[[enable explore_funcs to view]] end")
    end
    
    return wrapFunction(func, funcName, params)
end

-- Enhanced loadstring that reconstructs the loaded code
env.loadstring = function(code, chunkname)
    if settings.explore_funcs then
        addCode("-- loadstring code:")
        addCode(truncateString(code, 1000))
    else
        addCode("loadstring([[" .. truncateString(code, 100) .. "]])")
    end
    addComment("[SECURITY] loadstring NOT executed")
    return function(...)
        addComment("loadstring function called")
        return nil
    end
end

-- Track pcall/xpcall for better flow (kept simple)
local original_pcall = env.pcall
env.pcall = function(func, ...)
    local results = {original_pcall(func, ...)}
    return unpack(results)
end

local original_xpcall = env.xpcall
env.xpcall = function(func, errorHandler, ...)
    local results = {original_xpcall(func, errorHandler, ...)}
    return unpack(results)
end

-- SCRIPT EXECUTION (with sandbox timeout using debug.sethook if available)
local chunk, err = loadstring(scriptContent, "@script")
if not chunk then
    -- Record error as comment instead of printing
    addComment("-- Error loading script: " .. tostring(err))
else
    setfenv(chunk, env)

    local function runWithTimeout(f, timeout)
        if not timeout or timeout <= 0 then
            return pcall(f)
        end
        local hasDebug = type(debug) == "table" and type(debug.sethook) == "function"
        if hasDebug then
            local start = os.clock()
            local function hook()
                if os.clock() - start > timeout then
                    error("Execution timed out")
                end
            end
            debug.sethook(hook, "", 100000)
            local ok, res = pcall(f)
            debug.sethook()
            return ok, res
        else
            -- fallback: no preemption possible, just pcall
            return pcall(f)
        end
    end

    local success, result = runWithTimeout(function() return chunk() end, settings.execution_timeout)

    if not success then
        addComment("-- Runtime error: " .. tostring(result))
    else
        -- If returned function from chunk, try to run it within same sandbox
        if type(result) == "function" then
            setfenv(result, env)
            local ok2, res2 = runWithTimeout(function() return result() end, settings.execution_timeout)
            if not ok2 then
                addComment("-- Runtime error (returned function): " .. tostring(res2))
            end
        end
    end
end

-- New Feature: Fetch-any-URL utility (with fallbacks and caching), extended
local function ensureCacheDir()
    if not settings.cache_enabled then return end
    -- Prefer actual fs if available, otherwise log intent
    local ok, _ = pcall(fs.makeFolder or fs.mkdir or function() end, settings.cache_dir)
    -- Record cache creation as code for reconstruction
    addCode('makefolder("' .. settings.cache_dir .. '")')
end

local function cacheKeyForUrl(url)
    local key = url:gsub("[^%w%-_%.~]", function(c) return string.format("%%%02X", string.byte(c)) end)
    return settings.cache_dir .. "/" .. key
end

local function tryLuaSecFetch(url, timeout, followRedirects)
    local ok_ssl, https = pcall(require, "ssl.https")
    if not ok_ssl or not https then return nil, "no_luasec" end
    local ltn12_ok, ltn12 = pcall(require, "ltn12")
    if not ltn12_ok or not ltn12 then return nil, "no_ltn12" end
    local resbody = {}
    local r, code, headers, status = https.request{
        url = url,
        sink = ltn12.sink.table(resbody),
        redirect = followRedirects and true or false,
        protocol = "any",
        timeout = timeout
    }
    local body = table.concat(resbody)
    return {
        Body = body,
        StatusCode = tonumber(code) or 0,
        Headers = headers or {},
        StatusMessage = tostring(status or "")
    }
end

local function tryLuaSocketFetch(url, timeout, followRedirects)
    local ok, http = pcall(require, "socket.http")
    if not ok or not http then return nil, "no_luasocket" end
    local ltn12_ok, ltn12 = pcall(require, "ltn12")
    if not ltn12_ok or not ltn12 then return nil, "no_ltn12" end
    local resbody = {}
    http.TIMEOUT = timeout or settings.fetch_timeout
    local request_ok, code, headers, status = http.request{
        url = url,
        sink = ltn12.sink.table(resbody),
        redirect = followRedirects and true or false,
        protocol = "any"
    }
    local body = table.concat(resbody)
    return {
        Body = body,
        StatusCode = tonumber(code) or 0,
        Headers = headers or {},
        StatusMessage = tostring(status or "")
    }
end

local function tryCurlFetch(url, timeout, followRedirects)
    local curlCmd = 'curl -s -S'
    if followRedirects then curlCmd = curlCmd .. ' -L' end
    curlCmd = curlCmd .. ' --max-time ' .. tostring(timeout or settings.fetch_timeout)
    curlCmd = curlCmd .. ' ' .. ('"' .. url:gsub('"', '\\"') .. '"')
    local f = io.popen(curlCmd, "r")
    if not f then return nil, "no_curl" end
    local body = f:read("*a") or ""
    local okc, _, exit = pcall(function() return f:close() end)
    return {
        Body = body,
        StatusCode = (okc and 0) or (exit and exit) or 0,
        Headers = {},
        StatusMessage = "curl"
    }
end

local function fetchUrlAny(url, opts)
    opts = opts or {}
    if not settings.allow_fetch then
        addComment("Fetch disabled (allow_fetch=false), fetchUrlAny skipped for " .. tostring(url))
        return createMockResponse("Fetch disabled")
    end

    if settings.verbose then addComment("Fetching URL: " .. tostring(url)) end

    ensureCacheDir()
    local cacheKey = cacheKeyForUrl(url)
    if settings.cache_enabled then
        local ok, cached = pcall(fs.readFile, cacheKey)
        if ok and cached and cached ~= "" then
            addComment("Using cached response for " .. url)
            return {
                Body = cached,
                StatusCode = 200,
                Headers = {},
                StatusMessage = "OK (cached)",
                Success = true
            }
        end
    end

    local lastErr = ""
    for attempt = 1, (opts.retries or settings.fetch_retries) do
        local res, err = tryLuaSecFetch(url, opts.timeout or settings.fetch_timeout, opts.followRedirects or settings.fetch_follow_redirects)
        if res and res.Body then
            if settings.cache_enabled then pcall(fs.writeFile, cacheKey, res.Body) end
            addCode('HttpFetch("' .. tostring(url) .. '", "luasec")')
            return { Body = res.Body, StatusCode = res.StatusCode or 200, Headers = res.Headers or {}, StatusMessage = res.StatusMessage or "OK", Success = true }
        end
        lastErr = lastErr .. tostring(err) .. ";"

        local res2, err2 = tryLuaSocketFetch(url, opts.timeout or settings.fetch_timeout, opts.followRedirects or settings.fetch_follow_redirects)
        if res2 and res2.Body then
            if settings.cache_enabled then pcall(fs.writeFile, cacheKey, res2.Body) end
            addCode('HttpFetch("' .. tostring(url) .. '", "luasocket")')
            return { Body = res2.Body, StatusCode = res2.StatusCode or 200, Headers = res2.Headers or {}, StatusMessage = res2.StatusMessage or "OK", Success = true }
        end
        lastErr = lastErr .. tostring(err2) .. ";"

        local res3, err3 = tryCurlFetch(url, opts.timeout or settings.fetch_timeout, opts.followRedirects or settings.fetch_follow_redirects)
        if res3 and res3.Body then
            if settings.cache_enabled then pcall(fs.writeFile, cacheKey, res3.Body) end
            addCode('HttpFetch("' .. tostring(url) .. '", "curl")')
            return { Body = res3.Body, StatusCode = res3.StatusCode or 0, Headers = res3.Headers or {}, StatusMessage = res3.StatusMessage or "OK", Success = true }
        end
        lastErr = lastErr .. tostring(err3) .. ";"
    end

    addComment("Fetch failed for " .. tostring(url) .. " -> " .. tostring(lastErr))
    return createMockResponse("Fetch failed: " .. tostring(lastErr))
end

env.HttpFetchAny = function(url, options)
    local opts = type(options) == "table" and options or {}
    local res = fetchUrlAny(url, opts)
    addCode('HttpFetchAny("' .. tostring(url) .. '")')
    return res.Body
end

env.Fetch = function(options)
    local url = type(options) == "table" and (options.Url or options.url) or tostring(options)
    local method = type(options) == "table" and (options.Method or options.method or "GET") or "GET"
    local opts = {
        timeout = (type(options) == "table" and options.Timeout) or settings.fetch_timeout,
        followRedirects = (type(options) == "table" and options.FollowRedirects) or settings.fetch_follow_redirects,
        retries = (type(options) == "table" and options.Retries) or settings.fetch_retries
    }
    local body = fetchUrlAny(url, opts)
    addCode('Fetch({Url = "' .. tostring(url) .. '", Method = "' .. tostring(method) .. '"})')
    return { Body = body.Body, StatusCode = body.StatusCode, Headers = body.Headers, Success = body.Success }
end

env.ClearFetchCache = function()
    if not settings.cache_enabled then
        addComment("ClearFetchCache called but cache not enabled")
        return
    end
    addCode('delfolder("' .. settings.cache_dir .. '")')
end

-- MINIFIER (simple)
local function simpleMinify(src)
    local out = {}
    for line in src:gmatch("[^\r\n]+") do
        if not line:match("^%s*%-%-") then
            local s = line:gsub("%s+", " ")
            s = s:gsub("%s+$", "")
            if s ~= "" then table.insert(out, s) end
        end
    end
    return table.concat(out, "\n")
end

-- Assemble reconstructed code into string
local function assembleReconstructed()
    local lines = {}
    table.insert(lines, "-- Reconstructed Lua Code")
    table.insert(lines, "-- Generated by Roblox Environment Logger")
    table.insert(lines, "-- Original file: " .. scriptPath)
    table.insert(lines, "")
    for _, line in ipairs(codeLines) do
        table.insert(lines, line)
    end
    table.insert(lines, "")
    -- Add summary as comment
    table.insert(lines, "-- Summary:")
    table.insert(lines, "-- Instances created: " .. tostring(instanceCounter))
    table.insert(lines, "-- Lines captured: " .. tostring(#codeLines))
    table.insert(lines, "-- Tracked functions: " .. tostring(functionCounter))
    if settings.constant_collection then
        table.insert(lines, "-- Collected constants: ")
        for k, v in pairs(collected_constants) do
            table.insert(lines, "--   " .. tostring(k) .. " (count=" .. tostring(v) .. ")")
        end
    end
    table.insert(lines, "-- End of reconstructed code")
    return table.concat(lines, "\n")
end

-- Export reconstructed code to file (preferred) or record write intent
local function exportReconstructed(path)
    path = path or (scriptPath .. ".reconstructed.lua")
    local assembled = assembleReconstructed()
    local final = assembled
    if settings.minifier then
        final = simpleMinify(assembled)
    end
    -- Try to write via fs if present
    local ok, err = pcall(fs.writeFile, path, final)
    if ok then
        addComment("Wrote reconstructed code to " .. path)
    else
        -- fall back to env.writefile (records intent)
        env.writefile(path, final)
        addComment("Recorded write intent to " .. path .. " (fs.writeFile unavailable or failed)")
    end
    -- Optionally also write a summary JSON (basic)
    if settings.constant_collection then
        local summaryPath = path .. ".summary.txt"
        local s = {"Collected constants summary:"}
        for k, v in pairs(collected_constants) do
            table.insert(s, tostring(k) .. ": " .. tostring(v))
        end
        local ok2 = pcall(fs.writeFile, summaryPath, table.concat(s, "\n"))
        if not ok2 then
            env.writefile(summaryPath, table.concat(s, "\n"))
        end
    end
end

-- Final step: export without printing to stdout
local outPath = settings.output_file or (scriptPath .. ".reconstructed.lua")
exportReconstructed(outPath)

-- End of script (no final prints)
