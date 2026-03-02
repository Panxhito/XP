local QBCore = exports['qb-core']:GetCoreObject()

---@type table<number, {xp:number, level:number}>
local PlayerXP = {}

local function debugPrint(msg)
    if Config.Debug then
        print(('[qb-xp-system] %s'):format(msg))
    end
end

local function getXPRequiredForLevel(level)
    if level <= 1 then return 0 end
    return math.floor(Config.BaseXP * (Config.XPGrowth ^ (level - 1)))
end

local function resolveLevelFromXP(totalXP)
    local level = 1
    local remaining = totalXP

    while level < Config.MaxLevel do
        local needed = getXPRequiredForLevel(level)
        if remaining < needed then
            break
        end
        remaining = remaining - needed
        level = level + 1
    end

    local neededForNext = getXPRequiredForLevel(level)
    return level, remaining, neededForNext
end

local function ensurePlayerState(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return nil end

    if not PlayerXP[src] then
        local row = MySQL.single.await('SELECT xp, level FROM player_xp WHERE citizenid = ?', { citizenid })
        if row then
            PlayerXP[src] = {
                xp = tonumber(row.xp) or 0,
                level = tonumber(row.level) or 1
            }
        else
            PlayerXP[src] = { xp = 0, level = 1 }
            MySQL.insert.await('INSERT INTO player_xp (citizenid, xp, level) VALUES (?, ?, ?)', { citizenid, 0, 1 })
        end
        debugPrint(('Estado XP cargado para %s [%s]'):format(GetPlayerName(src), citizenid))
    end

    return PlayerXP[src], Player
end

local function persistPlayer(src)
    local state, Player = ensurePlayerState(src)
    if not state or not Player then return end

    MySQL.update.await('UPDATE player_xp SET xp = ?, level = ? WHERE citizenid = ?', {
        state.xp,
        state.level,
        Player.PlayerData.citizenid
    })
end

local function pushHudData(src)
    local state = ensurePlayerState(src)
    if not state then return end

    local level, progressXP, nextXP = resolveLevelFromXP(state.xp)
    state.level = level

    TriggerClientEvent('qb-xp:client:sync', src, {
        xp = state.xp,
        level = level,
        progressXP = progressXP,
        nextXP = nextXP
    })
end

local function addXP(src, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local state = ensurePlayerState(src)
    if not state then return false end

    local oldLevel = state.level
    state.xp = state.xp + amount

    local level = resolveLevelFromXP(state.xp)
    state.level = level

    persistPlayer(src)
    pushHudData(src)

    if Config.NotifyOnXP then
        TriggerClientEvent('QBCore:Notify', src, ('+%s XP%s'):format(amount, reason and (' (%s)'):format(reason) or ''), Config.NotifyType)
    end

    if state.level > oldLevel then
        TriggerClientEvent('QBCore:Notify', src, ('¡Subiste a nivel %s!'):format(state.level), 'primary')
    end

    return true
end

exports('AddXP', addXP)

exports('SetXP', function(src, totalXP)
    totalXP = math.max(0, math.floor(tonumber(totalXP) or 0))
    local state = ensurePlayerState(src)
    if not state then return false end

    state.xp = totalXP
    local level = resolveLevelFromXP(totalXP)
    state.level = level

    persistPlayer(src)
    pushHudData(src)
    return true
end)

exports('GetXP', function(src)
    local state = ensurePlayerState(src)
    if not state then return nil end
    return state.xp, state.level
end)

RegisterNetEvent('qb-xp:server:addWorkXP', function(baseAmount, reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local jobName = Player.PlayerData.job and Player.PlayerData.job.name or 'unemployed'
    local multiplier = Config.JobXP[jobName] or 1.0
    local amount = math.floor((tonumber(baseAmount) or Config.BaseWorkXP) * multiplier)

    addXP(src, amount, reason or ('Trabajo: %s'):format(jobName))
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source
    ensurePlayerState(src)
    pushHudData(src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if PlayerXP[src] then
        persistPlayer(src)
        PlayerXP[src] = nil
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for src in pairs(PlayerXP) do
        persistPlayer(src)
    end
end)

QBCore.Commands.Add('givexp', 'Dar XP a un jugador (Admin)', {
    { name = 'id', help = 'ID del jugador' },
    { name = 'amount', help = 'Cantidad de XP' },
    { name = 'reason', help = 'Razón (opcional)' }
}, true, function(source, args)
    local target = tonumber(args[1])
    local amount = tonumber(args[2])
    local reason = table.concat(args, ' ', 3)

    if not target or not amount then
        TriggerClientEvent('QBCore:Notify', source, 'Uso: /givexp [id] [amount] [reason]', 'error')
        return
    end

    if addXP(target, amount, reason ~= '' and reason or 'Admin') then
        TriggerClientEvent('QBCore:Notify', source, ('Le diste %s XP a %s'):format(amount, target), 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'No se pudo añadir XP.', 'error')
    end
end, 'admin')
