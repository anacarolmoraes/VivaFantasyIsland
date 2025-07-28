local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Importar módulos
local DataStoreModule = require(ServerStorage.Modules.DataStoreModule)

-- Configuração
local INICIAL_DREAMCOINS = 1000
local LIMITE_TRANSACAO = 10000
local TEMPO_COOLDOWN_COMPRA = 1 -- segundos

-- Eventos remotos
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ComprarItemEvent = RemoteEvents:WaitForChild("ComprarItem")
local AtualizarDreamCoinsEvent = RemoteEvents:WaitForChild("AtualizarDreamCoins")
local AtualizarInventarioEvent = RemoteEvents:WaitForChild("AtualizarInventario")

-- Módulo de economia
local EconomiaModule = {}

-- Dados em memória
local dreamCoins = {} -- {[userId] = quantidade}
local ultimasTransacoes = {} -- {[userId] = {timestamp, valor}}
local cooldownCompra = {} -- {[userId] = timestamp}

-- Contadores para estatísticas
local estatisticas = {
    transacoes = 0,
    compras = 0,
    vendas = 0,
    erros = 0
}

--[[-------------------------------------------------------------------------
    Catálogo de preços
    NOTA: deve ser mantido em **servidor** para evitar exploits.
---------------------------------------------------------------------------]]
local CATALOGO_ITENS = {
    -- decoracoes
    cerca_madeira     = 50,
    pedra_decorativa  = 30,
    estatua_pequena   = 150,
    fonte_pedra       = 250,
    luminaria_jardim  = 120,
    banco_parque      = 100,
    caixa_correio     = 80,
    estatua_grande    = 400,
    poste_sinalizacao = 75,
    -- moveis
    mesa_madeira      = 120,
    cadeira_simples   = 80,
    sofa_moderno      = 200,
    estante_livros    = 180,
    cama_simples      = 150,
    -- plantas
    arvore_pequena    = 100,
    flor_azul         = 45,
    arvore_grande     = 250,
    arbusto_flores    = 75,
    palmeira          = 180,
    jardim_flores     = 120,
    -- especiais
    portal_magico     = 500,
    cristal_energia   = 350,
    altar_mistico     = 600,
    -- ferramentas
    martelo_construcao= 200,
    pa_jardinagem     = 150,
    regador           = 100
}

-- Inventário básico na memória {[userId] = { [itemId] = quantidade }}
local inventarios = {}

--[[
    Inicializa o módulo de economia
    Configura eventos remotos e outras dependências
]]
function EconomiaModule.Inicializar()
    print("EconomiaModule: Inicializando...")
    
    -- Configurar eventos remotos
    ComprarItemEvent.OnServerEvent:Connect(function(player, itemId)
        local sucesso, mensagem = EconomiaModule.ProcessarCompra(player, itemId)
        
        -- Confirmar resultado para o cliente
        ComprarItemEvent:FireClient(player, sucesso, mensagem, itemId)
    end)
    
    -- Configurar eventos de jogador
    Players.PlayerAdded:Connect(function(player)
        EconomiaModule.CarregarDadosJogador(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        EconomiaModule.SalvarDadosJogador(player)
    end)
    
    print("EconomiaModule: Inicializado com sucesso!")
    return true
end

--[[
    Carrega os dados econômicos do jogador do DataStore
    Configura valores iniciais se necessário
]]
function EconomiaModule.CarregarDadosJogador(player)
    local userId = player.UserId
    
    -- Carregar DreamCoins
    local dadosEconomia = DataStoreModule:CarregarDados(player, "Economia")
    
    if dadosEconomia and dadosEconomia.dreamCoins then
        dreamCoins[userId] = dadosEconomia.dreamCoins
    else
        -- Valor inicial para novos jogadores
        dreamCoins[userId] = INICIAL_DREAMCOINS
    end
    
    -- Carregar inventário
    local dadosInventario = DataStoreModule:CarregarDados(player, "Inventario")
    
    if dadosInventario and dadosInventario.itens then
        inventarios[userId] = dadosInventario.itens
    else
        -- Inventário vazio para novos jogadores
        inventarios[userId] = {}
    end
    
    -- Notificar cliente
    AtualizarDreamCoinsEvent:FireClient(player, dreamCoins[userId])
    AtualizarInventarioEvent:FireClient(player, inventarios[userId])
    
    print("EconomiaModule: Dados carregados para " .. player.Name)
end

--[[
    Salva os dados econômicos do jogador no DataStore
]]
function EconomiaModule.SalvarDadosJogador(player)
    local userId = player.UserId
    
    -- Salvar apenas se temos dados para este jogador
    if dreamCoins[userId] then
        local dadosEconomia = {
            dreamCoins = dreamCoins[userId]
        }
        
        DataStoreModule:SalvarDados(player, "Economia", dadosEconomia)
    end
    
    -- Salvar inventário
    if inventarios[userId] then
        local dadosInventario = {
            itens = inventarios[userId]
        }
        
        DataStoreModule:SalvarDados(player, "Inventario", dadosInventario)
    end
    
    -- Limpar dados da memória
    dreamCoins[userId] = nil
    inventarios[userId] = nil
    ultimasTransacoes[userId] = nil
    cooldownCompra[userId] = nil
    
    print("EconomiaModule: Dados salvos para " .. player.Name)
end

--[[
    Processa a compra de um item pelo jogador
    Verifica se o jogador tem DreamCoins suficientes
    Atualiza o inventário e notifica o cliente
]]
function EconomiaModule.ProcessarCompra(player, itemId)
    local userId = player.UserId
    
    -- Verificar cooldown para evitar spam de compras
    if cooldownCompra[userId] and tick() - cooldownCompra[userId] < TEMPO_COOLDOWN_COMPRA then
        return false, "Aguarde um momento para fazer outra compra"
    end
    
    -- Verificar se o item existe no catálogo
    local preco = CATALOGO_ITENS[itemId]
    if not preco then
        estatisticas.erros = estatisticas.erros + 1
        return false, "Item não encontrado no catálogo"
    end
    
    -- Verificar se o jogador tem DreamCoins suficientes
    if not dreamCoins[userId] or dreamCoins[userId] < preco then
        return false, "DreamCoins insuficientes"
    end
    
    -- Atualizar cooldown
    cooldownCompra[userId] = tick()
    
    -- Processar a transação
    dreamCoins[userId] = dreamCoins[userId] - preco
    
    -- Atualizar inventário
    if not inventarios[userId] then
        inventarios[userId] = {}
    end
    
    -- Adicionar item ao inventário
    inventarios[userId][itemId] = (inventarios[userId][itemId] or 0) + 1
    
    -- Atualizar estatísticas
    estatisticas.transacoes = estatisticas.transacoes + 1
    estatisticas.compras = estatisticas.compras + 1
    
    -- Registrar transação para detecção de exploits
    ultimasTransacoes[userId] = {tick(), preco}
    
    -- Notificar cliente
    AtualizarDreamCoinsEvent:FireClient(player, dreamCoins[userId])
    AtualizarInventarioEvent:FireClient(player, inventarios[userId])
    
    print("EconomiaModule: Compra processada - " .. player.Name .. " comprou " .. itemId)
    return true, "Item comprado com sucesso!"
end

--[[
    Obtém o inventário de um jogador
]]
function EconomiaModule.ObterInventario(player)
    local userId = player.UserId
    return inventarios[userId] or {}
end

--[[
    Obtém a quantidade de DreamCoins de um jogador
]]
function EconomiaModule.ObterDreamCoins(player)
    local userId = player.UserId
    return dreamCoins[userId] or 0
end

--[[
    Adiciona DreamCoins a um jogador
    Utilizado para recompensas, missões, etc.
]]
function EconomiaModule.AdicionarDreamCoins(player, quantidade)
    if not player or not quantidade or quantidade <= 0 then
        return false
    end
    
    local userId = player.UserId
    
    -- Verificar limite de transação para evitar exploits
    if quantidade > LIMITE_TRANSACAO then
        warn("EconomiaModule: Tentativa de adicionar valor acima do limite: " .. quantidade)
        quantidade = LIMITE_TRANSACAO
    end
    
    -- Atualizar DreamCoins
    if not dreamCoins[userId] then
        dreamCoins[userId] = INICIAL_DREAMCOINS
    end
    
    dreamCoins[userId] = dreamCoins[userId] + quantidade
    
    -- Notificar cliente
    AtualizarDreamCoinsEvent:FireClient(player, dreamCoins[userId])
    
    -- Atualizar estatísticas
    estatisticas.transacoes = estatisticas.transacoes + 1
    
    print("EconomiaModule: " .. quantidade .. " DreamCoins adicionados para " .. player.Name)
    return true
end

--[[
    Obtém o catálogo de itens disponíveis para compra
]]
function EconomiaModule.ObterCatalogo()
    return CATALOGO_ITENS
end

return EconomiaModule
