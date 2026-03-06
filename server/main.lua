local QBCore = exports['qb-core']:GetCoreObject()

---@type table<number, {xp:number, level:number, prestige:number, citizenid:string}>
local PlayerXP = {}
---@type table<number, table<string, number>>
local SourceLocks = {}

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

local function getPermissionMultiplier(src)
    local multiplier = 1.0
    for permission, value in pairs(Config.PermissionMultipliers or {}) do
        if QBCore.Functions.HasPermission(src, permission) then
            multiplier = math.max(multiplier, tonumber(value) or 1.0)
        end
    end
    return multiplier
end

local function passSourceCooldown(src, sourceType)
    sourceType = sourceType or 'generic'
    local cooldown = (Config.SourceCooldowns and Config.SourceCooldowns[sourceType]) or 0
    if cooldown <= 0 then return true end

    if not SourceLocks[src] then SourceLocks[src] = {} end

    local now = os.time()
    local last = SourceLocks[src][sourceType] or 0
    if now - last < cooldown then
        return false
    end

    SourceLocks[src][sourceType] = now
    return true
end

local function ensurePlayerState(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return nil end

    if not PlayerXP[src] then
        local row = MySQL.single.await('SELECT xp, level, prestige FROM player_xp WHERE citizenid = ?', { citizenid })
        if row then
            PlayerXP[src] = {
                xp = tonumber(row.xp) or 0,
                level = tonumber(row.level) or 1,
                prestige = tonumber(row.prestige) or 0,
                citizenid = citizenid
            }
        else
            PlayerXP[src] = { xp = 0, level = 1, prestige = 0, citizenid = citizenid }
            MySQL.insert.await('INSERT INTO player_xp (citizenid, xp, level, prestige) VALUES (?, ?, ?, ?)', { citizenid, 0, 1, 0 })
        end
        debugPrint(('Estado XP cargado para %s [%s]'):format(GetPlayerName(src), citizenid))
    end

    return PlayerXP[src], Player
end

local function persistPlayer(src)
    local state = PlayerXP[src]
    if not state then return end

    MySQL.update.await('UPDATE player_xp SET xp = ?, level = ?, prestige = ? WHERE citizenid = ?', {
        state.xp,
        state.level,
        state.prestige,
        state.citizenid
    })
end

local function getHudData(state)
    local level, progressXP, nextXP = resolveLevelFromXP(state.xp)
    state.level = level

    return {
        xp = state.xp,
        level = level,
        progressXP = progressXP,
        nextXP = nextXP,
        prestige = state.prestige,
        maxLevel = Config.MaxLevel
    }
end

local function pushHudData(src)
    local state = ensurePlayerState(src)
    if not state then return end

    TriggerClientEvent('qb-xp:client:sync', src, getHudData(state))
end

local function logXPTransaction(src, amount, sourceType, reason)
    local state = PlayerXP[src]
    if not state then return end

    MySQL.insert.await(
        'INSERT INTO player_xp_logs (citizenid, source, amount, reason) VALUES (?, ?, ?, ?)',
        { state.citizenid, sourceType or 'generic', amount, reason or 'N/A' }
    )
end

local function processPrestige(state)
    if not Config.PrestigeEnabled then return false end
    if state.level < Config.MaxLevel then return false end
    if (state.prestige or 0) >= (Config.PrestigeMax or 0) then return false end

    state.prestige = state.prestige + 1
    state.xp = 0
    state.level = 1
    return true
end

local function addXP(src, amount, reason, sourceType, skipCooldown)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, 'invalid_amount' end

    local state = ensurePlayerState(src)
    if not state then return false, 'player_not_found' end

    sourceType = sourceType or 'generic'

    if not skipCooldown and not passSourceCooldown(src, sourceType) then
        return false, 'cooldown'
    end

    local oldLevel = state.level
    local permissionBoost = getPermissionMultiplier(src)
    amount = math.floor(amount * permissionBoost)

    state.xp = state.xp + amount

    local leveledUp = false
    local prestigeTriggered = false

    local level = resolveLevelFromXP(state.xp)
    state.level = level

    if state.level > oldLevel then
        leveledUp = true
    end

    if processPrestige(state) then
        prestigeTriggered = true
    end

    persistPlayer(src)
    logXPTransaction(src, amount, sourceType, reason)
    pushHudData(src)

    if Config.NotifyOnXP then
        TriggerClientEvent('QBCore:Notify', src, ('+%s XP%s'):format(amount, reason and (' (%s)'):format(reason) or ''), Config.NotifyType)
    end

    if leveledUp then
        TriggerClientEvent('QBCore:Notify', src, ('¡Subiste a nivel %s!'):format(state.level), 'primary')
    end

    if prestigeTriggered then
        TriggerClientEvent('QBCore:Notify', src, ('¡Prestigio %s alcanzado! Reiniciaste tu nivel.'):format(state.prestige), 'primary')
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
    return state.xp, state.level, state.prestige
end)

QBCore.Functions.CreateCallback('qb-xp:server:getPlayerData', function(source, cb)
    local state = ensurePlayerState(source)
    if not state then
        cb(nil)
        return
    end

    cb(getHudData(state))
end)

QBCore.Functions.CreateCallback('qb-xp:server:getLeaderboard', function(_, cb)
    local rows = MySQL.query.await(
        'SELECT p.name, x.xp, x.level, x.prestige FROM player_xp x INNER JOIN players p ON p.citizenid = x.citizenid ORDER BY x.prestige DESC, x.level DESC, x.xp DESC LIMIT ?',
        { Config.LeaderboardSize or 10 }
    ) or {}

    local payload = {}
    for i = 1, #rows do
        local row = rows[i]
        payload[#payload + 1] = {
            rank = i,
            name = row.name or 'Unknown',
            xp = tonumber(row.xp) or 0,
            level = tonumber(row.level) or 1,
            prestige = tonumber(row.prestige) or 0
        }
    end

    cb(payload)
end)

RegisterNetEvent('qb-xp:server:addWorkXP', function(baseAmount, reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local jobName = Player.PlayerData.job and Player.PlayerData.job.name or 'unemployed'
    local multiplier = Config.JobXP[jobName] or 1.0
    local amount = math.floor((tonumber(baseAmount) or Config.BaseWorkXP) * multiplier)

    addXP(src, amount, reason or ('Trabajo: %s'):format(jobName), 'work')
end)

RegisterNetEvent('qb-xp:server:addXP', function(amount, sourceType, reason)
    local src = source
    addXP(src, amount, reason, sourceType)
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
    SourceLocks[src] = nil
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

    local ok, err = addXP(target, amount, reason ~= '' and reason or 'Admin', 'admin', true)
    if ok then
        TriggerClientEvent('QBCore:Notify', source, ('Le diste %s XP a %s'):format(amount, target), 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, ('No se pudo añadir XP (%s).'):format(err or 'unknown'), 'error')
    end
end, 'admin')

QBCore.Commands.Add('xpleaderboard', 'Ver top de niveles XP', {}, false, function(source)
    local rows = MySQL.query.await(
        'SELECT p.name, x.xp, x.level, x.prestige FROM player_xp x INNER JOIN players p ON p.citizenid = x.citizenid ORDER BY x.prestige DESC, x.level DESC, x.xp DESC LIMIT ?',
        { Config.LeaderboardSize or 10 }
    )

    if not rows or #rows == 0 then
        TriggerClientEvent('QBCore:Notify', source, 'No hay datos de leaderboard aún.', 'error')
        return
    end

    TriggerClientEvent('qb-xp:client:showLeaderboard', source, rows)
end)
