-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Local player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Configuration
local COIN_NAME = "Coin_Server"
local CHECK_INTERVAL = 0.5
local TWEEN_DURATION = 0.3
local PLATFORM_OFFSET = Vector3.new(0, -5, 0)

-- Create collection platform
local platform = Instance.new("Part")
platform.Name = "CoinCollectorPlatform"
platform.Anchored = true
platform.CanCollide = false
platform.Size = Vector3.new(4, 1, 4)
platform.Transparency = 0.7
platform.Color = Color3.fromRGB(0, 255, 0)
platform.Parent = Workspace

-- Keep track of active coins
local activeCoins = {}
local platformMoving = false

-- Function to find all coins in workspace
local function findCoins()
    local coins = {}
    
    local function scan(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == COIN_NAME and child:IsA("BasePart") then
                table.insert(coins, child)
            end
            scan(child) -- Recursively scan children
        end
    end
    
    scan(Workspace)
    return coins
end

-- Function to move platform to coin
local function moveToCoin(coin)
    if not coin or not coin.Parent then return end
    if platformMoving then return end
    
    platformMoving = true
    
    -- Calculate target position (under the coin)
    local targetCFrame = CFrame.new(coin.Position + PLATFORM_OFFSET)
    
    -- Create smooth tween
    local tweenInfo = TweenInfo.new(
        TWEEN_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(platform, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    
    tween.Completed:Wait()
    platformMoving = false
end

-- Main collection function
local function collectCoins()
    while true do
        -- Find all current coins
        local coins = findCoins()
        
        if #coins > 0 then
            -- Sort coins by distance to platform
            table.sort(coins, function(a, b)
                return (a.Position - platform.Position).Magnitude < 
                       (b.Position - platform.Position).Magnitude
            end)
            
            -- Move to closest coin
            moveToCoin(coins[1])
        else
            -- No coins found, stay under player
            if not platformMoving then
                platform.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -5, 0)
            end
        end
        
        wait(CHECK_INTERVAL)
    end
end

-- Update platform position when character moves
local function followCharacter()
    while true do
        if not platformMoving then
            platform.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -5, 0)
        end
        wait(0.1)
    end
end

-- Handle character respawns
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end)

-- Start the functions
spawn(followCharacter)
spawn(collectCoins)

-- Initial position
platform.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -5, 0)
