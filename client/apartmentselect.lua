--[[
local BoardCoords = vec4(-44.19, -585.99, 87.71, 250.0)
local BoardModel = `tr_prop_tr_planning_board_01a`
local RenderTarget = 'modgarage_01'
local Board, scaleform, buttonsScaleform, currentButtonID = nil, 0, 0, 1
local previewCam

local function SetupBoard()
    lib.requestModel(BoardModel, 10000)
    Board = CreateObject(BoardModel, BoardCoords.x, BoardCoords.y, BoardCoords.z, false, false, false)
    SetEntityHeading(Board, BoardCoords.w)
    SetModelAsNoLongerNeeded(BoardModel)
end

local function SetupInstructionalButton(index, control, text)
    BeginScaleformMovieMethod(buttonsScaleform, 'SET_DATA_SLOT')

    ScaleformMovieMethodAddParamInt(index)

    ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(2, control, true))

    BeginTextCommandScaleformString('STRING')
    AddTextComponentSubstringKeyboardDisplay(text)
    EndTextCommandScaleformString()

    EndScaleformMovieMethod()
end

local function SetupInstructionalScaleform()
    DrawScaleformMovieFullscreen(buttonsScaleform, 255, 255, 255, 0, 0)

    BeginScaleformMovieMethod(buttonsScaleform, 'CLEAR_ALL')
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(buttonsScaleform, 'SET_CLEAR_SPACE')
    ScaleformMovieMethodAddParamInt(200)
    EndScaleformMovieMethod()

    SetupInstructionalButton(0, 191, locale('instructButtons.submit'))
    SetupInstructionalButton(1, 187, locale('instructButtons.down'))
    SetupInstructionalButton(2, 188, locale('instructButtons.up'))

    BeginScaleformMovieMethod(buttonsScaleform, 'DRAW_INSTRUCTIONAL_BUTTONS')
    EndScaleformMovieMethod()
end

local function CreateNamedRenderTargetForModel(name, model)
	local handle = 0
	if not IsNamedRendertargetRegistered(name) then
		RegisterNamedRendertarget(name, false)
	end

	if not IsNamedRendertargetLinked(model) then
		LinkNamedRendertarget(model)
	end

	if IsNamedRendertargetRegistered(name) then
		handle = GetNamedRendertargetRenderId(name)
	end

	return handle
end

local function StartScaleform()
    scaleform = lib.requestScaleformMovie('AUTO_SHOP_BOARD', 10000) or 0
    buttonsScaleform = lib.requestScaleformMovie('INSTRUCTIONAL_BUTTONS', 10000) or 0
    CreateThread(function()
        SetupInstructionalScaleform()
        while DoesCamExist(previewCam) do
            local Handle = CreateNamedRenderTargetForModel(RenderTarget, BoardModel)
            SetTextRenderId(Handle)
            SetScriptGfxDrawBehindPausemenu(true)
            SetScaleformFitRendertarget(scaleform, true)
            DrawScaleformMovie(scaleform, 0.25, 0.5, 0.5, 1.0, 255, 255, 255, 255, 0)
            SetTextRenderId(1)
            HideHudComponentThisFrame(6)
            HideHudComponentThisFrame(7)
            HideHudComponentThisFrame(9)
            DrawScaleformMovieFullscreen(buttonsScaleform, 255, 255, 255, 255, 0)
            SetScriptGfxDrawBehindPausemenu(false)
            Wait(0)
        end

        SetScaleformMovieAsNoLongerNeeded(scaleform)
        SetScaleformMovieAsNoLongerNeeded(buttonsScaleform)
    end)
end

local function SetupScaleform()
    -- Somehow doesn't update the screen unless you make it blank first. Even though the actionscript suggest it cleans the screen itself internally. :shrug:
    CallScaleformMovieMethod(scaleform, 'SHOW_BLANK_SCREEN')
    BeginScaleformMovieMethod(scaleform, 'SET_STYLE')
    ScaleformMovieMethodAddParamInt(3)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethod(scaleform, 'SHOW_SELECTION_SCREEN')

    -- Smart math that isn't modular at all. Can't wait for the support questions for this one
    local StartingPoint
    if currentButtonID < 4 then
        StartingPoint = 1
    elseif currentButtonID < 7 then
        StartingPoint = 4
    end

    for i = StartingPoint, StartingPoint + 2 do
        ScaleformMovieMethodAddParamTextureNameString(string.format('selection%s', i))
        BeginTextCommandScaleformString('STRING')
        AddTextComponentSubstringPlayerName(ApartmentOptions[i].label)
        EndTextCommandScaleformString()
        BeginTextCommandScaleformString('STRING')
        AddTextComponentSubstringPlayerName(ApartmentOptions[i].description)
        EndTextCommandScaleformString()
        ScaleformMovieMethodAddParamInt(0)
    end

    BeginTextCommandScaleformString('STRING')
    AddTextComponentSubstringPlayerName(string.format('%s/%s', currentButtonID, #ApartmentOptions))
    EndTextCommandScaleformString()

    ScaleformMovieMethodAddParamInt(0)

    ScaleformMovieMethodAddParamBool(true)
    ScaleformMovieMethodAddParamBool(true)
    ScaleformMovieMethodAddParamBool(true)

    -- Same "modular" bullshit here. Had no success with CURRENT_SELECTION nor CURRENT_ROLLOVER, not sure why.
    for i = StartingPoint, StartingPoint + 2 do
        if i == currentButtonID then
            ScaleformMovieMethodAddParamBool(true)
        else
            ScaleformMovieMethodAddParamBool(false)
        end
    end

    EndScaleformMovieMethod()
end

function SetupCamera(apartmentCam)
    if apartmentCam then
        previewCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', -46.33, -585.24, 89.29, -5.0, 0.0, 250.0, 60.0, false, 2)
        SetCamActive(previewCam, true)
        SetCamFarDof(previewCam, 0.65)
        SetCamDofStrength(previewCam, 0.5)
        RenderScriptCams(true, false, 1, true, true)
        CreateThread(function()
            while DoesCamExist(previewCam) do
                SetUseHiDof()
                Wait(0)
            end
        end)
    else
        previewCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', -24.77, -590.35, 90.8, -2.0, 0.0, 160.0, 45.0, false, 2)
        SetCamActive(previewCam, true)
        RenderScriptCams(true, false, 1, true, true)
    end
end

function StopCamera()
    SetCamActive(previewCam, false)
    DestroyCam(previewCam, true)
end

function ManagePlayer()
    SetEntityCoords(cache.ped, -21.58, -583.76, 86.31, false, false, false, false)
    FreezeEntityPosition(cache.ped, true)
    SetTimeout(500, function()
        DoScreenFadeIn(5000)
    end)
end

local function InputHandler()
    while true do
        if IsControlJustReleased(0, 188) then
            currentButtonID -= 1
            if currentButtonID < 1 then currentButtonID = #ApartmentOptions end
            SetupScaleform()
        elseif IsControlJustReleased(0, 187) then
            currentButtonID += 1
            if currentButtonID > #ApartmentOptions then currentButtonID = 1 end
            SetupScaleform()
        elseif IsControlJustReleased(0, 191) then
            local alert = lib.alertDialog({
                header = locale('alert.apartment_selection'),
                content = string.format(locale('alert.are_you_sure'), ApartmentOptions[currentButtonID].label),
                centered = true,
                cancel = true
            })
            if alert == 'confirm' then
                DoScreenFadeOut(500)
                while not IsScreenFadedOut() do Wait(0) end
                FreezeEntityPosition(cache.ped, false)
                SetEntityCoords(cache.ped, ApartmentOptions[currentButtonID].enter.x, ApartmentOptions[currentButtonID].enter.y, ApartmentOptions[currentButtonID].enter.z - 2.0, false, false, false, false)
                Wait(0)
                TriggerServerEvent('qbx_properties:server:apartmentSelect', currentButtonID)
                Wait(1000) -- Wait for player to spawn correctly so clothing menu can load in nice
                TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
                TriggerEvent('QBCore:Client:OnPlayerLoaded')
                break
            end
        end
        Wait(0)
    end
    StopCamera()
end


local function SetupContext()
    local options = {}
    for i=1, #ApartmentOptions do
        options[#options + 1] = {
            title = ApartmentOptions[i].label,
            icon = 'home',
            description = ApartmentOptions[i].description,
            image = "https://c4.wallpaperflare.com/wallpaper/109/907/613/grand-theft-auto-v-gta-v-franklin-clinton-michael-de-santa-wallpaper-preview.jpg",
            arrow = true,
            onSelect = function()
                local alert = lib.alertDialog({
                    header = locale('alert.apartment_selection'),
                    content = string.format(locale('alert.are_you_sure'), ApartmentOptions[i].label),
                    centered = true,
                    cancel = true
                })

                if alert == 'confirm' then
                    DoScreenFadeOut(500)
                    while not IsScreenFadedOut() do Wait(0) end
                    FreezeEntityPosition(cache.ped, false)
                    SetEntityCoords(cache.ped, ApartmentOptions[i].enter.x, ApartmentOptions[i].enter.y, ApartmentOptions[i].enter.z - 2.0, false, false, false, false)
                    Wait(0)
                    TriggerServerEvent('qbx_properties:server:apartmentSelect', i)
                    Wait(1000) -- Wait for player to spawn correctly so clothing menu can load in nice
                    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
                    TriggerEvent('QBCore:Client:OnPlayerLoaded')
                    if previewCam then
                        SetCamActive(previewCam, false)
                        DestroyCam(previewCam, true)
                        previewCam = nil
                    end
                    DoScreenFadeIn(1000)
                else
                    lib.showContext('qbx_properties_appartmentSelect')
                end
            end
        }    
    end

    lib.registerContext({
        id = 'qbx_properties_appartmentSelect',
        title = 'Appartments',
        options = options
    })

    lib.showContext('qbx_properties_appartmentSelect')
end
]]--
    
-- print('OxLib Way')
RegisterNetEvent('apartments:client:setupSpawnUI', function()
    -- Wait(400)
    Wait(1000) -- Wait for player to spawn correctly so clothing menu can load in nice
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
end)

-- Original Way
-- RegisterNetEvent('apartments:client:setupSpawnUI', function()
--     Wait(400)
--     ManagePlayer()
--     SetupCamera(true)
--     SetupBoard()
--     StartScaleform()
--     SetupScaleform()
--     InputHandler()
-- end)