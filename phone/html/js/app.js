let currentApp = 'home';
let messages = [];
let contacts = [];
let notes = [];
let photos = [];
let balance = 0;
let transactions = [];
let phoneNumber = '';
let currentCall = null;
let isPlaying = false;
let currentSongIndex = 0;

const playlist = [
    { title: 'Los Santos Nights', artist: 'Radio LS' },
    { title: 'San Andreas Groove', artist: 'K-DST' },
    { title: 'Grove Street Anthem', artist: 'Bounce FM' },
    { title: 'Desert Wind', artist: 'Radio X' },
    { title: 'Vinewood Dreams', artist: 'SF-UR' }
];

function updateTime() {
    const now = new Date();
    document.getElementById('time').textContent = 
        now.getHours().toString().padStart(2, '0') + ':' + 
        now.getMinutes().toString().padStart(2, '0');
}
setInterval(updateTime, 1000);
updateTime();

function updatePhoneInfo(data) {
    phoneNumber = data.number;
    document.getElementById('phone-number').textContent = data.number;
    document.getElementById('my-number').textContent = data.number;
    document.getElementById('battery').textContent = data.battery > 20 ? '\uD83D\uDD0B' : '\uD83E\uDEAB';
}

function goHome() {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById('home-screen').classList.add('active');
    currentApp = 'home';
    hideNewForms();
}

function hideNewForms() {
    document.getElementById('new-message-form').classList.add('hidden');
    document.getElementById('new-contact-form').classList.add('hidden');
    document.getElementById('new-note-form').classList.add('hidden');
}

document.querySelectorAll('.app').forEach(app => {
    app.addEventListener('click', () => {
        const appName = app.dataset.app;
        openApp(appName);
    });
});

function openApp(name) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById(name + '-screen').classList.add('active');
    currentApp = name;
    hideNewForms();
    
    if (name === 'weather') updateWeather();
    if (name === 'music') loadPlaylist();
}

function loadMessages(msgs) {
    messages = msgs;
    const list = document.getElementById('message-list');
    list.innerHTML = '';
    
    const grouped = {};
    msgs.forEach(msg => {
        const key = msg.from;
        if (!grouped[key]) grouped[key] = [];
        grouped[key].push(msg);
    });
    
    Object.keys(grouped).forEach(from => {
        const lastMsg = grouped[from][grouped[from].length - 1];
        const div = document.createElement('div');
        div.className = 'message-item';
        div.innerHTML = 
            '<span class="sender">' + from + '</span>' +
            '<span class="time">' + formatTime(lastMsg.time) + '</span>' +
            '<div class="preview">' + lastMsg.text.substring(0, 40) + (lastMsg.text.length > 40 ? '...' : '') + '</div>';
        div.onclick = () => showConversation(from);
        list.appendChild(div);
    });
}

function showConversation(from) {
    const list = document.getElementById('message-list');
    list.innerHTML = '';
    
    messages.filter(m => m.from === from || m.to === from).forEach(msg => {
        const div = document.createElement('div');
        div.className = 'message-item';
        const isMine = msg.to === from;
        div.innerHTML = 
            '<span class="' + (isMine ? 'sender' : '') + '">' + (isMine ? 'Sen' : msg.from) + '</span>' +
            '<span class="time">' + formatTime(msg.time) + '</span>' +
            '<div class="preview">' + msg.text + '</div>';
        list.appendChild(div);
    });
    
    const replyDiv = document.createElement('div');
    replyDiv.style.padding = '10px';
    replyDiv.innerHTML = 
        '<textarea id="reply-text" placeholder="Yanit yaz..."></textarea>' +
        '<button onclick="replyMessage(\'' + from + '\')">Gonder</button>';
    list.appendChild(replyDiv);
}

function showNewMessage() {
    document.getElementById('new-message-form').classList.toggle('hidden');
}

function sendMessage() {
    const number = document.getElementById('msg-number').value;
    const text = document.getElementById('msg-text').value;
    
    if (!number || !text) return;
    
    mta.invokeEvent('phone:sendSMS', number, text);
    document.getElementById('msg-number').value = '';
    document.getElementById('msg-text').value = '';
    hideNewForms();
}

function replyMessage(to) {
    const text = document.getElementById('reply-text').value;
    if (!text) return;
    mta.invokeEvent('phone:sendSMS', to, text);
    document.getElementById('reply-text').value = '';
}

function newMessageNotification(data) {
    const list = document.getElementById('message-list');
    const div = document.createElement('div');
    div.className = 'message-item';
    div.innerHTML = 
        '<span class="sender">' + data.from + '</span>' +
        '<span class="time">' + formatTime(data.time) + '</span>' +
        '<div class="preview">' + data.text + '</div>';
    list.insertBefore(div, list.firstChild);
}

function onMessageSent(data) {
    const list = document.getElementById('message-list');
    const div = document.createElement('div');
    div.className = 'message-item';
    div.innerHTML = 
        '<span class="sender">Sen -> ' + data.to + '</span>' +
        '<span class="time">' + formatTime(data.time) + '</span>' +
        '<div class="preview">' + data.text + '</div>';
    list.appendChild(div);
}

function loadContacts(cts) {
    contacts = cts;
    const list = document.getElementById('contact-list');
    list.innerHTML = '';
    
    cts.forEach(c => {
        const div = document.createElement('div');
        div.className = 'contact-item';
        div.innerHTML = 
            '<div class="name">' + (c.favorite ? '\u2B50 ' : '') + c.name + '</div>' +
            '<div class="number">' + c.number + '</div>' +
            '<div class="actions">' +
                '<button onclick="callContact(\'' + c.number + '\')">\uD83D\uDCDE</button>' +
                '<button onclick="messageContact(\'' + c.number + '\')">\uD83D\uDCAC</button>' +
                '<button onclick="toggleFav(' + c.id + ')">' + (c.favorite ? '\u2605' : '\u2606') + '</button>' +
                '<button onclick="deleteContact(' + c.id + ')" style="background:#FF3B30">\uD83D\uDDD1</button>' +
            '</div>';
        list.appendChild(div);
    });
}

function showNewContact() {
    document.getElementById('new-contact-form').classList.toggle('hidden');
}

function addContact() {
    const name = document.getElementById('contact-name').value;
    const number = document.getElementById('contact-number').value;
    
    if (!name || !number) return;
    
    mta.invokeEvent('phone:addContact', name, number);
    document.getElementById('contact-name').value = '';
    document.getElementById('contact-number').value = '';
    hideNewForms();
}

function deleteContact(id) {
    mta.invokeEvent('phone:deleteContact', id);
}

function toggleFav(id) {
    mta.invokeEvent('phone:toggleFavorite', id);
}

function callContact(number) {
    document.getElementById('dial-number').value = number;
    makeCall();
}

function messageContact(number) {
    document.getElementById('msg-number').value = number;
    openApp('messages');
    showNewMessage();
}

function dialPress(key) {
    const input = document.getElementById('dial-number');
    input.value += key;
}

function makeCall() {
    const number = document.getElementById('dial-number').value;
    if (!number) return;
    
    mta.invokeEvent('phone:startCall', number);
    document.getElementById('call-screen').classList.remove('hidden');
    document.getElementById('call-number').textContent = number;
    document.getElementById('call-status').textContent = 'Araniyor...';
}

function incomingCall(data) {
    document.getElementById('incoming-call-screen').classList.remove('hidden');
    document.getElementById('incoming-number').textContent = data.from;
    currentCall = data;
}

function acceptCall() {
    mta.invokeEvent('phone:acceptCall');
    document.getElementById('incoming-call-screen').classList.add('hidden');
    document.getElementById('call-screen').classList.remove('hidden');
    document.getElementById('call-number').textContent = currentCall.from;
    document.getElementById('call-status').textContent = 'Baglandi';
}

function rejectCall() {
    mta.invokeEvent('phone:rejectCall');
    document.getElementById('incoming-call-screen').classList.add('hidden');
    currentCall = null;
}

function endCall() {
    mta.invokeEvent('phone:endCall');
    document.getElementById('call-screen').classList.add('hidden');
    document.getElementById('incoming-call-screen').classList.add('hidden');
    document.getElementById('dial-number').value = '';
    currentCall = null;
}

function callStarted(data) {
    document.getElementById('call-status').textContent = 'Araniyor...';
}

function callConnected(data) {
    document.getElementById('call-status').textContent = 'Baglandi';
    document.getElementById('call-timer').textContent = '00:00';
}

function callEnded(data) {
    document.getElementById('call-status').textContent = 'Arama bitti: ' + data.reason;
    setTimeout(() => {
        document.getElementById('call-screen').classList.add('hidden');
        document.getElementById('dial-number').value = '';
    }, 2000);
}

function callFailed(reason) {
    document.getElementById('call-status').textContent = 'Hata: ' + reason;
    setTimeout(() => {
        document.getElementById('call-screen').classList.add('hidden');
        document.getElementById('dial-number').value = '';
    }, 2000);
}

function updateCallTime(time) {
    document.getElementById('call-timer').textContent = time;
}

function updateBalance(data) {
    balance = data.balance;
    transactions = data.transactions || [];
    document.getElementById('balance-amount').textContent = '$' + balance.toLocaleString();
    
    const list = document.getElementById('transaction-list');
    list.innerHTML = '';
    
    transactions.slice().reverse().forEach(tx => {
        const div = document.createElement('div');
        div.className = 'transaction-item';
        div.innerHTML = 
            '<div>' + tx.from + ' -> ' + tx.to + '</div>' +
            '<div class="amount">$' + tx.amount.toLocaleString() + '</div>' +
            '<div class="time">' + formatTime(tx.time) + '</div>';
        list.appendChild(div);
    });
}

function transferMoney() {
    const number = document.getElementById('transfer-number').value;
    const amount = parseInt(document.getElementById('transfer-amount').value);
    
    if (!number || !amount) return;
    
    mta.invokeEvent('phone:transferMoney', number, amount);
    document.getElementById('transfer-number').value = '';
    document.getElementById('transfer-amount').value = '';
}

function transferSuccess(data) {
    updateBalance(data);
    showNotification('Basarili', 'Transfer tamamlandi!');
}

function loadNotes(n) {
    notes = n;
    const list = document.getElementById('note-list');
    list.innerHTML = '';
    
    n.forEach(note => {
        const div = document.createElement('div');
        div.className = 'note-item';
        div.innerHTML = 
            '<div>' + note.text + '</div>' +
            '<div class="time">' + formatTime(note.time) + '</div>' +
            '<button class="delete-btn" onclick="deleteNote(' + note.id + ')">\uD83D\uDDD1</button>';
        list.appendChild(div);
    });
}

function showNewNote() {
    document.getElementById('new-note-form').classList.toggle('hidden');
}

function saveNote() {
    const text = document.getElementById('note-text').value;
    if (!text) return;
    
    mta.invokeEvent('phone:saveNote', text);
    document.getElementById('note-text').value = '';
    hideNewForms();
}

function deleteNote(id) {
    mta.invokeEvent('phone:deleteNote', id);
}

function loadPhotos(p) {
    photos = p;
    const grid = document.getElementById('photo-grid');
    grid.innerHTML = '';
    
    document.getElementById('no-photos').style.display = p.length === 0 ? 'block' : 'none';
    
    p.forEach(photo => {
        const div = document.createElement('div');
        div.className = 'photo-item';
        div.innerHTML = 
            '\uD83D\uDCF7' +
            '<button class="delete-btn" onclick="deletePhoto(' + photo.id + ')">x</button>';
        grid.appendChild(div);
    });
}

function deletePhoto(id) {
    mta.invokeEvent('phone:deletePhoto', id);
}

function callTaxi() {
    document.getElementById('call-taxi-btn').disabled = true;
    document.getElementById('taxi-status').classList.remove('hidden');
    document.getElementById('taxi-status-text').textContent = 'Taksi araniyor...';
    
    mta.invokeEvent('phone:callTaxi');
}

function taxiComing(data) {
    document.getElementById('taxi-status-text').textContent = 
        'Taksi yolda! Tahmini sure: ' + data.eta + ' saniye';
}

function taxiArrived(data) {
    document.getElementById('taxi-status-text').textContent = 
        'Taksi geldi! Ucret: $' + data.cost;
    document.getElementById('call-taxi-btn').disabled = false;
}

function updateWeather() {
    const weathers = [
        { icon: '\u2600\uFE0F', temp: 28, desc: 'Gunesli', humidity: 35, wind: 8 },
        { icon: '\u26C5', temp: 22, desc: 'Parcali Bulutlu', humidity: 50, wind: 15 },
        { icon: '\uD83C\uDF27\uFE0F', temp: 18, desc: 'Yagmurlu', humidity: 75, wind: 20 },
        { icon: '\uD83C\uDF24\uFE0F', temp: 25, desc: 'Az Bulutlu', humidity: 40, wind: 10 },
        { icon: '\uD83C\uDF19', temp: 15, desc: 'Acik Gece', humidity: 55, wind: 5 }
    ];
    
    const w = weathers[Math.floor(Math.random() * weathers.length)];
    document.getElementById('weather-icon').textContent = w.icon;
    document.getElementById('weather-temp').textContent = w.temp + 'C';
    document.getElementById('weather-desc').textContent = w.desc;
    document.getElementById('weather-humidity').textContent = w.humidity + '%';
    document.getElementById('weather-wind').textContent = w.wind + ' km/h';
}

function loadPlaylist() {
    const list = document.getElementById('playlist');
    list.innerHTML = '';
    
    playlist.forEach((song, i) => {
        const div = document.createElement('div');
        div.className = 'playlist-item';
        div.textContent = song.title + ' - ' + song.artist;
        div.onclick = () => playSong(i);
        list.appendChild(div);
    });
}

function playSong(index) {
    currentSongIndex = index;
    const song = playlist[index];
    document.getElementById('song-title').textContent = song.title;
    document.getElementById('song-artist').textContent = song.artist;
    isPlaying = true;
    document.getElementById('play-btn').textContent = '\u23F8';
}

function togglePlay() {
    isPlaying = !isPlaying;
    document.getElementById('play-btn').textContent = isPlaying ? '\u23F8' : '\u25B6';
}

function nextSong() {
    currentSongIndex = (currentSongIndex + 1) % playlist.length;
    playSong(currentSongIndex);
}

function prevSong() {
    currentSongIndex = (currentSongIndex - 1 + playlist.length) % playlist.length;
    playSong(currentSongIndex);
}

function setWaypoint() {
    mta.invokeEvent('phone:setWaypoint');
}

function changeWallpaper() {
    const wallpaper = document.getElementById('wallpaper-select').value;
    document.getElementById('phone').className = 'wallpaper-' + wallpaper;
    mta.invokeEvent('phone:settingsUpdate', { wallpaper: wallpaper });
}

function changeBrightness() {
    const brightness = document.getElementById('brightness-slider').value;
    document.getElementById('screen').style.filter = 'brightness(' + (brightness / 100) + ')';
    mta.invokeEvent('phone:settingsUpdate', { brightness: parseInt(brightness) });
}

function requestPlayerList() {
    mta.invokeEvent('phone:debugAllPlayers');
}

function loadPlayerList(players) {
    let msg = 'Oyuncular:\n';
    players.forEach(p => {
        msg += p.name + ' -> ' + p.number + '\n';
    });
    alert(msg);
}

function showError(message) {
    showNotification('Hata', message);
}

function showNotification(title, text) {
    const notif = document.getElementById('notification');
    document.getElementById('notif-title').textContent = title;
    document.getElementById('notif-text').textContent = text;
    notif.classList.remove('hidden');
    
    setTimeout(() => {
        notif.classList.add('hidden');
    }, 3000);
}

function formatTime(time) {
    if (!time) return '';
    const h = (time.hour || 0).toString().padStart(2, '0');
    const m = (time.minute || 0).toString().padStart(2, '0');
    return h + ':' + m;
}