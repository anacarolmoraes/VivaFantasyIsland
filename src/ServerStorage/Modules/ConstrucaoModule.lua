--[[
    ConstrucaoModule.lua
    
    Módulo temporário para gerenciamento de construção e decoração do jogo "Viva Fantasy Island"
    Este é um módulo básico para permitir o funcionamento do GameManager
    
    NOTA: Esta é uma versão simplificada para testes iniciais.
    Será expandido com mais funcionalidades no futuro.
    
    Autor: Factory AI
    Data: 26/07/2025
]]

-- Serviços do Roblox
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

-- Variáveis e constantes do módulo
local ConstrucaoModule = {}
local jogadoresDecoracoes = {} -- Tabela para armazenar as decorações dos jogadores {[UserId] = {decoracoes}}
local decoracoesColocadas = {} -- Tabela para armazenar as decorações colocadas {[UserId] = {id = {modelo, posicao, rotacao}}}

-- Configurações
local DISTANCIA_MAXIMA_CONSTRUCAO = 50 -- Distância máxima para colocar decorações
local LIMITE_DECORACOES = 100 -- Limite de decorações por ilha

-- Modelos de decorações (referências para os modelos em ServerStorage)
local modelosDecoracoes = {
    arvore_pequena = "ArvoreP",
    arvore_grande = "ArvoreG",
    fogueira = "Fogueira",
    ponte = "Ponte",
    cerca = "Cerca",
    flor_azul = "FlorAzul",
    flor_vermelha = "FlorVermelha",
    pedra = "Pedra"
}

-- Eventos Remotos
local RemoteEvents
local ColocarDecoracaoEvent
local RemoverDecoracaoEvent

--[[
    Inicializa o módulo de construção
    Configura eventos remotos e outras dependências
    @return (boolean) - Sucesso da inicialização
]]
function ConstrucaoModule.Inicializar()
    print("Inicializando módulo de construção (versão temporária)...")
    
    -- Obter referência aos eventos remotos
    RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
    ColocarDecoracaoEvent = RemoteEvents:WaitForChild("ColocarDecoracao")
    RemoverDecoracaoEvent = RemoteEvents:WaitForChild("RemoverDecoracao")
    
    -- Configurar eventos de comunicação com o cliente
    ColocarDecoracaoEvent.OnServerEvent:Connect(function(player, decoracaoId, posicao, rotacao)
        -- Verificar se o jogador pode colocar esta decoração
        local sucesso = ConstrucaoModule.ColocarDecoracao(player, decoracaoId, posicao, rotacao)
        
        if not sucesso then
            warn("Jogador " .. player.Name .. " tentou colocar decoração " .. decoracaoId .. " mas não foi possível")
        end
    end)
    
    RemoverDecoracaoEvent.OnServerEvent:Connect(function(player, decoracaoId)
        -- Verificar se o jogador pode remover esta decoração
        local sucesso = ConstrucaoModule.RemoverDecoracao(player, decoracaoId)
        
        if not sucesso then
            warn("Jogador " .. player.Name .. " tentou remover decoração " .. decoracaoId .. " mas não foi possível")
        end
    end)
    
    print("Módulo de construção inicializado com sucesso!")
    return true
end

--[[
    Inicializa o sistema de construção para um jogador específico
    @param player (Player) - Objeto do jogador
    @param decoracoes (table) - Decorações que o jogador possui
]]
function ConstrucaoModule.InicializarJogador(player, decoracoes)
    local userId = player.UserId
    
    -- Inicializar tabelas para o jogador
    jogadoresDecoracoes[userId] = decoracoes or {}
    decoracoesColocadas[userId] = {}
    
    print("Sistema de construção inicializado para jogador: " .. player.Name)
    
    -- Carregar decorações já colocadas anteriormente (se houver)
    CarregarDecoracoesColocadas(player)
    
    return true
end

--[[
    Coloca uma decoração na ilha do jogador
    @param player (Player) - Jogador
    @param decoracaoId (string) - ID da decoração
    @param posicao (Vector3) - Posição onde colocar
    @param rotacao (CFrame) - Rotação da decoração
    @return (boolean) - Sucesso da operação
]]
function ConstrucaoModule.ColocarDecoracao(player, decoracaoId, posicao, rotacao)
    local userId = player.UserId
    
    -- Verificar se o jogador tem esta decoração no inventário
    if not TemDecoracaoNoInventario(userId, decoracaoId) then
        return false
    end
    
    -- Verificar se está dentro da ilha do jogador
    if not EstaEmSuaIlha(player, posicao) then
        return false
    end
    
    -- Verificar se não excedeu o limite de decorações
    if ContarDecoracoesColocadas(userId) >= LIMITE_DECORACOES then
        return false
    end
    
    -- Criar a decoração no mundo
    local decoracao = CriarDecoracao(decoracaoId, posicao, rotacao)
    if not decoracao then
        return false
    end
    
    -- Registrar a decoração colocada
    local decoracaoUniqueId = "dec_" .. userId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
    decoracao.Name = decoracaoUniqueId
    
    -- Armazenar referência
    decoracoesColocadas[userId][decoracaoUniqueId] = {
        id = decoracaoId,
        modelo = decoracao,
        posicao = posicao,
        rotacao = rotacao
    }
    
    -- Remover do inventário
    RemoverDoInventario(userId, decoracaoId)
    
    return true
end

--[[
    Remove uma decoração da ilha do jogador
    @param player (Player) - Jogador
    @param decoracaoUniqueId (string) - ID único da decoração colocada
    @return (boolean) - Sucesso da operação
]]
function ConstrucaoModule.RemoverDecoracao(player, decoracaoUniqueId)
    local userId = player.UserId
    
    -- Verificar se esta decoração existe e pertence ao jogador
    if not decoracoesColocadas[userId] or not decoracoesColocadas[userId][decoracaoUniqueId] then
        return false
    end
    
    local decoracaoInfo = decoracoesColocadas[userId][decoracaoUniqueId]
    
    -- Remover do mundo
    if decoracaoInfo.modelo and decoracaoInfo.modelo:IsA("Model") then
        decoracaoInfo.modelo:Destroy()
    end
    
    -- Adicionar de volta ao inventário
    AdicionarAoInventario(userId, decoracaoInfo.id)
    
    -- Remover do registro
    decoracoesColocadas[userId][decoracaoUniqueId] = nil
    
    return true
end

--[[
    Obtém todas as decorações colocadas por um jogador
    @param player (Player) - Jogador
    @return (table) - Tabela com todas as decorações colocadas
]]
function ConstrucaoModule.ObterDecoracoesColocadas(player)
    local userId = player.UserId
    
    if not decoracoesColocadas[userId] then
        return {}
    end
    
    -- Retornar cópia para não permitir modificação direta
    return CopiarTabela(decoracoesColocadas[userId])
end

--[[
    Obtém o inventário de decorações de um jogador
    @param player (Player) - Jogador
    @return (table) - Tabela com o inventário de decorações
]]
function ConstrucaoModule.ObterInventarioDecoracoes(player)
    local userId = player.UserId
    
    if not jogadoresDecoracoes[userId] then
        return {}
    end
    
    -- Retornar cópia para não permitir modificação direta
    return CopiarTabela(jogadoresDecoracoes[userId])
end

--[[
    Limpa os dados de construção de um jogador quando ele sai
    @param userId (number) - ID do jogador
]]
function ConstrucaoModule.LimparDadosJogador(userId)
    jogadoresDecoracoes[userId] = nil
    -- Não limpar decoracoesColocadas para manter as decorações no mundo
end

-- Funções internas (privadas) do módulo --

--[[
    Verifica se o jogador tem uma decoração no inventário
    @param userId (number) - ID do jogador
    @param decoracaoId (string) - ID da decoração
    @return (boolean) - true se tiver a decoração
]]
function TemDecoracaoNoInventario(userId, decoracaoId)
    -- Verificação básica para testes iniciais
    -- Na versão completa, verificaria a quantidade disponível
    return true
end

--[[
    Verifica se a posição está dentro da ilha do jogador
    @param player (Player) - Jogador
    @param posicao (Vector3) - Posição a verificar
    @return (boolean) - true se estiver na ilha
]]
function EstaEmSuaIlha(player, posicao)
    -- Verificação básica para testes iniciais
    -- Na versão completa, verificaria os limites da ilha
    return true
end

--[[
    Conta quantas decorações o jogador já colocou
    @param userId (number) - ID do jogador
    @return (number) - Quantidade de decorações colocadas
]]
function ContarDecoracoesColocadas(userId)
    if not decoracoesColocadas[userId] then
        return 0
    end
    
    local contador = 0
    for _ in pairs(decoracoesColocadas[userId]) do
        contador = contador + 1
    end
    
    return contador
end

--[[
    Cria uma decoração no mundo
    @param decoracaoId (string) - ID da decoração
    @param posicao (Vector3) - Posição onde colocar
    @param rotacao (CFrame) - Rotação da decoração
    @return (Model) - Modelo criado ou nil se falhar
]]
function CriarDecoracao(decoracaoId, posicao, rotacao)
    -- Obter o modelo correspondente
    local modeloNome = modelosDecoracoes[decoracaoId]
    if not modeloNome then
        return nil
    end
    
    -- Na versão completa, buscaria o modelo em ServerStorage
    -- Por enquanto, criar um modelo simples para representação
    local decoracao = Instance.new("Part")
    decoracao.Name = "Decoracao_" .. decoracaoId
    decoracao.Anchored = true
    decoracao.CanCollide = true
    decoracao.Size = Vector3.new(1, 1, 1)
    decoracao.Position = posicao
    decoracao.CFrame = rotacao
    
    -- Cor baseada no tipo de decoração
    if decoracaoId:find("arvore") then
        decoracao.BrickColor = BrickColor.new("Forest green")
    elseif decoracaoId:find("flor") then
        if decoracaoId:find("azul") then
            decoracao.BrickColor = BrickColor.new("Bright blue")
        else
            decoracao.BrickColor = BrickColor.new("Bright red")
        end
    elseif decoracaoId:find("pedra") then
        decoracao.BrickColor = BrickColor.new("Medium stone grey")
    elseif decoracaoId:find("fogueira") then
        decoracao.BrickColor = BrickColor.new("Bright orange")
    else
        decoracao.BrickColor = BrickColor.new("Brown")
    end
    
    decoracao.Parent = Workspace
    
    return decoracao
end

--[[
    Remove uma decoração do inventário do jogador
    @param userId (number) - ID do jogador
    @param decoracaoId (string) - ID da decoração
]]
function RemoverDoInventario(userId, decoracaoId)
    -- Implementação básica para testes
    -- Na versão completa, decrementaria a quantidade
    if jogadoresDecoracoes[userId] and jogadoresDecoracoes[userId][decoracaoId] then
        jogadoresDecoracoes[userId][decoracaoId] = jogadoresDecoracoes[userId][decoracaoId] - 1
        if jogadoresDecoracoes[userId][decoracaoId] <= 0 then
            jogadoresDecoracoes[userId][decoracaoId] = nil
        end
    end
end

--[[
    Adiciona uma decoração ao inventário do jogador
    @param userId (number) - ID do jogador
    @param decoracaoId (string) - ID da decoração
]]
function AdicionarAoInventario(userId, decoracaoId)
    -- Implementação básica para testes
    if not jogadoresDecoracoes[userId] then
        jogadoresDecoracoes[userId] = {}
    end
    
    if not jogadoresDecoracoes[userId][decoracaoId] then
        jogadoresDecoracoes[userId][decoracaoId] = 0
    end
    
    jogadoresDecoracoes[userId][decoracaoId] = jogadoresDecoracoes[userId][decoracaoId] + 1
end

--[[
    Carrega decorações já colocadas anteriormente
    @param player (Player) - Jogador
]]
function CarregarDecoracoesColocadas(player)
    -- Esta função carregaria as decorações salvas no DataStore
    -- Por enquanto, apenas um placeholder para o sistema funcionar
    print("Carregando decorações colocadas para: " .. player.Name)
    -- Implementação futura
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
    ConstrucaoModule.LimparDadosJogador(player.UserId)
end)

-- Retornar o módulo
return ConstrucaoModule
