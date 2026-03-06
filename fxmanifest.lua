fx_version 'cerulean'
game 'gta5'

name 'qb-xp-system'
author 'Codex'
description 'Sistema de XP con niveles, trabajos y HUD para QBCore'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}
