# qb-xp-system (Advanced)

Sistema de XP avanzado para FiveM + QBCore con:
- Niveles + guardado persistente por `citizenid`
- Prestigio automático al llegar al nivel máximo
- XP por trabajos con multiplicadores por job
- Anti-spam/cooldown por tipo de fuente XP
- Multiplicador por permisos/roles (VIP/Mod/etc)
- HUD visual NUI (toggle con `F10`)
- Leaderboard y log de transacciones XP

## Instalación

1. Copia esta carpeta a `resources/[local]/qb-xp-system`.
2. Ejecuta el SQL `sql/player_xp.sql` en tu base de datos.
3. Asegúrate de tener `qb-core` y `oxmysql`.
4. Agrega en tu `server.cfg`:

```cfg
ensure qb-core
ensure oxmysql
ensure qb-xp-system
```

## Integración desde otros scripts

### Dar XP directa (server export)

```lua
exports['qb-xp-system']:AddXP(source, 25, 'Misión completada', 'mission')
```

### Dar XP por trabajo (server event)

```lua
TriggerEvent('qb-xp:server:addWorkXP', 10, 'Trabajo completado')
```

### Evento genérico de XP (server event)

```lua
TriggerEvent('qb-xp:server:addXP', 40, 'heist', 'Robo completado')
```

## Comandos

- `/givexp [id] [cantidad] [razón]` (admin)
- `/xpleaderboard` (muestra top)
- `/myxp` (estado personal)

## Configuración recomendada

Edita `config.lua` para:
- Curva de niveles (`BaseXP`, `XPGrowth`, `MaxLevel`)
- Prestigio (`PrestigeEnabled`, `PrestigeMax`)
- Multiplicadores por trabajo (`JobXP`)
- Cooldowns por tipo (`SourceCooldowns`)
- Multiplicador por permisos (`PermissionMultipliers`)
- Tecla/comando HUD
