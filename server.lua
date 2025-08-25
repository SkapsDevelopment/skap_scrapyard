
local dismantleAttempts = {}
local dismantleTimestamps = {}

RegisterServerEvent('kachna_scrap:givePart', function(partKey, playerCoords, netVeh)
    local src = source
    local part = Config.Parts[partKey]
    if not part or type(playerCoords) ~= 'table' or not netVeh then return end


    local zone = Config.Zone
    local size = Config.ZoneSize or vec3(5.0, 5.0, 3.0)
    local radius = math.max(size.x, size.y) / 2
    local dist = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - zone)

    local now = os.time()
    
    if not dismantleTimestamps[src] or now - dismantleTimestamps[src] > 10 then
        dismantleAttempts[src] = 1
        dismantleTimestamps[src] = now
    else
        dismantleAttempts[src] = (dismantleAttempts[src] or 0) + 1
        dismantleTimestamps[src] = now
    end
    if dismantleAttempts[src] > 2 then
        DropPlayer(src, '[kachna_scrapyard] Cheating detected: too many attempts (spam) within 10s.')
        dismantleAttempts[src] = 0
        dismantleTimestamps[src] = nil
        return
    end

    if dist > radius then
        print(('[kachna_scrapyard] Player %s tried to trigger dismantle event outside zone!'):format(src))
        DropPlayer(src, '[kachna_scrapyard] Cheating detected: trigger outside zone.')
        return
    end

    local veh = NetworkGetEntityFromNetworkId(netVeh)
    if not veh or veh == 0 then return end
    local vehCoords = GetEntityCoords(veh)
    local playerVec = vector3(playerCoords.x, playerCoords.y, playerCoords.z)
    if #(vehCoords - playerVec) > 7.0 then
        print(('[kachna_scrapyard] Player %s tried to dismantle vehicle not nearby!'):format(src))
        return
    end

    if partKey == 'crush' then
        local min = part.min or 1
        local max = part.max or 1
        local amount = math.random(min, max)
        exports.ox_inventory:AddItem(src, part.item, amount)
    else
        exports.ox_inventory:AddItem(src, part.item, 1)
    end
end)
