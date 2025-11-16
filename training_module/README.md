# 🎯 Module d'Entraînement au Combat - FiveM

Module d'entraînement au combat pour FiveM avec système de bots IA, routing buckets, et interface NUI moderne.

## 📋 Caractéristiques

- ✅ **PNJ de lobby** avec animation et interaction
- ✅ **Système de routing buckets** pour isoler les joueurs pendant l'entraînement
- ✅ **Bots IA intelligents** avec comportements aléatoires (marche, course, roulades)
- ✅ **Interface NUI moderne** avec HUD en temps réel
- ✅ **Système de score** avec compteur de kills
- ✅ **Timer de 1 minute** avec affichage en direct
- ✅ **Téléportation automatique** vers la zone d'entraînement
- ✅ **Nettoyage automatique** des entités et retour au lobby
- ✅ **Logs complets** pour faciliter le debug

## 📦 Installation

1. **Télécharger le module**
   - Placez le dossier `training_module` dans votre dossier `resources` de FiveM

2. **Ajouter au server.cfg**
   ```cfg
   ensure training_module
   ```

3. **Dépendances requises**
   - ESX (es_extended)

4. **Redémarrer le serveur**

## 🎮 Utilisation

### Pour les joueurs

1. Rendez-vous aux coordonnées du PNJ de lobby : `-2653.16, -770.69, 5.08`
2. Appuyez sur **E** pour interagir avec le formateur
3. Cliquez sur **"Lancer l'entraînement"**
4. Vous serez téléporté dans une zone d'entraînement isolée
5. Éliminez un maximum de bots en 1 minute
6. Votre score s'affiche en bas à droite
7. Utilisez le bouton **"Quitter l'entraînement"** pour arrêter à tout moment

### Armes et équipement

- **Arme fournie** : Cal.50 (WEAPON_PISTOL50)
- **Munitions** : Infinies
- **Santé** : 200
- **Armure** : 100
- **Stamina** : Illimitée

## ⚙️ Configuration

Modifiez le fichier `config.lua` pour personnaliser :

```lua
-- Position du PNJ de lobby
Config.LobbyNPC.coords = vector4(-2653.160400, -770.690124, 5.083496, 240.94488)

-- Paramètres d'entraînement
Config.Training.duration = 60 -- Durée en secondes
Config.Training.maxBots = 5 -- Nombre de bots simultanés
Config.Training.botRespawnDelay = 3000 -- Délai de respawn (ms)
Config.Training.rollProbability = 15 -- Probabilité de roulade (0-100)
Config.Training.weapon = 'WEAPON_PISTOL50' -- Arme du joueur
Config.Training.botWeapon = 'WEAPON_PISTOL' -- Arme des bots
Config.Training.botModel = 'g_m_y_lost_01' -- Modèle des bots
```

### Points de spawn des bots

Vous pouvez modifier les positions de spawn dans `Config.BotSpawnPoints` :

```lua
Config.BotSpawnPoints = {
    vector4(-1590.501098, -2994.778076, 13.929688, 243.779526),
    vector4(-1588.997802, -3002.637452, 13.929688, 212.598420),
    vector4(-1583.367066, -2994.210938, 13.929688, 260.787414),
    vector4(-1594.562622, -3000.250488, 13.929688, 206.929122),
    vector4(-1584.514282, -2999.459228, 13.929688, 246.614166)
}
```

## 🔧 Fonctionnalités techniques

### Routing Buckets

Le module utilise les routing buckets de FiveM pour isoler chaque session d'entraînement :
- Chaque joueur est assigné à un bucket unique
- Les bots sont créés dans le même bucket que le joueur
- Mode "strict" activé pour éviter les fuites d'entités
- Retour automatique au bucket public (0) à la fin

### Comportement des bots

Les bots disposent de plusieurs comportements :
- **Combat actif** : Attaquent le joueur en permanence
- **Mouvements aléatoires** : Marche, course, déplacements tactiques
- **Roulades** : Probabilité configurable (par défaut 15%)
- **Respawn automatique** : 3 secondes après leur élimination
- **IA adaptative** : Utilisent des couvertures et se déplacent intelligemment

### Système de score

- Compteur de kills mis à jour en temps réel
- Affichage dans le HUD en bas à droite
- Animation visuelle à chaque kill
- Score final affiché à la fin de la session

## 📝 Commandes de debug

### Console serveur

```
training:debug
```
Affiche les informations de toutes les sessions actives (buckets, kills, joueurs).

## 🐛 Résolution des problèmes

### Les bots ne spawnent pas
- Vérifiez que les coordonnées de spawn sont valides
- Vérifiez les logs serveur pour les erreurs de chargement de modèle
- Assurez-vous que le routing bucket est correctement configuré

### Le HUD ne s'affiche pas
- Ouvrez la console F8 et cherchez les erreurs JavaScript
- Vérifiez que jQuery est bien chargé
- Assurez-vous que l'ui_page est bien déclarée dans fxmanifest.lua

### Le joueur n'est pas téléporté
- Vérifiez les coordonnées dans config.lua
- Consultez les logs client pour les erreurs de téléportation

### Les bots restent après la fin de la session
- Vérifiez que l'événement `training:cleanupBots` est bien reçu
- Consultez les logs serveur pour les erreurs de nettoyage

## 📊 Structure des fichiers

```
training_module/
├── fxmanifest.lua          # Manifeste du module
├── config.lua              # Configuration
├── client/
│   └── main.lua           # Script client (PNJ, NUI, interactions)
├── server/
│   └── main.lua           # Script serveur (buckets, bots, sessions)
└── html/
    ├── index.html         # Interface NUI
    ├── style.css          # Styles CSS
    └── script.js          # Logique JavaScript
```

## 🔐 Permissions

Le module n'utilise pas de système de permissions par défaut. Tous les joueurs peuvent accéder au PNJ et lancer un entraînement.

Pour ajouter des restrictions, modifiez le serveur pour vérifier les permissions ESX avant de démarrer une session.

## 📄 Licence

Ce module est fourni tel quel. Vous êtes libre de le modifier selon vos besoins.

## 🤝 Support

Pour toute question ou problème :
1. Vérifiez les logs serveur et client (F8)
2. Consultez la section "Résolution des problèmes"
3. Vérifiez que toutes les dépendances sont installées

## 🎨 Personnalisation de l'interface

L'interface NUI peut être personnalisée en modifiant :
- `html/style.css` pour les couleurs, tailles, et animations
- `html/index.html` pour la structure et les textes
- `html/script.js` pour la logique et les interactions

Exemple de personnalisation des couleurs dans `style.css` :
```css
.btn-primary {
    background: linear-gradient(135deg, #votre_couleur1 0%, #votre_couleur2 100%);
}
```

## ✨ Fonctionnalités futures possibles

- [ ] Classement des meilleurs scores
- [ ] Différents niveaux de difficulté
- [ ] Statistiques détaillées (précision, temps de réaction, etc.)
- [ ] Modes de jeu alternatifs (survie, vagues, etc.)
- [ ] Récompenses pour les meilleurs scores
- [ ] Système de niveaux et progression

---

**Version** : 1.0.0  
**Auteur** : Votre nom  
**Framework** : ESX  
**FiveM Version** : Cerulean
