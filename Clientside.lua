local minimum_distance = 100
local maximum_distance = 300
local detail = 10
local spread = 50


task.wait(3)

local db = false
local connected, p1, p2, rotation_connection, mouse_func
local mouse = game.Players.LocalPlayer:GetMouse()
local PointsFolder = Instance.new("Folder", workspace)
local segments = {}

PointsFolder.Parent = workspace
PointsFolder.Name = "PointsFolder"

local function quad_bez(t, p0, p1, p2)
	return ((1 - t)^2) * p0 + 2 * (1 - t) * t * p1 + (t^2) * p2
end

script.Parent.Stand.ProximityPrompt.TriggerEnded:Connect(function()
	if script.Parent.Stand.ProximityPrompt.ActionText == "Reload" then
		script.Parent.Reload:FireServer()
		return
	end
	
	if script.Parent.Controller.Value ~= "None" or script.Parent.Reloading == true then
		return
	else
		script.Parent.Control:FireServer("On")
	end
	
	local Angle
	
	local function update_camera()
		script.Parent.Rotation:FireServer(game.Workspace.CurrentCamera.CFrame)
	end
	
	local function rebuild(dt)
		for _, point in PointsFolder:GetChildren() do
			point:Destroy()
		end

		

		for i=0, detail do
			local t = i / detail
			local position = quad_bez(t, script.Parent.Tip.Position, ((script.Parent.Tip.Position + mouse.Hit.p) / 2) + Vector3.new(0, math.sqrt((mouse.Hit.p - script.Parent.Tip.Position).Magnitude)*1.5, 0), mouse.Hit.p)
		
			p1 = ((script.Parent.Tip.Position + mouse.Hit.p) / 2) + Vector3.new(0, math.sqrt((mouse.Hit.p - script.Parent.Tip.Position).Magnitude), 0)
			p2 = mouse.Hit.p
			
			if (mouse.Hit.p - script.Parent.Tip.Position).Magnitude < minimum_distance then
				position = script.Parent.Tip.Position + ((mouse.hit.p - script.Parent.Tip.Position).Unit * minimum_distance)
				position = Vector3.new(position.X, mouse.Hit.p.Y, position.Z)
				position = quad_bez(t, script.Parent.Tip.Position, ((script.Parent.Tip.Position + position) / 2) + Vector3.new(0, math.sqrt((position - script.Parent.Tip.Position).Magnitude)*1.5, 0), position)
				
				p1 = ((script.Parent.Tip.Position + position) / 2) + Vector3.new(0, math.sqrt((position - script.Parent.Tip.Position).Magnitude), 0)
				p2 = position
			elseif (mouse.Hit.p - script.Parent.Tip.Position).Magnitude > maximum_distance then
				position = script.Parent.Tip.Position + ((mouse.hit.p - script.Parent.Tip.Position).Unit * 300)
				position = Vector3.new(position.X, mouse.Hit.p.Y, position.Z)
				position = quad_bez(t, script.Parent.Tip.Position, ((script.Parent.Tip.Position + position) / 2) + Vector3.new(0, math.sqrt((position - script.Parent.Tip.Position).Magnitude)*1.5, 0), position)
				
				p1 = ((script.Parent.Tip.Position + position) / 2) + Vector3.new(0, math.sqrt((position - script.Parent.Tip.Position).Magnitude)*1.5, 0)
				p2 = position
			end

			local part = Instance.new("Part")
			part.Size = Vector3.new(2 - (0.19 * i), 2 - (0.19 * i), 2 - (0.19 * i))
			part.Color = Color3.new(0, 1, 0)
			part.Material = Enum.Material.Neon
			part.CanCollide = false
			part.Anchored = true
			part.Position = position
			part.Parent = PointsFolder
			part.Transparency = 0.5
			
			if i == 0 then
				part.Transparency = 1
			end
			
			segments["Part" .. i] = part
		end

		
		local rangePart = Instance.new("Part")
		rangePart.Size = Vector3.new(1, 40, 40)
		rangePart.Shape = Enum.PartType.Cylinder
		rangePart.Color = Color3.new(0, 1, 0)
		rangePart.Material = Enum.Material.Neon
		rangePart.CanCollide = false
		rangePart.Anchored = true
		rangePart.Position = segments["Part" .. detail].Position
		rangePart.Orientation = Vector3.new(0, 90, 90)
		rangePart.Transparency = 0.5
		rangePart.Parent = PointsFolder
		
		local Point_A = script.Parent.Tip.Position + Vector3.new((script.Parent.Tip.CFrame.LookVector * (segments["Part" .. detail].Position - script.Parent.Tip.Position).Magnitude).X, 0, (script.Parent.Tip.CFrame.LookVector * (segments["Part" .. detail].Position - script.Parent.Tip.Position).Magnitude).Z)
		local Point_B = script.Parent.Tip.Position
		local Point_C = p2
		
		local Vector_AB = Point_B - Point_A
		local Vector_BC = Point_C - Point_B
		
		local DotProduct = Vector_AB:Dot(Vector_BC)
		local Mag_1 = Vector_AB.Magnitude
		local Mag_2 = Vector_BC.Magnitude
		
		Angle = DotProduct / (Mag_1 * Mag_2)
		
		Angle = math.deg(math.acos(Angle))
		
		
		
		if (segments["Part" .. detail].Position - script.Parent.Tip.Position).Magnitude < minimum_distance - 1 or Angle < 180 - (spread / 2) then
			for _, segment in segments do
				segment.Color = Color3.new(1, 0, 0)
			end
			rangePart.Color = Color3.new(1, 0, 0)			
		end
	end
	
	mouse_func = mouse.Button1Down:Connect(function()
		if (segments["Part" .. detail].Position - script.Parent.Tip.Position).Magnitude >= minimum_distance - 1 and Angle >= 180 - (spread / 2) and db == false then
			db = true

			script.Parent.Fire:FireServer(p1, p2, (script.Parent.Tip.Position - p2).Magnitude)
			
			wait(0.5)
			
			db = false
		end
	end)
	
	script.Parent.Fire.OnClientEvent:Connect(function()
		connected = game:GetService("RunService").Heartbeat:Connect(rebuild)
	end)
	
	update_camera()

	rotation_connection = game.Workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Connect(update_camera)
	connected = game:GetService("RunService").Heartbeat:Connect(rebuild)
end)

script.Parent.Rotation.OnClientEvent:Connect(function()
	rotation_connection:Disconnect()
	connected:Disconnect()
	mouse_func:Disconnect()
	
	for _, point in PointsFolder:GetChildren() do
		point:Destroy()
	end
end)
