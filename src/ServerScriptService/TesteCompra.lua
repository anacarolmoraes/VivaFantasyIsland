--[[
    TesteCompra.lua
    
    Script de teste isolado para diagnosticar problemas de comunicação
    na funcionalidade de compra da loja. Este script cria e conecta
    diretamente ao RemoteEvent "ComprarItem" sem depender do EconomiaModule.
    
    Autor: Factory AI
    Data: 27/07/2025
]]

-- Serviços do Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variáveis de estado para debug
local comprasProcessadas = 0
local ultimasCompras = {}

-- Função para log com prefixo e timestamp
local function Log(mensagem, tipo)
    local prefixo = "[TESTE COMPRA] "
    local timestamp = os.date("%H:%M:%S")
    
    if tipo == "erro" then
        warn(prefixo .. timestamp .. " ERRO: " .. mensagem)
    elseif tipo == "sucesso" then
        print(prefixo .. timestamp .. " SUCESSO: " .. mensagem)
    else
        print(prefixo .. timestamp .. " INFO: " .. mensagem)
    end
end

-- Função para garantir que o RemoteEvent existe
local function GarantirRemoteEvent()
    Log("Verificando RemoteEvent 'ComprarItem'...")
    
    -- Verificar se a pasta RemoteEvents existe
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        Log("Pasta RemoteEvents não encontrada, criando...", "erro")
        remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = ReplicatedStorage
    end
    
    -- Verificar se o RemoteEvent ComprarItem existe
    local comprarItemEvent = remoteEventsFolder:FindFirstChild("ComprarItem")
    if not comprarItemEvent then
        Log("RemoteEvent 'ComprarItem' não encontrado, criando...", "erro")
        comprarItemEvent = Instance.new("RemoteEvent")
        comprarItemEvent.Name = "ComprarItem"
        comprarItemEvent.Parent = remoteEventsFolder
    else
        Log("RemoteEvent 'ComprarItem' encontrado!", "sucesso")
    end
    
    return comprarItemEvent
end

-- Função para processar compra (versão simplificada)
local function ProcessarCompra(player, itemId)
    -- Validar parâmetros
    if not player or not itemId then
        Log("Parâmetros inválidos: " .. tostring(player) .. ", " .. tostring(itemId), "erro")
        return false
    end
    
    Log("Processando compra para " .. player.Name .. ": " .. itemId)
    
    -- Registrar compra para debug
    comprasProcessadas = comprasProcessadas + 1
    table.insert(ultimasCompras, {
        jogador = player.Name,
        item = itemId,
        timestamp = os.time()
    })
    
    -- Manter apenas as últimas 10 compras
    if #ultimasCompras > 10 then
        table.remove(ultimasCompras, 1)
    end
    
    -- Simular processamento
    wait(0.5) -- Simular algum processamento
    
    -- Simular verificação de moedas (sempre sucesso neste teste)
    local temMoedas = true
    local moedasAtuais = 100 -- Valor fixo para teste
    
    if temMoedas then
        Log("Compra aprovada para " .. player.Name .. ": " .. itemId, "sucesso")
        return true, moedasAtuais - 50 -- Simular gasto de 50 moedas
    else
        Log("Moedas insuficientes para " .. player.Name, "erro")
        return false, moedasAtuais
    end
end

-- Função principal
local function Inicializar()
    Log("Iniciando script de teste de compras...")
    
    -- Garantir que o RemoteEvent existe
    local comprarItemEvent = GarantirRemoteEvent()
    
    -- Conectar ao evento
    comprarItemEvent.OnServerEvent:Connect(function(player, itemId)
        Log("Evento recebido de " .. player.Name .. " para comprar: " .. tostring(itemId))
        
        -- Processar compra
        local sucesso, novasMoedas = ProcessarCompra(player, itemId)
        
        -- Enviar resposta ao cliente
        Log("Enviando resposta ao cliente: " .. (sucesso and "SUCESSO" or "FALHA"))
        comprarItemEvent:FireClient(
            player, 
            sucesso, 
            itemId, 
            novasMoedas,
            sucesso and "Compra de teste realizada com sucesso!" or "Falha na compra de teste (moedas insuficientes)"
        )
    end)
    
    -- Informar status no Output
    Log("Script de teste conectado ao RemoteEvent 'ComprarItem'", "sucesso")
    Log("Aguardando solicitações de compra...", "sucesso")
    Log("Para testar, use ComprarItem:FireServer('item_teste') no cliente", "sucesso")
    
    -- Criar loop para mostrar estatísticas a cada 30 segundos
    spawn(function()
        while wait(30) do
            Log("Estatísticas: " .. comprasProcessadas .. " compras processadas")
            
            if #ultimasCompras > 0 then
                Log("Últimas compras:")
                for i, compra in ipairs(ultimasCompras) do
                    local tempoPassado = os.time() - compra.timestamp
                    Log("  " .. i .. ". " .. compra.jogador .. " comprou " .. compra.item .. " há " .. tempoPassado .. "s")
                end
            end
        end
    end)
end

-- Iniciar o script
Inicializar()
