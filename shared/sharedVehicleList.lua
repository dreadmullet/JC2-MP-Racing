----------------------------------------------------------------------------------------------------
-- Example: 
-- VehicleList[2].modelId = 2
-- VehicleList[2].name = Mancini Cavallo 1001
-- VehicleList[2].type = "Land"
-- VehicleList[2].isDLC = false
----------------------------------------------------------------------------------------------------
VehicleList = {}

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

AddVehicle(1 , "Dongtai Agriboss 35" , "Land" , IsNotDLC)
AddVehicle(2 , "Mancini Cavallo 1001" , "Land" , IsNotDLC)
AddVehicle(4 , "Kenwall Heavy Rescue" , "Land" , IsNotDLC)
AddVehicle(7 , "Poloma Renegade" , "Land" , IsNotDLC)
AddVehicle(8 , "Columbi Excelsior" , "Land" , IsNotDLC)
AddVehicle(9 , "Tuk-Tuk Rickshaw" , "Land" , IsNotDLC)
AddVehicle(10 , "Saas PP12 Hogg" , "Land" , IsNotDLC)
AddVehicle(11 , "Shimuzu Tracline" , "Land" , IsNotDLC)
AddVehicle(12 , "Vanderbildt LeisureLiner" , "Land" , IsNotDLC)
AddVehicle(13 , "Stinger Dunebug 84" , "Land" , IsNotDLC)
AddVehicle(15 , "Sakura Aquila Space" , "Land" , IsNotDLC)
AddVehicle(18 , "SV-1003 Raider" , "Land" , IsNotDLC)
AddVehicle(20 , "Monster Truck" , "Land" , IsDLC)
AddVehicle(21 , "Hamaya Cougar 600" , "Land" , IsNotDLC)
AddVehicle(22 , "Tuk-Tuk Laa" , "Land" , IsNotDLC)
AddVehicle(23 , "Chevalier Liner SB" , "Land" , IsNotDLC)
AddVehicle(26 , "Chevalier Traveller SD" , "Land" , IsNotDLC)
AddVehicle(29 , "Sakura Aquila City" , "Land" , IsNotDLC)
AddVehicle(31 , "URGA-9380" , "Land" , IsNotDLC)
AddVehicle(32 , "Mosca 2000" , "Land" , IsNotDLC)
AddVehicle(33 , "Chevalier Piazza IX" , "Land" , IsNotDLC)
AddVehicle(35 , "Garret Traver-Z" , "Land" , IsNotDLC)
AddVehicle(36 , "Shimuzu Tracline" , "Land" , IsNotDLC)
AddVehicle(40 , "Fengding EC14FD2" , "Land" , IsNotDLC)
AddVehicle(41 , "Niseco Coastal D22" , "Land" , IsNotDLC)
AddVehicle(42 , "Niseco Tusker P246" , "Land" , IsNotDLC)
AddVehicle(43 , "Hamaya GSY650" , "Land" , IsNotDLC)
AddVehicle(44 , "Hamaya Oldman" , "Land" , IsNotDLC)
AddVehicle(46 , "MV V880" , "Land" , IsNotDLC)
AddVehicle(47 , "Schulz Virginia" , "Land" , IsNotDLC)
AddVehicle(48 , "Maddox FVA 45" , "Land" , IsNotDLC)
AddVehicle(49 , "Niseco Tusker D18" , "Land" , IsNotDLC)
AddVehicle(52 , "Saas PP12 Hogg" , "Land" , IsNotDLC)
AddVehicle(54 , "Boyd Fireflame 544" , "Land" , IsNotDLC)
AddVehicle(55 , "Sakura Aquila Metro ST" , "Land" , IsNotDLC)
AddVehicle(56 , "GV-104 Razorback" , "Land" , IsNotDLC)
AddVehicle(58 , "Chevalier Classic" , "Land" , IsDLC)
AddVehicle(60 , "Vaultier Patrolman" , "Land" , IsNotDLC)
AddVehicle(61 , "Makoto MZ 260X" , "Land" , IsNotDLC)
AddVehicle(63 , "Chevalier Traveller SC" , "Land" , IsNotDLC)
AddVehicle(66 , "Dinggong 134D" , "Land" , IsNotDLC)
AddVehicle(68 , "Chevalier Traveller SX" , "Land" , IsNotDLC)
AddVehicle(70 , "Sakura Aguila Forte" , "Land" , IsNotDLC)
AddVehicle(71 , "Niseco Tusker G216" , "Land" , IsNotDLC)
AddVehicle(72 , "Chepachet PVD" , "Land" , IsNotDLC)
AddVehicle(73 , "Chevalier Express HT" , "Land" , IsNotDLC)
AddVehicle(74 , "Hamaya 1300 Elite Cruiser" , "Land" , IsNotDLC)
AddVehicle(75 , "Tuk Tuk Boom Boom" , "Land" , IsDLC)
AddVehicle(76 , "SAAS PP30 Ox" , "Land" , IsNotDLC)
AddVehicle(77 , "Hedge Wildchild" , "Land" , IsNotDLC)
AddVehicle(78 , "Civadier 999" , "Land" , IsNotDLC)
AddVehicle(79 , "Pocumtuck Nomad" , "Land" , IsNotDLC)
AddVehicle(82 , "Chevalier Ice Breaker" , "Land" , IsDLC)
AddVehicle(83 , "Mosca 125 Performance" , "Land" , IsNotDLC)
AddVehicle(84 , "Marten Storm III" , "Land" , IsNotDLC)
AddVehicle(86 , "Dalton N90" , "Land" , IsNotDLC)
AddVehicle(87 , "Wilforce Trekstar" , "Land" , IsNotDLC)
AddVehicle(89 , "Hamaya Y250S" , "Land" , IsNotDLC)
AddVehicle(90 , "Makoto MZ 250" , "Land" , IsNotDLC)
AddVehicle(91 , "Titus ZJ" , "Land" , IsNotDLC)

AddVehicle(5 , "Pattani Gluay" , "Water" , IsNotDLC)
AddVehicle(6 , "Orque Grandois 21TT" , "Water" , IsNotDLC)
AddVehicle(16 , "YP-107 Phoenix" , "Water" , IsNotDLC)
AddVehicle(19 , "Orque Living 42T" , "Water" , IsNotDLC)
AddVehicle(25 , "Trat Tang-mo" , "Water" , IsNotDLC)
AddVehicle(27 , "SnakeHead T20" , "Water" , IsNotDLC)
AddVehicle(28 , "TextE Charteu 52CT" , "Water" , IsNotDLC)
AddVehicle(38 , "Kuang Sunrise" , "Water" , IsNotDLC)
AddVehicle(45 , "Orque Bon Ton 71FT" , "Water" , IsNotDLC)
AddVehicle(50 , "Zhejiang 6903" , "Water" , IsNotDLC)
AddVehicle(53 , "Agency Hovercraft" , "Water" , IsDLC)
AddVehicle(69 , "Winstons Amen 69" , "Water" , IsNotDLC)
AddVehicle(80 , "Frisco Catshark S-38" , "Water" , IsNotDLC)
AddVehicle(88 , "MTA Powerrun 77" , "Water" , IsNotDLC)

AddVehicle(3 , "Rowlinson K22" , "Air" , IsNotDLC)
AddVehicle(14 , "Mullen Skeeter Eagle" , "Air" , IsNotDLC)
AddVehicle(24 , "F-33 DragonFly Jet Fighter" , "Air" , IsDLC)
AddVehicle(30 , "Si-47 Leopard" , "Air" , IsNotDLC)
AddVehicle(34 , "G9 Eclipse" , "Air" , IsNotDLC)
AddVehicle(37 , "Sivirkin 15 Havoc" , "Air" , IsNotDLC)
AddVehicle(39 , "Aeroliner 474" , "Air" , IsNotDLC)
AddVehicle(51 , "Cassius 192" , "Air" , IsNotDLC)
AddVehicle(57 , "Sivirkin 15 Havoc" , "Air" , IsNotDLC)
AddVehicle(59 , "Peek Airhawk 225" , "Air" , IsNotDLC)
AddVehicle(62 , "UH-10 Chippewa" , "Air" , IsNotDLC)
AddVehicle(64 , "AH-33 Topachula" , "Air" , IsNotDLC)
AddVehicle(65 , "H-62 Quapaw" , "Air" , IsNotDLC)
AddVehicle(67 , "Mullen Skeeter Hawk" , "Air" , IsNotDLC)
AddVehicle(81 , "Pell Silverbolt 6" , "Air" , IsNotDLC)
AddVehicle(85 , "Bering I-86DP" , "Air" , IsNotDLC)
