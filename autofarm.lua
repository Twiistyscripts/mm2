local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- SETTINGS
local SEARCH_INTERVAL = 0.25 -- faster scanning
local PLATFORM_SIZE = Vector3.new(6, 1, 6)
local MOVE_TIME = 0.35 -- 2x faster tween
local UNDER_OFFSET = 10 -- go under the map slightly
local HEAD_OFFSET = 3 -- lift platform so player's head touches coin

-- Create platform under the map
local function createPlatform()
    local platform = Instance.new("Part")
    platform.Size = PLATFORM_SIZE
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 0.2
    platform.Material = Enum.Material.ForceField
    platform.Color = Color3.fromRGB(255, 150, 0)
    platform.Name = "AutoFarmPlatform"
    platform.Parent = Workspace
    return platform
end

-- Attach player smoothly to platform
local function attachPlayerToPlatform(character, platform)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = false
        local align = hrp:FindFirstChild("AlignPosition") or Instance.new("AlignPosition")
        align.Name = "AlignPosition"
        align.MaxForce = math.huge
        align.Responsiveness = 200
        align.Mode = Enum.PositionAlignmentMode.OneAttachment
        align.Attachment0 = hrp:FindFirstChild("Attachment") or Instance.new("Attachment", hrp)
        align.Attachment1 = platform:FindFirstChild("Attachment") or Instance.new("Attachment", platform)
        align.Parent = hrp
    end
end

-- Find all Coin_Server parts anywhere
local function getAllCoins()
    local coins = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Coin_Server" and obj:IsA("BasePart") then
            table.insert(coins, obj)
        end
    end
    return coins
end

-- Find closest coin
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

-- Tween platform under the map at target
local function tweenPlatform(platform, targetPos)
    -- move under the map but aligned horizontally
    local underMapPos = Vector3.new(targetPos.X, targetPos.Y - UNDER_OFFSET, targetPos.Z)
    local goal = {Position = underMapPos}
    local tween = TweenService:Create(platform, TweenInfo.new(MOVE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), goal)
    tween:Play()
    tween.Completed:Wait()
end

-- Make player head face coin
local function lookAtTarget(character, targetPos)
    local head = character:FindFirstChild("Head")
    if head then
        local dir = (targetPos - head.Position).Unit
        head.CFrame = CFrame.new(head.Position, head.Position + dir)
    end
end

-- Detect if player respawned
local function waitForRespawn()
    repeat task.wait(0.2) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    return LocalPlayer.Character
end

-- Main loop
local function autoFarm()
    local platform = Workspace:FindFirstChild("AutoFarmPlatform") or createPlatform()
    attachPlayerToPlatform(getClosestCoin() or LocalPlayer.Character, platform)
    
    while true do
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            char = waitForRespawn()
            attachPlayerToPlatform(char, platform)
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local coin = getClosestCoin(hrp.Position)

        if coin then
            -- move platform under map below coin
            tweenPlatform(platform, coin.Position)

            -- lift player so their head touches coin
            local finalPos = coin.Position + Vector3.new(0, HEAD_OFFSET, 0)
            hrp.CFrame = CFrame.new(finalPos.X, finalPos.Y, finalPos.Z)

            lookAtTarget(char, coin.Position)
            task.wait(SEARCH_INTERVAL)
        else
            -- no coins left, just wait and check again
            task.wait(0.5)
        end
    end
end

task.spawn(autoFarm)
