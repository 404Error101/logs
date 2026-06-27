-- COMBINED HTTPLOG2 DEOBFUSCATOR & CODE RECONSTRUCTOR
-- Lune-based with enhanced 25ms features and raw inline code output
-- TODO: add metatables that also have a real value like a string. For example for tostring returns on tables or sum!

local insert = table.insert
local _require = require
local settings = {
    varnames = true,
    usesimplefunctions = false,
    watchoutforloop = true,
    spynilglobals = false,
    hook_op = false,
    hook_op_default_return = "original",
    log_lines = false,
    better_funcs = false,
    
    hookOp = false,
    explore_funcs = false,
    spyexeconly = false,
    no_string_limit = false,
    minifier = false,
    comments = true,
    ui_detection = false,
    notify_scamblox = false,
    constant_collection = true,
    duplicate_searcher = false,
    neverNester = false,
    allow_fetch = false,
    fetch_timeout = 10,
    fetch_retries = 1,
    fetch_follow_redirects = true,
    cache_enabled = false,
    cache_dir = ".fetch_cache",
    verbose = true,
    output_file = nil,
    inline_output = true,
    ignore_prom_globals = false,
}

local unfinishedfuncs, is_unfinished = {}, false
local thisfunction = debug.info(1, "f")
local specialhandle = false
local msecNotReady = false
local luraphnotready = 0
local cenv, genv, analyzefunction, metatables, cclosures, types = {}, {}, nil, {}, {}, {}
local _tostring = tostring
local concat_me = `<25ms_concat_me>`
local concat_me_close = `</25ms_concat_me>`
local oldtype = type
local getmetatable = getmetatable
local pack, unpack = table.pack, unpack
local simplelog, isjunkie

-- Lune-specific imports
local process = require("@lune/process")
local fs = require("@lune/fs")
local luau = require("@lune/luau")

-- Parse CLI arguments
for i = 2, #process.args do
    local a = process.args[i]
    if a == "--allow-fetch" then settings.allow_fetch = true end
    if a == "--no-fetch" then settings.allow_fetch = false end
    if a:match("^--fetch-timeout=") then settings.fetch_timeout = tonumber(a:match("^--fetch-timeout=(%d+)")) or settings.fetch_timeout end
    if a:match("^--fetch-retries=") then settings.fetch_retries = tonumber(a:match("^--fetch-retries=(%d+)")) or settings.fetch_retries end
    if a == "--verbose" then settings.verbose = true end
    if a == "--no-verbose" then settings.verbose = false end
    if a == "--comments" then settings.comments = true end
    if a == "--no-comments" then settings.comments = false end
    if a == "--inline" then settings.inline_output = true end
    if a == "--no-inline" then settings.inline_output = false end
    local out = a:match("^--output=(.+)$")
    if out then settings.output_file = out end
    local cache = a:match("^--cache-dir=(.+)$")
    if cache then settings.cache_dir = cache end
end

-- Load user settings if available
local user_id = process.args[2]
if user_id and fs.isFile("dump_user_settings.json") then
    local ok, JsonDecode = pcall(function() return require("@lune/net").jsonDecode end)
    if ok then
        local ok2, data = pcall(function() return JsonDecode(fs.readFile("dump_user_settings.json")) end)
        if ok2 and data[user_id] then
            for k, v in data[user_id] do
                settings[k] = v
            end
        end
    end
end

local smart_unpack = function(packed)
    if packed and packed.n then
        return unpack(packed, 1, packed.n)
    end
    return unpack(packed or {})
end

local function tostring_impl(var)
    if oldtype(var) == "table" and getmetatable(var) and getmetatable(var).__type == "context_type" then
        return _tostring(var)
    end
    return _tostring(var)
end

local getfenv, string, table, debug, pcall, rawget, require = getfenv, string, table, debug, pcall, rawget, require
getfenv().require = function() end

local function unpackchoose(packed, ...)
    if packed then
        return unpack(packed)
    end
    return ...
end

local function multiunpack(...)
    local vars = {}
    for _, packed in {...} do
        for _, v in packed do
            insert(vars, v)
        end
    end
    return unpack(vars)
end

local function tablefind(tbl, value)
    for index, val in next, tbl do
        if val == value then
            return index
        end
    end
    return false
end

local tbl_to_s, tostring_complex, type

local function multiinsert(target, items)
    for _, item in items do
        insert(target, item)
    end
end

local identifier = tostring(math.random(1000000, 9999999))
local __25mslocation = "__25mslocation" .. tostring(math.random(1000000, 9999999))
local Enum_NOCALL = "NOCALL" .. tostring(math.random(1000000, 9999999))
local _print = print
local _printBuffer = {}

local function bufferedPrint(...)
    if settings.inline_output then
        table.insert(_printBuffer, table.concat({...}, "\t"))
    else
        _print(...)
    end
end

local is_bot = not not process.args[2]
if is_bot then
    bufferedPrint("-- wow this script had an infinite loop that wasnt resolved, this output was generated at runtime and is very bad.")
    bufferedPrint("-- script id: " .. tostring(process.args[1]))
end

local print = function(...)
    if is_bot and debug.info(2, "f") ~= simplelog then
        return
    end
    local args = {...}
    for i, v in args do
        if type(v) ~= "table" then
            args[i] = tostring(v):gsub(identifier .. "_?", "")
        end
    end
    bufferedPrint(unpack(args))
end

-- Code reconstruction with enhanced tracking
local codeLines = {}
local executedFunctions = {}
local globalAccess = {}
local tableOperations = {}
local functionCalls = {}
local variableAssignments = {}
local constantValues = {}

local function addCode(code)
    table.insert(codeLines, code)
end

local function addComment(comment)
    if settings.comments then
        table.insert(codeLines, "-- " .. comment)
    end
end

local function trackConstant(value, usage)
    if settings.constant_collection then
        if not constantValues[tostring(value)] then
            constantValues[tostring(value)] = {value = value, usages = 0, contexts = {}}
        end
        constantValues[tostring(value)].usages = constantValues[tostring(value)].usages + 1
        table.insert(constantValues[tostring(value)].contexts, usage)
    end
end

local function truncateString(str, maxLen)
    if settings.no_string_limit or #str <= maxLen then
        return str
    end
    local remaining = #str - maxLen
    return str:sub(1, maxLen) .. "...(" .. remaining .. " bytes left)"
end

-- Enhanced event system
local function createEvent()
    return setmetatable({}, {
        __index = function(t, k)
            if k == "Wait" or k == "wait" then
                return function() return nil end
            elseif k == "Connect" or k == "connect" or k == "ConnectParallel" then
                return function(self, callback) 
                    addComment("Event:Connect() called")
                    return setmetatable({
                        Connected = true,
                        Disconnect = function(self) self.Connected = false end,
                        disconnect = function(self) self.Connected = false end
                    }, {
                        __tostring = function() return "RBXScriptConnection" end
                    })
                end
            elseif k == "Fire" or k == "fire" or k == "FireServer" then
                return function(...) addComment("Event:Fire called") end
            end
            return createEvent()
        end,
        __call = function(t, ...)
            return nil
        end,
        __tostring = function() return "RBXScriptSignal" end
    })
end

-- Enhanced mock instance with tracking
local function createMockInstance(className, varName)
    local mock = {
        __className = className,
        __varName = varName,
        Name = className,
        Parent = nil
    }
    
    return setmetatable(mock, {
        __index = function(t, k)
            trackConstant(k, "instance_index:" .. className)
            
            if k == "WaitForChild" or k == "FindFirstChild" or k == "FindFirstChildOfClass" then
                return function(self, childName)
                    addComment("Instance method: " .. k .. "(" .. tostring(childName) .. ")")
                    return createMockInstance(childName or "Child", childName or "Child")
                end
            elseif k == "GetChildren" or k == "GetDescendants" then
                return function() addComment("Instance method: " .. k .. "()") return {} end
            elseif k == "GetPropertyChangedSignal" then
                return function(self, propName) 
                    addComment("GetPropertyChangedSignal: " .. tostring(propName))
                    return createEvent() 
                end
            elseif k == "Destroy" or k == "destroy" then
                return function() addComment(varName .. ":Destroy()") end
            elseif k == "Clone" or k == "clone" then
                return function() 
                    addComment(varName .. ":Clone()")
                    return createMockInstance(className, varName .. "_Clone") 
                end
            elseif k == "Connect" then
                return function(self, callback) 
                    addComment("Connect() on " .. varName)
                    return createEvent() 
                end
            elseif k == "IsA" then
                return function(self, typeName) 
                    trackConstant(typeName, "IsA_check")
                    return typeName == className 
                end
            elseif k:match("Click") or k:match("Input") or k:match("Changed") or k:match("beat") or k:match("Added") or k:match("Removing") or k:match("Enter") or k:match("Leave") then
                addComment("Event property accessed: " .. k)
                return createEvent()
            else
                globalAccess[k] = (globalAccess[k] or 0) + 1
                return createEvent()
            end
        end,
        __newindex = function(t, k, v)
            tableOperations[k] = (tableOperations[k] or 0) + 1
            local valueStr
            if type(v) == "string" then
                valueStr = '"' .. v .. '"'
                trackConstant(v, "string_assignment")
            elseif type(v) == "number" or type(v) == "boolean" then
                valueStr = tostring(v)
                trackConstant(v, "primitive_assignment")
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
            table.insert(variableAssignments, {target = varName .. "." .. k, value = valueStr})
        end,
        __call = function(t, ...)
            addComment("Instance called as function")
            return createEvent()
        end,
        __tostring = function()
            return varName
        end
    })
end

-- Enhanced environment
local env = {}

env.print = function(...)
    local args = {...}
    local strs = {}
    for i, v in ipairs(args) do
        if type(v) == "string" then
            trackConstant(v, "print_arg")
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
            trackConstant(v, "warn_arg")
            strs[i] = '"' .. truncateString(tostring(v), 256) .. '"'
        else
            strs[i] = tostring(v)
        end
    end
    addCode("warn(" .. table.concat(strs, ", ") .. ")")
end

local instanceCounter = 0
local instances = {}

env.Instance = {
    new = function(className, parent)
        instanceCounter = instanceCounter + 1
        local varName = "Instance" .. instanceCounter
        instances[varName] = className
        trackConstant(className, "instance_creation")
        
        if parent then
            addCode("local " .. varName .. ' = Instance.new("' .. className .. '", ' .. tostring(parent) .. ")")
        else
            addCode("local " .. varName .. ' = Instance.new("' .. className .. '")')
        end
        
        return createMockInstance(className, varName)
    end
}

-- Math types
env.Vector3 = {
    new = function(x, y, z)
        trackConstant({x, y, z}, "vector3_creation")
        return setmetatable({}, {
            __tostring = function() return string.format("Vector3.new(%g, %g, %g)", x or 0, y or 0, z or 0) end
        })
    end
}

env.Color3 = {
    fromRGB = function(r, g, b)
        trackConstant({r, g, b}, "color3_rgb")
        return setmetatable({}, {
            __tostring = function() return string.format("Color3.fromRGB(%d, %d, %d)", r, g, b) end
        })
    end,
    new = function(r, g, b)
        trackConstant({r, g, b}, "color3_new")
        return setmetatable({}, {
            __tostring = function() return string.format("Color3.new(%g, %g, %g)", r, g, b) end
        })
    end,
    fromHSV = function(h, s, v)
        trackConstant({h, s, v}, "color3_hsv")
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
        trackConstant(name, "brickcolor")
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
env.wait = function(t) 
    if t then addComment("wait(" .. t .. ")") end
    return 0 
end
env.delay = function(t, f) 
    addComment("delay(" .. t .. ", function)")
    return 0 
end
env.spawn = function(f) 
    addComment("spawn(function)")
    f() 
end

env.Enum = setmetatable({}, {
    __index = function(t, k)
        trackConstant(k, "enum_access")
        return setmetatable({}, {
            __index = function(t2, v)
                trackConstant(v, "enum_value")
                return setmetatable({}, {
                    __tostring = function() return "Enum." .. k .. "." .. v end
                })
            end
        })
    end
})

local services = {}
env.game = setmetatable({}, {
    __index = function(t, k)
        if k == "GetService" then
            return function(self, name)
                trackConstant(name, "service_access")
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
                        services[name].Teleport = function(self, placeId) 
                            trackConstant(placeId, "teleport_place")
                            addCode("TeleportService:Teleport(" .. placeId .. ")") 
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
    trackConstant(url, "http_request")
    addCode('HttpGet("' .. tostring(url) .. '")')
    return "Mock Response"
end

env.HttpGetAsync = env.HttpGet

env.request = function(options)
    local url = type(options) == "table" and options.Url or tostring(options)
    local method = type(options) == "table" and options.Method or "GET"
    trackConstant(url, "request_url")
    trackConstant(method, "request_method")
    addCode('request({Url = "' .. url .. '", Method = "' .. method .. '"})')
    return createMockResponse()
end

env.http_request = env.request
env.syn = { request = env.request }

env.writefile = function(filename, content)
    trackConstant(filename, "file_write")
    addCode('writefile("' .. filename .. '", [content])')
end

env.readfile = function(filename)
    trackConstant(filename, "file_read")
    addCode('readfile("' .. filename .. '")')
    return ""
end

env.isfile = function(filename) return true end
env.delfile = function(filename) 
    trackConstant(filename, "file_delete")
    addCode('delfile("' .. filename .. '")') 
end
env.listfiles = function(folder) 
    trackConstant(folder, "list_files")
    return {} 
end
env.makefolder = function(folder) 
    trackConstant(folder, "make_folder")
    addCode('makefolder("' .. folder .. '")') 
end
env.delfolder = function(folder) 
    trackConstant(folder, "del_folder")
    addCode('delfolder("' .. folder .. '")') 
end

env.loadstring = function(code)
    addComment("loadstring called with code length: " .. #code)
    addCode("loadstring([code])")
    return function() end
end

env.getgenv = function() return env end
env.getrenv = function() return env end
env.getreg = function() return {} end
env.getgc = function() return {} end
env.getinstances = function() return {} end
env.getnilinstances = function() return {} end
env.getloadedmodules = function() return {} end
env.getconnections = function() return {} end
env.firesignal = function(signal, ...) 
    addComment("firesignal called")
    addCode("firesignal(...)") 
end
env.fireclickdetector = function(part) 
    addCode("fireclickdetector(" .. tostring(part) .. ")") 
end
env.firetouchinterest = function(part) 
    addCode("firetouchinterest(" .. tostring(part) .. ")") 
end
env.fireproximityprompt = function(prompt) 
    addCode("fireproximityprompt(" .. tostring(prompt) .. ")") 
end
env.setreadonly = function(t, val) end
env.isreadonly = function(t) return false end
env.setclipboard = function(text)
    local preview = tostring(text):sub(1, 50)
    trackConstant(preview, "clipboard")
    addCode('setclipboard("' .. preview .. '")')
end

env.checkcaller = function() return true end
env.newcclosure = function(f) return f end
env.clonefunction = function(f) return f end

env.hookfunction = function(original, hook)
    addComment("hookfunction called")
    addCode("hookfunction([function], [hook])")
    return original
end

env.hookmetamethod = function(obj, method, hook)
    trackConstant(method, "hooked_method")
    addCode('hookmetamethod([obj], "' .. tostring(method) .. '", [hook])')
    return function() end
end

env.Drawing = {
    new = function(drawingType)
        instanceCounter = instanceCounter + 1
        local varName = "Drawing" .. instanceCounter
        trackConstant(drawingType, "drawing_type")
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

env.task = {
    wait = function(t)
        addComment("task.wait called")
        addCode("task.wait(" .. (t or "") .. ")")
        return 0
    end,
    spawn = function(func)
        addComment("task.spawn called")
        addCode("task.spawn(function() end)")
    end,
    delay = function(t, func)
        addComment("task.delay called")
        addCode("task.delay(" .. t .. ", function() end)")
    end
}

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

env.math = math
env.table = table
env.string = string
env.coroutine = coroutine
env.os = os
env.bit32 = bit32
env.utf8 = utf8

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

-- Main execution
local targetfilename = process.args[1]

if not targetfilename then
    bufferedPrint("lol you didnt put a filename")
    process.exit(1)
end

local commercial = false
local inpath = commercial and "" or "dumps\\original\\"
local outpath = commercial and "" or "dumps\\dumped\\"

local input
if fs.isFile(inpath .. targetfilename) then
    input = fs.readFile(inpath .. targetfilename)
elseif fs.isFile(targetfilename) then
    input = fs.readFile(targetfilename)
else
    bufferedPrint("file not found: " .. targetfilename)
    process.exit(1)
end

local chunk, err = luau.load(input, "sandbox")
if err then
    bufferedPrint("Load error: " .. err)
    process.exit(1)
end

-- Execute
setfenv(chunk, env)
local success, result = pcall(chunk)

if not success then
    addComment("Runtime error: " .. tostring(result))
else
    if type(result) == "function" then
        setfenv(result, env)
        pcall(result)
    end
end

-- Output raw code inline
local output = ""

output = output .. "-- ============================================\n"
output = output .. "-- RECONSTRUCTED LUA CODE\n"
output = output .. "-- Generated by: httplog2_combined.lua\n"
output = output .. "-- Source: " .. targetfilename .. "\n"
output = output .. "-- Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
output = output .. "-- ============================================\n\n"

for _, line in ipairs(codeLines) do
    output = output .. line .. "\n"
end

-- Add analysis section
if settings.verbose then
    output = output .. "\n-- ============================================\n"
    output = output .. "-- ANALYSIS REPORT\n"
    output = output .. "-- ============================================\n\n"
    
    output = output .. "-- GLOBAL ACCESS SUMMARY:\n"
    for key, count in pairs(globalAccess) do
        output = output .. "-- " .. key .. ": " .. count .. " access(es)\n"
    end
    
    output = output .. "\n-- TABLE OPERATIONS:\n"
    for key, count in pairs(tableOperations) do
        output = output .. "-- " .. key .. ": " .. count .. " operation(s)\n"
    end
    
    if settings.constant_collection then
        output = output .. "\n-- DETECTED CONSTANTS:\n"
        for key, data in pairs(constantValues) do
            output = output .. "-- Value: " .. tostring(data.value) .. " (used " .. data.usages .. " times)\n"
        end
    end
    
    output = output .. "\n-- VARIABLE ASSIGNMENTS:\n"
    for i, assignment in ipairs(variableAssignments) do
        if i <= 20 then
            output = output .. "-- " .. assignment.target .. " = " .. assignment.value .. "\n"
        end
    end
    if #variableAssignments > 20 then
        output = output .. "-- ... and " .. (#variableAssignments - 20) .. " more assignments\n"
    end
end

output = output .. "\n-- ============================================\n"
output = output .. "-- END OF RECONSTRUCTED CODE\n"
output = output .. "-- ============================================\n"

-- Output inline
_print(output)

-- Save to file if requested
if settings.output_file then
    fs.writeFile(settings.output_file, output)
    bufferedPrint("\n-- Output written to: " .. settings.output_file)
end

-- Flush buffer if needed
if settings.inline_output and #_printBuffer > 0 then
    for _, line in ipairs(_printBuffer) do
        _print(line)
    end
end
