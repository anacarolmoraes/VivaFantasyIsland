local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Obter jogador local
local player = Players.LocalPlayer

-- Obter eventos remotos
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ComprarItemEvent = RemoteEvents:WaitForChild("ComprarItem")

-- Configurações
local CONFIG = {
    tempoAnimacao = 0.3,
    corPrimaria = Color3.fromRGB(0, 170, 255),
    corSecundaria = Color3.fromRGB(0, 120, 180),
    corTexto = Color3.fromRGB(255, 255, 255),
    corFundo = Color3.fromRGB(40, 40, 40),
    corDestaque = Color3.fromRGB(255, 215, 0),
    corErro = Color3.fromRGB(255, 0, 0)
}

-- Definição dos itens disponíveis na loja
local ITENS_LOJA = {
    decoracoes = {
        {
            id = "cerca_madeira",
            nome = "Cerca de Madeira",
            descricao = "Uma cerca rústica para delimitar sua propriedade.",
            preco = 50,
            icone = "rbxassetid://6797380001",
            categoria = "decoracoes",
            modelo3d = "cerca_madeira"
        },
        {
            id = "pedra_decorativa",
            nome = "Pedra Decorativa",
            descricao = "Uma pedra ornamental para seu jardim.",
            preco = 30,
            icone = "rbxassetid://6797380002",
            categoria = "decoracoes",
            modelo3d = "pedra_decorativa"
        },
        {
            id = "estatua_pequena",
            nome = "Estátua de Pedra",
            descricao = "Uma pequena estátua para decorar seu espaço.",
            preco = 150,
            icone = "rbxassetid://6797380003",
            categoria = "decoracoes",
            modelo3d = "estatua_pequena"
        },
        {
            id = "fonte_pedra",
            nome = "Fonte de Pedra",
            descricao = "Uma bela fonte que adiciona charme à sua ilha.",
            preco = 250,
            icone = "rbxassetid://6797380004",
            categoria = "decoracoes",
            modelo3d = "fonte_pedra"
        },
        {
            id = "luminaria_jardim",
            nome = "Luminária de Jardim",
            descricao = "Ilumina seu jardim durante a noite.",
            preco = 120,
            icone = "rbxassetid://6797380005",
            categoria = "decoracoes",
            modelo3d = "luminaria_jardim"
        },
        {
            id = "banco_parque",
            nome = "Banco de Parque",
            descricao = "Um lugar confortável para sentar e relaxar.",
            preco = 100,
            icone = "rbxassetid://6797380006",
            categoria = "decoracoes",
            modelo3d = "banco_parque"
        },
        {
            id = "caixa_correio",
            nome = "Caixa de Correio",
            descricao = "Receba mensagens de seus amigos.",
            preco = 80,
            icone = "rbxassetid://6797380007",
            categoria = "decoracoes",
            modelo3d = "caixa_correio"
        },
        {
            id = "estatua_grande",
            nome = "Estátua Grande",
            descricao = "Uma estátua imponente para sua ilha.",
            preco = 400,
            icone = "rbxassetid://6797380008",
            categoria = "decoracoes",
            modelo3d = "estatua_grande"
        },
        {
            id = "poste_sinalizacao",
            nome = "Poste de Sinalização",
            descricao = "Ajuda a orientar visitantes em sua ilha.",
            preco = 75,
            icone = "rbxassetid://6797380009",
            categoria = "decoracoes",
            modelo3d = "poste_sinalizacao"
        }
    },
    moveis = {
        {
            id = "mesa_madeira",
            nome = "Mesa de Madeira",
            descricao = "Uma mesa robusta para sua casa.",
            preco = 120,
            icone = "rbxassetid://6797380010",
            categoria = "moveis",
            modelo3d = "mesa_madeira"
        },
        {
            id = "cadeira_simples",
            nome = "Cadeira Simples",
            descricao = "Uma cadeira confortável para sua mesa.",
            preco = 80,
            icone = "rbxassetid://6797380011",
            categoria = "moveis",
            modelo3d = "cadeira_simples"
        },
        {
            id = "sofa_moderno",
            nome = "Sofá Moderno",
            descricao = "Um sofá elegante e confortável para sua sala.",
            preco = 200,
            icone = "rbxassetid://6797380012",
            categoria = "moveis",
            modelo3d = "sofa_moderno"
        },
        {
            id = "estante_livros",
            nome = "Estante de Livros",
            descricao = "Organize seus livros com estilo.",
            preco = 180,
            icone = "rbxassetid://6797380013",
            categoria = "moveis",
            modelo3d = "estante_livros"
        },
        {
            id = "cama_simples",
            nome = "Cama Simples",
            descricao = "Um lugar aconchegante para descansar.",
            preco = 150,
            icone = "rbxassetid://6797380014",
            categoria = "moveis",
            modelo3d = "cama_simples"
        }
    },
    plantas = {
        {
            id = "arvore_pequena",
            nome = "Árvore Pequena",
            descricao = "Uma árvore jovem para seu jardim.",
            preco = 100,
            icone = "rbxassetid://6797380015",
            categoria = "plantas",
            modelo3d = "arvore_pequena"
        },
        {
            id = "flor_azul",
            nome = "Flores Azuis",
            descricao = "Lindas flores azuis para colorir seu jardim.",
            preco = 45,
            icone = "rbxassetid://6797380016",
            categoria = "plantas",
            modelo3d = "flor_azul"
        },
        {
            id = "arvore_grande",
            nome = "Árvore Grande",
            descricao = "Uma árvore majestosa para dar sombra.",
            preco = 250,
            icone = "rbxassetid://6797380017",
            categoria = "plantas",
            modelo3d = "arvore_grande"
        },
        {
            id = "arbusto_flores",
            nome = "Arbusto Florido",
            descricao = "Um arbusto cheio de flores coloridas.",
            preco = 75,
            icone = "rbxassetid://6797380018",
            categoria = "plantas",
            modelo3d = "arbusto_flores"
        },
        {
            id = "palmeira",
            nome = "Palmeira",
            descricao = "Uma palmeira tropical para sua ilha.",
            preco = 180,
            icone = "rbxassetid://6797380019",
            categoria = "plantas",
            modelo3d = "palmeira"
        },
        {
            id = "jardim_flores",
            nome = "Jardim de Flores",
            descricao = "Um conjunto de flores variadas para seu jardim.",
            preco = 120,
            icone = "rbxassetid://6797380020",
            categoria = "plantas",
            modelo3d = "jardim_flores"
        }
    },
    especiais = {
        {
            id = "portal_magico",
            nome = "Portal Mágico",
            descricao = "Um portal místico que adiciona magia à sua ilha.",
            preco = 500,
            icone = "rbxassetid://6797380021",
            categoria = "especiais",
            modelo3d = "portal_magico"
        },
        {
            id = "cristal_energia",
            nome = "Cristal de Energia",
            descricao = "Um cristal brilhante que emana energia mágica.",
            preco = 350,
            icone = "rbxassetid://6797380022",
            categoria = "especiais",
            modelo3d = "cristal_energia"
        },
        {
            id = "altar_mistico",
            nome = "Altar Místico",
            descricao = "Um altar antigo com poderes misteriosos.",
            preco = 600,
            icone = "rbxassetid://6797380023",
            categoria = "especiais",
            modelo3d = "altar_mistico"
        }
    },
    ferramentas = {
        {
            id = "martelo_construcao",
            nome = "Martelo de Construção",
            descricao = "Ferramenta essencial para construir estruturas.",
            preco = 200,
            icone = "rbxassetid://6797380024",
            categoria = "ferramentas",
            modelo3d = "martelo_construcao"
        },
        {
            id = "pa_jardinagem",
            nome = "Pá de Jardinagem",
            descricao = "Ideal para plantar e cuidar do seu jardim.",
            preco = 150,
            icone = "rbxassetid://6797380025",
            categoria = "ferramentas",
            modelo3d = "pa_jardinagem"
        },
        {
            id = "regador",
            nome = "Regador",
            descricao = "Mantenha suas plantas saudáveis e hidratadas.",
            preco = 100,
            icone = "rbxassetid://6797380026",
            categoria = "ferramentas",
            modelo3d = "regador"
        }
    }
}

-- Traduções para nomes de categorias
local TRADUCOES = {
    categorias = {
        decoracoes = "Decorações",
        moveis = "Móveis",
        plantas = "Plantas",
        especiais = "Especiais",
        ferramentas = "Ferramentas"
    }
}

-- Elementos da interface
local elementosLoja = {
    categorias = {},
    botoesCategorias = {},
    itensVisiveis = {},
    itemSelecionado = nil,
    categoriaAtual = "decoracoes",
    termoPesquisa = ""
}

-- Função para formatar números grandes (ex: 1000 -> 1.000)
local function FormatarNumero(numero)
    local formatado = tostring(numero)
    local pos = string.len(formatado) - 3
    
    while pos > 0 do
        formatado = string.sub(formatado, 1, pos) .. "." .. string.sub(formatado, pos + 1)
        pos = pos - 3
    end
    
    return formatado
end

-- Criar botões de categorias
local function CriarBotoesCategorias(lojaFrame)
    local categoriaFrame = Instance.new("Frame")
    categoriaFrame.Name = "CategoriaFrame"
    categoriaFrame.Parent = lojaFrame
    categoriaFrame.Size = UDim2.new(1, 0, 0, 50)
    categoriaFrame.Position = UDim2.new(0, 0, 0, 110)
    categoriaFrame.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = categoriaFrame
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    
    local categorias = {"decoracoes", "moveis", "plantas", "especiais", "ferramentas"}
    
    for i, categoria in ipairs(categorias) do
        local botao = Instance.new("TextButton")
        botao.Name = categoria
        botao.Parent = categoriaFrame
        botao.Size = UDim2.new(0, 100, 1, 0)
        botao.BackgroundColor3 = CONFIG.corFundo
        botao.Text = TRADUCOES.categorias[categoria]
        botao.TextColor3 = CONFIG.corTexto
        botao.Font = Enum.Font.GothamSemibold
        botao.TextSize = 14
        botao.LayoutOrder = i
        
        -- Arredondar cantos
        local corner = Instance.new("UICorner")
        corner.Parent = botao
        corner.CornerRadius = UDim.new(0, 8)
        
        -- Adicionar efeito de hover
        botao.MouseEnter:Connect(function()
            if elementosLoja.categoriaAtual ~= categoria then
                TweenService:Create(botao, TweenInfo.new(0.2), {BackgroundColor3 = CONFIG.corSecundaria}):Play()
            end
        end)
        
        botao.MouseLeave:Connect(function()
            if elementosLoja.categoriaAtual ~= categoria then
                TweenService:Create(botao, TweenInfo.new(0.2), {BackgroundColor3 = CONFIG.corFundo}):Play()
            end
        end)
        
        -- Adicionar funcionalidade de clique
        botao.MouseButton1Click:Connect(function()
            -- Desativar botão anterior
            if elementosLoja.categoriaAtual and elementosLoja.botoesCategorias[elementosLoja.categoriaAtual] then
                TweenService:Create(elementosLoja.botoesCategorias[elementosLoja.categoriaAtual], 
                    TweenInfo.new(0.2), {BackgroundColor3 = CONFIG.corFundo}):Play()
            end
            
            -- Ativar novo botão
            TweenService:Create(botao, TweenInfo.new(0.2), {BackgroundColor3 = CONFIG.corPrimaria}):Play()
            
            -- Atualizar categoria atual
            elementosLoja.categoriaAtual = categoria
            
            -- Atualizar itens visíveis
            AtualizarItensVisiveis()
        end)
        
        -- Armazenar referência ao botão
        elementosLoja.botoesCategorias[categoria] = botao
    end
    
    -- Ativar categoria inicial
    TweenService:Create(elementosLoja.botoesCategorias[elementosLoja.categoriaAtual], 
        TweenInfo.new(0.2), {BackgroundColor3 = CONFIG.corPrimaria}):Play()
end

-- Criar campo de pesquisa
local function CriarCampoPesquisa(lojaFrame)
    local pesquisaFrame = Instance.new("Frame")
    pesquisaFrame.Name = "PesquisaFrame"
    pesquisaFrame.Parent = lojaFrame
    pesquisaFrame.Size = UDim2.new(1, -40, 0, 40)
    pesquisaFrame.Position = UDim2.new(0, 20, 0, 60)
    pesquisaFrame.BackgroundColor3 = CONFIG.corFundo
    
    local corner = Instance.new("UICorner")
    corner.Parent = pesquisaFrame
    corner.CornerRadius = UDim.new(0, 8)
    
    local pesquisaBox = Instance.new("TextBox")
    pesquisaBox.Name = "PesquisaBox"
    pesquisaBox.Parent = pesquisaFrame
    pesquisaBox.Size = UDim2.new(1, -20, 1, -10)
    pesquisaBox.Position = UDim2.new(0, 10, 0, 5)
    pesquisaBox.BackgroundTransparency = 1
    pesquisaBox.Text = ""
    pesquisaBox.PlaceholderText = "Pesquisar itens..."
    pesquisaBox.TextColor3 = CONFIG.corTexto
    pesquisaBox.Font = Enum.Font.Gotham
    pesquisaBox.TextSize = 14
    pesquisaBox.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Adicionar funcionalidade de pesquisa
    pesquisaBox:GetPropertyChangedSignal("Text"):Connect(function()
        elementosLoja.termoPesquisa = pesquisaBox.Text:lower()
        AtualizarItensVisiveis()
    end)
end

-- Criar grid de itens
local function CriarGridItens(lojaFrame)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemsScrollFrame"
    scrollFrame.Parent = lojaFrame
    scrollFrame.Size = UDim2.new(1, -40, 1, -180)
    scrollFrame.Position = UDim2.new(0, 20, 0, 170)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = CONFIG.corSecundaria
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local grid = Instance.new("UIGridLayout")
    grid.Parent = scrollFrame
    grid.CellSize = UDim2.new(0, 150, 0, 200)
    grid.CellPadding = UDim2.new(0, 10, 0, 10)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Armazenar referência ao grid
    elementosLoja.gridFrame = scrollFrame
end

-- Criar card para um item
local function CriarItemCard(item)
    local card = Instance.new("Frame")
    card.Name = item.id
    card.Size = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3 = CONFIG.corFundo
    
    local corner = Instance.new("UICorner")
    corner.Parent = card
    corner.CornerRadius = UDim.new(0, 8)
    
    -- Imagem do item
    local imagem = Instance.new("ImageLabel")
    imagem.Name = "Imagem"
    imagem.Parent = card
    imagem.Size = UDim2.new(1, -20, 0, 100)
    imagem.Position = UDim2.new(0, 10, 0, 10)
    imagem.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    imagem.Image = item.icone
    
    local imagemCorner = Instance.new("UICorner")
    imagemCorner.Parent = imagem
    imagemCorner.CornerRadius = UDim.new(0, 6)
    
    -- Nome do item
    local nome = Instance.new("TextLabel")
    nome.Name = "Nome"
    nome.Parent = card
    nome.Size = UDim2.new(1, -20, 0, 20)
    nome.Position = UDim2.new(0, 10, 0, 120)
    nome.BackgroundTransparency = 1
    nome.Text = item.nome
    nome.TextColor3 = CONFIG.corTexto
    nome.Font = Enum.Font.GothamBold
    nome.TextSize = 14
    nome.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Preço do item
    local preco = Instance.new("TextLabel")
    preco.Name = "Preco"
    preco.Parent = card
    preco.Size = UDim2.new(1, -20, 0, 20)
    preco.Position = UDim2.new(0, 10, 0, 140)
    preco.BackgroundTransparency = 1
    preco.Text = FormatarNumero(item.preco) .. " DC"
    preco.TextColor3 = CONFIG.corDestaque
    preco.Font = Enum.Font.GothamSemibold
    preco.TextSize = 14
    preco.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Botão de compra
    local botaoComprar = Instance.new("TextButton")
    botaoComprar.Name = "BotaoComprar"
    botaoComprar.Parent = card
    botaoComprar.Size = UDim2.new(1, -20, 0, 30)
    botaoComprar.Position = UDim2.new(0, 10, 0, 160)
    botaoComprar.BackgroundColor3 = CONFIG.corPrimaria
    botaoComprar.Text = "Comprar"
    botaoComprar.TextColor3 = CONFIG.corTexto
    botaoComprar.Font = Enum.Font.GothamBold
    botaoComprar.TextSize = 14
    
    local botaoCorner = Instance.new("UICorner")
    botaoCorner.Parent = botaoComprar
    botaoCorner.CornerRadius = UDim.new(0, 6)
    
    -- Adicionar efeito de hover
    botaoComprar.MouseEnter:Connect(function()
        TweenService:Create(botaoComprar, TweenInfo.new(0.2), {BackgroundColor3 = CONFIG.corSecundaria}):Play()
    end)
    
    botaoComprar.MouseLeave:Connect(function()
        TweenService:Create(botaoComprar, TweenInfo.new(0.2), {BackgroundColor3 = CONFIG.corPrimaria}):Play()
    end)
    
    -- Adicionar funcionalidade de compra
    botaoComprar.MouseButton1Click:Connect(function()
        -- Desabilitar botão durante o processamento
        botaoComprar.Text = "Processando..."
        botaoComprar.BackgroundColor3 = CONFIG.corSecundaria
        botaoComprar.Enabled = false
        
        -- Enviar evento de compra para o servidor
        ComprarItemEvent:FireServer(item.id)
        
        -- Aguardar resposta do servidor
        local conexao
        conexao = ComprarItemEvent.OnClientEvent:Connect(function(sucesso, mensagem, itemComprado)
            -- Verificar se é a resposta para este item
            if itemComprado ~= item.id then return end
            
            -- Desconectar evento
            conexao:Disconnect()
            
            -- Atualizar interface baseado no resultado
            if sucesso then
                botaoComprar.Text = "Comprado!"
                botaoComprar.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
                
                -- Mostrar mensagem de sucesso
                MostrarNotificacao(mensagem, true)
                
                -- Reativar botão após 2 segundos
                wait(2)
                botaoComprar.Enabled = true
                botaoComprar.Text = "Comprar"
                botaoComprar.BackgroundColor3 = CONFIG.corPrimaria
            else
                -- Mostrar mensagem de erro
                MostrarNotificacao(mensagem, false)
                
                -- Reativar botão
                botaoComprar.Enabled = true
                botaoComprar.Text = "Comprar"
                botaoComprar.BackgroundColor3 = CONFIG.corPrimaria
            end
        end)
        
        -- Timeout para caso o servidor não responda
        wait(5)
        if botaoComprar.Text == "Processando..." then
            botaoComprar.Enabled = true
            botaoComprar.Text = "Comprar"
            botaoComprar.BackgroundColor3 = CONFIG.corPrimaria
            
            -- Mostrar mensagem de erro
            MostrarNotificacao("Tempo esgotado. Tente novamente.", false)
            
            -- Desconectar evento
            if conexao then conexao:Disconnect() end
        end
    end)
    
    -- Adicionar efeito de clique no card
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Selecionar item
            SelecionarItem(item, card)
        end
    end)
    
    return card
end

-- Selecionar um item
function SelecionarItem(item, card)
    -- Deselecionar item anterior
    if elementosLoja.itemSelecionado then
        elementosLoja.itemSelecionado.BackgroundColor3 = CONFIG.corFundo
    end
    
    -- Selecionar novo item
    card.BackgroundColor3 = CONFIG.corSecundaria
    elementosLoja.itemSelecionado = card
    
    -- Mostrar detalhes do item
    MostrarDetalhesItem(item)
end

-- Mostrar detalhes do item
function MostrarDetalhesItem(item)
    -- Implementação futura
end

-- Mostrar notificação
function MostrarNotificacao(mensagem, sucesso)
    local gui = player.PlayerGui:WaitForChild("MainGui")
    local notificacao = gui:FindFirstChild("Notificacao")
    
    if not notificacao then
        notificacao = Instance.new("Frame")
        notificacao.Name = "Notificacao"
        notificacao.Parent = gui
        notificacao.Size = UDim2.new(0, 300, 0, 50)
        notificacao.Position = UDim2.new(0.5, -150, 0, -60)
        notificacao.BackgroundColor3 = CONFIG.corFundo
        notificacao.ZIndex = 10
        
        local corner = Instance.new("UICorner")
        corner.Parent = notificacao
        corner.CornerRadius = UDim.new(0, 8)
        
        local texto = Instance.new("TextLabel")
        texto.Name = "Texto"
        texto.Parent = notificacao
        texto.Size = UDim2.new(1, -20, 1, 0)
        texto.Position = UDim2.new(0, 10, 0, 0)
        texto.BackgroundTransparency = 1
        texto.TextColor3 = CONFIG.corTexto
        texto.Font = Enum.Font.GothamSemibold
        texto.TextSize = 14
        texto.TextWrapped = true
        texto.ZIndex = 11
    end
    
    -- Atualizar texto e cor
    local texto = notificacao:FindFirstChild("Texto")
    texto.Text = mensagem
    
    if sucesso then
        notificacao.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        notificacao.BackgroundColor3 = CONFIG.corErro
    end
    
    -- Animar entrada
    notificacao:TweenPosition(UDim2.new(0.5, -150, 0, 20), Enum.EasingDirection.Out, Enum.EasingStyle.Bounce, 0.5, true)
    
    -- Agendar saída
    spawn(function()
        wait(3)
        notificacao:TweenPosition(UDim2.new(0.5, -150, 0, -60), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5, true)
    end)
end

-- Atualizar itens visíveis com base na categoria e pesquisa
function AtualizarItensVisiveis()
    -- Limpar itens existentes
    for _, item in pairs(elementosLoja.itensVisiveis) do
        item:Destroy()
    end
    elementosLoja.itensVisiveis = {}
    
    -- Obter itens da categoria atual
    local itensCategoria = ITENS_LOJA[elementosLoja.categoriaAtual] or {}
    
    -- Filtrar por termo de pesquisa
    local itensFiltrados = {}
    local termoPesquisa = elementosLoja.termoPesquisa:lower()
    
    for _, item in ipairs(itensCategoria) do
        if termoPesquisa == "" or 
           string.find(item.nome:lower(), termoPesquisa) or 
           string.find(item.descricao:lower(), termoPesquisa) then
            table.insert(itensFiltrados, item)
        end
    end
    
    -- Criar cards para itens filtrados
    for i, item in ipairs(itensFiltrados) do
        local card = CriarItemCard(item)
        card.Parent = elementosLoja.gridFrame
        card.LayoutOrder = i
        
        table.insert(elementosLoja.itensVisiveis, card)
    end
    
    -- Atualizar tamanho do canvas
    local linhas = math.ceil(#itensFiltrados / 3)
    elementosLoja.gridFrame.CanvasSize = UDim2.new(0, 0, 0, linhas * 210)
end

-- Inicializar a interface da loja
local function InicializarLoja()
    local gui = player.PlayerGui:WaitForChild("MainGui")
    local lojaFrame = gui:WaitForChild("LojaFrame")
    
    -- Criar elementos da interface
    CriarCampoPesquisa(lojaFrame)
    CriarBotoesCategorias(lojaFrame)
    CriarGridItens(lojaFrame)
    
    -- Atualizar itens visíveis iniciais
    AtualizarItensVisiveis()
    
    print("LojaGui: Interface da loja inicializada")
end

-- Inicializar quando o script é carregado
InicializarLoja()
