local UEHelpers = require("UEHelpers")

local function Log(msg)
    print("[DockMeBaby] " .. tostring(msg) .. "\n")
end

-- Scans for potential ship instances in the world
local function ScanForShips()
    Log("Starting ship scan...")
    
    local ok, pawns = pcall(function() return FindAllOf("Pawn") end)
    if not ok or not pawns then
        Log("Failed to execute FindAllOf('Pawn').")
        return
    end

    local foundCount = 0
    for _, pawn in ipairs(pawns) do
        if pawn and pawn:IsValid() then
            local okName, name = pcall(function() return pawn:GetFullName() end)
            if okName and name then
                local lowerName = string.lower(name)
                if string.find(lowerName, "ship") or string.find(lowerName, "boat") then
                    Log("Potential Ship Found: " .. name)
                    foundCount = foundCount + 1
                end
            end
        end
    end
    
    Log("Scan complete. Found " .. tostring(foundCount) .. " potential ship actors.")
end

-- Finds the first valid, active ship Pawn in the world
local function FindActiveShip(preferredClass)
    local ok, pawns = pcall(function() return FindAllOf("Pawn") end)
    if not ok or not pawns then return nil end
    
    for _, pawn in ipairs(pawns) do
        if pawn and pawn:IsValid() then
            local okName, name = pcall(function() return pawn:GetFullName() end)
            if okName and name then
                local lowerName = string.lower(name)
                local currentClass = string.match(name, "^([^%s]+)") or name
                
                local isShip = string.find(lowerName, "ship") and not string.find(lowerName, "character") and not string.find(lowerName, "shallowboat")
                local matchesPreferred = (not preferredClass) or (preferredClass == currentClass)
                
                if isShip and matchesPreferred then
                    -- Make sure we can read its location to ensure it's a real world instance
                    local okLoc, loc = pcall(function() return pawn:K2_GetActorLocation() end)
                    if okLoc and loc then
                        local okX = pcall(function() return loc.X + 0 end)
                        if okX then 
                            return pawn 
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Returns the relative path into our mod folder so the json isn't dumped in Binaries/Win64
local function GetConfigFilePath()
    return "ue4ss/Mods/DockMeBaby/DockMeBaby_Coords.json"
end

-- Loads and parses the coordinates from the JSON file
local function LoadDockData()
    local fileName = GetConfigFilePath()
    local file = io.open(fileName, "r")
    if not file then return nil end
    
    local content = file:read("*a")
    file:close()
    
    -- Simple regex-style matching to pull out our numbers
    local x = tonumber(string.match(content, '"X":%s*([%-%d%.]+)'))
    local y = tonumber(string.match(content, '"Y":%s*([%-%d%.]+)'))
    local z = tonumber(string.match(content, '"Z":%s*([%-%d%.]+)'))
    local yaw = tonumber(string.match(content, '"Yaw":%s*([%-%d%.]+)'))
    local shipName = string.match(content, '"ShipName":%s*"([^"]+)"')
    
    if x and y and z and yaw then
        return {X = x, Y = y, Z = z}, {Pitch = 0, Yaw = yaw, Roll = 0}, shipName
    end
    return nil
end

-- Saves coordinates to a JSON file
local function SaveDockData(loc, rot, shipName)
    local fileName = GetConfigFilePath()
    local file = io.open(fileName, "w")
    
    if file then
        local safeName = tostring(shipName or "UnknownShip")
        -- Writing a simple JSON format manually
        file:write(string.format('{\n  "ShipName": "%s",\n  "X": %f,\n  "Y": %f,\n  "Z": %f,\n  "Yaw": %f\n}', safeName, loc.X, loc.Y, loc.Z, rot.Yaw))
        file:close()
        Log("Success! Saved dock position for " .. safeName .. " to " .. fileName)
    else
        Log("Error: Could not open " .. fileName .. " for writing.")
    end
end

-- Console Command: scanship
RegisterConsoleCommandHandler("scanship", function(FullCommand, Parameters, Ar)
    ScanForShips()
    return true
end)

-- Console Command: setdock
RegisterConsoleCommandHandler("setdock", function(FullCommand, Parameters, Ar)
    Log("Command 'setdock' triggered.")
    
    local ship = FindActiveShip()
    if not ship then
        Log("Error: No valid active ship found in the world.")
        return true
    end

    local okName, name = pcall(function() return ship:GetFullName() end)
    local shipClass = string.match(name, "^([^%s]+)") or name
    Log("Targeting Ship: " .. tostring(shipClass))

    local okLoc, loc = pcall(function() return ship:K2_GetActorLocation() end)
    local okRot, rot = pcall(function() return ship:K2_GetActorRotation() end)
    
    if okLoc and loc and okRot and rot then
        Log(string.format("Current Ship Transform -> X:%.2f, Y:%.2f, Z:%.2f, Yaw:%.2f", loc.X, loc.Y, loc.Z, rot.Yaw))
        SaveDockData(loc, rot, shipClass)
    else
        Log("Error: Failed to read ship location or rotation.")
    end

    return true
end)

-- Console Command: dock
RegisterConsoleCommandHandler("dock", function(FullCommand, Parameters, Ar)
    Log("Command 'dock' triggered.")
    
    local targetLoc, targetRot, savedShipClass = LoadDockData()
    if not targetLoc then
        Log("Error: Could not load coordinates from " .. GetConfigFilePath())
        return true
    end
    
    local ship = FindActiveShip(savedShipClass)
    if not ship then
        Log("Error: No valid active ship found in the world.")
        return true
    end

    local okName, name = pcall(function() return ship:GetFullName() end)
    Log("Teleporting Ship: " .. tostring(name))

    local okLoc = pcall(function() return ship:K2_SetActorLocation(targetLoc, false, {}, true) end)
    local okRot = pcall(function() return ship:K2_SetActorRotation(targetRot, true) end)
    
    if okLoc and okRot then
        Log(string.format("Success! Ship docked at X:%.2f, Y:%.2f, Z:%.2f, Yaw:%.2f", targetLoc.X, targetLoc.Y, targetLoc.Z, targetRot.Yaw))
    else
        Log("Error: Failed to set ship location or rotation. Check parameters.")
    end

    return true
end)

-- Entry point execution
Log("Mod initialized successfully.")
Log("Available console commands: scanship, setdock, dock")