-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Local player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Configuration
local COIN_NAME = "Coin_Server"
local COLLECTION_INTERVAL = 0.5
local TWEEN_DURATION = 0.3
local SAFE_SPACE_CFRAME = CFrame.new(0, -100, 0) -- Position in the void for reset
local PLATFORM_OFFSET = Vector3.new(0, -5, 0) -- How far below coin to position platform

-- Create collection platform
local collectionPlatform = Instance.new("Part")
collectionPlatform.Name = "AutoCollectPlatform"
collectionPlatform.Anchored = true
collectionPlatform.CanCollide = true
collectionPlatform.Size = Vector3.new(4, 1, 4)
collectionPlatform.Transparency = 0.5
collectionPlatform.Color = Color3.fromRGB(0, 255, 0)
collectionPlatform.Parent = Workspace

-- Keep track of collected coins
local collectedCoins = {}

-- Function to find all active coins in the workspace
local function findActiveCoins()
    local coins = {}
    
    local function searchDescendants(parent)
        for _, descendant in ipairs(parent:GetDescendants()) do
            if descendant.Name == COIN_NAME and descendant:IsA("BasePart") then
                if not collectedCoins[descendant] then
                    table.insert(coins, descendant)
                end
            end
        end
    end
    
    -- Search all top-level objects in workspace
    for _, item in ipairs(Workspace:GetChildren()) do
        searchDescendants(item)
    end
    
    return coins
end

-- Function to get the closest coin to a position
local function getClosestCoin(position, coins)
    local closestCoin = nil
    local closestDistance = math.huge
    
    for _, coin in ipairs(coins) do
        local distance = (position - coin.Position).Magnitude
        if distance < closestDistance then
            closestDistance = distance
            closestCoin = coin
        end
    end
    
    return closestCoin
end

-- Function to collect a coin
local function collectCoin(coin)
    if not coin or not coin.Parent then return end
    
    -- Mark coin as collected
    collectedCoins[coin] = true
    
    -- Move platform under the coin
    local targetCFrame = CFrame.new(coin.Position) * CFrame.new(PLATFORM_OFFSET)
    
    -- Create tween for smooth movement
    local tweenInfo = TweenInfo.new(
        TWEEN_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(collectionPlatform, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    
    -- Wait for tween to complete
    tween.Completed:Wait()
    
    -- Small delay to ensure coin collection
    wait(0.1)
end

-- Function to reset collection state
local function resetCollection()
    collectedCoins = {}
    collectionPlatform.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -5, 0)
end

-- Main collection loop
local function startCollection()
    while true do
        -- Find all active coins
        local coins = findActiveCoins()
        
        if #coins > 0 then
            -- Get closest coin to current position
            local currentPosition = collectionPlatform.Position
            local closestCoin = getClosestCoin(currentPosition, coins)
            
            if closestCoin then
                collectCoin(closestCoin)
            end
        else
            -- No coins found, keep platform under player
            collectionPlatform.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -5, 0)
        end
        
        wait(COLLECTION_INTERVAL)
    end
end

-- Initialize
resetCollection()

-- Reset collection when character respawns
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    resetCollection()
end)

-- Start the collection process
startCollection()
