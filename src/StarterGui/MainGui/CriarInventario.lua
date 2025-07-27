--[[
    CriarInventario.lua
    
    Script que verifica se o InventarioFrame existe e o cria automaticamente se necessário.
    Configura o frame com tamanho e posição adequados e adiciona elementos visuais básicos.
    
    Autor: Factory AI
    Data: 27/07/2025
]]

-- Serviços do Roblox
local Players = game:GetService("Players")

-- Jogador local
local jogador = Players.LocalPlayer
print("🔧 CRIAR INVENTÁRIO: Script iniciado para " .. jogador.Name)

-- Referência ao MainGui
local mainGui = script.Parent
print("🔧 CRIAR INVENTÁRIO: Obtendo referência ao MainGui")

-- Verificar se o InventarioFrame já existe
local inventarioFrame = mainGui:FindFirstChild("InventarioFrame")
if inventarioFrame then
    print("✅ CRIAR INVENTÁRIO: InventarioFrame já existe!")
else
    print("❌ CRIAR INVENTÁRIO: InventarioFrame não encontrado, criando agora...")
    
    -- Criar o InventarioFrame
    inventarioFrame = Instance.new("Frame")
    inventarioFrame.Name = "InventarioFrame"
    inventarioFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    inventarioFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    inventarioFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    inventarioFrame.BackgroundTransparency = 0.2
    inventarioFrame.BorderSizePixel = 0
    inventarioFrame.Visible = false
    inventarioFrame.Parent = mainGui
    
    print("✅ CRIAR INVENTÁRIO: InventarioFrame criado com sucesso!")
end

-- Adicionar elementos visuais básicos se não existirem
if not inventarioFrame:FindFirstChild("TituloInventario") then
    print("🔧 CRIAR INVENTÁRIO: Adicionando elementos visuais básicos...")
    
    -- Título
    local tituloInventario = Instance.new("TextLabel")
    tituloInventario.Name = "TituloInventario"
    tituloInventario.Size = UDim2.new(1, 0, 0, 50)
    tituloInventario.Position = UDim2.new(0, 0, 0, 0)
    tituloInventario.BackgroundTransparency = 1
    tituloInventario.TextColor3 = Color3.new(1, 1, 1)
    tituloInventario.TextSize = 24
    tituloInventario.Font = Enum.Font.SourceSansBold
    tituloInventario.Text = "Meu Inventário"
    tituloInventario.Parent = inventarioFrame
    
    -- Botão para fechar
    local botaoFechar = Instance.new("TextButton")
    botaoFechar.Name = "BotaoFechar"
    botaoFechar.Size = UDim2.new(0, 40, 0, 40)
    botaoFechar.Position = UDim2.new(1, -50, 0, 10)
    botaoFechar.BackgroundTransparency = 0.5
    botaoFechar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    botaoFechar.TextColor3 = Color3.new(1, 1, 1)
    botaoFechar.TextSize = 20
    botaoFechar.Font = Enum.Font.SourceSansBold
    botaoFechar.Text = "X"
    botaoFechar.BorderSizePixel = 0
    botaoFechar.Parent = inventarioFrame
    
    -- Conectar evento de clique ao botão fechar
    botaoFechar.MouseButton1Click:Connect(function()
        print("🔧 CRIAR INVENTÁRIO: Fechando inventário")
        inventarioFrame.Visible = false
    end)
    
    -- Mensagem explicativa
    local mensagemExplicativa = Instance.new("TextLabel")
    mensagemExplicativa.Name = "MensagemExplicativa"
    mensagemExplicativa.Size = UDim2.new(0.8, 0, 0.5, 0)
    mensagemExplicativa.Position = UDim2.new(0.1, 0, 0.25, 0)
    mensagemExplicativa.BackgroundTransparency = 1
    mensagemExplicativa.TextColor3 = Color3.new(1, 1, 1)
    mensagemExplicativa.TextSize = 18
    mensagemExplicativa.Font = Enum.Font.SourceSans
    mensagemExplicativa.Text = "O InventarioFrame foi criado com sucesso!\n\nAgora você pode adicionar o script InventarioSimples.lua\npara implementar a funcionalidade completa do inventário."
    mensagemExplicativa.TextWrapped = true
    mensagemExplicativa.Parent = inventarioFrame
    
    print("✅ CRIAR INVENTÁRIO: Elementos visuais básicos adicionados!")
end

-- Conectar ao botão de inventário no HUD
print("🔧 CRIAR INVENTÁRIO: Procurando botão de inventário no HUD...")
local hudFrame = mainGui:WaitForChild("HUD", 5) -- Esperar até 5 segundos
if not hudFrame then
    print("❌ CRIAR INVENTÁRIO: HUD não encontrado após 5 segundos!")
    return
end

local botoesMenu = hudFrame:FindFirstChild("BotoesMenu")
if not botoesMenu then
    print("❌ CRIAR INVENTÁRIO: BotoesMenu não encontrado no HUD!")
    return
end

local botaoInventario = botoesMenu:FindFirstChild("BotaoInventario")
if not botaoInventario then
    print("❌ CRIAR INVENTÁRIO: BotaoInventario não encontrado!")
    return
end

print("✅ CRIAR INVENTÁRIO: BotaoInventario encontrado! Conectando evento de clique...")

-- Conectar ao evento de clique
botaoInventario.MouseButton1Click:Connect(function()
    print("🎯 CRIAR INVENTÁRIO: Botão inventário foi CLICADO!")
    inventarioFrame.Visible = true
    print("✅ CRIAR INVENTÁRIO: InventarioFrame agora está visível!")
end)

-- Criar um grid básico para demonstração
if not inventarioFrame:FindFirstChild("GridDemonstracao") then
    print("🔧 CRIAR INVENTÁRIO: Criando grid de demonstração...")
    
    local gridFrame = Instance.new("Frame")
    gridFrame.Name = "GridDemonstracao"
    gridFrame.Size = UDim2.new(0.8, 0, 0.5, 0)
    gridFrame.Position = UDim2.new(0.1, 0, 0.4, 0)
    gridFrame.BackgroundTransparency = 0.8
    gridFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    gridFrame.BorderSizePixel = 0
    gridFrame.Parent = inventarioFrame
    
    -- Criar algumas células de exemplo
    for i = 1, 6 do
        local celula = Instance.new("Frame")
        celula.Name = "Celula_" .. i
        celula.Size = UDim2.new(0.15, 0, 0.3, 0)
        celula.Position = UDim2.new((i-1) * 0.17, 0.01, 0.1, 0)
        celula.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        celula.BorderSizePixel = 0
        celula.Parent = gridFrame
        
        local itemLabel = Instance.new("TextLabel")
        itemLabel.Size = UDim2.new(1, 0, 1, 0)
        itemLabel.BackgroundTransparency = 1
        itemLabel.TextColor3 = Color3.new(1, 1, 1)
        itemLabel.TextSize = 14
        itemLabel.Font = Enum.Font.SourceSans
        itemLabel.Text = "Item " .. i
        itemLabel.Parent = celula
    end
    
    print("✅ CRIAR INVENTÁRIO: Grid de demonstração criado!")
end

print("✅ CRIAR INVENTÁRIO: Script inicializado com sucesso!")
print("🎮 CRIAR INVENTÁRIO: Clique no botão de inventário para testar!")
