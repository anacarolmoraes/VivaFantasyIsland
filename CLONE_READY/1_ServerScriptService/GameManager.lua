--[[
    GameManager.lua
    
    Script principal do servidor para o jogo "Viva Fantasy Island"
    Este script gerencia a entrada de jogadores, inicializa sistemas principais
    e configura a comunicação entre cliente e servidor.
    
    Autor: Factory AI
    Data: 26/07/2025
]]

-- Serviços do Roblox
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")

-- Configurações do jogo
local ILHA_INICIAL_MODEL_NAME = "IlhaInicial"
local SPAWN_LOCATION_NAME = "SpawnLocation"

-- Módulos do jogo (serão carregados de ServerStorage/Modules)
local Modules = ServerStorage:WaitForChild("Modules")
local EconomiaModule = require(Modules:WaitForChild("EconomiaModule"))
local DataStoreModule = require(Modules:WaitForChild("DataStoreModule"))
local MissoesModule = require(Modules:WaitForChild("MissoesModule"))
local ConstrucaoModule = require(Modules:WaitForChild("ConstrucaoModule"))

-- Eventos Remotos (para comunicação cliente-servidor)
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

-- Variáveis locais
local jogadoresData = {}
local ilhasJogadores = {}

-- Função para criar eventos remotos necessários
local function ConfigurarEventosRemotos()
    print("Configurando eventos remotos...")
    
    -- Criar pastas se não existirem
    if not ReplicatedStorage:FindFirstChild("RemoteEvents") then
        local remoteEvents = Instance.new("Folder")
        remoteEvents.Name = "RemoteEvents"
        remoteEvents.Parent = ReplicatedStorage
    end
    
    if not ReplicatedStorage:FindFirstChild("RemoteFunctions") then
        local remoteFunctions = Instance.new("Folder")
        remoteFunctions.Name = "RemoteFunctions"
        remoteFunctions.Parent = ReplicatedStorage
    end
    
    -- Eventos para Economia
    local atualizarMoedas = Instance.new("RemoteEvent")
    atualizarMoedas.Name = "AtualizarMoedas"
    atualizarMoedas.Parent = RemoteEvents
    
    -- Eventos para Construção
    local colocarDecoracao = Instance.new("RemoteEvent")
    colocarDecoracao.Name = "ColocarDecoracao"
    colocarDecoracao.Parent = RemoteEvents
    
    local removerDecoracao = Instance.new("RemoteEvent")
    removerDecoracao.Name = "RemoverDecoracao"
    removerDecoracao.Parent = RemoteEvents
    
    -- Eventos para Loja
    local comprarItem = Instance.new("RemoteFunction")
    comprarItem.Name = "ComprarItem"
    comprarItem.Parent = RemoteFunctions
    
    -- Eventos para Missões
    local completarMissao = Instance.new("RemoteEvent")
    completarMissao.Name = "CompletarMissao"
    completarMissao.Parent = RemoteEvents
    
    -- Eventos para Visitas
    local visitarIlha = Instance.new("RemoteFunction")
    visitarIlha.Name = "VisitarIlha"
    visitarIlha.Parent = RemoteFunctions
    
    print("Eventos remotos configurados com sucesso!")
end

-- Função para criar a ilha do jogador
local function CriarIlhaJogador(player)
    print("Criando ilha para o jogador: " .. player.Name)
    
    -- Clonar modelo da ilha inicial
    local ilhaModelo = ServerStorage:WaitForChild("Modelos"):WaitForChild(ILHA_INICIAL_MODEL_NAME):Clone()
    
    -- Posicionar a ilha (cada ilha fica em uma posição diferente no espaço)
    local posicaoBase = Vector3.new(0, 0, 0)
    local distanciaEntreIlhas = 1000 -- 1000 studs entre cada ilha
    local indiceJogador = #ilhasJogadores + 1
    
    -- Calcular posição da ilha (em grade)
    local linha = math.floor(indiceJogador / 10)
    local coluna = indiceJogador % 10
    
    local posicaoIlha = posicaoBase + Vector3.new(
        coluna * distanciaEntreIlhas,
        0,
        linha * distanciaEntreIlhas
    )
    
    ilhaModelo:SetPrimaryPartCFrame(CFrame.new(posicaoIlha))
    ilhaModelo.Parent = workspace
    
    -- Guardar referência da ilha
    ilhasJogadores[player.UserId] = {
        modelo = ilhaModelo,
        posicao = posicaoIlha
    }
    
    return ilhaModelo
end

-- Função para teleportar jogador para sua ilha
local function TeleportarParaIlha(player, ilhaModelo)
    print("Teleportando jogador " .. player.Name .. " para sua ilha")
    
    local spawnLocation = ilhaModelo:FindFirstChild(SPAWN_LOCATION_NAME)
    
    if spawnLocation then
        -- Se encontrou o ponto de spawn específico
        player.Character:SetPrimaryPartCFrame(spawnLocation.CFrame + Vector3.new(0, 5, 0))
    else
        -- Caso não encontre, usa o centro da ilha
        player.Character:SetPrimaryPartCFrame(ilhaModelo:GetPrimaryPartCFrame() + Vector3.new(0, 10, 0))
    end
end

-- Função para carregar os dados do jogador
local function CarregarDadosJogador(player)
    print("Carregando dados do jogador: " .. player.Name)
    
    -- Usar o módulo DataStore para carregar dados
    local dadosJogador = DataStoreModule.CarregarDadosJogador(player.UserId)
    
    -- Se for a primeira vez do jogador, criar dados padrão
    if not dadosJogador then
        dadosJogador = {
            moedas = 100, -- Moedas iniciais
            decoracoes = {}, -- Decorações que o jogador possui
            missoesConcluidas = {}, -- Missões já concluídas
            ultimoLogin = os.time(), -- Timestamp do último login
            nivel = 1, -- Nível inicial do jogador
            estatisticas = {
                visitasRecebidas = 0,
                likesRecebidos = 0,
                diasConsecutivos = 1
            }
        }
    else
        -- Atualizar estatísticas de login
        local diaAtual = math.floor(os.time() / (60 * 60 * 24))
        local ultimoLoginDia = math.floor(dadosJogador.ultimoLogin / (60 * 60 * 24))
        
        if diaAtual - ultimoLoginDia == 1 then
            -- Login em dias consecutivos
            dadosJogador.estatisticas.diasConsecutivos = dadosJogador.estatisticas.diasConsecutivos + 1
        elseif diaAtual - ultimoLoginDia > 1 then
            -- Quebrou a sequência
            dadosJogador.estatisticas.diasConsecutivos = 1
        end
        
        dadosJogador.ultimoLogin = os.time()
    end
    
    -- Armazenar dados na memória para uso durante a sessão
    jogadoresData[player.UserId] = dadosJogador
    
    -- Inicializar economia do jogador
    EconomiaModule.InicializarJogador(player, dadosJogador.moedas)
    
    return dadosJogador
end

-- Função para salvar dados do jogador
local function SalvarDadosJogador(player)
    print("Salvando dados do jogador: " .. player.Name)
    
    local dadosJogador = jogadoresData[player.UserId]
    if dadosJogador then
        -- Atualizar moedas antes de salvar
        dadosJogador.moedas = EconomiaModule.ObterMoedas(player)
        
        -- Salvar usando o módulo DataStore
        DataStoreModule.SalvarDadosJogador(player.UserId, dadosJogador)
        print("Dados salvos com sucesso para: " .. player.Name)
    else
        warn("Não foi possível salvar dados para " .. player.Name .. ": dados não encontrados")
    end
end

-- Função para configurar missões diárias
local function ConfigurarMissoesDiarias(player)
    print("Configurando missões diárias para: " .. player.Name)
    
    local dadosJogador = jogadoresData[player.UserId]
    if dadosJogador then
        -- Verificar se as missões precisam ser resetadas (novo dia)
        MissoesModule.ConfigurarMissoesDiarias(player, dadosJogador)
    end
end

-- Função chamada quando um jogador entra no jogo
local function OnPlayerAdded(player)
    print("Jogador entrou: " .. player.Name)
    
    -- Carregar dados do jogador
    local dadosJogador = CarregarDadosJogador(player)
    
    -- Configurar missões diárias
    ConfigurarMissoesDiarias(player)
    
    -- Esperar o personagem carregar
    player.CharacterAdded:Connect(function(character)
        print("Personagem carregado para: " .. player.Name)
        
        -- Criar ou carregar ilha do jogador
        local ilhaJogador = ilhasJogadores[player.UserId] and ilhasJogadores[player.UserId].modelo
        
        if not ilhaJogador then
            ilhaJogador = CriarIlhaJogador(player)
        end
        
        -- Teleportar jogador para sua ilha
        TeleportarParaIlha(player, ilhaJogador)
        
        -- Inicializar sistema de construção para este jogador
        ConstrucaoModule.InicializarJogador(player, dadosJogador.decoracoes)
    end)
    
    -- Configurar autosave a cada 5 minutos
    spawn(function()
        while player and player:IsDescendantOf(game) do
            wait(300) -- 5 minutos
            if player and player:IsDescendantOf(game) then
                SalvarDadosJogador(player)
            else
                break
            end
        end
    end)
end

-- Função chamada quando um jogador sai do jogo
local function OnPlayerRemoving(player)
    print("Jogador saiu: " .. player.Name)
    
    -- Salvar dados do jogador
    SalvarDadosJogador(player)
    
    -- Limpar dados da memória
    jogadoresData[player.UserId] = nil
    
    -- Manter a ilha no workspace para permitir visitas
    -- Mas podemos marcar como inativa
    if ilhasJogadores[player.UserId] then
        ilhasJogadores[player.UserId].ativa = false
    end
end

-- Função para inicializar todos os sistemas do jogo
local function InicializarSistemas()
    print("Inicializando sistemas do jogo...")
    
    -- Inicializar DataStore
    DataStoreModule.Inicializar()
    
    -- Inicializar Economia
    EconomiaModule.Inicializar()
    
    -- Inicializar Sistema de Missões
    MissoesModule.Inicializar()
    
    -- Inicializar Sistema de Construção
    ConstrucaoModule.Inicializar()
    
    print("Todos os sistemas inicializados com sucesso!")
end

-- Função principal de inicialização
local function Inicializar()
    print("Inicializando GameManager...")
    
    -- Configurar eventos remotos
    ConfigurarEventosRemotos()
    
    -- Inicializar sistemas
    InicializarSistemas()
    
    -- Conectar eventos de jogadores
    Players.PlayerAdded:Connect(OnPlayerAdded)
    Players.PlayerRemoving:Connect(OnPlayerRemoving)
    
    -- Processar jogadores que já estão no servidor
    for _, player in pairs(Players:GetPlayers()) do
        spawn(function()
            OnPlayerAdded(player)
        end)
    end
    
    print("GameManager inicializado com sucesso!")
end

-- Iniciar o GameManager
Inicializar()
