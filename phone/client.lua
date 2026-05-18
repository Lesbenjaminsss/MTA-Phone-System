-- Phone System - Client Side
local phoneOpen = false
local phoneBrowser = nil
local phoneNumber = ""
local playerInfo = {}
local currentCall = nil
local callTimer = nil
local browserReady = false

local PHONE_WIDTH = 360
local PHONE_HEIGHT = 720

function createPhoneUI()
    if phoneBrowser then
        destroyElement(phoneBrowser)
        phoneBrowser = nil
    end
    
    phoneBrowser = createBrowser(PHONE_WIDTH, PHONE_HEIGHT, false, true)
    if not phoneBrowser then
        outputChatBox("[Phone] Browser olusturulamadi!")
        return
    end
    
    outputChatBox("[Phone] Browser olusturuldu, bekleniyor...")
end

addEventHandler("onClientBrowserCreated", root, function()
    if source ~= phoneBrowser then return end
    outputChatBox("[Phone] Browser hazir, HTML yukleniyor...")
    
    local testHTML = "<html><body style='background:#1a1a2e;color:white;font-family:Arial;text-align:center;padding-top:200px;'><h1>PHONE CALISIYOR!</h1><p>Browser basarili!</p></body></html>"
    loadBrowserHTML(source, testHTML)
    outputChatBox("[Phone] Test HTML yuklendi!")
end)

addEventHandler("onClientBrowserCreated", phoneBrowser or root, function()
    outputChatBox("[Phone] Browser hazir!")
    browserReady = true
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    outputChatBox("[Phone] Resource basladi!")
    createPhoneUI()
    showCursor(false)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    if phoneBrowser then
        destroyElement(phoneBrowser)
        phoneBrowser = nil
    end
    if callTimer then
        killTimer(callTimer)
    end
end)

function togglePhone()
    outputChatBox("[Phone] Toggle cagrildi! phoneOpen=" .. tostring(phoneOpen))
    
    if not phoneBrowser then
        outputChatBox("[Phone] Browser yok, olusturuluyor...")
        createPhoneUI()
        if not phoneBrowser then
            outputChatBox("[Phone] Browser olusturulamadi!")
            return
        end
    end
    
    phoneOpen = not phoneOpen
    outputChatBox("[Phone] phoneOpen simdi: " .. tostring(phoneOpen))
    
    if phoneOpen then
        showCursor(true)
        setPlayerHudComponentVisible("all", false)
        triggerServerEvent("phone:requestNumber", localPlayer)
        triggerServerEvent("phone:getMessages", localPlayer)
        triggerServerEvent("phone:getContacts", localPlayer)
        triggerServerEvent("phone:getBalance", localPlayer)
        triggerServerEvent("phone:getNotes", localPlayer)
        triggerServerEvent("phone:getPhotos", localPlayer)
    else
        showCursor(false)
        setPlayerHudComponentVisible("all", true)
        if currentCall then
            triggerServerEvent("phone:endCall", localPlayer)
            currentCall = nil
        end
    end
end

bindKey("F1", "down", function()
    outputChatBox("[Phone] F1 basil!")
    togglePhone()
end)

addEvent("phone:togglePhone", true)
addEventHandler("phone:togglePhone", root, function()
    togglePhone()
end)

function isPhoneOpen()
    return phoneOpen
end

addEvent("phone:receiveNumber", true)
addEventHandler("phone:receiveNumber", root, function(data)
    phoneNumber = data.number
    playerInfo = data
    outputChatBox("[Phone] Numara alindi: " .. data.number)
    if phoneBrowser and phoneOpen then
        executeBrowserJavascript(phoneBrowser, 'updatePhoneInfo(' .. toJSON(data) .. ')')
    end
end)

addEvent("phone:receiveMessages", true)
addEventHandler("phone:receiveMessages", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'loadMessages(' .. toJSON(data.messages) .. ')')
    end
end)

addEvent("phone:receiveSMS", true)
addEventHandler("phone:receiveSMS", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'newMessageNotification(' .. toJSON(data) .. ')')
    end
    
    if not phoneOpen then
        outputChatBox("[SMS] " .. data.from .. ": " .. data.text)
    end
end)

addEvent("phone:smsSent", true)
addEventHandler("phone:smsSent", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'onMessageSent(' .. toJSON(data) .. ')')
    end
end)

addEvent("phone:smsError", true)
addEventHandler("phone:smsError", root, function(data)
    outputChatBox("[Phone] SMS Hatasi: " .. data.message)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'showError("' .. data.message .. '")')
    end
end)

addEvent("phone:receiveContacts", true)
addEventHandler("phone:receiveContacts", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'loadContacts(' .. toJSON(data.contacts) .. ')')
    end
end)

addEvent("phone:contactAdded", true)
addEventHandler("phone:contactAdded", root, function(data)
    triggerServerEvent("phone:getContacts", localPlayer)
end)

addEvent("phone:contactsUpdated", true)
addEventHandler("phone:contactsUpdated", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'loadContacts(' .. toJSON(data.contacts) .. ')')
    end
end)

addEvent("phone:incomingCall", true)
addEventHandler("phone:incomingCall", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'incomingCall(' .. toJSON(data) .. ')')
    end
    outputChatBox("[Phone] Gelen arama: " .. data.callerName .. " (" .. data.from .. ")")
end)

addEvent("phone:callStarted", true)
addEventHandler("phone:callStarted", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'callStarted(' .. toJSON(data) .. ')')
    end
end)

addEvent("phone:callConnected", true)
addEventHandler("phone:callConnected", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'callConnected(' .. toJSON(data) .. ')')
    end
    currentCall = { startTime = data.startTime }
end)

addEvent("phone:callEnded", true)
addEventHandler("phone:callEnded", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'callEnded(' .. toJSON(data) .. ')')
    end
    currentCall = nil
end)

addEvent("phone:callFailed", true)
addEventHandler("phone:callFailed", root, function(data)
    outputChatBox("[Phone] Arama basarisiz: " .. data.reason)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'callFailed("' .. data.reason .. '")')
    end
end)

addEvent("phone:receiveBalance", true)
addEventHandler("phone:receiveBalance", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'updateBalance(' .. toJSON(data) .. ')')
    end
end)

addEvent("phone:transferSuccess", true)
addEventHandler("phone:transferSuccess", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'transferSuccess(' .. toJSON(data) .. ')')
    end
end)

addEvent("phone:transferError", true)
addEventHandler("phone:transferError", root, function(data)
    outputChatBox("[Phone] Transfer hatasi: " .. data.message)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'showError("' .. data.message .. '")')
    end
end)

addEvent("phone:moneyReceived", true)
addEventHandler("phone:moneyReceived", root, function(data)
    outputChatBox("[Banka] " .. data.from .. " $" .. data.amount .. " gonderdi!")
    triggerServerEvent("phone:getBalance", localPlayer)
end)

addEvent("phone:receiveNotes", true)
addEventHandler("phone:receiveNotes", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'loadNotes(' .. toJSON(data.notes) .. ')')
    end
end)

addEvent("phone:noteSaved", true)
addEventHandler("phone:noteSaved", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'loadNotes(' .. toJSON(data.notes) .. ')')
    end
end)

addEvent("phone:noteDeleted", true)
addEventHandler("phone:noteDeleted", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'loadNotes(' .. toJSON(data.notes) .. ')')
    end
end)

addEvent("phone:receivePhotos", true)
addEventHandler("phone:receivePhotos", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'loadPhotos(' .. toJSON(data.photos) .. ')')
    end
end)

addEvent("phone:photoSaved", true)
addEventHandler("phone:photoSaved", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'loadPhotos(' .. toJSON(data.photos) .. ')')
    end
end)

addEvent("phone:photoDeleted", true)
addEventHandler("phone:photoDeleted", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'loadPhotos(' .. toJSON(data.photos) .. ')')
    end
end)

addEvent("phone:takeSelfie", true)
addEventHandler("phone:takeSelfie", root, function()
    local x, y, z = getCameraMatrix()
    local px, py, pz = getElementPosition(localPlayer)
    
    triggerServerEvent("phone:savePhoto", localPlayer, {
        type = "selfie",
        position = { x = px, y = py, z = pz }
    })
end)

addEvent("phone:taxiComing", true)
addEventHandler("phone:taxiComing", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'taxiComing(' .. toJSON(data) .. ')')
    end
end)

addEvent("phone:taxiArrived", true)
addEventHandler("phone:taxiArrived", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'taxiArrived(' .. toJSON(data) .. ')')
    end
end)

addEvent("phone:taxiNoMoney", true)
addEventHandler("phone:taxiNoMoney", root, function(data)
    outputChatBox("[Taksi] Yetersiz bakiye! Gerekli: $" .. data.required)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'showError("Yetersiz bakiye! Gerekli: $" .. ' .. data.required .. ')')
    end
end)

addEvent("phone:playerList", true)
addEventHandler("phone:playerList", root, function(data)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'loadPlayerList(' .. toJSON(data.players) .. ')')
    end
end)

function showNotification(title, text)
    outputChatBox("[Bildirim] " .. title .. ": " .. text)
    if phoneBrowser then
        executeBrowserJavascript(phoneBrowser, 'showNotification("' .. title .. '", "' .. text .. '")')
    end
end

function toJSON(value)
    if type(value) == "table" then
        local parts = {}
        for k, v in pairs(value) do
            local key = type(k) == "number" and tostring(k) or '"' .. k .. '"'
            local val
            if type(v) == "string" then
                val = '"' .. v:gsub('"', '\\"') .. '"'
            elseif type(v) == "table" then
                val = toJSON(v)
            elseif type(v) == "boolean" then
                val = v and "true" or "false"
            else
                val = tostring(v)
            end
            table.insert(parts, key .. ":" .. val)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return tostring(value)
end

addEventHandler("onClientRender", root, function()
    if phoneOpen and phoneBrowser then
        local sx, sy = guiGetScreenSize()
        local x = (sx - PHONE_WIDTH) / 2
        local y = (sy - PHONE_HEIGHT) / 2
        
        dxDrawImage(x, y, PHONE_WIDTH, PHONE_HEIGHT, phoneBrowser)
        dxDrawText("PHONE ACIK", x + 10, y + 10, x + PHONE_WIDTH - 10, y + 30, 0xFFFFFFFF, 1.0, "default-bold", "left", "top", false, false, false, 0, 0, 0)
    end
end)

addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY)
    if not phoneOpen or not phoneBrowser then return end
    
    local sx, sy = guiGetScreenSize()
    local phoneX = (sx - PHONE_WIDTH) / 2
    local phoneY = (sy - PHONE_HEIGHT) / 2
    
    if absoluteX >= phoneX and absoluteX <= phoneX + PHONE_WIDTH and
       absoluteY >= phoneY and absoluteY <= phoneY + PHONE_HEIGHT then
        local relX = (absoluteX - phoneX) / PHONE_WIDTH
        local relY = (absoluteY - phoneY) / PHONE_HEIGHT
        
        if state == "down" then
            injectBrowserMouseDown(phoneBrowser, relX, relY, "left")
        else
            injectBrowserMouseUp(phoneBrowser, relX, relY, "left")
        end
    end
end)

addEventHandler("onClientKey", root, function(button, press)
    if not phoneOpen then return end
    
    if button == "mouse_wheel_up" and press then
        injectBrowserMouseWheel(phoneBrowser, 1)
        cancelEvent()
    elseif button == "mouse_wheel_down" and press then
        injectBrowserMouseWheel(phoneBrowser, -1)
        cancelEvent()
    end
end)

function updateCallTimer()
    if currentCall and currentCall.startTime then
        local elapsed = math.floor((getTickCount() - currentCall.startTime) / 1000)
        local minutes = math.floor(elapsed / 60)
        local seconds = elapsed % 60
        local timeStr = string.format("%02d:%02d", minutes, seconds)
        
        if phoneBrowser then
            executeBrowserJavascript(phoneBrowser, 'updateCallTime("' .. timeStr .. '")')
        end
    end
end

callTimer = setTimer(updateCallTimer, 1000, 0)