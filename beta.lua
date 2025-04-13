local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local relief = loadstring(game:HttpGet("https://raw.githubusercontent.com/PeaPattern/relief-lib/main/new.lua"))()

relief.addCategory("Movement", "rbxassetid://1114393432")
relief.addCategory("Render", "rbxassetid://13321848320")
relief.addCategory("Combat", "rbxassetid://7485051715")
relief.addCategory("World", "rbxassetid://17640958405")
relief.addCategory("Utility", "rbxassetid://1538581893")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local chars = workspace.Characters
local regions = workspace.Regions
local terrain = workspace.BlockTerrain

local function GetWeapons()
	local Char = LocalPlayer.Character
	if not Char then return end

	local Weapons = {}

	local function Handle(Tool)
		if Tool.ClassName ~= "Tool" then return end
		
		local TS = Tool:FindFirstChild("ToolScripts")
		if not TS then return end

		local R = TS:FindFirstChild("MobileSwing")
		if not R then return end

		table.insert(Weapons, Tool)
	end

    for _, Tool in LocalPlayer.Backpack:GetChildren() do
		Handle(Tool)
	end

	for _, Tool in Char:GetChildren() do
		Handle(Tool)
	end

	return Weapons
end

local function GetOthers()
	local Others = {}
	for _, Plr in Players:GetPlayers() do
		if Plr ~= LocalPlayer then
			table.insert(Others, Plr)
		end
	end
	return Others
end

local HealNames = {"Apple", "Cookie", "Cake"}

local function FindHealTool()
	local Char = LocalPlayer.Character
	if not Char then return end

	for _, Name in HealNames do
		for _, Tool in LocalPlayer.Backpack:GetChildren() do
			if Tool.ClassName == "Tool" and Tool.Name == Name then
				return Tool
			end
		end
		for _, Tool in Char:GetChildren() do
			if Tool.ClassName == "Tool" and Tool.Name == Name then
				return Tool
			end
		end
	end
end

local function GetRemote(Folder, Whitelist)
	for _, R in Folder:GetChildren() do
		if R:IsA("RemoteEvent") and not table.find(Whitelist, R.Name) then
			return R
		end
	end
end

local healing = false
local function Heal()
	task.spawn(function()
		local Char = LocalPlayer.Character
		if not Char then return end

		local Tool = FindHealTool()
		if not Tool then return end
		if Char.Resources:GetAttribute("Food") < Tool.Stats:GetAttribute("FoodCost") then return end
		
		local Remote = GetRemote(Tool.FoodScripts, {"Eat"})
		if not Remote then return end

		healing = true
		local Moved = {}
		for _, t in Char:GetChildren() do
			if t.ClassName == "Tool" and t ~= Tool then
				t.Parent = LocalPlayer.Backpack
				table.insert(Moved, Weapon)
			end
		end
		Tool.Parent = Char
		wait()
		Remote:FireServer()
		wait()
		Tool.Parent = LocalPlayer.Backpack
		for _, Tool in Moved do
			if Tool then
				Tool.Parent = Char
			end
		end
		wait()
		healing = false
	end)
end

local waterspeed = false
local isinwater = false
local isinpond = false

for _, v in terrain:GetChildren() do
	if v.Name == "River" then
		v.Touched:Connect(function()
			isinwater = true
		end)
		v.TouchEnded:Connect(function()
			isinwater = false
		end)
	end
end

for _, v in terrain:GetChildren() do
	if v.Name == "Pool" then
		v.Touched:Connect(function()
			isinpond = true
		end)
		v.TouchEnded:Connect(function()
			isinpond = false
		end)
	end
end

local landadd = 2
local wateradd = 30
local c = {}
relief.addModule("Movement", "Speed", function(Toggled)
    if Toggled then
        local Char = LocalPlayer.Character
        local H = Char.Humanoid
		local Old = H.WalkSpeed

		local method = function()
			local Char = LocalPlayer.Character
			if not Char then return end

			local H = Char:FindFirstChildOfClass("Humanoid")
			if not H then return end

			if waterspeed then
				if isinpond then
					H.WalkSpeed = 20
					return
				end
				if isinwater then
					H.WalkSpeed = wateradd
					return
				end
			end

			H.WalkSpeed = Old + landadd
        end

		local c1
		local function start()
			c1 = RunService.Heartbeat:Connect(method)
			c[#c+1] = c1

			local Char = LocalPlayer.Character
			if not Char then return end

			local H = Char:FindFirstChildOfClass("Humanoid")
			if not H then return end

			c[#c+1] = H:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				local new = H.WalkSpeed
				if new ~= Old and new ~= (wateradd) and new ~= (Old + landadd) then
					Old = new
				end
			end)
		end

        start()
		LocalPlayer.CharacterAdded:Connect(function(Char)
			c1:Disconnect()
			wait(0.1)
			local H = Char:WaitForChild("Humanoid")
			Old = H.WalkSpeed
			isinwater = false
			start()
		end)
    else
        for _, v in c do
			v:Disconnect()
		end
		c = {}
    end
end, {
    {
        ["Type"] = "TextBox",
        ["Title"] = "speed amount",
        ["Placeholder"] = "speed here (2 default)",
        ["Callback"] = function(Text)
            landadd = tonumber(Text) or 2
        end,
    },
	{
        ["Type"] = "TextBox",
        ["Title"] = "water speed amount",
        ["Placeholder"] = "water speed here (30 default)",
        ["Callback"] = function(Text)
            wateradd = tonumber(Text) or 30
        end,
    },
    {
        ["Type"] = "Toggle",
        ["Title"] = "Water Speed",
        ["Callback"] = function(Toggled)
            waterspeed = Toggled
        end,
    },
})

local Arrow = {}
local Connections = {}

local ArrowScreen = Instance.new("ScreenGui")
ArrowScreen.Parent = CoreGui
ArrowScreen.IgnoreGuiInset = true

function Arrow.new(TargetPart)
	local Connection

	local ArrowFrame = Instance.new("Frame")
	ArrowFrame.Size = UDim2.new(0, 40, 0, 40)
	ArrowFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	ArrowFrame.BackgroundTransparency = 0.5
	ArrowFrame.BorderSizePixel = 1
	ArrowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	ArrowFrame.Parent = ArrowScreen

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0, 100, 0, 20)
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Color3.new(1, 1, 1)
	Label.Font = Enum.Font.SourceSansBold
	Label.TextScaled = true
	Label.Text = ""
	Label.AnchorPoint = Vector2.new(0.5, 0.5)
	Label.Parent = ArrowScreen
	Label.TextStrokeTransparency = 0

	local Callback

	local Object = {
		Hide = function()
			ArrowFrame.Visible = false
		end,
		Show = function()
			ArrowFrame.Visible = true
		end,
		Delete = function()
			if ArrowFrame then ArrowFrame:Destroy() end
			if Label then Label:Destroy() end
			Connection:Disconnect()
		end,
		SetText = function(Text)
			Label.Text = Text or "???"
		end,
		SetColor = function(Color)
			ArrowFrame.BackgroundColor3 = Color or Color3.new(1, 1, 1)
		end,
		SetCallback = function(Query)
			Callback = Query
		end,
	}

	Connection = RunService.Heartbeat:Connect(function()
		if not TargetPart or not TargetPart:IsDescendantOf(workspace) then Object.Delete() return end

		local Char = LocalPlayer.Character
		if not Char then Object.Hide() return end

		local Root = Char:FindFirstChild("HumanoidRootPart")
		if not Root then Object.Hide() return end

		local Value
		if Callback then
			Value = Callback(ArrowFrame)
		end
		if Value then return end

		local rootScreenPos = Camera:WorldToViewportPoint(Root.Position)
		local targetScreenPos = Camera:WorldToViewportPoint(TargetPart.Position)

		local delta = targetScreenPos - rootScreenPos
		local direction = delta.Unit

		local clampedX = math.clamp(targetScreenPos.X, 10, Camera.ViewportSize.X - 10)
		local clampedY = math.clamp(targetScreenPos.Y, 10, Camera.ViewportSize.Y - 10)
		local clampedTargetPos = Vector2.new(clampedX, clampedY)

		local displayLength = Camera.ViewportSize.Y / 3
		local arrowStart = rootScreenPos
		local arrowEnd = arrowStart + direction * displayLength
		local midpoint = arrowStart + direction * (displayLength / 2)
		local angle = math.deg(math.atan2(direction.Y, direction.X))

		ArrowFrame.Position = UDim2.fromOffset(midpoint.X, midpoint.Y)
		ArrowFrame.Size = UDim2.new(0, displayLength, 0, 4)
		ArrowFrame.Rotation = angle

		Label.Position = UDim2.fromOffset(arrowEnd.X, arrowEnd.Y)

		Object.Show()
	end)

	return Object
end

local ArrowCache = {}
relief.addModule("Render", "PlayerESP", function(Toggled)
    if Toggled then
		local function Handle(Target)
			local function OnCharacter(Char)
				if not Char then return end
				local tRoot = Char:WaitForChild("HumanoidRootPart")

				if not tRoot then return end
				local Arrow = Arrow.new(tRoot)
				Arrow.SetText(Target.Name)
				Arrow.SetCallback(function(Frame)
					local Root = LocalPlayer.Character.HumanoidRootPart
					local maxDistance = 500
					local distance = (Root.Position - tRoot.Position).Magnitude
					local clamped = math.clamp(distance / maxDistance, 0, 1)
					Frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), 1 - clamped)
				end)
				ArrowCache[#ArrowCache + 1] = Arrow
			end

			OnCharacter(Target.Character)
			Connections[#Connections + 1] = Target.CharacterAdded:Connect(OnCharacter)
		end

        for _, Target in GetOthers() do Handle(Target) end
		Connections[#Connections + 1] = Players.PlayerAdded:Connect(Handle)
	else
		for _, Arrow in ArrowCache do
			Arrow.Delete()
		end
		for _, C in Connections do
			C:Disconnect()
		end
		Connections = {}
    end
end)

local MobList = {
	["Cow"] = Color3.new(0, 0, 0),
	["Polar Bear"] = Color3.new(1, 1, 1),
	["Scorpion"] = Color3.new(1, 1, 0),
	["Swamp Beast"] = Color3.new(1, 0, 1),
	["Wandering Knight"] = Color3.new(0, 1, 1),
	["Wolf"] = Color3.new(.7, .7, .7),
	["Dire Wolf"] = Color3.new(.3, .3, .3),
	["Yeti"] = Color3.new(0, 1, 0),
	["Orc King"] = Color3.new(0, .7, 0),
	["Easter Bunny"] = Color3.new(0.5, 1, 1)
}

local function GetMob(Mob)
	for Name, Color in MobList do
		if Mob.Name == Name then
			return Color
		end
	end
end

local function GetMobs()
	local Mobs = {}
	for _, Mob in chars:GetChildren() do
		local isMob = GetMob(Mob)
		if not isMob then continue end
		Mobs[#Mobs + 1] = Mob
	end
	return Mobs
end

local MobCache = {}
local MEC
relief.addModule("Render", "MobESP", function(Toggled)
	if Toggled then
		local function HandleMob(Mob)
			local Color = GetMob(Mob)
			if not Color then return end
			
			local Torso = Mob:FindFirstChild("Torso")
			if not Torso then return end

			local Arrow = Arrow.new(Torso)
			Arrow.SetColor(Color)
			Arrow.SetText(Mob.Name)
			MobCache[#MobCache + 1] = Arrow
		end

		for _, Mob in chars:GetChildren() do
			HandleMob(Mob)
		end
		MEC = chars.ChildAdded:Connect(HandleMob)
	else
		for _, Arrow in MobCache do
			Arrow.Delete()
		end
		if MEC then
			MEC:Disconnect()
			MEC = nil
		end
	end
end)

local EggCache = {}
local Resources = workspace.Resources
relief.addModule("Render", "EggEsp", function(Toggled)
	if Toggled then
		local function Handle(Obj)
			if Obj.Name == "Egg" then
				local Arrow = Arrow.new(Obj.Egg)
				Arrow.SetText("Egg")
				EggCache[#EggCache + 1] = Arrow
			end
		end

		for _, Egg in Resources:GetChildren() do Handle(Egg) end
		Resources.ChildAdded:Connect(Handle)
	else
		for _, Egg in EggCache do
			Egg.Delete()
		end
	end
end)

relief.addModule("Render", "ModuleList", function(Toggled)
    relief.ModuleList.Visible = Toggled
end, {}, nil, true)

relief.addModule("Render", "MobileButton", function(Toggled)
    relief.MobileButton.Visible = Toggled
end, {}, nil, true)

local ahc = {}
local function handleAH(char)
	local hum = char:WaitForChild("Humanoid")
	ahc[#ahc + 1] = hum:GetPropertyChangedSignal("Health"):Connect(function()
		local health = hum.Health
		if health ~= hum.MaxHealth then
			Heal()
		end
	end)
end

relief.addModule("Combat", "AutoHeal", function(Toggled)
    if Toggled then
        local Char = LocalPlayer.Character
		if Char then handleAH(Char) end
		ahc[#ahc + 1] = LocalPlayer.CharacterAdded:Connect(handleAH)
	else
		for _, c in ahc do
			c:Disconnect()
		end
		ahc = {}
    end
end)

local multi = false
local asc = false
local oldtool
relief.addModule("Combat", "AutoSwing", function(Toggled)
    if Toggled then
		local Char = LocalPlayer.Character
		if not Char then return end
		
		asc = true
		task.spawn(function()
			oldtool = Char:FindFirstChildOfClass("Tool")
			while asc do
				task.wait()
				if multi then
					local Weapons = GetWeapons()
					if not Weapons then continue end

					for _, Weapon in Weapons do
						if healing then
							repeat task.wait() until not healing
						end
						if Weapon.Parent == LocalPlayer.Backpack then
							Weapon.Parent = Char
						end
						Weapon.ToolScripts.MobileSwing:Fire()
						wait()
						Weapon.Parent = LocalPlayer.Backpack
					end
				else
					local Weapon = Char:FindFirstChildOfClass("Tool")
					if not Weapon then continue end

					local TS = Weapon:FindFirstChild("ToolScripts")
					if not TS then continue end

					local Swing = TS:FindFirstChild("MobileSwing")
					if not Swing then continue end

					Swing:Fire()
				end
			end
		end)
	else
		asc = false
		if oldtool then
			wait()
			oldtool.Parent = LocalPlayer.Character
		end
    end
end, {
	{
		["Type"] = "Toggle",
		["Title"] = "MultiSwing",
		["Callback"] = function(Toggled)
			multi = Toggled
		end,
	}
})

local nc = {}
local ncc
relief.addModule("Movement", "Noclip", function(Toggled)
	if Toggled then
		local Character = LocalPlayer.Character
		if not Character then return end

		for _, BP in Character:GetChildren() do
			if BP:IsA("BasePart") then
				nc[#nc + 1] = {BP, BP.CanCollide}
			end
		end

		ncc = RunService.Stepped:Connect(function()
			local Character = LocalPlayer.Character
			if not Character then return end

			for _, BP in Character:GetChildren() do
				if BP:IsA("BasePart") then
					BP.CanCollide = false
				end
			end
		end)
	else
		if ncc then
			ncc:Disconnect()
			ncc = nil
		end
		for _, data in nc do
			data[1].CanCollide = data[2]
		end
	end
end)

local str = workspace.Structures
local oldhb = {}
local apc = {}
relief.addModule("Movement", "AntiPit", function(Toggled)
	if Toggled then
		local function hpt(v)
			if v.Name == "Pit Trap" then
				local hb = v:FindFirstChild("Hitbox")
				if hb then
					hb.Parent = RStorage
					oldhb[#oldhb + 1] = {v, hb}
				end
			end
		end
		for _, v in str:GetChildren() do
			hpt(v)
		end
		apc[#apc + 1] = str.ChildAdded:Connect(hpt)
	else
		for _, c in apc do
			c:Disconnect()
		end
		apc = {}
		for _, data in oldhb do
			local str, hb = data[1], data[2]
			if str then
				hb.Parent = str
			else
				if hb then hb:Destroy() end
			end
		end
	end
end)

local oldvel = {}
relief.addModule("Movement", "Jesus", function(Toggled)
	if Toggled then
		for _, v in terrain:GetChildren() do
			if v.Name == "River" then
				oldvel[#oldvel + 1] = {v, v.Velocity}
				v.Velocity = Vector3.zero
			end
		end
		for _, v in regions:GetChildren() do
			if v.Name == "River" then
				oldvel[#oldvel + 1] = {v, v.Velocity}
				v.Velocity = Vector3.zero
			end
		end
	else
		for _, data in oldvel do
			local riv, vel = data[1], data[2]
			riv.Velocity = vel
		end
	end
end)

local function block(model)
	local anti = Instance.new("Part")
	anti.Parent = workspace
	anti.Size = model:GetExtentsSize()
	anti.Anchored = true
	anti.Transparency = 0.5
	anti.Color = Color3.new(1, 0, 0)
	anti.Material = Enum.Material.SmoothPlastic
	anti.CFrame = model:GetPivot()
	local c
	c = model.Parent.ChildRemoved:Connect(function(obj)
		if obj == model then
			anti:Destroy()
			c:Disconnect()
		end
	end)
	return anti
end

local cache = {}
local Resources = workspace.Resources
relief.addModule("World", "AntiCactus", function(Toggled)
	if Toggled then
		for _, v in Resources:GetChildren() do
			if v.Name == "Tree" and v:FindFirstChild("cactus") then
				local anti = block(v)
				cache[#cache + 1] = anti
			end
		end
	else
		for _, v in cache do
			v:Destroy()
		end
	end
end)

local spikes = {}
local asc
relief.addModule("World", "AntiSpike", function(Toggled)
	if Toggled then
		local function validate(obj)
			if obj.Name == "Spikes" or obj.Name == "Super Spikes" or obj.Name == "Poisoned Spikes" or obj.Name == "Spike Trap" then
				local anti = block(obj)
				spikes[#spikes + 1] = anti
			end
		end
		for _, obj in str:GetChildren() do
			validate(obj)
		end
		asc = str.ChildAdded:Connect(validate)
	else
		for _, spike in spikes do
			spike:Destroy()
		end
		spikes = {}
		if asc then
			asc:Disconnect()
			asc = nil
		end
	end
end)

local Details = workspace.Details
local BP = workspace.Baseplate
relief.addModule("World", "AntiLag", function(Toggled)
	if Toggled then
		Details.Parent = RStorage
		BP.Parent = RStorage
	else
		Details.Parent = workspace
		BP.Parent = workspace
	end
end)

local ss = Instance.new("ScreenGui")
ss.Parent = CoreGui
ss.ResetOnSpawn = false
ss.IgnoreGuiInset = true

local labels = {}
local count = 0
local function reset()
	count = 0
	for _, label in labels do
		label:Destroy()
	end
end

local function newLabel(text, color)
	count += 1
	local Label = Instance.new("TextLabel")
	Label.Parent = ss
	Label.BackgroundTransparency = 1
	Label.Size = UDim2.new(.3, 0, .05, 0)
	Label.Position = UDim2.new(.5, 0, (count / 20), 0)
	Label.AnchorPoint = Vector2.new(0.5, 0.5)
	Label.TextScaled = true
	Label.TextColor3 = color or Color3.new(1, 1, 1)
	Label.Text = text
	Label.TextStrokeTransparency = 0
	labels[#labels + 1] = Label
end

local sdc
relief.addModule("Utility", "StatDisplay", function(Toggled)
	if Toggled then
		sdc = true
		local last
		while sdc do
			task.wait(.1)
			if not sdc then break end
			
			local Char = LocalPlayer.Character
			if not Char then continue end

			local Tool = Char:FindFirstChildOfClass("Tool")
			if not Tool then continue end

			if last and Tool == last then continue end
			last = Tool

			local Stats = Tool:FindFirstChild("Stats")
			if not Stats then continue end

			reset()
			local Attributes = Stats:GetAttributes()
			newLabel(Tool.Name, Color3.new(1, 0, 0))
			for Name, Value in Attributes do
				newLabel((Name or "Unknown") .. ": " .. (Value or "???"))
			end
		end
	else
		sdc = false
		reset()
	end
end)

local fov = 90
local Camera = workspace.CurrentCamera
local old = Camera.FieldOfView
local fovc
relief.addModule("Render", "FOV", function(Toggled)
	if Toggled then
		old = Camera.FieldOfView
		Camera.FieldOfView = fov
		fovc = Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
			if Camera.FieldOfView ~= fov then
				Camera.FieldOfView = fov
			end
		end)
	else
		if fovc then
			fovc:Disconnect()
			fovc = nil
		end
		Camera.FieldOfView = old
	end
end, {
    {
        ["Type"] = "TextBox",
        ["Title"] = "fov amount",
        ["Placeholder"] = "fov here (90 default)",
        ["Callback"] = function(Text)
            local amount = tonumber(Text) or 90
			fov = amount
			Camera.FieldOfView = fov
        end,
    }
})

local srhb = {}
local src
relief.addModule("Utility", "ShowRange", function(Toggled)
	if Toggled then
		local Char = LocalPlayer.Character
		if not Char then return end
		
		local Root = Char:FindFirstChild("HumanoidRootPart")
		if not Root then return end

		local function Hitbox(Tool)
			local Stats = Tool:FindFirstChild("Stats")
			if not Stats then return end

			local Range = Stats:GetAttribute("Range")
			if not Range then return end

			if Tool:FindFirstChild("HB") then return end

			local HB = Instance.new("Part")
			HB.Parent = Tool
			HB.CanCollide = false
			local am = Range * 2
			HB.Size = Vector3.new(am, am, am)
			HB.Transparency = 0.7
			HB.Material = Enum.Material.SmoothPlastic
			HB.Name = "HB"
			HB.Color = Color3.new(1, 0, 0)
			HB.Massless = true
			HB.Shape = Enum.PartType.Ball

			local Weld = Instance.new("Weld")
			Weld.Parent = HB
			Weld.Part0 = HB
			Weld.Part1 = Tool.Origin

			srhb[#srhb + 1] = HB
		end
		
		local Tool = Char:FindFirstChildOfClass("Tool")
		if Tool then Hitbox(Tool) end

		src = Char.ChildAdded:Connect(function(Tool)
			if Tool:IsA("Tool") then
				Hitbox(Tool)
			end
		end)
	else
		for _, v in srhb do
			v:Destroy()
		end
		if src then
			src:Disconnect()
			src = nil
		end
	end
end)

local function GetNearestPlayer()
	local Char = LocalPlayer.Character
	if not Char then return end

	local Root = Char:FindFirstChild("HumanoidRootPart")
	if not Root then return end
	
	local Data = {nil, nil}
	for _, Plr in GetOthers() do
		local tChar = Plr.Character
		if not tChar then continue end

		local tRoot = tChar:FindFirstChild("HumanoidRootPart")
		if not tRoot then continue end

		local Distance = (Root.Position - tRoot.Position).Magnitude
		
		local CurrentDistance = Data[2]
		if not CurrentDistance then
			Data = {Plr, Distance}
		else
			if Distance < CurrentDistance then
				Data = {Plr, Distance}
			end
		end
	end
	return Data
end

local function GetNearestMob()
	local Char = LocalPlayer.Character
	if not Char then return end

	local Root = Char:FindFirstChild("HumanoidRootPart")
	if not Root then return end
	
	local Data = {nil, nil}
	for _, Plr in GetMobs() do
		local tRoot = Plr:FindFirstChild("Torso")
		if not tRoot then continue end

		local Distance = (Root.Position - tRoot.Position).Magnitude
		
		local CurrentDistance = Data[2]
		if not CurrentDistance then
			Data = {Plr, Distance}
		else
			if Distance < CurrentDistance then
				Data = {Plr, Distance}
			end
		end
	end
	return Data
end

local mobaura = false
local kac = false
local range = 8
relief.addModule("Combat", "KillAura", function(Toggled)
	if Toggled then
		local looping = false
		local oldwep = nil
		local attacking = false

		local function start()
			if not attacking then
				oldwep = LocalPlayer.Character:FindFirstChildOfClass("Tool")
			end
			attacking = true
		end

		local function stop()
			if attacking then
				repeat wait() until not looping
				if oldwep then
					oldwep.Parent = LocalPlayer.Character
				end
				oldwep = nil
			end
			attacking = false
		end

		kac = true
		while kac do
			task.wait()
			local Char = LocalPlayer.Character
			if not Char then attacking = false continue end

			local Root = Char:FindFirstChild("HumanoidRootPart")
			if not Root then attacking = false continue end

			task.spawn(function()
				local Data = GetNearestPlayer()
				local Target = Data[1]
				if not Data or not Target then stop() return end

				local Distance = Data[2]
				if Distance > range then stop() return end

				local tChar = Target.Character
				if not tChar then return end

				local tRoot = tChar:FindFirstChild("Torso")
				if not tRoot then stop() return end

				local tHum = tChar:FindFirstChildOfClass("Humanoid")
				if not tHum or tHum.Health <= 0 then stop() return end

				local Weapons = GetWeapons()
				if not Weapons then stop() return end

				start()
				Root.CFrame = CFrame.lookAt(Root.Position, tRoot.Position)

				task.spawn(function()
					if looping or Weapons == {} then return end
					looping = true

					for _, Weapon in Weapons do
						if not Weapon then continue end
						local TS = Weapon:FindFirstChild("ToolScripts")
						if not TS then continue end
						local R = TS:FindFirstChild("MobileSwing")
						if not R then continue end

						if healing then
							repeat task.wait() until not healing
						end
						if Weapon.Parent == LocalPlayer.Backpack then
							Weapon.Parent = Char
						end
						local TS = Weapon:FindFirstChild("ToolScripts")
						if not TS then continue end

						R:Fire()
						wait()
						Weapon.Parent = LocalPlayer.Backpack
					end
					looping = false
				end)
			end)

			task.spawn(function()
				if not mobaura then return end

				local Data = GetNearestMob()
				local Target = Data[1]
				if not Data or not Target then stop() return end

				local Distance = Data[2]
				if Distance > range then stop() return end

				local tRoot = Target:FindFirstChild("HumanoidRootPart")
				if not tRoot then stop() return end

				local Weapons = GetWeapons()
				if not Weapons then stop() return end

				start()
				Root.CFrame = CFrame.lookAt(Root.Position, tRoot.Position)

				task.spawn(function()
					if looping or Weapons == {} then return end
					looping = true

					for _, Weapon in Weapons do
						if not Weapon then continue end
						local TS = Weapon:FindFirstChild("ToolScripts")
						if not TS then continue end
						local R = TS:FindFirstChild("MobileSwing")
						if not R then continue end

						if healing then
							repeat task.wait() until not healing
						end
						if Weapon.Parent == LocalPlayer.Backpack then
							Weapon.Parent = Char
						end
						local TS = Weapon:FindFirstChild("ToolScripts")
						if not TS then continue end

						R:Fire()
						wait()
						Weapon.Parent = LocalPlayer.Backpack
					end
					looping = false
				end)
			end)
		end
	else
		kac = false
	end
end, {
    {
        ["Type"] = "TextBox",
        ["Title"] = "range",
        ["Placeholder"] = "range here (8 default)",
        ["Callback"] = function(Text)
            range = tonumber(Text) or 8
        end,
    },
	{
        ["Type"] = "Toggle",
        ["Title"] = "Attack Mobs",
        ["Callback"] = function(Toggled)
            mobaura = Toggled
        end,
    },
})

game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Relief", Text = "Discord link copied. Join for more scripts!", Duration = 5})
setclipboard("https://discord.gg/5WyMy9n975")
