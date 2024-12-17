-- Add Trigger to Deduct Money
local function Transaction(source, price)
    if price and price < 1 then return true end

    local player  = exports.qbx_core:GetPlayer(playerId)
    if not player or not player.PlayerData.citizenid then 
        print('Not Player Found')
        return false 
    end

    local citizenid = player.PlayerData.citizenid

    local playerAccount = exports.ox_banking:GetCharacterAccount(citizenid)

    if not playerAccount then 
        print('Not Account Found')
        return false 
    end

    local accountId = playerAccount.accountId

    local response = exports.ox_banking:RemoveBalance(accountId, price, "Appartment Purchase", false)

    if response.success == true then 
        print('Paid Money')
        return true 
    end

    return false
end

RegisterNetEvent('qbx_properties:server:apartmentSelect', function(apartmentIndex)
    local playerSource = source --[[@as number]]
    local player = exports.qbx_core:GetPlayer(playerSource)
    if not ApartmentOptions[apartmentIndex] then return end

    local hasApartment = MySQL.single.await('SELECT * FROM appartments WHERE owner = ?', {player.PlayerData.citizenid})
    if hasApartment then 
        exports.qbx_core:Notify(playerSource, 'You already own an apartment.')
        return 
    end

    -- If Transaction  thenr return
    if not Transaction(playerSource, ApartmentOptions[apartmentIndex].price) then 
        exports.qbx_core:Notify(playerSource, 'Failed to pay for appartment.')
        --return 
    end

    local interior = ApartmentOptions[apartmentIndex].interior
    local interactData = {
        {
            type = 'logout',
            coords = Interiors[interior].logout
        },
        {
            type = 'clothing',
            coords = Interiors[interior].clothing
        },
        {
            type = 'exit',
            coords = Interiors[interior].exit
        }
    }
    local stashData = {
        {
            coords = Interiors[interior].stash,
            slots = ApartmentStash.slots,
            maxWeight = ApartmentStash.maxWeight,
        }
    }

    local result = MySQL.single.await('SELECT id FROM appartments ORDER BY id DESC')
    local apartmentNumber = result?.id or 0

    ::again::

    apartmentNumber += 1
    local numberExists = MySQL.single.await('SELECT * FROM appartments WHERE property_name = ?', {string.format('%s %s', ApartmentOptions[apartmentIndex].label, apartmentNumber)})
    if numberExists then goto again end

    local id = MySQL.insert.await('INSERT INTO `appartments` (`coords`, `property_name`, `owner`, `interior`, `interact_options`, `stash_options`) VALUES (?, ?, ?, ?, ?, ?)', {
        json.encode(ApartmentOptions[apartmentIndex].enter),
        string.format('%s %s', ApartmentOptions[apartmentIndex].label, apartmentNumber),
        player.PlayerData.citizenid,
        interior,
        json.encode(interactData),
        json.encode(stashData),
    })

    TriggerClientEvent('qbx_properties:client:addProperty', -1, ApartmentOptions[apartmentIndex].enter)
    EnterProperty(playerSource, id, true)
end)


-- Load SpawnCoords for locator

--[[

local properties = lib.callback.await('qbx_properties:client:spawnSelectorCoords', false)

for i=1, #properties do
    local coords = json.decode(properties[i].coords)
    table.insert(SpawnLocation, {
        name = properties[i].property_name,
        mapCoords = {x = coords.x, y = coords.y},
        locationType = 'apartment',
        gameCoords = vec4(coords.x, coords.y, coords.z, 0.0),
        propertyId = properties[i].id
    })
end

-- Event To Trigger On Spawn Event (Make Sure data has locationType, id available in it)
if data.locationType == 'apartment' then
    TriggerServerEvent('qbx_properties:server:enterProperty', {id = data.id, isSpawn = true})
end

]]--