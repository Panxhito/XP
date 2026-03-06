local QBCore = exports['qb-core']:GetCoreObject()
local hudVisible = true

RegisterNetEvent('qb-xp:client:sync', function(data)
    SendNUIMessage({
        action = 'sync',
        payload = data
    })
end)

RegisterNetEvent('qb-xp:client:showLeaderboard', function(rows)
    SendNUIMessage({
        action = 'leaderboard',
        payload = rows
    })
end)

RegisterCommand(Config.ToggleHudCommand, function()
    hudVisible = not hudVisible
    SendNUIMessage({
        action = 'toggle',
        payload = { visible = hudVisible }
    })
end, false)

RegisterKeyMapping(Config.ToggleHudCommand, 'Mostrar/Ocultar HUD de XP', 'keyboard', Config.ToggleHudDefaultKey)

RegisterCommand('myxp', function()
    QBCore.Functions.TriggerCallback('qb-xp:server:getPlayerData', function(data)
        if not data then
            QBCore.Functions.Notify('No se pudo obtener tu XP', 'error')
            return
        end

        QBCore.Functions.Notify((
            'Nivel %s | XP %s | Prestigio %s'
        ):format(data.level, data.xp, data.prestige or 0), 'primary')
    end)
end, false)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(500)
    SendNUIMessage({
        action = 'toggle',
        payload = { visible = hudVisible }
    })
end)
