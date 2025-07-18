local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- SETTINGS
local SEARCH_INTERVAL = 0.5
local PLATFORM_SIZE = Vector3.new(6, 1, 6)
local MOVE_TIME = 0.75
local SAFE_VOID_POS = Vector3.new(0, -500, 0)

-- Create floating platform under player
local function createPlatform()
    local platform = Instance.new("Part")
    platform.Size = PLATFORM_SIZE
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 0.2
    platform.Material = Enum.Material.ForceField
    platform.Color = Color3.fromRGB(0, 200, 255)
    platform.Name = "AutoFarmPlatform"
    platform.Parent = Workspace
    return platform
end

local function getCharacter()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character
    end
    return nil
end

-- Find all Coin_Server objects anywhere in Workspace
local function getAllCoins()
    local coins = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Coin_Server" and obj:IsA("BasePart") then
            table.insert(coins, obj)
        end
    end
    return coins
end

-- Find closest Coin_Server to current position
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

-- Tween platform smoothly to target position
local function tweenPlatform(platform, targetPos)
    local goal = {Position = targetPos}
    local tween = TweenService:Create(platform, TweenInfo.new(MOVE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), goal)
    tween:Play()
    tween.Completed:Wait()
end

-- Make player head look at the coin
local function lookAtTarget(character, targetPos)
    local head = character:FindFirstChild("Head")
    if head then
        local dir = (targetPos - head.Position).Unit
        head.CFrame = CFrame.new(head.Position, head.Position + dir)
    end
end

-- Main farming loop
local function autoFarm()
    local platform = Workspace:FindFirstChild("AutoFarmPlatform") or createPlatform()

    while true do
        local char = getCharacter()
        if not char then
            -- Player is respawning
            repeat task.wait(0.5) until getCharacter()
            platform.Position = getCharacter():WaitForChild("HumanoidRootPart").Position - Vector3.new(0, 3, 0)
        end

        -- Search for closest coin
        local coin = getClosestCoin(platform.Position)
        if coin then
            local coinPos = coin.Position - Vector3.new(0, 4, 0)
            tweenPlatform(platform, coinPos)
            lookAtTarget(getCharacter(), coin.Position)

            -- Teleport player onto platform
            getCharacter():WaitForChild("HumanoidRootPart").CFrame = platform.CFrame + Vector3.new(0, 3, 0)
            task.wait(SEARCH_INTERVAL)
        else
            -- No coins left, go to safe void
            tweenPlatform(platform, SAFE_VOID_POS)

            -- Move player safely to void and reset
            getCharacter():WaitForChild("HumanoidRootPart").CFrame = CFrame.new(SAFE_VOID_POS + Vector3.new(0, 5, 0))
            task.wait(2)

            -- Force reset to respawn
            local humanoid = getCharacter():FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end

            -- Wait for respawn
            repeat task.wait(0.5) until getCharacter()

            -- Move platform back under new spawn
            platform.Position = getCharacter():WaitForChild("HumanoidRootPart").Position - Vector3.new(0, 3, 0)
            task.wait(1)
        end
    end
end

-- Start farming
task.spawn(autoFarm)
