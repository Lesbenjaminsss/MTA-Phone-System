-- Phone System - Server Side
local phoneNumbers = {}
local playerData = {}
local activeCalls = {}
local messages = {}
local contacts = {}
local bankAccounts = {}
local notes = {}
local photos = {}
local callChannels = {}

local function generatePhoneNumber()
    math.randomseed(getTickCount())
    return string.format("5%d%d %d%d%d %d%d%d%d",
        math.random(0,9), math.random(0,9),
        math.random(0,9), math.random(0,9), math.random(0,9),
        math.random(0,9), math.random(0,9), math.random(0,9), math.random(0,9)
    )
end

local function cleanNumber(num)
    return num:gsub("[%s%-]", "")
end

addEventHandler("onPlayerJoin", root, function()
    local number = generatePhoneNumber()
    phoneNumbers[source] = number
    playerData[source] = { battery = 100, signal = 100, wallpaper = "default", brightness = 80 }
    bankAccounts[source] = { balance = 5000, transactions = {} }
    contacts[source] = {}
    messages[source] = {}
    notes[source] = {}
    photos[source] = {}
end)

addEventHandler("onPlayerQuit", root, function()
    phoneNumbers[source] = nil
    playerData[source] = nil
    bankAccounts[source] = nil
    contacts[source] = nil
    messages[source] = nil
    notes[source] = nil
    photos[source] = nil
    if activeCalls[source] then
        local other = activeCalls[source].target
        if other and isElement(other) then
            triggerClientEvent(other, "phone:callEnded", other, { reason = "disconnected" })
            activeCalls[other] = nil
        end
        activeCalls[source] = nil
    end
end)

function getPlayerPhoneNumber(player)
    return phoneNumbers[player]
end

function getPlayerBankBalance(player)
    if bankAccounts[player] then
        return bankAccounts[player].balance
    end
    return 0
end

addEvent("phone:requestNumber", true)
addEventHandler("phone:requestNumber", root, function()
    if not playerData[source] then
        playerData[source] = { battery = 100, signal = 100, wallpaper = "default", brightness = 80 }
        phoneNumbers[source] = generatePhoneNumber()
        bankAccounts[source] = { balance = 5000, transactions = {} }
        contacts[source] = {}
        messages[source] = {}
        notes[source] = {}
        photos[source] = {}
    end
    
    triggerClientEvent(source, "phone:receiveNumber", source, {
        number = phoneNumbers[source] or "Yok",
        battery = playerData[source].battery,
        signal = playerData[source].signal,
        wallpaper = playerData[source].wallpaper,
        brightness = playerData[source].brightness
    })
end)

addEvent("phone:sendSMS", true)
addEventHandler("phone:sendSMS", root, function(targetNumber, text)
    local sender = source
    local senderNumber = phoneNumbers[sender]
    local cleanTarget = cleanNumber(targetNumber)
    
    local target = nil
    for p, num in pairs(phoneNumbers) do
        if cleanNumber(num) == cleanTarget then
            target = p
            break
        end
    end
    
    if not target then
        triggerClientEvent(sender, "phone:smsError", sender, { message = "Numara bulunamadi!" })
        return
    end
    
    if target == sender then
        triggerClientEvent(sender, "phone:smsError", sender, { message = "Kendinize mesaj gonderemezsiniz!" })
        return
    end
    
    local msg = {
        id = getTickCount(),
        from = senderNumber,
        to = phoneNumbers[target],
        text = text,
        time = getRealTime(),
        read = false
    }
    
    if not messages[target] then messages[target] = {} end
    table.insert(messages[target], msg)
    
    if not messages[sender] then messages[sender] = {} end
    table.insert(messages[sender], msg)
    
    triggerClientEvent(target, "phone:receiveSMS", target, {
        from = senderNumber,
        text = text,
        time = msg.time,
        id = msg.id
    })
    
    triggerClientEvent(sender, "phone:smsSent", sender, {
        to = phoneNumbers[target],
        text = text,
        time = msg.time,
        id = msg.id
    })
end)

addEvent("phone:getMessages", true)
addEventHandler("phone:getMessages", root, function()
    triggerClientEvent(source, "phone:receiveMessages", source, { messages = messages[source] or {} })
end)

addEvent("phone:markRead", true)
addEventHandler("phone:markRead", root, function(msgId)
    if messages[source] then
        for _, msg in ipairs(messages[source]) do
            if msg.id == msgId then
                msg.read = true
            end
        end
    end
end)

addEvent("phone:addContact", true)
addEventHandler("phone:addContact", root, function(name, number)
    if not contacts[source] then contacts[source] = {} end
    table.insert(contacts[source], { name = name, number = number, favorite = false, id = getTickCount() })
    triggerClientEvent(source, "phone:contactAdded", source, { name = name, number = number })
end)

addEvent("phone:deleteContact", true)
addEventHandler("phone:deleteContact", root, function(contactId)
    if contacts[source] then
        for i, c in ipairs(contacts[source]) do
            if c.id == contactId then
                table.remove(contacts[source], i)
                break
            end
        end
    end
    triggerClientEvent(source, "phone:contactsUpdated", source, { contacts = contacts[source] or {} })
end)

addEvent("phone:toggleFavorite", true)
addEventHandler("phone:toggleFavorite", root, function(contactId)
    if contacts[source] then
        for _, c in ipairs(contacts[source]) do
            if c.id == contactId then
                c.favorite = not c.favorite
                break
            end
        end
    end
    triggerClientEvent(source, "phone:contactsUpdated", source, { contacts = contacts[source] or {} })
end)

addEvent("phone:getContacts", true)
addEventHandler("phone:getContacts", root, function()
    triggerClientEvent(source, "phone:receiveContacts", source, { contacts = contacts[source] or {} })
end)

addEvent("phone:startCall", true)
addEventHandler("phone:startCall", root, function(targetNumber)
    local caller = source
    local callerNumber = phoneNumbers[caller]
    local cleanTarget = cleanNumber(targetNumber)
    
    local target = nil
    for p, num in pairs(phoneNumbers) do
        if cleanNumber(num) == cleanTarget then
            target = p
            break
        end
    end
    
    if not target then
        triggerClientEvent(caller, "phone:callFailed", caller, { reason = "Numara bulunamadi!" })
        return
    end
    
    if target == caller then
        triggerClientEvent(caller, "phone:callFailed", caller, { reason = "Kendinizi arayamazsiniz!" })
        return
    end
    
    if activeCalls[target] then
        triggerClientEvent(caller, "phone:callFailed", caller, { reason = "Hat mesgul!" })
        return
    end
    
    activeCalls[caller] = { target = target, startTime = getTickCount(), status = "ringing" }
    
    triggerClientEvent(target, "phone:incomingCall", target, {
        from = callerNumber,
        callerName = getPlayerName(caller)
    })
    
    triggerClientEvent(caller, "phone:callStarted", caller, {
        to = phoneNumbers[target],
        status = "ringing"
    })
end)

addEvent("phone:acceptCall", true)
addEventHandler("phone:acceptCall", root, function()
    local receiver = source
    local caller = nil
    
    for p, call in pairs(activeCalls) do
        if call.target == receiver then
            caller = p
            break
        end
    end
    
    if not caller then return end
    
    activeCalls[caller].status = "connected"
    activeCalls[receiver] = { target = caller, startTime = getTickCount(), status = "connected" }
    
    local channelName = "phone_" .. tostring(caller) .. "_" .. tostring(receiver)
    callChannels[caller] = channelName
    callChannels[receiver] = channelName
    
    triggerClientEvent(caller, "phone:callConnected", caller, { startTime = getTickCount() })
    triggerClientEvent(receiver, "phone:callConnected", receiver, { startTime = getTickCount() })
    
    setPlayerVoiceChannel(caller, channelName)
    setPlayerVoiceChannel(receiver, channelName)
    setPlayerVoiceIgnoreRadio(caller, true)
    setPlayerVoiceIgnoreRadio(receiver, true)
end)

addEvent("phone:rejectCall", true)
addEventHandler("phone:rejectCall", root, function()
    local receiver = source
    local caller = nil
    
    for p, call in pairs(activeCalls) do
        if call.target == receiver then
            caller = p
            break
        end
    end
    
    if caller then
        triggerClientEvent(caller, "phone:callEnded", caller, { reason = "reddedildi" })
        activeCalls[caller] = nil
    end
end)

addEvent("phone:endCall", true)
addEventHandler("phone:endCall", root, function()
    local player = source
    
    if activeCalls[player] then
        local other = activeCalls[player].target
        if other and isElement(other) then
            triggerClientEvent(other, "phone:callEnded", other, { reason = "kapatildi" })
            activeCalls[other] = nil
            callChannels[other] = nil
            setPlayerVoiceIgnoreRadio(other, false)
        end
        activeCalls[player] = nil
        callChannels[player] = nil
        setPlayerVoiceIgnoreRadio(player, false)
    end
end)

addEvent("phone:getBalance", true)
addEventHandler("phone:getBalance", root, function()
    if bankAccounts[source] then
        triggerClientEvent(source, "phone:receiveBalance", source, {
            balance = bankAccounts[source].balance,
            transactions = bankAccounts[source].transactions
        })
    end
end)

addEvent("phone:transferMoney", true)
addEventHandler("phone:transferMoney", root, function(targetNumber, amount)
    local sender = source
    
    if not bankAccounts[sender] then return end
    if amount <= 0 then
        triggerClientEvent(sender, "phone:transferError", sender, { message = "Gecersiz miktar!" })
        return
    end
    if bankAccounts[sender].balance < amount then
        triggerClientEvent(sender, "phone:transferError", sender, { message = "Yetersiz bakiye!" })
        return
    end
    
    local cleanTarget = cleanNumber(targetNumber)
    local target = nil
    for p, num in pairs(phoneNumbers) do
        if cleanNumber(num) == cleanTarget then
            target = p
            break
        end
    end
    
    if not target then
        triggerClientEvent(sender, "phone:transferError", sender, { message = "Alici bulunamadi!" })
        return
    end
    
    bankAccounts[sender].balance = bankAccounts[sender].balance - amount
    if not bankAccounts[target] then bankAccounts[target] = { balance = 0, transactions = {} } end
    bankAccounts[target].balance = bankAccounts[target].balance + amount
    
    local tx = {
        id = getTickCount(),
        from = phoneNumbers[sender],
        to = phoneNumbers[target],
        amount = amount,
        time = getRealTime(),
        type = "transfer"
    }
    
    table.insert(bankAccounts[sender].transactions, tx)
    table.insert(bankAccounts[target].transactions, tx)
    
    triggerClientEvent(sender, "phone:transferSuccess", sender, {
        balance = bankAccounts[sender].balance,
        transactions = bankAccounts[sender].transactions
    })
    
    if isElement(target) then
        triggerClientEvent(target, "phone:moneyReceived", target, {
            from = phoneNumbers[sender],
            amount = amount,
            balance = bankAccounts[target].balance
        })
    end
end)

addEvent("phone:saveNote", true)
addEventHandler("phone:saveNote", root, function(text)
    if not notes[source] then notes[source] = {} end
    table.insert(notes[source], { id = getTickCount(), text = text, time = getRealTime() })
    triggerClientEvent(source, "phone:noteSaved", source, { notes = notes[source] })
end)

addEvent("phone:deleteNote", true)
addEventHandler("phone:deleteNote", root, function(noteId)
    if notes[source] then
        for i, n in ipairs(notes[source]) do
            if n.id == noteId then
                table.remove(notes[source], i)
                break
            end
        end
    end
    triggerClientEvent(source, "phone:noteDeleted", source, { notes = notes[source] })
end)

addEvent("phone:getNotes", true)
addEventHandler("phone:getNotes", root, function()
    triggerClientEvent(source, "phone:receiveNotes", source, { notes = notes[source] or {} })
end)

addEvent("phone:savePhoto", true)
addEventHandler("phone:savePhoto", root, function(photoData)
    if not photos[source] then photos[source] = {} end
    table.insert(photos[source], { id = getTickCount(), data = photoData, time = getRealTime() })
    triggerClientEvent(source, "phone:photoSaved", source, { photos = photos[source] })
end)

addEvent("phone:deletePhoto", true)
addEventHandler("phone:deletePhoto", root, function(photoId)
    if photos[source] then
        for i, p in ipairs(photos[source]) do
            if p.id == photoId then
                table.remove(photos[source], i)
                break
            end
        end
    end
    triggerClientEvent(source, "phone:photoDeleted", source, { photos = photos[source] })
end)

addEvent("phone:getPhotos", true)
addEventHandler("phone:getPhotos", root, function()
    triggerClientEvent(source, "phone:receivePhotos", source, { photos = photos[source] or {} })
end)

addEvent("phone:callTaxi", true)
addEventHandler("phone:callTaxi", root, function()
    local player = source
    local x, y, z = getElementPosition(player)
    
    triggerClientEvent(player, "phone:taxiComing", player, {
        eta = math.random(30, 90),
        position = { x = x, y = y, z = z }
    })
    
    local cost = math.random(50, 200)
    if bankAccounts[player] and bankAccounts[player].balance >= cost then
        bankAccounts[player].balance = bankAccounts[player].balance - cost
        triggerClientEvent(player, "phone:taxiArrived", player, { cost = cost })
    else
        triggerClientEvent(player, "phone:taxiNoMoney", player, { required = cost })
    end
end)

addEvent("phone:settingsUpdate", true)
addEventHandler("phone:settingsUpdate", root, function(settings)
    if playerData[source] then
        if settings.wallpaper then playerData[source].wallpaper = settings.wallpaper end
        if settings.brightness then playerData[source].brightness = settings.brightness end
    end
end)

addEvent("phone:debugAllPlayers", true)
addEventHandler("phone:debugAllPlayers", root, function()
    local list = {}
    for p, num in pairs(phoneNumbers) do
        if isElement(p) then
            table.insert(list, { name = getPlayerName(p), number = num })
        end
    end
    triggerClientEvent(source, "phone:playerList", source, { players = list })
end)

function transferMoney(fromPlayer, toPlayer, amount)
    if not bankAccounts[fromPlayer] or not bankAccounts[toPlayer] then return false end
    if bankAccounts[fromPlayer].balance < amount or amount <= 0 then return false end
    
    bankAccounts[fromPlayer].balance = bankAccounts[fromPlayer].balance - amount
    bankAccounts[toPlayer].balance = bankAccounts[toPlayer].balance + amount
    return true
end

addCommandHandler("selfie", function(player)
    triggerClientEvent(player, "phone:takeSelfie", player)
end)

addCommandHandler("telefon", function(player)
    triggerClientEvent(player, "phone:togglePhone", player)
end)