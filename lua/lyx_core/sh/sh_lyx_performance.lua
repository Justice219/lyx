lyx = lyx
lyx.perf = lyx.perf or {}
lyx.perfData = lyx.perfData or {}

--[[
.____                    __________              _____                                             
|    |    ___.__.___  ___\______   \ ____________/ ____\___________  _____ _____    ____   ____  ____  
|    |   <   |  |\  \/  / |     ___// __ \_  __ \   __\/  _ \_  __ \/     \\__  \  /    \_/ ___\/ __ \ 
|    |___ \___  | >    <  |    |   \  ___/|  | \/|  | (  <_> )  | \/  Y Y  \/ __ \|   |  \  \__\  ___/ 
|_______ \/ ____|/__/\_ \ |____|    \___  >__|   |__|  \____/|__|  |__|_|  (____  /___|  /\___  >___  >
        \/\/           \/               \/                               \/     \/     \/     \/    \/ 

Performance monitoring and profiling system for tracking and optimizing code execution

]]--

do
    -- Configuration
    local ENABLE_MONITORING = true
    local MAX_SAMPLES = 1000  -- Maximum samples to keep per metric
    local SLOW_THRESHOLD = 0.016  -- 16ms (one frame at 60fps)
    local MEMORY_WARNING_THRESHOLD = 100 * 1024 * 1024  -- 100MB
    
    -- Performance tracking state
    local activeTimers = {}
    local frameStats = {
        count = 0,
        totalTime = 0,
        minTime = math.huge,
        maxTime = 0,
        samples = {}
    }
    
    --[[
        Start a performance timer
        @param name string - Timer name
        @param category string - Optional category for grouping
        @return string - Timer ID
    ]]
    function lyx:PerfStart(name, category)
        if not ENABLE_MONITORING then return end
        
        if type(name) ~= "string" then
            return nil
        end
        
        local id = name .. "_" .. lyx:UtilNewHash(8)
        
        activeTimers[id] = {
            name = name,
            category = category or "default",
            startTime = SysTime and SysTime() or os.clock(),
            startMemory = collectgarbage("count") * 1024  -- Convert to bytes
        }
        
        return id
    end
    
    --[[
        End a performance timer and record results
        @param id string - Timer ID from PerfStart
        @return number - Elapsed time in seconds
    ]]
    function lyx:PerfEnd(id)
        if not ENABLE_MONITORING or not id then return end
        
        local timer = activeTimers[id]
        if not timer then
            lyx.Logger:Log("Performance timer not found: " .. tostring(id), 2)
            return
        end
        
        local endTime = SysTime and SysTime() or os.clock()
        local endMemory = collectgarbage("count") * 1024
        
        local elapsed = endTime - timer.startTime
        local memoryUsed = endMemory - timer.startMemory
        
        -- Initialize category if needed
        lyx.perfData[timer.category] = lyx.perfData[timer.category] or {}
        lyx.perfData[timer.category][timer.name] = lyx.perfData[timer.category][timer.name] or {
            calls = 0,
            totalTime = 0,
            minTime = math.huge,
            maxTime = 0,
            avgTime = 0,
            totalMemory = 0,
            samples = {}
        }
        
        local data = lyx.perfData[timer.category][timer.name]
        
        -- Update statistics
        data.calls = data.calls + 1
        data.totalTime = data.totalTime + elapsed
        data.minTime = math.min(data.minTime, elapsed)
        data.maxTime = math.max(data.maxTime, elapsed)
        data.avgTime = data.totalTime / data.calls
        data.totalMemory = data.totalMemory + memoryUsed
        
        -- Store sample
        table.insert(data.samples, {
            time = elapsed,
            memory = memoryUsed,
            timestamp = CurTime and CurTime() or os.time()
        })
        
        -- Limit samples
        if #data.samples > MAX_SAMPLES then
            table.remove(data.samples, 1)
        end
        
        -- Warn about slow operations
        if elapsed > SLOW_THRESHOLD then
            lyx.Logger:Log("Slow operation detected: " .. timer.name .. " took " .. 
                          math.Round(elapsed * 1000, 2) .. "ms", 2)
        end
        
        -- Warn about high memory usage
        if memoryUsed > MEMORY_WARNING_THRESHOLD then
            lyx.Logger:Log("High memory usage: " .. timer.name .. " used " .. 
                          math.Round(memoryUsed / (1024 * 1024), 2) .. "MB", 2)
        end
        
        -- Clean up
        activeTimers[id] = nil
        
        return elapsed
    end
    
    --[[
        Measure function execution time
        @param name string - Metric name
        @param func function - Function to measure
        @param ... any - Arguments to pass to function
        @return any - Function return values
    ]]
    function lyx:PerfMeasure(name, func, ...)
        if type(func) ~= "function" then
            return
        end
        
        local id = lyx:PerfStart(name, "functions")
        local results = {pcall(func, ...)}
        lyx:PerfEnd(id)
        
        if not results[1] then
            lyx.Logger:Log("Error in measured function '" .. name .. "': " .. tostring(results[2]), 3)
            return
        end
        
        return unpack(results, 2)
    end
    
    --[[
        Wrap a function with automatic performance tracking
        @param name string - Metric name
        @param func function - Function to wrap
        @param category string - Optional category
        @return function - Wrapped function
    ]]
    function lyx:PerfWrap(name, func, category)
        if type(func) ~= "function" then
            return func
        end
        
        return function(...)
            local id = lyx:PerfStart(name, category)
            local results = {func(...)}
            lyx:PerfEnd(id)
            return unpack(results)
        end
    end
    
    --[[
        Get performance statistics for a specific metric
        @param name string - Metric name
        @param category string - Optional category
        @return table - Performance statistics
    ]]
    function lyx:PerfGetStats(name, category)
        category = category or "default"
        
        if lyx.perfData[category] and lyx.perfData[category][name] then
            local data = lyx.perfData[category][name]
            return {
                calls = data.calls,
                totalTime = data.totalTime,
                avgTime = data.avgTime,
                minTime = data.minTime,
                maxTime = data.maxTime,
                totalMemory = data.totalMemory,
                avgMemory = data.totalMemory / data.calls,
                recentSamples = #data.samples > 10 and 
                               {unpack(data.samples, #data.samples - 9)} or 
                               data.samples
            }
        end
        
        return nil
    end
    
    --[[
        Get all performance statistics
        @param category string - Optional category filter
        @return table - All performance statistics
    ]]
    function lyx:PerfGetAllStats(category)
        if category then
            return lyx.perfData[category] or {}
        end
        
        -- Return formatted statistics
        local stats = {}
        for cat, metrics in pairs(lyx.perfData) do
            stats[cat] = {}
            for name, data in pairs(metrics) do
                stats[cat][name] = {
                    calls = data.calls,
                    avgTime = math.Round(data.avgTime * 1000, 3),  -- Convert to ms
                    totalTime = math.Round(data.totalTime, 3),
                    avgMemory = math.Round(data.totalMemory / data.calls / 1024, 2)  -- Convert to KB
                }
            end
        end
        
        return stats
    end
    
    --[[
        Clear performance statistics
        @param name string - Optional specific metric
        @param category string - Optional category
    ]]
    function lyx:PerfClear(name, category)
        if name and category then
            if lyx.perfData[category] then
                lyx.perfData[category][name] = nil
            end
        elseif category then
            lyx.perfData[category] = {}
        else
            lyx.perfData = {}
        end
        
        lyx.Logger:Log("Cleared performance data")
    end
    
    --[[
        Profile a code block
        @param name string - Profile name
        @param iterations number - Number of iterations to run
        @param func function - Function to profile
        @return table - Profile results
    ]]
    function lyx:PerfProfile(name, iterations, func)
        if type(func) ~= "function" or type(iterations) ~= "number" then
            return nil
        end
        
        iterations = math.max(1, math.min(iterations, 10000))  -- Limit iterations
        
        local results = {
            iterations = iterations,
            times = {},
            memory = {},
            errors = 0
        }
        
        -- Warm up (JIT compilation)
        pcall(func)
        
        -- Run profiling
        for i = 1, iterations do
            local startTime = SysTime and SysTime() or os.clock()
            local startMem = collectgarbage("count")
            
            local success = pcall(func)
            
            local elapsed = (SysTime and SysTime() or os.clock()) - startTime
            local memUsed = collectgarbage("count") - startMem
            
            if success then
                table.insert(results.times, elapsed)
                table.insert(results.memory, memUsed)
            else
                results.errors = results.errors + 1
            end
        end
        
        -- Calculate statistics
        if #results.times > 0 then
            table.sort(results.times)
            
            local total = 0
            for _, t in ipairs(results.times) do
                total = total + t
            end
            
            results.stats = {
                avg = total / #results.times,
                min = results.times[1],
                max = results.times[#results.times],
                median = results.times[math.floor(#results.times / 2)],
                total = total,
                errorRate = results.errors / iterations
            }
            
            -- Convert to milliseconds for readability
            results.stats.avg = math.Round(results.stats.avg * 1000, 4)
            results.stats.min = math.Round(results.stats.min * 1000, 4)
            results.stats.max = math.Round(results.stats.max * 1000, 4)
            results.stats.median = math.Round(results.stats.median * 1000, 4)
            
            lyx.Logger:Log("Profile '" .. name .. "': " .. 
                          "avg=" .. results.stats.avg .. "ms, " ..
                          "min=" .. results.stats.min .. "ms, " ..
                          "max=" .. results.stats.max .. "ms")
        end
        
        return results
    end
    
    --[[
        Track frame performance (CLIENT ONLY)
        Should be called once per frame
    ]]
    function lyx:PerfTrackFrame()
        if not CLIENT then return end
        
        local frameTime = FrameTime and FrameTime() or 0.016
        
        frameStats.count = frameStats.count + 1
        frameStats.totalTime = frameStats.totalTime + frameTime
        frameStats.minTime = math.min(frameStats.minTime, frameTime)
        frameStats.maxTime = math.max(frameStats.maxTime, frameTime)
        
        table.insert(frameStats.samples, frameTime)
        if #frameStats.samples > MAX_SAMPLES then
            table.remove(frameStats.samples, 1)
        end
    end
    
    --[[
        Get frame performance statistics (CLIENT ONLY)
        @return table - Frame statistics
    ]]
    function lyx:PerfGetFrameStats()
        if not CLIENT then return nil end
        
        if frameStats.count == 0 then
            return nil
        end
        
        local avgFrameTime = frameStats.totalTime / frameStats.count
        local avgFPS = 1 / avgFrameTime
        
        -- Calculate recent average
        local recentTotal = 0
        local recentCount = math.min(60, #frameStats.samples)  -- Last 60 frames
        for i = #frameStats.samples - recentCount + 1, #frameStats.samples do
            recentTotal = recentTotal + frameStats.samples[i]
        end
        local recentAvg = recentCount > 0 and (recentTotal / recentCount) or avgFrameTime
        
        return {
            avgFPS = math.Round(avgFPS, 1),
            minFPS = math.Round(1 / frameStats.maxTime, 1),
            maxFPS = math.Round(1 / frameStats.minTime, 1),
            currentFPS = math.Round(1 / recentAvg, 1),
            frameTime = math.Round(avgFrameTime * 1000, 2),  -- ms
            samples = frameStats.count
        }
    end
    
    --[[
        Enable/disable performance monitoring
        @param enabled boolean - Enable or disable
    ]]
    function lyx:PerfSetEnabled(enabled)
        ENABLE_MONITORING = enabled
        lyx.Logger:Log("Performance monitoring " .. (enabled and "enabled" or "disabled"))
    end
    
    --[[
        Print performance report to console
        @param category string - Optional category filter
    ]]
    function lyx:PerfPrintReport(category)
        local stats = lyx:PerfGetAllStats(category)
        
        print("\n=== PERFORMANCE REPORT ===")
        for cat, metrics in pairs(stats) do
            print("\nCategory: " .. cat)
            print(string.rep("-", 60))
            
            -- Sort by total time
            local sorted = {}
            for name, data in pairs(metrics) do
                table.insert(sorted, {name = name, data = data})
            end
            table.sort(sorted, function(a, b)
                return a.data.totalTime > b.data.totalTime
            end)
            
            for _, item in ipairs(sorted) do
                print(string.format("  %-30s | Calls: %6d | Avg: %7.3fms | Total: %7.3fs",
                    item.name,
                    item.data.calls,
                    item.data.avgTime,
                    item.data.totalTime
                ))
            end
        end
        print("\n" .. string.rep("=", 60) .. "\n")
    end
    
    -- Hook for automatic frame tracking on client
    if CLIENT then
        hook.Add("Think", "lyx_perf_frame", function()
            lyx:PerfTrackFrame()
        end)
    end
end