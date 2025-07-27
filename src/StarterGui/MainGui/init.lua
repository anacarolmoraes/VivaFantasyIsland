--[[
    MainGui/init_simples.lua
    
    Script cliente simplificado para gerenciar a interface do jogo "Viva Fantasy Island"
    Versão básica para testes iniciais, focada em fazer os botões funcionarem.
    
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
        frame.Visible = false
    end
    menuAberto = nil
    print("📱 GUI: Todos os menus fechados")
end

-- Função para alternar visibilidade de um menu
local function AlternarMenu(nomeMenu)
    print("📱 GUI: Alternando menu: " .. nomeMenu)
    
    local menu = frames[nomeMenu]
    if not menu then
        warn("📱 GUI: Menu não encontrado: " .. nomeMenu)
        return
    end
    
    -- Se o menu clicado já está aberto, feche-o
    if menu.Visible then
        menu.Visible = false
        menuAberto = nil
        print("📱 GUI: Menu fechado: " .. nomeMenu)
        return
    end
    
    -- Feche todos os menus primeiro
    FecharTodosMenus()
    
    -- Abra o menu clicado
    menu.Visible = true
    menuAberto = nomeMenu
    print("📱 GUI: Menu aberto: " .. nomeMenu)
    
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
    AlternarMenu("InventarioFrame")
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
