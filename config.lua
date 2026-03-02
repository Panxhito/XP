Config = {}

-- Teclas / HUD
Config.ToggleHudCommand = 'togglexphud'
Config.ToggleHudDefaultKey = 'F10'

-- Progresión
Config.MaxLevel = 100
Config.BaseXP = 100        -- XP necesaria para nivel 1 -> 2
Config.XPGrowth = 1.25     -- Multiplicador por nivel

-- Trabajos con bonus de XP
Config.JobXP = {
    unemployed = 1.0,
    police = 1.35,
    ambulance = 1.30,
    mechanic = 1.20,
    taxi = 1.15
}

-- XP base por acción de trabajo (puedes reutilizar exports/evento)
Config.BaseWorkXP = 10

-- Notificaciones
Config.NotifyOnXP = true
Config.NotifyType = 'success'

-- Debug
Config.Debug = false
