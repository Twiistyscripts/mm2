local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local SEARCH_INTERVAL = 0.25
local PLATFORM_SIZE = Vector3.new(6, 1, 6)
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

-- Fast coin check using attribute and transparency
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

-- Move platforms instantly
local function movePlatforms(bottomPlatform, topPlatform, targetPos)
    bottomPlatform.Position = Vector3.new(targetPos.X, targetPos.Y - UNDER_OFFSET, targetPos.Z)
    topPlatform.Position = Vector3.new(targetPos.X, targetPos.Y + HEAD_OFFSET, targetPos.Z)
end

-- Position player between platforms
local function positionPlayer(character, bottomPlatform)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(bottomPlatform.Position + Vector3.new(0, UNDER_OFFSET/2, 0))
    end
end

-- Wait until player respawns
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
            -- Move platforms to coin location
            movePlatforms(bottomPlatform, topPlatform, coin.Position)
            positionPlayer(character, bottomPlatform)
        else
            -- No valid coins found, move to void
            movePlatforms(bottomPlatform, topPlatform, Vector3.new(0, -1000, 0))
            positionPlayer(character, bottomPlatform)
        end
        task.wait(SEARCH_INTERVAL)
    end
end

task.spawn(autoFarm)
