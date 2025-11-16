$(document).ready(function() {
    console.log('[Training NUI] Script loaded');
    
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
    
    // Gestion des événements de boutons
    $('#startButton').click(function() {
        console.log('[Training NUI] Start button clicked');
        sendToClient('startTraining');
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
                break;
                
            case 'closeMenu':
                console.log('[Training NUI] Closing menu');
                $('#mainMenu').addClass('hidden');
                break;
                
            case 'showHUD':
                console.log('[Training NUI] Showing HUD');
                $('#trainingHUD').removeClass('hidden');
                $('#killsCount').text(data.kills || 0);
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
                break;
                
            case 'updateTimer':
                console.log('[Training NUI] Updating timer:', data.time);
                $('#timerDisplay').text(formatTime(data.time));
                
                // Changer la couleur si moins de 10 secondes
                if (data.time <= 10) {
                    $('#timerDisplay').css('color', '#eb3349');
                } else {
                    $('#timerDisplay').css('color', '#fff');
                }
                break;
                
            default:
                console.log('[Training NUI] Unknown action:', data.action);
        }
    });
    
    console.log('[Training NUI] All event listeners attached');
});
