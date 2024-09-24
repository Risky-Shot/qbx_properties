local garageData = {}

-- Setup Garages in Runtime For Parking so that anyone can park the car ? Is it needed though
CreateThread(function()
    local result = MySQL.query.await('SELECT id FROM appartments')

    for i = 1, #result do
        exports.qbx_garages:RegisterGarage("apartment:"..result[i].id, {
            label = "Apparment Garage"..result[i].id,
            vehicleType = 'car',
            accessPoints = {},
            shared = true
        })
    end
end)

local function isKeyholderToAppartment(citizenId, garageId)
    local appartmentId = tonumber(garageId:match(":(%d+)"))
    local property = MySQL.single.await('SELECT owner , keyholders FROM appartments WHERE id = ?', {appartmentId})

    if citizenId == property.owner then return true end

    local keyholders = json.decode(property.keyholders)
    for i = 1, #keyholders do
        if citizenId == keyholders[i] then return true end
    end

    return false
end

lib.callback.register('qbx_properties:server:enterGarage', function(source, garageId)
    -- HardCoded For Now
    local garageCoords = vec4(532.1072, -2637.6689, -48.9999, 91.4480)

    SetEntityCoords(GetPlayerPed(source), garageCoords.x, garageCoords.y, garageCoords.z, false, false, false, false)
    SetEntityHeading(GetPlayerPed(source), garageCoords.w)

    Player(source).state:set('currentApartGarage', garageId, true)
end)

lib.callback.register('qbx_properties:server:fetchPropertiesForGarage', function(source, coords)
    local player = exports.qbx_core:GetPlayer(source)
    local properties = MySQL.query.await('SELECT property_name, owner, id, price, rent_interval, keyholders FROM appartments WHERE coords = ?', {json.encode(coords)})
    
    local propertyData = {}
    for i = 1, #properties do
        if properties[i].owner == player.PlayerData.citizenid then
            propertyData[#propertyData + 1] = properties[i]
        else
            local keyholders = json.decode(properties[i].keyholders)
            for j = 1, #keyholders do
                if keyholders[j] == player.PlayerData.citizenid then 
                    propertyData[#propertyData + 1] = properties[i]
                end
            end
        end
    end

    return propertyData
end)

-- Spawn Cars For Garage
local function SpawnGarageCars(garageId)
    local filters = {
        garage = garageId,
        states = 1
    }

    local vehicles = exports.qbx_vehicles:GetPlayerVehicles(filters)

    local bucket = 1000 + tonumber(garageId:match(":(%d+)"))

    -- Initialise GarageData Table if not present
    if not garageData[garageId] then
        garageData[garageId] = {}
    end
    

    for i = 1, #vehicles do
        local vehData = vehicles[i]

        -- Spawn if vehicle not present in garage bucket
        if garageData[garageId][tostring(vehData.id)] == nil then
            local params = {
                model = joaat(vehData.modelName),
                -- Fix Spawn Location
                spawnSource = GarageCarSpawn[i],
                --bucket = bucket,
                props = vehData.props
            }

            local netId, veh = qbx.spawnVehicle(params)

            FreezeEntityPosition(veh, true)

            garageData[garageId][tostring(vehData.id)] = netId

            Entity(veh).state.vehId = vehData.id

            exports.qbx_core:SetEntityBucket(veh, bucket)
        end
    end

    -- Transition Vehicle to bucket ? maybe do in upper loop itself
    -- for _, value in pairs(garageData[garageId]) do
    --     local vehicle = NetworkGetEntityFromNetworkId(value)
    --     -- Check if entity not in bucket ? then set in bucket else skip
    --     exports.qbx_core:SetEntityBucket(vehicle, bucket)
    -- end
end


lib.callback.register('qbx_properties:server:fetchGarageCars', function(source, garageId)
    local _source = source

    SpawnGarageCars(garageId)

    local bucket = 1000 + tonumber(garageId:match(":(%d+)"))

    exports.qbx_core:SetPlayerBucket(_source, bucket)
end)

RegisterCommand("apartcheck", function(source, _)
    -- local filters = {
    --     garage = garageId,
    --     states = 1
    -- }

    -- local vehicles = exports.qbx_vehicles:GetPlayerVehicles(filters)

    -- for i = 1, #vehicles do
    --     local vehData = vehicles[i]
        
    --     local params = {
    --         model = joaat("sc1"),
    --         spawnSource = GarageCarSpawn[i],
    --         bucket = 0,
    --         props = vehData.props
    --     }

    --     local netId, veh = qbx.spawnVehicle(params)

    --     print('Created Vehicle')
    --     print('-------------------------------------------')
    --     print(NetworkGetEntityFromNetworkId(netId), veh)
    --     FreezeEntityPosition(veh, true)

    --     print(vehData.id)

    --     Entity(veh).state.vehId = vehData.id
    -- end
    print(json.encode(garageData))
end)


RegisterServerEvent('baseevents:enteredVehicle', function(veh, seat, modelName, netId)
    local _source = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local vehId = Entity(vehicle).state.vehId

    if not vehId then return end
    if seat ~= -1 then return end

    local success = lib.callback.await('qbx_properties:client:garageOutProgress', source)

    print(success == true and "Take Out" or "Cancelled")

    if not success then return end

    -- remove netId from garageData
    local currentGarage = Player(source).state.currentApartGarage 
    local player = exports.qbx_core:GetPlayer(_source)

    local canTakeOut = isKeyholderToAppartment(player.PlayerData.citizenid, currentGarage)

    if not canTakeOut then 
        print('Cannot Take Out Car as not owned')
        return 
    end

    -- Remove Car From GarageData and Delete From Bucket
    -- for i = 1, #garageData[currentGarage] do
    --     if garageData[currentGarage][i] == netId then
    --         table.remove(garageData[currentGarage], i)
    --     end
    -- end
    if garageData[currentGarage][tostring(vehId)] == nil then return end

    garageData[currentGarage][tostring(vehId)] = nil
    DeleteEntity(vehicle)  
    -- for key, value in pairs(garageData[currentGarage]) do
    --     if value == netId then
    --         garageData[currentGarage][key] = nil
    --         DeleteEntity(vehicle)  
    --     end
    -- end
    
    -- Change Player Bucket Back to 0
    exports.qbx_core:SetPlayerBucket(_source, 0)

    TriggerClientEvent("qbx_properties:client:exitGarageStart", _source, vehId)
end)

RegisterServerEvent('baseevents:leftVehicle', function(veh, seat, modelName, netId)

end)

lib.callback.register('qbx_properties:server:exitGarageFinish', function(source, vehId)
    local _source = source

    local currentGarage = Player(source).state.currentApartGarage
    local appartmentId = tonumber(currentGarage:match(":(%d+)"))
    local result = MySQL.single.await('SELECT coords FROM appartments WHERE id = ?', {appartmentId})

    local minDist = 99999999999999

    local appartmentCoords = json.decode(result.coords)

    local nearestSpawnCoords = nil

    for i = 1, #Garages do
        local spawn = Garages[i].spawn
        for j = 1, #spawn do

            local dist = #(vector3(spawn[j].x, spawn[j].y, spawn[j].z) - vector3(appartmentCoords.x, appartmentCoords.y, appartmentCoords.z))

            if dist < minDist then
                minDist = dist
                nearestSpawnCoords = Garages[i].spawn
            end
        end
    end

    local spawnCoords = nearestSpawnCoords[math.random(1, #nearestSpawnCoords)]

    -- Teleport Player to SpawnCoord
    SetEntityCoords(GetPlayerPed(_source), spawnCoords.x, spawnCoords.y, spawnCoords.z)  

    local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehId)

    local params = {
        model = playerVehicle.props.model,
        spawnSource = spawnCoords,
        bucket = 0,
        props = playerVehicle.props,
        warp = GetPlayerPed(_source)
    }

    local netId, veh = qbx.spawnVehicle(params)

    SetVehicleDoorsLocked(veh, 2)

    TriggerClientEvent('vehiclekeys:client:SetOwner', _source, playerVehicle.props.plate)

    Entity(veh).state:set('vehicleid', vehId, false)

    exports.qbx_vehicles:SaveVehicle(veh, {
        state = 0
    })

    -- Event Handler For garage script
    TriggerEvent('qbx_garages:server:vehicleSpawned', veh)

    Player(_source).state:set('currentApartGarage', nil, true)

    --TriggerClientEvent("qbx_properties:client:exitGarageFinished", _source)
    return 
end)

----------------------------------------
------------PARKING CARS----------------
----------------------------------------

VEHICLES = exports.qbx_core:GetVehiclesByName()

local function canParkThisType(playerVehicle)
    if VEHICLES[playerVehicle.modelName].category == 'helicopters' or VEHICLES[playerVehicle.modelName].category == 'planes' then
        return false
    elseif VEHICLES[playerVehicle.modelName].category == 'boats' then
        return false
    else
        return true
    end
end

lib.callback.register('qbx_properties:server:isParkable', function(source, netId, garage)
    local player = exports.qbx_core:GetPlayer(source)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local vehicleId = Entity(vehicle).state.vehicleid or exports.qbx_vehicles:GetVehicleIdByPlate(GetVehicleNumberPlateText(vehicle))


    if not vehicleId then return false end

    local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)

    -- Check if Vehicle Type is Car
    if not canParkThisType(playerVehicle) then return false end

    -- Check if vehicle is owned by player
    local isPlayerOwned = playerVehicle.citizenid == player.PlayerData.citizenid and true or false

    local filters = {
        garage = garage,
        states = 1
    }

    local vehicles = exports.qbx_vehicles:GetPlayerVehicles(filters)

    -- No Space to Save More Cars
    if #vehicles >= MaxCarsInGarage then return false end

    if isPlayerOwned then
        return true
    elseif playerVehicle.garage == garage then
        return true
    end
    
    return false
end)

lib.callback.register('qbx_properties:server:parkVehicle', function(source, netId, props, garage)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local vehicleId = Entity(vehicle).state.vehicleid or exports.qbx_vehicles:GetVehicleIdByPlate(GetVehicleNumberPlateText(vehicle))

    if not vehicleId then return false end

    local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
    
    exports.qbx_vehicles:SaveVehicle(vehicle, {
        garage = garage,
        state = 1,
        props = props
    })

    DeleteEntity(vehicle)
    return true
end)

-- Refactor Code A bit
lib.callback.register('qbx_properties:server:exitGarageElevator', function(source)
    local _source = source
    local currentGarage = Player(_source).state.currentApartGarage

    if currentGarage == nil then
        local player = exports.qbx_core:GetPlayer(_source)
        local citizenid = player.PlayerData.citizenid

        local enterCoords = json.decode(MySQL.single.await('SELECT coords FROM appartments WHERE owner = ?', {citizenid}).coords)

        Player(_source).state:set('currentApartGarage', nil, true)
        exports.qbx_core:SetPlayerBucket(_source, 0)

        SetEntityCoords(GetPlayerPed(_source), enterCoords.x, enterCoords.y, enterCoords.z, false, false, false, false)
    else
        local appartmentId = tonumber(currentGarage:match(":(%d+)"))
        local enterCoords = json.decode(MySQL.single.await('SELECT coords FROM appartments WHERE id = ?', {appartmentId}).coords)

        -- Remove From Bucket
        Player(_source).state:set('currentApartGarage', nil, true)
        exports.qbx_core:SetPlayerBucket(_source, 0)

        SetEntityCoords(GetPlayerPed(_source), enterCoords.x, enterCoords.y, enterCoords.z, false, false, false, false)
    end
end)
