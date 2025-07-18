local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local SEARCH_INTERVAL = 0.25 -- faster scanning
local PLATFORM_SIZE = Vector3.new(6, 1, 6)
local MOVE_TIME = 0.35 -- 2x faster tween
local UNDER_OFFSET = 10 -- go under the map slightly
local HEAD_OFFSET = 3 -- lift platform so player's head touches coin

-- Create platform
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
    if not hrp then return end

    -- Remove old attachments
    for _, obj in ipairs(hrp:GetChildren()) do
        if obj:IsA("AlignPosition") or obj:IsA("AlignOrientation") then
            obj:Destroy()
        end
    end

    -- Add new attachments
    local att0 = hrp:FindFirstChild("Attachment") or Instance.new("Attachment", hrp)
    local att1 = platform:FindFirstChild("Attachment") or Instance.new("Attachment", platform)

    local align = Instance.new("AlignPosition")
    align.Name = "AlignToPlatform"
    align.MaxForce = math.huge
    align.Responsiveness = 200
    align.Mode = Enum.PositionAlignmentMode.OneAttachment
    align.Attachment0 = att0
    align.Attachment1 = att1
    align.Parent = hrp
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

-- Tween platform under map below the target
local function tweenPlatform(platform, targetPos)
    local underMapPos = Vector3.new(targetPos.X, targetPos.Y - UNDER_OFFSET, targetPos.Z)
    local tween = TweenService:Create(platform, TweenInfo.new(MOVE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = underMapPos})
    tween:Play()
    tween.Completed:Wait()
end

-- Make player look at the coin
local function lookAtTarget(character, targetPos)
    local head = character:FindFirstChild("Head")
    if head then
        local dir = (targetPos - head.Position).Unit
        head.CFrame = CFrame.new(head.Position, head.Position + dir)
    end
end

-- Wait until player respawns
local function waitForRespawn()
    repeat task.wait(0.2) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    return LocalPlayer.Character
end

-- Main farming loop
local function autoFarm()
    local platform = Workspace:FindFirstChild("AutoFarmPlatform") or createPlatform()

    while true do
        local character = LocalPlayer.Character or waitForRespawn()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            -- wait until respawned fully
            character = waitForRespawn()
            hrp = character:WaitForChild("HumanoidRootPart")
        end

        -- Always reattach to platform after respawn
        attachPlayerToPlatform(character, platform)

        local coin = getClosestCoin(hrp.Position)
        if coin then
            -- Move platform under coin
            tweenPlatform(platform, coin.Position)

            -- Align player's head to coin (touch with head)
            local finalPos = coin.Position + Vector3.new(0, HEAD_OFFSET, 0)
            hrp.CFrame = CFrame.new(finalPos)

            -- Face towards coin
            lookAtTarget(character, coin.Position)

            task.wait(SEARCH_INTERVAL)
        else
            -- No coins left, just stay idle
            task.wait(0.5)
        end
    end
end

task.spawn(autoFarm)
