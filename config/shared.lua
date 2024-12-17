ShellUndergroundOffset = 50.0

function CalculateOffsetCoords(propertyCoords, offset)
    return vec3(propertyCoords.x + offset.x, propertyCoords.y + offset.y, (propertyCoords.z - ShellUndergroundOffset) + offset.z)
end

function CreateBlip(apartmentCoords, label, sprite)
	local blip = AddBlipForCoord(apartmentCoords.x, apartmentCoords.y, apartmentCoords.z)
	SetBlipSprite(blip, sprite)
	SetBlipAsShortRange(blip, true)
	SetBlipScale(blip, 0.8)
	SetBlipColour(blip, 2)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString(label)
	EndTextCommandSetBlipName(blip)
	return blip
end

--[[
More Appartment options (for others need to clone interior to other places)

Eclipse Tower : Same as other -778.50610000, 331.31600000, 210.39720

]]

ApartmentOptions = {
    {
        interior = 'DellPerroHeightsApt4',
        label = 'Del Perro Heights Apt',
        description = 'Enjoy ocean views far away from tourists and bums on Del Perro Beach.',
        enter = vec3(-1447.35, -537.84, 34.74),
		panel = vec3(-1441.8552246094, -543.42962646484, 35.256145477295),
		price = 10000
    },
    {
        interior = '4IntegrityWayApt30',
        label = '4 Integrity Way Apt',
        description = 'An apartment so expansive, all your friends will immediately know how much you paid for it.',
        enter = vec3(-47.52, -585.86, 37.95),
		panel = vec3(-49.091163635254, -590.41723632812, 38.465553283691),
		price = 10000
    },
    {
        interior = 'RichardMajesticApt2',
        label = 'Richard Majestic Apt',
        description = 'This breathtaking luxury condo is a stone\'s throw from AKAN Records and a Sperm Donor Clinic.',
        enter = vec3(-936.15, -378.91, 38.96),
		panel = vec3(-934.3623046875, -380.06356811523, 39.619285583496),
		price = 10000
    },
    {
        interior = 'TinselTowersApt42',
        label = 'Tinsel Towers Apt',
        description = 'A picture-perfect lateral living experience in one of Los Santos most sought-after tower blocks.',
        enter = vec3(-614.58, 46.52, 43.59),
		panel = vec3(-613.54766845703, 36.970626831055, 44.230236053467),
		price = 10000
    },
	{
        interior = 'EclipseTowersApt5',
        label = 'Eclipse Towers Apt',
        description = 'A picture-perfect lateral living experience in one of Los Santos most sought-after tower blocks.',
        enter = vec3(-773.0326, 317.7435, 85.6626),
		panel = vec3(-778.83325195312, 313.49774169922, 86.136169433594),
		price = 10000
    },
}

Garages = {
	-- Dell Perro
	{
		appartmentCoords = vec3(-1447.35, -537.84, 34.74), --Must be same as entry coords
		spawn = {
			vec4(-1491.2465, -522.5305, 32.4396, 35.2251),
			vec4(-1480.8784, -512.0031, 32.4395, 33.7558),
			vec4(-1473.5435, -506.5136, 32.4391, 34.4867),
		},
		dropOff = vec3(-1458.3442, -499.6631, 32.0971) -- Garage can be accessed from here
	},
	-- Integrity Way
	{
		appartmentCoords = vec3(-47.52, -585.86, 37.95),
		spawn = {
			vec4(-10.4642, -642.4049, 35.3567, 250.6894),
			vec4(-6.1266, -630.9563, 35.3571, 251.6850),
			vec4(4.5365, -616.9142, 35.3568, 161.1850)
		},
		dropOff = vec3(-26.1519, -624.3506, 35.1521)
	},
	-- Tinsel Towers
	{
		appartmentCoords = vec3(-614.58, 46.52, 43.59),
		spawn = {
			vec4(-620.3749, 60.1852, 43.3691, 89.7062),
			vec4(-620.1719, 52.2298, 43.3696, 89.6458)
		},
		dropOff = vec3(-566.6966, 55.5906, 49.2571)
	},
	-- Richard Majestic
	{
		appartmentCoords = vec3(-936.15, -378.91, 38.96),
		spawn = {
			vec4(-1040.2433, -411.4003, 32.9062, 26.4142),
			vec4(-1032.8413, -408.0217, 32.9061, 26.9098)
		},
		dropOff = vec3(-1038.7344, -403.4747, 32.9058)
	},
	-- Eclips Towers
	{
		appartmentCoords = vec3(-773.0326, 317.7435, 85.6626),
		spawn = {
			vec4(-791.6827, 331.8393, 85.2760, 180.9388),
			vec4(-800.3967, 332.2888, 85.2768, 180.9118)
		},
		dropOff = vec3(-796.2831, 317.8094, 85.2479)
	},
}


Interiors = {
	['4IntegrityWayApt30'] = {
		exit = vec3(-17.7533, -589.4276, 90.1148),
		clothing = vec3(-38.11, -583.48, 83.92),
		stash = vec3(-26.95, -588.61, 90.12),
		logout = vec3(-37.28, -577.89, 83.91)
	},
    ['DellPerroHeightsApt4'] = {
        exit = vec3(-1452.8683, -539.8164, 74.0443),
        clothing = vec3(-1449.88, -549.25, 72.84),
        stash = vec3(-1466.83, -527.03, 73.44),
        logout = vec3(-1454.08, -553.25, 72.84)
    },
	['RichardMajesticApt2'] = {
		exit = vec3(-913.51, -365.55, 114.27),
		clothing = vec3(-903.79, -363.99, 113.07),
		stash = vec3(-928.04, -377.22, 113.67),
		logout = vec3(-900.27, -368.65, 113.07)
	},
	['TinselTowersApt42'] = {
		exit = vec3(-603.73, 58.96, 98.2),
		clothing = vec3(-594.63, 56.15, 97.0),
		stash = vec3(-622.36, 55.09, 97.6),
		logout = vec3(-593.71, 50.18, 97.0)
	},
	['EclipseTowersApt5'] = { -- -778.5064, 331.3159, 211.3971, 90.7223
		exit = vec3(-784.1286, 323.5202, 211.9972),
		clothing = vec3(-793.3002, 326.3842, 210.7967),
		stash = vec3(-766.8076, 328.4537, 211.3966),
		logout = vec3(-794.3795, 332.3813, 210.7967)
	},
}

-- Make sure to change in config/server.lua too
GarageCarSpawn = {
	[1] = vec4(515.0365, -2614.4829, -49.3736, 240.5865),
	[2] = vec4(524.5573, -2618.3267, -49.3739, 119.9464),
	[3] = vec4(515.0269, -2618.2566, -49.3739, 244.3332),
	[4] = vec4(524.5459, -2622.2048, -49.3738, 116.6740),
	[5] = vec4(515.0540, -2622.1550, -49.3739, 247.7094),
	[6] = vec4(524.6008, -2626.2566, -49.3739, 114.5935),
	[7] = vec4(514.8771, -2625.7573, -49.3739, 251.8771),
	[8] = vec4(524.6436, -2630.2029, -49.3739, 116.0741),
	[9] = vec4(515.0258, -2629.8145, -49.3739, 250.3176),
	[10] = vec4(514.9919, -2633.8032, -49.3737, 250.0547),
}

