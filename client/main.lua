local hudVisible = true

RegisterNetEvent('qb-xp:client:sync', function(data)
    SendNUIMessage({
        action = 'sync',
        payload = data
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

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(500)
    SendNUIMessage({
        action = 'toggle',
        payload = { visible = hudVisible }
    })
end)
