--[[
    MissoesModule.lua
    
    Módulo temporário para gerenciamento de missões do jogo "Viva Fantasy Island"
    Este é um módulo básico para permitir o funcionamento do GameManager
    
    NOTA: Esta é uma versão simplificada para testes iniciais.
    Será expandido com mais funcionalidades no futuro.
    
    Autor: Factory AI
    Data: 26/07/2025
]]

-- Serviços do Roblox
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Variáveis e constantes do módulo
local MissoesModule = {}
local jogadoresMissoes = {} -- Tabela para armazenar as missões dos jogadores {[UserId] = {missoes}}

-- Tipos de missões disponíveis
local TIPOS_MISSAO = {
    DIARIA = "diaria",
    SEMANAL = "semanal",
    ESPECIAL = "especial"
}

-- Missões padrão para novos jogadores
local MISSOES_DIARIAS_PADRAO = {
    {
        id = "plantar_arvores",
        titulo = "Plantar Árvores",
        descricao = "Plante 3 árvores na sua ilha",
        tipo = TIPOS_MISSAO.DIARIA,
        objetivo = 3,
        progresso = 0,
        recompensa = 25,
        completada = false
    },
    {
        id = "visitar_ilhas",
        titulo = "Visitar Ilhas",
        descricao = "Visite a ilha de 2 jogadores diferentes",
        tipo = TIPOS_MISSAO.DIARIA,
        objetivo = 2,
        progresso = 0,
        recompensa = 50,
        completada = false
    },
    {
        id = "coletar_recursos",
        titulo = "Coletar Recursos",
        descricao = "Colete 10 recursos da sua ilha",
        tipo = TIPOS_MISSAO.DIARIA,
        objetivo = 10,
        progresso = 0,
        recompensa = 35,
        completada = false
    }
}

local MISSOES_SEMANAIS_PADRAO = {
    {
        id = "construir_casa",
        titulo = "Construir Casa",
        descricao = "Construa uma casa completa na sua ilha",
        tipo = TIPOS_MISSAO.SEMANAL,
        objetivo = 1,
        progresso = 0,
        recompensa = 150,
        completada = false
    },
    {
        id = "decorar_ilha",
        titulo = "Decorar Ilha",
        descricao = "Coloque 15 decorações na sua ilha",
        tipo = TIPOS_MISSAO.SEMANAL,
        objetivo = 15,
        progresso = 0,
        recompensa = 100,
        completada = false
    }
}

-- Eventos Remotos
local RemoteEvents
local CompletarMissaoEvent

--[[
    Inicializa o módulo de missões
    Configura eventos remotos e outras dependências
    @return (boolean) - Sucesso da inicialização
]]
function MissoesModule.Inicializar()
    print("Inicializando módulo de missões (versão temporária)...")
    
    -- Obter referência aos eventos remotos
    RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
    CompletarMissaoEvent = RemoteEvents:WaitForChild("CompletarMissao")
    
    -- Configurar eventos de comunicação com o cliente
    CompletarMissaoEvent.OnServerEvent:Connect(function(player, missaoId)
        -- Verificar se o jogador pode completar esta missão
        local sucesso = MissoesModule.CompletarMissao(player, missaoId)
        
        if not sucesso then
            warn("Jogador " .. player.Name .. " tentou completar missão " .. missaoId .. " mas não foi possível")
        end
    end)
    
    print("Módulo de missões inicializado com sucesso!")
    return true
end

--[[
    Configura as missões diárias para um jogador
    @param player (Player) - Objeto do jogador
    @param dadosJogador (table) - Dados do jogador do DataStore
]]
function MissoesModule.ConfigurarMissoesDiarias(player, dadosJogador)
    local userId = player.UserId
    
    -- Verificar se já tem dados de missões
    if not dadosJogador.missoes then
        dadosJogador.missoes = {
            diarias = {},
            semanais = {},
            concluidas = {}
        }
    end
    
    -- Verificar se precisa resetar missões diárias (novo dia)
    local dataAtual = os.date("*t")
    local diaAtual = dataAtual.year * 10000 + dataAtual.month * 100 + dataAtual.day
    
    local ultimoLoginDia = 0
    if dadosJogador.estatisticas and dadosJogador.estatisticas.ultimoLogin then
        local dataUltimoLogin = os.date("*t", dadosJogador.estatisticas.ultimoLogin)
        ultimoLoginDia = dataUltimoLogin.year * 10000 + dataUltimoLogin.month * 100 + dataUltimoLogin.day
    end
    
    -- Se for um novo dia, resetar missões diárias
    if diaAtual > ultimoLoginDia then
        print("Novo dia detectado para " .. player.Name .. ", resetando missões diárias")
        dadosJogador.missoes.diarias = CopiarTabela(MISSOES_DIARIAS_PADRAO)
    end
    
    -- Verificar se precisa resetar missões semanais (nova semana)
    local semanaAtual = math.floor(os.time() / (60 * 60 * 24 * 7))
    local ultimaSemanaMissoes = dadosJogador.missoes.ultimaSemana or 0
    
    if semanaAtual > ultimaSemanaMissoes then
        print("Nova semana detectada para " .. player.Name .. ", resetando missões semanais")
        dadosJogador.missoes.semanais = CopiarTabela(MISSOES_SEMANAIS_PADRAO)
        dadosJogador.missoes.ultimaSemana = semanaAtual
    end
    
    -- Armazenar missões na memória para uso durante a sessão
    jogadoresMissoes[userId] = dadosJogador.missoes
    
    -- Enviar missões para o cliente (a ser implementado)
    AtualizarMissoesCliente(player)
    
    return true
end

--[[
    Atualiza o progresso de uma missão
    @param player (Player) - Jogador
    @param missaoId (string) - ID da missão
    @param progresso (number) - Quantidade a adicionar ao progresso (opcional, padrão 1)
    @return (boolean) - Sucesso da atualização
]]
function MissoesModule.AtualizarProgresso(player, missaoId, progresso)
    progresso = progresso or 1
    local userId = player.UserId
    
    -- Verificar se o jogador tem missões carregadas
    if not jogadoresMissoes[userId] then
        warn("Jogador " .. player.Name .. " não tem missões carregadas")
        return false
    end
    
    -- Procurar missão nas diárias
    local missao = EncontrarMissao(userId, missaoId)
    if not missao then
        warn("Missão " .. missaoId .. " não encontrada para jogador " .. player.Name)
        return false
    end
    
    -- Atualizar progresso
    missao.progresso = math.min(missao.objetivo, missao.progresso + progresso)
    
    -- Verificar se completou
    if missao.progresso >= missao.objetivo and not missao.completada then
        missao.completada = true
        -- Notificar cliente que pode reclamar recompensa
        AtualizarMissoesCliente(player)
    end
    
    return true
end

--[[
    Completa uma missão e concede recompensa
    @param player (Player) - Jogador
    @param missaoId (string) - ID da missão
    @return (boolean) - Sucesso da operação
]]
function MissoesModule.CompletarMissao(player, missaoId)
    local userId = player.UserId
    
    -- Verificar se o jogador tem missões carregadas
    if not jogadoresMissoes[userId] then
        return false
    end
    
    -- Procurar missão
    local missao = EncontrarMissao(userId, missaoId)
    if not missao then
        return false
    end
    
    -- Verificar se a missão está completa e não foi reclamada
    if not missao.completada or missao.recompensaReclamada then
        return false
    end
    
    -- Conceder recompensa
    -- Aqui deveria chamar o módulo de economia, mas para simplificar:
    local Modules = ServerStorage:WaitForChild("Modules")
    local EconomiaModule = require(Modules:WaitForChild("EconomiaModule"))
    
    local sucesso = EconomiaModule.AdicionarMoedas(player, missao.recompensa, "Recompensa missão: " .. missao.titulo)
    
    if sucesso then
        -- Marcar como reclamada
        missao.recompensaReclamada = true
        
        -- Registrar nas missões concluídas
        if not jogadoresMissoes[userId].concluidas then
            jogadoresMissoes[userId].concluidas = {}
        end
        
        table.insert(jogadoresMissoes[userId].concluidas, {
            id = missao.id,
            tipo = missao.tipo,
            dataCompletada = os.time(),
            recompensa = missao.recompensa
        })
        
        -- Atualizar cliente
        AtualizarMissoesCliente(player)
        
        return true
    end
    
    return false
end

--[[
    Obtém todas as missões de um jogador
    @param player (Player) - Jogador
    @return (table) - Tabela com todas as missões
]]
function MissoesModule.ObterMissoes(player)
    local userId = player.UserId
    
    if not jogadoresMissoes[userId] then
        return {
            diarias = {},
            semanais = {},
            concluidas = {}
        }
    end
    
    return CopiarTabela(jogadoresMissoes[userId])
end

--[[
    Limpa os dados de missões de um jogador quando ele sai
    @param userId (number) - ID do jogador
]]
function MissoesModule.LimparDadosJogador(userId)
    jogadoresMissoes[userId] = nil
end

-- Funções internas (privadas) do módulo --

--[[
    Encontra uma missão pelo ID
    @param userId (number) - ID do jogador
    @param missaoId (string) - ID da missão
    @return (table) - Missão encontrada ou nil
]]
function EncontrarMissao(userId, missaoId)
    local missoes = jogadoresMissoes[userId]
    if not missoes then
        return nil
    end
    
    -- Procurar nas missões diárias
    for _, missao in ipairs(missoes.diarias or {}) do
        if missao.id == missaoId then
            return missao
        end
    end
    
    -- Procurar nas missões semanais
    for _, missao in ipairs(missoes.semanais or {}) do
        if missao.id == missaoId then
            return missao
        end
    end
    
    return nil
end

--[[
    Atualiza as missões no cliente
    @param player (Player) - Jogador a ser notificado
]]
function AtualizarMissoesCliente(player)
    -- Esta função seria implementada para enviar atualizações ao cliente
    -- Por enquanto, apenas um placeholder para o sistema funcionar
    
    -- Exemplo de implementação futura:
    -- local missoes = jogadoresMissoes[player.UserId]
    -- if missoes then
    --     local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
    --     local AtualizarMissoesEvent = RemoteEvents:WaitForChild("AtualizarMissoes")
    --     AtualizarMissoesEvent:FireClient(player, missoes)
    -- end
end

--[[
    Cria uma cópia profunda de uma tabela
    @param original (table) - Tabela original
    @return (table) - Cópia da tabela
]]
function CopiarTabela(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copia = {}
    for chave, valor in pairs(original) do
        if type(valor) == "table" then
            copia[chave] = CopiarTabela(valor)
        else
            copia[chave] = valor
        end
    end
    
    return copia
end

-- Configurar limpeza automática quando jogadores saem
Players.PlayerRemoving:Connect(function(player)
    MissoesModule.LimparDadosJogador(player.UserId)
end)

-- Retornar o módulo
return MissoesModule
