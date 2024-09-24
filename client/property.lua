local interiorShell
DecorationObjects = {}
local properties = {}
local insideProperty = false
local isPropertyRental = false
local interactions
local isConcealing = false
local concealWhitelist = {}
local blips = {}

local function prepareKeyMenu()
    local keyholders = lib.callback.await('qbx_properties:callback:requestKeyHolders')
    local options = {
        {
            title = locale('menu.add_keyholder'),
            icon = 'plus',
            arrow = true,
            onSelect = function()
                local insidePlayers = lib.callback.await('qbx_properties:callback:requestPotentialKeyholders')
                local options = {}
                for i = 1, #insidePlayers do
                    options[#options + 1] = {
                        title = insidePlayers[i].name,
                        icon = 'user',
                        arrow = true,
                        onSelect = function()
                            local alert = lib.alertDialog({
                                header = insidePlayers[i].name,
                                content = locale('alert.give_keys'),
                                centered = true,
                                cancel = true
                            })
                            if alert == 'confirm' then
                                TriggerServerEvent('qbx_properties:server:addKeyholder', insidePlayers[i].citizenid)
                            end
                        end
                    }
                end
                lib.registerContext({
                    id = 'qbx_properties_insideMenu',
                    title = locale('menu.people_inside'),
                    menu = 'qbx_properties_keyMenu',
                    options = options
                })
                lib.showContext('qbx_properties_insideMenu')
            end
        }
    }
    for i = 1, #keyholders do
        options[#options + 1] = {
            title = keyholders[i].name,
            icon = 'user',
            arrow = true,
            onSelect = function()
                local alert = lib.alertDialog({
                    header = keyholders[i].name,
                    content = locale('alert.want_remove_keys'),
                    centered = true,
                    cancel = true
                })
                if alert == 'confirm' then
                    TriggerServerEvent('qbx_properties:server:removeKeyholder', keyholders[i].citizenid)
                end
            end
        }
    end
    lib.registerContext({
        id = 'qbx_properties_keyMenu',
        title = locale('menu.keyholders'),
        menu = 'qbx_properties_manageMenu',
        options = options
    })
    lib.showContext('qbx_properties_keyMenu')
end

local function prepareDoorbellMenu()
    local ringers = lib.callback.await('qbx_properties:callback:requestRingers')
    local options = {}
    for i = 1, #ringers do
        options[#options + 1] = {
            title = ringers[i].name,
            icon = 'user',
            arrow = true,
            onSelect = function()
                local alert = lib.alertDialog({
                    header = ringers[i].name,
                    content = locale('alert.want_let_person_in'),
                    centered = true,
                    cancel = true
                })
                if alert == 'confirm' then
                    TriggerServerEvent('qbx_properties:server:letRingerIn', ringers[i].citizenid)
                end
            end
        }
    end
    lib.registerContext({
        id = 'qbx_properties_doorbellMenu',
        title = locale('menu.doorbell_ringers'),
        menu = 'qbx_properties_manageMenu',
        options = options
    })
    lib.showContext('qbx_properties_doorbellMenu')
end

local function prepareManageMenu()
    local hasAccess = lib.callback.await('qbx_properties:callback:checkAccess')
    if not hasAccess then exports.qbx_core:Notify(locale('notify.no_access'), 'error') return end
    local options = {
        {
            title = locale('menu.manage_keys'),
            icon = 'key',
            arrow = true,
            onSelect = function()
                prepareKeyMenu()
            end
        },
        {
            title = locale('menu.doorbell'),
            icon = 'bell',
            arrow = true,
            onSelect = function()
                prepareDoorbellMenu()
            end
        },
        {
            title = locale('menu.start_decorating'),
            icon = 'shrimp',
            onSelect = function()
                ToggleDecorating()
            end
        }
    }
    if isPropertyRental then
        options[#options+1] = {
            title = 'Stop Renting',
            icon = 'file-invoice-dollar',
            arrow = true,
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Stop Renting',
                    content = 'Are you sure that you want to stop renting this place?',
                    centered = true,
                    cancel = true
                })
                if alert == 'confirm' then
                    TriggerServerEvent('qbx_properties:server:stopRenting')
                end
            end
        }
    end
    lib.registerContext({
        id = 'qbx_properties_manageMenu',
        title = locale('menu.manage_property'),
        options = options
    })
    lib.showContext('qbx_properties_manageMenu')
end

local function checkInteractions()
    local interactOptions = {
        ['stash'] = function(coords)
            qbx.drawText3d({ coords = coords, text = locale('drawtext.stash') })
            if IsControlJustPressed(0, 38) then
                TriggerServerEvent('qbx_properties:server:openStash')
            end
        end,
        ['exit'] = function(coords)
            qbx.drawText3d({ coords = coords, text = locale('drawtext.exit') })
            if IsControlJustPressed(0, 38) then
                DoScreenFadeOut(1000)
                while not IsScreenFadedOut() do Wait(0) end
                TriggerServerEvent('qbx_properties:server:exitProperty')
            end
            if IsControlJustPressed(0, 47) then
                prepareManageMenu()
            end
        end,
        ['clothing'] = function(coords)
            qbx.drawText3d({ coords = coords, text = locale('drawtext.clothing') })
            if IsControlJustPressed(0, 38) then
                exports['illenium-appearance']:startPlayerCustomization(function(appearance)
                    if appearance then
                        TriggerServerEvent("illenium-appearance:server:saveAppearance", appearance)
                    end
                end, {
                    components = true, componentConfig = { masks = true, upperBody = true, lowerBody = true, bags = true, shoes = true, scarfAndChains = true, bodyArmor = true, shirts = true, decals = true, jackets = true },
                    props = true, propConfig = { hats = true, glasses = true, ear = true, watches = true, bracelets = true },
                    enableExit = true,
                })
            end
            if IsControlJustPressed(0, 47) then
                TriggerEvent('illenium-appearance:client:openOutfitMenu')
            end
        end,
        ['logout'] = function(coords)
            qbx.drawText3d({ coords = coords, text = locale('drawtext.logout') })
            if IsControlJustPressed(0, 38) then
                DoScreenFadeOut(1000)
                while not IsScreenFadedOut() do Wait(0) end
                TriggerServerEvent('qbx_properties:server:logoutProperty')
            end
        end,
    }
    CreateThread(function()
        while insideProperty do
            local sleep = 800
            local playerCoords = GetEntityCoords(cache.ped)
            for i = 1, #interactions do
                if #(playerCoords - interactions[i].coords) < 1.5 and not IsDecorating then
                    sleep = 0
                    interactOptions[interactions[i].type](interactions[i].coords)
                end
            end
            Wait(sleep)
        end
    end)
end

RegisterNetEvent('qbx_properties:client:updateInteractions', function(interactionsData, isRental)
    DoScreenFadeIn(1000)
    interactions = interactionsData
    insideProperty = true
    isPropertyRental = isRental
    checkInteractions()
end)

RegisterNetEvent('qbx_properties:client:createInterior', function(interiorHash, interiorCoords)
    lib.requestModel(interiorHash, 2000)
    interiorShell = CreateObjectNoOffset(interiorHash, interiorCoords.x, interiorCoords.y, interiorCoords.z, false, false, false)
    FreezeEntityPosition(interiorShell, true)
    SetModelAsNoLongerNeeded(interiorHash)
end)

RegisterNetEvent('qbx_properties:client:loadDecorations', function(decorations)
    for i = 1, #decorations do
        local decoration = decorations[i]
        lib.requestModel(decoration.model, 5000)
        DecorationObjects[decoration.id] = CreateObjectNoOffset(decoration.model, decoration.coords.x, decoration.coords.y, decoration.coords.z, false, false, false)
        SetEntityCollision(DecorationObjects[decoration.id], true, true)
        FreezeEntityPosition(DecorationObjects[decoration.id], true)
        SetEntityRotation(DecorationObjects[decoration.id], decoration.rotation.x, decoration.rotation.y, decoration.rotation.z, 2, false)
        SetModelAsNoLongerNeeded(decoration.model)
    end
end)

RegisterNetEvent('qbx_properties:client:addDecoration', function(id, hash, coords, rotation)
    lib.requestModel(hash, 5000)
    DecorationObjects[id] = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
    FreezeEntityPosition(DecorationObjects[id], true)
    SetEntityRotation(DecorationObjects[id], rotation.x, rotation.y, rotation.z, 2, false)
    SetModelAsNoLongerNeeded(hash)
end)

RegisterNetEvent('qbx_properties:client:removeDecoration', function(objectId)
    if DoesEntityExist(DecorationObjects[objectId]) then DeleteEntity(DecorationObjects[objectId]) end
    DecorationObjects[objectId] = nil
end)

RegisterNetEvent('qbx_properties:client:unloadProperty', function()
    DoScreenFadeIn(1000)
    insideProperty = false
    if DoesEntityExist(interiorShell) then DeleteEntity(interiorShell) end
    for _, v in pairs(DecorationObjects) do
        if DoesEntityExist(v) then DeleteEntity(v) end
    end
    interiorShell = nil
    DecorationObjects = {}
end)

local function singlePropertyMenu(property, noBackMenu)
    local options = {}
    if QBX.PlayerData.citizenid == property.owner or lib.table.contains(json.decode(property.keyholders), QBX.PlayerData.citizenid) then
        options[#options + 1] = {
            title = locale('menu.enter'),
            icon = 'cog',
            arrow = true,
            onSelect = function()
                DoScreenFadeOut(1000)
                while not IsScreenFadedOut() do 
                    Wait(0) 
                end
            end,
            serverEvent = 'qbx_properties:server:enterProperty',
            args = { id = property.id }
        }
    elseif property.owner == nil then
        if property.rent_interval then
            options[#options + 1] = {
                title = 'Rent',
                icon = 'dollar-sign',
                arrow = true,
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = string.format('Renting - %s', property.property_name),
                        content = string.format('Are you sure you want to rent %s for $%s which will be billed every %sh(s)?', property.property_name, property.price, property.rent_interval),
                        centered = true,
                        cancel = true
                    })
                    if alert == 'confirm' then
                        TriggerServerEvent('qbx_properties:server:rentProperty', property.id)
                    end
                end,
            }
        else
            options[#options + 1] = {
                title = 'Buy',
                icon = 'dollar-sign',
                arrow = true,
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = string.format('Buying - %s', property.property_name),
                        content = string.format('Are you sure you want to buy %s for $%s?', property.property_name, property.price),
                        centered = true,
                        cancel = true
                    })
                    if alert == 'confirm' then
                        TriggerServerEvent('qbx_properties:server:buyProperty', property.id)
                    end
                end,
            }
        end
    else
        options[#options + 1] = {
            title = locale('menu.ring_doorbell'),
            icon = 'bell',
            arrow = true,
            serverEvent = 'qbx_properties:server:ringProperty',
            args = { id = property.id }
        }
    end
    local menu = 'qbx_properties_propertiesMenu'
    ---@diagnostic disable-next-line: cast-local-type
    if noBackMenu then menu = nil end
    lib.registerContext({
        id = 'qbx_properties_propertyMenu',
        title = property.property_name,
        menu = menu,
        options = options
    })
    lib.showContext('qbx_properties_propertyMenu')
end

local function propertyMenu(propertyList, owned)
    local options = {
        {
            title = locale('menu.retrieve_properties'),
            description = locale('menu.show_owned_properties'),
            icon = 'bars',
            onSelect = function()
                propertyMenu(propertyList, true)
            end
        }
    }
    for i = 1, #propertyList do
        if owned and propertyList[i].owner == QBX.PlayerData.citizenid or lib.table.contains(json.decode(propertyList[i].keyholders), QBX.PlayerData.citizenid) then
            options[#options + 1] = {
                title = propertyList[i].property_name,
                icon = 'home',
                arrow = true,
                onSelect = function()
                    singlePropertyMenu(propertyList[i])
                end
            }
        elseif not owned then
            options[#options + 1] = {
                title = propertyList[i].property_name,
                icon = 'home',
                arrow = true,
                onSelect = function()
                    singlePropertyMenu(propertyList[i])
                end
            }
        end
    end
    lib.registerContext({
        id = 'qbx_properties_propertiesMenu',
        title = locale('menu.properties'),
        options = options
    })
    lib.showContext('qbx_properties_propertiesMenu')
end

function PreparePropertyMenu(propertyCoords)
    local propertyList = lib.callback.await('qbx_properties:callback:requestProperties', false, propertyCoords)
    if #propertyList == 1 then
        singlePropertyMenu(propertyList[1], true)
    else
        propertyMenu(propertyList)
    end
end

local points = {}

CreateThread(function()
    for i = 1, #ApartmentOptions do
        local data = ApartmentOptions[i]

        if not blips[data.enter] then
            blips[data.enter] = CreateBlip(data.enter, data.label, 40)
        end

        local apartPoint = lib.points.new({
            coords = data.buy.coords,
            distance = 10,
        })

        function apartPoint:onEnter()
            lib.requestModel(data.buy.model, 10000)

            data.buy.ped = CreatePed(0, data.buy.model, data.buy.coords.x, data.buy.coords.y, data.buy.coords.z-1, data.buy.coords.w, false, false)
            SetModelAsNoLongerNeeded(data.buy.model)

            TaskStartScenarioInPlace(data.buy.ped, 'PROP_HUMAN_STAND_IMPATIENT', 0, true)
            FreezeEntityPosition(data.buy.ped, true)
            SetEntityInvincible(data.buy.ped, true)
            SetBlockingOfNonTemporaryEvents(data.buy.ped, true)
            exports.ox_target:addLocalEntity(data.buy.ped, {
                {
                    label = "Buy Appartment",
                    distance = 5,
                    onSelect = function()
                        TriggerServerEvent('qbx_properties:server:apartmentSelect', i)
                    end,
                },
            })
        end

        function apartPoint:onExit()
            exports.ox_target:removeLocalEntity(data.buy.ped)
            if DoesEntityExist(data.buy.ped) then
                DeletePed(data.buy.ped)
            end
            data.buy.ped = nil
        end

        points[#points + 1] = apartPoint
    end

    properties = lib.callback.await('qbx_properties:callback:loadProperties')
    while true do
        local sleep = 800
        local playerCoords = GetEntityCoords(cache.ped)
        for i = 1, #properties do
            if #(playerCoords - properties[i].xyz) < 1.6 then
                sleep = 0
                qbx.drawText3d({ coords = properties[i].xyz, text = locale('drawtext.view_property') })
                if IsControlJustPressed(0, 38) then
                    PreparePropertyMenu(properties[i])
                end
                if IsControlJustPressed(0, 182) then
                    accessGarageMenu(properties[i])
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() == resource then
        for i=1, #points do
            points[i]:remove()
        end
    end
end)

RegisterNetEvent('qbx_properties:client:concealPlayers', function(playerIds)
    local players = GetActivePlayers()
    for i = 1, #players do NetworkConcealPlayer(players[i], false, false) end
    concealWhitelist = playerIds
    if not isConcealing then
        isConcealing = true
        while isConcealing do
            players = GetActivePlayers()
            for i = 1, #players do
                if not lib.table.contains(concealWhitelist, GetPlayerServerId(players[i])) then
                    NetworkConcealPlayer(players[i], true, false)
                end
            end
            Wait(3000)
        end
    end
end)

RegisterNetEvent('qbx_properties:client:revealPlayers', function()
    local players = GetActivePlayers()
    for i = 1, #players do NetworkConcealPlayer(players[i], false, false) end
    isConcealing = false
end)

RegisterNetEvent('qbx_properties:client:addProperty', function(propertyCoords)
    if lib.table.contains(properties, propertyCoords) then return end
    properties[#properties + 1] = propertyCoords
end)

------------------------------------------------------
-----------GARAGE MODIFICATION------------------------
------------------------------------------------------
function accessGarageMenu(appartCoords)
    -- Send coords to server and retrieve properties with access
    local accessProperties = lib.callback.await('qbx_properties:server:fetchPropertiesForGarage', false, appartCoords)

    if #accessProperties < 1 then 
        exports.qbx_core:Notify(locale('notify.no_access'), 'error')
        return
    end

    local options = {}
    for i=1, #accessProperties do
        options[#options + 1] = {
            title = accessProperties[i].property_name,
            icon = 'home',
            arrow = true,
            onSelect = function()
                -- Store Vehicle
                if not cache.vehicle then 
                    enterAppartmentGarage("apartment:"..accessProperties[i].id)
                    return 
                end

                parkVehicle("apartment:"..accessProperties[i].id)
            end
        }    
    end

    lib.registerContext({
        id = 'qbx_properties_accessGarageMenu',
        title = 'Garage',
        options = options
    })

    lib.showContext('qbx_properties_accessGarageMenu')
end

local garagePoints = {}

CreateThread(function()
    -- Register points for dropoff
    -- Based on point show a ui [E] Access Garage
    -- Access Garage has properties listed based on user access (keyholder + owner)
    -- On Property Select, car gets stored to property garage based on available slots
    -- Register points for dropoff
    -- Based on point show a ui [E] Access Garage
    -- Access Garage has properties listed based on user access (keyholder + owner)
    -- On Property Select, car gets stored to property garage based on available slots

    local point = lib.points.new({
        coords = vec3(532.1072, -2637.6689, -48.9999),
        distance = 2
    })

    function point:onEnter()
        lib.showTextUI('[E] Exit Garage', {
            position = 'right-center'
        })
    end

    function point:onExit()
        lib.hideTextUI()
    end

    function point:nearby()
        if IsControlJustPressed(0, 38) then
            ExitGarage()
        end
    end

    for i = 1, #Garages do
        if not blips[Garages[i].dropOff] then
            blips[Garages[i].dropOff] = CreateBlip(Garages[i].dropOff, "Appartment Garage", 225)
        end
        
        local point = lib.points.new({
            coords = Garages[i].dropOff,
            distance = 5
        })

        function point:onEnter()
            lib.showTextUI('[E] Access Garages', {
                position = 'right-center'
            })
        end

        function point:onExit()
            lib.hideTextUI()
        end

        function point:nearby()
            if IsControlJustPressed(0, 38) then
                for j=1, #properties do
                    if #(Garages[i].appartmentCoords - properties[j]) < 1.0 then
                        accessGarageMenu(properties[j], Garages[i].spawn)
                    end
                end
            end
        end

        garagePoints[#garagePoints + 1] = point
    end
end)

-- Exit Garage From Elevator
function ExitGarage()
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do Wait(0) end

    lib.callback.await('qbx_properties:server:exitGarageElevator', false)
    
    DoScreenFadeIn(1000)
end