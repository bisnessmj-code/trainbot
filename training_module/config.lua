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
    rollProbability = 20, -- Probabilité de roulade (0-100)
    weapon = 'WEAPON_PISTOL50', -- Arme donnée au joueur
    botModel = 'g_m_y_lost_01' -- Modèle des bots
}

-- 🆕 NOUVEAU : Modes de difficulté
Config.Difficulty = {
    enabled = true, -- Activer le système de difficulté
    
    easy = {
        botHealth = 150,
        botArmor = 0,
        botAccuracy = 20,
        botWeapon = 'WEAPON_PISTOL',
        rollProbability = 10,
        label = 'Facile'
    },
    
    medium = {
        botHealth = 200,
        botArmor = 50,
        botAccuracy = 40,
        botWeapon = 'WEAPON_PISTOL',
        rollProbability = 20,
        label = 'Moyen'
    },
    
    hard = {
        botHealth = 250,
        botArmor = 100,
        botAccuracy = 60,
        botWeapon = 'WEAPON_COMBATPISTOL',
        rollProbability = 35,
        label = 'Difficile'
    },
    
    extreme = {
        botHealth = 300,
        botArmor = 150,
        botAccuracy = 80,
        botWeapon = 'WEAPON_APPISTOL',
        rollProbability = 50,
        label = 'Extrême'
    }
}

-- 🆕 NOUVEAU : Types de bots variés
Config.BotTypes = {
    enabled = true, -- Activer les types de bots variés
    
    -- Soldat standard
    soldier = {
        model = 'g_m_y_lost_01',
        weapon = 'WEAPON_PISTOL',
        health = 200,
        armor = 50,
        accuracy = 40,
        spawnChance = 50 -- Probabilité d'apparition (%)
    },
    
    -- Sniper (précis, moins résistant)
    sniper = {
        model = 's_m_y_swat_01',
        weapon = 'WEAPON_COMBATPISTOL',
        health = 150,
        armor = 25,
        accuracy = 70,
        spawnChance = 25
    },
    
    -- Tank (très résistant, moins précis)
    tank = {
        model = 'g_m_m_armboss_01',
        weapon = 'WEAPON_PISTOL',
        health = 300,
        armor = 100,
        accuracy = 25,
        spawnChance = 15
    },
    
    -- Rusher (rapide, peu résistant)
    rusher = {
        model = 'g_m_y_mexgang_01',
        weapon = 'WEAPON_KNIFE',
        health = 100,
        armor = 0,
        accuracy = 30,
        spawnChance = 10
    }
}

-- 🆕 NOUVEAU : Comportements des bots
Config.BotBehaviors = {
    -- Animations de roulade (vraies roulades)
    dodgeAnimations = {
        {dict = 'move_crouch_proto', anim = 'idle_intro', duration = 1000},
        {dict = 'move_jump', anim = 'dive_start_stumble', duration = 1200}
    },
    
    -- Mouvements tactiques
    tacticalMoves = {
        enabled = true,
        rushProbability = 30, -- Probabilité de foncer sur le joueur
        coverProbability = 25, -- Probabilité de chercher une couverture
        flankProbability = 20 -- Probabilité de contourner
    },
    
    -- Sons des bots
    sounds = {
        enabled = true,
        onSpawn = 'GENERIC_INSULT_HIGH',
        onKill = 'GENERIC_DEAD_BODY'
    }
}

-- 🆕 NOUVEAU : Système de statistiques
Config.Stats = {
    enabled = true,
    trackHeadshots = true, -- Compter les headshots
    trackAccuracy = true, -- Compter les tirs ratés/réussis
    trackBestStreak = true, -- Meilleure série de kills
    trackReactionTime = true -- Temps de réaction moyen
}

-- 🆕 NOUVEAU : Système de récompenses
Config.Rewards = {
    enabled = true,
    
    -- Récompenses par paliers de kills
    killMilestones = {
        {kills = 5, money = 500, xp = 100},
        {kills = 10, money = 1000, xp = 250},
        {kills = 15, money = 2000, xp = 500},
        {kills = 20, money = 5000, xp = 1000}
    },
    
    -- Bonus de performance
    bonuses = {
        perfectAccuracy = {threshold = 90, money = 1000, xp = 200}, -- >90% précision
        speedKiller = {threshold = 30, money = 1500, xp = 300}, -- >30 kills/min
        headhunter = {threshold = 70, money = 2000, xp = 400} -- >70% headshots
    }
}

-- 🆕 NOUVEAU : Effets visuels
Config.VisualEffects = {
    enabled = true,
    
    -- Marqueur au-dessus des bots
    botMarker = {
        enabled = true,
        type = 2, -- Type de marqueur
        color = {r = 255, g = 0, b = 0, a = 150},
        height = 2.0
    },
    
    -- Effets de particules lors des kills
    killEffects = {
        enabled = true,
        particle = 'scr_rcbarry2',
        particleName = 'scr_clown_appears'
    },
    
    -- Effets sonores
    soundEffects = {
        enabled = true,
        onKill = true,
        onHeadshot = true
    }
}

-- Messages
Config.Messages = {
    pressE = '~INPUT_CONTEXT~ Interagir avec le formateur',
    trainingStart = 'Entraînement démarré ! Éliminez un maximum d\'ennemis.',
    trainingEnd = 'Fin de l\'entraînement',
    finalScore = 'Score final : %s kills en 1 minute',
    newRecord = '🏆 Nouveau record personnel !',
    headshot = '💀 HEADSHOT !',
    killStreak = '🔥 Série de %s kills !',
    selectDifficulty = 'Choisissez votre niveau de difficulté'
}

-- Configuration NUI
Config.NUI = {
    hudPosition = 'top-right',
    showKills = true,
    showTimer = true,
    showHeadshots = true,
    showStreak = true,
    showAccuracy = true
}