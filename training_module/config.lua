Config = {}

-- Position du PNJ de lobby
Config.LobbyNPC = {
    model = 'a_m_y_business_03',
    coords = vector4(-2658.857178, -768.712098, 5.993408, 0.00000),
    animation = {
        dict = 'world_human_clipboard',
        anim = 'base'
    }
}

-- Position de téléportation pour l'entraînement
Config.TrainingSpawn = vector4(-1572.843994, -3006.975830, 13.929688, 51.023624)

-- Points de spawn des bots
Config.BotSpawnPoints = {
    vector4(-1590.501098, -2994.778076, 13.929688, 243.779526),
    vector4(-1588.997802, -3002.637452, 13.929688, 212.598420),
    vector4(-1583.367066, -2994.210938, 13.929688, 260.787414),
    vector4(-1594.562622, -3000.250488, 13.929688, 206.929122),
    vector4(-1584.514282, -2999.459228, 13.929688, 246.614166)
}

-- Paramètres d'entraînement
Config.Training = {
    duration = 60, -- Durée en secondes (1 minute)
    maxBots = 5, -- Nombre maximum de bots simultanés
    botRespawnDelay = 3000, -- Délai de respawn en ms (3 secondes)
    rollProbability = 15, -- Probabilité de roulade (0-100)
    weapon = 'WEAPON_PISTOL50', -- Arme donnée au joueur
    botWeapon = 'snife', -- Arme donnée aux bots
    botModel = 'g_m_y_lost_01' -- Modèle des bots
}

-- Messages
Config.Messages = {
    pressE = '~INPUT_CONTEXT~ Interagir avec le formateur',
    trainingStart = 'Entraînement démarré ! Éliminez un maximum d\'ennemis.',
    trainingEnd = 'Fin de l\'entraînement',
    finalScore = 'Score final : %s kills en 1 minute'
}

-- Configuration NUI
Config.NUI = {
    hudPosition = 'top-right', -- Position du HUD (top-right, bottom-right, etc.)
    showKills = true,
    showTimer = true
}
