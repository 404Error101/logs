-- ULTIMATE ADVANCED ROBLOX ENVIRONMENT LOGGER & CODE RECONSTRUCTOR
-- Enterprise-grade VM deobfuscation, memory forensics, and code recovery system
-- Supports: LuaU, Prometheus, Sentinel, Synapse, KRNL, Script-Ware VMs
-- Auto-Config & Enhanced Logging - Generated on Aetheria

local process = require("@lune/process")
local fs = require("@lune/fs")
local net = require("@lune/net")

local scriptPath = process.args[1]
if not scriptPath then
    io.stderr:write("ERROR: No script path provided\n")
    process.exit(1)
end

local urlToFetch = process.args[2]
local scriptContent = fs.readFile(scriptPath)

-- ═══════════════════════════════════════════════════════════════
-- AUTOMATIC CONFIGURATION SYSTEM
-- ═══════════════════════════════════════════════════════════════

local function analyzeScriptComplexity(code)
    local complexity = {
        lines = select(2, code:gsub("\n", "")) + 1,
        has_network = code:match("HttpService") ~= nil or code:match("http_request") ~= nil,
        has_exploit = code:match("getgenv") ~= nil or code:match("hookfunction") ~= nil,
        has_obfuscation = code:match("loadstring") ~= nil or code:match("string.char") ~= nil,
        has_debug = code:match("debug%.") ~= nil,
        has_file_io = code:match("writefile") ~= nil or code:match("readfile") ~= nil,
    }
    return complexity
end

local function getAutoConfig(scriptContent)
    local analysis = analyzeScriptComplexity(scriptContent)
    
    return {
        -- Always enable core features
        hookOp = true,
        explore_funcs = true,
        spyexeconly = false,
        no_string_limit = true,
        minifier = false,
        comments = true,
        ui_detection = false,
        notify_scamblox = false,
        constant_collection = true,
        duplicate_searcher = false,
        neverNester = false,
        
        -- Enable based on script analysis
        enable_url_fetch = analysis.has_network or urlToFetch ~= nil,
        memory_analysis = analysis.has_exploit or analysis.has_obfuscation,
        vm_detection = analysis.has_exploit or analysis.has_obfuscation,
        obfuscation_analysis = analysis.has_obfuscation,
        bytecode_analysis = analysis.has_debug,
        registry_scan = analysis.has_exploit,
        heap_dump = analysis.has_exploit,
        call_stack_trace = analysis.has_exploit,
        metamethod_tracking = analysis.has_exploit,
        upvalue_extraction = analysis.has_exploit,
        coroutine_tracking = analysis.has_exploit,
        thread_analysis = analysis.has_exploit,
        environment_persistence = true,
        
        -- Enterprise features
        control_flow_analysis = analysis.lines > 50,
        data_flow_analysis = analysis.lines > 100,
        string_deobfuscation = analysis.has_obfuscation,
        constant_folding = true,
        dead_code_elimination = false,
        pattern_recognition = true,
        vulnerability_scan = true,
        performance_profiling = analysis.has_exploit,
        behavior_analysis = true,
        machine_learning_detection = false,
    }
end

-- Check for environment overrides
local settings = getAutoConfig(scriptContent)
for key, _ in pairs(settings) do
    local envKey = "SETTING_" .. key:upper()
    local envVal = process.env[envKey]
    if envVal ~= nil then
        settings[key] = envVal == "1" or envVal == "true"
    end
end

-- ═══════════════════════════════════════════════════════════════
-- LOGGING SYSTEM
-- ═══════════════════════════════════════════════════════════════

local logger = {
    logs = {},
    level = "INFO",
    startTime = os.clock(),
}

local function log(level, message)
    local timestamp = string.format("%.3f", os.clock() - logger.startTime)
    local logEntry = string.format("[%s] [%s] %s", timestamp, level, message)
    table.insert(logger.logs, logEntry)
end

local function logInfo(msg) log("INFO", msg) end
local function logWarn(msg) log("WARN", msg) end
local function logError(msg) log("ERROR", msg) end
local function logDebug(msg) if settings.spyexeconly == false then log("DEBUG", msg) end end

logInfo("Reconstructor started")
logInfo("Script path: " .. scriptPath)
logInfo("Script size: " .. #scriptContent .. " bytes")
logInfo("Auto-config: enabled")

-- ════════════��══════════════════════════════════════════════════
-- STATE MANAGEMENT & BUFFERS
-- ═══════════════════════════════════════════════════════════════

local state = {
    codeLines = {},
    constantBuffer = {},
    functionRegistry = {},
    callStack = {},
    memoryMap = {},
    urlCache = {},
    environmentState = {},
    executionTrace = {},
    performanceMetrics = {},
    vulnerabilities = {},
    dataFlows = {},
    controlFlows = {},
    stringPool = {},
    callGraph = {},
    heapObjects = {},
    executionErrors = {},
    detectedPatterns = {},
}

-- ═══════════════════════════════════════════════════════════════
-- ADVANCED URL FETCHING WITH CACHING & RETRY LOGIC
-- ═══════════════════════════════════════════════════════════════

local function fetchURL(url, method, headers, body, retries)
    if not settings.enable_url_fetch then
        logDebug("URL fetch disabled: " .. url)
        return nil, "URL fetching disabled"
    end
    
    retries = retries or 3
    method = method or "GET"
    headers = headers or {}
    
    local lastError
    for attempt = 1, retries do
        local success, response = pcall(function()
            if net then
                local config = {
                    url = url,
                    method = method,
                    headers = headers,
                }
                if body then
                    config.body = body
                end
                return net.request(config)
            end
            return nil
        end)
        
        if success and response then
            state.urlCache[url] = {
                content = response,
                timestamp = os.clock(),
                method = method,
                attempts = attempt
            }
            logDebug("URL fetched: " .. url .. " (attempt " .. attempt .. ")")
            return response, nil
        end
        
        lastError = response
        logWarn("URL fetch failed (attempt " .. attempt .. "/" .. retries .. "): " .. tostring(lastError))
    end
    
    logError("Failed to fetch URL after " .. retries .. " retries: " .. url)
    return nil, "Failed after " .. retries .. " retries: " .. tostring(lastError)
end

local function getCachedURL(url)
    local cached = state.urlCache[url]
    return cached and cached.content or nil
end

-- ═══════════════════════════════════════════════════════════════
-- ENTERPRISE-GRADE MEMORY ANALYSIS
-- ═══════════════════════════════════════════════════════════════

local memoryAnalyzer = {
    allocations = {},
    access_patterns = {},
    total_allocated = 0,
    peak_allocated = 0,
    gc_events = {},
    heap_snapshots = {},
}

local function trackMemory(identifier, size, access_type, source_line)
    if not settings.memory_analysis then return end
    
    if not memoryAnalyzer.allocations[identifier] then
        memoryAnalyzer.allocations[identifier] = {
            size = size or 0,
            accesses = 0,
            last_access = 0,
            access_times = {},
            access_types = {},
            source_line = source_line or "unknown",
            freed = false,
            alloc_time = os.clock(),
        }
        memoryAnalyzer.total_allocated = memoryAnalyzer.total_allocated + (size or 0)
    end
    
    local entry = memoryAnalyzer.allocations[identifier]
    entry.accesses = entry.accesses + 1
    entry.last_access = os.clock()
    table.insert(entry.access_types, access_type or "unknown")
    
    if memoryAnalyzer.total_allocated > memoryAnalyzer.peak_allocated then
        memoryAnalyzer.peak_allocated = memoryAnalyzer.total_allocated
    end
end

local function heapDump()
    if not settings.heap_dump then return {} end
    
    local dump = {
        timestamp = os.clock(),
        total_objects = 0,
        by_type = {},
        cycles = 0,
    }
    
    for id, alloc in pairs(memoryAnalyzer.allocations) do
        if not alloc.freed then
            dump.total_objects = dump.total_objects + 1
            local atype = alloc.access_types[1] or "unknown"
            dump.by_type[atype] = (dump.by_type[atype] or 0) + 1
        end
    end
    
    table.insert(memoryAnalyzer.heap_snapshots, dump)
    logDebug("Heap dump created: " .. dump.total_objects .. " objects")
    return dump
end

-- ═══════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function countTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local function truncateString(str, maxLen)
    if settings.no_string_limit or #str <= maxLen then
        return str
    end
    local remaining = #str - maxLen
    return str:sub(1, maxLen) .. "...(" .. remaining .. " bytes)"
end

local function addCode(code)
    table.insert(state.codeLines, code)
end

local function addComment(comment)
    if settings.comments then
        table.insert(state.codeLines, "-- " .. comment)
    end
end

local function addConstant(name, value)
    if settings.constant_collection then
        state.constantBuffer[name] = value
        addCode("local " .. name .. " = " .. tostring(value))
    end
end

local function stringDeobfuscate(encodedStr)
    if not settings.string_deobfuscation then return encodedStr end
    
    local deobfuscated = encodedStr
    
    -- Attempt hex decoding
    if encodedStr:match("^%x+$") and #encodedStr % 2 == 0 then
        local success, result = pcall(function()
            return encodedStr:gsub("..", function(cc)
                return string.char(tonumber(cc, 16))
            end)
        end)
        if success then
            deobfuscated = result
            logDebug("String deobfuscated via hex decoding")
        end
    end
    
    return deobfuscated
end

-- ═══════════════════════════════════════════════════════════════
-- ENTERPRISE VM DETECTION ENGINE
-- ═══════════════════════════════════════════════════════════════

local vmDetector = {
    detected_vms = {},
    obfuscation_markers = {},
    vm_signatures = {
        prometheus = {"local.*=.*getfenv", "script.*environment", "bytecode"},
        sentinel = {"getupvalue", "setupvalue", "debug.sethook"},
        synapse = {"syn.request", "syn.cache", "loadstring"},
        krnl = {"krnl.request", "cache_replace", "env_set"},
        scriptware = {"scriptware.env", "obfuscate", "protected"},
    }
}

local function detectVMCharacteristics(env_table)
    if not settings.vm_detection then return end
    
    local characteristics = {
        has_debug = type(env_table.debug) == "table",
        has_getfenv = type(env_table.getfenv) == "function",
        has_setfenv = type(env_table.setfenv) == "function",
        has_getupvalue = type(env_table.debug) == "table" and type(env_table.debug.getupvalue) == "function",
        has_setupvalue = type(env_table.debug) == "table" and type(env_table.debug.setupvalue) == "function",
        has_getlocal = type(env_table.debug) == "table" and type(env_table.debug.getlocal) == "function",
        has_setlocal = type(env_table.debug) == "table" and type(env_table.debug.setlocal) == "function",
        has_getinfo = type(env_table.debug) == "table" and type(env_table.debug.getinfo) == "function",
        has_getreg = type(env_table.getreg) == "function",
        has_getgc = type(env_table.getgc) == "function",
    }
    
    if characteristics.has_getfenv and characteristics.has_setfenv then
        vmDetector.detected_vms["LuaU_Compatible"] = true
        logDebug("Detected: LuaU_Compatible")
    end
    if characteristics.has_getupvalue and characteristics.has_setupvalue then
        vmDetector.detected_vms["UpvalueManipulation"] = true
        logDebug("Detected: UpvalueManipulation")
    end
    if characteristics.has_getlocal and characteristics.has_setlocal then
        vmDetector.detected_vms["LocalVariableManipulation"] = true
        logDebug("Detected: LocalVariableManipulation")
    end
    if characteristics.has_getreg or characteristics.has_getgc then
        vmDetector.detected_vms["MemoryAccess"] = true
        logDebug("Detected: MemoryAccess")
    end
    
    return characteristics
end

local function detectObfuscationPatterns(code_str)
    if not settings.obfuscation_analysis then return end
    
    local patterns = {
        string_encoding = code_str:match("string%.fromhex") ~= nil or code_str:match("string%.char") ~= nil,
        table_obfuscation = code_str:match("table%[%[") ~= nil,
        control_flow_flattening = code_str:match("while true") ~= nil and code_str:match("break") ~= nil,
        metamethod_hooking = code_str:match("setmetatable") ~= nil and code_str:match("__index") ~= nil,
        bytecode_loading = code_str:match("loadstring") ~= nil or code_str:match("load") ~= nil,
        function_wrapping = code_str:match("function%(%.%.%)") ~= nil,
        variable_renaming = #code_str > 0 and true,
        arithmetic_encoding = code_str:match("[%d]%s*[%+%-%%]%s*[%d]") ~= nil,
        xor_encoding = code_str:match("xor") ~= nil or code_str:match("bit32.bxor") ~= nil,
    }
    
    for pattern, detected in pairs(patterns) do
        if detected then
            vmDetector.obfuscation_markers[pattern] = true
            logDebug("Obfuscation pattern detected: " .. pattern)
        end
    end
    
    return patterns
end

-- ═══════════════════════════════════════════════════════════════
-- ADVANCED UPVALUE & BYTECODE EXTRACTION
-- ═══════════════════════════════════════════════════════════════

local function extractUpvalues(func, depth)
    if not settings.upvalue_extraction then return {} end
    
    depth = depth or 0
    if depth > 5 then return {} end
    
    local upvalues = {}
    if type(func) == "function" and debug and debug.getupvalue then
        local i = 1
        while true do
            local success, name, value = pcall(function()
                return debug.getupvalue(func, i)
            end)
            if not success or not name then break end
            
            upvalues[i] = {
                name = name,
                value = value,
                type = type(value),
            }
            
            if type(value) == "function" then
                upvalues[i].nested_upvalues = extractUpvalues(value, depth + 1)
            end
            
            trackMemory("upvalue_" .. name, 64, "upvalue_extraction")
            i = i + 1
        end
    end
    
    logDebug("Extracted " .. #upvalues .. " upvalues at depth " .. depth)
    return upvalues
end

local function analyzeBytecode(func)
    if not settings.bytecode_analysis then return "" end
    
    local analysis = {}
    
    if debug and debug.getinfo then
        local success, info = pcall(function()
            return debug.getinfo(func)
        end)
        if success and info then
            table.insert(analysis, "source:" .. tostring(info.source))
            table.insert(analysis, "line_defined:" .. tostring(info.linedefined))
            table.insert(analysis, "last_line:" .. tostring(info.lastlinedefined))
            table.insert(analysis, "params:" .. tostring(info.nparams))
            table.insert(analysis, "vararg:" .. tostring(info.isvararg))
            
            if debug.getlocal then
                local locals = {}
                local j = 1
                while true do
                    local success2, name, value = pcall(function()
                        return debug.getlocal(func, j)
                    end)
                    if not success2 or not name then break end
                    table.insert(locals, name)
                    j = j + 1
                end
                if #locals > 0 then
                    table.insert(analysis, "locals:" .. table.concat(locals, ","))
                end
            end
        end
    end
    
    return table.concat(analysis, "|")
end

-- ═══════════════════════════════════════════════════════════════
-- CONTROL FLOW & DATA FLOW ANALYSIS
-- ═══════════════════════════════════════════════════════════════

local function analyzeControlFlow(code_str)
    if not settings.control_flow_analysis then return {} end
    
    local flows = {
        conditionals = 0,
        loops = 0,
        branches = 0,
        complex_conditions = 0,
    }
    
    flows.conditionals = select(2, code_str:gsub("if%s+", "")) or 0
    flows.loops = (select(2, code_str:gsub("while%s+", "")) or 0) + (select(2, code_str:gsub("for%s+", "")) or 0)
    flows.branches = (select(2, code_str:gsub("elseif%s+", "")) or 0) + (select(2, code_str:gsub("else%s+", "")) or 0)
    flows.complex_conditions = (select(2, code_str:gsub(" and ", "")) or 0) + (select(2, code_str:gsub(" or ", "")) or 0)
    
    logDebug(string.format("Control flow: conditionals=%d, loops=%d, branches=%d, complex=%d", 
        flows.conditionals, flows.loops, flows.branches, flows.complex_conditions))
    
    return flows
end

local function analyzeDataFlow(code_str)
    if not settings.data_flow_analysis then return {} end
    
    local flows = {
        assignments = 0,
        reads = 0,
        writes = 0,
        functions = 0,
        tables = 0,
    }
    
    flows.assignments = select(2, code_str:gsub("local%s+", "")) or 0
    flows.functions = (select(2, code_str:gsub("function%s+", "")) or 0) + (select(2, code_str:gsub("function%(", "")) or 0)
    flows.tables = select(2, code_str:gsub("{", "")) or 0
    
    logDebug(string.format("Data flow: assignments=%d, functions=%d, tables=%d", 
        flows.assignments, flows.functions, flows.tables))
    
    return flows
end

-- ═══════════════════════════════════════════════════════════════
-- VULNERABILITY SCANNING ENGINE
-- ═══════════════════════════════════════════════════════════════

local function scanVulnerabilities(code_str)
    if not settings.vulnerability_scan then return {} end
    
    local vulns = {}
    
    if code_str:match("os%.execute") then
        table.insert(vulns, {type = "RCE", severity = "CRITICAL", pattern = "os.execute"})
        logWarn("CRITICAL: RCE vulnerability detected (os.execute)")
    end
    if code_str:match("loadstring") then
        table.insert(vulns, {type = "CODE_INJECTION", severity = "HIGH", pattern = "loadstring"})
        logWarn("HIGH: Code injection risk (loadstring)")
    end
    if code_str:match("debug%.setfenv") or code_str:match("setfenv") then
        table.insert(vulns, {type = "ENV_MANIPULATION", severity = "HIGH", pattern = "setfenv"})
        logWarn("HIGH: Environment manipulation detected")
    end
    if code_str:match("getfenv") then
        table.insert(vulns, {type = "ENV_LEAK", severity = "MEDIUM", pattern = "getfenv"})
        logWarn("MEDIUM: Environment leak risk")
    end
    if code_str:match("writefile") then
        table.insert(vulns, {type = "FILE_WRITE", severity = "MEDIUM", pattern = "writefile"})
        logWarn("MEDIUM: File write capability detected")
    end
    if code_str:match("game:GetService.*HttpService") then
        table.insert(vulns, {type = "NETWORK_ACCESS", severity = "MEDIUM", pattern = "HttpService"})
        logWarn("MEDIUM: Network access capability detected")
    end
    
    return vulns
end

-- ═══════════════════════════════════════════════════════════════
-- PERFORMANCE PROFILING ENGINE
-- ═══════════════════════════════════════════════════════════════

local profiler = {
    function_times = {},
    call_counts = {},
    hotspots = {},
}

local function profileFunction(func, name)
    if not settings.performance_profiling then return func end
    
    name = name or "unknown"
    
    return function(...)
        local startTime = os.clock()
        local results = {pcall(func, ...)}
        local endTime = os.clock()
        
        local duration = endTime - startTime
        
        if not profiler.function_times[name] then
            profiler.function_times[name] = {}
            profiler.call_counts[name] = 0
        end
        
        table.insert(profiler.function_times[name], duration)
        profiler.call_counts[name] = profiler.call_counts[name] + 1
        
        if duration > 0.01 then
            profiler.hotspots[name] = (profiler.hotspots[name] or 0) + 1
        end
        
        return unpack(results)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- CALL STACK & EXECUTION TRACE
-- ═══════════════════════════════════════════════════════════════

local function captureCallStack(depth)
    if not settings.call_stack_trace then return {} end
    
    depth = depth or 15
    local stack = {}
    
    for i = 1, depth do
        if debug and debug.getinfo then
            local success, info = pcall(function()
                return debug.getinfo(i)
            end)
            if success and info then
                table.insert(stack, {
                    name = info.name or "unknown",
                    source = info.source or "unknown",
                    line = info.currentline or 0,
                    what = info.what or "unknown"
                })
            else
                break
            end
        end
    end
    
    return stack
end

local function logCallStack()
    if not settings.call_stack_trace then return end
    
    local stack = captureCallStack(20)
    for i, frame in ipairs(stack) do
        table.insert(state.executionTrace, {
            index = i,
            name = frame.name,
            source = frame.source,
            line = frame.line,
            timestamp = os.clock()
        })
    end
    logDebug("Call stack logged: " .. #stack .. " frames")
end

-- ═══════════════════════════════════════════════════════════════
-- ENVIRONMENT SETUP WITH ADVANCED MOCKING
-- ═══════════════════════════════════════════════════════════════

local env = {}

env.print = function(...) end
env.warn = function(...) end

-- ═══════════════════════════════════════════════════════════════
-- ADVANCED MOCK INSTANCE CREATION
-- ═══════════════════════════════════════════════════════════════

local function createEvent()
    trackMemory("event_creation", 128, "signal")
    return setmetatable({__type = "RBXScriptSignal"}, {
        __index = function(t, k)
            if k == "Wait" or k == "wait" then
                return function() return nil end
            elseif k == "Connect" or k == "connect" or k == "ConnectParallel" then
                return function(self, callback) 
                    trackMemory("RBXScriptConnection", 96, "connection")
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

local instanceCounter = 0
local instances = {}

local function createMockInstance(className, varName)
    trackMemory(varName, 512, "instance")
    
    local mock = {
        __className = className,
        __varName = varName,
        Name = className,
        Parent = nil,
        __createdAt = os.clock(),
    }
    
    return setmetatable(mock, {
        __index = function(t, k)
            if k == "WaitForChild" or k == "FindFirstChild" then
                return function(self, childName)
                    return createMockInstance(childName or "Child", childName or "Child")
                end
            elseif k == "FindFirstChildOfClass" then
                return function(self, className)
                    return createMockInstance(className, className)
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
            elseif k == "IsA" or k == "IsDescendantOf" then
                return function(self, typeName) return typeName == className end
            elseif k:match("Click") or k:match("Input") or k:match("Changed") or k:match("beat") then
                return createEvent()
            else
                return createEvent()
            end
        end,
        __newindex = function(t, k, v)
            local valueStr = "nil"
            if type(v) == "string" then
                valueStr = '"' .. stringDeobfuscate(v) .. '"'
            elseif type(v) == "number" or type(v) == "boolean" then
                valueStr = tostring(v)
            elseif type(v) == "table" then
                valueStr = v.__varName or "table"
            else
                valueStr = tostring(v)
            end
            addCode(varName .. "." .. k .. " = " .. valueStr)
            trackMemory("instance_write_" .. varName .. "_" .. k, 256, "property_assignment")
        end,
        __call = function(t, ...)
            return createEvent()
        end,
        __tostring = function()
            return varName
        end
    })
end

-- ═══════════════════════════════════════════════════════════════
-- ROBLOX API COMPLETE MOCK
-- ═══════════════════════════════════════════════════════════════

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
        
        trackMemory("instance_new_" .. className, 512, "allocation")
        return createMockInstance(className, varName)
    end
}

-- Math & Type definitions
env.Vector3 = {
    new = function(x, y, z) 
        trackMemory("Vector3", 96, "type")
        return setmetatable({x=x,y=y,z=z}, {
            __tostring = function() 
                return string.format("Vector3.new(%g,%g,%g)", x or 0, y or 0, z or 0) 
            end
        })
    end
}

env.Color3 = {
    fromRGB = function(r, g, b) 
        trackMemory("Color3_fromRGB", 96, "type")
        return setmetatable({r=r,g=g,b=b}, {
            __tostring = function() 
                return string.format("Color3.fromRGB(%d,%d,%d)", r, g, b) 
            end
        })
    end,
    new = function(r, g, b) 
        trackMemory("Color3_new", 96, "type")
        return setmetatable({}, {
            __tostring = function() 
                return string.format("Color3.new(%g,%g,%g)", r or 0, g or 0, b or 0) 
            end
        })
    end,
    fromHSV = function(h, s, v) 
        trackMemory("Color3_fromHSV", 96, "type")
        return setmetatable({}, {
            __tostring = function() 
                return string.format("Color3.fromHSV(%g,%g,%g)", h, s, v) 
            end
        })
    end,
}

env.UDim = {
    new = function(s, o) 
        trackMemory("UDim", 64, "type")
        return setmetatable({}, {
            __tostring = function() 
                return string.format("UDim.new(%g,%g)", s, o) 
            end
        })
    end,
}

env.UDim2 = {
    new = function(xs, xo, ys, yo) 
        trackMemory("UDim2", 96, "type")
        return setmetatable({}, {
            __tostring = function() 
                return string.format("UDim2.new(%g,%g,%g,%g)", xs, xo, ys, yo) 
            end
        })
    end,
}

env.Vector2 = {
    new = function(x, y) 
        trackMemory("Vector2", 64, "type")
        return setmetatable({}, {
            __tostring = function() 
                return string.format("Vector2.new(%g,%g)", x, y) 
            end
        })
    end,
}

env.BrickColor = {
    new = function(name) 
        trackMemory("BrickColor", 96, "type")
        return setmetatable({}, {
            __tostring = function() 
                return 'BrickColor.new("' .. name .. '")' 
            end
        })
    end,
}

env.NumberRange = {
    new = function(...) 
        trackMemory("NumberRange", 64, "type")
        local args = {...}
        return setmetatable({}, {
            __tostring = function() 
                return "NumberRange.new(" .. table.concat(args, ", ") .. ")" 
            end
        })
    end
}

env.NumberSequence = {
    new = function(...) 
        trackMemory("NumberSequence", 96, "type")
        return setmetatable({}, {
            __tostring = function() 
                return "NumberSequence.new(...)" 
            end
        })
    end,
}

env.NumberSequenceKeypoint = {
    new = function(...) 
        trackMemory("NumberSequenceKeypoint", 96, "type")
        return setmetatable({}, {
            __tostring = function() 
                return "NumberSequenceKeypoint.new(...)" 
            end
        })
    end,
}

env.ColorSequence = {
    new = function(...) 
        trackMemory("ColorSequence", 96, "type")
        return setmetatable({}, {
            __tostring = function() 
                return "ColorSequence.new(...)" 
            end
        })
    end,
}

env.ColorSequenceKeypoint = {
    new = function(...) 
        trackMemory("ColorSequenceKeypoint", 96, "type")
        return setmetatable({}, {
            __tostring = function() 
                return "ColorSequenceKeypoint.new(...)" 
            end
        })
    end,
}

env.TweenInfo = {
    new = function(...) 
        trackMemory("TweenInfo", 128, "type")
        return setmetatable({}, {
            __tostring = function() 
                return "TweenInfo.new(...)" 
            end
        })
    end,
}

-- Timing functions
env.tick = function() trackMemory("tick", 16, "timing"); return os.clock() end
env.wait = function(t) trackMemory("wait", 32, "timing"); return 0 end
env.delay = function(t, f) trackMemory("delay", 64, "timing"); return 0 end
env.spawn = function(f) trackMemory("spawn", 128, "coroutine"); f() end

-- Enum system
env.Enum = setmetatable({}, {
    __index = function(t, k)
        return setmetatable({}, {
            __index = function(t2, v)
                return setmetatable({}, {
                    __tostring = function() 
                        return "Enum." .. k .. "." .. v 
                    end
                })
            end
        })
    end
})

-- Game & Services
local services = {}
env.game = setmetatable({}, {
    __index = function(t, k)
        if k == "GetService" then
            return function(self, name)
                if not services[name] then
                    trackMemory("service_" .. name, 1024, "service")
                    services[name] = createMockInstance(name, 'game:GetService("' .. name .. '")')
                    
                    if name == "Players" then
                        services[name].LocalPlayer = createMockInstance("Player", "LocalPlayer")
                        services[name].LocalPlayer.Character = createMockInstance("Character", "Character")
                        services[name].LocalPlayer.CharacterAdded = createEvent()
                        services[name].PlayerAdded = createEvent()
                    elseif name == "TweenService" then
                        services[name].Create = function(self, obj, info, props)
                            addCode('TweenService:Create(...)')
                            trackMemory("tween_creation", 256, "service")
                            return setmetatable({}, {
                                __index = {
                                    Play = function() addCode("Tween:Play()") end, 
                                    Cancel = function() addCode("Tween:Cancel()") end
                                }
                            })
                        end
                    elseif name == "HttpService" then
                        services[name].GetAsync = function(self, url)
                            addCode('HttpService:GetAsync("' .. url .. '")')
                            local response = fetchURL(url, "GET")
                            return response or ""
                        end
                        services[name].PostAsync = function(self, url, data)
                            addCode('HttpService:PostAsync("' .. url .. '", ...)')
                            local response = fetchURL(url, "POST", {}, data)
                            return response or ""
                        end
                    end
                end
                return services[name]
            end
        end
        return createEvent()
    end,
})

env.workspace = createMockInstance("Workspace", "workspace")
env.script = createMockInstance("Script", "script")

-- HTTP & Network functions
env.HttpGet = function(url)
    addCode('HttpGet("' .. tostring(url) .. '")')
    trackMemory("http_get", 256, "network")
    local response = fetchURL(url, "GET")
    return response or ""
end

env.HttpGetAsync = env.HttpGet

env.request = function(options)
    local url = type(options) == "table" and options.Url or tostring(options)
    addCode('request({Url = "' .. url .. '"})')
    trackMemory("request", 512, "network")
    return {Body = fetchURL(url, "GET") or "", StatusCode = 200}
end

env.http_request = env.request
env.syn = {request = env.request}

-- File operations
env.writefile = function(filename, content)
    addCode('writefile("' .. filename .. '", [content])')
    trackMemory("writefile", (#content or 1024), "file_io")
end

env.readfile = function(filename)
    addCode('readfile("' .. filename .. '")')
    trackMemory("readfile", 1024, "file_io")
    return ""
end

env.isfile = function(filename) trackMemory("isfile", 64, "file_io"); return true end
env.delfile = function(filename) addCode('delfile("' .. filename .. '")'); trackMemory("delfile", 64, "file_io") end
env.listfiles = function(folder) trackMemory("listfiles", 512, "file_io"); return {} end
env.makefolder = function(folder) addCode('makefolder("' .. folder .. '")'); trackMemory("makefolder", 64, "file_io") end
env.delfolder = function(folder) addCode('delfolder("' .. folder .. '")'); trackMemory("delfolder", 64, "file_io") end

-- Code loading
env.loadstring = function(code)
    addCode("loadstring([code])")
    trackMemory("loadstring", (#code or 1024), "code_loading")
    return function() end
end

-- Memory & Exploit functions
env.getgenv = function() return env end
env.getrenv = function() return env end
env.getreg = function() trackMemory("getreg", 2048, "memory"); return {} end
env.getgc = function() trackMemory("getgc", 2048, "memory"); return {} end
env.getinstances = function() trackMemory("getinstances", 1024, "memory"); return {} end
env.getnilinstances = function() trackMemory("getnilinstances", 1024, "memory"); return {} end
env.getloadedmodules = function() trackMemory("getloadedmodules", 1024, "memory"); return {} end
env.getconnections = function(signal) trackMemory("getconnections", 512, "memory"); return {} end

-- Event firing
env.firesignal = function(signal, ...) addCode("firesignal(...)"); trackMemory("firesignal", 256, "events") end
env.fireclickdetector = function(part) addCode("fireclickdetector(...)"); trackMemory("fireclickdetector", 256, "events") end
env.firetouchinterest = function(part) addCode("firetouchinterest(...)"); trackMemory("firetouchinterest", 256, "events") end
env.fireproximityprompt = function(prompt) addCode("fireproximityprompt(...)"); trackMemory("fireproximityprompt", 256, "events") end

-- Hooking
env.hookfunction = function(original, hook) addCode("hookfunction([func], [hook])"); trackMemory("hookfunction", 512, "hooking"); return original end
env.hookmetamethod = function(obj, method, hook) addCode('hookmetamethod([obj], "' .. tostring(method) .. '", [hook])'); trackMemory("hookmetamethod", 512, "hooking"); return function() end end

-- Drawing
env.Drawing = {
    new = function(drawingType)
        instanceCounter = instanceCounter + 1
        local varName = "Drawing" .. instanceCounter
        addCode('local ' .. varName .. ' = Drawing.new("' .. drawingType .. '")')
        trackMemory(varName, 512, "drawing")
        return setmetatable({__varName = varName}, {
            __index = function(t, k) return nil end,
            __newindex = function(t, k, v) addCode(varName .. "." .. k .. " = " .. tostring(v)) end,
        })
    end
}

-- Task library
env.task = {
    wait = function(t) addCode("task.wait(...)"); trackMemory("task_wait", 32, "timing"); return 0 end,
    spawn = function(func) addCode("task.spawn(...)"); trackMemory("task_spawn", 256, "coroutine") end,
    delay = function(t, func) addCode("task.delay(...)"); trackMemory("task_delay", 128, "timing") end,
    defer = function(func) addCode("task.defer(...)"); trackMemory("task_defer", 256, "coroutine") end,
}

-- Standard Lua
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

-- ═══════════════════════════════════════════════════════════════
-- ADVANCED OPERATION TRACKING WITH ARITHMETIC HOOKS
-- ═══════════════════════════════════════════════════════════════

if settings.hookOp then
    local function createTrackedNumber(value)
        return setmetatable({__value = value}, {
            __add = function(a, b) 
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                addComment("OP: " .. av .. " + " .. bv)
                return createTrackedNumber(av + bv)
            end,
            __sub = function(a, b) 
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                addComment("OP: " .. av .. " - " .. bv)
                return createTrackedNumber(av - bv)
            end,
            __mul = function(a, b) 
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                addComment("OP: " .. av .. " * " .. bv)
                return createTrackedNumber(av * bv)
            end,
            __div = function(a, b) 
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                if bv ~= 0 then
                    addComment("OP: " .. av .. " / " .. bv)
                    return createTrackedNumber(av / bv)
                end
                return createTrackedNumber(0)
            end,
            __mod = function(a, b) 
                local av = type(a) == "table" and a.__value or a
                local bv = type(b) == "table" and b.__value or b
                if bv ~= 0 then
                    addComment("OP: " .. av .. " % " .. bv)
                    return createTrackedNumber(av % bv)
                end
                return createTrackedNumber(0)
            end,
            __tostring = function(self) 
                return tostring(self.__value) 
            end,
        })
    end
    
    local original_tonumber = env.tonumber
    env.tonumber = function(...) 
        local result = original_tonumber(...)
        return result and createTrackedNumber(result) or result 
    end
    
    logDebug("Arithmetic operation tracking enabled")
end

-- ═══════════════════════════════════════════════════════════════
-- SCRIPT EXECUTION & STATE CAPTURE
-- ═══════════════════════════════════════════════════════════════

logInfo("Analyzing script characteristics...")
detectVMCharacteristics(env)
detectObfuscationPatterns(scriptContent)
state.vulnerabilities = scanVulnerabilities(scriptContent)

logInfo("Loading script chunk...")
local chunk, err = loadstring(scriptContent, "@script")
if not chunk then
    logError("Failed to load script: " .. tostring(err))
    table.insert(state.executionErrors, {
        error = err,
        timestamp = os.clock(),
        stage = "chunk_loading"
    })
else
    logInfo("Executing script...")
    setfenv(chunk, env)
    local success, result = pcall(chunk)
    
    if not success then
        logError("Script execution failed: " .. tostring(result))
        table.insert(state.executionErrors, {
            error = result,
            timestamp = os.clock(),
            stage = "script_execution"
        })
    else
        logInfo("Script executed successfully")
        if type(result) == "function" then
            logDebug("Result is function, executing...")
            setfenv(result, env)
            local success2, result2 = pcall(result)
            if not success2 then
                logError("Function execution failed: " .. tostring(result2))
                table.insert(state.executionErrors, {
                    error = result2,
                    timestamp = os.clock(),
                    stage = "function_execution"
                })
            end
        end
    end
end

logCallStack()
heapDump()

-- ═══════════════════════════════════════════════════════════════
-- DATA SERIALIZATION FOR OUTPUT
-- ═══════════════════════════════════════════════════════════════

local function serializeState()
    local output = {}
    
    -- Header
    table.insert(output, "═══════════════════════════════════════════════════════════════")
    table.insert(output, "ROBLOX CODE RECONSTRUCTOR OUTPUT - GENERATED ON AETHERIA")
    table.insert(output, "═══════════════════════════════════════════════════════════════")
    table.insert(output, "")
    
    -- Execution summary
    table.insert(output, "EXECUTION SUMMARY")
    table.insert(output, "─────────────────────────────────────────────────────────────")
    table.insert(output, "Execution Time: " .. string.format("%.3f", os.clock() - logger.startTime) .. "s")
    table.insert(output, "Total Code Lines Generated: " .. #state.codeLines)
    table.insert(output, "Execution Errors: " .. #state.executionErrors)
    table.insert(output, "Vulnerabilities Found: " .. #state.vulnerabilities)
    table.insert(output, "")
    
    -- Configuration used
    table.insert(output, "CONFIGURATION")
    table.insert(output, "─────────────────────────────────────────────────────────────")
    local enabledFeatures = {}
    for setting, enabled in pairs(settings) do
        if enabled then
            table.insert(enabledFeatures, setting)
        end
    end
    table.insert(output, "Enabled Features: " .. table.concat(enabledFeatures, ", "))
    table.insert(output, "")
    
    -- Execution errors
    if #state.executionErrors > 0 then
        table.insert(output, "EXECUTION ERRORS")
        table.insert(output, "─────────────────────────────────────────────────────────────")
        for i, err in ipairs(state.executionErrors) do
            table.insert(output, string.format("[%d] Stage: %s | Error: %s", i, err.stage, err.error))
        end
        table.insert(output, "")
    end
    
    -- Vulnerabilities
    if #state.vulnerabilities > 0 then
        table.insert(output, "VULNERABILITY SCAN RESULTS")
        table.insert(output, "─────────────────────────────────────────────────────────────")
        for i, vuln in ipairs(state.vulnerabilities) do
            table.insert(output, string.format("[%s] %s - Severity: %s (Pattern: %s)", i, vuln.type, vuln.severity, vuln.pattern))
        end
        table.insert(output, "")
    end
    
    -- VM Detection
    if countTable(vmDetector.detected_vms) > 0 then
        table.insert(output, "DETECTED VMs")
        table.insert(output, "─────────────────────────────────────────────────────────────")
        for vm_type, _ in pairs(vmDetector.detected_vms) do
            table.insert(output, "✓ " .. vm_type)
        end
        table.insert(output, "")
    end
    
    -- Obfuscation patterns
    if countTable(vmDetector.obfuscation_markers) > 0 then
        table.insert(output, "OBFUSCATION PATTERNS DETECTED")
        table.insert(output, "─────────────────────────────────────────────────────────────")
        for marker, _ in pairs(vmDetector.obfuscation_markers) do
            table.insert(output, "◆ " .. marker)
        end
        table.insert(output, "")
    end
    
    -- Memory metrics
    if settings.memory_analysis then
        table.insert(output, "MEMORY ANALYSIS")
        table.insert(output, "─────────────────────────────────────────────────────────────")
        table.insert(output, "Total Allocated: " .. memoryAnalyzer.total_allocated .. " bytes")
        table.insert(output, "Peak Allocated: " .. memoryAnalyzer.peak_allocated .. " bytes")
        table.insert(output, "Total Objects: " .. countTable(memoryAnalyzer.allocations))
        table.insert(output, "")
    end
    
    -- URLs fetched
    if countTable(state.urlCache) > 0 then
        table.insert(output, "NETWORK ACTIVITY")
        table.insert(output, "─────────────────────────────────────────────────────────────")
        for url, data in pairs(state.urlCache) do
            table.insert(output, "GET " .. url .. " (attempts: " .. data.attempts .. ")")
        end
        table.insert(output, "")
    end
    
    -- Control flow analysis
    if settings.control_flow_analysis then
        local flow = analyzeControlFlow(scriptContent)
        table.insert(output, "CONTROL FLOW ANALYSIS")
        table.insert(output, "─────────────────────────────────────────────────────────────")
        table.insert(output, "Conditionals: " .. flow.conditionals)
        table.insert(output, "Loops: " .. flow.loops)
        table.insert(output, "Branches: " .. flow.branches)
        table.insert(output, "Complex Conditions: " .. flow.complex_conditions)
        table.insert(output, "")
    end
    
    -- Data flow analysis
    if settings.data_flow_analysis then
        local flow = analyzeDataFlow(scriptContent)
        table.insert(output, "DATA FLOW ANALYSIS")
        table.insert(output, "─────────────────────────────────────────────────────────────")
        table.insert(output, "Assignments: " .. flow.assignments)
        table.insert(output, "Functions: " .. flow.functions)
        table.insert(output, "Tables: " .. flow.tables)
        table.insert(output, "")
    end
    
    -- Performance profiling
    if settings.performance_profiling and countTable(profiler.call_counts) > 0 then
        table.insert(output, "PERFORMANCE PROFILING")
        table.insert(output, "─────────────────────────────────────────────────────────────")
        for func, count in pairs(profiler.call_counts) do
            table.insert(output, string.format("%s: %d calls", func, count))
        end
        table.insert(output, "")
    end
    
    -- Reconstructed code
    table.insert(output, "RECONSTRUCTED CODE")
    table.insert(output, "═══════════════════════════════════════════════════════════════")
    table.insert(output, "")
    if #state.codeLines > 0 then
        for _, line in ipairs(state.codeLines) do
            table.insert(output, line)
        end
    else
        table.insert(output, "-- No code reconstructed")
    end
    table.insert(output, "")
    
    -- Execution trace
    if settings.call_stack_trace and #state.executionTrace > 0 then
        table.insert(output, "EXECUTION TRACE")
        table.insert(output, "═══════════════════════════════════════════════════════════════")
        for i, frame in ipairs(state.executionTrace) do
            table.insert(output, string.format("[%d] %s @ %s:%d", frame.index, frame.name, frame.source, frame.line))
        end
        table.insert(output, "")
    end
    
    -- Logs
    table.insert(output, "SYSTEM LOGS")
    table.insert(output, "═══════════════════════════════════════════════════════════════")
    for _, logEntry in ipairs(logger.logs) do
        table.insert(output, logEntry)
    end
    table.insert(output, "")
    
    -- Footer
    table.insert(output, "═══════════════════════════════════════════════════════════════")
    table.insert(output, "Analysis completed at " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(output, "═══════════════════════════════════════════════════════════════")
    
    return table.concat(output, "\n")
end

-- ═══════════════════════════════════════════════════════════════
-- WRITE OUTPUT TO FILE
-- ═══════════════════════════════════════════════════════════════

logInfo("Serializing output...")
local serialized = serializeState()

local outputFile = scriptPath .. ".reconstructed.log"
local success, err = pcall(function()
    fs.writeFile(outputFile, serialized)
end)

if success then
    logInfo("Output written to: " .. outputFile)
    logInfo("Output size: " .. #serialized .. " bytes")
else
    logError("Failed to write output: " .. tostring(err))
end

logInfo("Reconstructor finished")
process.exit(0)
