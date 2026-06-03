local UEHelpers = require("UEHelpers")

local function Log(msg)
    print("[DockMeBaby] " .. tostring(msg) .. "\n")
end

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================
local function GetPlayerSafe()
    local ok1, r1 = pcall(function()
        local chars = FindAllOf("BP_R5Character_C")
        if chars then
            for _, c in ipairs(chars) do
                if c and c:IsValid() then return c end
            end
        end
        return nil
    end)
    if ok1 and r1 then return r1 end

    local ok2, r2 = pcall(function()
        local pc = FindFirstOf("PlayerController")
        if pc and pc:IsValid() then
            local pawn = pc:GetPawn()
            if pawn and pawn:IsValid() then return pawn end
        end
        return nil
    end)
    if ok2 and r2 then return r2 end

    local ok3, r3 = pcall(UEHelpers.GetPlayer)
    if ok3 and r3 and r3:IsValid() then return r3 end

    return nil
end

local function GetActorLoc(actor)
    if not actor then return nil end
    local ok, loc = pcall(function() return actor:K2_GetActorLocation() end)
    if ok and loc then
        local okX = pcall(function() return loc.X + 0 end)
        if okX then return loc end
    end
    local ok2, loc2 = pcall(function()
        local root = actor.RootComponent
        if root then return root.RelativeLocation end
        return nil
    end)
    if ok2 and loc2 then
        local okX = pcall(function() return loc2.X + 0 end)
        if okX then return loc2 end
    end
    return nil
end

local function GetPlayerIdentifier()
    local okPC, pc = pcall(function() return FindFirstOf("PlayerController") end)
    if okPC and pc and pc:IsValid() then
        local okPS, ps = pcall(function() return pc.PlayerState end)
        if okPS and ps and ps:IsValid() then
            local okName, pName = pcall(function() return ps:GetPlayerName() end)
            if okName and pName then
                local rawName = ""
                -- Unpack the UE4 FString object into a normal Lua string
                pcall(function()
                    if type(pName) == "userdata" and pName.ToString then
                        rawName = pName:ToString()
                    else
                        rawName = tostring(pName)
                    end
                end)
                
                -- Ensure we don't accidentally save the FString memory pointer
                if rawName ~= "" and not string.match(rawName, "^FString%s") then
                    local safeName = string.gsub(rawName, '[^%w%s_]', '')
                    if safeName ~= "" then
                        return safeName
                    end
                end
            end
        end
    end
    return "LocalPlayer"
end

-- Checks if the player is within a specific distance of ANY BuildingCenter (Camp)
local function IsPlayerNearCamp(maxDistance)
    local player = GetPlayerSafe()
    local pLoc = GetActorLoc(player)
    if not pLoc then 
        Log("Could not verify player location for camp proximity check.")
        return false, 999999999 
    end

    local bestDist = 999999999
    local ok, actors = pcall(function() return FindAllOf("Actor") end)
    if ok and actors then
        for _, actor in ipairs(actors) do
            if actor and actor:IsValid() then
                local okName, name = pcall(function() return actor:GetFullName() end)
                if okName and name then
                    local lowerName = string.lower(name)
                    if string.find(lowerName, "buildingcenter") then
                        local aLoc = GetActorLoc(actor)
                        if aLoc then
                            local dx = pLoc.X - aLoc.X
                            local dy = pLoc.Y - aLoc.Y
                            local dz = pLoc.Z - aLoc.Z
                            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                            if dist < bestDist then
                                bestDist = dist
                            end
                        end
                    end
                end
            end
        end
    end
    
    return (bestDist <= maxDistance), bestDist
end

-- Finds the ship physically closest to the player (so we save the right one if multiple exist)
local function GetClosestShipToPlayer()
    local player = GetPlayerSafe()
    local pLoc = GetActorLoc(player)
    if not pLoc then 
        Log("Could not find player location.")
        return nil 
    end

    local bestShip = nil
    local bestDist = 999999999

    local ok, pawns = pcall(function() return FindAllOf("Pawn") end)
    if not ok or not pawns then return nil end
    
    for _, pawn in ipairs(pawns) do
        if pawn and pawn:IsValid() then
            local okName, name = pcall(function() return pawn:GetFullName() end)
            if okName and name then
                local lowerName = string.lower(name)
                local isShip = string.find(lowerName, "ship") and not string.find(lowerName, "character")
                if isShip then
                    local sLoc = GetActorLoc(pawn)
                    if sLoc then
                        local dx = pLoc.X - sLoc.X
                        local dy = pLoc.Y - sLoc.Y
                        local dz = pLoc.Z - sLoc.Z
                        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                        if dist < bestDist then
                            bestDist = dist
                            bestShip = pawn
                        end
                    end
                end
            end
        end
    end
    
    -- 15000 units is approx 150 meters. Prevents saving ships halfway across the map.
    if bestShip and bestDist < 15000 then
        return bestShip
    end
    
    Log("No ship found close enough to the player.")
    return nil
end

-- ==========================================
-- DATA MANAGEMENT
-- ==========================================
local function GetSaveFilePath()
    return "ue4ss/Mods/DockMeBaby/DockMeBaby_SaveData.lua"
end

local function LoadDockData()
    local fileName = GetSaveFilePath()
    local file = io.open(fileName, "r")
    if not file then return {} end
    
    local content = file:read("*a")
    file:close()
    
    local chunk = load(content)
    if chunk then
        local ok, data = pcall(chunk)
        if ok and type(data) == "table" then
            return data
        end
    end
    return {}
end

local function SaveDockData(data)
    local fileName = GetSaveFilePath()
    local file = io.open(fileName, "w")
    
    if not file then
        Log("Error: Could not open " .. fileName .. " for writing.")
        return
    end
    
    -- Write proper nested Lua dictionary structure
    file:write("return {\n")
    for playerName, ships in pairs(data) do
        file:write(string.format('  ["%s"] = {\n', playerName))
        for shipClass, spots in pairs(ships) do
            file:write(string.format('    ["%s"] = {\n', shipClass))
            for i, coords in ipairs(spots) do
                file:write(string.format('      [%d] = { X = %f, Y = %f, Z = %f, Yaw = %f },\n', i, coords.X, coords.Y, coords.Z, coords.Yaw))
            end
            file:write("    },\n")
        end
        file:write("  },\n")
    end
    file:write("}\n")
    file:close()
    Log("Success! Saved multi-ship data to " .. fileName)
end

-- ==========================================
-- COMMANDS
-- ==========================================

-- Console Command: setdock
RegisterConsoleCommandHandler("setdock", function(FullCommand, Parameters, Ar)
    Log("Command 'setdock' triggered.")
    
    local ship = GetClosestShipToPlayer()
    if not ship then
        Log("Error: You must be near a ship to save its dock.")
        return true
    end

    local okName, name = pcall(function() return ship:GetFullName() end)
    local shipClass = string.match(name, "^([^%s]+)") or name
    local playerName = GetPlayerIdentifier()
    
    Log("Targeting Ship: " .. tostring(shipClass) .. " for Player: " .. playerName)

    local loc = GetActorLoc(ship)
    local okRot, rot = pcall(function() return ship:K2_GetActorRotation() end)
    
    if loc and okRot and rot then
        Log(string.format("Current Ship Transform -> X:%.2f, Y:%.2f, Z:%.2f, Yaw:%.2f", loc.X, loc.Y, loc.Z, rot.Yaw))
        
        local data = LoadDockData()
        if not data[playerName] then data[playerName] = {} end
        
        -- Auto-migrate old format if necessary
        if type(data[playerName][shipClass]) ~= "table" or data[playerName][shipClass].X then
            data[playerName][shipClass] = {} 
        end
        
        local spots = data[playerName][shipClass]
        local foundIdx = nil
        
        -- Check if we are adjusting an existing dock (within 1000 units / 10 meters)
        for i, coords in ipairs(spots) do
            local dx = loc.X - coords.X
            local dy = loc.Y - coords.Y
            local dz = loc.Z - coords.Z
            if math.sqrt(dx*dx + dy*dy + dz*dz) < 1000 then
                foundIdx = i
                break
            end
        end
        
        if foundIdx then
            spots[foundIdx] = { X = loc.X, Y = loc.Y, Z = loc.Z, Yaw = rot.Yaw }
            Log(string.format("Adjusted existing dock [%d] for %s.", foundIdx, shipClass))
        else
            table.insert(spots, { X = loc.X, Y = loc.Y, Z = loc.Z, Yaw = rot.Yaw })
            Log(string.format("Created new dock [%d] for %s.", #spots, shipClass))
        end
        
        SaveDockData(data)
    else
        Log("Error: Failed to read ship location or rotation.")
    end

    return true
end)

-- Console Command: dock
RegisterConsoleCommandHandler("dock", function(FullCommand, Parameters, Ar)
    Log("Command 'dock' triggered.")
    
    local playerName = GetPlayerIdentifier()
    local data = LoadDockData()
    
    if not data[playerName] then
        Log("Error: No saved docks found for player: " .. playerName)
        return true
    end
    
    -- Anti-Cheat: Check proximity to Camp (BuildingCenter)
    local maxAllowedDistance = 25000
    local isNear, currentDist = IsPlayerNearCamp(maxAllowedDistance)
    
    if not isNear then
        if currentDist == 999999999 then
            Log("Error: Could not find any Camp (BuildingCenter) in the world. You need a camp to dock.")
        else
            Log(string.format("Error: You are too far from your Camp to dock! (Distance: %.0f / %.0f)", currentDist, maxAllowedDistance))
        end
        return true
    end
    
    local ok, pawns = pcall(function() return FindAllOf("Pawn") end)
    if not ok or not pawns then return true end

    local dockedCount = 0
    local spotIndexTracker = {}
    for _, pawn in ipairs(pawns) do
        if pawn and pawn:IsValid() then
            local okName, name = pcall(function() return pawn:GetFullName() end)
            if okName and name then
                local lowerName = string.lower(name)
                local isShip = string.find(lowerName, "ship") and not string.find(lowerName, "character")
                if isShip then
                    local shipClass = string.match(name, "^([^%s]+)") or name
                    local spots = data[playerName][shipClass]
                    
                    if spots and type(spots) == "table" and not spots.X then
                        local currentIdx = spotIndexTracker[shipClass] or 1
                        local savedCoords = spots[currentIdx]
                        
                        if savedCoords then
                            local targetLoc = { X = savedCoords.X, Y = savedCoords.Y, Z = savedCoords.Z }
                            local targetRot = { Pitch = 0, Yaw = savedCoords.Yaw, Roll = 0 }
                            
                            pcall(function() pawn:K2_SetActorLocation(targetLoc, false, {}, true) end)
                            pcall(function() pawn:K2_SetActorRotation(targetRot, true) end)
                            
                            Log(string.format("Success! %s docked at spot [%d].", shipClass, currentIdx))
                            dockedCount = dockedCount + 1
                            spotIndexTracker[shipClass] = currentIdx + 1
                        end
                    end
                end
            end
        end
    end
    
    if dockedCount == 0 then
        Log("Error: Found saved data, but no matching active ships in the world.")
    end

    return true
end)

-- Entry point execution
Log("Mod initialized successfully.")
Log("Available console commands: setdock, dock")