ESX = nil

local CurrentAction, CurrentActionMsg, CurrentActionData = nil, '', {}
local CurrentlyTowedVehicle, Blips, NPCOnJob, NPCTargetTowable, NPCTargetTowableZone = nil, {}, false, nil, nil
local NPCHasSpawnedTowable, NPCLastCancel, NPCHasBeenNextToTowable, NPCTargetDeleterZone = false, GetGameTimer() - 5 * 60000, false, false
local isDead, isBusy = false, false
local PlayerData = {}
local ped = PlayerPedId()
local vehicle = GetVehiclePedIsIn( ped, false )
local societyMoney = nil
local Veh = {Action = {'Réparer','Nettoyer','Crocheter'}, List = 1}

Citizen.CreateThread(function()
    TriggerEvent(Config.ESXTrigger, function(lib) ESX = lib end)
    while ESX == nil do Citizen.Wait(100) end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

Citizen.CreateThread(function()
    local BLIPMECA = AddBlipForCoord(Config.blips)
    SetBlipSprite(BLIPMECA, 402)
    SetBlipColour(BLIPMECA, 5)
    SetBlipScale(BLIPMECA, 1.0)
    SetBlipAsShortRange(BLIPMECA, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString("Benny's")
    EndTextCommandSetBlipName(BLIPMECA)
end)

function SelectRandomTowable()
	local index = GetRandomIntInRange(1,  #Config.Towables)

	for k,v in pairs(Config.Zones) do
		if v.Pos.x == Config.Towables[index].x and v.Pos.y == Config.Towables[index].y and v.Pos.z == Config.Towables[index].z then
			return k
		end
	end
end

function StartNPCJob()
	local playerPed = PlayerPedId()
	if IsPedInAnyVehicle(playerPed, false) and IsVehicleModel(GetVehiclePedIsIn(playerPed, false), GetHashKey(Config.Require)) then
		NPCOnJob = true

		NPCTargetTowableZone = SelectRandomTowable()
		local zone = Config.Zones[NPCTargetTowableZone]
	
		Blips['NPCTargetTowableZone'] = AddBlipForCoord(zone.Pos.x,  zone.Pos.y,  zone.Pos.z)
		SetBlipRoute(Blips['NPCTargetTowableZone'], true)
	
		RageUI.Popup({message = "~y~Conduisez~s~ jusqu'à l'endroit indiqué"})
	else
		RageUI.Popup({message = "Vous devez être dans un véhicule avec remorque."})
	end
end

function StopNPCJob()
	if Blips['NPCTargetTowableZone'] then
		RemoveBlip(Blips['NPCTargetTowableZone'])
		Blips['NPCTargetTowableZone'] = nil
	end

	if Blips['NPCDelivery'] then
		RemoveBlip(Blips['NPCDelivery'])
		Blips['NPCDelivery'] = nil
	end

	Config.Zones.VehicleDelivery.Type = -1

	NPCOnJob = false
	NPCTargetTowable  = nil
	NPCTargetTowableZone = nil
	NPCHasSpawnedTowable = false
	NPCHasBeenNextToTowable = false

	RageUI.Popup({message = "Mission ~r~annulée~s~"})
end

local EnBoucleDeBzByEnos = true		---- optimisation ma caille <3
-- Pop NPC mission vehicle when inside area
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		---- optimisation ma caille c simple regarde <3
		EnBoucleDeBzByEnos = true


		if NPCTargetTowableZone and not NPCHasSpawnedTowable then
			EnBoucleDeBzByEnos = false --- look
			local coords = GetEntityCoords(PlayerPedId())
			local zone   = Config.Zones[NPCTargetTowableZone]

			if GetDistanceBetweenCoords(coords, zone.Pos.x, zone.Pos.y, zone.Pos.z, true) < Config.NPCSpawnDistance then
				local model = Config.Vehicles[GetRandomIntInRange(1,  #Config.Vehicles)]

				ESX.Game.SpawnVehicle(model, zone.Pos, 0, function(vehicle)
					NPCTargetTowable = vehicle
				end)

				NPCHasSpawnedTowable = true
			end
		end

		if NPCTargetTowableZone and NPCHasSpawnedTowable and not NPCHasBeenNextToTowable then
			EnBoucleDeBzByEnos = false --- look
			local coords = GetEntityCoords(PlayerPedId())
			local zone   = Config.Zones[NPCTargetTowableZone]

			if GetDistanceBetweenCoords(coords, zone.Pos.x, zone.Pos.y, zone.Pos.z, true) < Config.NPCNextToDistance then
				RageUI.Popup({message = "Veuillez ~y~remorquer~s~ le véhicule"})
				NPCHasBeenNextToTowable = true
			end
		end


        if EnBoucleDeBzByEnos then --- look
            Citizen.Wait(800) --- look
        end --- look
	end
end)

local function KeyboardImput(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    blockinput = true

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
        Citizen.Wait(0)
    end
        
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult() 
        Citizen.Wait(500) 
        blockinput = false
        return result 
    else
        Citizen.Wait(500) 
        blockinput = false 
        return nil 
    end
end

function GetCloseVehi()
    local player = GetPlayerPed(-1)
    local vehicle = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 15.0, 0, 70)
    local vCoords = GetEntityCoords(vehicle)
    DrawMarker(2, vCoords.x, vCoords.y, vCoords.z + 1.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 102, 0, 170, 0, 1, 2, 0, nil, nil, 0)
end

---------------

function MenuF6Meca()
	local Menu = RageUI.CreateMenu(" ", "Intéractions", Config.MenuPositionX, Config.MenuPositionY)
	local Annonces = RageUI.CreateSubMenu(Menu, " ", "Annonces", Config.MenuPositionX, Config.MenuPositionY)
	RageUI.Visible(Menu, not RageUI.Visible(Menu))
	while Menu do
		Citizen.Wait(0)
			RageUI.IsVisible(Menu, true, true, true, function()

			RageUI.ButtonWithStyle("Annonces",nil, {RightLabel = "→→→"}, not cooldown, function(Hovered, Active, Selected)
			end, Annonces)

			RageUI.ButtonWithStyle("Facture",nil, {RightLabel = "→→"}, not cooldown, function(Hovered,Active,Selected)
                local player, distance = ESX.Game.GetClosestPlayer()
                if Selected then
                    local raison = ""
                    local montant = 0
                    AddTextEntry("FMMC_MPM_NA", "Objet de la facture")
                    DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "Donnez le motif de la facture :", "", "", "", "", 30)
                    while (UpdateOnscreenKeyboard() == 0) do
                        DisableAllControlActions(0)
                        Wait(0)
                    end
                    if (GetOnscreenKeyboardResult()) then
                        local result = GetOnscreenKeyboardResult()
                        if result then
                            raison = result
                            result = nil
                            AddTextEntry("FMMC_MPM_NA", "Montant de la facture")
                            DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "Indiquez le montant de la facture :", "", "", "", "", 30)
                            while (UpdateOnscreenKeyboard() == 0) do
                                DisableAllControlActions(0)
                                Wait(0)
                            end
                            if (GetOnscreenKeyboardResult()) then
                                result = GetOnscreenKeyboardResult()
                                if result then
                                    montant = result
                                    result = nil
                                    if player ~= -1 and distance <= 3.0 then
                                        TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(player), 'society_mechanic', ("Benny's"), montant)
                                        TriggerEvent('esx:showAdvancedNotification', 'Fl~g~ee~s~ca ~g~Bank', 'Facture envoyée : ', 'Vous avez envoyé une facture d\'un montant de : ~g~'..montant.. '$ ~s~pour cette raison : ~b~' ..raison.. '', 'CHAR_BANK_FLEECA', 9)
                                    else
                                        RageUI.Popup({message = "~r~Probleme~s~: Aucuns joueurs proche"})
                                    end
                                end
                            end
                        end
                    end
					cooldown = true
					Citizen.SetTimeout(5000,function()
						cooldown = false
					end)
				end
            end)	
			
		RageUI.ButtonWithStyle("Commencer une mission",nil, {RightLabel = "→→"}, not cooldown, function(Hovered, Active, Selected)
			if Selected then 
				StartNPCJob()
				cooldowncool(10000)
			end
		end)

		RageUI.ButtonWithStyle("Arrêter la mission",nil, {RightLabel = "→→"}, not cooldown, function(Hovered, Active, Selected)
			if Selected then 
				StopNPCJob(cancel)
				cooldowncool(10000)
			end
		end)

		RageUI.List('Action sur véhicule', Veh.Action, Veh.List, nil, {RightLabel = ""}, not cooldown, function(Hovered, Active, Selected, Index)
			if (Active) then
				GetCloseVehi()
			end
			if (Selected) then 
				local playerPed = PlayerPedId()
				local vehicle   = ESX.Game.GetVehicleInDirection()
				local coords    = GetEntityCoords(playerPed)
				if IsPedSittingInAnyVehicle(playerPed) then
					RageUI.Popup({message = "Vous ne pouvez pas effectuer cette action depuis un véhicule!"})
					return
				end
				if Index == 1 then
				if DoesEntityExist(vehicle) then
					ESX.TriggerServerCallback('tcheck:ifhaveitem',function(item)
						if item then    
					isBusy = true
					TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, true)
					Citizen.CreateThread(function()
						cooldowncool(20000)
						Citizen.Wait(20000)
						SetVehicleFixed(vehicle)
						SetVehicleDeformationFixed(vehicle)
						SetVehicleUndriveable(vehicle, false)
						SetVehicleEngineOn(vehicle, true, true)
						ClearPedTasksImmediately(playerPed)
						RageUI.Popup({message = "Véhicule ~g~réparé"})
						isBusy = false
					end)
					else 
						RageUI.Popup({message = "<C>~o~Besoin d'un kit de réparation !"}) 
						cooldowncool(3000)
					end
				end, "fixkit")
				else 
					RageUI.Popup({message = "Aucun véhicule à proximité"}) 
					cooldowncool(3000)
				end
			elseif Index == 2 then
				if DoesEntityExist(vehicle) then
					ESX.TriggerServerCallback('tcheck:ifhaveitem',function(item)
						if item then   
					isBusy = true
					TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_MAID_CLEAN', 0, true)
					Citizen.CreateThread(function()
						Citizen.Wait(10000)
						cooldowncool(10000)
	
						SetVehicleDirtLevel(vehicle, 0)
						ClearPedTasksImmediately(playerPed)
	
						RageUI.Popup({message = "Véhicule ~g~nettoyé"})
						isBusy = false
					end)
				else 
					RageUI.Popup({message = "<C>~o~Besoin d'un kit de carosserie !"}) 
					cooldowncool(3000)
				end
			end, "carokit")
				else
					RageUI.Popup({message = "Aucun véhicule à proximité"})
					cooldowncool(3000)
				end
			elseif Index == 3 then
				local playerPed = PlayerPedId()
				local vehicle = ESX.Game.GetVehicleInDirection()
				local coords = GetEntityCoords(playerPed)
	
				if IsPedSittingInAnyVehicle(playerPed) then
					RageUI.Popup({message = "Vous ne pouvez pas effectuer cette action depuis un véhicule!"})
					return
				end

				ESX.TriggerServerCallback('tcheck:ifhaveitem',function(item)
					if item then 
	
				if DoesEntityExist(vehicle) then
					isBusy = true
					TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
					Citizen.CreateThread(function()
						Citizen.Wait(10000)
						cooldowncool(10000)
						SetVehicleDoorsLocked(vehicle, 1)
						SetVehicleDoorsLockedForAllPlayers(vehicle, false)
						ClearPedTasksImmediately(playerPed)
	
						RageUI.Popup({message = "<C>Véhicule ~g~déverrouillé"})
						isBusy = false
					end)
				else
					RageUI.Popup({message = "<C>Aucun véhicule à proximité"})
					cooldowncool(3000)
				end
				else 
					RageUI.Popup({message = "<C>~o~Besoin d'un Chalumeaux !"}) 
					cooldowncool(3000)
				end
			end, "blowpipe")
			end
		end
		Veh.List = Index;              
		end)

		RageUI.ButtonWithStyle("Placer le véhicule sur la remorque",nil, {RightLabel = "→→"}, not cooldown, function(Hovered, Active, Selected)
			if (Active) then
				GetCloseVehi()
			end
			if Selected then
				local playerPed = PlayerPedId()
				local vehicle = GetVehiclePedIsIn(playerPed, true)
	
				local towmodel = GetHashKey('flatbed')
				local isVehicleTow = IsVehicleModel(vehicle, towmodel)
	
				if isVehicleTow then
					local targetVehicle = ESX.Game.GetVehicleInDirection()
	
					if CurrentlyTowedVehicle == nil then
						if targetVehicle ~= 0 then
							if not IsPedInAnyVehicle(playerPed, true) then
								if vehicle ~= targetVehicle then
									AttachEntityToEntity(targetVehicle, vehicle, 20, -0.5, -5.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
									CurrentlyTowedVehicle = targetVehicle
									RageUI.Popup({message = "<C>Vehicule ~b~attaché~s~ avec succès!"})
	
									if NPCOnJob then
										if NPCTargetTowable == targetVehicle then
											RageUI.Popup({message = "<C>Veuillez déposer le véhicule à la concession"})
											Config.Zones.VehicleDelivery.Type = 1
	
											if Blips['NPCTargetTowableZone'] then
												RemoveBlip(Blips['NPCTargetTowableZone'])
												Blips['NPCTargetTowableZone'] = nil
											end
	
											Blips['NPCDelivery'] = AddBlipForCoord(Config.Zones.VehicleDelivery.Pos.x, Config.Zones.VehicleDelivery.Pos.y, Config.Zones.VehicleDelivery.Pos.z)
											SetBlipRoute(Blips['NPCDelivery'], true)
										end
									end
								else
									RageUI.Popup({message = "<C>~r~Impossible~s~ d'attacher votre propre dépanneuse"})
								end
							end
						else
							RageUI.Popup({message = "<C>Il n\'y a ~r~pas de véhicule~s~ à attacher"})
						end
					else
						AttachEntityToEntity(CurrentlyTowedVehicle, vehicle, 20, -0.5, -12.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
						DetachEntity(CurrentlyTowedVehicle, true, true)
	
						if NPCOnJob then
							if NPCTargetDeleterZone then
	
								if CurrentlyTowedVehicle == NPCTargetTowable then
									ESX.Game.DeleteVehicle(NPCTargetTowable)
									TriggerServerEvent('mechanic:onNPCJobMissionCompleted')
									StopNPCJob()
									NPCTargetDeleterZone = false
								else
									RageUI.Popup({message = "<C>Ce n'est pas le bon véhicule"})
								end
	
							else
								RageUI.Popup({message = "<C>Vous devez être au bon endroit pour faire cela"})
							end
						end
	
						CurrentlyTowedVehicle = nil
						RageUI.Popup({message = "<C>Vehicule ~b~détaché~s~ avec succès!"})
					end
				else
					RageUI.Popup({message = "<C>~r~Action Impossible!\n ~s~Vous devez avoir un ~b~Flatbed ~s~pour ça"})
				end
				cooldowncool(4000)
			end
		end)

    end, function()
	end)

	RageUI.IsVisible(Annonces, true, true, true, function()
			
		RageUI.ButtonWithStyle("Ouvert",nil, {RightLabel = ""}, not cooldown, function(Hovered, Active, Selected)
			if Selected then
				TriggerServerEvent('Annonce:MoiSaMGL', true, false, false, false, false)
				cooldowncool(40000)
			end
		end)

		RageUI.ButtonWithStyle("Fermer",nil, {RightLabel = ""}, not cooldown, function(Hovered, Active, Selected)
			if Selected then
				TriggerServerEvent('Annonce:MoiSaMGL', false, true, false, false, false)
				cooldowncool(40000)
			end
		end)

		RageUI.ButtonWithStyle("Pause",nil, {RightLabel = ""}, not cooldown, function(Hovered, Active, Selected)
			if Selected then
				TriggerServerEvent('Annonce:MoiSaMGL', false, false, true, false, false)
				cooldowncool(40000)
			end
		end)

		RageUI.ButtonWithStyle("Déplacement disponible",nil, {RightLabel = ""}, not cooldown, function(Hovered, Active, Selected)
			if Selected then
				TriggerServerEvent('Annonce:MoiSaMGL', false, false, false, true, false)
				cooldowncool(40000)
			end
		end)

		RageUI.ButtonWithStyle("Déplacement indisponible",nil, {RightLabel = ""}, not cooldown, function(Hovered, Active, Selected)
			if Selected then
				TriggerServerEvent('Annonce:MoiSaMGL', false, false, false, false, true)
				cooldowncool(40000)
			end
		end)

    end, function()
	end)

	if not RageUI.Visible(Menu) and not RageUI.Visible(Annonces) then
		Menu = RMenu:DeleteType(Menu, true)
	end
end
end

Keys.Register('F6', 'Mécano', 'Ouvrir le menu Mécano', function()
    if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
        MenuF6Meca()
    end
end)

function BoutiqueMeca()
	local bmeca = RageUI.CreateMenu(" ", "Marchand", Config.MenuPositionX, Config.MenuPositionY)
	RageUI.Visible(bmeca, not RageUI.Visible(bmeca))
	while bmeca do
	Citizen.Wait(0)
		RageUI.IsVisible(bmeca, true, true, true, function()

			for k, v in pairs(Config.Boutique) do

				RageUI.ButtonWithStyle(v.nom, nil, {RightLabel = "~o~"..v.prix.."$ Entreprise"}, not cooldown, function(Hovered, Active, Selected)
					if (Selected) then  
                    TriggerServerEvent('buy:objects', v.item, v.prix)
					cooldowncool(1100)
				end
				end)
	
			end

        end, function() 
        end)
        if not RageUI.Visible(bmeca) then
            bmeca = RMenu:DeleteType(bmeca, true)
        end
    end
end

Citizen.CreateThread(function()
    while true do
        local wait = 800
        local plyPos = GetEntityCoords(PlayerPedId())
        local dist = #(plyPos-Config.boutiquekit)
            if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then 
                if dist <= 15.0 then
                wait = 0
				DrawMarker(Config.MarkerType,  Config.boutiquekit.x, Config.boutiquekit.y, Config.boutiquekit.z-0.99, nil, nil, nil, -90, nil, nil, 1.0, 1.0, 1.0, 230, 230, 0 , 120)
                end
            if dist <= 1.0 then
                wait = 0
                RageUI.Text({ message = "Appuyez sur ~y~[E]~s~ pour ouvrir →→ ~y~Boutique", time_display = 1 })
                if IsControlJustPressed(1,51) then
                    BoutiqueMeca()
                end
            end
        end
    Citizen.Wait(wait)
    end
end)

function GarageMeca()
	local gmecano = RageUI.CreateMenu(" ", "Garage", Config.MenuPositionX, Config.MenuPositionY)
	RageUI.Visible(gmecano, not RageUI.Visible(gmecano))
		while gmecano do
		Citizen.Wait(0)
		RageUI.IsVisible(gmecano, true, true, true, function()

		RageUI.ButtonWithStyle("Ranger le véhicule", "Pour ranger une voiture.", {RightLabel = "→→"},not cooldown, function(Hovered, Active, Selected)
			if (Selected) then   
				local veh,dist4 = ESX.Game.GetClosestVehicle(playerCoords)
				if dist4 < 5 then
					DeleteEntity(veh)
					RageUI.CloseAll()
				end 
			end
		end) 

		for k,v in pairs(Config.garagevoiture) do
				RageUI.ButtonWithStyle(v.nom, "Pour sortir une " ..v.nom, {RightLabel = "→"}, not cooldown, function(Hovered, Active, Selected)
				if (Selected) then
				Citizen.Wait(1)  
				spawnuniCarrz(v.modele)
				cooldowncool(10000)
				RageUI.CloseAll()
				end
			end)
		end
            
		end, function() 
		end)
		if not RageUI.Visible(gmecano) then
			gmecano = RMenu:DeleteType(gmecano, true)
		end
	end
end

Citizen.CreateThread(function()
	while true do
		local wait = 800
		local plyPos = GetEntityCoords(PlayerPedId())
		local dist = #(plyPos-Config.garage)
			if dist <= 15.0 then
				wait = 0
				DrawMarker(Config.MarkerType,  Config.garage.x, Config.garage.y, Config.garage.z-0.99, nil, nil, nil, -90, nil, nil, 1.0, 1.0, 1.0, 230, 230, 0 , 120)
			end
            if dist <= 3.0 then
                wait = 0
            if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' or ESX.PlayerData.job2 and ESX.PlayerData.job2.name == 'mechanic' then    
                RageUI.Text({ message = "Appuyez sur ~y~[E]~s~ pour ouvrir →→ ~y~Garage", time_display = 1 })
                    if IsControlJustPressed(1,51) then           
                        GarageMeca()
                    end   
                end
            end
        Citizen.Wait(wait) 
    end
end)

function spawnuniCarrz(car)
    local car = GetHashKey(car)
    RequestModel(car)
    while not HasModelLoaded(car) do
        RequestModel(car)
        Citizen.Wait(0)
    end
    local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), false))
    local vehicle = CreateVehicle(car, Config.spawngarage, Config.spawnheading, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    local plaque = "Meca"..math.random(1,9)
    SetVehicleNumberPlateText(vehicle, plaque) 
    SetPedIntoVehicle(GetPlayerPed(-1),vehicle,-1)
end

function VestMeca()
	local vmecano = RageUI.CreateMenu(" ", "Vestiaire", Config.MenuPositionX, Config.MenuPositionY)
	RageUI.Visible(vmecano, not RageUI.Visible(vmecano))
	while vmecano do
		Citizen.Wait(0)
			RageUI.IsVisible(vmecano, true, true, true, function()
            RageUI.ButtonWithStyle("S'équiper de sa tenue | ~b~Civile",nil, {RightBadge = RageUI.BadgeStyle.Clothes}, not cooldown, function(Hovered, Active, Selected)
                if Selected then
                    vcivil()
					cooldowncool(5000)
                end
            end)
            RageUI.ButtonWithStyle("S'équiper de la tenue | ~y~Travaille",nil, {RightBadge = RageUI.BadgeStyle.Clothes}, not cooldown, function(Hovered, Active, Selected)
                if Selected then
                    vmechanic()
					cooldowncool(5000)
                end
            end)
        end, function() 
        end)
        if not RageUI.Visible(vmecano) then
            vmecano = RMenu:DeleteType(vmecano, true)
        end
	end
end

Citizen.CreateThread(function()
    while true do
		local wait = 800
		local plyPos = GetEntityCoords(PlayerPedId())
		local dist = #(plyPos-Config.vestiaire)
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then 
			if dist <= 15.0 then
			wait = 0
			DrawMarker(Config.MarkerType,  Config.vestiaire.x, Config.vestiaire.y, Config.vestiaire.z-0.99, nil, nil, nil, -90, nil, nil, 1.0, 1.0, 1.0, 230, 230, 0 , 120)
			end
			if dist <= 1.0 then
				wait = 0
				RageUI.Text({ message = "Appuyez sur ~y~[E]~s~ pour ouvrir →→ ~y~Vestiaire", time_display = 1 })
					if IsControlJustPressed(1,51) then
						VestMeca()
					end
				end
			end
		Citizen.Wait(wait)
	end
end)

function vmechanic()
	local model = GetEntityModel(GetPlayerPed(-1))
	TriggerEvent('skinchanger:getSkin', function(skin)
		if model == GetHashKey("mp_m_freemode_01") then
			clothesSkin = {
				['bags_1'] = 0, ['bags_2'] = 0,
				['tshirt_1'] = 15, ['tshirt_2'] = 2,
				['torso_1'] = 65, ['torso_2'] = 2,
				['arms'] = 31,
				['pants_1'] = 38, ['pants_2'] = 2,
				['shoes_1'] = 12, ['shoes_2'] = 6,
				['mask_1'] = 0, ['mask_2'] = 0,
				['bproof_1'] = 0,
				['chain_1'] = 0,
				['helmet_1'] = -1, ['helmet_2'] = 0,
			}
		else
			clothesSkin = {
				['bags_1'] = 0, ['bags_2'] = 0,
				['tshirt_1'] = 15,['tshirt_2'] = 2,
				['torso_1'] = 65, ['torso_2'] = 2,
				['arms'] = 36, ['arms_2'] = 0,
				['pants_1'] = 38, ['pants_2'] = 2,
				['shoes_1'] = 12, ['shoes_2'] = 6,
				['mask_1'] = 0, ['mask_2'] = 0,
				['bproof_1'] = 0,
				['chain_1'] = 0,
				['helmet_1'] = -1, ['helmet_2'] = 0,
			}
		end
		TriggerEvent('skinchanger:loadClothes', skin, clothesSkin)
	end)
end

function vcivil()
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
        TriggerEvent('skinchanger:loadSkin', skin)
    end)
end

local function menuCoffre()
    local menuCoffreP = RageUI.CreateMenu(" ", "Coffre", Config.MenuPositionX, Config.MenuPositionY)
        RageUI.Visible(menuCoffreP, not RageUI.Visible(menuCoffreP))
            while menuCoffreP do
            Citizen.Wait(0)
            RageUI.IsVisible(menuCoffreP, true, true, true, function()

                RageUI.Separator("~b~↓ Objet(s) ↓")

                    RageUI.ButtonWithStyle("Retirer Objet(s)",nil, {RightLabel = "→→"}, true, function(Hovered, Active, Selected)
                        if Selected then
                            RageUI.CloseAll()
                            menuCoffreRetirer()
                        end
                    end)
                    
                    RageUI.ButtonWithStyle("Déposer Objet(s)",nil, {RightLabel = "→→"}, true, function(Hovered, Active, Selected)
                        if Selected then
                            RageUI.CloseAll()
                            menuCoffreDeposer()
                        end
                    end)
					
					RageUI.Separator("~b~↓ Arme(s) ↓")

					RageUI.ButtonWithStyle("Prendre Arme(s)",nil, {RightLabel = "→→"}, true, function(Hovered, Active, Selected)
						if Selected then
							CoffreRetirerWeapon()
							RageUI.CloseAll()
						end
					end)
					
					RageUI.ButtonWithStyle("Déposer Arme(s)",nil, {RightLabel = "→→"}, true, function(Hovered, Active, Selected)
						if Selected then
							CoffreDeposerWeapon()
							RageUI.CloseAll()
						end
					end)


                end)



            if not RageUI.Visible(menuCoffreP) then
            menuCoffreP = RMenu:DeleteType(menuCoffreP, true)
        end
    end
end

Citizen.CreateThread(function()
    while true do
        local Timer = 500
        local plyPos = GetEntityCoords(PlayerPedId())
        local dist = #(plyPos-Config.coffre)
        if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
        if dist <= 15.0 then
         Timer = 0
         DrawMarker(Config.MarkerType,  Config.coffre.x, Config.coffre.y, Config.coffre.z-0.99, nil, nil, nil, -90, nil, nil, 1.0, 1.0, 1.0, 230, 230, 0 , 120)
        end
         if dist <= 3.0 then
            Timer = 0
                RageUI.Text({ message = "Appuyez sur ~y~[E]~s~ pour ouvrir →→ ~y~Coffre", time_display = 1 })
            if IsControlJustPressed(1,51) then
                menuCoffre()
            end
         end
        end
    Citizen.Wait(Timer)
 end
end)


local itemstock = {}
function menuCoffreRetirer()
    local menuCoffre = RageUI.CreateMenu(" ", "Coffre retrait", Config.MenuPositionX, Config.MenuPositionY)
    ESX.TriggerServerCallback('Mechanic:getStockItems', function(items) 
    itemstock = items
    RageUI.Visible(menuCoffre, not RageUI.Visible(menuCoffre))
        while menuCoffre do
            Citizen.Wait(0)
                RageUI.IsVisible(menuCoffre, true, true, true, function()
                        for k,v in pairs(itemstock) do 
                            if v.count > 0 then
                            RageUI.ButtonWithStyle(v.label, nil, {RightLabel = v.count}, true, function(Hovered, Active, Selected)
                                if Selected then
                                    local count = KeyboardImput("Combien ?", "", 2)
                                    TriggerServerEvent('Mechanic:getStockItem', v.name, tonumber(count))
                                    RageUI.CloseAll()
                                end
                            end)
                        end
                    end
                end, function()
                end)
            if not RageUI.Visible(menuCoffre) then
            menuCoffre = RMenu:DeleteType(menuCoffre, true)
        end
    end
     end)
end


function menuCoffreDeposer()
    local StockPlayer = RageUI.CreateMenu(" ", "Coffre dépôt", Config.MenuPositionX, Config.MenuPositionY)
    ESX.TriggerServerCallback('Mechanic:getPlayerInventory', function(inventory)
        RageUI.Visible(StockPlayer, not RageUI.Visible(StockPlayer))
    while StockPlayer do
        Citizen.Wait(0)
            RageUI.IsVisible(StockPlayer, true, true, true, function()
                for i=1, #inventory.items, 1 do
                    if inventory ~= nil then
                         local item = inventory.items[i]
                            if item.count > 0 then
                                    RageUI.ButtonWithStyle(item.label, nil, {RightLabel = item.count}, true, function(Hovered, Active, Selected)
                                            if Selected then
                                            local count = KeyboardImput("Combien ?", '' , 8)
                                            TriggerServerEvent('Mechanic:putStockItems', item.name, tonumber(count))
                                            RageUI.CloseAll()
                                        end
                                    end)
                                end
                            else
                                RageUI.Separator('Chargement en cours')
                            end
                        end
                    end, function()
                    end)
                if not RageUI.Visible(StockPlayer) then
                StockPlayer = RMenu:DeleteType(StockPlayer, true)
            end
        end
    end)
end

Weaponstock = {}
function CoffreRetirerWeapon()
    local StockCoffreWeapon = RageUI.CreateMenu(" ", "Retrait Arme(s)", Config.MenuPositionX, Config.MenuPositionY)
    ESX.TriggerServerCallback('rCoffre:getArmoryWeapons', function(weapons)
    Weaponstock = weapons
    RageUI.Visible(StockCoffreWeapon, not RageUI.Visible(StockCoffreWeapon))
        while StockCoffreWeapon do
            Citizen.Wait(0)
                RageUI.IsVisible(StockCoffreWeapon, true, true, true, function()
                        for k,v in pairs(Weaponstock) do 
                            if v.count > 0 then
                            RageUI.ButtonWithStyle("~r~→~s~ "..ESX.GetWeaponLabel(v.name), nil, {RightLabel = v.count}, true, function(Hovered, Active, Selected)
                                if Selected then
                                    --local cbRetirer = rGangBuilderKeyboardInput("Combien ?", "", 15)
                                    ESX.TriggerServerCallback('rCoffre:removeArmoryWeapon', function()
                                        CoffreRetirerWeapon()
                                    end, v.name, societe)
                                end
                            end)
                        end
                    end
                end, function()
                end)
            if not RageUI.Visible(StockCoffreWeapon) then
            StockCoffreWeapon = RMenu:DeleteType(StockCoffreWeapon, true)
        end
    end
    end, societe)
end

function CoffreDeposerWeapon()
    local StockPlayerWeapon = RageUI.CreateMenu(" ", "Dépôt arme", Config.MenuPositionX, Config.MenuPositionY)
        RageUI.Visible(StockPlayerWeapon, not RageUI.Visible(StockPlayerWeapon))
    while StockPlayerWeapon do
        Citizen.Wait(0)
            RageUI.IsVisible(StockPlayerWeapon, true, true, true, function()
                
                local weaponList = ESX.GetWeaponList()

                for i=1, #weaponList, 1 do
                    local weaponHash = GetHashKey(weaponList[i].name)
                    if HasPedGotWeapon(PlayerPedId(), weaponHash, false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
                    RageUI.ButtonWithStyle("~r~→~s~ "..weaponList[i].label, nil, {RightLabel = ""}, true, function(Hovered, Active, Selected)
                        if Selected then
                        --local cbDeposer = rGangBuilderKeyboardInput("Combien ?", '' , 15)
                        ESX.TriggerServerCallback('rCoffre:addArmoryWeapon', function()
                            CoffreDeposerWeapon()
                        end, weaponList[i].name, true, societe)
                    end
                end)
            end
            end
            end, function()
            end)
                if not RageUI.Visible(StockPlayerWeapon) then
                StockPlayerWeapon = RMenu:DeleteType(StockPlayerWeapon, true)
            end
        end
end

local function menuBoss()
    local menuBossP = RageUI.CreateMenu(" ", "Patron", Config.MenuPositionX, Config.MenuPositionY)
    RageUI.Visible(menuBossP, not RageUI.Visible(menuBossP))
    while menuBossP do
        Wait(0)
        RageUI.IsVisible(menuBossP, true, true, true, function()

            if societyMoney ~= nil then
                RageUI.ButtonWithStyle("Argent société :", nil, {RightLabel = societyMoney.."$"}, true, function()
                end)
            end

            RageUI.ButtonWithStyle("Retirer de l'argent",nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
                if Selected then
					local amount = KeyboardImput("Retrait banque entreprise", "", 15)

					if amount ~= nil then
						amount = tonumber(amount)
				
						if type(amount) == 'number' then
							TriggerServerEvent('mechanic:retraitentreprise', amount)
						else
							RageUI.Popup({message = "Vous n'avez pas saisi un montant"})
						end
					end
                end
            end)

            RageUI.ButtonWithStyle("Déposer de l'argent",nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    local amount = KeyboardImput("Montant", "", 10)
                    amount = tonumber(amount)
                    if amount == nil then
                        RageUI.Popup({message = "Montant invalide"})
                    else
						TriggerServerEvent('mechanic:depotentreprise', amount)
                    end
                end
            end)

			RageUI.ButtonWithStyle("Recruter", nil, {RightLabel = "→"},not cooldown, function(Hovered, Active, Selected)
				if (Selected) then   
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('mechanic:recruter', GetPlayerServerId(closestPlayer))
					 else
						RageUI.Popup({message = "Aucun joueur à proximité"})
					end 
					cooldowncool(5000)
				end
				end)

				RageUI.ButtonWithStyle("Promouvoir", nil, {RightLabel = "→"},not cooldown, function(Hovered, Active, Selected)
				if (Selected) then   
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('mechanic:promouvoir', GetPlayerServerId(closestPlayer))
					 else
						RageUI.Popup({message = "Aucun joueur à proximité"})
					end 
					cooldowncool(5000)
				end
				end)

				RageUI.ButtonWithStyle("Rétrograder", nil, {RightLabel = "→"},not cooldown, function(Hovered, Active, Selected)
				if (Selected) then   
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('mechanic:descendre', GetPlayerServerId(closestPlayer))
					 else
						RageUI.Popup({message = "Aucun joueur à proximité"})
					end 
					cooldowncool(5000)
				end
				end)

				RageUI.ButtonWithStyle("Virer", nil, {RightLabel = "→"},not cooldown, function(Hovered, Active, Selected)
				if (Selected) then   
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('mechanic:virer', GetPlayerServerId(closestPlayer))
					 else
						RageUI.Popup({message = "Aucun joueur à proximité"})
					end 
					cooldowncool(5000)
				end
				end)

			end, function()
			end)

        if not RageUI.Visible(menuBossP) then
            menuBossP = RMenu:DeleteType(menuBossP, true)
        end
    end
end

Citizen.CreateThread(function()
    while true do
        local Timer = 500
        local plyPos = GetEntityCoords(PlayerPedId())
        local dist = #(plyPos-Config.Boss)
        if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' and ESX.PlayerData.job.grade_name == 'boss' then
        if dist <= 15 then
         Timer = 0
		 DrawMarker(Config.MarkerType, Config.Boss.x, Config.Boss.y, Config.Boss.z-0.99, nil, nil, nil, -90, nil, nil, 1.0, 1.0, 1.0, 230, 230, 0 , 120)
        end
         if dist <= 3.0 then
            Timer = 0
                RageUI.Text({ message = "Appuyez sur ~y~[E]~s~ pour ouvrir →→ ~y~Patron", time_display = 1 })
            if IsControlJustPressed(1,51) then
                menuBoss()
				end
			end
		end
		Citizen.Wait(Timer)
	end
end)


function cooldowncool(time)
	cooldown = true
	Citizen.SetTimeout(time,function()
		cooldown = false
	end)
end