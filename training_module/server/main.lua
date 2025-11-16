-- Script de gestion des sessions d'entraînement (SERVEUR)
print('[Training] Server script loading...')

local activeSessions = {}
local nextBucketId = 1000

print('[Training] Server script loaded successfully')

-- Fonction pour générer un ID de bucket unique
local function GetNextBucketId()
    nextBucketId = nextBucketId + 1
    return nextBucketId
end

-- Fonction pour créer une session d'entraînement
local function CreateTrainingSession(source)
    print('[Training] Creating training session for player ' .. source)
    
    local bucketId = GetNextBucketId()
    
    activeSessions[source] = {
        bucketId = bucketId,
        kills = 0,
        startTime = os.time(),
        bots = {},
        timerActive = true
    }
    
    -- Assigner le joueur au bucket
    SetPlayerRoutingBucket(source, bucketId)
    SetRoutingBucketEntityLockdownMode(bucketId, 'strict')
    
    print('[Training] Player ' .. source .. ' assigned to bucket ' .. bucketId)
    
    return bucketId
end

-- Fonction pour spawner un bot
local function SpawnBot(source, session)
    if not activeSessions[source] then return end
    
    print('[Training] Spawning bot for player ' .. source)
    
    -- Choisir un point de spawn aléatoire
    local spawnPoint = Config.BotSpawnPoints[math.random(1, #Config.BotSpawnPoints)]
    
    -- Charger le modèle
    local model = GetHashKey(Config.Training.botModel)
    
    -- Créer le bot côté serveur (minimal)
    local bot = CreatePed(4, model, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, true)
    
    if not DoesEntityExist(bot) then
        print('[Training] ERROR: Failed to create bot')
        return
    end
    
    print('[Training] Bot entity created: ' .. bot)
    
    -- IMPORTANT : Assigner le bot au routing bucket (côté serveur uniquement)
    SetEntityRoutingBucket(bot, session.bucketId)
    
    print('[Training] Bot assigned to bucket: ' .. session.bucketId)
    
    -- Obtenir le NetworkId
    local botNetId = NetworkGetNetworkIdFromEntity(bot)
    
    -- Ajouter à la liste des bots de la session
    table.insert(session.bots, {entity = bot, netId = botNetId})
    
    print('[Training] Bot created server-side, NetID: ' .. botNetId .. ', Bucket: ' .. session.bucketId)
    
    -- Notifier le client pour qu'il gère la configuration et le comportement
    TriggerClientEvent('training:configureBotClient', source, botNetId, spawnPoint)
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

-- Fonction pour terminer une session
local function EndTrainingSession(source, returnToLobby)
    if not activeSessions[source] then return end
    
    print('[Training] Ending training session for player ' .. source)
    
    local session = activeSessions[source]
    session.timerActive = false
    
    -- Supprimer tous les bots de la session
    for _, botData in ipairs(session.bots) do
        if DoesEntityExist(botData.entity) then
            print('[Training] Deleting bot entity: ' .. botData.netId)
            DeleteEntity(botData.entity)
        end
    end
    
    -- Notifier le client de la fin de session
    TriggerClientEvent('training:sessionEnded', source, session.kills)
    
    -- Notifier le client pour nettoyer sa liste de bots
    TriggerClientEvent('training:cleanupBots', source)
    
    -- Attendre un peu avant de remettre le joueur dans le monde public
    SetTimeout(3000, function()
        if returnToLobby then
            TriggerClientEvent('training:teleportToLobby', source)
        end
        
        -- Remettre le joueur dans le bucket public
        SetPlayerRoutingBucket(source, 0)
        
        -- Supprimer la session
        activeSessions[source] = nil
        
        print('[Training] Player ' .. source .. ' returned to public bucket')
    end)
end

-- Fonction pour gérer le timer
local function StartSessionTimer(source)
    if not activeSessions[source] then return end
    
    local session = activeSessions[source]
    local duration = Config.Training.duration
    
    CreateThread(function()
        for i = duration, 0, -1 do
            if not activeSessions[source] or not session.timerActive then
                break
            end
            
            -- Mettre à jour le timer côté client
            TriggerClientEvent('training:updateTimer', source, i)
            
            Wait(1000)
            
            -- Fin du timer
            if i == 0 then
                EndTrainingSession(source, true)
            end
        end
    end)
end

-- Événement: Démarrer une session d'entraînement
print('[Training] Registering training:startSession event handler')
RegisterNetEvent('training:startSession')
AddEventHandler('training:startSession', function()
    local source = source
    
    print('[Training] ===== START SESSION EVENT RECEIVED =====')
    print('[Training] Start session request from player ' .. source)
    
    -- Vérifier si le joueur n'a pas déjà une session active
    if activeSessions[source] then
        print('[Training] Player ' .. source .. ' already has an active session')
        return
    end
    
    print('[Training] Creating new session for player ' .. source)
    
    -- Créer la session
    local bucketId = CreateTrainingSession(source)
    
    print('[Training] Session created, teleporting player...')
    
    -- Téléporter le joueur
    TriggerClientEvent('training:teleportToTraining', source)
    
    -- Attendre que le joueur soit téléporté
    Wait(1000)
    
    print('[Training] Spawning ' .. Config.Training.maxBots .. ' bots...')
    
    -- Spawner les bots initiaux
    for i = 1, Config.Training.maxBots do
        print('[Training] Spawning bot ' .. i .. '/' .. Config.Training.maxBots)
        SpawnBot(source, activeSessions[source])
    end
    
    print('[Training] Starting session timer...')
    
    -- Démarrer le timer
    StartSessionTimer(source)
    
    print('[Training] ===== SESSION STARTED =====')
end)

-- Événement: Arrêter une session d'entraînement
RegisterNetEvent('training:stopSession')
AddEventHandler('training:stopSession', function()
    local source = source
    
    print('[Training] Stop session request from player ' .. source)
    
    if activeSessions[source] then
        EndTrainingSession(source, true)
    end
end)

-- Événement: Un bot a été tué
RegisterNetEvent('training:botKilled')
AddEventHandler('training:botKilled', function(botNetId)
    local source = source
    
    if not activeSessions[source] then return end
    
    print('[Training] Bot killed by player ' .. source)
    
    -- Incrémenter les kills
    activeSessions[source].kills = activeSessions[source].kills + 1
    
    -- Mettre à jour le score côté client
    TriggerClientEvent('training:updateKills', source, activeSessions[source].kills)
    
    -- Respawn un nouveau bot
    RespawnBot(source)
end)

-- Gestion de la déconnexion
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    if activeSessions[source] then
        print('[Training] Player ' .. source .. ' disconnected, cleaning up session')
        
        -- Supprimer tous les bots de la session
        for _, botData in ipairs(activeSessions[source].bots) do
            if DoesEntityExist(botData.entity) then
                DeleteEntity(botData.entity)
            end
        end
        
        -- Nettoyer la session sans retour au lobby
        activeSessions[source].timerActive = false
        activeSessions[source] = nil
    end
end)

-- Nettoyage à l'arrêt de la ressource
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('[Training] Resource stopping, cleaning up all sessions')
    
    for source, session in pairs(activeSessions) do
        -- Supprimer tous les bots
        for _, botData in ipairs(session.bots) do
            if DoesEntityExist(botData.entity) then
                DeleteEntity(botData.entity)
            end
        end
        
        -- Remettre tous les joueurs dans le bucket public
        SetPlayerRoutingBucket(source, 0)
        
        -- Nettoyer les bots côté client
        TriggerClientEvent('training:cleanupBots', source)
    end
    
    activeSessions = {}
end)

-- Commande admin pour debug
RegisterCommand('training:debug', function(source, args, rawCommand)
    if source == 0 then -- Console serveur uniquement
        print('[Training] ===== DEBUG INFO =====')
        print('[Training] Active sessions: ' .. tostring(#activeSessions))
        for playerId, session in pairs(activeSessions) do
            print('[Training] Player ' .. playerId .. ' - Bucket: ' .. session.bucketId .. ' - Kills: ' .. session.kills)
        end
        print('[Training] ====================')
    end
end, true)
