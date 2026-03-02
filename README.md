# qb-xp-system

Sistema de XP para FiveM + QBCore con:
- Niveles y guardado en base de datos
- XP por trabajos
- HUD visual NUI
- Toggle HUD con `F10`

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

## Uso básico

### Dar XP desde otro script (server)

```lua
exports['qb-xp-system']:AddXP(source, 25, 'Misión completada')
```

### Dar XP por trabajo (server)

```lua
TriggerClientEvent('QBCore:Notify', source, 'Trabajo completado', 'success')
TriggerEvent('qb-xp:server:addWorkXP', 10, 'Trabajo completado')
```

> `10` es la base y se multiplica según `Config.JobXP[job]`.

### Comando admin

- `/givexp [id] [cantidad] [razón]`

## Configuración

Edita `config.lua` para:
- Curva de niveles (`BaseXP`, `XPGrowth`, `MaxLevel`)
- Multiplicadores de XP por trabajo
- Tecla/comando del HUD
