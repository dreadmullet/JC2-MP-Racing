----------------------------------------------------------------------------------------------------
-- Example: 
-- VehicleList[2].modelId = 2
-- VehicleList[2].name = Mancini Cavallo 1001
-- VehicleList[2].type = "Car"
-- VehicleList[2].isDLC = false
----------------------------------------------------------------------------------------------------

VehicleList.SelectRandom = function(type , allowDLC)
	
	local list = {}
	
	for modelId , vehicle in ipairs(VehicleList) do
		if type then
			if vehicle.type == type then
				if allowDLC then
					table.insert(list , vehicle)
				elseif vehicle.isDLC == false then
					table.insert(list , vehicle)
				end
			end
		else
			if allowDLC then
				table.insert(list , vehicle)
			elseif vehicle.isDLC == false then
				table.insert(list , vehicle)
			end
		end
	end
	
	if table.count(list) > 0 then
		return table.randomvalue(list)
	else
		return nil
	end
	
end

VehicleList.FindByName = function(name)
	
	for modelId , vehicle in ipairs(VehicleList) do
		if vehicle.name:find(name) then
			return vehicle
		end
	end
	
	return nil
	
end

local IsDLC = true
local IsNotDLC = false

local AddVehicle = function(modelId , name , type , isDLC)
	
	local vehicle = {}
	vehicle.modelId = modelId
	vehicle.name = name
	vehicle.type = type
	vehicle.isDLC = isDLC
	VehicleList[modelId] = vehicle
	
end

AddVehicle(1 , "Dongtai Agriboss 35" , "Car" , IsNotDLC)
AddVehicle(2 , "Mancini Cavallo 1001" , "Car" , IsNotDLC)
AddVehicle(4 , "Kenwall Heavy Rescue" , "Car" , IsNotDLC)
AddVehicle(7 , "Poloma Renegade" , "Car" , IsNotDLC)
AddVehicle(8 , "Columbi Excelsior" , "Car" , IsNotDLC)
AddVehicle(9 , "Tuk-Tuk Rickshaw" , "Car" , IsNotDLC)
AddVehicle(10 , "Saas PP12 Hogg" , "Car" , IsNotDLC)
AddVehicle(11 , "Shimuzu Tracline" , "Car" , IsNotDLC)
AddVehicle(12 , "Vanderbildt LeisureLiner" , "Car" , IsNotDLC)
AddVehicle(13 , "Stinger Dunebug 84" , "Car" , IsNotDLC)
AddVehicle(15 , "Sakura Aquila Space" , "Car" , IsNotDLC)
AddVehicle(18 , "SV-1003 Raider" , "Car" , IsNotDLC)
AddVehicle(20 , "Monster Truck" , "Car" , IsDLC)
AddVehicle(21 , "Hamaya Cougar 600" , "Car" , IsNotDLC)
AddVehicle(22 , "Tuk-Tuk Laa" , "Car" , IsNotDLC)
AddVehicle(23 , "Chevalier Liner SB" , "Car" , IsNotDLC)
AddVehicle(26 , "Chevalier Traveller SD" , "Car" , IsNotDLC)
AddVehicle(29 , "Sakura Aquila City" , "Car" , IsNotDLC)
AddVehicle(31 , "URGA-9380" , "Car" , IsNotDLC)
AddVehicle(32 , "Mosca 2000" , "Car" , IsNotDLC)
AddVehicle(33 , "Chevalier Piazza IX" , "Car" , IsNotDLC)
AddVehicle(35 , "Garret Traver-Z" , "Car" , IsNotDLC)
AddVehicle(36 , "Shimuzu Tracline" , "Car" , IsNotDLC)
AddVehicle(40 , "Fengding EC14FD2" , "Car" , IsNotDLC)
AddVehicle(41 , "Niseco Coastal D22" , "Car" , IsNotDLC)
AddVehicle(42 , "Niseco Tusker P246" , "Car" , IsNotDLC)
AddVehicle(43 , "Hamaya GSY650" , "Car" , IsNotDLC)
AddVehicle(44 , "Hamaya Oldman" , "Car" , IsNotDLC)
AddVehicle(46 , "MV V880" , "Car" , IsNotDLC)
AddVehicle(47 , "Schulz Virginia" , "Car" , IsNotDLC)
AddVehicle(48 , "Maddox FVA 45" , "Car" , IsNotDLC)
AddVehicle(49 , "Niseco Tusker D18" , "Car" , IsNotDLC)
AddVehicle(52 , "Saas PP12 Hogg" , "Car" , IsNotDLC)
AddVehicle(54 , "Boyd Fireflame 544" , "Car" , IsNotDLC)
AddVehicle(55 , "Sakura Aquila Metro ST" , "Car" , IsNotDLC)
AddVehicle(56 , "GV-104 Razorback" , "Car" , IsNotDLC)
AddVehicle(58 , "Chevalier Classic" , "Car" , IsDLC)
AddVehicle(60 , "Vaultier Patrolman" , "Car" , IsNotDLC)
AddVehicle(61 , "Makoto MZ 260X" , "Car" , IsNotDLC)
AddVehicle(63 , "Chevalier Traveller SC" , "Car" , IsNotDLC)
AddVehicle(66 , "Dinggong 134D" , "Car" , IsNotDLC)
AddVehicle(68 , "Chevalier Traveller SX" , "Car" , IsNotDLC)
AddVehicle(70 , "Sakura Aguila Forte" , "Car" , IsNotDLC)
AddVehicle(71 , "Niseco Tusker G216" , "Car" , IsNotDLC)
AddVehicle(72 , "Chepachet PVD" , "Car" , IsNotDLC)
AddVehicle(73 , "Chevalier Express HT" , "Car" , IsNotDLC)
AddVehicle(74 , "Hamaya 1300 Elite Cruiser" , "Car" , IsNotDLC)
AddVehicle(75 , "Tuk Tuk Boom Boom" , "Car" , IsDLC)
AddVehicle(76 , "SAAS PP30 Ox" , "Car" , IsNotDLC)
AddVehicle(77 , "Hedge Wildchild" , "Car" , IsNotDLC)
AddVehicle(78 , "Civadier 999" , "Car" , IsNotDLC)
AddVehicle(79 , "Pocumtuck Nomad" , "Car" , IsNotDLC)
AddVehicle(82 , "Chevalier Ice Breaker" , "Car" , IsDLC)
AddVehicle(83 , "Mosca 125 Performance" , "Car" , IsNotDLC)
AddVehicle(84 , "Marten Storm III" , "Car" , IsNotDLC)
AddVehicle(86 , "Dalton N90" , "Car" , IsNotDLC)
AddVehicle(87 , "Wilforce Trekstar" , "Car" , IsNotDLC)
AddVehicle(89 , "Hamaya Y250S" , "Car" , IsNotDLC)
AddVehicle(90 , "Makoto MZ 250" , "Car" , IsNotDLC)
AddVehicle(91 , "Titus ZJ" , "Car" , IsNotDLC)

AddVehicle(5 , "Pattani Gluay" , "Boat" , IsNotDLC)
AddVehicle(6 , "Orque Grandois 21TT" , "Boat" , IsNotDLC)
AddVehicle(16 , "YP-107 Phoenix" , "Boat" , IsNotDLC)
AddVehicle(19 , "Orque Living 42T" , "Boat" , IsNotDLC)
AddVehicle(25 , "Trat Tang-mo" , "Boat" , IsNotDLC)
AddVehicle(27 , "SnakeHead T20" , "Boat" , IsNotDLC)
AddVehicle(28 , "TextE Charteu 52CT" , "Boat" , IsNotDLC)
AddVehicle(38 , "Kuang Sunrise" , "Boat" , IsNotDLC)
AddVehicle(45 , "Orque Bon Ton 71FT" , "Boat" , IsNotDLC)
AddVehicle(50 , "Zhejiang 6903" , "Boat" , IsNotDLC)
AddVehicle(53 , "Agency Hovercraft" , "Boat" , IsDLC)
AddVehicle(69 , "Winstons Amen 69" , "Boat" , IsNotDLC)
AddVehicle(80 , "Frisco Catshark S-38" , "Boat" , IsNotDLC)
AddVehicle(88 , "MTA Powerrun 77" , "Boat" , IsNotDLC)

AddVehicle(3 , "Rowlinson K22" , "Plane" , IsNotDLC)
AddVehicle(14 , "Mullen Skeeter Eagle" , "Plane" , IsNotDLC)
AddVehicle(24 , "F-33 DragonFly Jet Fighter" , "Plane" , IsDLC)
AddVehicle(30 , "Si-47 Leopard" , "Plane" , IsNotDLC)
AddVehicle(34 , "G9 Eclipse" , "Plane" , IsNotDLC)
AddVehicle(37 , "Sivirkin 15 Havoc" , "Plane" , IsNotDLC)
AddVehicle(39 , "Aeroliner 474" , "Plane" , IsNotDLC)
AddVehicle(51 , "Cassius 192" , "Plane" , IsNotDLC)
AddVehicle(57 , "Sivirkin 15 Havoc" , "Plane" , IsNotDLC)
AddVehicle(59 , "Peek Airhawk 225" , "Plane" , IsNotDLC)
AddVehicle(62 , "UH-10 Chippewa" , "Plane" , IsNotDLC)
AddVehicle(64 , "AH-33 Topachula" , "Plane" , IsNotDLC)
AddVehicle(65 , "H-62 Quapaw" , "Plane" , IsNotDLC)
AddVehicle(67 , "Mullen Skeeter Hawk" , "Plane" , IsNotDLC)
AddVehicle(81 , "Pell Silverbolt 6" , "Plane" , IsNotDLC)
AddVehicle(85 , "Bering I-86DP" , "Plane" , IsNotDLC)
