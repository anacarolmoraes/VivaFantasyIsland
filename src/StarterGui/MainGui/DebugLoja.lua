--[[
    DebugLoja.lua
    
    Script de diagnóstico para identificar problemas na comunicação da loja
    Verifica RemoteEvents, monitora comunicação cliente-servidor e mostra logs detalhados
    
    Autor: Factory AI
    Data: 27/07/2025
]]

-- Serviços do Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Jogador local
local jogador = Players.LocalPlayer
local personagem = jogador.Character or jogador.CharacterAdded:Wait()

-- Referências à GUI
local mainGui = script.Parent
local lojaFrame = mainGui:WaitForChild("LojaFrame")

-- Lista de RemoteEvents necessários
local remoteEventsNecessarios = {
    "AtualizarHUD",
    "AlternarFrame",
    "ComprarItem",
    "CompletarMissao",
    "ColocarDecoracao",
    "RemoverDecoracao"
}

-- Variáveis de estado para debug
local debugInfo = {
    remoteEventsEncontrados = {},
    ultimaCompra = nil,
    tempoInicioCompra = 0,
    respostaRecebida = false,
    tempoResposta = 0
}

-- Função para log de debug com prefixo e cor
local function LogDebug(mensagem, tipo)
    tipo = tipo or "info"
    
    local prefixo = "🔍 DEBUG LOJA: "
    local cor = ""
    
    if tipo == "erro" then
        prefixo = "❌ ERRO LOJA: "
        cor = "rgb(255, 100, 100)"
    elseif tipo == "sucesso" then
        prefixo = "✅ SUCESSO LOJA: "
        cor = "rgb(100, 255, 100)"
    elseif tipo == "aviso" then
        prefixo = "⚠️ AVISO LOJA: "
        cor = "rgb(255, 255, 100)"
    end
    
    if cor ~= "" then
        print(string.format('<font color="%s">%s%s</font>', cor, prefixo, mensagem))
    else
        print(prefixo .. mensagem)
    end
end

-- Função para verificar se os RemoteEvents existem
local function VerificarRemoteEvents()
    LogDebug("Iniciando verificação de RemoteEvents...")
    
    -- Verificar se a pasta RemoteEvents existe
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        LogDebug("Pasta RemoteEvents não encontrada em ReplicatedStorage!", "erro")
        return false
    end
    
    -- Verificar cada RemoteEvent necessário
    local todosEncontrados = true
    for _, nomeEvento in ipairs(remoteEventsNecessarios) do
        local evento = remoteEventsFolder:FindFirstChild(nomeEvento)
        if evento then
            debugInfo.remoteEventsEncontrados[nomeEvento] = true
            LogDebug("RemoteEvent '" .. nomeEvento .. "' encontrado", "sucesso")
        else
            debugInfo.remoteEventsEncontrados[nomeEvento] = false
            LogDebug("RemoteEvent '" .. nomeEvento .. "' NÃO encontrado!", "erro")
            todosEncontrados = false
        end
    end
    
    return todosEncontrados
end

-- Função para monitorar o botão de compra
local function MonitorarBotaoCompra()
    -- Tentar encontrar o botão de compra na interface da loja
    local botaoComprar = nil
    
    -- Procurar por um botão com nome "BotaoComprar"
    botaoComprar = lojaFrame:FindFirstChild("DetalhesFrame", true) and 
                   lojaFrame.DetalhesFrame:FindFirstChild("BotaoComprar", true)
    
    -- Se não encontrar por nome, tentar por texto
    if not botaoComprar then
        for _, obj in pairs(lojaFrame:GetDescendants()) do
            if obj:IsA("TextButton") and (obj.Text == "COMPRAR" or obj.Text:find("COMPRAR") or obj.Text:find("Comprar")) then
                botaoComprar = obj
                break
            end
        end
    end
    
    if not botaoComprar then
        LogDebug("Botão de compra não encontrado na interface!", "aviso")
        return
    end
    
    -- Conectar ao evento de clique
    LogDebug("Monitorando botão de compra: " .. botaoComprar.Name)
    
    botaoComprar.MouseButton1Click:Connect(function()
        LogDebug("Botão COMPRAR clicado!")
        debugInfo.tempoInicioCompra = tick()
        debugInfo.respostaRecebida = false
        
        -- Verificar se o texto muda para "PROCESSANDO..."
        if botaoComprar.Text == "PROCESSANDO..." then
            LogDebug("Botão mudou para 'PROCESSANDO...'", "info")
        end
        
        -- Iniciar timer para verificar resposta
        spawn(function()
            wait(5) -- Esperar 5 segundos
            if not debugInfo.respostaRecebida then
                LogDebug("TIMEOUT: Nenhuma resposta recebida do servidor após 5 segundos!", "erro")
                LogDebug("Provável causa: RemoteEvent 'ComprarItem' não existe ou não está conectado no servidor", "erro")
            end
        end)
    end)
end

-- Função para criar interface de debug
local function CriarInterfaceDebug()
    -- Criar frame de debug
    local debugFrame = Instance.new("Frame")
    debugFrame.Name = "DebugFrame"
    debugFrame.Size = UDim2.new(0, 200, 0, 300)
    debugFrame.Position = UDim2.new(0, 10, 0, 10)
    debugFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    debugFrame.BackgroundTransparency = 0.5
    debugFrame.Visible = false -- Inicialmente invisível
    debugFrame.Parent = mainGui
    
    -- Título
    local titulo = Instance.new("TextLabel")
    titulo.Name = "Titulo"
    titulo.Size = UDim2.new(1, 0, 0, 30)
    titulo.Position = UDim2.new(0, 0, 0, 0)
    titulo.BackgroundTransparency = 0.5
    titulo.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    titulo.TextColor3 = Color3.new(1, 1, 1)
    titulo.TextSize = 14
    titulo.Font = Enum.Font.SourceSansBold
    titulo.Text = "Debug Loja"
    titulo.Parent = debugFrame
    
    -- Botão para testar comunicação
    local botaoTesteCompra = Instance.new("TextButton")
    botaoTesteCompra.Name = "BotaoTesteCompra"
    botaoTesteCompra.Size = UDim2.new(0.8, 0, 0, 30)
    botaoTesteCompra.Position = UDim2.new(0.1, 0, 0, 40)
    botaoTesteCompra.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    botaoTesteCompra.TextColor3 = Color3.new(1, 1, 1)
    botaoTesteCompra.TextSize = 14
    botaoTesteCompra.Font = Enum.Font.SourceSansBold
    botaoTesteCompra.Text = "Testar ComprarItem"
    botaoTesteCompra.Parent = debugFrame
    
    -- Conectar evento de teste
    botaoTesteCompra.MouseButton1Click:Connect(function()
        TestarComprarItem()
    end)
    
    -- Botão para mostrar/esconder debug
    local botaoToggleDebug = Instance.new("TextButton")
    botaoToggleDebug.Name = "BotaoToggleDebug"
    botaoToggleDebug.Size = UDim2.new(0, 100, 0, 30)
    botaoToggleDebug.Position = UDim2.new(0, 10, 0, 10)
    botaoToggleDebug.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    botaoToggleDebug.TextColor3 = Color3.new(1, 1, 1)
    botaoToggleDebug.TextSize = 12
    botaoToggleDebug.Font = Enum.Font.SourceSansBold
    botaoToggleDebug.Text = "Debug Loja"
    botaoToggleDebug.BackgroundTransparency = 0.3
    botaoToggleDebug.Parent = mainGui
    
    botaoToggleDebug.MouseButton1Click:Connect(function()
        debugFrame.Visible = not debugFrame.Visible
    end)
    
    return debugFrame
end

-- Função para testar o RemoteEvent ComprarItem diretamente
function TestarComprarItem()
    LogDebug("Testando RemoteEvent 'ComprarItem'...")
    
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        LogDebug("Pasta RemoteEvents não encontrada!", "erro")
        return
    end
    
    local comprarItemEvent = remoteEventsFolder:FindFirstChild("ComprarItem")
    if not comprarItemEvent then
        LogDebug("RemoteEvent 'ComprarItem' não encontrado!", "erro")
        return
    end
    
    -- Registrar tempo de início
    debugInfo.tempoInicioCompra = tick()
    debugInfo.respostaRecebida = false
    
    -- Disparar evento com dados de teste
    LogDebug("Enviando evento 'ComprarItem' para o servidor...")
    comprarItemEvent:FireServer("arvore_pequena", "plantas")
    
    -- Iniciar timer para verificar resposta
    spawn(function()
        wait(5) -- Esperar 5 segundos
        if not debugInfo.respostaRecebida then
            LogDebug("TIMEOUT: Nenhuma resposta recebida do servidor após 5 segundos!", "erro")
            LogDebug("Verifique se o servidor está processando o evento 'ComprarItem'", "erro")
            LogDebug("Possíveis causas:", "erro")
            LogDebug("1. Não há OnServerEvent:Connect() para 'ComprarItem' no servidor", "erro")
            LogDebug("2. O servidor está com erro ao processar a compra", "erro")
            LogDebug("3. O servidor não está enviando resposta de volta", "erro")
        end
    end)
end

-- Função para monitorar respostas do servidor
local function MonitorarRespostasServidor()
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then return end
    
    local comprarItemEvent = remoteEventsFolder:FindFirstChild("ComprarItem")
    if not comprarItemEvent then return end
    
    -- Monitorar respostas do servidor
    comprarItemEvent.OnClientEvent:Connect(function(sucesso, itemId, novasMoedas, mensagem)
        debugInfo.respostaRecebida = true
        debugInfo.tempoResposta = tick() - debugInfo.tempoInicioCompra
        
        if sucesso then
            LogDebug("Resposta do servidor recebida em " .. string.format("%.2f", debugInfo.tempoResposta) .. "s", "sucesso")
            LogDebug("Compra bem-sucedida: " .. mensagem, "sucesso")
            LogDebug("Novas moedas: " .. tostring(novasMoedas), "info")
        else
            LogDebug("Resposta do servidor recebida em " .. string.format("%.2f", debugInfo.tempoResposta) .. "s", "aviso")
            LogDebug("Compra falhou: " .. mensagem, "aviso")
        end
    end)
    
    LogDebug("Monitoramento de respostas do servidor configurado", "sucesso")
end

-- Função para verificar se o script LojaGui.lua está presente e ativo
local function VerificarLojaGui()
    local lojaGui = mainGui:FindFirstChild("LojaGui")
    
    if not lojaGui then
        LogDebug("Script 'LojaGui' não encontrado em MainGui!", "erro")
        LogDebug("Certifique-se de que o script 'LojaGui.lua' foi adicionado como LocalScript em StarterGui/MainGui", "erro")
        return false
    end
    
    if not lojaGui.Enabled then
        LogDebug("Script 'LojaGui' está desabilitado!", "erro")
        LogDebug("Certifique-se de que a propriedade 'Enabled' está marcada como true", "erro")
        return false
    end
    
    LogDebug("Script 'LojaGui' encontrado e ativo", "sucesso")
    return true
end

-- Função para verificar se o EconomiaModule está processando compras
local function VerificarEconomiaModule()
    -- Não podemos verificar diretamente do cliente, mas podemos dar dicas
    LogDebug("Verificando se EconomiaModule está configurado corretamente...")
    LogDebug("NOTA: Esta é apenas uma verificação de configuração, não podemos acessar o servidor diretamente", "aviso")
    
    -- Verificar se o jogador tem moedas (indicação de que EconomiaModule inicializou)
    local moedas = tonumber(mainGui.HUD.MoedasFrame.ValorMoedas.Text) or 0
    if moedas > 0 then
        LogDebug("Jogador tem " .. moedas .. " moedas - EconomiaModule provavelmente inicializou", "sucesso")
    else
        LogDebug("Jogador tem 0 moedas - EconomiaModule pode não ter inicializado corretamente", "aviso")
    end
    
    -- Dicas para verificação no servidor
    LogDebug("Para verificar no servidor, procure por estas mensagens no Output:")
    LogDebug("1. 'Módulo de economia inicializado com sucesso!'")
    LogDebug("2. 'ComprarItemEvent.OnServerEvent:Connect()' deve estar configurado")
    LogDebug("3. 'ProcessarCompraItem()' deve ser chamado quando o evento é disparado")
end

-- Inicializar o script de debug
local function Inicializar()
    LogDebug("=== INICIANDO DEBUG DA LOJA ===", "info")
    
    -- Verificar RemoteEvents
    local remoteEventsOk = VerificarRemoteEvents()
    if not remoteEventsOk then
        LogDebug("Problema encontrado com RemoteEvents! Verifique os erros acima.", "erro")
    end
    
    -- Verificar LojaGui
    local lojaGuiOk = VerificarLojaGui()
    
    -- Criar interface de debug
    local debugFrame = CriarInterfaceDebug()
    
    -- Monitorar botão de compra
    MonitorarBotaoCompra()
    
    -- Monitorar respostas do servidor
    MonitorarRespostasServidor()
    
    -- Verificar EconomiaModule
    VerificarEconomiaModule()
    
    LogDebug("=== DEBUG DA LOJA INICIALIZADO ===", "sucesso")
    LogDebug("Clique no botão 'Debug Loja' para mostrar ferramentas de diagnóstico", "info")
end

-- Iniciar quando o script carregar
Inicializar()
