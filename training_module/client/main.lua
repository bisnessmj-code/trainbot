-- Script client du module d'entraînement (VERSION AMÉLIORÉE)
print('[Training Client] Loading improved version...')

-- Variables globales
local lobbyNPC = nil
local isTrainingActive = false
local nearNPC = false
local kills = 0
local headshots = 0
local totalShots = 0
local hits = 0
local bestStreak = 0
local currentStreak = 0
local timeRemaining = 0
local selectedDifficulty = 'medium'

-- Fonction de notification simple
local function ShowNotification(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

-- 🆕 Notification avancée avec couleur
local function ShowAdvancedNotification(message, type)
    local colors = {
        success = '~g~',
        warning = '~o~',
        error = '~r~',
        info = '~b~',
        special = '~p~'
    }
    
    local color = colors[type] or ''
    ShowNotification(color .. message)
end

-- Fonction pour afficher le texte d'aide
local function ShowHelpNotification(message)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- Fonction pour spawner le PNJ de lobby
local function SpawnLobbyNPC()
    print('[Training Client] Spawning lobby NPC')
    
    local model = GetHashKey(Config.LobbyNPC.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    lobbyNPC = CreatePed(4, model, Config.LobbyNPC.coords.x, Config.LobbyNPC.coords.y, Config.LobbyNPC.coords.z - 1.0, Config.LobbyNPC.coords.w, false, true)
    
    SetEntityAsMissionEntity(lobbyNPC, true, true)
    SetBlockingOfNonTemporaryEvents(lobbyNPC, true)
    SetPedDiesWhenInjured(lobbyNPC, false)
    SetPedCanPlayAmbientAnims(lobbyNPC, true)
    SetPedCanRagdollFromPlayerImpact(lobbyNPC, false)
    SetEntityInvincible(lobbyNPC, true)
    FreezeEntityPosition(lobbyNPC, true)
    
    RequestAnimDict(Config.LobbyNPC.animation.dict)
    while not HasAnimDictLoaded(Config.LobbyNPC.animation.dict) do
        Wait(100)
    end
    
    TaskPlayAnim(lobbyNPC, Config.LobbyNPC.animation.dict, Config.LobbyNPC.animation.anim, 8.0, 0.0, -1, 1, 0, false, false, false)
    
    SetModelAsNoLongerNeeded(model)
    
    print('[Training Client] Lobby NPC spawned successfully')
end

-- Fonction pour ouvrir l'interface NUI
local function OpenTrainingUI()
    print('[Training Client] Opening NUI')
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMenu',
        isTraining = isTrainingActive,
        difficulties = Config.Difficulty.enabled and Config.Difficulty or nil
    })
end

-- Fonction pour fermer l'interface NUI
local function CloseTrainingUI()
    print('[Training Client] Closing NUI')
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeMenu'
    })
end

-- 🆕 Fonction pour reset les stats
local function ResetStats()
    kills = 0
    headshots = 0
    totalShots = 0
    hits = 0
    currentStreak = 0
end

-- Fonction pour démarrer l'entraînement
local function StartTraining(difficulty)
    print('[Training Client] Starting training session with difficulty: ' .. difficulty)
    isTrainingActive = true
    selectedDifficulty = difficulty or 'medium'
    
    -- Reset stats
    ResetStats()
    timeRemaining = Config.Training.duration
    
    CloseTrainingUI()
    
    -- Notifier le serveur avec la difficulté
    TriggerServerEvent('training:startSession', selectedDifficulty)
    
    -- Afficher le HUD
    SendNUIMessage({
        action = 'showHUD',
        kills = kills,
        time = timeRemaining,
        headshots = headshots,
        accuracy = 0,
        streak = 0
    })
    
    ShowAdvancedNotification(Config.Messages.trainingStart, 'success')
end

-- Fonction pour arrêter l'entraînement
local function StopTraining()
    print('[Training Client] Stopping training session')
    isTrainingActive = false
    
    SendNUIMessage({
        action = 'hideHUD'
    })
    
    TriggerServerEvent('training:stopSession')
    
    -- Calculer les stats finales
    local accuracy = totalShots > 0 and math.floor((hits / totalShots) * 100) or 0
    local headshotPercent = kills > 0 and math.floor((headshots / kills) * 100) or 0
    
    ShowNotification(string.format(Config.Messages.finalScore, kills))
    
    if Config.Stats.enabled then
        Wait(1000)
        ShowNotification(string.format('Headshots: %s (%s%%)', headshots, headshotPercent))
        Wait(500)
        ShowNotification(string.format('Précision: %s%%', accuracy))
        Wait(500)
        ShowNotification(string.format('Meilleure série: %s kills', bestStreak))
    end
end

-- Callbacks NUI
RegisterNUICallback('close', function(data, cb)
    CloseTrainingUI()
    cb('ok')
end)

RegisterNUICallback('startTraining', function(data, cb)
    local difficulty = data.difficulty or 'medium'
    StartTraining(difficulty)
    cb('ok')
end)

RegisterNUICallback('stopTraining', function(data, cb)
    StopTraining()
    cb('ok')
end)

-- Événements serveur
RegisterNetEvent('training:teleportToTraining')
AddEventHandler('training:teleportToTraining', function()
    print('[Training Client] Teleporting to training area')
    
    local playerPed = PlayerPedId()
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(playerPed, Config.TrainingSpawn.x, Config.TrainingSpawn.y, Config.TrainingSpawn.z, false, false, false, true)
    SetEntityHeading(playerPed, Config.TrainingSpawn.w)
    
    Wait(100)
    
    SetEntityHealth(playerPed, 200)
    SetPedArmour(playerPed, 100)
    
    RemoveAllPedWeapons(playerPed, true)
    GiveWeaponToPed(playerPed, GetHashKey(Config.Training.weapon), 9999, false, true)
    SetPedInfiniteAmmo(playerPed, true, GetHashKey(Config.Training.weapon))
    
    RestorePlayerStamina(PlayerId(), 1.0)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
    
    DoScreenFadeIn(500)
end)

RegisterNetEvent('training:teleportToLobby')
AddEventHandler('training:teleportToLobby', function()
    print('[Training Client] Teleporting back to lobby')
    
    local playerPed = PlayerPedId()
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(playerPed, Config.LobbyNPC.coords.x, Config.LobbyNPC.coords.y, Config.LobbyNPC.coords.z, false, false, false, true)
    SetEntityHeading(playerPed, Config.LobbyNPC.coords.w)
    
    RemoveAllPedWeapons(playerPed, true)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    
    DoScreenFadeIn(500)
end)

RegisterNetEvent('training:updateKills')
AddEventHandler('training:updateKills', function(newKills, isHeadshot)
    print('[Training Client] Kills updated: ' .. newKills)
    kills = newKills
    currentStreak = currentStreak + 1
    
    if currentStreak > bestStreak then
        bestStreak = currentStreak
    end
    
    -- 🆕 Gestion des headshots
    if isHeadshot then
        headshots = headshots + 1
        if Config.Stats.trackHeadshots then
            ShowAdvancedNotification(Config.Messages.headshot, 'special')
            
            -- 🆕 Effet sonore headshot
            if Config.VisualEffects.soundEffects.enabled and Config.VisualEffects.soundEffects.onHeadshot then
                PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
            end
        end
    end
    
    -- 🆕 Notification de série
    if currentStreak > 0 and currentStreak % 5 == 0 then
        ShowAdvancedNotification(string.format(Config.Messages.killStreak, currentStreak), 'warning')
    end
    
    if isTrainingActive then
        local accuracy = totalShots > 0 and math.floor((hits / totalShots) * 100) or 0
        
        SendNUIMessage({
            action = 'updateKills',
            kills = kills,
            headshots = headshots,
            accuracy = accuracy,
            streak = currentStreak
        })
        
        -- 🆕 Effet sonore kill
        if Config.VisualEffects.soundEffects.enabled and Config.VisualEffects.soundEffects.onKill then
            PlaySoundFrontend(-1, "BASE_JUMP_PASSED", "HUD_AWARDS", true)
        end
    end
end)

RegisterNetEvent('training:updateTimer')
AddEventHandler('training:updateTimer', function(newTime)
    timeRemaining = newTime
    
    if isTrainingActive then
        SendNUIMessage({
            action = 'updateTimer',
            time = timeRemaining
        })
    end
end)

RegisterNetEvent('training:sessionEnded')
AddEventHandler('training:sessionEnded', function(finalKills)
    print('[Training Client] Session ended with ' .. finalKills .. ' kills')
    
    isTrainingActive = false
    kills = finalKills
    
    SendNUIMessage({
        action = 'hideHUD'
    })
    
    ShowNotification(Config.Messages.trainingEnd)
    Wait(1000)
    
    -- Stats finales
    local accuracy = totalShots > 0 and math.floor((hits / totalShots) * 100) or 0
    local headshotPercent = kills > 0 and math.floor((headshots / kills) * 100) or 0
    
    ShowNotification(string.format(Config.Messages.finalScore, finalKills))
    
    if Config.Stats.enabled then
        Wait(800)
        ShowAdvancedNotification(string.format('💀 Headshots: %s (%s%%)', headshots, headshotPercent), 'info')
        Wait(600)
        ShowAdvancedNotification(string.format('🎯 Précision: %s%%', accuracy), 'info')
        Wait(600)
        ShowAdvancedNotification(string.format('🔥 Meilleure série: %s', bestStreak), 'warning')
    end
end)

-- Gestion des bots
local activeBots = {}

-- 🆕 Fonction pour obtenir un type de bot aléatoire
local function GetRandomBotType()
    if not Config.BotTypes.enabled then
        return nil
    end
    
    local totalChance = 0
    for _, botType in pairs(Config.BotTypes) do
        if botType.spawnChance then
            totalChance = totalChance + botType.spawnChance
        end
    end
    
    local random = math.random(1, totalChance)
    local current = 0
    
    for typeName, botType in pairs(Config.BotTypes) do
        if botType.spawnChance then
            current = current + botType.spawnChance
            if random <= current then
                return typeName, botType
            end
        end
    end
    
    return 'soldier', Config.BotTypes.soldier
end

-- Événement pour configurer et gérer un bot créé par le serveur
RegisterNetEvent('training:configureBotClient')
AddEventHandler('training:configureBotClient', function(botNetId, spawnPoint, botTypeData)
    print('[Training Client] Configuring bot for NetID: ' .. botNetId)
    
    local timeout = 0
    local bot = nil
    
    while timeout < 5000 do
        if NetworkDoesEntityExistWithNetworkId(botNetId) then
            bot = NetworkGetEntityFromNetworkId(botNetId)
            if DoesEntityExist(bot) then
                break
            end
        end
        Wait(100)
        timeout = timeout + 100
    end
    
    if not bot or not DoesEntityExist(bot) then
        print('[Training Client] ERROR: Could not find bot entity')
        return
    end
    
    print('[Training Client] Bot entity found, configuring...')
    
    -- Configuration du bot
    SetEntityAsMissionEntity(bot, true, true)
    SetEntityHealth(bot, botTypeData.health or 200)
    SetPedArmour(bot, botTypeData.armor or 50)
    SetPedCanSwitchWeapon(bot, true)
    SetPedFleeAttributes(bot, 0, false)
    SetPedCombatAttributes(bot, 46, true)
    SetPedCombatAttributes(bot, 5, true)
    SetPedCombatMovement(bot, 2)
    SetPedAlertness(bot, 3)
    SetPedSeeingRange(bot, 100.0)
    SetPedHearingRange(bot, 100.0)
    SetPedAccuracy(bot, botTypeData.accuracy or 40)
    
    -- Donner une arme au bot
    GiveWeaponToPed(bot, GetHashKey(botTypeData.weapon), 250, false, true)
    SetCurrentPedWeapon(bot, GetHashKey(botTypeData.weapon), true)
    
    print('[Training Client] Bot configured successfully')
    
    table.insert(activeBots, {entity = bot, netId = botNetId})
    
    local playerPed = PlayerPedId()
    
    -- Démarrer le comportement du bot
    TaskCombatPed(bot, playerPed, 0, 16)
    
    -- 🆕 Thread pour comportements tactiques améliorés
    CreateThread(function()
        while DoesEntityExist(bot) and not IsEntityDead(bot) and isTrainingActive do
            Wait(math.random(2000, 4000))
            
            if not DoesEntityExist(bot) or IsEntityDead(bot) then break end
            
            local playerPos = GetEntityCoords(playerPed)
            local botPos = GetEntityCoords(bot)
            local distance = #(playerPos - botPos)
            
            -- 🆕 VRAIE ROULADE avec plusieurs animations possibles
            local difficultyConfig = Config.Difficulty[selectedDifficulty] or Config.Difficulty.medium
            local rollChance = difficultyConfig.rollProbability or Config.Training.rollProbability
            
            if math.random(1, 100) <= rollChance then
                print('[Training Client] Bot performing roll')
                
                -- Choisir une animation de roulade aléatoire
                local dodgeAnims = Config.BotBehaviors.dodgeAnimations
                local selectedAnim = dodgeAnims[math.random(1, #dodgeAnims)]
                
                RequestAnimDict(selectedAnim.dict)
                while not HasAnimDictLoaded(selectedAnim.dict) do
                    Wait(100)
                end
                
                -- Direction aléatoire pour la roulade
                local randomHeading = math.random(0, 360)
                SetEntityHeading(bot, randomHeading)
                
                -- Faire la roulade
                TaskPlayAnim(bot, selectedAnim.dict, selectedAnim.anim, 8.0, -8.0, selectedAnim.duration, 0, 0, false, false, false)
                Wait(selectedAnim.duration)
                
                -- Reprendre le combat
                if DoesEntityExist(bot) and not IsEntityDead(bot) then
                    TaskCombatPed(bot, playerPed, 0, 16)
                end
            end
            
            -- 🆕 Comportements tactiques variés
            if Config.BotBehaviors.tacticalMoves.enabled then
                local randomBehavior = math.random(1, 100)
                
                -- Rush vers le joueur
                if randomBehavior <= Config.BotBehaviors.tacticalMoves.rushProbability and distance > 10.0 then
                    print('[Training Client] Bot rushing towards player')
                    TaskGoToEntity(bot, playerPed, -1, 2.0, 3.0, 0, 0)
                    Wait(2000)
                    TaskCombatPed(bot, playerPed, 0, 16)
                    
                -- Chercher une couverture
                elseif randomBehavior <= Config.BotBehaviors.tacticalMoves.coverProbability + Config.BotBehaviors.tacticalMoves.rushProbability then
                    print('[Training Client] Bot seeking cover')
                    TaskSeekCoverFromPed(bot, playerPed, 3000, true)
                    Wait(3000)
                    TaskCombatPed(bot, playerPed, 0, 16)
                end
            end
        end
    end)
    
    -- Thread pour surveiller la mort du bot
    CreateThread(function()
        while DoesEntityExist(bot) and not IsEntityDead(bot) and isTrainingActive do
            Wait(500)
        end
        
        if DoesEntityExist(bot) and IsEntityDead(bot) then
            print('[Training Client] Bot died, NetID: ' .. botNetId)
            
            -- 🆕 Vérifier si c'est un headshot
            local isHeadshot = false
            local cause = GetPedCauseOfDeath(bot)
            local boneHit = GetPedLastDamageBone(bot)
            
            -- Os de la tête : 31086
            if boneHit == 31086 then
                isHeadshot = true
            end
            
            -- Reset streak si le joueur est touché
            currentStreak = currentStreak
            
            -- Notifier le serveur
            TriggerServerEvent('training:botKilled', botNetId, isHeadshot)
            
            -- Retirer de la liste des bots actifs
            for i, botData in ipairs(activeBots) do
                if botData.netId == botNetId then
                    table.remove(activeBots, i)
                    break
                end
            end
        end
    end)
    
    -- 🆕 Thread pour marqueur au-dessus du bot
    if Config.VisualEffects.enabled and Config.VisualEffects.botMarker.enabled then
        CreateThread(function()
            while DoesEntityExist(bot) and not IsEntityDead(bot) and isTrainingActive do
                local botCoords = GetEntityCoords(bot)
                local markerConfig = Config.VisualEffects.botMarker
                
                DrawMarker(
                    markerConfig.type,
                    botCoords.x, botCoords.y, botCoords.z + markerConfig.height,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.3, 0.3, 0.3,
                    markerConfig.color.r, markerConfig.color.g, markerConfig.color.b, markerConfig.color.a,
                    false, false, 2, false, nil, nil, false
                )
                
                Wait(0)
            end
        end)
    end
end)

-- Événement pour nettoyer tous les bots
RegisterNetEvent('training:cleanupBots')
AddEventHandler('training:cleanupBots', function()
    print('[Training Client] Cleaning up all bots')
    activeBots = {}
    currentStreak = 0
end)

-- 🆕 Thread pour tracker les tirs (précision)
CreateThread(function()
    while true do
        Wait(0)
        
        if isTrainingActive and Config.Stats.trackAccuracy then
            local playerPed = PlayerPedId()
            
            if IsPedShooting(playerPed) then
                totalShots = totalShots + 1
                
                -- Vérifier si on touche quelque chose
                local hasHit, hitEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
                
                if hasHit and IsPedAHumanInCurrentTeam(hitEntity) == false then
                    hits = hits + 1
                end
            end
        else
            Wait(500)
        end
    end
end)

-- 🆕 Thread pour reset streak si touché
CreateThread(function()
    while true do
        Wait(100)
        
        if isTrainingActive then
            local playerPed = PlayerPedId()
            
            if HasEntityBeenDamagedByAnyPed(playerPed) then
                if currentStreak > 0 then
                    print('[Training Client] Streak reset - player was hit')
                    currentStreak = 0
                end
                ClearEntityLastDamageEntity(playerPed)
            end
        else
            Wait(1000)
        end
    end
end)

-- Thread pour gérer la proximité avec le PNJ
CreateThread(function()
    while true do
        local sleep = 1000
        
        if not isTrainingActive then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local npcCoords = vector3(Config.LobbyNPC.coords.x, Config.LobbyNPC.coords.y, Config.LobbyNPC.coords.z)
            local distance = #(playerCoords - npcCoords)
            
            if distance < 2.5 then
                sleep = 0
                nearNPC = true
                
                ShowHelpNotification(Config.Messages.pressE)
                
                if IsControlJustReleased(0, 38) then
                    OpenTrainingUI()
                end
            else
                if nearNPC then
                    nearNPC = false
                end
            end
        else
            sleep = 1000
        end
        
        Wait(sleep)
    end
end)

-- Thread pour maintenir la stamina pendant l'entraînement
CreateThread(function()
    while true do
        Wait(1000)
        
        if isTrainingActive then
            local playerPed = PlayerPedId()
            RestorePlayerStamina(PlayerId(), 1.0)
        end
    end
end)

-- Thread pour gérer la touche G (quitter l'entraînement)
CreateThread(function()
    while true do
        Wait(0)
        
        if isTrainingActive then
            -- G = INPUT_CONTEXT = 47
            if IsControlJustReleased(0, 47) then
                print('[Training Client] G pressed, stopping training')
                StopTraining()
            end
            
            -- Afficher le texte au-dessus de la minimap (en bas à gauche)
            SetTextFont(4)
            SetTextScale(0.45, 0.45)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("Appuyez sur ~r~G~w~ pour quitter l'entraînement")
            DrawText(0.015, 0.85) -- Position au-dessus de la minimap
        else
            Wait(1000)
        end
    end
end)

-- Initialisation au chargement du script
CreateThread(function()
    Wait(1000)
    SpawnLobbyNPC()
end)

-- Nettoyage à la déconnexion
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('[Training Client] Resource stopping, cleaning up')
    
    if DoesEntityExist(lobbyNPC) then
        DeleteEntity(lobbyNPC)
    end
    
    for _, botData in ipairs(activeBots) do
        if DoesEntityExist(botData.entity) then
            DeleteEntity(botData.entity)
        end
    end
    
    if isTrainingActive then
        TriggerServerEvent('training:stopSession')
    end
end)

print('[Training Client] Improved script loaded successfully')