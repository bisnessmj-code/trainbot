$(document).ready(function() {
    console.log('[Training NUI] Improved script loaded');
    
    let selectedDifficulty = 'medium'; // Difficulté par défaut
    
    // Fonction pour envoyer des messages au client
    function sendToClient(action, data = {}) {
        console.log('[Training NUI] Sending to client:', action, data);
        $.post(`https://${GetParentResourceName()}/${action}`, JSON.stringify(data));
    }
    
    // Fonction pour formater le temps (secondes vers mm:ss)
    function formatTime(seconds) {
        const minutes = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    
    // Fonction pour animer le compteur de kills
    function animateKills() {
        $('#killsCount').addClass('pulse');
        setTimeout(() => {
            $('#killsCount').removeClass('pulse');
        }, 300);
    }
    
    // 🆕 Fonction pour animer les headshots
    function animateHeadshots() {
        $('#headshotsCount').addClass('pulse headshot-glow');
        setTimeout(() => {
            $('#headshotsCount').removeClass('pulse headshot-glow');
        }, 500);
    }
    
    // 🆕 Fonction pour animer la série
    function animateStreak(streakCount) {
        const $streak = $('#streakCount');
        $streak.addClass('pulse');
        
        // Effet spécial pour les séries élevées
        if (streakCount >= 10) {
            $streak.addClass('streak-fire');
        } else {
            $streak.removeClass('streak-fire');
        }
        
        setTimeout(() => {
            $streak.removeClass('pulse');
        }, 300);
    }
    
    // 🆕 Gestion de la sélection de difficulté
    $('.difficulty-btn').click(function() {
        $('.difficulty-btn').removeClass('active');
        $(this).addClass('active');
        selectedDifficulty = $(this).data('difficulty');
        console.log('[Training NUI] Difficulty selected:', selectedDifficulty);
    });
    
    // Gestion des événements de boutons
    $('#startButton').click(function() {
        console.log('[Training NUI] Start button clicked with difficulty:', selectedDifficulty);
        sendToClient('startTraining', { difficulty: selectedDifficulty });
    });
    
    $('#closeButton').click(function() {
        console.log('[Training NUI] Close button clicked');
        sendToClient('close');
    });
    
    $('#quitButton').click(function() {
        console.log('[Training NUI] Quit button clicked');
        sendToClient('stopTraining');
    });
    
    // Fermer le menu avec Escape
    $(document).keyup(function(e) {
        if (e.key === "Escape" && !$('#mainMenu').hasClass('hidden')) {
            console.log('[Training NUI] ESC pressed, closing menu');
            sendToClient('close');
        }
    });
    
    // Écoute des messages venant du client
    window.addEventListener('message', function(event) {
        const data = event.data;
        console.log('[Training NUI] Received message:', data);
        
        switch(data.action) {
            case 'openMenu':
                console.log('[Training NUI] Opening menu');
                $('#mainMenu').removeClass('hidden');
                
                // Désactiver le bouton start si déjà en entraînement
                if (data.isTraining) {
                    $('#startButton').prop('disabled', true).text('Entraînement en cours...');
                } else {
                    $('#startButton').prop('disabled', false).html('<span class="btn-icon">▶</span> Lancer l\'entraînement');
                }
                
                // 🆕 Afficher/masquer le sélecteur de difficulté
                if (data.difficulties) {
                    $('#difficultySelector').show();
                } else {
                    $('#difficultySelector').hide();
                }
                break;
                
            case 'closeMenu':
                console.log('[Training NUI] Closing menu');
                $('#mainMenu').addClass('hidden');
                break;
                
            case 'showHUD':
                console.log('[Training NUI] Showing HUD');
                $('#trainingHUD').removeClass('hidden');
                $('#killsCount').text(data.kills || 0);
                $('#headshotsCount').text(data.headshots || 0);
                $('#streakCount').text(data.streak || 0);
                $('#accuracyPercent').text((data.accuracy || 0) + '%');
                $('#timerDisplay').text(formatTime(data.time || 60));
                break;
                
            case 'hideHUD':
                console.log('[Training NUI] Hiding HUD');
                $('#trainingHUD').addClass('hidden');
                break;
                
            case 'updateKills':
                console.log('[Training NUI] Updating kills:', data.kills);
                $('#killsCount').text(data.kills);
                animateKills();
                
                // 🆕 Mettre à jour les headshots
                if (data.headshots !== undefined) {
                    $('#headshotsCount').text(data.headshots);
                    
                    // Vérifier si c'est un nouveau headshot
                    const oldHeadshots = parseInt($('#headshotsCount').text()) || 0;
                    if (data.headshots > oldHeadshots) {
                        animateHeadshots();
                    }
                }
                
                // 🆕 Mettre à jour la série
                if (data.streak !== undefined) {
                    $('#streakCount').text(data.streak);
                    animateStreak(data.streak);
                }
                
                // 🆕 Mettre à jour la précision
                if (data.accuracy !== undefined) {
                    $('#accuracyPercent').text(data.accuracy + '%');
                    
                    // Changer la couleur selon la précision
                    const $accuracy = $('#accuracyPercent');
                    if (data.accuracy >= 80) {
                        $accuracy.css('color', '#4CAF50'); // Vert
                    } else if (data.accuracy >= 50) {
                        $accuracy.css('color', '#FFC107'); // Orange
                    } else {
                        $accuracy.css('color', '#F44336'); // Rouge
                    }
                }
                break;
                
            case 'updateTimer':
                console.log('[Training NUI] Updating timer:', data.time);
                $('#timerDisplay').text(formatTime(data.time));
                
                // Changer la couleur et animation si moins de 10 secondes
                const $timer = $('#timerDisplay');
                if (data.time <= 10) {
                    $timer.css('color', '#eb3349');
                    
                    // Animation de pulsation pour les dernières secondes
                    if (data.time <= 5) {
                        $timer.addClass('timer-urgent');
                    }
                } else {
                    $timer.css('color', '#fff');
                    $timer.removeClass('timer-urgent');
                }
                break;
                
            default:
                console.log('[Training NUI] Unknown action:', data.action);
        }
    });
    
    console.log('[Training NUI] All event listeners attached');
});