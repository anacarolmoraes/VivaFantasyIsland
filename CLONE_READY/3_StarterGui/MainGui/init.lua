--[[
    MainGui/init.lua
    
    Script cliente para gerenciar a interface do jogo "Viva Fantasy Island"
    Versão com logs detalhados para debug e correção do problema do inventário
    
    Autor: Factory AI
    Data: 27/07/2025
]]

-- Serviços do Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Jogador local
local jogador = Players.LocalPlayer
print("📱 GUI: Script cliente iniciado para " .. jogador.Name)

-- Referências à GUI
local mainGui = script.Parent
print("📱 GUI: Obtendo referência ao MainGui")

-- Mapeamento dos frames
local frames = {
    LojaFrame = mainGui:WaitForChild("LojaFrame"),
    InventarioFrame = mainGui:WaitForChild("InventarioFrame"),
    MissoesFrame = mainGui:WaitForChild("MissoesFrame"),
    ConstrucaoFrame = mainGui:WaitForChild("ConstrucaoFrame"),
    SocialFrame = mainGui:WaitForChild("SocialFrame"),
    ConfiguracoesFrame = mainGui:WaitForChild("ConfiguracoesFrame")
}

-- Verificar se todos os frames existem
for nome, frame in pairs(frames) do
    if frame then
        print("📱 GUI: ✅ Frame encontrado: " .. nome)
    else
        warn("📱 GUI: ❌ ERRO: Frame não encontrado: " .. nome)
    end
end

-- Mapeamento dos botões
local botoes = {
    BotaoLoja = mainGui:WaitForChild("HUD"):WaitForChild("BotoesMenu"):WaitForChild("BotaoLoja"),
    BotaoInventario = mainGui:WaitForChild("HUD"):WaitForChild("BotoesMenu"):WaitForChild("BotaoInventario"),
    BotaoMissoes = mainGui:WaitForChild("HUD"):WaitForChild("BotoesMenu"):WaitForChild("BotaoMissoes"),
    BotaoConstrucao = mainGui:WaitForChild("HUD"):WaitForChild("BotoesMenu"):WaitForChild("BotaoConstrucao"),
    BotaoSocial = mainGui:WaitForChild("HUD"):WaitForChild("BotoesMenu"):WaitForChild("BotaoSocial"),
    BotaoConfiguracoes = mainGui:WaitForChild("HUD"):WaitForChild("BotoesMenu"):WaitForChild("BotaoConfiguracoes")
}

-- Elementos do HUD
local moedas = mainGui:WaitForChild("HUD"):WaitForChild("MoedasFrame"):WaitForChild("ValorMoedas")
local nivel = mainGui:WaitForChild("HUD"):WaitForChild("NivelFrame"):WaitForChild("ValorNivel")

-- Eventos Remotos (apenas os que existem)
print("📱 GUI: Conectando aos RemoteEvents...")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local atualizarHUDEvent = RemoteEvents:WaitForChild("AtualizarHUD")
local alternarFrameEvent = RemoteEvents:WaitForChild("AlternarFrame")

-- Variável para controlar qual menu está aberto
local menuAberto = nil

-- Função para fechar todos os menus
local function FecharTodosMenus()
    for nome, frame in pairs(frames) do
        if frame then
            frame.Visible = false
            print("📱 GUI: Frame " .. nome .. " fechado")
        end
    end
    menuAberto = nil
    print("📱 GUI: Todos os menus fechados")
end

-- Função para alternar visibilidade de um menu
local function AlternarMenu(nomeMenu)
    print("📱 GUI: Alternando menu: " .. nomeMenu)
    
    local menu = frames[nomeMenu]
    if not menu then
        warn("📱 GUI: ❌ ERRO: Menu não encontrado: " .. nomeMenu)
        return
    end
    
    print("📱 GUI: Estado atual do menu " .. nomeMenu .. ": Visible = " .. tostring(menu.Visible))
    
    -- CORREÇÃO: Fechar todos os menus primeiro, independente do estado
    FecharTodosMenus()
    
    -- FORÇAR a abertura do menu clicado (não verificar se já está aberto)
    menu.Visible = true
    menuAberto = nomeMenu
    print("📱 GUI: FORÇANDO abertura do menu: " .. nomeMenu)
    
    -- Verificação adicional para garantir que o menu foi aberto
    if menu.Visible then
        print("📱 GUI: ✅ Menu " .. nomeMenu .. " confirmado como visível")
    else
        warn("📱 GUI: ❌ ERRO: Menu " .. nomeMenu .. " não ficou visível após tentativa de abertura!")
    end
    
    -- Tratamento especial para o Inventário
    if nomeMenu == "InventarioFrame" then
        print("📱 GUI: Tratamento especial para Inventário - verificando elementos...")
        
        -- Verificar se o frame tem filhos
        local numFilhos = #menu:GetChildren()
        print("📱 GUI: InventarioFrame tem " .. numFilhos .. " elementos filhos")
        
        -- Garantir que está visível
        menu.Visible = true
        print("📱 GUI: InventarioFrame.Visible definido como true")
        
        -- Se não tiver elementos, criar um texto temporário
        if numFilhos < 2 then
            print("📱 GUI: Criando texto temporário no InventarioFrame para debug")
            local textoTemp = Instance.new("TextLabel")
            textoTemp.Name = "TextoTemporario"
            textoTemp.Size = UDim2.new(0.8, 0, 0.2, 0)
            textoTemp.Position = UDim2.new(0.1, 0, 0.4, 0)
            textoTemp.BackgroundTransparency = 0.5
            textoTemp.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            textoTemp.TextColor3 = Color3.new(1, 1, 1)
            textoTemp.TextSize = 24
            textoTemp.Font = Enum.Font.SourceSansBold
            textoTemp.Text = "Inventário - Frame Visível"
            textoTemp.Parent = menu
        end
    end
    
    -- Notificar o servidor (opcional)
    alternarFrameEvent:FireServer(nomeMenu)
end

-- Função para atualizar o HUD com novos valores
local function AtualizarHUD(novasMoedas, novoNivel)
    moedas.Text = tostring(novasMoedas or 0)
    nivel.Text = tostring(novoNivel or 1)
    print("📱 GUI: HUD atualizado - Moedas: " .. moedas.Text .. ", Nível: " .. nivel.Text)
end

-- Conectar eventos remotos
atualizarHUDEvent.OnClientEvent:Connect(function(novasMoedas, novoNivel)
    print("📱 GUI: Evento AtualizarHUD recebido")
    AtualizarHUD(novasMoedas, novoNivel)
end)

-- Conectar botões aos menus correspondentes
botoes.BotaoLoja.MouseButton1Click:Connect(function()
    print("📱 GUI: Botão Loja clicado")
    AlternarMenu("LojaFrame")
end)

botoes.BotaoInventario.MouseButton1Click:Connect(function()
    print("📱 GUI: Botão Inventário clicado")
    print("📱 GUI: CHAMANDO AlternarMenu para InventarioFrame")
    AlternarMenu("InventarioFrame")
    
    -- Verificação adicional após o clique
    wait(0.1) -- Pequena espera para garantir que a interface atualizou
    if frames.InventarioFrame and frames.InventarioFrame.Visible then
        print("📱 GUI: ✅ SUCESSO: InventarioFrame está visível após clique")
    else
        warn("📱 GUI: ❌ ERRO: InventarioFrame NÃO está visível após clique!")
    end
end)

botoes.BotaoMissoes.MouseButton1Click:Connect(function()
    print("📱 GUI: Botão Missões clicado")
    AlternarMenu("MissoesFrame")
end)

botoes.BotaoConstrucao.MouseButton1Click:Connect(function()
    print("📱 GUI: Botão Construção clicado")
    AlternarMenu("ConstrucaoFrame")
end)

botoes.BotaoSocial.MouseButton1Click:Connect(function()
    print("📱 GUI: Botão Social clicado")
    AlternarMenu("SocialFrame")
end)

botoes.BotaoConfiguracoes.MouseButton1Click:Connect(function()
    print("📱 GUI: Botão Configurações clicado")
    AlternarMenu("ConfiguracoesFrame")
end)

-- Inicialização
FecharTodosMenus()
AtualizarHUD(100, 1) -- Valores iniciais para testes

print("📱 GUI: Script de interface inicializado com sucesso!")
