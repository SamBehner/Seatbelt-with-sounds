local isUiOpen = false 
local speedBuffer  = {}
local velBuffer    = {}
local beltOn       = false
local wasInCar     = false

function notify(string)
  SetNotificationTextEntry("STRING")
  AddTextComponentString(string)
  DrawNotification(false, true)
end

local validClasses = {
	[0] = true, [1] = true, [2] = true, 
	[3] = true, [4] = true, [5] = true, 
	[6] = true, [7] = true, [9] = true,
	[10] = true, [11] = true, [12] = true,
	[17] = true, [18] = true, [19] = true,
	[20] = true
}

function IsCar(v)
	local c = GetVehicleClass(v)
	
	return validClasses[c] == true
end

function Fvw(e)
	local h = GetEntityHeading(e) + 90.0
	if h < 0.0 then h = 360.0 + h end
	
	h = h * 0.0174533
	
	return { x = math.cos(h) * 2.0, y = math.sin(h) * 2.0 }
end

local function SeatbeltThread()
	while true do
		Citizen.Wait(0)
		
		local p = PlayerPedId()
		local v = GetVehiclePedIsIn(p, false)
		
		if v ~= 0 and (wasInCar or IsCar(v)) then
			wasInCar = true
			
			if not isUiOpen and not IsPlayerDead(PlayerId()) then
				SendNUIMessage {
					displayWindow = 'true'	
				}
			end
			
			if beltOn then
				DisableControlAction(0, 75, true)  -- Disable exit vehicle when stop
	  			DisableControlAction(27, 75, true) -- Disable exit vehicle when Driving
			end
			
			speedBuffer[2] = speedBuffer[1]
			speedBuffer[1] = GetEntitySpeed(car)
			
			if speedBuffer[2] ~= nil and not beltOn and GetEntitySpeedVector(cat, true).y > 1.0 and speedBuffer[1] > 19.25 and 
				(speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * 0.255) 
			then
				local c = GetEntityCoords(p)
				local f = Fwv(p)
				
				SetEntityCoords(p, co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
				SetEntityVelocity(p, velBuffer[2].x, velBuffer[2].y, velBuffer[2].z)
				Citizen.Wait(1)
				SetPedToRagdoll(p, 1000, 1000, 0, 0, 0, 0)
			end
			
			velBuffer[2] = velBuffer[1]
			velBuffer[1] = GetEntityVelocity(v)
			
			if IsControlJustReleased(0, 311) and GetLastInputMethod(0) then
				beltOn = not beltOn
				
				if beltOn then
					Citizen.Wait(1)
					
					TriggerServerEvent('InteractSound_SV:PlayOnSource', 'buckle', 0.9)
					Citizen.Wait(2500)
					notify '~y~ Seatbelt~s~: ~g~connected~s~.'
					
					SendNuiMessage { displayWindow = 'false' }
					isUiOpen = true
				else
					notify '~y~Seatbelt~s~: ~r~disconnected~s~.'
					TriggerServerEvent('InteractSound_SV:PlayOnSource', 'unbuckle', 0.9)
					
					SendNUIMessage { displayWindow = 'true' }
					isUiOpen = true
				end
			end
		elseif wasInCar then
			wasInCar = false
			beltOn = false
			speedBuffer[1], speedBuffer[2] = 0.0, 0.0
			
			if isUiOpen == true and not IsPlayerDead(PlayerId()) then
				SendNUIMessage { displayWindow = 'false' }
				isUiOpen = false
			end
		end
		
		if (IsPlayerDead(PlayerId()) and isUiOpen == true) or IsPauseMenuActive() then
			SendNUIMessage { displayWindow = 'false' }
			isUiOpen = false
		end
	end
end
Citizen.CreateThread(SeatbeltThread)

--[[
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if not beltOn and wasInCar and not IsPauseMenuActive() then

			--------- Täältä voit muuttaa ääntä, kun turvavyö ei ole päällä -------------- Tässä ----
			--------- Here you can change sounds, when seatbelt is off ------------------- Here -----
			--------- Hier kannst du den Erinnerungs-Sound zum Anschnallen einstellen ---- Hier ----- 
			TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.3, 'seatbelt', 0.3)
			Citizen.Wait(9000)
		end
	end
end)
--]]
