local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local SEARCH_INTERVAL = 0.1 -- Faster checking
local PLATFORM_SIZE = Vector3.new(6, 1, 6)
local UNDER_OFFSET = 3 -- Closer to coin bottom
local HEAD_OFFSET = 1.5 -- Better head positioning

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

-- Get valid coins
local function getAllCoins()
    local coins = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Coin_Server" and obj:IsA("BasePart") then
            if not obj:GetAttribute("Collected") and obj.Transparency < 1 then
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

-- Position platforms and player
local function positionForCoin(bottomPlatform, topPlatform, character, coin)
    -- Position platforms relative to coin
    local coinPos = coin.Position
    bottomPlatform.Position = Vector3.new(coinPos.X, coinPos.Y - UNDER_OFFSET, coinPos.Z)
    topPlatform.Position = Vector3.new(coinPos.X, coinPos.Y + HEAD_OFFSET, coinPos.Z)
    
    -- Position player's head at coin level
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if head and hrp then
        hrp.CFrame = CFrame.new(coinPos.X, coinPos.Y - 1.5, coinPos.Z) -- Head will be at coin level
    end
end

-- Wait for respawn
local function waitForRespawn()
    repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    return LocalPlayer.Character
end

-- Main farming loop
local function autoFarm()
    local bottomPlatform, topPlatform = createPlatforms()

    while true do
        local character = LocalPlayer.Character or waitForRespawn()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            character = waitForRespawn()
            hrp = character:WaitForChild("HumanoidRootPart")
        end

        local coin = getClosestCoin(hrp.Position)
        if coin then
            positionForCoin(bottomPlatform, topPlatform, character, coin)
        else
            -- No coins, move to void
            bottomPlatform.Position = Vector3.new(0, -1000, 0)
            topPlatform.Position = Vector3.new(0, -1000, 0)
            hrp.CFrame = CFrame.new(0, -1000, 0)
        end
        task.wait(SEARCH_INTERVAL)
    end
end

task.spawn(autoFarm)
