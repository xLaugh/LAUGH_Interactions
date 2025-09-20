ESX = exports["es_extended"]:getSharedObject()  

local webhookUrl = "DISCORD_WEBHOOK_URL"

local playersBeingSearched = {}

local playersCarrying = {}
local playersBeingCarried = {}

function SendDiscordWebhook(playerId, coords)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    
    local playerName = GetPlayerName(playerId)
    local steamHex = GetPlayerIdentifier(playerId, 0) or "Inconnu"
    local job = xPlayer.job.name or "Inconnu"
    local jobGrade = xPlayer.job.grade_label or "Inconnu"
    local firstName = xPlayer.get('firstName') or "Inconnu"
    local lastName = xPlayer.get('lastName') or "Inconnu"
    
    local message = {
        embeds = {
            {
                title = "Pneu crevé",
                color = 16711680,
                description = "Un joueur a crevé un pneu",
                fields = {
                    {name = "Pseudo Steam", value = playerName, inline = true},
                    {name = "Prénom Nom RP", value = firstName .. " " .. lastName, inline = true},
                    {name = "Steam Hex", value = steamHex, inline = false},
                    {name = "Coordonnées", value = "X: " .. coords.x .. ", Y: " .. coords.y .. ", Z: " .. coords.z, inline = false},
                    {name = "Métier", value = job .. " - " .. jobGrade, inline = true}
                },
            }
        }
    }
    
    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode(message), {['Content-Type'] = 'application/json'})
end

RegisterServerEvent('esx_policeinteractions:handcufftargetid')
AddEventHandler('esx_policeinteractions:handcufftargetid', function(targetid, playerheading, playerCoords,  playerlocation)
    _source = source
    TriggerClientEvent('esx_policeinteractions:targetcloseplayer', targetid, playerheading, playerCoords, playerlocation)
    TriggerClientEvent('esx_policeinteractions:player', _source)
end)

RegisterServerEvent('esx_policeinteractions:allunlockcuff')
AddEventHandler('esx_policeinteractions:allunlockcuff', function(targetid, playerheading, playerCoords,  playerlocation)
    _source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.job.name == 'police' then
        TriggerClientEvent('esx_policeinteractions:getuncuffed', targetid, playerheading, playerCoords, playerlocation)
        TriggerClientEvent('esx_policeinteractions:douncuffing', _source)
        xPlayer.addInventoryItem('handcuff', 1)
    else
        TriggerClientEvent('esx:showNotification', _source, "Vous n'êtes pas autorisé à démenotter quelqu'un")
    end
end)

RegisterServerEvent('esx_policeinteractions:requestarrest')
AddEventHandler('esx_policeinteractions:requestarrest', function(targetid, playerheading, playerCoords,  playerlocation)
    _source = source
    TriggerClientEvent('esx_policeinteractions:getarrested', targetid, playerheading, playerCoords, playerlocation)
    TriggerClientEvent('esx_policeinteractions:doarrested', _source)
end)

RegisterServerEvent("esx_policeinteractions:removehandcuff")
AddEventHandler("esx_policeinteractions:removehandcuff", function()
    _source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local handcuff = xPlayer.getInventoryItem('handcuff').count
    
    if handcuff >= 1 then  
        xPlayer.removeInventoryItem('handcuff', 1)
        TriggerClientEvent('esx_policeinteractions:re', _source)
    else
        TriggerClientEvent('esx:showNotification', _source, "Vous n'avez pas de menottes")
    end
end)

RegisterServerEvent('esx_policeinteractions:attachPlayer',function(who,anim)
	local xPlayer = ESX.GetPlayerFromId(source)
	local _source = source
	
	if anim == 'carry' then
		if playersCarrying[_source] then
			if playersCarrying[_source] == who then
				playersCarrying[_source] = nil
				playersBeingCarried[who] = nil
			else
				TriggerClientEvent('esx:showNotification', _source, "Vous portez déjà quelqu'un")
				return
			end
		elseif playersBeingCarried[_source] then
			TriggerClientEvent('esx:showNotification', _source, "Vous ne pouvez pas porter quelqu'un car vous êtes déjà porté")
			return
		elseif playersBeingCarried[who] then
			TriggerClientEvent('esx:showNotification', _source, "Cette personne est déjà portée par quelqu'un d'autre")
			return
		elseif playersCarrying[who] then
			TriggerClientEvent('esx:showNotification', _source, "Cette personne porte déjà quelqu'un")
			return
		else
			playersCarrying[_source] = who
			playersBeingCarried[who] = _source
		end
	elseif anim == 'escort' then
		if playersCarrying[_source] then
			if playersCarrying[_source] == who then
				playersCarrying[_source] = nil
				playersBeingCarried[who] = nil
			else
				TriggerClientEvent('esx:showNotification', _source, "Vous portez déjà quelqu'un")
				return
			end
		elseif playersBeingCarried[_source] then
			TriggerClientEvent('esx:showNotification', _source, "Vous ne pouvez pas escorter quelqu'un car vous êtes déjà porté")
			return
		elseif playersBeingCarried[who] then
			TriggerClientEvent('esx:showNotification', _source, "Cette personne est déjà portée par quelqu'un d'autre")
			return
		elseif playersCarrying[who] then
			TriggerClientEvent('esx:showNotification', _source, "Cette personne porte déjà quelqu'un")
			return
		else
			playersCarrying[_source] = who
			playersBeingCarried[who] = _source
		end
	end
	
	TriggerClientEvent('esx_policeinteractions:doAnimation',_source,anim)
	TriggerClientEvent('esx_policeinteractions:getDragged',who, _source, anim)
end)
  

RegisterNetEvent('esx_policeinteractions:putInVehicle')
AddEventHandler('esx_policeinteractions:putInVehicle', function(target)
	TriggerClientEvent('esx_policeinteractions:putInVehicle', target)
end)

RegisterNetEvent('esx_policeinteractions:OutVehicle')
AddEventHandler('esx_policeinteractions:OutVehicle', function(target)
	TriggerClientEvent('esx_policeinteractions:OutVehicle', target)
end)

RegisterNetEvent('esx_policeinteractions:sech')
AddEventHandler('esx_policeinteractions:sech', function(target)
	local xPlayer = ESX.GetPlayerFromId(source)
	
	TriggerClientEvent('esx_policeinteractions:sech', target)
end)


RegisterServerEvent("SlashTires:TargetClient")
AddEventHandler("SlashTires:TargetClient", function(client, tireIndex)
	TriggerClientEvent("SlashTires:SlashClientTire", client, tireIndex)
end)

RegisterServerEvent("SlashTires:LogTireSlash")
AddEventHandler("SlashTires:LogTireSlash", function(coords)
    local _source = source
    SendDiscordWebhook(_source, coords)
end)

RegisterServerEvent('esx_policeinteractions:openInventory')
AddEventHandler('esx_policeinteractions:openInventory', function(target)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(target)
    
    if xPlayer and tPlayer then
        exports.ox_inventory:forceOpenInventory(source, 'player', target)
        TriggerClientEvent('esx:showNotification', target, "~r~Quelqu'un est en train de vous fouiller.")
    end
end)

RegisterServerEvent('esx_policeinteractions:setBeingSearched')
AddEventHandler('esx_policeinteractions:setBeingSearched', function(target, status)
    local source = source
    
    if status then
        playersBeingSearched[target] = source
        TriggerClientEvent('esx_policeinteractions:setSearchedStatus', target, true, source)
    else
        playersBeingSearched[target] = nil
        TriggerClientEvent('esx_policeinteractions:setSearchedStatus', target, false, nil)
    end
end)

RegisterServerEvent('esx_policeinteractions:handsDown')
AddEventHandler('esx_policeinteractions:handsDown', function(searcher)
    local source = source
    
    if searcher then
        TriggerClientEvent('esx_policeinteractions:closeInventory', searcher)
    end
    
    for target, searcherID in pairs(playersBeingSearched) do
        if searcherID == searcher then
            playersBeingSearched[target] = nil
            break
        end
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    
    for target, searcher in pairs(playersBeingSearched) do
        if searcher == source then
            playersBeingSearched[target] = nil
            TriggerClientEvent('esx_policeinteractions:setSearchedStatus', target, false, nil)
        end
    end
    
    if playersBeingSearched[source] then
        local searcher = playersBeingSearched[source]
        playersBeingSearched[source] = nil
        TriggerClientEvent('esx_policeinteractions:closeInventory', searcher)
    end
    
    if playersCarrying[source] then
        local target = playersCarrying[source]
        playersCarrying[source] = nil
        playersBeingCarried[target] = nil
        TriggerClientEvent('esx_policeinteractions:getDragged', target, source, 'carry')
    end
    
    if playersBeingCarried[source] then
        local carrier = playersBeingCarried[source]
        playersBeingCarried[source] = nil
        playersCarrying[carrier] = nil
        TriggerClientEvent('esx_policeinteractions:doAnimation', carrier, 'carry')
    end
end)
