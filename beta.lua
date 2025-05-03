------------------ Variables & Functions
local Players = game:GetService("Players")
local RStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Remotes = RStorage.Remotes

local Tribes = Remotes.Tribes
local Hats = Remotes.Hats

local Characters = workspace.Characters
local Regions = workspace.Regions
local BlockTerrain = workspace.BlockTerrain
local Resources = workspace.Resources
local Structures = workspace.Structures
local Details = workspace.Details

local function Block(Model)
	local Barrier = Instance.new("Part")
	Barrier.Parent = workspace
	Barrier.Size = Model:GetExtentsSize()
	Barrier.Anchored = true
	Barrier.Transparency = 0.5
	Barrier.Color = Color3.new(1, 0, 0)
	Barrier.Material = Enum.Material.SmoothPlastic
	Barrier.CFrame = Model:GetPivot()

	local Connection
	Connection = Model.Parent.ChildRemoved:Connect(function(Object)
		if Object == Model then
			Barrier:Destroy()
			Connection:Disconnect()
		end
	end)

	return Barrier
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

local function RandomString(Length)
    local Chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local Result = ""
    
    for i = 1, Length do
        local RNG = math.random(1, #Chars)
        Result = Result .. Chars:sub(RNG, RNG)
    end
    
    return Result
end

local function GetRoot(Target)
	Target = Target or LocalPlayer
	local Char = Target.Character
	if not Char then return end

	return Char:FindFirstChild("Torso")
end

local function GetHumanoid(Target)
	Target = Target or LocalPlayer
	local Char = Target.Character
	if not Char then return end

	return Char:FindFirstChildOfClass("Humanoid")
end

local function GetHeal()
	local Char = LocalPlayer.Character
	if not Char then return end

	local Backpack = LocalPlayer.Backpack
	if not Backpack then return end

    for _, Tool in Backpack:GetChildren() do
		if Tool.ClassName ~= "Tool" then continue end
		
		local FS = Tool:FindFirstChild("FoodScripts")
		if not FS then continue end

		local R = FS:FindFirstChild("Eat")
		if not R then continue end

		return Tool
	end

	for _, Tool in Char:GetChildren() do
		if Tool.ClassName ~= "Tool" then continue end
		
		local FS = Tool:FindFirstChild("FoodScripts")
		if not FS then continue end

		local R = FS:FindFirstChild("Eat")
		if not R then continue end

		return Tool
	end
end

local function GetWeapons()
	local Char = LocalPlayer.Character
	if not Char then return end

	local Backpack = LocalPlayer.Backpack
	if not Backpack then return end

	local Weapons = {}

	local function Handle(Tool)
		if Tool.ClassName ~= "Tool" then return end
		
		local TS = Tool:FindFirstChild("ToolScripts")
		if not TS then return end

		local R = TS:FindFirstChild("MobileSwing")
		if not R then return end

		Weapons[#Weapons + 1] = Tool
	end

    for _, Tool in Backpack:GetChildren() do
		Handle(Tool)
	end

	for _, Tool in Char:GetChildren() do
		Handle(Tool)
	end

	return Weapons
end

------------------ Relief Ui
local Relief = loadstring(game:HttpGet("https://raw.githubusercontent.com/PeaPattern/relief-lib/main/new.lua"))()

Relief.addCategory("Movement", "rbxassetid://1114393432")
Relief.addCategory("Render", "rbxassetid://13321848320")
Relief.addCategory("Combat", "rbxassetid://7485051715")
Relief.addCategory("World", "rbxassetid://17640958405")
Relief.addCategory("Utility", "rbxassetid://1538581893")

------------------ Threads Library
local Threads = {}
Threads.Container = {}

function Threads:New(Name, Callback)
	if Threads.Container[Name] then
		Threads:Stop(Name)
	end

	local Running = true
	local ThreadObj = {}
	function ThreadObj:Disconnect()
		Running = false
		local Found = table.find(Threads.Container, ThreadObj)
		if Found then
			table.remove(Threads.Container, Found)
		end
	end
	Threads.Container[Name] = ThreadObj

	task.spawn(function()
		while Running do
			task.wait()
			local S, F = pcall(Callback)
			if not S then
				warn(F)
				ThreadObj:Disconnect()
				break
			end
		end
	end)

	return ThreadObj
end

function Threads:Get(Name)
	local Found = Threads.Container[Name]
	if Found then
		return Found
	end
end

function Threads:Stop(Name)
	local Found = Threads:Get(Name)
	if Found then
		Found:Disconnect()
	end
end

------------------ Maid Library
local Maid = {}

function Maid:Tag(Name, Connection)
	if not Maid[Name] then Maid[Name] = {} end
	table.insert(Maid[Name], Connection)
end

function Maid:Disconnect(Name)
	local Found = Maid[Name]
	if Found then
		for _, Connection in Found do
			if Connection then
				Connection:Disconnect()
			end
		end
		Maid[Name] = nil
	end
end

------------------ Tribe Library
local Tribe = {}

function Tribe:Create(Name)
	Tribes.CreateTribe:InvokeServer(Name)
end

function Tribe:Join(Name)
	Tribes.JoinTribe:FireServer(Name)
end

function Tribe:Leave()
	Tribes.LeaveTribe:FireServer()
end

function Tribe:Kick(Player)
	Tribes.KickPlayer:FireServer(Player)
end

function Tribe:ToggleInviteOnly()
	Tribes.ToggleInviteOnly:FireServer()
end

------------------ Tool Library
local Tool = {}

function Tool:GetCurrent()
	local Char = LocalPlayer.Character
	if not Char then return end

	local Tool = Char:FindFirstChildOfClass("Tool")
	if not Tool then return end

	return Tool
end

function Tool:Unequip()
	local Char = LocalPlayer.Character
	if not Char then return end
	
	local Backpack = LocalPlayer.Backpack
	if not Backpack then return end
	
	for _, Tool in Char:GetChildren() do
		if Tool.ClassName ~= "Tool" then return end
		Tool.Parent = Backpack
	end
end

function Tool:Swing()
	local Char = LocalPlayer.Character
	if not Char then return end

	local Hum = Char:FindFirstChildOfClass("Humanoid")
	if not Hum or Hum.Health <= 0 then return end
	
	local Tool = Tool:GetCurrent()
	if not Tool then return end

	local TS = Tool:FindFirstChild("ToolScripts")
	if not TS then return end

	local Remote = TS:FindFirstChild("MobileSwing")
	if not Remote then return end

	Remote:Fire()
end

local ToolHolder = {}
function Tool:Save(Name)
	local Tool = Tool:GetCurrent()
	if not Tool then return end
	
	if not ToolHolder[Name] then ToolHolder[Name] = {} end
	table.insert(ToolHolder[Name], Tool)
end

function Tool:Load(Name)
	if not ToolHolder[Name] then return end

	local Char = LocalPlayer.Character
	if not Char then return end

	local Backpack = LocalPlayer.Backpack
	if not Backpack then return end

	Tool:Unequip()
	for _, Tool in ToolHolder[Name] do
		if Tool and (Tool.Parent == Backpack or Tool.Parent == Char) then
			Tool.Parent = Char
		end
	end
	ToolHolder[Name] = nil
end

local MultiSwinging = false
local Healing = false

function Tool:Heal()
	if Healing then return end
	
	local Heal = GetHeal()
	if not Heal then return end

	local Stats = Heal:FindFirstChild("Stats")
	if not Stats then return end

	local Price = Stats:GetAttribute("FoodCost")
	if not Price then return end

	local Char = LocalPlayer.Character
	if not Char then return end

	local Resources = Char:FindFirstChild("Resources")
	if not Resources then return end

	local Food = Resources:GetAttribute("Food")
	if not Food then return end
	
	local FS = Heal:FindFirstChild("FoodScripts")
	if not FS then return end

	local Remote = FS:FindFirstChild("Eat")
	if not Remote then return end
	
	if Food >= Price then
		task.spawn(function()
			Healing = true
			Tool:Save("Heal")
			Tool:Unequip()
		end)
		wait()
		Heal.Parent = Char
		wait()
		task.spawn(function()
			Remote:FireServer()
		end)
		wait()
		task.spawn(function()
			Tool:Unequip()
			wait()
			Tool:Load("Heal")
		end)
		wait()
		Healing = false
	end
end

function Tool:MultiSwing()
	task.spawn(function()
		if MultiSwinging then return end

		local Char = LocalPlayer.Character
		if not Char then return end

		local Backpack = LocalPlayer.Backpack
		if not Backpack then return end

		local Hum = Char:FindFirstChildOfClass("Humanoid")
		if not Hum or Hum.Health <= 0 then return end

		local Weapons = GetWeapons()
		if not Weapons then return end

		if #Weapons == 1 then
			Tool:Swing()
			return
		end

		MultiSwinging = true

		for _, Weapon in Weapons do
			if Healing then repeat wait() until not Healing end
			if not Weapon or not Weapon.Parent then return end
			if Weapon.Parent == Backpack then
				Weapon.Parent = Char
			end
			Weapon.ToolScripts.MobileSwing:Fire()
			wait()
			if Weapon and Weapon.Parent then Weapon.Parent = LocalPlayer.Backpack end
		end

		MultiSwinging = false
	end)
end

------------------ Player Library
local Player = {}

function Player:Respawn()
	Remotes.Respawn:FireServer()
end

function Player:GetStat(Name)
	return LocalPlayer:GetAttribute(Name)
end

function Player:InWater()
	local Root = GetRoot()
	if not Root then return end

	local Hitbox = Instance.new("Part")
	Hitbox.Parent = workspace
	Hitbox.CFrame = Root.CFrame
	Hitbox.Size = Vector3.new(0.01, 8, 0.01)

	local PartList = Hitbox:GetTouchingParts()
	Hitbox:Destroy()

	for _, Part in PartList do
		if Part.Parent == BlockTerrain and Part.Name == "River" then
			return true
		end
	end
end

function Player:GetSpeed()
	local Speed = 17

	local Char = LocalPlayer.Character
	if not Char then return end
	
	local Tool = Tool:GetCurrent()
	if not Tool then return end
	
	local Stats = Tool:FindFirstChild("Stats")
	if Stats then
		local WalkspeedStat = Stats:GetAttribute("WalkSpeed")
		if WalkspeedStat then
			Speed = WalkspeedStat
		end
	end	

	local Hat = Char:FindFirstChild("Hat")
	if Hat then
		local Stats = Hat:FindFirstChild("Stats")
		if Stats then
			local WalkspeedStat = Hat:GetAttribute("WalkSpeed")
			if WalkspeedStat then
				Speed += WalkspeedStat
			end
		end	
	end

	return Speed
end

------------------ Hat Library
local Hat = {}

function Hat:OpenCrate()
	if Player:GetStat("Money") >= 100000 then
		Hats.BuyHatCrate:InvokeServer()
	end
end

function Hat:Equip(Name)
	Hats.EquipHat:FireServer(Name)
end

------------------ Arrow Library
local Arrow = {}

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

local function GetDistanceColor(Obj1, Obj2, Max)
	local Distance = (Obj1.Position - Obj2.Position).Magnitude
	local Limited = math.clamp(Distance / Max, 0, 1)
	return Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), 1 - Limited)
end

------------------ Main
local ArrowCache = {}
Relief.addModule("Render", "PlayerESP", function(Toggled)
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
					local Color = GetDistanceColor(Root, tRoot, 500)
					Frame.BackgroundColor3 = Color
					local Hum = GetHumanoid(Target)
					if Hum and Hum.Health > 0 then
						Arrow.Show()
					else
						Arrow.Hide()
					end
				end)
				ArrowCache[#ArrowCache + 1] = Arrow
			end

			OnCharacter(Target.Character)
			Maid:Tag("PlayerESP", Target.CharacterAdded:Connect(OnCharacter))
		end

        for _, Target in GetOthers() do Handle(Target) end
		Maid:Tag("PlayerESP", Players.PlayerAdded:Connect(Handle))
	else
		for _, Arrow in ArrowCache do
			Arrow.Delete()
		end
		Maid:Disconnect("PlayerESP")
    end
end)

local Multi = false
Relief.addModule("Combat", "AutoSwing", function(Toggled)
	if Toggled then
		Tool:Save("AutoSwing")
		Threads:New("AutoSwing", function()
			if Multi then
				Tool:MultiSwing()
				repeat task.wait() until not MultiSwinging
			else
				Tool:Swing()
			end
		end)
	else
		Threads:Stop("AutoSwing")
		if MultiSwinging then
			repeat task.wait() until not MultiSwinging
			Tool:Load("AutoSwing")
		end
	end
end, {
	{
        ["Type"] = "Toggle",
        ["Title"] = "MultiSwing",
        ["Callback"] = function(Toggled)
            Multi = Toggled
			if not Toggled then
				repeat task.wait() until not MultiSwinging
				Tool:Load("AutoSwing")
			end
        end,
    },
})

local SCD = false
local OldHat
local WaterSpeed = false
local Snorkling = false
Relief.addModule("Movement", "Speed", function(Toggled)
	if Toggled then
		Threads:New("Speed", function()
			local Hum = GetHumanoid()
			if not Hum then return end

			local Speed = Player:GetSpeed()
			if not Speed then return end

			local InWater = Player:InWater()
			if InWater and WaterSpeed then
				if Snorkeling then
					local CurrentHat = Player:GetStat("EquippedHat")
					if not SCD and not OldHat and CurrentHat ~= "Snorkeling Gear" then
						OldHat = CurrentHat
						Hat:Equip("Snorkeling Gear")
						SCD = true
						task.spawn(function()
							task.wait(1)
							SCD = false
						end)
					end
					Hum.WalkSpeed = Speed + 22
					return
				end
				Hum.WalkSpeed = Speed + 10
			else
				if OldHat then
					task.spawn(function()
						local Archive = OldHat
						OldHat = nil
						task.wait(1)
						Hat:Equip(Archive)
					end)
				end
				Hum.WalkSpeed = Speed + 3
			end
		end)
	else
		Threads:Stop("Speed")
	end
end, {
	{
		["Type"] = "Toggle",
		["Title"] = "Water Speed",
		["Callback"] = function(Toggled)
			WaterSpeed = Toggled
		end
	},
	{
		["Type"] = "Toggle",
		["Title"] = "Snorkeling",
		["Callback"] = function(Toggled)
			Snorkeling = Toggled
		end
	}
})

local OldVelocity = {}
Relief.addModule("Movement", "Jesus", function(Toggled)
	if Toggled then
		for _, River in BlockTerrain:GetChildren() do
			if River.Name == "River" then
				table.insert(OldVelocity, {River, River.Velocity})
				River.Velocity = Vector3.zero
			end
		end
	else
		for _, Data in OldVelocity do
			local River, Velocity = Data[1], Data[2]
			River.Velocity = Velocity
		end
	end
end)

Relief.addModule("Utility", "Anonymous", function(Toggled)
	if Toggled then
		Tribe:Leave()
		Tribe:Create("\n\n\n" .. RandomString(6))
	else
		Tribe:Leave()
	end
end)

local Prefix = "Relief | "
Relief.addModule("Utility", "TribeSpam", function(Toggled)
	if Toggled then
		Tribe:Leave()
		Threads:New("TribeSpam", function()
			Tribe:Create(Prefix .. RandomString(6))
			Tribe:Kick(LocalPlayer)
			Tribe:Leave()
			wait()
		end)
	else
		local Found = Threads:Get("TribeSpam")
		if Found then
			Found:Disconnect()
		end
	end
end)

Relief.addModule("Utility", "AutoCrate", function(Toggled)
	if Toggled then
		Threads:New("AutoCrate", function()
			Hat:OpenCrate()
		end)
	else
		Threads:Stop("AutoCrate")
	end
end)

Relief.addModule("Combat", "AutoHeal", function(Toggled)
	if Toggled then
		Threads:New("AutoHeal", function()
			local Hum = GetHumanoid()
			if not Hum or Hum.Health > (Hum.MaxHealth - 10) then return end

			Tool:Heal()
			repeat task.wait() until not Healing
		end)
	else
		Threads:Stop("AutoHeal")
	end
end)

local NoclipCache = {}
Relief.addModule("Movement", "Noclip", function(Toggled)
	if Toggled then
		local Character = LocalPlayer.Character
		if not Character then return end

		for _, BodyPart in Character:GetChildren() do
			if BodyPart:IsA("BasePart") then
				table.insert(NoclipCache, {BodyPart, BodyPart.CanCollide})
			end
		end

		Maid:Tag("Noclip", RunService.Stepped:Connect(function()
			local Character = LocalPlayer.Character
			if not Character then return end

			for _, BodyPart in Character:GetChildren() do
				if BodyPart:IsA("BasePart") then
					BodyPart.CanCollide = false
				end
			end
		end))
	else
		Maid:Disconnect("Noclip")
		for _, Data in NoclipCache do
			local BodyPart, Collides = Data[1], Data[2]
			BodyPart.CanCollide = Collides
			print(Data)
		end
	end
end)

local CactusCache = {}
Relief.addModule("World", "AntiCactus", function(Toggled)
	if Toggled then
		for _, Cactus in Resources:GetChildren() do
			if Cactus.Name == "Tree" and Cactus:FindFirstChild("cactus") then
				local Barrier = Block(Cactus)
				table.insert(CactusCache, Barrier)
			end
		end
	else
		for _, Cactus in CactusCache do
			Cactus:Destroy()
		end
		CactusCache = {}
	end
end)

local SpikeCache = {}
Relief.addModule("World", "AntiSpike", function(Toggled)
	if Toggled then
		local function Validate(Spike)
			if Spike.Name == "Spikes" or Spike.Name == "Super Spikes" or Spike.Name == "Poisoned Spikes" or Spike.Name == "Spike Trap" then
				local Barrier = Block(Spike)
				table.insert(SpikeCache, Barrier)
			end
		end

		for _, Spike in Structures:GetChildren() do
			Validate(Spike)
		end

		Maid:Tag("AntiSpike", Structures.ChildAdded:Connect(Validate))
	else
		for _, Spike in SpikeCache do
			Spike:Destroy()
		end
		SpikeCache = {}
		Maid:Disconnect("AntiSpike")
	end
end)

local Baseplate = workspace.Baseplate
Relief.addModule("World", "AntiLag", function(Toggled)
	if Toggled then
		Details.Parent = RStorage
		Baseplate.Parent = RStorage
	else
		Details.Parent = workspace
		Baseplate.Parent = workspace
	end
end)

local TargetFOV = 90
local DefaultFOV = Camera.FieldOfView
Relief.addModule("Render", "FOV", function(Toggled)
	if Toggled then
		DefaultFOV = Camera.FieldOfView
		Camera.FieldOfView = TargetFOV
		Maid:Tag("FOV", Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
			if Camera.FieldOfView ~= TargetFOV then
				Camera.FieldOfView = TargetFOV
			end
		end))
	else
		Maid:Disconnect("FOV")
		Camera.FieldOfView = DefaultFOV
	end
end, {
    {
        ["Type"] = "TextBox",
        ["Title"] = "FOV Amount",
        ["Placeholder"] = "FOV Here (90 Default)",
        ["Callback"] = function(Text)
            local Amount = tonumber(Text) or 90
			TargetFOV = Amount
			Camera.FieldOfView = TargetFOV
        end,
    }
})

Relief.addModule("Utility", "AutoRespawn", function(Toggled)
	if Toggled then
		Threads:New("AutoRespawn", function()
			Player:Respawn()
		end)
	else
		Threads:Stop("AutoRespawn")
	end
end)

local function GetNearestPlayer()
	local Root = GetRoot()
	if not Root then return end 

	local Data = {nil, nil}
	for _, Target in GetOthers() do
		local TRoot = GetRoot(Target)
		if not TRoot then continue end

		local Distance = (Root.Position - TRoot.Position).Magnitude
		local CurrentDistance = Data[2]

		if CurrentDistance then
			if Distance < CurrentDistance then
				Data = {Target, Distance}
			end
		else
			Data = {Target, Distance}
		end
	end

	return Data
end

local Range = 8
local TargetHat = ""

local IgnoreTeam = false
local HatSwap = false
local TPAura = false

Relief.addModule("Combat", "KillAura", function(Toggled)
	if Toggled then
		local OldWeapon = nil
		local OldHat = nil
		local Attacking = false

		local function Start()
			if not Attacking then
				OldWeapon = Tool:GetCurrent()
				if HatSwap then
					OldHat = Player:GetStat("EquippedHat")
					Hat:Equip(TargetHat) 
				end
			end
			Attacking = true
		end

		local function Stop()
			if Attacking then
				repeat wait() until not MultiSwinging
				if OldWeapon then
					wait()
					Tool:Unequip()
					OldWeapon.Parent = LocalPlayer.Character
				end
				if HatSwap and OldHat then
					wait()
					task.spawn(function()
						local Archive = OldHat
						task.wait(1)
						Hat:Equip(Archive)
					end)
				end
				OldHat = nil
				OldWeapon = nil
			end
			Attacking = false
		end

		Threads:New("KillAura", function()
			local Root = GetRoot()
			if not Root then Attacking = false return end

			local Data = GetNearestPlayer()
			local Target = Data[1]
			if not Data or not Target then Stop() return end

			local Tutorial = Target.Character:GetAttribute("InTutorial")
			if Tutorial then Stop() return end

			local Distance = Data[2]
			if Distance > Range then Stop() return end

			local TRoot = GetRoot(Target)
			if not TRoot then Stop() return end

			local THum = GetHumanoid(Target)
			if not THum or THum.Health <= 0 then Stop() return end
			if IgnoreTeam and LocalPlayer.Team and Target.Team == LocalPlayer.Team then return end

			Start()
			if TPAura then
				Root.CFrame = TRoot.CFrame * CFrame.new(0, 0, 3)
			end
			Root.CFrame = CFrame.lookAt(Root.Position, TRoot.Position)
			Tool:MultiSwing()

			for _, BP in LocalPlayer.Character:GetChildren() do
				if BP:IsA("BasePart") then
					BP.Velocity, BP.RotVelocity = Vector3.zero, Vector3.zero
				end
			end
		end)
	else
		Threads:Stop("KillAura")
	end
end, {

	{
		["Type"] = "Toggle",
		["Title"] = "Hat Swap",
		["Callback"] = function(Toggled)
			HatSwap = Toggled
		end
	},
	{
		["Type"] = "Toggle",
		["Title"] = "Team Check",
		["Callback"] = function(Toggled)
			IgnoreTeam = Toggled
		end
	},
	{
		["Type"] = "Toggle",
		["Title"] = "TP Aura",
		["Callback"] = function(Toggled)
			TPAura = Toggled
		end
	},

	{
        ["Type"] = "TextBox",
        ["Title"] = "Target Hat",
        ["Placeholder"] = "Hat Name Here",
        ["Callback"] = function(Text)
            TargetHat = Text
        end,
    },
	{
        ["Type"] = "TextBox",
        ["Title"] = "Attack Range",
        ["Placeholder"] = "Range Here (Default 8)",
        ["Callback"] = function(Text)
            local Amount = tonumber(Text) or 8
			Range = Amount
        end,
    },

})

local TreasureCache = {}
Relief.addModule("Render", "TreasureESP", function(Toggled)
	if Toggled then
		local function Handle(Obj)
			if Obj.Name == "Treasure" then
				local tRoot = Obj:FindFirstChild("HumanoidRootPart")
				if not tRoot then return end

				local Arrow = Arrow.new(tRoot)
				Arrow.SetText("Treasure")
				Arrow.SetCallback(function(Frame)
					local Root = LocalPlayer.Character.HumanoidRootPart
					local Color = GetDistanceColor(Root, tRoot, 500)
					Frame.BackgroundColor3 = Color
				end)
				table.insert(TreasureCache, Arrow)
			end
		end

		for _, Treasure in Resources:GetChildren() do Handle(Treasure) end
		Maid:Tag("TreasureESP", Resources.ChildAdded:Connect(Handle))
	else
		Maid:Disconnect("TreasureESP")
		for _, Arr in TreasureCache do
			Arr.Delete()
		end
	end
end)

Relief.addModule("Render", "ModuleList", function(Toggled)
    Relief.ModuleList.Visible = Toggled
end, {}, nil, true)

Relief.addModule("Render", "MobileButton", function(Toggled)
    Relief.MobileButton.Visible = Toggled
end, {}, nil, true)

Relief.addModule("Utility", "KillScript", function(Toggled)
    Relief.KillScript()
end)
