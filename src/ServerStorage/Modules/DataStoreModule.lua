--[[
    DataStoreModule.lua
    
    Módulo responsável pelo gerenciamento de persistência de dados do jogo "Viva Fantasy Island"
    Utiliza o DataStoreService do Roblox para salvar e carregar dados dos jogadores
    
    Autor: Factory AI
    Data: 26/07/2025
]]

-- Serviços do Roblox
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configurações do módulo
local NOME_DATASTORE = "VivaFantasyIslandData_v1" -- Versão do DataStore (incrementar em caso de mudanças estruturais)
local NOME_DATASTORE_BACKUP = "VivaFantasyIslandBackup_v1" -- DataStore para backups
local INTERVALO_AUTO_SAVE = 300 -- 5 minutos entre salvamentos automáticos
local MAX_TENTATIVAS_SAVE = 5 -- Número máximo de tentativas de salvamento
local TEMPO_ENTRE_TENTATIVAS = 5 -- Tempo entre tentativas de salvamento (segundos)
local USAR_MOCK_DATASTORE = false -- Para testes locais

-- Variáveis do módulo
local DataStoreModule = {}
local dataStore
local dataStoreBackup
local cacheJogadores = {} -- Cache para reduzir chamadas ao DataStore {[userId] = {dados = {}, ultimoSalvamento = timestamp}}
local salvamentosEmProgresso = {} -- Controle de salvamentos em andamento {[userId] = true/false}
local salvamentosAgendados = {} -- Controle de salvamentos agendados {[userId] = true/false}

-- Estrutura padrão de dados para novos jogadores
local DADOS_PADRAO = {
    versao = 1, -- Versão da estrutura de dados
    moedas = 100, -- Moedas iniciais
    decoracoes = {}, -- Decorações que o jogador possui
    decoracoesColocadas = {}, -- Decorações colocadas na ilha {id = {posicao = Vector3, rotacao = CFrame}}
    missoes = {
        diarias = {},
        semanais = {},
        concluidas = {}
    },
    estatisticas = {
        visitasRecebidas = 0,
        likesRecebidos = 0,
        diasConsecutivos = 1,
        tempoJogado = 0,
        ultimoLogin = 0
    },
    configuracoes = {
        ilhaPublica = true, -- Se outros jogadores podem visitar
        permitirConstrucao = false -- Se visitantes podem construir
    },
    inventario = {
        decoracoes = {}, -- IDs das decorações no inventário
        itensEspeciais = {} -- Itens especiais ou raros
    },
    amigos = {}, -- Lista de amigos favoritos (para visitas rápidas)
    ultimoSalvamento = 0 -- Timestamp do último salvamento
}

--[[
    Inicializa o módulo DataStore
    Configura os DataStores e inicia o sistema de auto-save
    @return (boolean) - Sucesso da inicialização
]]
function DataStoreModule.Inicializar()
    print("Inicializando DataStoreModule...")
    
    -- Verificar se estamos em ambiente de teste
    if RunService:IsStudio() and not game:GetService("RunService"):IsServer() then
        warn("DataStoreModule: Executando em modo Studio cliente. Usando MockDataStore.")
        USAR_MOCK_DATASTORE = true
    end
    
    -- Inicializar DataStores
    local sucesso, mensagemErro = pcall(function()
        if USAR_MOCK_DATASTORE then
            -- Usar um mock para testes locais
            dataStore = CriarMockDataStore()
            dataStoreBackup = CriarMockDataStore()
        else
            -- Usar DataStore real
            dataStore = DataStoreService:GetDataStore(NOME_DATASTORE)
            dataStoreBackup = DataStoreService:GetDataStore(NOME_DATASTORE_BACKUP)
        end
    end)
    
    if not sucesso then
        warn("DataStoreModule: Erro ao inicializar DataStores: " .. mensagemErro)
        return false
    end
    
    -- Iniciar sistema de auto-save
    IniciarAutoSave()
    
    -- Conectar eventos de jogadores
    Players.PlayerRemoving:Connect(function(player)
        -- Salvar dados quando o jogador sair
        DataStoreModule.SalvarDadosJogador(player.UserId)
        
        -- Limpar cache após salvamento
        wait(2) -- Esperar um pouco para garantir que o salvamento foi processado
        LimparCacheJogador(player.UserId)
    end)
    
    -- Conectar evento de fechamento do servidor
    game:BindToClose(function()
        print("DataStoreModule: Servidor fechando, salvando todos os dados...")
        SalvarTodosJogadores(true) -- Forçar salvamento síncrono
    end)
    
    print("DataStoreModule inicializado com sucesso!")
    return true
end

--[[
    Carrega os dados de um jogador do DataStore
    @param userId (number) - ID do jogador
    @return (table) - Dados do jogador ou dados padrão se não encontrado
]]
function DataStoreModule.CarregarDadosJogador(userId)
    -- Verificar se já está no cache
    if cacheJogadores[userId] then
        print("DataStoreModule: Dados do jogador " .. userId .. " encontrados no cache.")
        return CopiarTabela(cacheJogadores[userId].dados)
    end
    
    print("DataStoreModule: Carregando dados do jogador " .. userId .. "...")
    
    -- Tentar carregar do DataStore principal
    local dadosJogador, sucesso = CarregarDoDataStore(dataStore, userId)
    
    -- Se falhar, tentar carregar do backup
    if not sucesso then
        warn("DataStoreModule: Falha ao carregar dados principais do jogador " .. userId .. ". Tentando backup...")
        dadosJogador, sucesso = CarregarDoDataStore(dataStoreBackup, userId)
        
        if sucesso then
            print("DataStoreModule: Dados de backup carregados com sucesso para jogador " .. userId)
        else
            warn("DataStoreModule: Falha ao carregar dados de backup do jogador " .. userId .. ". Usando dados padrão.")
            dadosJogador = CopiarTabela(DADOS_PADRAO)
        end
    end
    
    -- Verificar se os dados estão na versão atual e migrar se necessário
    dadosJogador = MigrarDadosSeNecessario(dadosJogador)
    
    -- Adicionar ao cache
    cacheJogadores[userId] = {
        dados = CopiarTabela(dadosJogador),
        ultimoSalvamento = os.time()
    }
    
    -- Atualizar timestamp de último login
    dadosJogador.estatisticas.ultimoLogin = os.time()
    
    return dadosJogador
end

--[[
    Salva os dados de um jogador no DataStore
    @param userId (number) - ID do jogador
    @param dadosPersonalizados (table, opcional) - Dados específicos a salvar (se omitido, usa o cache)
    @param forcaSincrono (boolean, opcional) - Se verdadeiro, força salvamento síncrono
    @return (boolean) - Sucesso do salvamento
]]
function DataStoreModule.SalvarDadosJogador(userId, dadosPersonalizados, forcaSincrono)
    -- Verificar se já existe um salvamento em andamento para este jogador
    if salvamentosEmProgresso[userId] then
        -- Se já está salvando, apenas agendar outro salvamento para depois
        salvamentosAgendados[userId] = true
        return true
    end
    
    -- Marcar que um salvamento está em andamento
    salvamentosEmProgresso[userId] = true
    
    -- Obter dados a salvar (do parâmetro ou do cache)
    local dadosParaSalvar
    if dadosPersonalizados then
        dadosParaSalvar = dadosPersonalizados
    elseif cacheJogadores[userId] then
        dadosParaSalvar = CopiarTabela(cacheJogadores[userId].dados)
    else
        warn("DataStoreModule: Tentativa de salvar dados para jogador " .. userId .. " sem dados em cache.")
        salvamentosEmProgresso[userId] = false
        return false
    end
    
    -- Atualizar timestamp de último salvamento
    dadosParaSalvar.ultimoSalvamento = os.time()
    
    -- Função para processar o salvamento
    local function ProcessarSalvamento()
        local sucesso = false
        local tentativas = 0
        
        -- Tentar salvar até o número máximo de tentativas
        while not sucesso and tentativas < MAX_TENTATIVAS_SAVE do
            tentativas = tentativas + 1
            
            -- Tentar salvar no DataStore principal
            local sucessoPrincipal, erro = SalvarNoDataStore(dataStore, userId, dadosParaSalvar)
            
            if sucessoPrincipal then
                -- Se salvou com sucesso no principal, salvar também no backup
                local sucessoBackup = SalvarNoDataStore(dataStoreBackup, userId, dadosParaSalvar)
                
                if not sucessoBackup then
                    warn("DataStoreModule: Falha ao salvar no DataStore de backup para jogador " .. userId)
                    -- Não consideramos falha crítica se apenas o backup falhar
                end
                
                sucesso = true
                print("DataStoreModule: Dados salvos com sucesso para jogador " .. userId)
            else
                warn("DataStoreModule: Tentativa " .. tentativas .. " falhou ao salvar dados para jogador " .. userId .. ": " .. tostring(erro))
                
                -- Esperar antes de tentar novamente
                if tentativas < MAX_TENTATIVAS_SAVE then
                    wait(TEMPO_ENTRE_TENTATIVAS)
                end
            end
        end
        
        -- Atualizar cache se salvou com sucesso
        if sucesso then
            if cacheJogadores[userId] then
                cacheJogadores[userId].dados = CopiarTabela(dadosParaSalvar)
                cacheJogadores[userId].ultimoSalvamento = os.time()
            end
        else
            warn("DataStoreModule: Falha ao salvar dados após " .. MAX_TENTATIVAS_SAVE .. " tentativas para jogador " .. userId)
        end
        
        -- Marcar que o salvamento terminou
        salvamentosEmProgresso[userId] = false
        
        -- Verificar se há outro salvamento agendado
        if salvamentosAgendados[userId] then
            salvamentosAgendados[userId] = false
            -- Agendar próximo salvamento com um pequeno delay
            spawn(function()
                wait(1)
                DataStoreModule.SalvarDadosJogador(userId)
            end)
        end
        
        return sucesso
    end
    
    -- Executar salvamento de forma síncrona ou assíncrona
    if forcaSincrono then
        return ProcessarSalvamento()
    else
        spawn(ProcessarSalvamento)
        return true -- Retorna verdadeiro pois o salvamento foi iniciado com sucesso
    end
end

--[[
    Atualiza dados específicos de um jogador sem salvar imediatamente
    @param userId (number) - ID do jogador
    @param caminho (string) - Caminho para o dado (formato: "chave1.chave2.chave3")
    @param valor (any) - Novo valor
    @param salvarImediatamente (boolean) - Se deve salvar imediatamente após atualizar
    @return (boolean) - Sucesso da operação
]]
function DataStoreModule.AtualizarDadosJogador(userId, caminho, valor, salvarImediatamente)
    -- Verificar se o jogador está no cache
    if not cacheJogadores[userId] then
        warn("DataStoreModule: Tentativa de atualizar dados para jogador " .. userId .. " não presente no cache.")
        return false
    end
    
    -- Atualizar o valor no caminho especificado
    local dadosJogador = cacheJogadores[userId].dados
    local sucesso = AtualizarValorEmCaminho(dadosJogador, caminho, valor)
    
    if not sucesso then
        warn("DataStoreModule: Falha ao atualizar valor no caminho '" .. caminho .. "' para jogador " .. userId)
        return false
    end
    
    -- Salvar imediatamente se solicitado
    if salvarImediatamente then
        return DataStoreModule.SalvarDadosJogador(userId)
    end
    
    return true
end

--[[
    Obtém um valor específico dos dados de um jogador
    @param userId (number) - ID do jogador
    @param caminho (string) - Caminho para o dado (formato: "chave1.chave2.chave3")
    @param valorPadrao (any) - Valor padrão caso não encontre
    @return (any) - Valor encontrado ou valorPadrao
]]
function DataStoreModule.ObterDadoJogador(userId, caminho, valorPadrao)
    -- Verificar se o jogador está no cache
    if not cacheJogadores[userId] then
        warn("DataStoreModule: Tentativa de obter dados para jogador " .. userId .. " não presente no cache.")
        return valorPadrao
    end
    
    -- Obter o valor no caminho especificado
    local dadosJogador = cacheJogadores[userId].dados
    local valor = ObterValorDeCaminho(dadosJogador, caminho)
    
    if valor == nil then
        return valorPadrao
    end
    
    return valor
end

--[[
    Verifica se um jogador tem dados salvos
    @param userId (number) - ID do jogador
    @return (boolean) - true se o jogador tem dados salvos
]]
function DataStoreModule.JogadorTemDados(userId)
    -- Verificar primeiro no cache
    if cacheJogadores[userId] then
        return true
    end
    
    -- Verificar no DataStore
    local sucesso, temDados = pcall(function()
        local dados = dataStore:GetAsync(tostring(userId))
        return dados ~= nil
    end)
    
    if not sucesso then
        warn("DataStoreModule: Erro ao verificar se jogador " .. userId .. " tem dados.")
        return false
    end
    
    return temDados
end

--[[
    Limpa o cache de um jogador específico
    @param userId (number) - ID do jogador
]]
function DataStoreModule.LimparCacheJogador(userId)
    LimparCacheJogador(userId)
end

--[[
    Força um salvamento para todos os jogadores online
    @param forcaSincrono (boolean) - Se verdadeiro, força salvamento síncrono
    @return (boolean) - Sucesso da operação
]]
function DataStoreModule.SalvarTodosJogadores(forcaSincrono)
    return SalvarTodosJogadores(forcaSincrono)
end

--[[
    Cria um backup dos dados de todos os jogadores online
    @return (boolean) - Sucesso da operação
]]
function DataStoreModule.CriarBackupCompleto()
    print("DataStoreModule: Criando backup completo de todos os jogadores online...")
    
    local sucesso = true
    
    -- Para cada jogador online, salvar no DataStore de backup
    for _, player in pairs(Players:GetPlayers()) do
        local userId = player.UserId
        
        if cacheJogadores[userId] then
            local dadosJogador = CopiarTabela(cacheJogadores[userId].dados)
            
            -- Salvar no DataStore de backup
            local sucessoBackup = SalvarNoDataStore(dataStoreBackup, userId, dadosJogador)
            
            if not sucessoBackup then
                warn("DataStoreModule: Falha ao criar backup para jogador " .. userId)
                sucesso = false
            end
        end
    end
    
    return sucesso
end

-- Funções internas (privadas) do módulo --

--[[
    Inicia o sistema de auto-save para todos os jogadores
]]
function IniciarAutoSave()
    spawn(function()
        while true do
            wait(INTERVALO_AUTO_SAVE)
            
            print("DataStoreModule: Executando auto-save para todos os jogadores...")
            local sucessoSalvamento = SalvarTodosJogadores(false)
            
            if not sucessoSalvamento then
                warn("DataStoreModule: Auto-save encontrou problemas ao salvar alguns jogadores.")
            end
        end
    end)
end

--[[
    Salva os dados de todos os jogadores online
    @param forcaSincrono (boolean) - Se verdadeiro, força salvamento síncrono
    @return (boolean) - Sucesso da operação
]]
function SalvarTodosJogadores(forcaSincrono)
    local sucesso = true
    
    -- Para cada jogador online, salvar seus dados
    for _, player in pairs(Players:GetPlayers()) do
        local userId = player.UserId
        
        if cacheJogadores[userId] then
            local sucessoJogador = DataStoreModule.SalvarDadosJogador(userId, nil, forcaSincrono)
            
            if not sucessoJogador then
                warn("DataStoreModule: Falha ao salvar dados para jogador " .. userId .. " durante salvamento em massa.")
                sucesso = false
            end
        end
    end
    
    return sucesso
end

--[[
    Limpa o cache de um jogador específico
    @param userId (number) - ID do jogador
]]
function LimparCacheJogador(userId)
    if cacheJogadores[userId] then
        print("DataStoreModule: Limpando cache do jogador " .. userId)
        cacheJogadores[userId] = nil
    end
    
    -- Limpar também controles de salvamento
    salvamentosEmProgresso[userId] = nil
    salvamentosAgendados[userId] = nil
end

--[[
    Carrega dados de um jogador do DataStore especificado
    @param store (DataStore) - DataStore a ser usado
    @param userId (number) - ID do jogador
    @return (table, boolean) - Dados do jogador e status de sucesso
]]
function CarregarDoDataStore(store, userId)
    local dadosJogador
    local sucesso = false
    
    -- Tentar carregar dados do DataStore
    pcall(function()
        dadosJogador = store:GetAsync(tostring(userId))
        sucesso = dadosJogador ~= nil
    end)
    
    -- Se não encontrou dados, usar dados padrão
    if not sucesso or not dadosJogador then
        dadosJogador = CopiarTabela(DADOS_PADRAO)
        sucesso = false
    end
    
    return dadosJogador, sucesso
end

--[[
    Salva dados de um jogador no DataStore especificado
    @param store (DataStore) - DataStore a ser usado
    @param userId (number) - ID do jogador
    @param dados (table) - Dados a serem salvos
    @return (boolean, string) - Sucesso da operação e mensagem de erro (se houver)
]]
function SalvarNoDataStore(store, userId, dados)
    local sucesso, mensagemErro = pcall(function()
        store:SetAsync(tostring(userId), dados)
    end)
    
    return sucesso, mensagemErro
end

--[[
    Migra dados de jogador para a versão atual se necessário
    @param dados (table) - Dados do jogador
    @return (table) - Dados migrados
]]
function MigrarDadosSeNecessario(dados)
    -- Verificar se os dados têm uma versão
    if not dados.versao then
        dados.versao = 0 -- Versão legada
    end
    
    -- Migrar da versão 0 para 1
    if dados.versao < 1 then
        print("DataStoreModule: Migrando dados do jogador da versão " .. dados.versao .. " para versão 1")
        
        -- Adicionar campos que não existiam na versão anterior
        if not dados.estatisticas then
            dados.estatisticas = DADOS_PADRAO.estatisticas
        end
        
        if not dados.configuracoes then
            dados.configuracoes = DADOS_PADRAO.configuracoes
        end
        
        if not dados.inventario then
            dados.inventario = DADOS_PADRAO.inventario
        end
        
        if not dados.amigos then
            dados.amigos = DADOS_PADRAO.amigos
        end
        
        -- Atualizar versão
        dados.versao = 1
    end
    
    -- Aqui você pode adicionar mais migrações no futuro
    -- if dados.versao < 2 then ... end
    
    return dados
end

--[[
    Atualiza um valor em um caminho específico dentro de uma tabela
    @param tabela (table) - Tabela a ser atualizada
    @param caminho (string) - Caminho para o valor (formato: "chave1.chave2.chave3")
    @param valor (any) - Novo valor
    @return (boolean) - Sucesso da operação
]]
function AtualizarValorEmCaminho(tabela, caminho, valor)
    if not tabela or type(tabela) ~= "table" then
        return false
    end
    
    local chaves = {}
    for chave in string.gmatch(caminho, "[^%.]+") do
        table.insert(chaves, chave)
    end
    
    local atual = tabela
    for i = 1, #chaves - 1 do
        local chave = chaves[i]
        
        -- Se a chave não existir, criar uma tabela vazia
        if atual[chave] == nil then
            atual[chave] = {}
        elseif type(atual[chave]) ~= "table" then
            -- Se não for uma tabela, não podemos continuar
            return false
        end
        
        atual = atual[chave]
    end
    
    -- Atualizar o valor final
    atual[chaves[#chaves]] = valor
    return true
end

--[[
    Obtém um valor de um caminho específico dentro de uma tabela
    @param tabela (table) - Tabela de origem
    @param caminho (string) - Caminho para o valor (formato: "chave1.chave2.chave3")
    @return (any) - Valor encontrado ou nil se não existir
]]
function ObterValorDeCaminho(tabela, caminho)
    if not tabela or type(tabela) ~= "table" then
        return nil
    end
    
    local chaves = {}
    for chave in string.gmatch(caminho, "[^%.]+") do
        table.insert(chaves, chave)
    end
    
    local atual = tabela
    for i = 1, #chaves do
        local chave = chaves[i]
        
        if atual[chave] == nil then
            return nil
        end
        
        atual = atual[chave]
    end
    
    return atual
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

--[[
    Cria um mock de DataStore para testes em ambiente Studio
    @return (table) - Mock de DataStore
]]
function CriarMockDataStore()
    local dadosTemporarios = {}
    
    local mockDataStore = {
        GetAsync = function(self, chave)
            return dadosTemporarios[chave]
        end,
        
        SetAsync = function(self, chave, valor)
            dadosTemporarios[chave] = CopiarTabela(valor)
            return true
        end,
        
        RemoveAsync = function(self, chave)
            local valorAntigo = dadosTemporarios[chave]
            dadosTemporarios[chave] = nil
            return valorAntigo
        end,
        
        UpdateAsync = function(self, chave, funcaoTransformacao)
            local valorAtual = dadosTemporarios[chave]
            local novoValor = funcaoTransformacao(valorAtual)
            dadosTemporarios[chave] = novoValor
            return novoValor
        end
    }
    
    return mockDataStore
end

-- Retornar o módulo
return DataStoreModule
