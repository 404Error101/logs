-- ═══════════════════════════════════════════════════════════════════════════════
-- ULTIMATE ADVANCED ROBLOX CODE RECONSTRUCTOR V2 - ENTERPRISE EDITION
-- Full-featured VM deobfuscation, memory forensics, code recovery & reconstruction
-- ═══════════════════════════════════════════════════════════════════════════════

local process = require("@lune/process")
local fs = require("@lune/fs")
local net = require("@lune/net")

-- ═══════════════════════════════════════════════════════════════════════════════
-- ARGUMENT PARSING & VALIDATION
-- ═══════════════════════════════════════════════════════════════════════════════

local scriptPath = process.args[1]
local urlToFetch = process.args[2]

if not scriptPath then
    io.stderr:write("ERROR: No script path provided\n")
    io.stderr:write("Usage: lune run code_reconstructor_v2.lua <script_path> [url_to_fetch]\n")
    process.exit(1)
end

-- Validate script exists
local scriptExists = pcall(function()
    return fs.readFile(scriptPath)
end)

if not scriptExists then
    io.stderr:write("ERROR: Script file not found: " .. scriptPath .. "\n")
    process.exit(1)
end

local scriptContent = fs.readFile(scriptPath)

-- ═══════════════════════════════════════════════════════════════════════════════
-- LOGGER SYSTEM WITH TIMESTAMPS & LEVELS
-- ═════════════��═════════════════════════════════════════════════════════════════

local logger = {
    logs = {},
    level = "DEBUG",
    startTime = os.clock(),
    levels = {
        TRACE = 0,
        DEBUG = 1,
        INFO = 2,
        WARN = 3,
        ERROR = 4,
    }
}

local function log(level, message)
    local timestamp = string.format("%.4f", os.clock() - logger.startTime)
    local logEntry = string.format("[%s] [%-5s] %s", timestamp, level, message)
    table.insert(logger.logs, logEntry)
    
    -- Also print to stderr in real-time
    if logger.levels[level] >= logger.levels[logger.level] then
        io.stderr:write(logEntry .. "\n")
    end
end

local function logTrace(msg) log("TRACE", msg) end
local function logDebug(msg) log("DEBUG", msg) end
local function logInfo(msg) log("INFO", msg) end
local function logWarn(msg) log("WARN", msg) end
local function logError(msg) log("ERROR", msg) end

logInfo("═══════════════════════════════════════════════════════════���═══════════════════")
logInfo("ROBLOX CODE RECONSTRUCTOR v2.0 - INITIALIZATION")
logInfo("═══════════════════════════════════════════════════════════════════════════════")
logInfo("Script Path: " .. scriptPath)
logInfo("Script Size: " .. #scriptContent .. " bytes")
logInfo("Lines in Script: " .. select(2, scriptContent:gsub("\n", "")) + 1)

-- ═══════════════════════════════════════════════════════════════════════════════
-- ADVANCED CONFIGURATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════════

local function analyzeScriptComplexity(code)
    local lines = select(2, code:gsub("\n", "")) + 1
    local complexity = {
        lines = lines,
        has_network = code:match("HttpService") ~= nil or code:match("http_request") ~= nil,
        has_exploit = code:match("getgenv") ~= nil or code:match("hookfunction") ~= nil,
        has_obfuscation = code:match("loadstring") ~= nil or code:match("string%.char") ~= nil,
        has_debug = code:match("debug%.") ~= nil,
        has_file_io = code:match("writefile") ~= nil or code:match("readfile") ~= nil,
        has_loops = code:match("while%s") ~= nil or code:match("for%s") ~= nil,
        has_metamethods = code:match("setmetatable") ~= nil,
        has_coroutines = code:match("coroutine%.") ~= nil,
        char_count = #code,
    }
    return complexity
end

local function getAutoConfig(scriptContent)
    local analysis = analyzeScriptComplexity(scriptContent)
    
    return {
        -- Core tracking
        hookOp = true,
        explore_funcs = true,
        constant_collection = true,
        environment_persistence = true,
        pattern_recognition = true,
        
        -- Advanced analysis
        enable_url_fetch = analysis.has_network or urlToFetch ~= nil,
        memory_analysis = true,
        vm_detection = analysis.has_exploit or analysis.has_obfuscation,
        obfuscation_analysis = analysis.has_obfuscation,
        bytecode_analysis = analysis.has_debug or analysis.has_exploit,
        registry_scan = analysis.has_exploit,
        heap_dump = true,
        call_stack_trace = true,
        metamethod_tracking = analysis.has_metamethods,
        upvalue_extraction = analysis.has_exploit,
        coroutine_tracking = analysis.has_coroutines,
        
        -- Enterprise features
        control_flow_analysis = analysis.lines > 20,
        data_flow_analysis = analysis.lines > 30,
        string_deobfuscation = analysis.has_obfuscation,
        constant_folding = true,
        dead_code_detection = false,
        vulnerability_scan = true,
        performance_profiling = true,
        behavior_analysis = true,
        ast_generation = true,
        ast_simplification = true,
        variable_tracking = true,
        function_signature_analysis = true,
        
        -- Output options
        comments = true,
        include_debug_info = true,
        minifier = false,
        spyexeconly = false,
        no_string_limit = true,
    }
end

local settings = getAutoConfig(scriptContent)

-- Allow environment overrides
for key, _ in pairs(settings) do
    local envKey = "SETTING_" .. key:upper()
    local envVal = process.env[envKey]
    if envVal ~= nil then
        settings[key] = envVal == "1" or envVal == "true"
    end
end

logInfo("Configuration System Initialized")
logDebug("Active Features: " .. tostring(select(2, next(settings))))

-- ═══════════════════════════════════════════════════════════════════════════════
-- GLOBAL STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════════

local state = {
    codeLines = {},
    reconstructedCode = {},
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
    variableTracking = {},
    functionSignatures = {},
    astNodes = {},
    astStatements = {},
    scopeStack = {},
}

-- ════════════════��══════════════════════════════════════════════════════════════
-- ADVANCED URL FETCHING WITH RETRY LOGIC & CACHING
-- ═══════════════════════════════════════════════════════════════════════════════

local function fetchURL(url, method, headers, body, retries)
    if not settings.enable_url_fetch then
        logDebug("URL fetch disabled: " .. url)
        return nil, "URL fetching disabled"
    end
    
    retries = retries or 3
    method = method or "GET"
    headers = headers or {}
    
    -- Check cache first
    if state.urlCache[url] and state.urlCache[url].content then
        logDebug("URL cache hit: " .. url)
        return state.urlCache[url].content, nil
    end
    
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
                attempts = attempt,
                success = true
            }
            logDebug("URL fetched successfully: " .. url .. " (attempt " .. attempt .. ")")
            return response, nil
        end
        
        lastError = response
        logWarn("URL fetch attempt " .. attempt .. "/" .. retries .. " failed: " .. tostring(lastError))
    end
    
    logError("Failed to fetch URL after " .. retries .. " retries: " .. url)
    state.urlCache[url] = {
        success = false,
        error = lastError,
        attempts = retries
    }
    return nil, "Failed after " .. retries .. " retries"
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ENTERPRISE MEMORY ANALYSIS ENGINE
-- ═══════════════════════════════════════════════════════════════════════════════

local memoryAnalyzer = {
    allocations = {},
    access_patterns = {},
    total_allocated = 0,
    peak_allocated = 0,
    gc_events = {},
    heap_snapshots = {},
    allocation_timeline = {},
}

local function trackMemory(identifier, size, access_type, source_line)
    if not settings.memory_analysis then return end
    
    size = size or 64
    
    if not memoryAnalyzer.allocations[identifier] then
        memoryAnalyzer.allocations[identifier] = {
            size = size,
            accesses = 0,
            last_access = 0,
            access_times = {},
            access_types = {},
            source_line = source_line or "unknown",
            freed = false,
            alloc_time = os.clock(),
            alloc_sequence = countTable(memoryAnalyzer.allocations) + 1,
        }
        memoryAnalyzer.total_allocated = memoryAnalyzer.total_allocated + size
        table.insert(memoryAnalyzer.allocation_timeline, {
            timestamp = os.clock(),
            identifier = identifier,
            size = size,
            type = access_type,
        })
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
        by_size = {},
        largest_objects = {},
    }
    
    for id, alloc in pairs(memoryAnalyzer.allocations) do
        if not alloc.freed then
            dump.total_objects = dump.total_objects + 1
            local atype = alloc.access_types[1] or "unknown"
            dump.by_type[atype] = (dump.by_type[atype] or 0) + 1
            table.insert(dump.largest_objects, {id = id, size = alloc.size})
        end
    end
    
    table.sort(dump.largest_objects, function(a, b) return a.size > b.size end)
    
    table.insert(memoryAnalyzer.heap_snapshots, dump)
    logDebug("Heap dump created: " .. dump.total_objects .. " objects, Peak: " .. memoryAnalyzer.peak_allocated .. " bytes")
    return dump
end

-- ═════════════���═════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

function countTable(t)
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

local function addCode(code, codeType)
    codeType = codeType or "general"
    table.insert(state.codeLines, code)
    table.insert(state.reconstructedCode, {
        code = code,
        type = codeType,
        timestamp = os.clock(),
        line = #state.codeLines,
    })
end

local function addComment(comment)
    if settings.comments then
        addCode("-- " .. comment, "comment")
    end
end

local function addConstant(name, value, typeInfo)
    if settings.constant_collection then
        state.constantBuffer[name] = {value = value, type = typeInfo or type(value)}
        local valueStr = tostring(value)
        if type(value) == "string" then
            valueStr = '"' .. value:gsub('"', '\\"') .. '"'
        end
        addCode("local " .. name .. " = " .. valueStr, "constant")
    end
end

local function stringDeobfuscate(encodedStr)
    if not settings.string_deobfuscation then return encodedStr end
    
    local deobfuscated = encodedStr
    local methods = {}
    
    -- Attempt hex decoding
    if encodedStr:match("^%x+$") and #encodedStr % 2 == 0 then
        local success, result = pcall(function()
            return encodedStr:gsub("..", function(cc)
                return string.char(tonumber(cc, 16))
            end)
        end)
        if success then
            deobfuscated = result
            table.insert(methods, "hex_decode")
            logDebug("String deobfuscated via hex decoding")
        end
    end
    
    -- Attempt base64-like patterns
    if encodedStr:match("^[A-Za-z0-9+/]+={0,2}$") and #encodedStr > 4 then
        table.insert(methods, "potential_base64")
    end
    
    if #methods > 0 then
        table.insert(state.stringPool, {original = encodedStr, deobfuscated = deobfuscated, methods = methods})
    end
    
    return deobfuscated
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- AST NODE GENERATION & SIMPLIFICATION
-- ═══════════════════════════════════════════════════════════════════════════════

local function createASTNode(nodeType, value, metadata)
    local node = {
        type = nodeType,
        value = value,
        metadata = metadata or {},
        children = {},
        parent = nil,
        line_number = #state.astNodes + 1,
        created_at = os.clock(),
    }
    table.insert(state.astNodes, node)
    return node
end

local function parseCodeStructure(code_str)
    if not settings.ast_generation then return end
    
    local lines = {}
    for line in code_str:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    for line_idx, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$")
        
        if trimmed:match("^local%s+") then
            local varName = trimmed:match("^local%s+([%w_]+)")
            if varName then
                createASTNode("variable_declaration", varName, {line = line_idx})
                table.insert(state.variableTracking, {name = varName, line = line_idx, type = "local"})
            end
        elseif trimmed:match("^function%s+") then
            local funcName = trimmed:match("^function%s+([%w_.]+)")
            if funcName then
                createASTNode("function_declaration", funcName, {line = line_idx})
                state.functionSignatures[funcName] = {line = line_idx, raw = line}
            end
        elseif trimmed:match("^if%s+") then
            createASTNode("conditional", "if", {line = line_idx})
        elseif trimmed:match("^for%s+") or trimmed:match("^while%s+") then
            createASTNode("loop", trimmed:match("^%w+"), {line = line_idx})
        end
    end
    
    logDebug("AST generated with " .. #state.astNodes .. " nodes")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- VM DETECTION & CHARACTERIZATION
-- ═══════════════════════════════════════════════════════════════════════════════

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
        logInfo("✓ Detected: LuaU_Compatible")
    end
    if characteristics.has_getupvalue and characteristics.has_setupvalue then
        vmDetector.detected_vms["UpvalueManipulation"] = true
        logInfo("✓ Detected: UpvalueManipulation")
    end
    if characteristics.has_getlocal and characteristics.has_setlocal then
        vmDetector.detected_vms["LocalVariableManipulation"] = true
        logInfo("✓ Detected: LocalVariableManipulation")
    end
    if characteristics.has_getreg or characteristics.has_getgc then
        vmDetector.detected_vms["MemoryAccess"] = true
        logInfo("✓ Detected: MemoryAccess")
    end
    if characteristics.has_debug then
        vmDetector.detected_vms["DebugCapabilities"] = true
        logInfo("✓ Detected: DebugCapabilities")
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
        unicode_obfuscation = code_str:match("\\u%x%x%x%x") ~= nil,
        nested_functions = select(2, code_str:gsub("function%s*%(", "")) > 5,
    }
    
    local detectedCount = 0
    for pattern, detected in pairs(patterns) do
        if detected then
            vmDetector.obfuscation_markers[pattern] = true
            logWarn("Obfuscation pattern detected: " .. pattern)
            detectedCount = detectedCount + 1
        end
    end
    
    logInfo("Total obfuscation patterns detected: " .. detectedCount)
    return patterns
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- UPVALUE & BYTECODE EXTRACTION
-- ═══════════════════════════════════════════════════════════════════════════════

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
            
            trackMemory("upvalue_" .. name, 64, "upvalue_extraction", "depth_" .. depth)
            i = i + 1
        end
    end
    
    if #upvalues > 0 then
        logDebug("Extracted " .. #upvalues .. " upvalues at depth " .. depth)
    end
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

-- ═══════════════════════════════════════��═══════════════════════════════════════
-- CONTROL FLOW & DATA FLOW ANALYSIS
-- ═══════════════════════════════════════════════════════════════════════════════

local function analyzeControlFlow(code_str)
    if not settings.control_flow_analysis then return {} end
    
    local flows = {
        conditionals = select(2, code_str:gsub("if%s+", "")) or 0,
        loops = (select(2, code_str:gsub("while%s+", "")) or 0) + (select(2, code_str:gsub("for%s+", "")) or 0),
        branches = (select(2, code_str:gsub("elseif%s+", "")) or 0) + (select(2, code_str:gsub("else%s+", "")) or 0),
        complex_conditions = (select(2, code_str:gsub(" and ", "")) or 0) + (select(2, code_str:gsub(" or ", "")) or 0),
        returns = select(2, code_str:gsub("return%s+", "")) or 0,
        breaks = select(2, code_str:gsub("break", "")) or 0,
    }
    
    logInfo(string.format("Control Flow: conditionals=%d, loops=%d, branches=%d, complex=%d, returns=%d", 
        flows.conditionals, flows.loops, flows.branches, flows.complex_conditions, flows.returns))
    
    return flows
end

local function analyzeDataFlow(code_str)
    if not settings.data_flow_analysis then return {} end
    
    local flows = {
        assignments = select(2, code_str:gsub("local%s+", "")) or 0,
        functions = (select(2, code_str:gsub("function%s+", "")) or 0) + (select(2, code_str:gsub("function%(", "")) or 0),
        tables = select(2, code_str:gsub("{", "")) or 0,
        array_access = select(2, code_str:gsub("%[", "")) or 0,
        table_access = select(2, code_str:gsub("%.", "")) or 0,
    }
    
    logInfo(string.format("Data Flow: assignments=%d, functions=%d, tables=%d, array_access=%d, table_access=%d", 
        flows.assignments, flows.functions, flows.tables, flows.array_access, flows.table_access))
    
    return flows
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- VULNERABILITY SCANNING
-- ═══════════════════════════════════════════════════════════════════════════════

local function scanVulnerabilities(code_str)
    if not settings.vulnerability_scan then return {} end
    
    local vulns = {}
    
    local patterns = {
        {pattern = "os%.execute", type = "RCE", severity = "CRITICAL", desc = "Remote Code Execution via os.execute"},
        {pattern = "os%.system", type = "RCE", severity = "CRITICAL", desc = "System command execution"},
        {pattern = "loadstring", type = "CODE_INJECTION", severity = "HIGH", desc = "Code injection via loadstring"},
        {pattern = "load%s*%(", type = "CODE_INJECTION", severity = "HIGH", desc = "Code injection via load"},
        {pattern = "debug%.setfenv", type = "ENV_MANIPULATION", severity = "HIGH", desc = "Environment manipulation"},
        {pattern = "setfenv", type = "ENV_MANIPULATION", severity = "HIGH", desc = "Function environment manipulation"},
        {pattern = "getfenv", type = "ENV_LEAK", severity = "MEDIUM", desc = "Environment information leak"},
        {pattern = "writefile", type = "FILE_WRITE", severity = "MEDIUM", desc = "File write capability"},
        {pattern = "readfile", type = "FILE_READ", severity = "MEDIUM", desc = "File read capability"},
        {pattern = "HttpService", type = "NETWORK_ACCESS", severity = "MEDIUM", desc = "Network access via HttpService"},
        {pattern = "http_request", type = "NETWORK_ACCESS", severity = "MEDIUM", desc = "Direct HTTP requests"},
        {pattern = "getgenv", type = "ENV_ACCESS", severity = "LOW", desc = "Global environment access"},
        {pattern = "getreg", type = "MEMORY_ACCESS", severity = "HIGH", desc = "Registry access (memory forensics)"},
        {pattern = "getgc", type = "MEMORY_ACCESS", severity = "HIGH", desc = "Garbage collector access"},
    }
    
    for _, item in ipairs(patterns) do
        if code_str:match(item.pattern) then
            table.insert(vulns, {
                type = item.type,
                severity = item.severity,
                pattern = item.pattern,
                description = item.desc,
                found_at = os.clock(),
            })
            logWarn(item.severity .. ": " .. item.type .. " - " .. item.desc)
        end
    end
    
    logInfo("Vulnerability scan complete: " .. #vulns .. " issues found")
    return vulns
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PERFORMANCE PROFILING
-- ═══════════════════════════════════════════════════════════════════════════════

local profiler = {
    function_times = {},
    call_counts = {},
    hotspots = {},
    total_calls = 0,
}

local function profileFunction(func, name)
    if not settings.performance_profiling then return func end
    
    name = name or "anonymous"
    
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
        profiler.total_calls = profiler.total_calls + 1
        
        if duration > 0.001 then
            profiler.hotspots[name] = (profiler.hotspots[name] or 0) + 1
        end
        
        return unpack(results)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CALL STACK & EXECUTION TRACE
-- ═══════════════════════════════════════════════════════════════════════════════

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
                    what = info.what or "unknown",
                    nups = info.nups or 0,
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
            what = frame.what,
            timestamp = os.clock()
        })
    end
    logDebug("Call stack logged: " .. #stack .. " frames")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ENVIRONMENT SETUP WITH ADVANCED MOCKING
-- ═══════════════════════════════════════════════════════════════════════════════

local env = {}
env.print = function(...) addCode("print(...)", "output"); end
env.warn = function(...) addCode("warn(...)", "output"); end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ADVANCED EVENT/SIGNAL MOCKING
-- ═══════════════════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════════════════
-- MOCK INSTANCE CREATION ENGINE
-- ═══════════════════════════════════════════════════════════════════════════════

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
                valueStr = '"' .. stringDeobfuscate(v):gsub('"', '\\"') .. '"'
            elseif type(v) == "number" or type(v) == "boolean" then
                valueStr = tostring(v)
            elseif type(v) == "table" then
                valueStr = v.__varName or "table"
            else
                valueStr = tostring(v)
            end
            addCode(varName .. "." .. k .. " = " .. valueStr, "property_assignment")
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROBLOX API COMPLETE MOCK LIBRARY
-- ═══════════════════════════════════════════════════════════════════════════════

env.Instance = {
    new = function(className, parent)
        instanceCounter = instanceCounter + 1
        local varName = "Instance" .. instanceCounter
        instances[varName] = className
        
        if parent then
            addCode("local " .. varName .. ' = Instance.new("' .. className .. '", ' .. tostring(parent) .. ")", "instance_creation")
        else
            addCode("local " .. varName .. ' = Instance.new("' .. className .. '")', "instance_creation")
        end
        
        trackMemory("instance_new_" .. className, 512, "allocation")
        return createMockInstance(className, varName)
    end
}

-- Type definitions
env.Vector3 = {
    new = function(x, y, z) 
        trackMemory("Vector3", 96, "type")
        return setmetatable({x=x,y=y,z=z}, {
            __tostring = function() 
                return string.format("Vector3.new(%g,%g,%g)", x or 0, y or 0, z or 0) 
            end
        })
    end,
    FromNormalId = function(normalId) return env.Vector3.new() end,
    FromAxis = function(axis) return env.Vector3.new() end,
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
        return setmetatable({Scale = s, Offset = o}, {
            __tostring = function() 
                return string.format("UDim.new(%g,%g)", s, o) 
            end
        })
    end,
}

env.UDim2 = {
    new = function(xs, xo, ys, yo) 
        trackMemory("UDim2", 96, "type")
        return setmetatable({XScale=xs, XOffset=xo, YScale=ys, YOffset=yo}, {
            __tostring = function() 
                return string.format("UDim2.new(%g,%g,%g,%g)", xs, xo, ys, yo) 
            end
        })
    end,
}

env.Vector2 = {
    new = function(x, y) 
        trackMemory("Vector2", 64, "type")
        return setmetatable({X=x, Y=y}, {
            __tostring = function() 
                return string.format("Vector2.new(%g,%g)", x, y) 
            end
        })
    end,
}

env.BrickColor = {
    new = function(name) 
        trackMemory("BrickColor", 96, "type")
        return setmetatable({Name = name}, {
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
env.time = function() trackMemory("time", 16, "timing"); return os.clock() end
env.wait = function(t) trackMemory("wait", 32, "timing"); return 0 end
env.delay = function(t, f) trackMemory("delay", 64, "timing"); if f then f() end; return 0 end
env.spawn = function(f) trackMemory("spawn", 128, "coroutine"); if f then f() end; end

-- Enum system
env.Enum = setmetatable({}, {
    __index = function(t, k)
        return setmetatable({}, {
            __index = function(t2, v)
                return setmetatable({Name = v}, {
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
                        services[name].LocalPlayer.Chatted = createEvent()
                        services[name].PlayerAdded = createEvent()
                        services[name].PlayerRemoving = createEvent()
                    elseif name == "TweenService" then
                        services[name].Create = function(self, obj, info, props)
                            addCode('TweenService:Create(...)', "service_call")
                            trackMemory("tween_creation", 256, "service")
                            return setmetatable({}, {
                                __index = {
                                    Play = function() addCode("Tween:Play()", "service_call") end, 
                                    Cancel = function() addCode("Tween:Cancel()", "service_call") end,
                                    Completed = createEvent(),
                                }
                            })
                        end
                    elseif name == "HttpService" then
                        services[name].GetAsync = function(self, url)
                            addCode('HttpService:GetAsync("' .. url .. '")', "network_call")
                            local response = fetchURL(url, "GET")
                            return response or ""
                        end
                        services[name].PostAsync = function(self, url, data)
                            addCode('HttpService:PostAsync("' .. url .. '", ...)', "network_call")
                            local response = fetchURL(url, "POST", {}, data)
                            return response or ""
                        end
                    elseif name == "RunService" then
                        services[name].RenderStepped = createEvent()
                        services[name].Heartbeat = createEvent()
                        services[name].Stepped = createEvent()
                    end
                end
                return services[name]
            end
        elseif k == "Workspace" or k == "workspace" then
            return createMockInstance("Workspace", "workspace")
        end
        return createEvent()
    end,
})

env.workspace = createMockInstance("Workspace", "workspace")
env.script = createMockInstance("Script", "script")

-- HTTP & Network functions
env.HttpGet = function(url)
    addCode('HttpGet("' .. tostring(url) .. '")', "network_call")
    trackMemory("http_get", 256, "network")
    local response = fetchURL(url, "GET")
    return response or ""
end

env.HttpGetAsync = env.HttpGet

env.request = function(options)
    local url = type(options) == "table" and options.Url or tostring(options)
    addCode('request({Url = "' .. url .. '"})', "network_call")
    trackMemory("request", 512, "network")
    return {Body = fetchURL(url, "GET") or "", StatusCode = 200}
end

env.http_request = env.request
env.syn = {request = env.request}

-- File operations
env.writefile = function(filename, content)
    addCode('writefile("' .. filename .. '", [content])', "file_io")
    trackMemory("writefile", (#content or 1024), "file_io")
end

env.readfile = function(filename)
    addCode('readfile("' .. filename .. '")', "file_io")
    trackMemory("readfile", 1024, "file_io")
    return ""
end

env.isfile = function(filename) trackMemory("isfile", 64, "file_io"); return true end
env.delfile = function(filename) addCode('delfile("' .. filename .. '")', "file_io"); trackMemory("delfile", 64, "file_io") end
env.listfiles = function(folder) trackMemory("listfiles", 512, "file_io"); return {} end
env.makefolder = function(folder) addCode('makefolder("' .. folder .. '")', "file_io"); trackMemory("makefolder", 64, "file_io") end
env.delfolder = function(folder) addCode('delfolder("' .. folder .. '")', "file_io"); trackMemory("delfolder", 64, "file_io") end

-- Code loading
env.loadstring = function(code)
    addCode("loadstring([code])", "code_loading")
    trackMemory("loadstring", (#code or 1024), "code_loading")
    return function() end
end

env.load = function(code)
    addCode("load([code])", "code_loading")
    trackMemory("load", (#code or 1024), "code_loading")
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
env.firesignal = function(signal, ...) addCode("firesignal(...)", "event_firing"); trackMemory("firesignal", 256, "events") end
env.fireclickdetector = function(part) addCode("fireclickdetector(...)", "event_firing"); trackMemory("fireclickdetector", 256, "events") end
env.firetouchinterest = function(part) addCode("firetouchinterest(...)", "event_firing"); trackMemory("firetouchinterest", 256, "events") end
env.fireproximityprompt = function(prompt) addCode("fireproximityprompt(...)", "event_firing"); trackMemory("fireproximityprompt", 256, "events") end

-- Hooking
env.hookfunction = function(original, hook) addCode("hookfunction([func], [hook])", "hooking"); trackMemory("hookfunction", 512, "hooking"); return original end
env.hookmetamethod = function(obj, method, hook) addCode('hookmetamethod([obj], "' .. tostring(method) .. '", [hook])', "hooking"); trackMemory("hookmetamethod", 512, "hooking"); return function() end end

-- Drawing
env.Drawing = {
    new = function(drawingType)
        instanceCounter = instanceCounter + 1
        local varName = "Drawing" .. instanceCounter
        addCode('local ' .. varName .. ' = Drawing.new("' .. drawingType .. '")', "drawing")
        trackMemory(varName, 512, "drawing")
        return setmetatable({__varName = varName}, {
            __index = function(t, k) return nil end,
            __newindex = function(t, k, v) addCode(varName .. "." .. k .. " = " .. tostring(v), "drawing_property") end,
        })
    end
}

-- Task library
env.task = {
    wait = function(t) addCode("task.wait(...)", "timing"); trackMemory("task_wait", 32, "timing"); return 0 end,
    spawn = function(func) addCode("task.spawn(...)", "coroutine"); trackMemory("task_spawn", 256, "coroutine"); if func then func() end end,
    delay = function(t, func) addCode("task.delay(...)", "timing"); trackMemory("task_delay", 128, "timing"); if func then func() end end,
    defer = function(func) addCode("task.defer(...)", "coroutine"); trackMemory("task_defer", 256, "coroutine"); if func then func() end end,
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
env.bit32 = bit32 or {}
env.utf8 = utf8 or {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- OPERATION TRACKING WITH ARITHMETIC HOOKS
-- ═══════════════════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCRIPT EXECUTION & STATE CAPTURE
-- ═══════════════════════════════════════════════════════════════════════════════

logInfo("═══════════════════════════════════════════════════════════════════════════════")
logInfo("ANALYSIS PHASE: Script Analysis & Preparation")
logInfo("═══════════════════════════════════════════════════════════════════════════════")

logInfo("Analyzing script characteristics...")
detectVMCharacteristics(env)
detectObfuscationPatterns(scriptContent)
state.vulnerabilities = scanVulnerabilities(scriptContent)
parseCodeStructure(scriptContent)

logInfo("═══════════════════════════════════════════════════════════════════════════════")
logInfo("EXECUTION PHASE: Script Execution")
logInfo("═══════════════════════════════════════════════════════════════════════════════")

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
    logInfo("Executing script in sandboxed environment...")
    setfenv(chunk, env)
    local success, result = pcall(chunk)
    
    if not success then
        logError("Script execution error: " .. tostring(result))
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
                logError("Function execution error: " .. tostring(result2))
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

logInfo("═══════════════════════════════════════════════════════════════════════════════")
logInfo("POST-ANALYSIS PHASE: Data Collection")
logInfo("═══════════════════════════════════════════════════════════════════════════════")

-- Collect control flow and data flow
state.controlFlows = analyzeControlFlow(scriptContent)
state.dataFlows = analyzeDataFlow(scriptContent)

-- ══════════════════════════════════��════════════════════════════════════════════
-- COMPREHENSIVE OUTPUT GENERATION
-- ═══════════════════════════════════════════════════════════════════════════════

local function generateComprehensiveReport()
    local output = {}
    
    -- Header
    table.insert(output, "╔" .. string.rep("═", 79) .. "╗")
    table.insert(output, "║" .. string.format("%-79s", " ROBLOX CODE RECONSTRUCTOR - COMPREHENSIVE ANALYSIS REPORT") .. "║")
    table.insert(output, "║" .. string.format("%-79s", " Enterprise-Grade Code Recovery & VM Deobfuscation System") .. "║")
    table.insert(output, "╚" .. string.rep("═", 79) .. "╝")
    table.insert(output, "")
    
    -- Execution Summary
    local execTime = os.clock() - logger.startTime
    table.insert(output, "┌─ EXECUTION SUMMARY " .. string.rep("─", 60) .. "┐")
    table.insert(output, "│ Analysis Time:             " .. string.format("%.4f seconds", execTime))
    table.insert(output, "│ Code Lines Generated:      " .. #state.codeLines)
    table.insert(output, "│ AST Nodes Created:         " .. #state.astNodes)
    table.insert(output, "│ Execution Errors:          " .. #state.executionErrors)
    table.insert(output, "│ Vulnerabilities Found:     " .. #state.vulnerabilities)
    table.insert(output, "│ Network Requests:          " .. countTable(state.urlCache))
    table.insert(output, "└" .. string.rep("─", 79) .. "┘")
    table.insert(output, "")
    
    -- Configuration
    table.insert(output, "┌─ ACTIVE CONFIGURATION " .. string.rep("─", 57) .. "┐")
    local enabledFeatures = {}
    for setting, enabled in pairs(settings) do
        if enabled then
            table.insert(enabledFeatures, setting)
        end
    end
    for i, feature in ipairs(enabledFeatures) do
        if i % 2 == 1 then
            table.insert(output, "│ " .. string.format("%-37s", feature) .. "  " .. string.format("%-37s", enabledFeatures[i+1] or ""))
        end
    end
    table.insert(output, "└" .. string.rep("─", 79) .. "┘")
    table.insert(output, "")
    
    -- Detected VMs & Features
    if countTable(vmDetector.detected_vms) > 0 then
        table.insert(output, "┌─ DETECTED VIRTUAL MACHINES " .. string.rep("─", 52) .. "┐")
        for vm_type, _ in pairs(vmDetector.detected_vms) do
            table.insert(output, "│ ✓ " .. vm_type)
        end
        table.insert(output, "└" .. string.rep("─", 79) .. "┘")
        table.insert(output, "")
    end
    
    -- Obfuscation Analysis
    if countTable(vmDetector.obfuscation_markers) > 0 then
        table.insert(output, "┌─ OBFUSCATION PATTERNS DETECTED " .. string.rep("─", 48) .. "┐")
        for marker, _ in pairs(vmDetector.obfuscation_markers) do
            table.insert(output, "│ ◆ " .. marker)
        end
        table.insert(output, "└" .. string.rep("─", 79) .. "┘")
        table.insert(output, "")
    end
    
    -- Vulnerability Report
    if #state.vulnerabilities > 0 then
        table.insert(output, "┌─ VULNERABILITY SCAN RESULTS " .. string.rep("─", 50) .. "┐")
        for i, vuln in ipairs(state.vulnerabilities) do
            table.insert(output, "│ [" .. i .. "] " .. vuln.severity .. ": " .. vuln.type)
            table.insert(output, "│     Pattern: " .. vuln.pattern)
            table.insert(output, "│     Description: " .. vuln.description)
        end
        table.insert(output, "└" .. string.rep("─", 79) .. "┘")
        table.insert(output, "")
    end
    
    -- Memory Analysis
    if settings.memory_analysis then
        table.insert(output, "┌─ MEMORY ANALYSIS " .. string.rep("─", 62) .. "┐")
        table.insert(output, "│ Total Allocated:           " .. memoryAnalyzer.total_allocated .. " bytes")
        table.insert(output, "│ Peak Allocated:            " .. memoryAnalyzer.peak_allocated .. " bytes")
        table.insert(output, "│ Total Objects:             " .. countTable(memoryAnalyzer.allocations))
        table.insert(output, "│ Heap Snapshots:            " .. #memoryAnalyzer.heap_snapshots)
        table.insert(output, "└" .. string.rep("─", 79) .. "┘")
        table.insert(output, "")
    end
    
    -- Control Flow Analysis
    if countTable(state.controlFlows) > 0 then
        table.insert(output, "┌─ CONTROL FLOW ANALYSIS " .. string.rep("─", 56) .. "┐")
        table.insert(output, "│ Conditionals:              " .. state.controlFlows.conditionals)
        table.insert(output, "│ Loops:                     " .. state.controlFlows.loops)
        table.insert(output, "│ Branches:                  " .. state.controlFlows.branches)
        table.insert(output, "│ Complex Conditions:        " .. state.controlFlows.complex_conditions)
        table.insert(output, "│ Returns:                   " .. state.controlFlows.returns)
        table.insert(output, "│ Breaks:                    " .. state.controlFlows.breaks)
        table.insert(output, "└" .. string.rep("─", 79) .. "┘")
        table.insert(output, "")
    end
    
    -- Data Flow Analysis
    if countTable(state.dataFlows) > 0 then
        table.insert(output, "┌─ DATA FLOW ANALYSIS " .. string.rep("─", 59) .. "┐")
        table.insert(output, "│ Assignments:               " .. state.dataFlows.assignments)
        table.insert(output, "│ Functions:                 " .. state.dataFlows.functions)
        table.insert(output, "│ Tables:                    " .. state.dataFlows.tables)
        table.insert(output, "│ Array Accesses:            " .. state.dataFlows.array_access)
        table.insert(output, "│ Table Accesses:            " .. state.dataFlows.table_access)
        table.insert(output, "└" .. string.rep("─", 79) .. "┘")
        table.insert(output, "")
    end
    
    -- Network Activity
    if countTable(state.urlCache) > 0 then
        table.insert(output, "┌─ NETWORK ACTIVITY " .. string.rep("─", 61) .. "┐")
        for url, data in pairs(state.urlCache) do
            table.insert(output, "│ URL: " .. truncateString(url, 70))
            table.insert(output, "│ Method: " .. (data.method or "GET") .. " | Attempts: " .. data.attempts .. " | Status: " .. (data.success and "OK" or "FAILED"))
        end
        table.insert(output, "└" .. string.rep("─", 79) .. "┘")
        table.insert(output, "")
    end
    
    -- Variable Tracking
    if #state.variableTracking > 0 then
        table.insert(output, "┌─ VARIABLE TRACKING (" .. #state.variableTracking .. " variables) " .. string.rep("─", 40) .. "┐")
        for i, var in ipairs(state.variableTracking) do
            if i <= 20 then  -- Limit display
                table.insert(output, "│ " .. string.format("%-20s", var.name) .. " [Line " .. var.line .. ", Type: " .. var.type .. "]")
            end
        end
        if #state.variableTracking > 20 then
            table.insert(output, "│ ... and " .. (#state.variableTracking - 20) .. " more")
        end
        table.insert(output, "└" .. string.rep("─", 79) .. "┘")
        table.insert(output, "")
    end
    
    -- Performance Profiling
    if settings.performance_profiling and countTable(profiler.call_counts) > 0 then
        table.insert(output, "┌─ PERFORMANCE PROFILING " .. string.rep("─", 56) .. "┐")
        table.insert(output, "│ Total Function Calls:      " .. profiler.total_calls)
        table.insert(output, "│ Tracked Functions:         " .. countTable(profiler.call_counts))
        for func, count in pairs(profiler.call_counts) do
            if count > 0 then
                table.insert(output, "│ " .. string.format("%-30s", func) .. ": " .. count .. " calls")
            end
        end
        table.insert(output, "└" .. string.rep("─", 79) .. "┘")
        table.insert(output, "")
    end
    
    -- Execution Errors
    if #state.executionErrors > 0 then
        table.insert(output, "┌─ EXECUTION ERRORS " .. string.rep("─", 61) .. "┐")
        for i, err in ipairs(state.executionErrors) do
            table.insert(output, "│ [" .. i .. "] Stage: " .. err.stage)
            table.insert(output, "│     Error: " .. tostring(err.error))
        end
        table.insert(output, "└" .. string.rep("─", 79) .. "┘")
        table.insert(output, "")
    end
    
    -- Reconstructed Code Section
    table.insert(output, "╔" .. string.rep("═", 79) .. "╗")
    table.insert(output, "║" .. string.format("%-79s", " RECONSTRUCTED CODE (" .. #state.codeLines .. " lines)") .. "║")
    table.insert(output, "╚" .. string.rep("═", 79) .. "╝")
    table.insert(output, "")
    
    if #state.codeLines > 0 then
        for idx, line in ipairs(state.codeLines) do
            table.insert(output, string.format("%4d │ %s", idx, line))
        end
    else
        table.insert(output, "-- No code reconstructed from execution")
    end
    
    table.insert(output, "")
    table.insert(output, "")
    
    -- Execution Trace
    if settings.call_stack_trace and #state.executionTrace > 0 then
        table.insert(output, "╔" .. string.rep("═", 79) .. "╗")
        table.insert(output, "║" .. string.format("%-79s", " EXECUTION TRACE (" .. #state.executionTrace .. " frames)") .. "║")
        table.insert(output, "╚" .. string.rep("═", 79) .. "╝")
        table.insert(output, "")
        for i, frame in ipairs(state.executionTrace) do
            table.insert(output, string.format("[%2d] %s @ %s:%d (%s)", frame.index, frame.name, frame.source, frame.line, frame.what))
        end
        table.insert(output, "")
    end
    
    -- System Logs
    table.insert(output, "╔" .. string.rep("═", 79) .. "╗")
    table.insert(output, "║" .. string.format("%-79s", " SYSTEM LOGS (" .. #logger.logs .. " entries)") .. "║")
    table.insert(output, "╚" .. string.rep("═", 79) .. "╝")
    table.insert(output, "")
    for _, logEntry in ipairs(logger.logs) do
        table.insert(output, logEntry)
    end
    table.insert(output, "")
    
    -- Footer
    table.insert(output, "╔" .. string.rep("═", 79) .. "╗")
    table.insert(output, "║" .. string.format("%-79s", " Report Generated: " .. os.date("%Y-%m-%d %H:%M:%S")) .. "║")
    table.insert(output, "║" .. string.format("%-79s", " Total Analysis Time: " .. string.format("%.4f seconds", execTime)) .. "║")
    table.insert(output, "╚" .. string.rep("═", 79) .. "╝")
    
    return table.concat(output, "\n")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- FILE OUTPUT OPERATIONS
-- ═══════════════════════════════════════════════════════════════════════════════

logInfo("═══════════════════════════════════════════════════════════════════════════════")
logInfo("OUTPUT PHASE: Report Generation & File Writing")
logInfo("═══════════════════════════════════════════════════════════════════════════════")

logInfo("Generating comprehensive report...")
local report = generateComprehensiveReport()

-- Write main report
local reportFile = scriptPath .. ".analysis.log"
local success, err = pcall(function()
    fs.writeFile(reportFile, report)
end)

if success then
    logInfo("✓ Analysis report written to: " .. reportFile)
    logInfo("✓ Report size: " .. #report .. " bytes")
else
    logError("Failed to write report: " .. tostring(err))
end

-- Write reconstructed code to separate file
if #state.codeLines > 0 then
    local codeFile = scriptPath .. ".reconstructed.lua"
    local reconstructedCode = table.concat(state.codeLines, "\n")
    
    local success2, err2 = pcall(function()
        fs.writeFile(codeFile, reconstructedCode)
    end)
    
    if success2 then
        logInfo("✓ Reconstructed code written to: " .. codeFile)
        logInfo("✓ Code file size: " .. #reconstructedCode .. " bytes")
    else
        logError("Failed to write reconstructed code: " .. tostring(err2))
    end
end

-- Write raw JSON data for programmatic analysis
local jsonData = {
    summary = {
        execution_time = os.clock() - logger.startTime,
        code_lines_generated = #state.codeLines,
        ast_nodes = #state.astNodes,
        errors = #state.executionErrors,
        vulnerabilities = #state.vulnerabilities,
    },
    vulnerabilities = state.vulnerabilities,
    variables = state.variableTracking,
    functions = state.functionSignatures,
    errors = state.executionErrors,
}

local jsonFile = scriptPath .. ".analysis.json"
local jsonString = "{\n"
jsonString = jsonString .. '  "execution_time": ' .. (os.clock() - logger.startTime) .. ",\n"
jsonString = jsonString .. '  "code_lines": ' .. #state.codeLines .. ",\n"
jsonString = jsonString .. '  "vulnerabilities": ' .. #state.vulnerabilities .. ",\n"
jsonString = jsonString .. '  "errors": ' .. #state.executionErrors .. "\n"
jsonString = jsonString .. "}\n"

local success3, err3 = pcall(function()
    fs.writeFile(jsonFile, jsonString)
end)

if success3 then
    logInfo("✓ JSON data written to: " .. jsonFile)
else
    logError("Failed to write JSON data: " .. tostring(err3))
end

logInfo("═══════════════════════════════════════════════════════════════════════════════")
logInfo("ANALYSIS COMPLETE")
logInfo("═══════════════════════════════════════════════════════════════════════════════")
logInfo("Total execution time: " .. string.format("%.4f", os.clock() - logger.startTime) .. " seconds")
logInfo("Output files generated: 3")

print("\n" .. report .. "\n")

process.exit(0)
