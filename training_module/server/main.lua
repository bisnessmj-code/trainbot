-- Script de gestion des sessions d'entraînement (SERVEUR CORRIGÉ)
print('[Training] ===== SERVER LOADING =====')

-- Initialiser ESX
local ESX = nil

CreateThread(function()
    while ESX == nil do
        ESX = exports['es_extended']:getSharedObject()
        if ESX then
            print('[Training] ✅ ESX initialized successfully')
        else
            print('[Training] ⏳ Waiting for ESX...')
            Wait(100)
        end
    end
end)

local activeSessions = {}
local nextBucketId = 1000
local playerStats = {}

print('[Training] Server script loaded')

-- Fonction pour générer un ID de bucket unique
local function GetNextBucketId()
    nextBucketId = nextBucketId + 1
    print('[Training] Generated new bucket ID: ' .. nextBucketId)
    return nextBucketId
end

-- Fonction pour obtenir les paramètres de difficulté
local function GetDifficultyConfig(difficulty)
    if Config.Difficulty.enabled and Config.Difficulty[difficulty] then
        return Config.Difficulty[difficulty]
    end
    return Config.Difficulty.medium
end

-- Fonction pour choisir un type de bot aléatoire
local function GetRandomBotType(difficulty)
    if not Config.BotTypes.enabled then
        local diffConfig = GetDifficultyConfig(difficulty)
        return {
            model = Config.Training.botModel,
            weapon = diffConfig.botWeapon,
            health = diffConfig.botHealth,
            armor = diffConfig.botArmor,
            accuracy = diffConfig.botAccuracy
        }
    end
    
    local totalChance = 0
    local botTypes = {}
    
    for typeName, botType in pairs(Config.BotTypes) do
        -- Ignorer la propriété 'enabled' et vérifier que c'est bien un type de bot
        if typeName ~= 'enabled' and type(botType) == 'table' and botType.spawnChance and type(botType.spawnChance) == 'number' then
            totalChance = totalChance + botType.spawnChance
            table.insert(botTypes, {name = typeName, data = botType, chance = botType.spawnChance})
            print('[Training] Bot type registered: ' .. typeName .. ' (chance: ' .. botType.spawnChance .. '%)')
        end
    end
    
    if #botTypes == 0 then
        print('[Training] ⚠️ No bot types found, using default')
        local diffConfig = GetDifficultyConfig(difficulty)
        return {
            model = Config.Training.botModel,
            weapon = diffConfig.botWeapon,
            health = diffConfig.botHealth,
            armor = diffConfig.botArmor,
            accuracy = diffConfig.botAccuracy
        }
    end
    
    local random = math.random(1, totalChance)
    local current = 0
    
    for _, botType in ipairs(botTypes) do
        current = current + botType.chance
        if random <= current then
            print('[Training] Selected bot type: ' .. botType.name)
            return botType.data
        end
    end
    
    -- Fallback sur le premier type disponible
    print('[Training] Using fallback bot type: ' .. botTypes[1].name)
    return botTypes[1].data
end

-- Fonction pour créer une session d'entraînement
local function CreateTrainingSession(source, difficulty)
    print('[Training] ===== CREATING SESSION =====')
    print('[Training] Player: ' .. source)
    print('[Training] Difficulty: ' .. difficulty)
    
    local bucketId = GetNextBucketId()
    local difficultyConfig = GetDifficultyConfig(difficulty)
    
    activeSessions[source] = {
        bucketId = bucketId,
        kills = 0,
        headshots = 0,
        startTime = os.time(),
        bots = {},
        timerActive = true,
        difficulty = difficulty,
        difficultyConfig = difficultyConfig
    }
    
    if not playerStats[source] then
        playerStats[source] = {
            totalKills = 0,
            totalHeadshots = 0,
            bestScore = 0,
            gamesPlayed = 0
        }
    end
    
    playerStats[source].gamesPlayed = playerStats[source].gamesPlayed + 1
    
    SetPlayerRoutingBucket(source, bucketId)
    SetRoutingBucketEntityLockdownMode(bucketId, 'strict')
    
    print('[Training] ✅ Session created - Bucket: ' .. bucketId)
    print('[Training] =========================')
    
    return bucketId
end

-- Fonction pour spawner un bot
local function SpawnBot(source, session)
    if not activeSessions[source] then 
        print('[Training] ❌ ERROR: Session not found for player ' .. source)
        return 
    end
    
    print('[Training] ----- Spawning Bot -----')
    
    local spawnPoint = Config.BotSpawnPoints[math.random(1, #Config.BotSpawnPoints)]
    local botTypeData = GetRandomBotType(session.difficulty)
    
    print('[Training] Spawn: ' .. spawnPoint.x .. ', ' .. spawnPoint.y)
    print('[Training] Model: ' .. botTypeData.model)
    print('[Training] Weapon: ' .. botTypeData.weapon)
    
    local model = GetHashKey(botTypeData.model)
    local bot = CreatePed(4, model, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, true)
    
    if not DoesEntityExist(bot) then
        print('[Training] ❌ ERROR: Failed to create bot!')
        return
    end
    
    SetEntityRoutingBucket(bot, session.bucketId)
    
    local botNetId = NetworkGetNetworkIdFromEntity(bot)
    
    table.insert(session.bots, {
        entity = bot,
        netId = botNetId,
        type = botTypeData
    })
    
    print('[Training] ✅ Bot created - NetID: ' .. botNetId .. ' | Total: ' .. #session.bots)
    
    TriggerClientEvent('training:configureBotClient', source, botNetId, spawnPoint, botTypeData)
    
    print('[Training] -----------------------')
end

-- Fonction pour gérer le respawn d'un bot
local function RespawnBot(source)
    if not activeSessions[source] then return end
    
    SetTimeout(Config.Training.botRespawnDelay, function()
        if activeSessions[source] and activeSessions[source].timerActive then
            SpawnBot(source, activeSessions[source])
        end
    end)
end

-- Fonction pour calculer les récompenses
local function CalculateRewards(session, source)
    if not Config.Rewards.enabled or not ESX then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local totalMoney = 0
    local totalXP = 0
    
    for _, milestone in ipairs(Config.Rewards.killMilestones) do
        if session.kills >= milestone.kills then
            totalMoney = milestone.money
            totalXP = milestone.xp
        end
    end
    
    if session.kills > 0 then
        local headshotPercent = math.floor((session.headshots / session.kills) * 100)
        
        if headshotPercent >= Config.Rewards.bonuses.headhunter.threshold then
            totalMoney = totalMoney + Config.Rewards.bonuses.headhunter.money
            totalXP = totalXP + Config.Rewards.bonuses.headhunter.xp
            TriggerClientEvent('esx:showNotification', source, '🎯 Bonus Headhunter: +' .. Config.Rewards.bonuses.headhunter.money .. '$')
        end
        
        local killsPerMinute = session.kills
        if killsPerMinute >= Config.Rewards.bonuses.speedKiller.threshold then
            totalMoney = totalMoney + Config.Rewards.bonuses.speedKiller.money
            totalXP = totalXP + Config.Rewards.bonuses.speedKiller.xp
            TriggerClientEvent('esx:showNotification', source, '⚡ Bonus Rapidité: +' .. Config.Rewards.bonuses.speedKiller.money .. '$')
        end
    end
    
    if totalMoney > 0 then
        xPlayer.addMoney(totalMoney)
        TriggerClientEvent('esx:showNotification', source, '💰 Récompense totale: ' .. totalMoney .. '$')
    end
    
    print('[Training] Player ' .. source .. ' earned: ' .. totalMoney .. '$ and ' .. totalXP .. ' XP')
end

-- Fonction pour terminer une session
local function EndTrainingSession(source, returnToLobby)
    if not activeSessions[source] then return end
    
    print('[Training] ===== ENDING SESSION =====')
    print('[Training] Player: ' .. source)
    
    local session = activeSessions[source]
    session.timerActive = false
    
    if playerStats[source] then
        playerStats[source].totalKills = playerStats[source].totalKills + session.kills
        playerStats[source].totalHeadshots = playerStats[source].totalHeadshots + session.headshots
        
        if session.kills > playerStats[source].bestScore then
            playerStats[source].bestScore = session.kills
            TriggerClientEvent('esx:showNotification', source, Config.Messages.newRecord)
        end
    end
    
    CalculateRewards(session, source)
    
    for _, botData in ipairs(session.bots) do
        if DoesEntityExist(botData.entity) then
            DeleteEntity(botData.entity)
        end
    end
    
    TriggerClientEvent('training:sessionEnded', source, session.kills)
    TriggerClientEvent('training:cleanupBots', source)
    
    print('[Training] ✅ Session ended')
    print('[Training] =========================')
    
    SetTimeout(3000, function()
        if returnToLobby then
            TriggerClientEvent('training:teleportToLobby', source)
        end
        
        SetPlayerRoutingBucket(source, 0)
        activeSessions[source] = nil
    end)
end

-- Fonction pour gérer le timer
local function StartSessionTimer(source)
    if not activeSessions[source] then return end
    
    local session = activeSessions[source]
    local duration = Config.Training.duration
    
    print('[Training] ⏰ Timer started: ' .. duration .. ' seconds')
    
    CreateThread(function()
        for i = duration, 0, -1 do
            if not activeSessions[source] or not session.timerActive then
                print('[Training] ⏰ Timer stopped early')
                break
            end
            
            TriggerClientEvent('training:updateTimer', source, i)
            
            Wait(1000)
            
            if i == 0 then
                print('[Training] ⏰ Timer finished!')
                EndTrainingSession(source, true)
            end
        end
    end)
end

-- Événement: Démarrer une session d'entraînement
RegisterNetEvent('training:startSession')
AddEventHandler('training:startSession', function(difficulty)
    local source = source
    difficulty = difficulty or 'medium'
    
    print('[Training] ========================================')
    print('[Training] 🎮 START SESSION REQUEST')
    print('[Training] Player: ' .. source)
    print('[Training] Difficulty: ' .. difficulty)
    print('[Training] ========================================')
    
    if activeSessions[source] then
        print('[Training] ❌ Player already has active session!')
        return
    end
    
    local bucketId = CreateTrainingSession(source, difficulty)
    
    TriggerClientEvent('training:teleportToTraining', source)
    
    Wait(1500)
    
    print('[Training] 🤖 Spawning ' .. Config.Training.maxBots .. ' bots...')
    
    for i = 1, Config.Training.maxBots do
        print('[Training] Spawning bot ' .. i .. '/' .. Config.Training.maxBots)
        SpawnBot(source, activeSessions[source])
        Wait(200)
    end
    
    print('[Training] ✅ All bots spawned!')
    
    StartSessionTimer(source)
    
    print('[Training] ========================================')
    print('[Training] 🎮 SESSION STARTED SUCCESSFULLY')
    print('[Training] ========================================')
end)

-- Événement: Arrêter une session d'entraînement
RegisterNetEvent('training:stopSession')
AddEventHandler('training:stopSession', function()
    local source = source
    print('[Training] 🛑 Stop session request from player ' .. source)
    
    if activeSessions[source] then
        EndTrainingSession(source, true)
    end
end)

-- Événement: Un bot a été tué
RegisterNetEvent('training:botKilled')
AddEventHandler('training:botKilled', function(botNetId, isHeadshot)
    local source = source
    
    if not activeSessions[source] then return end
    
    activeSessions[source].kills = activeSessions[source].kills + 1
    
    if isHeadshot then
        activeSessions[source].headshots = activeSessions[source].headshots + 1
        print('[Training] 💀 HEADSHOT! Player ' .. source .. ' - Total: ' .. activeSessions[source].headshots)
    else
        print('[Training] ✓ Kill! Player ' .. source .. ' - Total: ' .. activeSessions[source].kills)
    end
    
    TriggerClientEvent('training:updateKills', source, activeSessions[source].kills, isHeadshot)
    
    RespawnBot(source)
end)

-- Commande pour voir ses stats
RegisterCommand('trainstats', function(source, args, rawCommand)
    if playerStats[source] then
        local stats = playerStats[source]
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {"📊 Statistiques", string.format(
                "\nParties: %d | Kills: %d | Headshots: %d | Record: %d",
                stats.gamesPlayed,
                stats.totalKills,
                stats.totalHeadshots,
                stats.bestScore
            )}
        })
    end
end, false)

-- Gestion de la déconnexion
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    if activeSessions[source] then
        print('[Training] Player ' .. source .. ' disconnected, cleaning session')
        
        for _, botData in ipairs(activeSessions[source].bots) do
            if DoesEntityExist(botData.entity) then
                DeleteEntity(botData.entity)
            end
        end
        
        activeSessions[source] = nil
    end
end)

-- Nettoyage à l'arrêt
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('[Training] Cleaning all sessions...')
    
    for source, session in pairs(activeSessions) do
        for _, botData in ipairs(session.bots) do
            if DoesEntityExist(botData.entity) then
                DeleteEntity(botData.entity)
            end
        end
        
        SetPlayerRoutingBucket(source, 0)
        TriggerClientEvent('training:cleanupBots', source)
    end
    
    activeSessions = {}
end)

-- Commande debug
RegisterCommand('training:debug', function(source, args)
    if source == 0 then
        print('[Training] ===== DEBUG INFO =====')
        local count = 0
        for _ in pairs(activeSessions) do count = count + 1 end
        print('[Training] Active sessions: ' .. count)
        for playerId, session in pairs(activeSessions) do
            print(string.format('[Training] Player %d - Bucket: %d - Kills: %d - Headshots: %d - Bots: %d',
                playerId, session.bucketId, session.kills, session.headshots, #session.bots))
        end
        print('[Training] ====================')
    end
end, true)

print('[Training] ===== SERVER READY =====')