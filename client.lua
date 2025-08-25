CreateThread(function()
    while true do
        Wait(0)
        local coords = Config.Zone
        local size = Config.ZoneSize or vec3(5.0, 5.0, 3.0)
        local color = Config.ZoneColor or {r = 120, g = 120, b = 120, a = 80}
        DrawMarker(
            1,
            coords.x, coords.y, coords.z - 1.0,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 
            size.x, size.y, 0.3,
            color.r, color.g, color.b, color.a,
            false, false, 2, false, nil, nil, false
        )
    end
end)

ESX = exports['es_extended']:getSharedObject()

local Config = Config or {}
if not Config.Parts then
    Config = exports.ox_lib:require('config')
end

local function IsInZone()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local zone = Config.Zone
    local size = Config.ZoneSize or vec3(5.0, 5.0, 3.0)
    local radius = math.max(size.x, size.y) / 2
    local dist = #(playerCoords - zone)
    return dist <= radius
end

local function CanDismantle(vehicle)
    return DoesEntityExist(vehicle) and GetEntityHealth(vehicle) > 0 and IsInZone()
end

local dismantledParts = {}

local function NotifyPolice(coords)
    TriggerServerEvent('cd_dispatch:AddNotification', {
        job_table = {'police'},
        coords = coords,
        title = 'Nelegální činnost',
        message = 'Někdo právě rozebírá vozidlo!',
        flash = 0,
        unique_id = tostring(math.random(0000000, 9999999)),
        blip = {
            sprite = 229,
            scale = 1.2,
            colour = 1,
            flashes = true,
            text = 'Nelegální demontáž'
        }
    })
end

local function openDismantleMenu(vehicle)
    local vehNetId = VehToNet(vehicle)
    dismantledParts[vehNetId] = dismantledParts[vehNetId] or {}
    local menu = {
        id = 'kachna_dismantle_menu',
        title = 'Vyber část k demontáži',
        options = {}
    }
    local hasOption = false

    for partKey, part in pairs(Config.Parts) do
        if not dismantledParts[vehNetId][partKey] then
            hasOption = true
            table.insert(menu.options, {
                title = part.label,
                icon = (partKey == 'crush') and 'fa-solid fa-car-burst' or 'fa-solid fa-gear',
                onSelect = function()
                    local ped = PlayerPedId()
                    if partKey == 'crush' then
                        FreezeEntityPosition(vehicle, true)
                        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WELDING', 0, true)
                        lib.progressBar({
                            duration = Config.ProgressTime or 4000,
                            label = part.label or 'Sešrotuji vozidlo...',
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                                move = true,
                                combat = true,
                            },
                        })
                        ClearPedTasks(ped)
                        FreezeEntityPosition(vehicle, false)
                        local netId = VehToNet(vehicle)
                        DeleteEntity(vehicle)
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        TriggerServerEvent('kachna_scrap:givePart', 'crush', {x = playerCoords.x, y = playerCoords.y, z = playerCoords.z}, netId)

                        NotifyPolice(playerCoords)
                        dismantledParts[vehNetId]['crush'] = true
                    else
                        FreezeEntityPosition(vehicle, true)
                        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WELDING', 0, true)
                        lib.progressBar({
                            duration = Config.ProgressTime or 4000,
                            label = 'Demontuji '..part.label..'...',
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                                move = true,
                                combat = true,
                            },
                        })
                        ClearPedTasks(ped)
                        FreezeEntityPosition(vehicle, false)

                        if part.bone == 'bonnet' then
                            SetVehicleDoorBroken(vehicle, 4, true)
                        elseif part.bone == 'boot' then
                            SetVehicleDoorBroken(vehicle, 5, true)
                        elseif part.bone == 'door_pside_f' then
                            SetVehicleDoorBroken(vehicle, 1, true)
                        elseif part.bone == 'door_dside_f' then
                            SetVehicleDoorBroken(vehicle, 0, true)
                        elseif part.bone == 'door_pside_r' then
                            SetVehicleDoorBroken(vehicle, 3, true)
                        elseif part.bone == 'door_dside_r' then
                            SetVehicleDoorBroken(vehicle, 2, true)
                        end

                        local playerCoords = GetEntityCoords(PlayerPedId())
                        TriggerServerEvent('kachna_scrap:givePart', partKey, {x = playerCoords.x, y = playerCoords.y, z = playerCoords.z}, VehToNet(vehicle))
                        NotifyPolice(playerCoords)
                        dismantledParts[vehNetId][partKey] = true
                    end
                end
            })
        end
    end

    if hasOption then
        lib.registerContext(menu)
        lib.showContext('kachna_dismantle_menu')
    else
        lib.notify({title = 'Demontáž', description = 'Není co demontovat.', type = 'info'})
    end
end

CreateThread(function()
    local option = {
        name = 'dismantle_menu',
        icon = 'fa-solid fa-gear',
        label = 'Demontovat vozidlo',
        canInteract = function(entity, distance, coords, name, bone)
            return CanDismantle(entity)
        end,
        onSelect = function(data)
            openDismantleMenu(data.entity)
        end
    }
    exports.ox_target:addGlobalVehicle({option})
end)
