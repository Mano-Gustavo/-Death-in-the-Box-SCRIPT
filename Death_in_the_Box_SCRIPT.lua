-- Death in the Box SCRIPT
-- Made by: ManoGustavo

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mano-Gustavo/Mano-Gustavo-Library/refs/heads/main/library.lua"))()

local Window = Library:CreateWindow({
    Title = "Death in the Box SCRIPT",
    Keybind = Enum.KeyCode.RightControl
})

print("Death in the Box SCRIPT (Made by ManoGustavo) Enjoy the Script!")

-- ============================================
-- VARIÁVEIS GLOBAIS
-- ============================================
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = game.Players.LocalPlayer

-- Variáveis de estado
local espEnabled = false
local fullbrightEnabled = false
local autoShootEnabled = false

-- Conexões
local espConnection
local autoShootConnection
local fullbrightConnection

-- Status Display (não abrir automaticamente)
local statusDisplayEnabled = false
local statusDisplay

-- Armazenamento
local distanceLabels = {}
local humanoidConnections = {}

-- Variáveis para cartas ocultas
local lastHiddenCards = {}
local lastCheckTime = "Never"
local hiddenCardsCheckConnection

-- ============================================
-- FUNÇÃO PARA VERIFICAR CARTAS OCULTAS
-- ============================================
local function checkPlayerHiddenCards()
    local playerFolder = workspace:FindFirstChild(LocalPlayer.Name)
    if not playerFolder then
        lastHiddenCards = {}
        return {}
    end
    
    local cardsFolder = playerFolder:FindFirstChild("Cards")
    if not cardsFolder then
        lastHiddenCards = {}
        return {}
    end
    
    local hiddenCards = {}
    for _, card in ipairs(cardsFolder:GetChildren()) do
        if card:FindFirstChild("isHidden") then
            table.insert(hiddenCards, card.Name)
        end
    end
    
    lastHiddenCards = hiddenCards
    lastCheckTime = os.date("%H:%M:%S")
    return hiddenCards
end

-- ============================================
-- FUNÇÕES ESP (COM CORREÇÃO PARA JOGADORES MORTOS)
-- ============================================
local function createCardLabels(player)
    if player == Players.LocalPlayer then return end
    local character = player.Character
    if character and character:FindFirstChild("Head") then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            -- Jogador está morto, remover labels se existirem
            if distanceLabels[player] then
                for _, label in ipairs(distanceLabels[player]) do
                    label.Enabled = false
                end
                distanceLabels[player] = nil
            end
            return
        end
        
        local head = character.Head
        local cardFolder = Workspace:FindFirstChild(player.Name) and Workspace[player.Name]:FindFirstChild("Cards")
        if cardFolder then
            local cardLabels = distanceLabels[player] or {}
            for i, card in ipairs(cardFolder:GetChildren()) do
                local cardLabel = cardLabels[i]
                if not cardLabel then
                    cardLabel = Instance.new("BillboardGui")
                    cardLabel.Adornee = head
                    cardLabel.Size = UDim2.new(0, 70, 0, 15)
                    cardLabel.StudsOffset = Vector3.new(0, 2.5 + (i * 0.6), 0)
                    cardLabel.AlwaysOnTop = true
                    cardLabel.Parent = head
                    
                    local cardTextLabel = Instance.new("TextLabel")
                    cardTextLabel.Size = UDim2.new(1, 0, 1, 0)
                    cardTextLabel.BackgroundTransparency = 1
                    cardTextLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                    cardTextLabel.TextStrokeTransparency = 0.3
                    cardTextLabel.TextScaled = true
                    cardTextLabel.Font = Enum.Font.GothamBold
                    cardTextLabel.TextSize = 10
                    cardTextLabel.Text = card.Name
                    cardTextLabel.Parent = cardLabel
                    
                    cardLabels[i] = cardLabel
                end
                cardLabels[i].TextLabel.Text = card.Name
                cardLabels[i].Enabled = espEnabled and humanoid.Health > 0 -- Só ativar se estiver vivo
            end
            distanceLabels[player] = cardLabels
            
            -- Desativar conexões antigas
            if humanoidConnections[player] then
                humanoidConnections[player]:Disconnect()
            end
            
            -- Conectar evento de morte
            humanoidConnections[player] = humanoid.Died:Connect(function()
                if distanceLabels[player] then
                    for _, label in ipairs(distanceLabels[player]) do
                        label.Enabled = false
                    end
                    distanceLabels[player] = nil
                end
            end)
            
            for i = #cardFolder:GetChildren() + 1, #cardLabels do
                cardLabels[i].Enabled = false
            end
        end
    end
end

local function updateCardLabels()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Head") then
            createCardLabels(player)
        end
    end
end

local function onPlayerDied(player)
    if distanceLabels[player] then
        for _, label in ipairs(distanceLabels[player]) do
            label.Enabled = false
        end
        distanceLabels[player] = nil
    end
end

local function toggleESP(value)
    espEnabled = value
    if espEnabled then
        if espConnection then
            espConnection:Disconnect()
        end
        
        -- Limpar conexões antigas
        for player, connection in pairs(humanoidConnections) do
            connection:Disconnect()
        end
        humanoidConnections = {}
        
        espConnection = RunService.Heartbeat:Connect(function()
            updateCardLabels()
        end)
        
        -- Conectar eventos de morte para jogadores existentes
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoidConnections[player] = humanoid.Died:Connect(function()
                        onPlayerDied(player)
                    end)
                end
            end
        end
        
        Library:Notification({
            Title = "Cards ESP",
            Text = "ESP enabled! You can see opponent's cards.",
            Duration = 3,
            Type = "Success"
        })
    else
        if espConnection then
            espConnection:Disconnect()
            espConnection = nil
        end
        
        -- Desconectar todas as conexões de humanoid
        for player, connection in pairs(humanoidConnections) do
            connection:Disconnect()
        end
        humanoidConnections = {}
        
        -- Desativar todas as labels
        for _, labels in pairs(distanceLabels) do
            for _, label in ipairs(labels) do
                label.Enabled = false
            end
        end
        distanceLabels = {}
        
        Library:Notification({
            Title = "Cards ESP",
            Text = "ESP disabled.",
            Duration = 3,
            Type = "Info"
        })
    end
end

-- ============================================
-- FUNÇÕES FULLBRIGHT
-- ============================================
local originalLighting = {
    FogEnd = game.Lighting.FogEnd,
    TintColor = game.Lighting.ColorCorrection and game.Lighting.ColorCorrection.TintColor or Color3.fromRGB(255, 255, 255),
    FogColor = game.Lighting.FogColor,
    Ambient = game.Lighting.Ambient
}

local function toggleFullbright(value)
    fullbrightEnabled = value
    if fullbrightEnabled then
        if fullbrightConnection then
            fullbrightConnection:Disconnect()
        end
        
        fullbrightConnection = RunService.Heartbeat:Connect(function()
            if fullbrightEnabled then
                game.Lighting.FogEnd = 1000000
                game.Lighting.FogColor = Color3.fromRGB(255, 255, 255)
                game.Lighting.Ambient = Color3.fromRGB(200, 200, 200)
                
                if game.Lighting:FindFirstChild("ColorCorrection") then
                    game.Lighting.ColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
                end
            else
                fullbrightConnection:Disconnect()
            end
        end)
        
        Library:Notification({
            Title = "Fullbright",
            Text = "Fullbright enabled! Better visibility in dark areas.",
            Duration = 3,
            Type = "Success"
        })
    else
        if fullbrightConnection then
            fullbrightConnection:Disconnect()
            fullbrightConnection = nil
        end
        
        game.Lighting.FogEnd = originalLighting.FogEnd
        game.Lighting.FogColor = originalLighting.FogColor
        game.Lighting.Ambient = originalLighting.Ambient
        
        if game.Lighting:FindFirstChild("ColorCorrection") then
            game.Lighting.ColorCorrection.TintColor = originalLighting.TintColor
        end
        
        Library:Notification({
            Title = "Fullbright",
            Text = "Fullbright disabled.",
            Duration = 3,
            Type = "Info"
        })
    end
end

-- ============================================
-- FUNÇÕES AUTO-SHOOT
-- ============================================
local function toggleAutoShoot(value)
    autoShootEnabled = value
    
    if autoShootEnabled then
        local LocalPlayer = game.Players.LocalPlayer
        local Duel = workspace:FindFirstChild("Duel")
        
        if not Duel then
            Library:Notification({
                Title = "Error",
                Text = "You are not in a duel!",
                Duration = 5,
                Type = "Error"
            })
            autoShootEnabled = false
            return
        end
        
        if autoShootConnection then
            autoShootConnection:Disconnect()
        end
        
        local function fireAtTarget(targetPlayer)
            if not targetPlayer or targetPlayer == LocalPlayer then return end
            local success, errorMsg = pcall(function()
                game.ReplicatedStorage.Remote.PickPlayerRevolver:FireServer(targetPlayer)
            end)
            if not success then
                print("Auto-Shoot error:", errorMsg)
            end
        end
        
        autoShootConnection = RunService.Heartbeat:Connect(function()
            if Duel and Duel:FindFirstChild("Active") and Duel.Active.Value then
                local isPlayerInDuel = false
                local opponentPlayer = nil
                
                if Duel:FindFirstChild("Player1") and Duel.Player1.Value == LocalPlayer then
                    isPlayerInDuel = true
                    opponentPlayer = Duel.Player2.Value
                elseif Duel:FindFirstChild("Player2") and Duel.Player2.Value == LocalPlayer then
                    isPlayerInDuel = true
                    opponentPlayer = Duel.Player1.Value
                end
                
                if isPlayerInDuel and opponentPlayer then
                    fireAtTarget(opponentPlayer)
                end
            end
        end)
        
        Library:Notification({
            Title = "Auto-Shoot",
            Text = "Auto-Shoot enabled! Will automatically fire during duels.",
            Duration = 5,
            Type = "Success"
        })
    else
        if autoShootConnection then
            autoShootConnection:Disconnect()
            autoShootConnection = nil
        end
        
        Library:Notification({
            Title = "Auto-Shoot",
            Text = "Auto-Shoot disabled.",
            Duration = 3,
            Type = "Info"
        })
    end
end

-- ============================================
-- FUNÇÃO REVEAL HIDDEN CARDS (PARA O BOTÃO)
-- ============================================
local function checkHiddenCards()
    local hiddenCards = checkPlayerHiddenCards()
    
    local message = ""
    if #hiddenCards > 0 then
        message = "🎴 HIDDEN CARDS FOUND:\n" .. table.concat(hiddenCards, ", ")
        message = message .. "\n\n⚠️ You have " .. #hiddenCards .. " hidden card(s)"
        
        -- Atualizar última verificação
        lastCheckTime = os.date("%H:%M:%S")
    else
        message = "✅ No hidden cards in your hand"
    end
    
    Library:Notification({
        Title = "Your Hidden Cards",
        Text = message,
        Duration = 8,
        Type = "Info"
    })
end

-- ============================================
-- FUNÇÃO STATUS DISPLAY (COM INFO DE CARTAS OCULTAS)
-- ============================================
local function createStatusDisplay()
    if statusDisplay then
        statusDisplay:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatusDisplay"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Frame principal (maior para acomodar cartas ocultas)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 280, 0, 220)
    mainFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    
    -- Bordas arredondadas
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Sombra
    local shadow = Instance.new("UIStroke")
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Thickness = 1.5
    shadow.Transparency = 0.7
    shadow.Parent = mainFrame
    
    mainFrame.Parent = screenGui
    
    -- Barra de título
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 28)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    titleBar.BorderSizePixel = 0
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12, 0, 0)
    titleCorner.Parent = titleBar
    
    titleBar.Parent = mainFrame
    
    -- Título
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -10, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "📊 STATUS"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- Container principal
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(1, -10, 1, -33)
    mainContainer.Position = UDim2.new(0, 5, 0, 28)
    mainContainer.BackgroundTransparency = 1
    mainContainer.Parent = mainFrame
    
    -- Seção 1: Status das funções
    local functionsSection = Instance.new("Frame")
    functionsSection.Name = "FunctionsSection"
    functionsSection.Size = UDim2.new(1, 0, 0, 90)
    functionsSection.BackgroundTransparency = 1
    functionsSection.Parent = mainContainer
    
    -- Título da seção
    local functionsTitle = Instance.new("TextLabel")
    functionsTitle.Size = UDim2.new(1, 0, 0, 20)
    functionsTitle.BackgroundTransparency = 1
    functionsTitle.Text = "FUNCTIONS"
    functionsTitle.TextColor3 = Color3.fromRGB(180, 180, 200)
    functionsTitle.Font = Enum.Font.GothamBold
    functionsTitle.TextSize = 12
    functionsTitle.TextXAlignment = Enum.TextXAlignment.Left
    functionsTitle.Parent = functionsSection
    
    -- Status labels para funções
    local statusLabels = {}
    
    local function createFunctionRow(text, yPosition, icon)
        local rowFrame = Instance.new("Frame")
        rowFrame.Size = UDim2.new(1, 0, 0, 22)
        rowFrame.Position = UDim2.new(0, 0, 0, yPosition)
        rowFrame.BackgroundTransparency = 1
        rowFrame.Parent = functionsSection
        
        -- Ícone
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 20, 1, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon or "○"
        iconLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextSize = 12
        iconLabel.TextXAlignment = Enum.TextXAlignment.Center
        iconLabel.Parent = rowFrame
        
        -- Texto
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -22, 1, 0)
        textLabel.Position = UDim2.new(0, 22, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextSize = 12
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = rowFrame
        
        return {icon = iconLabel, text = textLabel}
    end
    
    statusLabels.esp = createFunctionRow("Cards ESP: OFF", 20, "👁️")
    statusLabels.fullbright = createFunctionRow("Fullbright: OFF", 44, "💡")
    statusLabels.autoshoot = createFunctionRow("Auto-Shoot: OFF", 68, "🎯")
    
    -- Seção 2: Cartas ocultas
    local cardsSection = Instance.new("Frame")
    cardsSection.Name = "CardsSection"
    cardsSection.Size = UDim2.new(1, 0, 0, 100)
    cardsSection.Position = UDim2.new(0, 0, 0, 100)
    cardsSection.BackgroundTransparency = 1
    cardsSection.Parent = mainContainer
    
    -- Título da seção de cartas
    local cardsTitle = Instance.new("TextLabel")
    cardsTitle.Size = UDim2.new(1, 0, 0, 20)
    cardsTitle.BackgroundTransparency = 1
    cardsTitle.Text = "HIDDEN CARDS"
    cardsTitle.TextColor3 = Color3.fromRGB(180, 180, 200)
    cardsTitle.Font = Enum.Font.GothamBold
    cardsTitle.TextSize = 12
    cardsTitle.TextXAlignment = Enum.TextXAlignment.Left
    cardsTitle.Parent = cardsSection
    
    -- Info de cartas ocultas
    local hiddenCardsIcon = Instance.new("TextLabel")
    hiddenCardsIcon.Size = UDim2.new(0, 20, 0, 20)
    hiddenCardsIcon.Position = UDim2.new(0, 0, 0, 22)
    hiddenCardsIcon.BackgroundTransparency = 1
    hiddenCardsIcon.Text = "🎴"
    hiddenCardsIcon.TextColor3 = Color3.fromRGB(150, 150, 150)
    hiddenCardsIcon.Font = Enum.Font.GothamBold
    hiddenCardsIcon.TextSize = 12
    hiddenCardsIcon.TextXAlignment = Enum.TextXAlignment.Center
    hiddenCardsIcon.Parent = cardsSection
    
    -- Status das cartas (quantidade)
    local cardsStatusLabel = Instance.new("TextLabel")
    cardsStatusLabel.Name = "CardsStatus"
    cardsStatusLabel.Size = UDim2.new(1, -22, 0, 20)
    cardsStatusLabel.Position = UDim2.new(0, 22, 0, 22)
    cardsStatusLabel.BackgroundTransparency = 1
    cardsStatusLabel.Text = "Checking..."
    cardsStatusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    cardsStatusLabel.Font = Enum.Font.Gotham
    cardsStatusLabel.TextSize = 12
    cardsStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    cardsStatusLabel.Parent = cardsSection
    
    -- Nome das cartas (scrollable se muitas)
    local cardsListLabel = Instance.new("TextLabel")
    cardsListLabel.Name = "CardsList"
    cardsListLabel.Size = UDim2.new(1, -5, 0, 58)
    cardsListLabel.Position = UDim2.new(0, 5, 0, 44)
    cardsListLabel.BackgroundTransparency = 1
    cardsListLabel.Text = "No hidden cards"
    cardsListLabel.TextColor3 = Color3.fromRGB(180, 200, 220)
    cardsListLabel.Font = Enum.Font.Gotham
    cardsListLabel.TextSize = 11
    cardsListLabel.TextXAlignment = Enum.TextXAlignment.Left
    cardsListLabel.TextYAlignment = Enum.TextYAlignment.Top
    cardsListLabel.TextWrapped = true
    cardsListLabel.Parent = cardsSection
    
    -- Sistema de arrastar
    local dragging = false
    local dragStart, startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Função para atualizar display das cartas
    local function updateCardsDisplay()
        local hiddenCards = checkPlayerHiddenCards()
        
        if #hiddenCards > 0 then
            -- Tem cartas ocultas
            hiddenCardsIcon.TextColor3 = Color3.fromRGB(255, 100, 100)
            cardsStatusLabel.Text = "Hidden: " .. #hiddenCards .. " card(s)"
            cardsStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            
            -- Mostrar nomes das cartas (limitar se muitas)
            if #hiddenCards <= 3 then
                cardsListLabel.Text = table.concat(hiddenCards, "\n")
            else
                cardsListLabel.Text = table.concat({hiddenCards[1], hiddenCards[2], hiddenCards[3]}, "\n") .. 
                                    "\n... +" .. (#hiddenCards - 3) .. " more"
            end
            cardsListLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
        else
            -- Sem cartas ocultas
            hiddenCardsIcon.TextColor3 = Color3.fromRGB(100, 255, 100)
            cardsStatusLabel.Text = "No hidden cards"
            cardsStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            cardsListLabel.Text = "All cards are visible"
            cardsListLabel.TextColor3 = Color3.fromRGB(150, 220, 150)
        end
    end
    
    -- Função para atualizar todo o status display
    local function updateStatusDisplay()
        if not screenGui or not screenGui.Parent then return end
        
        -- Atualizar status das funções
        if espEnabled then
            statusLabels.esp.icon.TextColor3 = Color3.fromRGB(0, 255, 100)
            statusLabels.esp.text.Text = "Cards ESP: ON"
            statusLabels.esp.text.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            statusLabels.esp.icon.TextColor3 = Color3.fromRGB(255, 80, 80)
            statusLabels.esp.text.Text = "Cards ESP: OFF"
            statusLabels.esp.text.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        if fullbrightEnabled then
            statusLabels.fullbright.icon.TextColor3 = Color3.fromRGB(255, 200, 0)
            statusLabels.fullbright.text.Text = "Fullbright: ON"
            statusLabels.fullbright.text.TextColor3 = Color3.fromRGB(255, 200, 0)
        else
            statusLabels.fullbright.icon.TextColor3 = Color3.fromRGB(255, 80, 80)
            statusLabels.fullbright.text.Text = "Fullbright: OFF"
            statusLabels.fullbright.text.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        if autoShootEnabled then
            statusLabels.autoshoot.icon.TextColor3 = Color3.fromRGB(0, 180, 255)
            statusLabels.autoshoot.text.Text = "Auto-Shoot: ON"
            statusLabels.autoshoot.text.TextColor3 = Color3.fromRGB(0, 180, 255)
        else
            statusLabels.autoshoot.icon.TextColor3 = Color3.fromRGB(255, 80, 80)
            statusLabels.autoshoot.text.Text = "Auto-Shoot: OFF"
            statusLabels.autoshoot.text.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        -- Atualizar display das cartas
        updateCardsDisplay()
    end
    
    -- Verificar cartas periodicamente
    if hiddenCardsCheckConnection then
        hiddenCardsCheckConnection:Disconnect()
    end
    
    hiddenCardsCheckConnection = RunService.Heartbeat:Connect(function()
        if screenGui and screenGui.Parent then
            updateStatusDisplay()
        else
            hiddenCardsCheckConnection:Disconnect()
        end
    end)
    
    statusDisplay = screenGui
    return screenGui
end

local function toggleStatusDisplay(value)
    statusDisplayEnabled = value
    
    if statusDisplayEnabled then
        createStatusDisplay()
        Library:Notification({
            Title = "Status Display",
            Text = "Status display enabled with hidden cards info!",
            Duration = 3,
            Type = "Success"
        })
    else
        if statusDisplay then
            statusDisplay:Destroy()
            statusDisplay = nil
        end
    end
end

-- ============================================
-- INTERFACE DO USUÁRIO
-- ============================================
local TabVisuals = Window:CreateTab("🔎 Visuals")
local SectionESP = TabVisuals:CreateSection("ESP Settings")
local SectionVisual = TabVisuals:CreateSection("Visual Enhancements")

-- Cards ESP
local ToggleESP = SectionESP:CreateToggle("Cards ESP", function(Value)
    toggleESP(Value)
end)
ToggleESP:SetTooltip("Show opponent's cards above their heads")

-- Fullbright
local ToggleFullbright = SectionVisual:CreateToggle("Fullbright", function(Value)
    toggleFullbright(Value)
end)
ToggleFullbright:SetTooltip("Improves visibility in dark areas")

-- ============================================
-- GAME TAB
-- ============================================
local TabGame = Window:CreateTab("♠️ Game")
local SectionCombat = TabGame:CreateSection("Combat")
local SectionCards = TabGame:CreateSection("Cards Management")

-- Warning
SectionCombat:CreateLabel("⚠️ Enable Auto-Shoot only during duels!")

-- Auto-Shoot
local AutoShootToggle = SectionCombat:CreateToggle("Auto-Shoot", function(Value)
    toggleAutoShoot(Value)
end)
AutoShootToggle:SetTooltip("Automatically shoot at your opponent during duels")

-- Reveal Hidden Cards
local RevealCardsBtn = SectionCards:CreateButton("Reveal Hidden Cards", function()
    checkHiddenCards()
end)
RevealCardsBtn:SetTooltip("Check which hidden cards are in your hand")

-- Auto-Check Toggle (nova função)
local AutoCheckToggle = SectionCards:CreateToggle("Auto-Check Cards", function(Value)
    if Value then
        Library:Notification({
            Title = "Auto-Check",
            Text = "Auto-check enabled. Status display will update automatically.",
            Duration = 4,
            Type = "Success"
        })
    else
        Library:Notification({
            Title = "Auto-Check",
            Text = "Auto-check disabled.",
            Duration = 3,
            Type = "Info"
        })
    end
end)
AutoCheckToggle:SetTooltip("Automatically check for hidden cards (requires Status Display)")

-- ============================================
-- UTILITIES TAB
-- ============================================
local TabUtilities = Window:CreateTab("🛠️ Utilities")
local SectionDisplay = TabUtilities:CreateSection("Display")
local SectionTools = TabUtilities:CreateSection("Tools")

-- Status Display Toggle
local StatusDisplayToggle = SectionDisplay:CreateToggle("Show Status Display", function(Value)
    toggleStatusDisplay(Value)
end)
StatusDisplayToggle:SetTooltip("Show/hide the status display with hidden cards info")

-- Reset Position Button
local ResetPosBtn = SectionDisplay:CreateButton("Reset Display Position", function()
    if statusDisplay then
        statusDisplay:Destroy()
        statusDisplay = nil
    end
    if statusDisplayEnabled then
        createStatusDisplay()
    end
end)
ResetPosBtn:SetTooltip("Reset status display to default position")

-- Check Cards Now Button
local CheckNowBtn = SectionTools:CreateButton("Check Cards Now", function()
    checkHiddenCards()
    if statusDisplay then
        Library:Notification({
            Title = "Cards Checked",
            Text = "Hidden cards info updated in Status Display.",
            Duration = 3,
            Type = "Info"
        })
    end
end)
CheckNowBtn:SetTooltip("Force check for hidden cards and update display")

-- Clear All ESP Button
local ClearESPBtn = SectionTools:CreateButton("Clear All ESP", function()
    for _, labels in pairs(distanceLabels) do
        for _, label in ipairs(labels) do
            label.Enabled = false
        end
    end
    distanceLabels = {}
    
    for player, connection in pairs(humanoidConnections) do
        connection:Disconnect()
    end
    humanoidConnections = {}
    
    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end
    
    espEnabled = false
    ToggleESP:SetValue(false)
    
    Library:Notification({
        Title = "ESP Cleared",
        Text = "All ESP labels have been removed",
        Duration = 3,
        Type = "Info"
    })
end)
ClearESPBtn:SetTooltip("Remove all ESP labels from the game")

-- ============================================
-- INFO TAB
-- ============================================
local TabInfo = Window:CreateTab("📝 Info")
local SectionInfo = TabInfo:CreateSection("Script Info")
SectionInfo:CreateLabel("Death in the Box SCRIPT")
SectionInfo:CreateLabel("Version: 2.2")
SectionInfo:CreateLabel("Author: ManoGustavo")

local SectionInstructions = TabInfo:CreateSection("How to Use")
SectionInstructions:CreateLabel("1. Enable Status Display in Utilities")
SectionInstructions:CreateLabel("2. Status Display shows hidden cards in real-time")
SectionInstructions:CreateLabel("3. Use Reveal Hidden Cards for detailed check")
SectionInstructions:CreateLabel("4. ESP auto-hides for dead players")
SectionInstructions:CreateLabel("5. Auto-Shoot only works in active duels")

local SectionFeatures = TabInfo:CreateSection("Status Display Features")
SectionFeatures:CreateLabel("✅ Real-time hidden cards detection")
SectionFeatures:CreateLabel("✅ Shows card names when hidden")
SectionFeatures:CreateLabel("✅ Auto-updates every few seconds")
SectionFeatures:CreateLabel("✅ Drag to move position")
SectionFeatures:CreateLabel("✅ Color-coded status indicators")

-- ============================================
-- INICIALIZAÇÃO
-- ============================================
Library:Notification({
    Title = "Death in the Box SCRIPT v2.2",
    Text = "Loaded successfully! Status Display shows hidden cards.",
    Duration = 5,
    Type = "Success"
})

-- Verificar cartas inicialmente
task.spawn(function()
    task.wait(2)
    checkPlayerHiddenCards()
end)

print("[SCRIPT] Death in the Box SCRIPT loaded!")
print("[SCRIPT] Status Display now shows hidden cards information!")
print("[SCRIPT] Enable Status Display in Utilities tab to see it")