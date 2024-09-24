
lib.addCommand('createproperty', {
    help = 'Create a property at your current location',
}, function(source)
    local player = exports.qbx_core:GetPlayer(source)

    if player.PlayerData.job.name ~= 'realestate' then exports.qbx_core:Notify(source, 'Not a realtor', 'error') return end

    TriggerClientEvent('qbx_properties:client:createProperty', source)
end)

RegisterNetEvent('qbx_properties:server:createProperty', function(interiorIndex, data, propertyCoords)
    local playerSource = source --[[@as number]]
    local player = exports.qbx_core:GetPlayer(playerSource)
    local playerCoords = GetEntityCoords(GetPlayerPed(playerSource))

    if player.PlayerData.job.name ~= 'realestate' then return end
    if #(playerCoords - propertyCoords) > 5.0 then return end

    local interactData = {
        {
            type = 'logout',
            coords = Interiors[interiorIndex].logout
        },
        {
            type = 'clothing',
            coords = Interiors[interiorIndex].clothing
        },
        {
            type = 'exit',
            coords = Interiors[interiorIndex].exit
        }
    }
    local stashData = {
        {
            coords = Interiors[interiorIndex].stash,
            slots = ApartmentStash.slots,
            maxWeight = ApartmentStash.maxWeight,
        }
    }
    local result = MySQL.single.await('SELECT id FROM appartments ORDER BY id DESC', {})
    local propertNumber = result?.id or 0
    MySQL.insert('INSERT INTO `appartments` (`coords`, `property_name`, `price`, `interior`, `interact_options`, `stash_options`, `rent_interval`) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        json.encode(propertyCoords),
        string.format('%s %s', data[1], propertNumber),
        data[2],
        interiorIndex,
        json.encode(interactData),
        json.encode(stashData),
        data[3]
    })
    TriggerClientEvent('qbx_properties:client:addProperty', -1, propertyCoords)
end)
