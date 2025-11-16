-- Script client du module d'entraînement
print('[Training Client] Loading...')

-- Variables globales
local lobbyNPC = nil
local isTrainingActive = false
local nearNPC = false
local kills = 0
local timeRemaining = 0

-- Fonction de notification simple
local function ShowNotification(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
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
    
    -- Charger et jouer l'animation
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
        isTraining = isTrainingActive
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

-- Fonction pour démarrer l'entraînement
local function StartTraining()
    print('[Training Client] Starting training session')
    isTrainingActive = true
    kills = 0
    timeRemaining = Config.Training.duration
    
    -- Fermer l'UI de menu
    CloseTrainingUI()
    
    -- Notifier le serveur
    TriggerServerEvent('training:startSession')
    
    -- Afficher le HUD
    SendNUIMessage({
        action = 'showHUD',
        kills = kills,
        time = timeRemaining
    })
    
    -- Afficher notification
    ShowNotification(Config.Messages.trainingStart)
end

-- Fonction pour arrêter l'entraînement
local function StopTraining()
    print('[Training Client] Stopping training session')
    isTrainingActive = false
    
    -- Cacher le HUD
    SendNUIMessage({
        action = 'hideHUD'
    })
    
    -- Notifier le serveur
    TriggerServerEvent('training:stopSession')
    
    -- Afficher le score final
    ShowNotification(string.format(Config.Messages.finalScore, kills))
end

-- Callbacks NUI
RegisterNUICallback('close', function(data, cb)
    print('[Training Client] NUI callback: close')
    CloseTrainingUI()
    cb('ok')
end)

RegisterNUICallback('startTraining', function(data, cb)
    print('[Training Client] NUI callback: startTraining')
    StartTraining()
    cb('ok')
end)

RegisterNUICallback('stopTraining', function(data, cb)
    print('[Training Client] NUI callback: stopTraining')
    StopTraining()
    cb('ok')
end)

-- Événements serveur
RegisterNetEvent('training:teleportToTraining')
AddEventHandler('training:teleportToTraining', function()
    print('[Training Client] Teleporting to training area')
    
    local playerPed = PlayerPedId()
    
    -- Téléportation
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(playerPed, Config.TrainingSpawn.x, Config.TrainingSpawn.y, Config.TrainingSpawn.z, false, false, false, true)
    SetEntityHeading(playerPed, Config.TrainingSpawn.w)
    
    Wait(100)
    
    -- Préparer le joueur
    SetEntityHealth(playerPed, 200)
    SetPedArmour(playerPed, 100)
    
    -- Retirer toutes les armes et donner l'arme d'entraînement
    RemoveAllPedWeapons(playerPed, true)
    GiveWeaponToPed(playerPed, GetHashKey(Config.Training.weapon), 9999, false, true)
    SetPedInfiniteAmmo(playerPed, true, GetHashKey(Config.Training.weapon))
    
    -- Stamina illimitée
    RestorePlayerStamina(PlayerId(), 1.0)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
    
    DoScreenFadeIn(500)
    
    print('[Training Client] Player prepared for training')
end)

RegisterNetEvent('training:teleportToLobby')
AddEventHandler('training:teleportToLobby', function()
    print('[Training Client] Teleporting back to lobby')
    
    local playerPed = PlayerPedId()
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(playerPed, Config.LobbyNPC.coords.x, Config.LobbyNPC.coords.y, Config.LobbyNPC.coords.z, false, false, false, true)
    SetEntityHeading(playerPed, Config.LobbyNPC.coords.w)
    
    -- Retirer les armes
    RemoveAllPedWeapons(playerPed, true)
    
    -- Reset stamina
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    
    DoScreenFadeIn(500)
    
    print('[Training Client] Player returned to lobby')
end)

RegisterNetEvent('training:updateKills')
AddEventHandler('training:updateKills', function(newKills)
    print('[Training Client] Kills updated: ' .. newKills)
    kills = newKills
    
    if isTrainingActive then
        SendNUIMessage({
            action = 'updateKills',
            kills = kills
        })
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
    
    -- Cacher le HUD
    SendNUIMessage({
        action = 'hideHUD'
    })
    
    -- Afficher le message de fin
    ShowNotification(Config.Messages.trainingEnd)
    Wait(1000)
    ShowNotification(string.format(Config.Messages.finalScore, finalKills))
end)

-- Gestion des bots
local activeBots = {}

-- Événement pour configurer et gérer un bot créé par le serveur
RegisterNetEvent('training:configureBotClient')
AddEventHandler('training:configureBotClient', function(botNetId, spawnPoint)
    print('[Training Client] Configuring bot for NetID: ' .. botNetId)
    
    -- Attendre que l'entité soit disponible
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
    
    -- Configuration du bot (CÔTÉ CLIENT)
    SetEntityAsMissionEntity(bot, true, true)
    SetEntityHealth(bot, 200)
    SetPedArmour(bot, 50)
    SetPedCanSwitchWeapon(bot, true)
    SetPedFleeAttributes(bot, 0, false)
    SetPedCombatAttributes(bot, 46, true) -- Always fight
    SetPedCombatAttributes(bot, 5, true) -- Can use cover
    SetPedCombatMovement(bot, 2) -- Offensive
    SetPedAlertness(bot, 3)
    SetPedSeeingRange(bot, 100.0)
    SetPedHearingRange(bot, 100.0)
    SetPedAccuracy(bot, 40)
    
    -- Donner une arme au bot
    GiveWeaponToPed(bot, GetHashKey(Config.Training.botWeapon), 250, false, true)
    SetCurrentPedWeapon(bot, GetHashKey(Config.Training.botWeapon), true)
    
    print('[Training Client] Bot configured successfully')
    
    -- Ajouter à la liste des bots actifs
    table.insert(activeBots, {entity = bot, netId = botNetId})
    
    local playerPed = PlayerPedId()
    
    -- Démarrer le comportement du bot
    print('[Training Client] Starting bot behavior')
    
    -- Combat avec le joueur
    TaskCombatPed(bot, playerPed, 0, 16)
    
    -- Thread pour les mouvements aléatoires
    CreateThread(function()
        while DoesEntityExist(bot) and not IsEntityDead(bot) and isTrainingActive do
            Wait(math.random(2000, 5000))
            
            if not DoesEntityExist(bot) or IsEntityDead(bot) then break end
            
            -- Probabilité de faire une roulade
            if math.random(1, 100) <= Config.Training.rollProbability then
                print('[Training Client] Bot performing roll')
                
                -- Charger l'animation de roulade
                RequestAnimDict('move_strafe@stealth')
                while not HasAnimDictLoaded('move_strafe@stealth') do
                    Wait(100)
                end
                
                -- Faire la roulade
                TaskPlayAnim(bot, 'move_strafe@stealth', 'idle', 8.0, -8.0, 1000, 0, 0, false, false, false)
                Wait(1000)
                
                -- Reprendre le combat
                if DoesEntityExist(bot) and not IsEntityDead(bot) then
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
            
            -- Notifier le serveur
            TriggerServerEvent('training:botKilled', botNetId)
            
            -- Retirer de la liste des bots actifs
            for i, botData in ipairs(activeBots) do
                if botData.netId == botNetId then
                    table.remove(activeBots, i)
                    break
                end
            end
        end
    end)
end)

-- Événement pour nettoyer tous les bots
RegisterNetEvent('training:cleanupBots')
AddEventHandler('training:cleanupBots', function()
    print('[Training Client] Cleaning up all bots')
    activeBots = {}
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
                
                -- Afficher le texte d'aide
                ShowHelpNotification(Config.Messages.pressE)
                
                -- Vérifier l'appui sur E
                if IsControlJustReleased(0, 38) then -- INPUT_CONTEXT (E)
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

-- Thread pour gérer la touche F1 (quitter l'entraînement)
CreateThread(function()
    while true do
        Wait(0)
        
        if isTrainingActive then
            -- Vérifier si F1 est pressé (INPUT_REPLAY_START_STOP_RECORDING = 288)
            if IsControlJustReleased(0, 288) then
                print('[Training Client] F1 pressed, stopping training')
                StopTraining()
            end
            
            -- Afficher le texte d'aide
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('Appuyez sur ~INPUT_REPLAY_START_STOP_RECORDING~ pour quitter l\'entraînement')
            EndTextCommandDisplayHelp(0, false, true, -1)
        else
            Wait(1000) -- Réduire la charge quand pas en entraînement
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
    
    -- Nettoyer les bots
    for _, botData in ipairs(activeBots) do
        if DoesEntityExist(botData.entity) then
            DeleteEntity(botData.entity)
        end
    end
    
    if isTrainingActive then
        TriggerServerEvent('training:stopSession')
    end
end)

print('[Training Client] Script loaded successfully')
