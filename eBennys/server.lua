ESX = nil 

TriggerEvent(Config.ESXTrigger, function(obj) ESX = obj end)

local societyName = "society_mechanic"
local PlayersHarvesting  = {}
local PlayersHarvesting2 = {}
local PlayersHarvesting3 = {}
local PlayersCrafting    = {}
local PlayersCrafting2   = {}
local PlayersCrafting3   = {}

ESX.RegisterServerCallback('Mechanic:getStockItems', function(source, cb)
	TriggerEvent('esx_addoninventory:getSharedInventory', societyName, function(inventory)
		cb(inventory.items)
	end)
end)

RegisterNetEvent('Mechanic:getStockItem')
AddEventHandler('Mechanic:getStockItem', function(itemName, count)
	local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)

	TriggerEvent('esx_addoninventory:getSharedInventory', societyName, function(inventory)
		local inventoryItem = inventory.getItem(itemName)

		-- is there enough in the society?
		if count > 0 and inventoryItem.count >= count then

			-- can the player carry the said amount of x item?
				inventory.removeItem(itemName, count)
				xPlayer.addInventoryItem(itemName, count)
				TriggerClientEvent('esx:showAdvancedNotification', _src, 'Coffre', '~o~Informations~s~', 'Vous avez retiré ~r~'..inventoryItem.label.." x"..count, 'CHAR_MP_FM_CONTACT', 8)
		else
			TriggerClientEvent('esx:showAdvancedNotification', _src, 'Coffre', '~o~Informations~s~', "Quantité ~r~invalide", 'CHAR_MP_FM_CONTACT', 9)
		end
	end)
end)

ESX.RegisterServerCallback('Mechanic:getPlayerInventory', function(source, cb)
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	local items   = xPlayer.inventory

	cb({items = items})
end)

RegisterNetEvent('Mechanic:putStockItems')
AddEventHandler('Mechanic:putStockItems', function(itemName, count)
	local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
	local sourceItem = xPlayer.getInventoryItem(itemName)

	TriggerEvent('esx_addoninventory:getSharedInventory', societyName, function(inventory)
		local inventoryItem = inventory.getItem(itemName)

		-- does the player have enough of the item?
		if sourceItem.count >= count and count > 0 then
			xPlayer.removeInventoryItem(itemName, count)
			inventory.addItem(itemName, count)
			TriggerClientEvent('esx:showAdvancedNotification', _src, 'Coffre', '~o~Informations~s~', 'Vous avez déposé ~g~'..inventoryItem.label.." x"..count, 'CHAR_MP_FM_CONTACT', 8)
		else
			TriggerClientEvent('esx:showAdvancedNotification', _src, 'Coffre', '~o~Informations~s~', "Quantité ~r~invalide", 'CHAR_MP_FM_CONTACT', 9)
		end
	end)
end)

RegisterServerEvent('Annonce:MoiSaMGL')
AddEventHandler('Annonce:MoiSaMGL', function(open, close, pause, dispolivre, nodispolivre)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local xPlayers	= ESX.GetPlayers()
	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		if open then
		TriggerClientEvent('esx:showAdvancedNotification', xPlayers[i], 'Benny\'s', '~y~Annonce', 'Le Benny\'s est désormais ~g~OUVERT~s~ | Custom & Réparation disponible !', 'CHAR_LS_CUSTOMS', 8)
		elseif close then
		TriggerClientEvent('esx:showAdvancedNotification', xPlayers[i], 'Benny\'s', '~y~Annonce', 'Le Benny\'s est désormais ~r~FERMER~s~ | Passe plus tard !', 'CHAR_LS_CUSTOMS', 8)
		elseif pause then
		TriggerClientEvent('esx:showAdvancedNotification', xPlayers[i], 'Benny\'s', '~y~Annonce', 'Le Benny\'s est désormais en ~o~PAUSE~s~', 'CHAR_LS_CUSTOMS', 8)
		elseif dispolivre then
		TriggerClientEvent('esx:showAdvancedNotification', xPlayers[i], 'Benny\'s', '~y~Annonce', 'Un mécanicien du Benny\'s est désormais disponible en déplacement, Contactez nous par téléphone !', 'CHAR_LS_CUSTOMS', 8)
		elseif nodispolivre then
		TriggerClientEvent('esx:showAdvancedNotification', xPlayers[i], 'Benny\'s', '~y~Annonce', 'Les mécanos du Benny\'s ne sont plus disponible en déplacement pour le moment !', 'CHAR_LS_CUSTOMS', 8)
		end
	end
end)


RegisterNetEvent('buy:objects')
AddEventHandler('buy:objects', function(item, prix)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local price = prix
    local xMoney = xPlayer.getMoney()
      TriggerEvent('esx_addonaccount:getSharedAccount', societyName, function (account)
        if account.money >= price then
          account.removeMoney(price)
          xPlayer.addInventoryItem(item, 1)
          TriggerClientEvent('esx:showNotification', source, "Vous avez reçu votre "..item.." pour ~g~"..price.."$ avec l'argent de la société")
          else
          TriggerClientEvent('esx:showNotification', source, "Il vous manque ~r~"..price.."$ dans la société")
        end
    end)
end)

RegisterServerEvent('mechanic:onNPCJobMissionCompleted')
AddEventHandler('mechanic:onNPCJobMissionCompleted', function()
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local total   = math.random(Config.NPCJobEarnings.min, Config.NPCJobEarnings.max);

	if xPlayer.job.grade >= 3 then
		total = total * 2
	end

	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
		account.addMoney(total)
	end)

	TriggerClientEvent("esx:showNotification", _source, "Votre société a ~g~gagné~s~ ~g~$".. total)
end)

--------------------------------------------------------------

RegisterServerEvent("mechanic:retraitentreprise")
AddEventHandler("mechanic:retraitentreprise", function(money)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local total = money
    
    TriggerEvent('esx_addonaccount:getSharedAccount', societyName, function (account)
        if account.money >= total then
            account.removeMoney(total)
            xPlayer.addMoney(total)
            TriggerClientEvent('esx:showAdvancedNotification', source, 'Banque', 'Banque', "~g~Vous avez retiré "..total.." $ de votre entreprise", 'CHAR_BANK_FLEECA', 10)
        else
            TriggerClientEvent('esx:showNotification', source, "Vous n'avez pas assez d\'argent dans votre entreprise!")
        end
    end)

   
end) 

RegisterServerEvent("mechanic:depotentreprise")
AddEventHandler("mechanic:depotentreprise", function(money)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local total = money
    local xMoney = xPlayer.getMoney()
    
    TriggerEvent('esx_addonaccount:getSharedAccount', societyName, function (account)
        if xMoney >= total then
            account.addMoney(total)
            xPlayer.removeAccountMoney('bank', total)
            TriggerClientEvent('esx:showAdvancedNotification', source, 'Banque', 'Banque', "~g~Vous avez déposé "..total.." $ dans votre entreprise", 'CHAR_BANK_FLEECA', 10)
        else
            TriggerClientEvent('esx:showNotification', source, "Vous n'avez pas assez d\'argent !")
        end
    end)   
end)

RegisterServerEvent('mechanic:recruter')
AddEventHandler('mechanic:recruter', function(target)

  local xPlayer = ESX.GetPlayerFromId(source)
  local xTarget = ESX.GetPlayerFromId(target)

  
  	if xPlayer.job.grade_name == 'boss' then
  	xTarget.setJob("mechanic", 0)
  	TriggerClientEvent('esx:showNotification', xPlayer.source, "Le joueur a été recruté")
  	TriggerClientEvent('esx:showNotification', target, "Bienvenue chez les mécaniciens!")
  	else
	TriggerClientEvent('esx:showNotification', xPlayer.source, "Vous n'êtes pas patron...")
	end
end)

RegisterServerEvent('mechanic:promouvoir')
AddEventHandler('mechanic:promouvoir', function(target)

	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = ESX.GetPlayerFromId(target)

  	if xPlayer.job.grade_name == 'boss' and xPlayer.job.name == xTarget.job.name then
  	xTarget.setJob(societe, tonumber(xTarget.job.grade) + 1)
  	TriggerClientEvent('esx:showNotification', xPlayer.source, "Le joueur a été promu")
  	TriggerClientEvent('esx:showNotification', target, "Vous avez été promu !")
  	else
	TriggerClientEvent('esx:showNotification', xPlayer.source, "Vous n'êtes pas patron ou le joueur ne peut pas être promu.")

  end
end)

RegisterServerEvent('mechanic:descendre')
AddEventHandler('mechanic:descendre', function(target)

  local xPlayer = ESX.GetPlayerFromId(source)
  local xTarget = ESX.GetPlayerFromId(target)

  	if xPlayer.job.grade_name == 'boss' and xPlayer.job.name == xTarget.job.name then
  	xTarget.setJob("mechanic", tonumber(xTarget.job.grade) - 1)
  	TriggerClientEvent('esx:showNotification', xPlayer.source, "Le joueur a été rétrogradé")
  	TriggerClientEvent('esx:showNotification', target, "Vous avez été rétrogradé !")
  	else
	TriggerClientEvent('esx:showNotification', xPlayer.source, "Vous n'êtes pas patron ou le joueur ne peut pas être promu.")
  end
end)

RegisterServerEvent('mechanic:virer')
AddEventHandler('mechanic:virer', function(target)

  local xPlayer = ESX.GetPlayerFromId(source)
  local xTarget = ESX.GetPlayerFromId(target)

  	if xPlayer.job.grade_name == 'boss' and xPlayer.job.name == xTarget.job.name then
  	xTarget.setJob("unemployed", 0)
  	TriggerClientEvent('esx:showNotification', xPlayer.source, "Le joueur a été viré")
  	TriggerClientEvent('esx:showNotification', target, "Vous avez été viré !")
  	else
	TriggerClientEvent('esx:showNotification', xPlayer.source, "Vous n'êtes pas patron ou le joueur ne peut pas être promu")

  end
end)

ESX.RegisterServerCallback('tcheck:ifhaveitem', function(source,cb,itemname)
	local xPlayer = ESX.GetPlayerFromId(source)
  
  if xPlayer.getInventoryItem(itemname).count >= 1 then
      xPlayer.removeInventoryItem(itemname,1)

      cb(true)
    else
      cb(false)
    end
end)

---------------------

ESX.RegisterServerCallback('rCoffre:getArmoryWeapons', function(source, cb, soc)
	TriggerEvent('esx_datastore:getSharedDataStore', societyName, function(store)
		local weapons = store.get('weapons')

		if weapons == nil then
			weapons = {}
		end

		cb(weapons)
	end)
end)

ESX.RegisterServerCallback('rCoffre:removeArmoryWeapon', function(source, cb, weaponName, soc)
	local _src = source
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.addWeapon(weaponName, 500)
	TriggerClientEvent('esx:showAdvancedNotification', _src, 'Coffre', '~o~Informations~s~', 'Vous avez retiré ~r~'..ESX.GetWeaponLabel(weaponName), 'CHAR_MP_FM_CONTACT', 8)

	TriggerEvent('esx_datastore:getSharedDataStore', societyName, function(store)
		local weapons = store.get('weapons') or {}

		local foundWeapon = false

		for i=1, #weapons, 1 do
			if weapons[i].name == weaponName then
				weapons[i].count = (weapons[i].count > 0 and weapons[i].count - 1 or 0)
				foundWeapon = true
				break
			end
		end

		if not foundWeapon then
			table.insert(weapons, {
				name = weaponName,
				count = 0
			})
		end

		store.set('weapons', weapons)
		cb()
	end)
end)

ESX.RegisterServerCallback('rCoffre:addArmoryWeapon', function(source, cb, weaponName, removeWeapon, soc)
	local _src = source
	local xPlayer = ESX.GetPlayerFromId(source)

	if removeWeapon then
		xPlayer.removeWeapon(weaponName)
	end

	TriggerClientEvent('esx:showAdvancedNotification', _src, 'Coffre', '~o~Informations~s~', 'Vous avez déposé ~g~'..ESX.GetWeaponLabel(weaponName), 'CHAR_MP_FM_CONTACT', 8)

	TriggerEvent('esx_datastore:getSharedDataStore', societyName, function(store)
		local weapons = store.get('weapons') or {}
		local foundWeapon = false

		for i=1, #weapons, 1 do
			if weapons[i].name == weaponName then
				weapons[i].count = weapons[i].count + 1
				foundWeapon = true
				break
			end
		end

		if not foundWeapon then
			table.insert(weapons, {
				name  = weaponName,
				count = 1
			})
		end

		store.set('weapons', weapons)
		cb()
	end)
end)