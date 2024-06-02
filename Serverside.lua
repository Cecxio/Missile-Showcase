local speed = 70

local function cubic_bez(t, p0, p1, p2, p3)
	local t = t * t
	return ((1 - t)^3) * p0 + 3 * ((1-t)^2) * t * p1 + 3*(1 - t)* (t^2) * p2 + (t^3) * p3
end

local can_rotate = true

script.Parent.Rotation.OnServerEvent:Connect(function(player, cframe : CFrame)
	if can_rotate == false then
		return
	end
	
	local direction = -(cframe.Position - script.Parent.Stand.Position).Unit
	
	local new_cframe = CFrame.new(script.Parent.Stand.Position, script.Parent.Stand.Position + Vector3.new(direction.X, 0, direction.Z))
	local playerpos = CFrame.new(script.Parent.Stand.Position + Vector3.new(0, 3, 0), script.Parent.Circle.Position + Vector3.new(direction.X, 0, direction.Z)) * CFrame.new(0, 0, 2)
	
	player.Character.PrimaryPart.Anchored = true
	script.Parent:SetPrimaryPartCFrame(new_cframe)
	player.Character:SetPrimaryPartCFrame(playerpos)
end)

script.Parent.Control.OnServerEvent:Connect(function(player, onoff)
	if onoff == "On" then
		script.Parent.Controller.Value = player.Name
		script.Parent.Stand.ProximityPrompt.Enabled = false
	else
		script.Parent.Controller.Value = "None"
		script.Parent.Stand.ProximityPrompt.Enabled = true
	end
end)

local function eject()
	script.Parent.Rotation:FireClient(game.Players:FindFirstChild(script.Parent.Controller.Value))
	game.Players:FindFirstChild(script.Parent.Controller.Value).Character.HumanoidRootPart.Anchored = false
	
	script.Parent.Stand.ProximityPrompt.Enabled = true
	script.Parent.Controller.Value = "None"
end

local function calculate_damage_within_radius(position)
	for _, player in game.Players:GetChildren() do
		if player.Character then
			if (player.Character.PrimaryPart.Position - position).Magnitude <= 10 then
				
				player.Character.Humanoid.Health -= 80
				
			end
		end
	end
end

script.Parent.Reload.OnServerEvent:Connect(function()
	script.Parent.Reloading.Value = true
	script.Parent.Stand.ProximityPrompt.Enabled = false
	
	for i = 1, 6 do
		local Rocket = game.ServerStorage.ReloadRocket:Clone()
		
		Rocket.Transparency = 1
		Rocket.CFrame = script.Parent:FindFirstChild("Launcher_" .. i).CFrame * CFrame.new(0, -0.7, 2)
		Rocket.Parent = script.Parent
		Rocket.Name = "Rocket_" .. i
		
		game:GetService("TweenService"):Create(
			Rocket,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine),
			{Transparency = 0, CFrame = script.Parent:FindFirstChild("Launcher_" .. i).CFrame}
		):Play()	
		
		wait(1)
	end
	
	script.Parent.Reloading.Value = false
	script.Parent.Stand.ProximityPrompt.ActionText = "Use"
	script.Parent.Stand.ProximityPrompt.Enabled = true
end)


script.Parent.Fire.OnServerEvent:Connect(function(player, p1, p2, mag)	
	local connected, totime, total, t
	local rocket_ttime = {}
	local begin_position = {}
	local end_position = {}
	local nn_val = math.random(-100000, 100000)
	
	totime = mag / speed
	total = totime	
	
	local function run(dt, rocket_id)
		local rtotime = rocket_ttime["Rocket" .. rocket_id] - dt
		rocket_ttime["Rocket" .. rocket_id] = rtotime
		t = 1 - (rtotime / total)
		
		if rtotime < 0 then
			return false
		end
		
		game.Workspace:FindFirstChild("Rocket_" .. rocket_id).CFrame = CFrame.new(
			cubic_bez(
				t,
				begin_position["Rocket" .. rocket_id],
				script.Parent.Tip.Position + (script.Parent.Tip.CFrame.LookVector * (begin_position["Rocket" .. rocket_id] - end_position["Rocket" .. rocket_id]).Magnitude / 2),
				p1,
				end_position["Rocket" .. rocket_id]) :: Vector3, 
			
			cubic_bez(
				math.min(t + 0.3, 1),
				begin_position["Rocket" .. rocket_id],
				script.Parent.Tip.Position + (script.Parent.Tip.CFrame.LookVector * (begin_position["Rocket" .. rocket_id] - end_position["Rocket" .. rocket_id]).Magnitude / 2),
				p1,
			end_position["Rocket" .. rocket_id]) :: Vector3
		) * CFrame.Angles(math.rad(-12), 0, 0)

		return true
	end
	
	local val = nil
	
	for i = 1, 6 do
		if script.Parent:FindFirstChild("Rocket_" .. i) then
			val = i
			break
		end
	end
	
	if val == nil then
		return
	end
	
	rocket_ttime["Rocket" .. nn_val] = totime
	begin_position["Rocket" .. nn_val] = script.Parent:FindFirstChild("Rocket_" .. val).Position
	
	local endpos = p2 + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
	
	while true do
		if (endpos - p2).Magnitude <= 20 then
			break
		end
		endpos = p2 + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
	end
	
	end_position["Rocket" .. nn_val] = endpos


	spawn(function()
		local connection
		can_rotate = false
		
		script.Parent:FindFirstChild("Rocket_" .. val).Name = "Rocket_" .. nn_val
		val = nn_val
		script.Parent:FindFirstChild("Rocket_" .. val).Parent = workspace
		
		wait(0.1)

		local LaunchSound = script.Parent.Launch:Clone()

		LaunchSound.Parent = game.Workspace:FindFirstChild("Rocket_" .. val)
		LaunchSound:Play()

		game:GetService("Debris"):AddItem(LaunchSound, 6)
		game.Workspace:FindFirstChild("Rocket_" .. val).Attachment.ParticleEmitter.Enabled = true

		wait(0.25)

		connection = game:GetService("RunService").Heartbeat:Connect(function(dt)				
			local run_result = run(dt, val)
			if run_result == false then
				connection:Disconnect()
				
				local ExplosionSound = script.Parent.Explosion:Clone()

				ExplosionSound.Parent = game.Workspace:FindFirstChild("Rocket_" .. val)
				ExplosionSound:Play()

				calculate_damage_within_radius(game.Workspace:FindFirstChild("Rocket_" .. val).Position)

				game.Workspace:FindFirstChild("Rocket_" .. val).Smoke:Emit(10)
				game:GetService("Debris"):AddItem(ExplosionSound, 5)
				game:GetService("TweenService"):Create(game.Workspace:FindFirstChild("Rocket_" .. val), TweenInfo.new(0.5), {Transparency = 1}):Play()
				game:GetService("Debris"):AddItem(game.Workspace:FindFirstChild("Rocket_" .. val), 10)
			end
		end)

		game.Workspace:FindFirstChild("Rocket_" .. val).Attachment.ParticleEmitter.Enabled = false
		
		local nval = nil

		for i = 1, 6 do
			if script.Parent:FindFirstChild("Rocket_" .. i) then
				nval = i
				break
			end
		end

		if nval == nil then
			eject()
			script.Parent.Stand.ProximityPrompt.ActionText = "Reload"
		end

		wait(2)
		
		can_rotate = true
	end)	
end)
