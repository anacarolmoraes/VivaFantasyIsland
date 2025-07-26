--[[
    EconomiaModule.lua
    
    Módulo responsável pelo gerenciamento da economia do jogo "Viva Fantasy Island"
    Controla o sistema de moedas (DreamCoins), transações e recompensas
    
    Autor: Factory AI
    Data: 26/07/2025
]]

-- Serviços do Roblox
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Variáveis e constantes do módulo
local EconomiaModule = {}
local jogadoresMoedas = {} -- Tabela para armazenar as moedas dos jogadores {[UserId] = quantidade}
local MOEDAS_INICIAIS = 100 -- Quantidade inicial de moedas para novos jogadores
local LIMITE_TRANSACAO = 10000 -- Limite máximo para uma única transação
local INTERVALO_ATUALIZACAO_GUI = 0.5 -- Intervalo em segundos para atualizar a GUI do cliente

-- Eventos Remotos
local RemoteEvents
local AtualizarMoedasEvent

-- Configurações de recompensas
local RECOMPENSAS = {
    LOGIN_DIARIO = 10,
    MISSAO_DIARIA = 25,
    MISSAO_SEMANAL = 100,
    VISITA_RECEBIDA = 5,
    LIKE_RECEBIDO = 2,
    NIVEL_ALCANCADO = function(nivel) return nivel * 15 end
}

-- Histórico de transações para auditoria e prevenção de fraudes
local historicoTransacoes = {}

--[[
    Inicializa o módulo de economia
    Configura eventos remotos e outras dependências
]]
function EconomiaModule.Inicializar()
    print("Inicializando módulo de economia...")
    
    -- Obter referência aos eventos remotos
    RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
    AtualizarMoedasEvent = RemoteEvents:WaitForChild("AtualizarMoedas")
    
    -- Configurar eventos de comunicação com o cliente
    AtualizarMoedasEvent.OnServerEvent:Connect(function(player, acao)
        -- Ignorar eventos do cliente para evitar exploits
        -- Apenas o servidor pode modificar moedas
        warn("Tentativa de modificação de moedas pelo cliente: " .. player.Name)
    end)
    
    -- Configurar sistema de recompensas automáticas
    ConfigurarRecompensasAutomaticas()
    
    print("Módulo de economia inicializado com sucesso!")
    return true
end

--[[
    Inicializa a economia para um jogador específico
    @param player (Player) - Objeto do jogador
    @param moedasIniciais (number) - Quantidade inicial de moedas (opcional)
]]
function EconomiaModule.InicializarJogador(player, moedasIniciais)
    local userId = player.UserId
    
    -- Verificar se o jogador já está inicializado
    if jogadoresMoedas[userId] then
        return
    end
    
    -- Definir moedas iniciais
    jogadoresMoedas[userId] = moedasIniciais or MOEDAS_INICIAIS
    
    -- Registrar transação inicial
    RegistrarTransacao(userId, "INICIAL", moedasIniciais or MOEDAS_INICIAIS, "Moedas iniciais")
    
    -- Notificar cliente
    AtualizarGUICliente(player)
    
    print("Economia inicializada para jogador: " .. player.Name .. " com " .. jogadoresMoedas[userId] .. " DreamCoins")
end

--[[
    Adiciona moedas à conta do jogador
    @param player (Player/number) - Jogador ou UserId
    @param quantidade (number) - Quantidade de moedas a adicionar
    @param motivo (string) - Motivo da adição (para registro)
    @return (boolean) - Sucesso da operação
]]
function EconomiaModule.AdicionarMoedas(player, quantidade, motivo)
    -- Validar parâmetros
    if not ValidarParametros(player, quantidade) then
        return false
    end
    
    local userId = ObterUserId(player)
    if not userId then return false end
    
    -- Validar a transação
    if not ValidarTransacao(userId, "ADICIONAR", quantidade) then
        return false
    end
    
    -- Adicionar moedas
    jogadoresMoedas[userId] = jogadoresMoedas[userId] + quantidade
    
    -- Registrar transação
    RegistrarTransacao(userId, "ADICIONAR", quantidade, motivo or "Adição de moedas")
    
    -- Atualizar GUI do cliente
    local playerObj = type(player) == "number" and Players:GetPlayerByUserId(userId) or player
    if playerObj then
        AtualizarGUICliente(playerObj)
    end
    
    return true
end

--[[
    Remove moedas da conta do jogador
    @param player (Player/number) - Jogador ou UserId
    @param quantidade (number) - Quantidade de moedas a remover
    @param motivo (string) - Motivo da remoção (para registro)
    @return (boolean) - Sucesso da operação
]]
function EconomiaModule.RemoverMoedas(player, quantidade, motivo)
    -- Validar parâmetros
    if not ValidarParametros(player, quantidade) then
        return false
    end
    
    local userId = ObterUserId(player)
    if not userId then return false end
    
    -- Verificar se o jogador tem moedas suficientes
    if (jogadoresMoedas[userId] or 0) < quantidade then
        warn("Jogador " .. userId .. " não tem moedas suficientes. Tem: " .. 
              (jogadoresMoedas[userId] or 0) .. ", Tentou remover: " .. quantidade)
        return false
    end
    
    -- Validar a transação
    if not ValidarTransacao(userId, "REMOVER", quantidade) then
        return false
    end
    
    -- Remover moedas
    jogadoresMoedas[userId] = jogadoresMoedas[userId] - quantidade
    
    -- Registrar transação
    RegistrarTransacao(userId, "REMOVER", quantidade, motivo or "Remoção de moedas")
    
    -- Atualizar GUI do cliente
    local playerObj = type(player) == "number" and Players:GetPlayerByUserId(userId) or player
    if playerObj then
        AtualizarGUICliente(playerObj)
    end
    
    return true
end

--[[
    Obtém o saldo atual de moedas do jogador
    @param player (Player/number) - Jogador ou UserId
    @return (number) - Quantidade de moedas ou 0 se não encontrado
]]
function EconomiaModule.ObterMoedas(player)
    local userId = ObterUserId(player)
    if not userId then return 0 end
    
    return jogadoresMoedas[userId] or 0
end

--[[
    Verifica se o jogador tem moedas suficientes para uma compra
    @param player (Player/number) - Jogador ou UserId
    @param quantidade (number) - Quantidade necessária
    @return (boolean) - true se tiver moedas suficientes
]]
function EconomiaModule.TemMoedasSuficientes(player, quantidade)
    local userId = ObterUserId(player)
    if not userId then return false end
    
    return (jogadoresMoedas[userId] or 0) >= quantidade
end

--[[
    Processa uma compra, removendo moedas se houver saldo suficiente
    @param player (Player/number) - Jogador ou UserId
    @param quantidade (number) - Custo da compra
    @param itemId (string) - Identificador do item comprado
    @return (boolean) - Sucesso da compra
]]
function EconomiaModule.ProcessarCompra(player, quantidade, itemId)
    local userId = ObterUserId(player)
    if not userId then return false end
    
    -- Verificar se tem moedas suficientes
    if not EconomiaModule.TemMoedasSuficientes(player, quantidade) then
        return false
    end
    
    -- Remover moedas
    local sucesso = EconomiaModule.RemoverMoedas(player, quantidade, "Compra: " .. itemId)
    
    return sucesso
end

--[[
    Concede uma recompensa ao jogador
    @param player (Player/number) - Jogador ou UserId
    @param tipoRecompensa (string) - Tipo de recompensa (LOGIN_DIARIO, MISSAO_DIARIA, etc.)
    @param multiplicador (number) - Multiplicador opcional (padrão: 1)
    @return (number) - Quantidade de moedas adicionadas ou 0 se falhou
]]
function EconomiaModule.ConcederRecompensa(player, tipoRecompensa, multiplicador)
    multiplicador = multiplicador or 1
    
    -- Determinar quantidade da recompensa
    local quantidade = 0
    if type(RECOMPENSAS[tipoRecompensa]) == "function" then
        quantidade = RECOMPENSAS[tipoRecompensa](multiplicador)
    elseif RECOMPENSAS[tipoRecompensa] then
        quantidade = RECOMPENSAS[tipoRecompensa] * multiplicador
    else
        warn("Tipo de recompensa inválido: " .. tostring(tipoRecompensa))
        return 0
    end
    
    -- Adicionar moedas
    local sucesso = EconomiaModule.AdicionarMoedas(player, quantidade, "Recompensa: " .. tipoRecompensa)
    
    return sucesso and quantidade or 0
end

--[[
    Transfere moedas entre jogadores
    @param origem (Player/number) - Jogador de origem ou UserId
    @param destino (Player/number) - Jogador de destino ou UserId
    @param quantidade (number) - Quantidade a transferir
    @param motivo (string) - Motivo da transferência
    @return (boolean) - Sucesso da transferência
]]
function EconomiaModule.TransferirMoedas(origem, destino, quantidade, motivo)
    -- Validar parâmetros
    if not ValidarParametros(origem, quantidade) or not ValidarParametros(destino, 0) then
        return false
    end
    
    local origemId = ObterUserId(origem)
    local destinoId = ObterUserId(destino)
    
    if not origemId or not destinoId then
        return false
    end
    
    -- Verificar se é uma autotransferência
    if origemId == destinoId then
        warn("Tentativa de transferência para si mesmo: UserId " .. origemId)
        return false
    end
    
    -- Verificar se tem moedas suficientes
    if not EconomiaModule.TemMoedasSuficientes(origem, quantidade) then
        return false
    end
    
    -- Executar a transferência
    local removido = EconomiaModule.RemoverMoedas(origem, quantidade, "Transferência para " .. destinoId .. ": " .. (motivo or ""))
    if not removido then
        return false
    end
    
    local adicionado = EconomiaModule.AdicionarMoedas(destino, quantidade, "Transferência de " .. origemId .. ": " .. (motivo or ""))
    if not adicionado then
        -- Reverter a remoção se a adição falhar
        EconomiaModule.AdicionarMoedas(origem, quantidade, "Estorno de transferência falha")
        return false
    end
    
    return true
end

--[[
    Retorna o histórico de transações de um jogador
    @param player (Player/number) - Jogador ou UserId
    @param limite (number) - Número máximo de transações a retornar (opcional)
    @return (table) - Tabela com histórico de transações
]]
function EconomiaModule.ObterHistoricoTransacoes(player, limite)
    local userId = ObterUserId(player)
    if not userId then return {} end
    
    local historico = historicoTransacoes[userId] or {}
    
    -- Limitar quantidade de transações retornadas
    if limite and #historico > limite then
        local resultado = {}
        for i = #historico - limite + 1, #historico do
            table.insert(resultado, historico[i])
        end
        return resultado
    end
    
    return historico
end

-- Funções internas (privadas) do módulo --

--[[
    Valida os parâmetros básicos de uma transação
    @param player (Player/number) - Jogador ou UserId
    @param quantidade (number) - Quantidade de moedas
    @return (boolean) - true se os parâmetros são válidos
]]
function ValidarParametros(player, quantidade)
    -- Verificar se o jogador é válido
    if not player then
        warn("Jogador inválido na transação")
        return false
    end
    
    -- Verificar se a quantidade é válida
    if type(quantidade) ~= "number" or quantidade < 0 then
        warn("Quantidade inválida na transação: " .. tostring(quantidade))
        return false
    end
    
    return true
end

--[[
    Obtém o UserId a partir de um objeto Player ou número
    @param player (Player/number) - Jogador ou UserId
    @return (number) - UserId ou nil se inválido
]]
function ObterUserId(player)
    if type(player) == "number" then
        return player
    elseif typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    else
        warn("Tipo de jogador inválido: " .. typeof(player))
        return nil
    end
end

--[[
    Valida uma transação para evitar exploits e fraudes
    @param userId (number) - ID do jogador
    @param tipo (string) - Tipo da transação (ADICIONAR, REMOVER)
    @param quantidade (number) - Quantidade de moedas
    @return (boolean) - true se a transação é válida
]]
function ValidarTransacao(userId, tipo, quantidade)
    -- Verificar se o jogador existe no sistema
    if not jogadoresMoedas[userId] then
        warn("Jogador não inicializado na economia: " .. userId)
        return false
    end
    
    -- Verificar limite de transação
    if quantidade > LIMITE_TRANSACAO then
        warn("Transação excede o limite permitido: " .. quantidade .. " > " .. LIMITE_TRANSACAO)
        return false
    end
    
    -- Verificar por transações suspeitas (muitas transações em curto período)
    local historico = historicoTransacoes[userId]
    if historico then
        local transacoesRecentes = 0
        local tempoAtual = os.time()
        
        for i = #historico, 1, -1 do
            if tempoAtual - historico[i].timestamp < 60 then -- Últimos 60 segundos
                transacoesRecentes = transacoesRecentes + 1
                
                if transacoesRecentes > 20 then -- Mais de 20 transações por minuto é suspeito
                    warn("Muitas transações em curto período para UserId: " .. userId)
                    return false
                end
            else
                break -- Histórico está ordenado por tempo, então podemos parar
            end
        end
    end
    
    return true
end

--[[
    Registra uma transação no histórico
    @param userId (number) - ID do jogador
    @param tipo (string) - Tipo da transação
    @param quantidade (number) - Quantidade de moedas
    @param motivo (string) - Motivo da transação
]]
function RegistrarTransacao(userId, tipo, quantidade, motivo)
    if not historicoTransacoes[userId] then
        historicoTransacoes[userId] = {}
    end
    
    table.insert(historicoTransacoes[userId], {
        tipo = tipo,
        quantidade = quantidade,
        motivo = motivo,
        timestamp = os.time(),
        saldoResultante = jogadoresMoedas[userId]
    })
    
    -- Limitar tamanho do histórico (manter últimas 100 transações)
    if #historicoTransacoes[userId] > 100 then
        table.remove(historicoTransacoes[userId], 1)
    end
end

--[[
    Atualiza a GUI do cliente com o saldo atual
    @param player (Player) - Jogador a ser notificado
]]
function AtualizarGUICliente(player)
    if not player or not player:IsA("Player") then
        return
    end
    
    local userId = player.UserId
    local moedas = jogadoresMoedas[userId] or 0
    
    -- Enviar atualização para o cliente
    AtualizarMoedasEvent:FireClient(player, moedas)
end

--[[
    Configura o sistema de recompensas automáticas
    Inclui recompensas diárias, por tempo de jogo, etc.
]]
function ConfigurarRecompensasAutomaticas()
    -- Recompensa por tempo de jogo (a cada 15 minutos)
    spawn(function()
        while true do
            wait(900) -- 15 minutos
            
            for _, player in pairs(Players:GetPlayers()) do
                -- Verificar se o jogador está ativo (não AFK)
                local character = player.Character
                if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
                    EconomiaModule.AdicionarMoedas(player, 5, "Tempo de jogo (15 minutos)")
                end
            end
        end
    end)
end

--[[
    Limpa os dados de um jogador quando ele sai do jogo
    @param userId (number) - ID do jogador
]]
function EconomiaModule.LimparDadosJogador(userId)
    -- Não removemos os dados completamente para caso o jogador volte na mesma sessão
    -- Apenas marcamos para economizar memória em sessões longas
    if historicoTransacoes[userId] and #historicoTransacoes[userId] > 10 then
        -- Manter apenas as 10 transações mais recentes na memória
        local transacoesRecentes = {}
        for i = #historicoTransacoes[userId] - 9, #historicoTransacoes[userId] do
            table.insert(transacoesRecentes, historicoTransacoes[userId][i])
        end
        historicoTransacoes[userId] = transacoesRecentes
    end
end

-- Configurar limpeza automática quando jogadores saem
Players.PlayerRemoving:Connect(function(player)
    EconomiaModule.LimparDadosJogador(player.UserId)
end)

-- Retornar o módulo
return EconomiaModule
