local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local SEARCH_INTERVAL = 0.25
local PLATFORM_SIZE = Vector3.new(6, 1, 6)
local MOVE_TIME = 0.35
local UNDER_OFFSET = 10
local HEAD_OFFSET = 3

-- Create platforms
local function createPlatforms()
    local bottomPlatform = Instance.new("Part")
    bottomPlatform.Size = PLATFORM_SIZE
    bottomPlatform.Anchored = true
    bottomPlatform.CanCollide = true
    bottomPlatform.Transparency = 0.2
    bottomPlatform.Material = Enum.Material.ForceField
    bottomPlatform.Color = Color3.fromRGB(255, 150, 0)
    bottomPlatform.Name = "AutoFarmBottomPlatform"
    
    local topPlatform = bottomPlatform:Clone()
    topPlatform.Name = "AutoFarmTopPlatform"
    topPlatform.Transparency = 0.5
    topPlatform.Color = Color3.fromRGB(0, 150, 255)
    
    bottomPlatform.Parent = Workspace
    topPlatform.Parent = Workspace
    
    return bottomPlatform, topPlatform
end

-- Get all valid coins
local function getAllCoins()
    local coins = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Coin_Server" and obj:IsA("BasePart") then
            local collected = obj:GetAttribute("Collected")
            if collected ~= true and obj.Transparency < 1 then
                table.insert(coins, obj)
            end
        end
    end
    return coins
end

-- Find closest valid coin
local function getClosestCoin(position)
    local coins = getAllCoins()
    local closest, dist = nil, math.huge
    for _, coin in ipairs(coins) do
        local d = (coin.Position - position).Magnitude
        if d < dist then
            closest = coin
            dist = d
        end
    end
    return closest
end

-- Move platforms together
local function movePlatforms(bottomPlatform, topPlatform, targetPos)
    local underMapPos = Vector3.new(targetPos.X, targetPos.Y - UNDER_OFFSET, targetPos.Z)
    local topPos = Vector3.new(targetPos.X, targetPos.Y + HEAD_OFFSET, targetPos.Z)
    
    local bottomTween = TweenService:Create(bottomPlatform, TweenInfo.new(MOVE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = underMapPos})
    local topTween = TweenService:Create(topPlatform, TweenInfo.new(MOVE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = topPos})
    
    bottomTween:Play()
    topTween:Play()
    
    bottomTween.Completed:Wait()
end

-- Position player between platforms
local function positionPlayer(character, bottomPlatform, topPlatform)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local middleY = (bottomPlatform.Position.Y + topPlatform.Position.Y) / 2
    hrp.CFrame = CFrame.new(Vector3.new(bottomPlatform.Position.X, middleY, bottomPlatform.Position.Z))
end

-- Wait until player respawns
local function waitForRespawn()
    repeat task.wait(0.2) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    return LocalPlayer.Character
end

-- Main farming loop
local function autoFarm()
    local bottomPlatform = Workspace:FindFirstChild("AutoFarmBottomPlatform") 
    local topPlatform = Workspace:FindFirstChild("AutoFarmTopPlatform")
    
    if not bottomPlatform or not topPlatform then
        bottomPlatform, topPlatform = createPlatforms()
    end

    while true do
        local character = LocalPlayer.Character or waitForRespawn()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            character = waitForRespawn()
            hrp = character:WaitForChild("HumanoidRootPart")
        end

        local coin = getClosestCoin(hrp.Position)
        if coin then
            -- Move platforms to coin location
            movePlatforms(bottomPlatform, topPlatform, coin.Position)
            
            -- Position player between platforms
            positionPlayer(character, bottomPlatform, topPlatform)
            
            task.wait(SEARCH_INTERVAL)
        else
            -- No coins found, move to void
            local voidPos = Vector3.new(0, -1000, 0)
            movePlatforms(bottomPlatform, topPlatform, voidPos)
            positionPlayer(character, bottomPlatform, topPlatform)
            task.wait(0.5)
        end
    end
end

task.spawn(autoFarm)
