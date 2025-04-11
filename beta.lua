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
local regions = workspace.Regions
local terrain = workspace.BlockTerrain

local function GetCharacter(Target)
    Target = Target or LocalPlayer
    local Char = workspace.Characters:FindFirstChild(Target.Name)
    return Char
end

local HealNames = {"Apple", "Cookie", "Cake"}

local function FindHealTool()
	local Char = GetCharacter()
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

local function Heal()
	task.spawn(function()
		local Char = GetCharacter()
		if not Char then return end

		local Weapon = Char:FindFirstChildOfClass("Tool")
		local Tool = FindHealTool()
		if Char.Resources:GetAttribute("Food") < Tool.Stats:GetAttribute("FoodCost") then return end
		Tool.Parent = Char

		local Remote = GetRemote(Tool.FoodScripts, {"Eat"})
		if Remote then
			repeat
				Remote:FireServer()
				task.wait()
			until Char.Humanoid.Health == Char.Humanoid.MaxHealth
		end

		Weapon.Parent = LocalPlayer.Backpack
		wait()
		Tool.Parent = LocalPlayer.Backpack
		wait()
		Weapon.Parent = Char
	end)
end

local waterspeed = false
local isinwater = false

local rivers = {}
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

local landadd = 2.5
local wateradd = 30
local c = {}
relief.addModule("Movement", "Speed", function(Toggled)
    if Toggled then
        local Char = GetCharacter()
        local H = Char.Humanoid
		local Old = H.WalkSpeed

		local method = function()
			local Char = GetCharacter()
			if not Char then return end

			local H = Char:FindFirstChildOfClass("Humanoid")
			if not H then return end

			if waterspeed and isinwater then
				H.WalkSpeed = wateradd
			else
				H.WalkSpeed = Old + landadd
			end
        end

		local c1
		local function start()
			c1 = RunService.Heartbeat:Connect(method)
			c[#c+1] = c1

			local Char = GetCharacter()
			if not Char then return end

			local H = Char:FindFirstChildOfClass("Humanoid")
			if not H then return end

			c[#c+1] = H:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				local new = H.WalkSpeed
				if new ~= Old and new ~= (Old + wateradd) and new ~= (Old + landadd) then
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
        ["Placeholder"] = "speed here (2.5 default)",
        ["Callback"] = function(Text)
            landadd = tonumber(Text) or 2.5
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

local arrows = {}
local connections = {}

local function createarrow(Target)
	local arrow = Instance.new("Part")
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.Material = Enum.Material.SmoothPlastic
	arrow.Parent = workspace
	arrow.Transparency = 0.5
	arrow.CastShadow = false

	local outline = Instance.new("SelectionBox")
	outline.Parent = arrow
	outline.Adornee = arrow
	outline.LineThickness = 0.01
	outline.Color3 = Color3.new(0, 0, 0)
	outline.SurfaceTransparency = 1
	outline.Transparency = 0.5

	local genre = Instance.new("BillboardGui")
	genre.Parent = arrow
	genre.AlwaysOnTop = true
	genre.Size = UDim2.new(10, 0, 1, 0)

	local label = Instance.new("TextLabel")
	label.Parent = genre
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextStrokeTransparency = 0
	label.Text = Target.Name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.SourceSansBold

	local Connection
	local Connection2
	local function DeleteArrow()
		if arrow then
			arrow:Destroy()
		end
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end
		if Connection2 then
			Connection2:Disconnect()
			Connection2 = nil
		end
	end

	arrows[#arrows + 1] = DeleteArrow

	local Char = GetCharacter()
	if not Char then return end

	local tChar = GetCharacter(Target)
	if not tChar then return end

	local tHum = tChar:FindFirstChildOfClass("Humanoid")
	if not tHum then return end

	connections[#connections + 1] = tHum.Died:Connect(DeleteArrow)

	local Connection = RunService.Heartbeat:Connect(function()
		local Char = GetCharacter()
		if not Char then return end

		local tChar = GetCharacter(Target)
		if not tChar then return end

		local Root = Char:FindFirstChild("HumanoidRootPart")
		if not Root then return end

		local tRoot = tChar:FindFirstChild("HumanoidRootPart")
		if not tRoot then return end

		local maxDistance = 500

		local distance = (Root.Position - tRoot.Position).Magnitude
		local clamped = math.clamp(distance / maxDistance, 0, 1)

		local red = Color3.fromRGB(255, 0, 0)
		local green = Color3.fromRGB(0, 255, 0)
		arrow.Color = red:Lerp(green, 1 - clamped)

		local arrowPosition = Root.Position + (Root.Position - tRoot.Position).unit * 5
		arrow.Size = Vector3.new(0.2, 32, 32)
		arrow.CFrame = CFrame.new(arrowPosition, tRoot.Position) * CFrame.new(0, 0, -24)
	end)

	local Connection2 = Players.PlayerRemoving:Connect(function(Plr)
		if Plr == Target then
			DeleteArrow()
		end
	end)
end

local function handle(Target)
	createarrow(Target)
	connections[#connections + 1] = Target.CharacterAdded:Connect(function()
		wait(0.1)
		createarrow(Target)
	end)
end

relief.addModule("Render", "Arrows", function(Toggled)
    if Toggled then
        for _, Target in Players:GetPlayers() do
            if Target == LocalPlayer then continue end
			handle(Target)
        end
		connections[#connections + 1] = Players.PlayerAdded:Connect(handle)
	else
		for _, arrow in arrows do
			arrow()
		end
		for _, c in connections do
			c:Disconnect()
		end
		connections = {}
    end
end)

local Resources = workspace.Resources
local arroweggs = {}
relief.addModule("Render", "EggEsp", function(Toggled)
	if Toggled then
		local function handle(obj)
			if obj.Name == "Egg" then
				local arrow = Instance.new("Part")
				arrow.Anchored = true
				arrow.CanCollide = false
				arrow.Material = Enum.Material.SmoothPlastic
				arrow.Parent = workspace
				arrow.Transparency = 0.5
				arrow.CastShadow = false

				local outline = Instance.new("SelectionBox")
				outline.Parent = arrow
				outline.Adornee = arrow
				outline.LineThickness = 0.01
				outline.Color3 = Color3.new(0, 0, 0)
				outline.SurfaceTransparency = 1
				outline.Transparency = 0.5
				
				local C
				C = RunService.Heartbeat:Connect(function()
					if not obj then arrow:Destroy() C:Disconnect() return end

					local Char = GetCharacter()
					if not Char then return end

					local Root = Char:FindFirstChild("HumanoidRootPart")
					if not Root then return end

					local tRoot = obj:FindFirstChild("Egg")
					if not tRoot then return end

					local maxDistance = 500

					local distance = (Root.Position - tRoot.Position).Magnitude
					local clamped = math.clamp(distance / maxDistance, 0, 1)

					local red = Color3.fromRGB(255, 0, 0)
					local green = Color3.fromRGB(0, 255, 0)
					arrow.Color = red:Lerp(green, 1 - clamped)

					local arrowPosition = Root.Position + (Root.Position - tRoot.Position).unit * 5
					arrow.Size = Vector3.new(0.2, 32, 32)
					arrow.CFrame = CFrame.new(arrowPosition, tRoot.Position) * CFrame.new(0, 0, -24)
				end)

				arroweggs[#arroweggs + 1] = {arrow, C}
			end
		end

		for _, v in Resources:GetChildren() do
			handle(v)
		end
		arroweggs[#arroweggs] = {nil, Resources.ChildAdded:Connect(handle)}
	else
		for _, v in arroweggs do
			local egg, c = v[1], v[2]
			if egg then egg:Destroy() end
			if c then c:Disconnect() end
		end
		arroweggs = {}
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
		if health <= 90 then
			Heal()
		end
	end)
end

relief.addModule("Combat", "AutoHeal", function(Toggled)
    if Toggled then
        local Char = GetCharacter()
		if Char then handleAH(Char) end
		ahc[#ahc + 1] = LocalPlayer.CharacterAdded:Connect(handleAH)
	else
		for _, c in ahc do
			c:Disconnect()
		end
		ahc = {}
    end
end)

local asc = false
relief.addModule("Combat", "AutoSwing", function(Toggled)
    if Toggled then
		local Char = GetCharacter()
		if not Char then return end
		
		asc = true
		task.spawn(function()
			while asc do
				task.wait()
				local Weapon = Char:FindFirstChildOfClass("Tool")
				if not Weapon then continue end

				local TS = Weapon:FindFirstChild("ToolScripts")
				if not TS then continue end

				local Swing = TS:FindFirstChild("MobileSwing")
				if not Swing then continue end

				Swing:Fire()
			end
		end)
	else
		asc = false
    end
end)

local nc = {}
local ncc
relief.addModule("Movement", "Noclip", function(Toggled)
	if Toggled then
		local Character = GetCharacter()
		if not Character then return end

		for _, BP in Character:GetChildren() do
			if BP:IsA("BasePart") then
				nc[#nc + 1] = {BP, BP.CanCollide}
			end
		end

		ncc = RunService.Stepped:Connect(function()
			local Character = GetCharacter()
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
			
			local Char = GetCharacter()
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
relief.addModule("Utility", "ShowRange", function(Toggled)
	if Toggled then
		local Char = GetCharacter()
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

		Char.ChildAdded:Connect(function(Tool)
			if Tool:IsA("Tool") then
				Hitbox(Tool)
			end
		end)
	else
		for _, v in srhb do
			v:Destroy()
		end
	end
end)

local function GetOthers()
	local Others = {}
	for _, Plr in Players:GetPlayers() do
		if Plr ~= LocalPlayer then
			table.insert(Others, Plr)
		end
	end
	return Others
end

local function GetNearestPlayer()
	local Char = GetCharacter()
	if not Char then return end

	local Root = Char:FindFirstChild("HumanoidRootPart")
	if not Root then return end
	
	local Data = {nil, nil}
	for _, Plr in GetOthers() do
		local tChar = GetCharacter(Plr)
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

local function GetWeapons()
	local Char = GetCharacter()
	if not Char then return end

	local Weapons = {}

	for _, Tool in LocalPlayer.Backpack:GetChildren() do
		if Tool.ClassName ~= "Tool" then continue end
		
		local ToolScripts = Tool:FindFirstChild("ToolScripts")
		if not ToolScripts then continue end

		local Remote = ToolScripts:FindFirstChild("MobileSwing")
		if not Remote then continue end

		Weapons[#Weapons + 1] = Tool
	end

	for _, Tool in Char:GetChildren() do
		if Tool.ClassName ~= "Tool" then continue end
		
		local ToolScripts = Tool:FindFirstChild("ToolScripts")
		if not ToolScripts then continue end

		local Remote = ToolScripts:FindFirstChild("MobileSwing")
		if not Remote then continue end

		Weapons[#Weapons + 1] = Tool
	end

	return Weapons
end

local kac = false
relief.addModule("Combat", "KillAura", function(Toggled)
	if Toggled then
		kac = true
		local looping = false
		while kac do
			task.wait()
			local Char = GetCharacter()
			if not Char then continue end

			local Root = Char:FindFirstChild("HumanoidRootPart")
			if not Root then continue end

			local Data = GetNearestPlayer()
			local Target = Data[1]
			if not Data or not Target then continue end

			local Distance = Data[2]
			if Distance > 8 then continue end

			local tChar = GetCharacter(Target)
			if not tChar then continue end

			local tHum = tChar:FindFirstChildOfClass("Humanoid")
			if not tHum or tHum.Health <= 0 then continue end

			local tRoot = tChar:FindFirstChild("HumanoidRootPart")
			if not tRoot then continue end

			Root.CFrame = CFrame.lookAt(Root.Position, tRoot.Position)

			local Weapons = GetWeapons()
			if not Weapons then continue end
			
			task.spawn(function()
				if looping then return end
				local oldtool = Char:FindFirstChildOfClass("Tool")
				looping = true
				for _, Tool in Weapons do
					if Tool.Parent == LocalPlayer.Backpack then
						Tool.Parent = Char
					end
					Tool.ToolScripts.MobileSwing:Fire()
					wait()
					Tool.Parent = LocalPlayer.Backpack
				end
				looping = false
				if oldtool then
					for _, Tool in Weapons do
						Tool.Parent = LocalPlayer.Backpack
					end
					oldtool.Parent = Char
				end
			end)
		end
	else
		kac = false
	end
end)

game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Relief", Text = "Discord link copied. Join for more scripts!", Duration = 5})
setclipboard("https://discord.gg/5WyMy9n975")
