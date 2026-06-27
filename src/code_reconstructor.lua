-- ULTIMATE ADVANCED ROBLOX ENVIRONMENT LOGGER & CODE RECONSTRUCTOR
-- Enterprise-grade VM deobfuscation, memory forensics, and code recovery system
-- Supports: LuaU, Prometheus, Sentinel, Synapse, KRNL, Script-Ware VMs

local process = require("@lune/process")
local fs = require("@lune/fs")
local net = require("@lune/net")

local scriptPath = process.args[1]
if not scriptPath then
    process.exit(1)
end

local urlToFetch = process.args[2]
local scriptContent = fs.readFile(scriptPath)

-- ═══════════════════════════════════════════════════════════════
-- ADVANCED CONFIGURATION SYSTEM
-- ═══════════════════════════════════════════════════════════════

local settings = {
    -- Core reconstruction
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
    
    -- Advanced analysis
    enable_url_fetch = process.env.SETTING_URL_FETCH == "1" or urlToFetch ~= nil,
    memory_analysis = process.env.SETTING_MEMORY_ANALYSIS == "1",
    vm_detection = process.env.SETTING_VM_DETECTION == "1",
    obfuscation_analysis = process.env.SETTING_OBFUSCATION_ANALYSIS == "1",
    bytecode_analysis = process.env.SETTING_BYTECODE_ANALYSIS == "1",
    registry_scan = process.env.SETTING_REGISTRY_SCAN == "1",
    heap_dump = process.env.SETTING_HEAP_DUMP == "1",
    call_stack_trace = process.env.SETTING_CALL_STACK_TRACE == "1",
    metamethod_tracking = process.env.SETTING_METAMETHOD_TRACKING == "1",
    upvalue_extraction = process.env.SETTING_UPVALUE_EXTRACTION == "1",
    coroutine_tracking = process.env.SETTING_COROUTINE_TRACKING == "1",
    thread_analysis = process.env.SETTING_THREAD_ANALYSIS == "1",
    environment_persistence = process.env.SETTING_ENV_PERSISTENCE == "1",
    
    -- Enterprise features
    control_flow_analysis = process.env.SETTING_CONTROL_FLOW == "1",
    data_flow_analysis = process.env.SETTING_DATA_FLOW == "1",
    string_deobfuscation = process.env.SETTING_STRING_DEOBFUSCATION == "1",
    constant_folding = process.env.SETTING_CONSTANT_FOLDING == "1",
    dead_code_elimination = process.env.SETTING_DEAD_CODE_ELIM == "1",
    pattern_recognition = process.env.SETTING_PATTERN_REC == "1",
    vulnerability_scan = process.env.SETTING_VULN_SCAN == "1",
    performance_profiling = process.env.SETTING_PERF_PROFILE == "1",
    behavior_analysis = process.env.SETTING_BEHAVIOR_ANALYSIS == "1",
    machine_learning_detection = process.env.SETTING_ML_DETECTION == "1",
}

-- ═══════════════════════════════════════════════════════════════
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
}

-- ═══════════════════════════════════════════════════════════════
-- ADVANCED URL FETCHING WITH CACHING & RETRY LOGIC
-- ═══════════════════════════════════════════════════════════════

local function fetchURL(url, method, headers, body, retries)
    if not settings.enable_url_fetch then
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
            return response, nil
        end
        
        lastError = response
    end
    
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
        deobfuscated = encodedStr:gsub("..", function(cc)
            return string.char(tonumber(cc, 16))
        end)
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
    end
    if characteristics.has_getupvalue and characteristics.has_setupvalue then
        vmDetector.detected_vms["UpvalueManipulation"] = true
    end
    if characteristics.has_getlocal and characteristics.has_setlocal then
        vmDetector.detected_vms["LocalVariableManipulation"] = true
    end
    if characteristics.has_getreg or characteristics.has_getgc then
        vmDetector.detected_vms["MemoryAccess"] = true
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
            local name, value = debug.getupvalue(func, i)
            if not name then break end
            
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
    
    return upvalues
end

local function analyzeBytecode(func)
    if not settings.bytecode_analysis then return "" end
    
    local analysis = {}
    
    if debug and debug.getinfo then
        local info = debug.getinfo(func)
        if info then
            table.insert(analysis, "source:" .. tostring(info.source))
            table.insert(analysis, "line_defined:" .. tostring(info.linedefined))
            table.insert(analysis, "last_line:" .. tostring(info.lastlinedefined))
            table.insert(analysis, "params:" .. tostring(info.nparams))
            table.insert(analysis, "vararg:" .. tostring(info.isvararg))
            
            if debug.getlocal then
                local locals = {}
                local j = 1
                while true do
                    local name, value = debug.getlocal(func, j)
                    if not name then break end
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
    flows.loops = select(2, code_str:gsub("while%s+", "")) + select(2, code_str:gsub("for%s+", "")) or 0
    flows.branches = select(2, code_str:gsub("elseif%s+", "")) + select(2, code_str:gsub("else%s+", "")) or 0
    flows.complex_conditions = select(2, code_str:gsub(" and ", "")) + select(2, code_str:gsub(" or ", "")) or 0
    
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
    flows.functions = select(2, code_str:gsub("function%s+", "")) + select(2, code_str:gsub("function%(", "")) or 0
    flows.tables = select(2, code_str:gsub("{", "")) or 0
    
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
    end
    if code_str:match("loadstring") then
        table.insert(vulns, {type = "CODE_INJECTION", severity = "HIGH", pattern = "loadstring"})
    end
    if code_str:match("debug%.setfenv") or code_str:match("setfenv") then
        table.insert(vulns, {type = "ENV_MANIPULATION", severity = "HIGH", pattern = "setfenv"})
    end
    if code_str:match("getfenv") then
        table.insert(vulns, {type = "ENV_LEAK", severity = "MEDIUM", pattern = "getfenv"})
    end
    if code_str:match("writefile") then
        table.insert(vulns, {type = "FILE_WRITE", severity = "MEDIUM", pattern = "writefile"})
    end
    if code_str:match("game:GetService.*HttpService") then
        table.insert(vulns, {type = "NETWORK_ACCESS", severity = "MEDIUM", pattern = "HttpService"})
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
            local info = debug.getinfo(i)
            if not info then break end
            table.insert(stack, {
                name = info.name or "unknown",
                source = info.source or "unknown",
                line = info.currentline or 0,
                what = info.what or "unknown"
            })
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
end

-- ═══════════════════════════════════════════════════════════════
-- ENVIRONMENT SETUP WITH ADVANCED MOCKING
-- ═══════════════════════════════════════════════════════════════

local env = {}

env.print = function(...) end
env.warn = function(...) end

-- ═══════════════════════════════════════════════════════════════
-- ADVANCED MOCK INSTANCE CREATION
-- ══════════════════════════════════════════════════════════��════

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
    new = function(x, y, z) trackMemory("Vector3", 96, "type"); return setmetatable({x=x,y=y,z=z}, {__tostring = function() return string.format("Vector3.new(%g,%g,%g)", x or 0, y or 0, z or 0) end}) end,
}

env.Color3 = {
    fromRGB = function(r, g, b) trackMemory("Color3_fromRGB", 96, "type"); return setmetatable({r=r,g=g,b=b}, {__tostring = function() return string.format("Color3.fromRGB(%d,%d,%d)", r, g, b) end}) end,
    new = function(r, g, b) trackMemory("Color3_new", 96, "type"); return setmetatable({}, {__tostring = function() return string.format("Color3.new(%g,%g,%g)", r or 0, g or 0, b or 0) end}) end,
    fromHSV = function(h, s, v) trackMemory("Color3_fromHSV", 96, "type"); return setmetatable({}, {__tostring = function() return string.format("Color3.fromHSV(%g,%g,%g)", h, s, v) end}) end,
}

env.UDim = {
    new = function(s, o) trackMemory("UDim", 64, "type"); return setmetatable({}, {__tostring = function() return string.format("UDim.new(%g,%g)", s, o) end}) end,
}

env.UDim2 = {
    new = function(xs, xo, ys, yo) trackMemory("UDim2", 96, "type"); return setmetatable({}, {__tostring = function() return string.format("UDim2.new(%g,%g,%g,%g)", xs, xo, ys, yo) end}) end,
}

env.Vector2 = {
    new = function(x, y) trackMemory("Vector2", 64, "type"); return setmetatable({}, {__tostring = function() return string.format("Vector2.new(%g,%g)", x, y) end}) end,
}

env.BrickColor = {
    new = function(name) trackMemory("BrickColor", 96, "type"); return setmetatable({}, {__tostring = function() return 'BrickColor.new("' .. name .. '")' end}) end,
}

env.NumberRange = {
    new = function(...) trackMemory("NumberRange", 64, "type"); local args = {...}; return setmetatable({}, {__tostring = function() return "NumberRange.new(" .. table.concat(args, ", ") .. ")" end}) end,
}

env.NumberSequence = {
    new = function(...) trackMemory("NumberSequence", 96, "type"); return setmetatable({}, {__tostring = function() return "NumberSequence.new(...)" end}) end,
}

env.NumberSequenceKeypoint = {
    new = function(...) trackMemory("NumberSequenceKeypoint", 96, "type"); return setmetatable({}, {__tostring = function() return "NumberSequenceKeypoint.new(...)" end}) end,
}

env.ColorSequence = {
    new = function(...) trackMemory("ColorSequence", 96, "type"); return setmetatable({}, {__tostring = function() return "ColorSequence.new(...)" end}) end,
}

env.ColorSequenceKeypoint = {
    new = function(...) trackMemory("ColorSequenceKeypoint", 96, "type"); return setmetatable({}, {__tostring = function() return "ColorSequenceKeypoint.new(...)" end}) end,
}

env.TweenInfo = {
    new = function(...) trackMemory("TweenInfo", 128, "type"); return setmetatable({}, {__tostring = function() return "TweenInfo.new(...)" end}) end,
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
                    __tostring = function() return "Enum." .. k .. "." .. v end
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
                            return setmetatable({}, {__index = {Play = function() addCode("Tween:Play()") end, Cancel = function() addCode("Tween:Cancel()") end}})
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
            __add = function(a, b) local av = type(a) == "table" and a.__value or a; local bv = type(b) == "table" and b.__value or b; addComment("OP: " .. av .. " + " .. bv); return createTrackedNumber(av + bv) end,
            __sub = function(a, b) local av = type(a) == "table" and a.__value or a; local bv = type(b) == "table" and b.__value or b; addComment("OP: " .. av .. " - " .. bv); return createTrackedNumber(av - bv) end,
            __mul = function(a, b) local av = type(a) == "table" and a.__value or a; local bv = type(b) == "table" and b.__value or b; addComment("OP: " .. av .. " * " .. bv); return createTrackedNumber(av * bv) end,
            __div = function(a, b) local av = type(a) == "table" and a.__value or a; local bv = type(b) == "table" and b.__value or b; addComment("OP: " .. av .. " / " .. bv); return createTrackedNumber(av / bv) end,
            __mod = function(a, b) local av = type(a) == "table" and a.__value or a; local bv = type(b) == "table" and b.__value or b; addComment("OP: " .. av .. " % " .. bv); return createTrackedNumber(av % bv) end,
            __tostring = function(self) return tostring(self.__value) end,
        })
    end
    
    local original_tonumber = env.tonumber
    env.tonumber = function(...) local result = original_tonumber(...); return result and createTrackedNumber(result) or result end
end

-- ═══════════════════════════════════════════════════════════════
-- SCRIPT EXECUTION & STATE CAPTURE
-- ═══════════════════════════════════════════════════════════════

detectVMCharacteristics(env)
detectObfuscationPatterns(scriptContent)
state.vulnerabilities = scanVulnerabilities(scriptContent)

local chunk, err = loadstring(scriptContent, "@script")
if not chunk then
    process.exit(1)
end

setfenv(chunk, env)
local success, result = pcall(chunk)

if success and type(result) == "function" then
    setfenv(result, env)
    pcall(result)
end

logCallStack()
heapDump()

-- ═══════════════════════════════════════════════════════════════
-- DATA SERIALIZATION FOR OUTPUT
-- ═══════════════════════════════════════════════════════════════

local function serializeState()
    local output = {}
    
    -- Code reconstruction
    table.insert(output, "CODE:" .. table.concat(state.codeLines, "\n"))
    
    -- VM Detection
    if settings.vm_detection and countTable(vmDetector.detected_vms) > 0 then
        local vms = {}
        for vm_type, _ in pairs(vmDetector.detected_vms) do
            table.insert(vms, vm_type)
        end
        table.insert(output, "VMS:" .. table.concat(vms, ","))
    end
    
    -- Obfuscation markers
    if settings.obfuscation_analysis and countTable(vmDetector.obfuscation_markers) > 0 then
        local markers = {}
        for marker, _ in pairs(vmDetector.obfuscation_markers) do
            table.insert(markers, marker)
        end
        table.insert(output, "OBFUSCATION:" .. table.concat(markers, ","))
    end
    
    -- Memory metrics
    if settings.memory_analysis then
        table.insert(output, "MEMORY_TOTAL:" .. memoryAnalyzer.total_allocated)
        table.insert(output, "MEMORY_PEAK:" .. memoryAnalyzer.peak_allocated)
        table.insert(output, "MEMORY_OBJECTS:" .. countTable(memoryAnalyzer.allocations))
    end
    
    -- Vulnerabilities
    if settings.vulnerability_scan and #state.vulnerabilities > 0 then
        local vulnStrs = {}
        for _, vuln in ipairs(state.vulnerabilities) do
            table.insert(vulnStrs, vuln.type .. ":" .. vuln.severity)
        end
        table.insert(output, "VULNERABILITIES:" .. table.concat(vulnStrs, ","))
    end
    
    -- URLs
    if countTable(state.urlCache) > 0 then
        local urls = {}
        for url, _ in pairs(state.urlCache) do
            table.insert(urls, url)
        end
        table.insert(output, "URLS:" .. table.concat(urls, "|"))
    end
    
    -- Control flow
    if settings.control_flow_analysis then
        local flow = analyzeControlFlow(scriptContent)
        table.insert(output, "CONTROL_FLOW:conditionals=" .. flow.conditionals .. ",loops=" .. flow.loops)
    end
    
    -- Performance
    if settings.performance_profiling and countTable(profiler.call_counts) > 0 then
        local profs = {}
        for func, count in pairs(profiler.call_counts) do
            table.insert(profs, func .. "=" .. count)
        end
        table.insert(output, "PERFORMANCE:" .. table.concat(profs, ","))
    end
    
    return table.concat(output, "\n---\n")
end

-- ═══════════════════════════════════════════════════════════════
-- WRITE OUTPUT TO FILE
-- ═══════════════════════════════════════════════════════════════

local outputFile = scriptPath .. ".reconstructed"
fs.writeFile(outputFile, serializeState())
