function enterAppartmentGarage(garageId)
    -- Fadeout Here
    lib.callback.await('qbx_properties:server:enterGarage', false, garageId)
    Wait(2000) -- Wait for Proper Bucket Transition
    lib.callback.await('qbx_properties:server:fetchGarageCars', false, garageId)
end

lib.callback.register("qbx_properties:client:garageOutProgress", function()
    return lib.progressCircle({
        duration = 5000,
        label = "Wait or [X] to Cancel",
        useWhileDead = false,
        canCancel = true,
        disable = {}
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() == resource then

    end
end)

RegisterNetEvent("qbx_properties:client:exitGarageStart", function(vehId)
    -- Blackout Start Here
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do Wait(0) end
    -- callback to teleport out at spawn locations from server based on apartment
    local spawnCoords = lib.callback.await('qbx_properties:server:exitGarageFinish', false, vehId)
    DoScreenFadeIn(1000)
end)

------
---PARK
------
local function kickOutPeds(vehicle)
    for i = -1, 5, 1 do
        local seat = GetPedInVehicleSeat(vehicle, i)
        if seat then
            TaskLeaveVehicle(seat, vehicle, 1)
        end
    end
end

function parkVehicle(garageId)
    if GetVehicleNumberOfPassengers(cache.vehicle) ~= 1 then
        local canPark = lib.callback.await('qbx_properties:server:isParkable', false, NetworkGetNetworkIdFromEntity(cache.vehicle), garageId)
        if not canPark then 
            exports.qbx_core:Notify("This vehicle can't be stored", 'error', 5000)
            return 
        end

        TaskLeaveVehicle(-1, cache.vehicle, 1)

        Wait(1000)

        lib.callback.await('qbx_properties:server:parkVehicle', false, NetworkGetNetworkIdFromEntity(cache.vehicle), lib.getVehicleProperties(cache.vehicle), garageId)
        exports.qbx_core:Notify("Vehicle Stored", 'primary', 4500)
    else
        exports.qbx_core:Notify("You can't store this vehicle as it is not empty", 'error', 3500)
    end
end      