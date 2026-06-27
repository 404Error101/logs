-- ULTIMATE ADVANCED ROBLOX CODE RECONSTRUCTOR V2 - FIXED & IMPROVED
-- Robust, cross-Lua compatible variant with safer I/O, additional CLI flags,
-- improved error handling, and feature enhancements.

-- Notes:
-- - This file is defensive: it tolerates missing io.stderr, missing debug, and
--   differences between Lua 5.1 and 5.2+ load environments.
-- - New CLI flags: --url / -u, --dry-run, --log-level=LEVEL, --max-lines=N

-- Acquire platform modules (these will vary by runtime; fail gracefully)
local ok_process, process = pcall(require, "@lune/process")
local ok_fs, fs = pcall(require, "@lune/fs")
local ok_net, net = pcall(require, "@lune/net")
process = ok_process and process or { args = {}, env = {}, exit = os.exit }
fs = ok_fs and fs or {
    readFile = function(path) error("fs.readFile not available in this runtime") end,
    writeFile = function(path, content) error("fs.writeFile not available in this runtime") end
}
net = ok_net and net or nil

-- Fallbacks for process.args if not provided
process.args = process.args or {}
process.env = process.env or {}

-- CLI parsing helpers
local function parse_args(args)
    local parsed = { flags = {}, positional = {} }
    local i = 1
    while i <= #args do
        local a = args[i]
        if a == "--" then
            for j = i+1, #args do table.insert(parsed.positional, args[j]) end
            break
        elseif a:match("^%-%-url=") then
            parsed.flags.url = a:match("^%-%-url=(.*)")
        elseif a == "--url" or a == "-u" then
            parsed.flags.url = args[i+1]; i = i + 1
        elseif a == "--dry-run" then
            parsed.flags.dry_run = true
        elseif a:match("^%-%-log%-level=") then
            parsed.flags.log_level = a:match("^%-%-log%-level=(.*)")
        elseif a:match("^%-%-max%-lines=") then
            parsed.flags.max_lines = tonumber(a:match("^%-%-max%-lines=(%d+)"))
        elseif a:match("^%-") then
            -- ignore unknown short flags for now
        else
            table.insert(parsed.positional, a)
        end
        i = i + 1
    end
    return parsed
end

local cli = parse_args(process.args)

-- Input: first positional is scriptPath, second may be url
local scriptPath = cli.positional[1] or process.args[1]
local urlToFetch = cli.flags.url or cli.positional[2] or process.args[2]

if not scriptPath then
    io.write("ERROR: No script path provided\n")
    io.write("Usage: lune run code_reconstructor_v2.lua <script_path> [--url <url>] [--dry-run] [--log-level=LEVEL]\n")
    (process.exit or os.exit)(1)
end

-- Utility functions (early)
local function countTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local function safe_tostring(v)
    if type(v) == "string" then return v end
    if type(v) == "table" then
        if v.__varName then return tostring(v.__varName) end
        return "<table>"
    end
    return tostring(v)
end

local function truncateString(str, maxLen)
    if not maxLen then return str end
    if #str <= maxLen then return str end
    local remaining = #str - maxLen
    return str:sub(1, maxLen) .. "...(" .. remaining .. " bytes)"
end

-- Robust stderr wrapper (some environments have io.stderr == nil)
local stderr = {}
if io and io.stderr and type(io.stderr.write) == "function" then
    stderr.write = function(...) return io.stderr:write(...) end
else
    -- fallback to stdout
    stderr.write = function(...)
        return io.write(...)
    end
end

-- Simple safe logger with levels
local logger = {
    logs = {},
    level = "DEBUG",
    startTime = os.clock(),
    levels = { TRACE = 0, DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 },
}

-- Allow override of log level via CLI or env
if cli.flags.log_level then logger.level = cli.flags.log_level:upper() end
if process.env and process.env.SETTING_LOG_LEVEL then logger.level = process.env.SETTING_LOG_LEVEL:upper() end
if not logger.level or not logger.levels[logger.level] then logger.level = "DEBUG" end

local function log(level, message)
    level = level:upper()
    local ts = string.format("%.4f", os.clock() - logger.startTime)
    local entry = string.format("[%s] [%-5s] %s", ts, level, message)
    table.insert(logger.logs, entry)
    local msgLevel = logger.levels[level] or 0
    local configured = logger.levels[logger.level] or 0
    if msgLevel >= configured then
        stderr.write(entry .. "\n")
    end
end

local function logTrace(m) log("TRACE", m) end
local function logDebug(m) log("DEBUG", m) end
local function logInfo(m) log("INFO", m) end
local function logWarn(m) log("WARN", m) end
local function logError(m) log("ERROR", m) end

logInfo("================================ ROBLOX CODE RECONSTRUCTOR v2.0 =================================")
logInfo("Initialization complete")
logInfo("Script Path: " .. tostring(scriptPath))

-- Validate script exists and read it
local scriptContent
local ok, readErr = pcall(function() scriptContent = fs.readFile(scriptPath) end)
if not ok or type(scriptContent) ~= "string" then
    logError("Script file not found or unreadable: " .. tostring(scriptPath) .. " (" .. tostring(readErr) .. ")")
    (process.exit or os.exit)(1)
end

-- Count lines robustly
local function count_lines(s)
    if not s or s == "" then return 0 end
    local n = 0
    for _ in s:gmatch("\n") do n = n + 1 end
    return n + 1
end
logInfo("Script Size: " .. #scriptContent .. " bytes")
logInfo("Lines in Script: " .. count_lines(scriptContent))

-- Feature auto-configuration
local function analyzeScriptComplexity(code)
    code = code or ""
    local lines = count_lines(code)
    local function has(pat) return code:match(pat) ~= nil end
    return {
        lines = lines,
        has_network = has("HttpService") or has("http_request") or has("request"),
        has_exploit = has("getgenv") or has("hookfunction") or has("getreg"),
        has_obfuscation = has("loadstring") or has("string%.char") or has("string%.fromhex"),
        has_debug = has("debug%.") or has("getupvalue") or has("getfenv"),
        has_file_io = has("writefile") or has("readfile"),
        has_loops = has("while%s") or has("for%s"),
        has_metamethods = has("setmetatable"),
        has_coroutines = has("coroutine%.") or has("task%.spawn"),
        char_count = #code,
    }
end

local function getAutoConfig(content)
    local analysis = analyzeScriptComplexity(content)
    return {
        hookOp = true,
        explore_funcs = true,
        constant_collection = true,
        environment_persistence = true,
        pattern_recognition = true,
        enable_url_fetch = analysis.has_network or (urlToFetch ~= nil),
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
        comments = true,
        include_debug_info = true,
        minifier = false,
        spyexeconly = false,
        no_string_limit = true,
    }
end

local settings = getAutoConfig(scriptContent)

-- Allow environment overrides (setting names: SETTING_<KEY>)
for key in pairs(settings) do
    local envKey = "SETTING_" .. key:upper()
    local envVal = (process.env and process.env[envKey]) or nil
    if envVal ~= nil then
        settings[key] = (envVal == "1" or envVal == "true" or envVal == "True")
    end
end

logInfo("Configuration System Initialized")
local enabledFeatures = {}
for k, v in pairs(settings) do if v then table.insert(enabledFeatures, k) end end
logDebug("Active Features: " .. table.concat(enabledFeatures, ", "))

-- Global state
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

-- Memory analyzer
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
    if not settings.memory_analysis or not identifier then return end
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
        table.insert(memoryAnalyzer.allocation_timeline, { timestamp = os.clock(), identifier = identifier, size = size, type = access_type })
    end
    local entry = memoryAnalyzer.allocations[identifier]
    entry.accesses = entry.accesses + 1
    entry.last_access = os.clock()
    table.insert(entry.access_types, access_type or "unknown")
    if memoryAnalyzer.total_allocated > memoryAnalyzer.peak_allocated then memoryAnalyzer.peak_allocated = memoryAnalyzer.total_allocated end
end

local function heapDump()
    if not settings.heap_dump then return {} end
    local dump = { timestamp = os.clock(), total_objects = 0, by_type = {}, by_size = {}, largest_objects = {} }
    for id, alloc in pairs(memoryAnalyzer.allocations) do
        if not alloc.freed then
            dump.total_objects = dump.total_objects + 1
            local atype = alloc.access_types[1] or "unknown"
            dump.by_type[atype] = (dump.by_type[atype] or 0) + 1
            table.insert(dump.largest_objects, { id = id, size = alloc.size })
        end
    end
    table.sort(dump.largest_objects, function(a, b) return a.size > b.size end)
    table.insert(memoryAnalyzer.heap_snapshots, dump)
    logDebug("Heap dump created: " .. dump.total_objects .. " objects, Peak: " .. memoryAnalyzer.peak_allocated .. " bytes")
    return dump
end

-- Code builders
local function addCode(code, codeType)
    codeType = codeType or "general"
    table.insert(state.codeLines, code)
    table.insert(state.reconstructedCode, { code = code, type = codeType, timestamp = os.clock(), line = #state.codeLines })
end

local function addComment(comment)
    if settings.comments then addCode("-- " .. tostring(comment), "comment") end
end

local function addConstant(name, value, typeInfo)
    if settings.constant_collection and name then
        state.constantBuffer[name] = { value = value, type = typeInfo or type(value) }
        local valueStr = tostring(value)
        if type(value) == "string" then valueStr = '"' .. value:gsub('"', '\\"') .. '"' end
        addCode("local " .. name .. " = " .. valueStr, "constant")
    end
end

local function stringDeobfuscate(encodedStr)
    if not settings.string_deobfuscation or type(encodedStr) ~= "string" then return encodedStr end
    local deobfuscated = encodedStr
    local methods = {}
    -- hex detection
    if encodedStr:match("^%x+$") and #encodedStr % 2 == 0 then
        local success, result = pcall(function()
            return encodedStr:gsub("..", function(cc) return string.char(tonumber(cc, 16)) end)
        end)
        if success and result then deobfuscated = result; table.insert(methods, "hex_decode"); logDebug("String deobfuscated via hex decoding") end
    end
    -- base64-ish
    if encodedStr:match("^[A-Za-z0-9+/]+={0,2}$") and #encodedStr > 4 then
        table.insert(methods, "potential_base64")
    end
    if #methods > 0 then table.insert(state.stringPool, { original = encodedStr, deobfuscated = deobfuscated, methods = methods }) end
    return deobfuscated
end

-- AST node generation
local function createASTNode(nodeType, value, metadata)
    local node = { type = nodeType, value = value, metadata = metadata or {}, children = {}, parent = nil, line_number = #state.astNodes + 1, created_at = os.clock() }
    table.insert(state.astNodes, node)
    return node
end

local function parseCodeStructure(code_str)
    if not settings.ast_generation or type(code_str) ~= "string" then return end
    local lines = {}
    for line in code_str:gmatch("[^\n]+") do table.insert(lines, line) end
    for idx, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$") or ""
        if trimmed:match("^local%s+") then
            local varName = trimmed:match("^local%s+([%w_]+)")
            if varName then createASTNode("variable_declaration", varName, { line = idx }); table.insert(state.variableTracking, { name = varName, line = idx, type = "local" }) end
        elseif trimmed:match("^function%s+") then
            local funcName = trimmed:match("^function%s+([%w_.]+)")
            if funcName then createASTNode("function_declaration", funcName, { line = idx }); state.functionSignatures[funcName] = { line = idx, raw = line } end
        elseif trimmed:match("^if%s+") then createASTNode("conditional", "if", { line = idx })
        elseif trimmed:match("^for%s+") or trimmed:match("^while%s+") then createASTNode("loop", trimmed:match("^%w+"), { line = idx }) end
    end
    logDebug("AST generated with " .. #state.astNodes .. " nodes")
end

-- VM detection
local vmDetector = { detected_vms = {}, obfuscation_markers = {}, vm_signatures = {} }

local function detectVMCharacteristics(env_table)
    if not settings.vm_detection then return end
    env_table = env_table or {}
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
    if characteristics.has_getfenv and characteristics.has_setfenv then vmDetector.detected_vms["LuaU_Compatible"] = true; logInfo("Detected: LuaU_Compatible") end
    if characteristics.has_getupvalue and characteristics.has_setupvalue then vmDetector.detected_vms["UpvalueManipulation"] = true; logInfo("Detected: UpvalueManipulation") end
    if characteristics.has_getlocal and characteristics.has_setlocal then vmDetector.detected_vms["LocalVariableManipulation"] = true; logInfo("Detected: LocalVariableManipulation") end
    if characteristics.has_getreg or characteristics.has_getgc then vmDetector.detected_vms["MemoryAccess"] = true; logInfo("Detected: MemoryAccess") end
    if characteristics.has_debug then vmDetector.detected_vms["DebugCapabilities"] = true; logInfo("Detected: DebugCapabilities") end
    return characteristics
end

local function detectObfuscationPatterns(code_str)
    if not settings.obfuscation_analysis or type(code_str) ~= "string" then return {} end
    local patterns = {
        string_encoding = code_str:match("string%.fromhex") ~= nil or code_str:match("string%.char") ~= nil,
        table_obfuscation = code_str:match("table%[%[") ~= nil,
        control_flow_flattening = code_str:match("while true") ~= nil and code_str:match("break") ~= nil,
        metamethod_hooking = code_str:match("setmetatable") ~= nil and code_str:match("__index") ~= nil,
        bytecode_loading = code_str:match("loadstring") ~= nil or code_str:match("load%(") ~= nil,
        function_wrapping = code_str:match("function%(%.%.%)") ~= nil,
        variable_renaming = #code_str > 0 and true,
        arithmetic_encoding = code_str:match("[%d]%s*[%+%-%%]%s*[%d]") ~= nil,
        xor_encoding = code_str:match("xor") ~= nil or code_str:match("bit32.bxor") ~= nil,
        unicode_obfuscation = code_str:match("\\u%x%x%x%x") ~= nil,
        nested_functions = select(2, code_str:gsub("function%s*%(", "")) > 5,
    }
    local detectedCount = 0
    for pattern, detected in pairs(patterns) do
        if detected then vmDetector.obfuscation_markers[pattern] = true; logWarn("Obfuscation pattern detected: " .. pattern); detectedCount = detectedCount + 1 end
    end
    logInfo("Total obfuscation patterns detected: " .. detectedCount)
    return patterns
end

-- Upvalue & bytecode weak analysis
local function safe_debug() return (type(debug) == "table") and debug or nil end
local function extractUpvalues(func, depth)
    if not settings.upvalue_extraction then return {} end
    depth = depth or 0
    if depth > 5 then return {} end
    local upvalues = {}
    local dbg = safe_debug()
    if type(func) == "function" and dbg and dbg.getupvalue then
        local i = 1
        while true do
            local success, name, value = pcall(function() return dbg.getupvalue(func, i) end)
            if not success or not name then break end
            upvalues[i] = { name = name, value = value, type = type(value) }
            if type(value) == "function" then upvalues[i].nested_upvalues = extractUpvalues(value, depth + 1) end
            trackMemory("upvalue_" .. name, 64, "upvalue_extraction", "depth_" .. depth)
            i = i + 1
        end
    end
    if #upvalues > 0 then logDebug("Extracted " .. #upvalues .. " upvalues at depth " .. depth) end
    return upvalues
end

local function analyzeBytecode(func)
    if not settings.bytecode_analysis then return "" end
    local analysis = {}
    local dbg = safe_debug()
    if dbg and dbg.getinfo then
        local ok, info = pcall(function() return dbg.getinfo(func) end)
        if ok and info then
            table.insert(analysis, "source:" .. tostring(info.source))
            table.insert(analysis, "line_defined:" .. tostring(info.linedefined))
            table.insert(analysis, "last_line:" .. tostring(info.lastlinedefined))
            table.insert(analysis, "params:" .. tostring(info.nparams))
            table.insert(analysis, "vararg:" .. tostring(info.isvararg))
            if dbg.getlocal then
                local locals = {}
                local j = 1
                while true do
                    local ok2, name, value = pcall(function() return dbg.getlocal(func, j) end)
                    if not ok2 or not name then break end
                    table.insert(locals, name)
                    j = j + 1
                end
                if #locals > 0 then table.insert(analysis, "locals:" .. table.concat(locals, ",")) end
            end
        end
    end
    return table.concat(analysis, "|")
end

-- Control & Data flow
local function analyzeControlFlow(code_str)
    if not settings.control_flow_analysis or type(code_str) ~= "string" then return {} end
    local function count(pat) return (select(2, code_str:gsub(pat, "")) or 0) end
    local flows = {
        conditionals = count("if%s+"),
        loops = count("while%s+") + count("for%s+"),
        branches = count("elseif%s+") + count("else%s+"),
        complex_conditions = count(" and ") + count(" or "),
        returns = count("return%s+"),
        breaks = count("break"),
    }
    logInfo(string.format("Control Flow: conditionals=%d, loops=%d, branches=%d, complex=%d, returns=%d",
        flows.conditionals, flows.loops, flows.branches, flows.complex_conditions, flows.returns))
    return flows
end

local function analyzeDataFlow(code_str)
    if not settings.data_flow_analysis or type(code_str) ~= "string" then return {} end
    local function count(pat) return (select(2, code_str:gsub(pat, "")) or 0) end
    local flows = {
        assignments = count("local%s+"),
        functions = count("function%s+") + count("function%("),
        tables = count("{"),
        array_access = count("%["),
        table_access = count("%."),
    }
    logInfo(string.format("Data Flow: assignments=%d, functions=%d, tables=%d, array_access=%d, table_access=%d",
        flows.assignments, flows.functions, flows.tables, flows.array_access, flows.table_access))
    return flows
end

-- Vulnerability scanning
local function scanVulnerabilities(code_str)
    if not settings.vulnerability_scan or type(code_str) ~= "string" then return {} end
    local vulns = {}
    local patterns = {
        { pattern = "os%.execute", type = "RCE", severity = "CRITICAL", desc = "Remote Code Execution via os.execute" },
        { pattern = "os%.system", type = "RCE", severity = "CRITICAL", desc = "System command execution" },
        { pattern = "loadstring", type = "CODE_INJECTION", severity = "HIGH", desc = "Code injection via loadstring" },
        { pattern = "load%s*%(", type = "CODE_INJECTION", severity = "HIGH", desc = "Code injection via load" },
        { pattern = "debug%.setfenv", type = "ENV_MANIPULATION", severity = "HIGH", desc = "Environment manipulation" },
        { pattern = "setfenv", type = "ENV_MANIPULATION", severity = "HIGH", desc = "Function environment manipulation" },
        { pattern = "getfenv", type = "ENV_LEAK", severity = "MEDIUM", desc = "Environment information leak" },
        { pattern = "writefile", type = "FILE_WRITE", severity = "MEDIUM", desc = "File write capability" },
        { pattern = "readfile", type = "FILE_READ", severity = "MEDIUM", desc = "File read capability" },
        { pattern = "HttpService", type = "NETWORK_ACCESS", severity = "MEDIUM", desc = "Network access via HttpService" },
        { pattern = "http_request", type = "NETWORK_ACCESS", severity = "MEDIUM", desc = "Direct HTTP requests" },
        { pattern = "getgenv", type = "ENV_ACCESS", severity = "LOW", desc = "Global environment access" },
        { pattern = "getreg", type = "MEMORY_ACCESS", severity = "HIGH", desc = "Registry access (memory forensics)" },
        { pattern = "getgc", type = "MEMORY_ACCESS", severity = "HIGH", desc = "Garbage collector access" },
    }
    for _, item in ipairs(patterns) do
        if code_str:match(item.pattern) then
            table.insert(vulns, { type = item.type, severity = item.severity, pattern = item.pattern, description = item.desc, found_at = os.clock() })
            logWarn(item.severity .. ": " .. item.type .. " - " .. item.desc)
        end
    end
    logInfo("Vulnerability scan complete: " .. #vulns .. " issues found")
    return vulns
end

-- Profiler
local profiler = { function_times = {}, call_counts = {}, hotspots = {}, total_calls = 0 }
local function profileFunction(func, name)
    if not settings.performance_profiling or type(func) ~= "function" then return func end
    name = name or "anonymous"
    return function(...)
        local startTime = os.clock()
        local results = { pcall(func, ...) }
        local success = table.remove(results, 1)
        local endTime = os.clock()
        local duration = endTime - startTime
        profiler.function_times[name] = profiler.function_times[name] or {}
        profiler.call_counts[name] = (profiler.call_counts[name] or 0) + 1
        table.insert(profiler.function_times[name], duration)
        profiler.total_calls = profiler.total_calls + 1
        if duration > 0.001 then profiler.hotspots[name] = (profiler.hotspots[name] or 0) + 1 end
        if success then return unpack(results) else return nil end
    end
end

-- Call stack and trace
local function captureCallStack(depth)
    if not settings.call_stack_trace then return {} end
    depth = depth or 15
    local stack = {}
    local dbg = safe_debug()
    if not dbg or not dbg.getinfo then return stack end
    for i = 1, depth do
        local ok, info = pcall(function() return dbg.getinfo(i) end)
        if ok and info then
            table.insert(stack, { name = info.name or "unknown", source = info.source or "unknown", line = info.currentline or 0, what = info.what or "unknown", nups = info.nups or 0 })
        else break end
    end
    return stack
end

local function logCallStack()
    if not settings.call_stack_trace then return end
    local stack = captureCallStack(20)
    for i, frame in ipairs(stack) do
        table.insert(state.executionTrace, { index = i, name = frame.name, source = frame.source, line = frame.line, what = frame.what, timestamp = os.clock() })
    end
    logDebug("Call stack logged: " .. #stack .. " frames")
end

-- Build a sandbox environment with mocks
local env = {}
env.print = function(...) addCode("print(...)", "output") end
env.warn = function(...) addCode("warn(...)", "output") end

-- events & mock instance utilities
local function createEvent()
    trackMemory("event_creation", 128, "signal")
    return setmetatable({ __type = "RBXScriptSignal" }, {
        __index = function(t, k)
            if k == "Wait" or k == "wait" then return function() return nil end
            elseif k == "Connect" or k == "connect" or k == "ConnectParallel" then
                return function(self, callback) trackMemory("RBXScriptConnection", 96, "connection"); return setmetatable({ Connected = true, Disconnect = function(self) self.Connected = false end, disconnect = function(self) self.Connected = false end }, { __tostring = function() return "RBXScriptConnection" end }) end
            elseif k == "Fire" or k == "fire" or k == "FireServer" then return function() end end
            return createEvent()
        end,
        __call = function() return nil end,
        __tostring = function() return "RBXScriptSignal" end
    })
end

local instanceCounter = 0
local instances = {}
local function createMockInstance(className, varName)
    trackMemory(varName, 512, "instance")
    local mock = { __className = className, __varName = varName, Name = className, Parent = nil, __createdAt = os.clock() }
    return setmetatable(mock, {
        __index = function(t, k)
            if k == "WaitForChild" or k == "FindFirstChild" then return function(self, childName) return createMockInstance(childName or "Child", childName or "Child") end
            elseif k == "FindFirstChildOfClass" then return function(self, cn) return createMockInstance(cn, cn) end
            elseif k == "GetChildren" or k == "GetDescendants" then return function() return {} end
            elseif k == "GetPropertyChangedSignal" then return function(self, propName) return createEvent() end
            elseif k == "Destroy" or k == "destroy" then return function() end
            elseif k == "Clone" or k == "clone" then return function() return createMockInstance(className, varName .. "_Clone") end
            elseif k == "Connect" then return function(self, callback) return createEvent() end
            elseif k == "IsA" or k == "IsDescendantOf" then return function(self, typeName) return typeName == className end
            elseif k:match("Click") or k:match("Input") or k:match("Changed") or k:match("beat") then return createEvent()
            else return createEvent() end
        end,
        __newindex = function(t, k, v)
            local valueStr = "nil"
            if type(v) == "string" then valueStr = '"' .. stringDeobfuscate(v):gsub('"', '\\"') .. '"' elseif type(v) == "number" or type(v) == "boolean" then valueStr = tostring(v) elseif type(v) == "table" then valueStr = v.__varName or "table" else valueStr = tostring(v) end
            addCode(varName .. "." .. k .. " = " .. valueStr, "property_assignment")
            trackMemory("instance_write_" .. varName .. "_" .. k, 256, "property_assignment")
        end,
        __call = function() return createEvent() end,
        __tostring = function() return varName end
    })
end

-- Robox API mock library (subset)
env.Instance = {
    new = function(className, parent)
        instanceCounter = instanceCounter + 1
        local varName = "Instance" .. instanceCounter
        instances[varName] = className
        if parent then addCode("local " .. varName .. ' = Instance.new("' .. className .. '", ' .. safe_tostring(parent) .. ")", "instance_creation")
        else addCode("local " .. varName .. ' = Instance.new("' .. className .. '")', "instance_creation") end
        trackMemory("instance_new_" .. className, 512, "allocation")
        return createMockInstance(className, varName)
    end
}

env.Vector3 = { new = function(x, y, z) trackMemory("Vector3", 96, "type"); return setmetatable({ x = x, y = y, z = z }, { __tostring = function() return string.format("Vector3.new(%g,%g,%g)", x or 0, y or 0, z or 0) end }) end }
env.Color3 = { fromRGB = function(r, g, b) trackMemory("Color3_fromRGB", 96, "type"); return setmetatable({ r = r, g = g, b = b }, { __tostring = function() return string.format("Color3.fromRGB(%d,%d,%d)", r, g, b) end }) end }
env.UDim = { new = function(s, o) trackMemory("UDim", 64, "type"); return setmetatable({ Scale = s, Offset = o }, { __tostring = function() return string.format("UDim.new(%g,%g)", s, o) end }) end }
env.UDim2 = { new = function(xs, xo, ys, yo) trackMemory("UDim2", 96, "type"); return setmetatable({ XScale = xs, XOffset = xo, YScale = ys, YOffset = yo }, { __tostring = function() return string.format("UDim2.new(%g,%g,%g,%g)", xs, xo, ys, yo) end }) end }

-- Timing
env.tick = function() trackMemory("tick", 16, "timing"); return os.clock() end
env.time = function() trackMemory("time", 16, "timing"); return os.clock() end
env.wait = function(t) trackMemory("wait", 32, "timing"); return 0 end
env.delay = function(t, f) trackMemory("delay", 64, "timing"); if f then f() end; return 0 end
env.spawn = function(f) trackMemory("spawn", 128, "coroutine"); if f then f() end end

-- Enums/Services
env.Enum = setmetatable({}, { __index = function(_, k) return setmetatable({}, { __index = function(_, v) return setmetatable({ Name = v }, { __tostring = function() return "Enum." .. k .. "." .. v end }) end }) end })

local services = {}
env.game = setmetatable({}, { __index = function(_, k)
    if k == "GetService" then
        return function(_, name)
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
                        addCode('TweenService:Create(...)', "service_call"); trackMemory("tween_creation", 256, "service")
                        return setmetatable({}, { __index = { Play = function() addCode("Tween:Play()", "service_call") end, Cancel = function() addCode("Tween:Cancel()", "service_call") end, Completed = createEvent() } })
                    end
                elseif name == "HttpService" then
                    services[name].GetAsync = function(self, url) addCode('HttpService:GetAsync("' .. url .. '")', "network_call"); local resp, err = fetchURL(url, "GET"); return resp or "" end
                    services[name].PostAsync = function(self, url, data) addCode('HttpService:PostAsync("' .. url .. '", ...)', "network_call"); local resp, err = fetchURL(url, "POST", {}, data); return resp or "" end
                elseif name == "RunService" then
                    services[name].RenderStepped = createEvent(); services[name].Heartbeat = createEvent(); services[name].Stepped = createEvent()
                end
            end
            return services[name]
        end
    elseif k == "Workspace" or k == "workspace" then
        return createMockInstance("Workspace", "workspace")
    end
    return createEvent()
end })

env.workspace = createMockInstance("Workspace", "workspace")
env.script = createMockInstance("Script", "script")

-- Network helpers
function fetchURL(url, method, headers, body, retries)
    if not settings.enable_url_fetch then logDebug("URL fetch disabled: " .. tostring(url)); return nil, "URL fetching disabled" end
    if not url then return nil, "No URL" end
    retries = retries or 3
    method = method or "GET"
    headers = headers or {}
    if state.urlCache[url] and state.urlCache[url].content then logDebug("URL cache hit: " .. url); return state.urlCache[url].content, nil end
    local lastError
    if not net then lastError = "net module not available"; logWarn("Cannot fetch URL: net module missing"); state.urlCache[url] = { success = false, error = lastError, attempts = 0 }; return nil, lastError end
    for attempt = 1, retries do
        local ok, response_or_err = pcall(function()
            local config = { url = url, method = method, headers = headers }
            if body then config.body = body end
            return net.request(config)
        end)
        if ok and response_or_err then
            state.urlCache[url] = { content = response_or_err, timestamp = os.clock(), method = method, attempts = attempt, success = true }
            logDebug("URL fetched successfully: " .. url .. " (attempt " .. attempt .. ")")
            return response_or_err, nil
        end
        lastError = response_or_err
        logWarn("URL fetch attempt " .. attempt .. "/" .. retries .. " failed: " .. tostring(lastError))
    end
    logError("Failed to fetch URL after " .. retries .. " retries: " .. url)
    state.urlCache[url] = { success = false, error = lastError, attempts = retries }
    return nil, "Failed after " .. retries .. " retries"
end

-- FS helpers (wrap write to catch errors)
local function safe_write_file(path, content)
    local ok, err = pcall(function() fs.writeFile(path, content) end)
    return ok, err
end

-- Hook arithmetic ops if enabled
if settings.hookOp then
    local function createTrackedNumber(value)
        return setmetatable({ __value = value }, {
            __add = function(a, b) local av = (type(a) == "table") and a.__value or a; local bv = (type(b) == "table") and b.__value or b; addComment("OP: " .. av .. " + " .. bv); return createTrackedNumber(av + bv) end,
            __sub = function(a, b) local av = (type(a) == "table") and a.__value or a; local bv = (type(b) == "table") and b.__value or b; addComment("OP: " .. av .. " - " .. bv); return createTrackedNumber(av - bv) end,
            __mul = function(a, b) local av = (type(a) == "table") and a.__value or a; local bv = (type(b) == "table") and b.__value or b; addComment("OP: " .. av .. " * " .. bv); return createTrackedNumber(av * bv) end,
            __div = function(a, b) local av = (type(a) == "table") and a.__value or a; local bv = (type(b) == "table") and b.__value or b; if bv ~= 0 then addComment("OP: " .. av .. " / " .. bv); return createTrackedNumber(av / bv) end; return createTrackedNumber(0) end,
            __mod = function(a, b) local av = (type(a) == "table") and a.__value or a; local bv = (type(b) == "table") and b.__value or b; if bv ~= 0 then addComment("OP: " .. av .. " % " .. bv); return createTrackedNumber(av % bv) end; return createTrackedNumber(0) end,
            __tostring = function(self) return tostring(self.__value) end,
        })
    end
    local orig_tonumber = env.tonumber or tonumber
    env.tonumber = function(...) local result = orig_tonumber(...) return result and createTrackedNumber(result) or result end
    logDebug("Arithmetic operation tracking enabled")
end

-- Additional robust code loading: support Lua 5.1 and 5.2+ with env injection
local function load_chunk(code, name, env_tbl)
    env_tbl = env_tbl or {}
    if type(load) == "function" then
        -- try to use load with env arg (Lua 5.2+)
        local ok, chunk = pcall(function() return load(code, name or "chunk", "t", env_tbl) end)
        if ok and type(chunk) == "function" then return chunk, nil end
    end
    -- fallback to loadstring (Lua 5.1) then setfenv if available
    if type(loadstring) == "function" then
        local f, err = loadstring(code, name or "chunk")
        if not f then return nil, err end
        if type(setfenv) == "function" then
            pcall(setfenv, f, env_tbl)
        end
        return f, nil
    end
    return nil, "No load function available in this runtime"
end

-- Analysis & Preparation
logInfo("ANALYSIS PHASE: Script Analysis & Preparation")
logInfo("Analyzing script characteristics...")
local _ = detectVMCharacteristics(env)
local _ = detectObfuscationPatterns(scriptContent)
state.vulnerabilities = scanVulnerabilities(scriptContent)
parseCodeStructure(scriptContent)

-- Execution Phase
logInfo("EXECUTION PHASE: Script Execution")
logInfo("Loading script chunk...")
local chunk, err = load_chunk(scriptContent, "@script", env)
if not chunk then
    logError("Failed to load script: " .. tostring(err))
    table.insert(state.executionErrors, { error = err, timestamp = os.clock(), stage = "chunk_loading" })
else
    logInfo("Executing script in sandboxed environment...")
    local success, result = pcall(chunk)
    if not success then
        logError("Script execution error: " .. tostring(result))
        table.insert(state.executionErrors, { error = result, timestamp = os.clock(), stage = "script_execution" })
    else
        logInfo("Script executed successfully")
        if type(result) == "function" then
            logDebug("Result is function, executing...")
            -- If setfenv exists try to set the env; otherwise assume closure already correct
            if type(setfenv) == "function" then pcall(setfenv, result, env) end
            local ok2, res2 = pcall(result)
            if not ok2 then
                logError("Function execution error: " .. tostring(res2))
                table.insert(state.executionErrors, { error = res2, timestamp = os.clock(), stage = "function_execution" })
            end
        end
    end
end

logCallStack()
heapDump()

-- Post analysis
logInfo("POST-ANALYSIS PHASE: Data Collection")
state.controlFlows = analyzeControlFlow(scriptContent)
state.dataFlows = analyzeDataFlow(scriptContent)

-- Report generation
local function generateComprehensiveReport()
    local output = {}
    table.insert(output, string.rep("=", 100))
    table.insert(output, " ROBLOX CODE RECONSTRUCTOR - COMPREHENSIVE ANALYSIS REPORT")
    table.insert(output, string.rep("=", 100))
    table.insert(output, "")
    local execTime = os.clock() - logger.startTime
    table.insert(output, "EXECUTION SUMMARY")
    table.insert(output, ("Analysis Time: %.4f seconds"):format(execTime))
    table.insert(output, "Code Lines Generated: " .. #state.codeLines)
    table.insert(output, "AST Nodes Created: " .. #state.astNodes)
    table.insert(output, "Execution Errors: " .. #state.executionErrors)
    table.insert(output, "Vulnerabilities Found: " .. #state.vulnerabilities)
    table.insert(output, "Network Requests: " .. countTable(state.urlCache))
    table.insert(output, "")
    table.insert(output, "ACTIVE CONFIGURATION")
    local feat_lines = {}
    for setting, enabled in pairs(settings) do if enabled then table.insert(feat_lines, setting) end end
    table.insert(output, table.concat(feat_lines, ", "))
    table.insert(output, "")
    if countTable(vmDetector.detected_vms) > 0 then
        table.insert(output, "DETECTED VIRTUAL MACHINES")
        for vm_type in pairs(vmDetector.detected_vms) do table.insert(output, " - " .. vm_type) end
        table.insert(output, "")
    end
    if countTable(vmDetector.obfuscation_markers) > 0 then
        table.insert(output, "OBFUSCATION PATTERNS")
        for marker in pairs(vmDetector.obfuscation_markers) do table.insert(output, " - " .. marker) end
        table.insert(output, "")
    end
    if #state.vulnerabilities > 0 then
        table.insert(output, "VULNERABILITY SCAN RESULTS")
        for i, vuln in ipairs(state.vulnerabilities) do
            table.insert(output, string.format("[%d] %s: %s", i, vuln.severity, vuln.type))
            table.insert(output, "    Pattern: " .. vuln.pattern)
            table.insert(output, "    Description: " .. vuln.description)
        end
        table.insert(output, "")
    end
    if settings.memory_analysis then
        table.insert(output, "MEMORY ANALYSIS")
        table.insert(output, " Total Allocated: " .. memoryAnalyzer.total_allocated .. " bytes")
        table.insert(output, " Peak Allocated: " .. memoryAnalyzer.peak_allocated .. " bytes")
        table.insert(output, " Total Objects: " .. countTable(memoryAnalyzer.allocations))
        table.insert(output, "")
    end
    if state.controlFlows and countTable(state.controlFlows) > 0 then
        table.insert(output, "CONTROL FLOW ANALYSIS")
        table.insert(output, (" Conditionals: %d  Loops: %d  Branches: %d  Returns: %d"):format(state.controlFlows.conditionals or 0, state.controlFlows.loops or 0, state.controlFlows.branches or 0, state.controlFlows.returns or 0))
        table.insert(output, "")
    end
    if state.dataFlows and countTable(state.dataFlows) > 0 then
        table.insert(output, "DATA FLOW ANALYSIS")
        table.insert(output, (" Assignments: %d  Functions: %d  Tables: %d"):format(state.dataFlows.assignments or 0, state.dataFlows.functions or 0, state.dataFlows.tables or 0))
        table.insert(output, "")
    end
    if #state.codeLines > 0 then
        table.insert(output, "RECONSTRUCTED CODE (" .. #state.codeLines .. " lines)")
        local max_display = tonumber(cli.flags.max_lines) or 0
        for idx, line in ipairs(state.codeLines) do
            if max_display > 0 and idx > max_display then break end
            table.insert(output, string.format("%4d â”‚ %s", idx, line))
        end
        if max_display > 0 and #state.codeLines > max_display then table.insert(output, "... output truncated by --max-lines") end
        table.insert(output, "")
    else
        table.insert(output, "-- No code reconstructed from execution")
    end
    if settings.call_stack_trace and #state.executionTrace > 0 then
        table.insert(output, "EXECUTION TRACE (" .. #state.executionTrace .. " frames)")
        for _, frame in ipairs(state.executionTrace) do
            table.insert(output, string.format("[%d] %s @ %s:%d (%s)", frame.index, frame.name, frame.source or "?", frame.line or 0, frame.what or "?"))
        end
        table.insert(output, "")
    end
    table.insert(output, "SYSTEM LOGS (" .. #logger.logs .. " entries)")
    for _, entry in ipairs(logger.logs) do table.insert(output, entry) end
    table.insert(output, "")
    table.insert(output, "Report Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(output, ("Total Analysis Time: %.4f seconds"):format(execTime))
    return table.concat(output, "\n")
end

-- Output phase
logInfo("OUTPUT PHASE: Report Generation & File Writing")
local report = generateComprehensiveReport()
local reportFile = scriptPath .. ".analysis.log"

if cli.flags.dry_run then
    logInfo("Dry run enabled; not writing files. Printing report to STDOUT.")
    print("\n" .. report .. "\n")
else
    local ok1, err1 = safe_write_file(reportFile, report)
    if ok1 then logInfo("Analysis report written to: " .. reportFile .. " (" .. #report .. " bytes)") else logError("Failed to write report: " .. tostring(err1)) end

    if #state.codeLines > 0 then
        local codeFile = scriptPath .. ".reconstructed.lua"
        local reconCode = table.concat(state.codeLines, "\n")
        local ok2, err2 = safe_write_file(codeFile, reconCode)
        if ok2 then logInfo("Reconstructed code written to: " .. codeFile .. " (" .. #reconCode .. " bytes)") else logError("Failed to write reconstructed code: " .. tostring(err2)) end
    end

    -- JSON output (simple)
    local jsonFile = scriptPath .. ".analysis.json"
    local json_tbl = {
        summary = { execution_time = os.clock() - logger.startTime, code_lines_generated = #state.codeLines, ast_nodes = #state.astNodes, errors = #state.executionErrors, vulnerabilities = #state.vulnerabilities },
        vulnerabilities = state.vulnerabilities,
        variables = state.variableTracking,
        functions = state.functionSignatures,
        errors = state.executionErrors,
    }
    -- Basic JSON serialization (for portability; not full-featured)
    local function to_json_simple(t)
        local seen = {}
        local function esc(s) return tostring(s):gsub("\\", "\\\\"):gsub('"', '\\"') end
        local function ser(v)
            if v == nil then return "null" end
            local tp = type(v)
            if tp == "string" then return '"' .. esc(v) .. '"' end
            if tp == "number" or tp == "boolean" then return tostring(v) end
            if tp == "table" then
                if seen[v] then return '"<cycle>"' end
                seen[v] = true
                local is_arr = true
                local max = 0
                for k in pairs(v) do if type(k) ~= "number" then is_arr = false; break end; if k > max then max = k end end
                local parts = {}
                if is_arr then
                    for i = 1, max do table.insert(parts, ser(v[i])) end
                    return "[" .. table.concat(parts, ",") .. "]"
                else
                    for k, val in pairs(v) do table.insert(parts, '"' .. esc(k) .. '":' .. ser(val)) end
                    return "{" .. table.concat(parts, ",") .. "}"
                end
            end
            return '"' .. esc(tostring(v)) .. '"'
        end
        return ser(t)
    end

    local ok3, err3 = safe_write_file(jsonFile, to_json_simple(json_tbl))
    if ok3 then logInfo("JSON data written to: " .. jsonFile) else logError("Failed to write JSON data: " .. tostring(err3)) end
end

logInfo("ANALYSIS COMPLETE")
logInfo("Total execution time: " .. string.format("%.4f", os.clock() - logger.startTime) .. " seconds")
logInfo("Output files generated: " .. (cli.flags.dry_run and "0 (dry-run)" or ">=1"))

-- Print report to STDOUT (also useful)
print("\n" .. report .. "\n")

-- Exit politely
(local function final_exit(code) (process.exit or os.exit)(code or 0) end)(0)
