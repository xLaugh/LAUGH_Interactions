ESX = exports["es_extended"]:getSharedObject()  
local ox_inventory = exports.ox_inventory 

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
	ESX.PlayerLoaded = false
	ESX.PlayerData = {}
end)


RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)
local isEscorting = false 
local isAttached = false

local Tonyhandecuff = false
local cuffObj
local dragnotify = nil
local sechde = false

local tireSlashCount = 0
local lastTireSlashTime = 0
local maxTireSlashes = 4
local cooldownTime = 2400000
local beingSearched = false
local searchingPlayer = nil

function loadanimdict(dictname)
	if not HasAnimDictLoaded(dictname) then
		RequestAnimDict(dictname) 
		while not HasAnimDictLoaded(dictname) do 
			Citizen.Wait(1)
		end
	end
end

function IsPlayerHandsUp(ped)
    local handsUpAnims = {
        {'missminuteman_1ig_2', 'handsup_base'},
        {'random@mugging3', 'handsup_standing_base'},
        {'random@arrests@busted', 'idle_a'},
        {'mp_arresting', 'idle'},
        {'random@arrests', 'idle_2_hands_up'},
        {'random@getawaydriver', 'idle_2b'},
        {'anim@mp_player_intuppersurrender', 'idle_a'},
    }
    
    for _, anim in ipairs(handsUpAnims) do
        if IsEntityPlayingAnim(ped, anim[1], anim[2], 3) and not IsEntityPlayingAnim(ped, 'move_m@generic_variations@walk', 'idle', 3) then
            return true
        end
    end
    
    local rightHandBone = GetPedBoneIndex(ped, 6286)
    local leftHandBone = GetPedBoneIndex(ped, 18905)
    
    if rightHandBone ~= -1 and leftHandBone ~= -1 then
        local rightHandPos = GetWorldPositionOfEntityBone(ped, rightHandBone)
        local leftHandPos = GetWorldPositionOfEntityBone(ped, leftHandBone)
        local headBone = GetPedBoneIndex(ped, 31086)
        local headPos = GetWorldPositionOfEntityBone(ped, headBone)
        
        if (rightHandPos.z > headPos.z - 0.1 or leftHandPos.z > headPos.z - 0.1) then
            if not IsEntityPlayingAnim(ped, 'move_m@generic_variations@walk', 'idle', 3) then
                return true
            end
        end
    end
    
    return false
end

function LoadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(10)
    end
end
function ShowUI(message, icon)
    if icon == 0 then
        lib.showTextUI(message)
    else
        lib.showTextUI(message, {
            icon = icon
        })
    end
end

function HideUI()
    lib.hideTextUI()
end

local policeinteractions = {
  
    {
        name = 'esx_policeinteractions:handcuff',
        event = 'esx_policeinteractions:handcuff',
        icon = 'fa-solid fa-handcuffs',
 
        label = TranslateCap('HandCuff_uncuff'), 
        canInteract = function(entity, distance, coords, name, bone)
            local isHandcuffed = IsEntityPlayingAnim(entity, 'anim@move_m@prisoner_cuffed', 'idle', 3)
            
            if isHandcuffed then
                return not IsEntityDead(entity, distance, coords, name, bone) and ESX.PlayerData.job and ESX.PlayerData.job.name == 'police'
            else
                return not IsEntityDead(entity, distance, coords, name, bone)
            end
        end
    },

	{
        name = 'esx_policeinteractions:sechce',
        event = 'esx_policeinteractions:sechce',
        icon = 'fa-solid fa-magnifying-glass',
 
		label = TranslateCap('Sechce'), 
        canInteract = function(entity, distance, coords, name, bone)
            return not IsEntityDead(entity, distance, coords, name, bone)
        end
    },

    {
        name = 'esx_policeinteractions:putInVehiclece',
        event = 'esx_policeinteractions:putInVehiclece',
        icon = 'fa-solid fa-car',
 
        label = TranslateCap('PutInVehiclece'), 
        canInteract = function(entity, distance, coords, name, bone)
            local isHandcuffed = IsEntityPlayingAnim(entity, 'anim@move_m@prisoner_cuffed', 'idle', 3)
            local isBeingEscorted = IsEntityPlayingAnim(entity, 'move_m@generic_variations@walk', 'idle', 3)
            return not IsEntityDead(entity, distance, coords, name, bone) and isHandcuffed and not isBeingEscorted
        end
    },
    
    {
        name = 'esx_policeinteractions:carry',
        event = 'esx_policeinteractions:carry',
        icon = Config.icon_carry,
        label = Config.carry,
        canInteract = function(entity, distance, coords, name, bone)
            local isHandcuffed = IsEntityPlayingAnim(entity, 'anim@move_m@prisoner_cuffed', 'idle', 3)
            local isBeingCarried = IsEntityPlayingAnim(entity, 'nm', 'firemans_carry', 3)
            local isCarryingSomeone = IsEntityPlayingAnim(entity, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 3)
            local canCarry = not isEscorting and not isAttached
            return not IsEntityDead(entity, distance, coords, name, bone) and not isHandcuffed and not isBeingCarried and not isCarryingSomeone and canCarry
        end
    },
    
    {
        name = 'esx_policeinteractions:carryDead',
        event = 'esx_policeinteractions:carryDead',
        icon = Config.icon_carryDead,
        label = Config.carryDead,
        canInteract = function(entity, distance, coords, name, bone)
            local isDead = IsEntityDead(entity, distance, coords, name, bone)
            local isBeingCarried = IsEntityPlayingAnim(entity, 'nm', 'firemans_carry', 3)
            local isCarryingSomeone = IsEntityPlayingAnim(entity, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 3)
            local canCarry = not isEscorting and not isAttached
            return isDead and not isBeingCarried and not isCarryingSomeone and canCarry
        end
    },
}

exports.ox_target:addGlobalPlayer(policeinteractions)


RegisterNetEvent('esx_policeinteractions:handcuff')
AddEventHandler('esx_policeinteractions:handcuff', function()
	local target, distance = ESX.Game.GetClosestPlayer()
	playerheading = GetEntityHeading(GetPlayerPed(-1))
	playerlocation = GetEntityForwardVector(PlayerPedId())
	playerCoords = GetEntityCoords(GetPlayerPed(-1))
	local target_id = GetPlayerServerId(target)
 
	if distance <= 2.0 then
		local targetPed = GetPlayerPed(target)
		local isHandcuffed = IsEntityPlayingAnim(targetPed, 'anim@move_m@prisoner_cuffed', 'idle', 3)
		local isBeingEscorted = IsEntityPlayingAnim(targetPed, 'move_m@generic_variations@walk', 'idle', 3)
		
		if isHandcuffed and not isBeingEscorted then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
				TriggerServerEvent('esx_policeinteractions:allunlockcuff', target_id, playerheading, playerCoords, playerlocation)
			else
				ESX.ShowNotification("Vous n'êtes pas autorisé à démenotter quelqu'un")
			end
		else
			if not isBeingEscorted then
				TriggerServerEvent('esx_policeinteractions:removehandcuff')
			else
				ESX.ShowNotification("Vous ne pouvez pas menotter une personne qui est en train d'être escortée")
			end
		end
	end
end)	

RegisterNetEvent('esx_policeinteractions:re')
AddEventHandler('esx_policeinteractions:re', function()
	local target, distance = ESX.Game.GetClosestPlayer()
	playerheading = GetEntityHeading(GetPlayerPed(-1))
	playerlocation = GetEntityForwardVector(PlayerPedId())
	playerCoords = GetEntityCoords(GetPlayerPed(-1))
	local target_id = GetPlayerServerId(target)
	TriggerServerEvent('esx_policeinteractions:handcufftargetid', target_id, playerheading, playerCoords, playerlocation)

end	)

 

RegisterNetEvent('esx_policeinteractions:targetcloseplayer')
AddEventHandler('esx_policeinteractions:targetcloseplayer', function(playerheading, playercoords, playerlocation)
 
 

	playerPed = GetPlayerPed(-1)
     SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)  

	local coords = GetEntityCoords(playerPed)
    local hash = `p_cs_cuffs_02_s`
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

	cuffObj = CreateObject(hash,coords,true,false)
	AttachEntityToEntity(cuffObj, playerPed, GetPedBoneIndex(PlayerPedId(), 60309), -0.058, 0.005, 0.090, 290.0, 95.0, 120.0, true, false, false, false, 0, true)
  

 	local x, y, z   = table.unpack(playercoords + playerlocation * 1.0)
	SetEntityCoords(GetPlayerPed(-1), x, y, z)
	SetEntityHeading(GetPlayerPed(-1), playerheading)
	Citizen.Wait(250)
	loadanimdict('mp_arrest_paired')
	TaskPlayAnim(GetPlayerPed(-1), 'mp_arrest_paired', 'crook_p2_back_right', 8.0, -8, 3750, 2, 0, 0, 0, 0)
	Citizen.Wait(3760)
	Tonyhandecuff = true
	LoadAnimDict('anim@move_m@prisoner_cuffed')
	TaskPlayAnim(GetPlayerPed(-1), 'anim@move_m@prisoner_cuffed', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
    DisplayRadar(false)
    SetEnableHandcuffs(playerPed, true)
    DisablePlayerFiring(playerPed, true)
    SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true) 
    SetPedCanPlayGestureAnims(playerPed, false)
    
    exports.ox_target:disableTargeting(true)
end)

 
RegisterNetEvent('esx_policeinteractions:player')
AddEventHandler('esx_policeinteractions:player', function()
 	Citizen.Wait(250)
	loadanimdict('mp_arrest_paired')
	TaskPlayAnim(GetPlayerPed(-1), 'mp_arrest_paired', 'cop_p2_back_right', 8.0, -8,3750, 2, 0, 0, 0, 0)
	Citizen.Wait(3000)

end) 




RegisterNetEvent('esx_policeinteractions:uncuff')
AddEventHandler('esx_policeinteractions:uncuff', function()
	local target, distance = ESX.Game.GetClosestPlayer()
	playerheading = GetEntityHeading(GetPlayerPed(-1))
	playerlocation = GetEntityForwardVector(PlayerPedId())
	playerCoords = GetEntityCoords(GetPlayerPed(-1))
	local target_id = GetPlayerServerId(target)
	TriggerServerEvent('esx_policeinteractions:allunlockcuff', target_id, playerheading, playerCoords, playerlocation)
end)

RegisterNetEvent('esx_policeinteractions:douncuffing')
AddEventHandler('esx_policeinteractions:douncuffing', function()
	Citizen.Wait(250)
	loadanimdict('mp_arresting')
	TaskPlayAnim(GetPlayerPed(-1), 'mp_arresting', 'a_uncuff', 8.0, -8,-1, 2, 0, 0, 0, 0)
	Citizen.Wait(5500)
	ClearPedTasks(GetPlayerPed(-1))
end)

RegisterNetEvent('esx_policeinteractions:getuncuffed')
AddEventHandler('esx_policeinteractions:getuncuffed', function(playerheading, playercoords, playerlocation)
   
	local x, y, z   = table.unpack(playercoords + playerlocation * 1.0)
	SetEntityCoords(GetPlayerPed(-1), x, y, z)
	SetEntityHeading(GetPlayerPed(-1), playerheading)
	Citizen.Wait(250)
	loadanimdict('mp_arresting')
	TaskPlayAnim(GetPlayerPed(-1), 'mp_arresting', 'b_uncuff', 8.0, -8,-1, 2, 0, 0, 0, 0)
	Citizen.Wait(5500)
	Tonyhandecuff = false
 
	ClearPedTasks(GetPlayerPed(-1))
    DisplayRadar(true)
	
    ClearPedSecondaryTask(playerPed)
	SetEnableHandcuffs(playerPed, false)
	DisablePlayerFiring(playerPed, false)
	SetPedCanPlayGestureAnims(playerPed, true)

	DeleteEntity(cuffObj)
    
    exports.ox_target:disableTargeting(false)
end)

RegisterNetEvent('esx_policeinteractions:ft')
AddEventHandler('esx_policeinteractions:ft', function()
	local target, distance = ESX.Game.GetClosestPlayer()
	playerheading = GetEntityHeading(GetPlayerPed(-1))
	playerlocation = GetEntityForwardVector(PlayerPedId())
	playerCoords = GetEntityCoords(GetPlayerPed(-1))
	local target_id = GetPlayerServerId(target)
	TriggerServerEvent('esx_policeinteractions:requestarrest', target_id, playerheading, playerCoords, playerlocation)


end)	
 
RegisterNetEvent('esx_policeinteractions:getarrested')
AddEventHandler('esx_policeinteractions:getarrested', function(playerheading, playercoords, playerlocation)
 
 

	playerPed = GetPlayerPed(-1)
 
    SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)  
 	AttachEntityToEntity(obj2, playerPed, GetPedBoneIndex(playerPed,  57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
	local x, y, z   = table.unpack(playercoords + playerlocation * 1.0)
	SetEntityCoords(GetPlayerPed(-1), x, y, z)
	SetEntityHeading(GetPlayerPed(-1), playerheading)
	Citizen.Wait(250)
	loadanimdict('mp_arrest_paired')
	TaskPlayAnim(GetPlayerPed(-1), 'mp_arrest_paired', 'crook_p2_back_right', 8.0, -8, 3750 , 2, 0, 0, 0, 0)
	Citizen.Wait(3760)
	 
	loadanimdict('mp_arresting')
	TaskPlayAnim(GetPlayerPed(-1), 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
    DisplayRadar(false)
    SetEnableHandcuffs(playerPed, true)
    DisablePlayerFiring(playerPed, true)
    SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)  
    SetPedCanPlayGestureAnims(playerPed, false)

	local coords = GetEntityCoords(PlayerPedId())
    local hash = `p_cs_cuffs_02_s`
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
  
        cuffObj = CreateObject(hash,coords,true,false)
        AttachEntityToEntity(cuffObj, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 60309), -0.055, 0.06, 0.04, 265.0, 155.0, 80.0, true, false, false, false, 0, true) 
  

end)

 
RegisterNetEvent('esx_policeinteractions:doarrested')
AddEventHandler('esx_policeinteractions:doarrested', function()
 	Citizen.Wait(250)
	loadanimdict('mp_arrest_paired')
	TaskPlayAnim(GetPlayerPed(-1), 'mp_arrest_paired', 'cop_p2_back_right', 8.0, -8,3750, 2, 0, 0, 0, 0)
	Citizen.Wait(3000)

end) 
 
 
CreateThread(function()
 	while true do
		local Sleep = 0   
		if isEscorting  and not dragnotify    then
			ShowUI(_U('StopDargging'), 'hand')
		 
			if IsControlJustPressed(0, 183) then
				dragnotify = true
				lib.hideTextUI()
 				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					dragnotify = true

					TriggerServerEvent('esx_policeinteractions:attachPlayer',GetPlayerServerId(closestPlayer),'escort')
				end
              
			end
		elseif dragnotify then
			Wait(1000)
			lib.hideTextUI()
			dragnotify = nil
		 
      
        end

	 
		 



	Wait(Sleep)
	end
end)


CreateThread(function()
	local DisableControlAction = DisableControlAction
	local IsEntityPlayingAnim = IsEntityPlayingAnim
	while true do
		local Sleep = 1000

		if Tonyhandecuff then
			Sleep = 0
			DisableControlAction(0, 24, true) -- Attack
			DisableControlAction(0, 257, true) -- Attack 2
			DisableControlAction(0, 25, true) -- Aim
			DisableControlAction(0, 263, true) -- Melee Attack 1
	 
			DisableControlAction(0, 45, true) -- Reload
			DisableControlAction(0, 22, true) -- Jump
			DisableControlAction(0, 44, true) -- Cover
			DisableControlAction(0, 37, true)
			
			if IsPedInAnyVehicle(PlayerPedId(), false) then
				if IsControlJustPressed(0, 23) then
					TriggerEvent('esx_policeinteractions:OutVehicle')
				end
			end

			DisableControlAction(0, 288,  true)
			DisableControlAction(0, 289, true)
			DisableControlAction(0, 170, true)
			DisableControlAction(0, 167, true)

			DisableControlAction(0, 0, true)
			DisableControlAction(0, 73, true)
			DisableControlAction(2, 199, true)

			DisableControlAction(0, 59, true)
			DisableControlAction(0, 71, true)
			DisableControlAction(0, 72, true)

			DisableControlAction(2, 36, true)

			DisableControlAction(0, 47, true)
			DisableControlAction(0, 264, true)
			DisableControlAction(0, 257, true)
			DisableControlAction(0, 140, true)
			DisableControlAction(0, 141, true)
			DisableControlAction(0, 142, true)
			DisableControlAction(0, 143, true)
			DisableControlAction(0, 75, true)
			DisableControlAction(27, 75, true)
 
			if IsEntityPlayingAnim(playerPed, 'anim@move_m@prisoner_cuffed', 'idle', 3) ~= 1 and not IsEntityPlayingAnim(playerPed, 'move_m@generic_variations@walk', 'idle', 3) then
                playerPed = GetPlayerPed(-1)

				ESX.Streaming.RequestAnimDict('anim@move_m@prisoner_cuffed', function()
					TaskPlayAnim(ESX.PlayerData.ped, 'anim@move_m@prisoner_cuffed', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
					RemoveAnimDict('anim@move_m@prisoner_cuffed')
				end)
			end
		end 

	Wait(Sleep)
	end
end)

 


 

RegisterNetEvent('esx_policeinteractions:escort')
AddEventHandler('esx_policeinteractions:escort', function()
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        TriggerServerEvent('esx_policeinteractions:attachPlayer',GetPlayerServerId(closestPlayer),'escort')
    end
end)

RegisterNetEvent('esx_policeinteractions:doAnimation',function(anim)
    if anim == 'escort' then
        if isEscorting then
            ClearPedTasks(PlayerPedId())
            isEscorting = false
        else
            isEscorting = true
            LoadAnimDict('amb@world_human_drinking@coffee@male@base')
            if IsEntityPlayingAnim(PlayerPedId(), 'amb@world_human_drinking@coffee@male@base','base', 3) ~= 1 then
                TaskPlayAnim(PlayerPedId(), 'amb@world_human_drinking@coffee@male@base','base' ,8.0, -8, -1, 51, 0, false, false, false)
            end
        end
  
    elseif anim == 'carry' then
        if isEscorting then
            ClearPedTasks(PlayerPedId())
            isEscorting = false
        else
            isEscorting = true
            LoadAnimDict('missfinale_c2mcs_1')
            if IsEntityPlayingAnim(PlayerPedId(), 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 3) ~= 1 then
                TaskPlayAnim(PlayerPedId(), 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8, -1, 49, 0, false, false, false)
            end
        end
    end
end)
RegisterNetEvent('esx_policeinteractions:getDragged',function(entToAttach,anim)
    local curAttachedPed = GetPlayerPed(GetPlayerFromServerId(entToAttach))
   
    if anim == 'escort' then
        if not isAttached then
             ClearPedTasks(PlayerPedId())
             isAttached = true
            loadanimdict('move_m@generic_variations@walk')
            TaskPlayAnim(PlayerPedId(), 'move_m@generic_variations@walk', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
            AttachEntityToEntity(PlayerPedId(),curAttachedPed, 1816,0.25, 0.49, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            amBeingEscorted(curAttachedPed)
        else
             isAttached = false
             DetachEntity(PlayerPedId())
            ClearPedTasks(PlayerPedId())
        end
    elseif anim == 'carry' then
        if not isAttached then
            ClearPedTasks(PlayerPedId())
            isAttached = true
            LoadAnimDict('nm')
            TaskPlayAnim(PlayerPedId(), 'nm', 'firemans_carry', 8.0, -8, -1, 33, 0, false, false, false)
            AttachEntityToEntity(PlayerPedId(), curAttachedPed, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, true)
        else
            isAttached = false
            DetachEntity(PlayerPedId())
            ClearPedTasks(PlayerPedId())
        end
    end
end)

function amBeingEscorted(entID)
    CreateThread(function()
        while isAttached do
            Wait(0)
            local speed = GetEntitySpeed(entID)
            if speed > 1 then
                if IsEntityPlayingAnim(PlayerPedId(), 'move_m@generic_variations@walk', 'walk_b', 3) ~= 1 then
                    TaskPlayAnim(PlayerPedId(), 'move_m@generic_variations@walk','walk_b' ,8.0, -8, -1, 0, 0, false, false, false)
                end
            end
        end
    end)

end

RegisterNetEvent('esx_policeinteractions:sechce')
AddEventHandler('esx_policeinteractions:sechce', function()
	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	
	if closestPlayer ~= -1 and closestDistance <= 3.0 then
		local targetPed = GetPlayerPed(closestPlayer)
		local isHandcuffed = IsEntityPlayingAnim(targetPed, 'anim@move_m@prisoner_cuffed', 'idle', 3)
		local isBeingEscorted = IsEntityPlayingAnim(targetPed, 'move_m@generic_variations@walk', 'idle', 3)
		local isHandsUp = IsPlayerHandsUp(targetPed)
		
		if (isHandcuffed and not isBeingEscorted) or isHandsUp then
			if lib.progressBar({
				duration = 5000,
				label = TranslateCap('searching'),
				useWhileDead = false,
				canCancel = true,
				disable = {
					car = true,
				},
				anim = {
					dict = 'anim@gangops@facility@servers@bodysearch@',
					clip = 'player_search'
				},
			}) then 
				OpenBodySearchMenu(closestPlayer)
				TriggerServerEvent('esx_policeinteractions:sech', GetPlayerServerId(closestPlayer))
				ESX.ShowNotification(TranslateCap('search_success'))
			end
		else
			ESX.ShowNotification(TranslateCap('must_be_handcuffed'))
		end
	else
		ESX.ShowNotification(TranslateCap('no_player_nearby'))
	end
end)


RegisterNetEvent('esx_policeinteractions:sech')
AddEventHandler('esx_policeinteractions:sech', function()
 
 
	local playerPed = PlayerPedId(-1)
	sechde = true
	loadanimdict('missminuteman_1ig_2')
	TaskPlayAnim(GetPlayerPed(-1), 'missminuteman_1ig_2', 'handsup_base', 8.0, -8,3750, 2, 0, 0, 0, 0)
	Citizen.Wait(3000)
 
	 

end)
function OpenBodySearchMenu(player)
	TriggerServerEvent('esx_policeinteractions:openInventory', GetPlayerServerId(player))
	
	TriggerServerEvent('esx_policeinteractions:setBeingSearched', GetPlayerServerId(player), true)
end

RegisterNetEvent('esx_policeinteractions:setSearchedStatus')
AddEventHandler('esx_policeinteractions:setSearchedStatus', function(status, searcher)
	beingSearched = status
	searchingPlayer = searcher
	
	if beingSearched then
		StartHandsUpCheck()
	end
end)

function StartHandsUpCheck()
	Citizen.CreateThread(function()
		while beingSearched do
			Citizen.Wait(500)
			
			if not IsPlayerHandsUp(PlayerPedId()) then
				TriggerServerEvent('esx_policeinteractions:handsDown', searchingPlayer)
				beingSearched = false
				searchingPlayer = nil
				break
			end
		end
	end)
end

RegisterNetEvent('esx_policeinteractions:closeInventory')
AddEventHandler('esx_policeinteractions:closeInventory', function()
	exports.ox_inventory:closeInventory()
	ESX.ShowNotification("~r~La personne a baissé les bras, la fouille est annulée")
end)

 RegisterNetEvent('esx_policeinteractions:putInVehiclece')
 AddEventHandler('esx_policeinteractions:putInVehiclece', function()
   local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
   if closestPlayer ~= -1 and closestDistance <= 3.0 then
        TriggerServerEvent('esx_policeinteractions:putInVehicle', GetPlayerServerId(closestPlayer))
    end
 end)


 RegisterNetEvent('esx_policeinteractions:putInVehicle')
AddEventHandler('esx_policeinteractions:putInVehicle', function()
    local playerPed = PlayerPedId()
    local vehicle, distance = ESX.Game.GetClosestVehicle()

    if vehicle and distance < 5 then
        local backSeats = {}
        local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
        
        for i = 2, maxSeats - 1 do
            if IsVehicleSeatFree(vehicle, i) then
                table.insert(backSeats, i)
            end
        end
        
        if #backSeats == 0 then
            for i = 0, maxSeats - 1 do
                if i ~= 0 and IsVehicleSeatFree(vehicle, i) then
                    table.insert(backSeats, i)
                end
            end
        end
        
        if #backSeats > 0 then
            local selectedSeat = backSeats[1]
            
            loadanimdict('mp_arresting')
            TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, false, false, false)
            
            Citizen.Wait(300)
            
            TaskEnterVehicle(playerPed, vehicle, 10000, selectedSeat, 1.0, 1, 0)
        else
            ESX.ShowNotification("~r~Aucune place disponible dans le véhicule")
        end
    else
        ESX.ShowNotification("~r~Aucun véhicule à proximité")
    end
end)


RegisterNetEvent('esx_policeinteractions:OutVehiclece')
AddEventHandler('esx_policeinteractions:OutVehiclece', function()
  local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
  if closestPlayer ~= -1 and closestDistance <= 3.0 then

   TriggerServerEvent('esx_policeinteractions:OutVehicle', GetPlayerServerId(closestPlayer))
  end
end)


RegisterNetEvent('esx_policeinteractions:OutVehicle')
AddEventHandler('esx_policeinteractions:OutVehicle', function()
	local GetVehiclePedIsIn = GetVehiclePedIsIn
	local IsPedSittingInAnyVehicle = IsPedSittingInAnyVehicle
	local TaskLeaveVehicle = TaskLeaveVehicle
	if IsPedSittingInAnyVehicle(ESX.PlayerData.ped) then
		local vehicle = GetVehiclePedIsIn(ESX.PlayerData.ped, false)
		TaskLeaveVehicle(ESX.PlayerData.ped, vehicle, 64)
	end
end)



exports.ox_target:addGlobalVehicle({
	{
		name = 'tireknife',
		icon = Config.icon_tire,
		label = Config.tireknife,
		canInteract = function(entity, distance, coords, name)
			return CanUseWeapon(Config.allowedWeapons) and distance <= 2.0
		end,
		onSelect = function()
			TriggerEvent('tireknife')
		end
	}
})

AddEventHandler('tireknife', function()
    local allowedWeapons = Config.allowedWeapons
    local player = PlayerPedId()
    local vehicle = GetClosestVehicleToPlayer()
    local animDict = "melee@knife@streamed_core_fps"
    local animName = "ground_attack_on_spot"
    
    local currentTime = GetGameTimer()
    if tireSlashCount >= maxTireSlashes then
        if currentTime - lastTireSlashTime < cooldownTime then
            local remainingMinutes = math.ceil((cooldownTime - (currentTime - lastTireSlashTime)) / 60000)
            ESX.ShowNotification("~r~Vous devez attendre " .. remainingMinutes .. " minutes avant de pouvoir crever d'autres pneus")
            return
        else
            tireSlashCount = 0
        end
    end
    
    if vehicle ~= 0 then
        if CanUseWeapon(allowedWeapons) then
            local closestTire = GetClosestVehicleTire(vehicle)
            if closestTire ~= nil then
                ESX.Streaming.RequestAnimDict(animDict, function()
                    TaskPlayAnim(player, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
                    Citizen.Wait(1000)
                    ClearPedTasks(player) 
                end)

                local driverOfVehicle = GetDriverOfVehicle(vehicle)
                local driverServer = GetPlayerServerId(driverOfVehicle)
                
                local playerCoords = GetEntityCoords(player)

                if driverServer == 0 then
                    SetVehicleTyreBurst(vehicle, closestTire.tireIndex, 0, 100.0)
                    tireSlashCount = tireSlashCount + 1
                    if tireSlashCount >= maxTireSlashes then
                        lastTireSlashTime = currentTime
                    end
                    TriggerServerEvent("SlashTires:LogTireSlash", playerCoords)
                else
                    TriggerServerEvent("SlashTires:TargetClient", driverServer, closestTire.tireIndex)
                    tireSlashCount = tireSlashCount + 1
                    if tireSlashCount >= maxTireSlashes then
                        lastTireSlashTime = currentTime
                    end
                    TriggerServerEvent("SlashTires:LogTireSlash", playerCoords)
                end
            else
                ESX.ShowNotification("Aucun pneu à proximité")
            end
        else
            ESX.ShowNotification("Vous devez avoir un couteau")
        end
    else
        ESX.ShowNotification("Aucun véhicule à proximité")
    end
end)

function GetClosestVehicleTire(vehicle)
    local tireBones = {"wheel_lf", "wheel_rf", "wheel_lm1", "wheel_rm1", "wheel_lm2", "wheel_rm2", "wheel_lm3", "wheel_rm3", "wheel_lr", "wheel_rr"}
    local tireIndex = {
        ["wheel_lf"] = 0,
        ["wheel_rf"] = 1,
        ["wheel_lm1"] = 2,
        ["wheel_rm1"] = 3,
        ["wheel_lm2"] = 45,
        ["wheel_rm2"] = 47,
        ["wheel_lm3"] = 46,
        ["wheel_rm3"] = 48,
        ["wheel_lr"] = 4,
        ["wheel_rr"] = 5,
    }
    
    local player = PlayerId()
    local plyPed = GetPlayerPed(player)
    local plyPos = GetEntityCoords(plyPed, false)
    local minDistance = 1.4
    local closestTire = nil
    
    for a = 1, #tireBones do
        local bonePos = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, tireBones[a]))
        local distance = #(plyPos - bonePos)
        
        if distance <= minDistance then
            if closestTire == nil or distance < closestTire.boneDist then
                closestTire = {
                    bone = tireBones[a], 
                    boneDist = distance, 
                    bonePos = bonePos, 
                    tireIndex = tireIndex[tireBones[a]]
                }
            end
        end
    end
    
    return closestTire
end

function GetDriverOfVehicle(vehicle)
	local dPed = GetPedInVehicleSeat(vehicle, -1)
	for a = 0, 32 do
		if dPed == GetPlayerPed(a) then
			return a
		end
	end
	return -1
end

function GetClosestVehicleToPlayer()
	local player = PlayerId()
	local plyPed = GetPlayerPed(player)
	local plyPos = GetEntityCoords(plyPed, false)
	local plyOffset = GetOffsetFromEntityInWorldCoords(plyPed, 0.0, 1.0, 0.0)
	local radius = 3.0
	local rayHandle = StartShapeTestCapsule(plyPos.x, plyPos.y, plyPos.z, plyOffset.x, plyOffset.y, plyOffset.z, radius, 10, plyPed, 7)
	local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
	return vehicle
end

function CanUseWeapon(allowedWeapons)
	local player = PlayerId()
	local plyPed = GetPlayerPed(player)
	local plyCurrentWeapon = GetSelectedPedWeapon(plyPed)
	for a = 1, #allowedWeapons do
		if GetHashKey(allowedWeapons[a]) == plyCurrentWeapon then
			return true
		end
	end
	return false
end

RegisterNetEvent("SlashTires:SlashClientTire")
AddEventHandler("SlashTires:SlashClientTire", function(tireIndex)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle ~= 0 then
        SetVehicleTyreBurst(vehicle, tireIndex, 0, 100.0)
    end
end)

RegisterNetEvent('esx_policeinteractions:carry')
AddEventHandler('esx_policeinteractions:carry', function()
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        local targetPed = GetPlayerPed(closestPlayer)
        local isHandcuffed = IsEntityPlayingAnim(targetPed, 'anim@move_m@prisoner_cuffed', 'idle', 3)
        local isBeingCarried = IsEntityPlayingAnim(targetPed, 'nm', 'firemans_carry', 3)
        
        if isEscorting then
            ESX.ShowNotification("Vous portez déjà quelqu'un")
            return
        end
        
        if isAttached then
            ESX.ShowNotification("Vous ne pouvez pas porter quelqu'un car vous êtes déjà porté")
            return
        end
        
        if isHandcuffed then
            ESX.ShowNotification("Vous ne pouvez pas porter une personne menottée")
            return
        end
        
        if isBeingCarried then
            ESX.ShowNotification("Cette personne est déjà portée par quelqu'un d'autre")
            return
        end
        
        local isCarryingSomeone = IsEntityPlayingAnim(targetPed, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 3)
        if isCarryingSomeone then
            ESX.ShowNotification("Cette personne porte déjà quelqu'un et ne peut pas être portée")
            return
        end
        
        TriggerServerEvent('esx_policeinteractions:attachPlayer', GetPlayerServerId(closestPlayer), 'carry')
    else
        ESX.ShowNotification("Aucun joueur à proximité")
    end
end)

RegisterNetEvent('esx_policeinteractions:carryDead')
AddEventHandler('esx_policeinteractions:carryDead', function()
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        local targetPed = GetPlayerPed(closestPlayer)
        local isBeingCarried = IsEntityPlayingAnim(targetPed, 'nm', 'firemans_carry', 3)
        
        if isEscorting then
            ESX.ShowNotification("Vous portez déjà quelqu'un")
            return
        end
        
        if isAttached then
            ESX.ShowNotification("Vous ne pouvez pas porter quelqu'un car vous êtes déjà porté")
            return
        end
        
        if not IsEntityDead(targetPed) then
            ESX.ShowNotification("Cette personne n'est pas morte")
            return
        end
        
        if isBeingCarried then
            ESX.ShowNotification("Cette personne est déjà portée par quelqu'un d'autre")
            return
        end
        
        local isCarryingSomeone = IsEntityPlayingAnim(targetPed, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 3)
        if isCarryingSomeone then
            ESX.ShowNotification("Cette personne porte déjà quelqu'un et ne peut pas être portée")
            return
        end
        
        TriggerServerEvent('esx_policeinteractions:attachPlayer', GetPlayerServerId(closestPlayer), 'carry')
    else
        ESX.ShowNotification("Aucun joueur à proximité")
    end
end)