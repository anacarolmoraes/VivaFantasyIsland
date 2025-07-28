--[[
    DragDropSystem.lua
    
    Sistema avançado de drag & drop para o jogo "Viva Fantasy Island"
    Permite arrastar itens do inventário para colocá-los na ilha,
    organizar o inventário, e oferece feedback visual durante o processo.
    
    Autor: Factory AI
    Data: 27/07/2025
]]

-- Serviços do Roblox
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

-- Jogador local
local jogador = Players.LocalPlayer
local mouse = jogador:GetMouse()

-- Referências à GUI
local mainGui = script.Parent
local inventarioFrame = mainGui:WaitForChild("InventarioFrame")
local construcaoFrame = mainGui:WaitForChild("ConstrucaoFrame")

-- Eventos Remotos
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local colocarDecoracaoEvent = RemoteEvents:WaitForChild("ColocarDecoracao")
local atualizarInventarioEvent = RemoteEvents:WaitForChild("AtualizarInventario")

-- Configurações
local CONFIG = {
    -- Configurações visuais
    TAMANHO_ARRASTO = UDim2.new(0, 80, 0, 80),  -- Tamanho do item durante arrasto
    TRANSPARENCIA_ARRASTO = 0.3,                -- Transparência do item durante arrasto
    COR_VALIDO = Color3.fromRGB(0, 255, 0),     -- Verde para drop válido
    COR_INVALIDO = Color3.fromRGB(255, 0, 0),   -- Vermelho para drop inválido
    DURACAO_ANIMACAO = 0.2,                     -- Duração das animações em segundos
    
    -- Configurações de grid
    GRID_TAMANHO = 10,                          -- Tamanho das células do grid
    GRID_ESPACAMENTO = 5,                       -- Espaçamento entre células
    GRID_SNAP_DISTANCIA = 15,                   -- Distância para snap ao grid
    
    -- Configurações de multi-seleção
    MULTI_SELECAO_TECLA = Enum.KeyCode.LeftShift, -- Tecla para multi-seleção
    MULTI_SELECAO_COR = Color3.fromRGB(0, 162, 255), -- Cor de destaque para multi-seleção
    
    -- Configurações de drop zones
    DROPZONE_TRANSPARENCIA = 0.7,               -- Transparência das drop zones
    DROPZONE_COR = Color3.fromRGB(0, 120, 215), -- Cor das drop zones
    
    -- Configurações de touch
    TOUCH_THRESHOLD = 30,                       -- Distância mínima para considerar arrasto em touch
    TOUCH_LONG_PRESS = 0.5                      -- Tempo para long press em segundos
}

-- Estado do sistema de drag & drop
local estado = {
    arrastando = false,           -- Se está arrastando um item
    itemArrastado = nil,          -- Item sendo arrastado
    itemOriginal = nil,           -- Referência ao item original
    posicaoInicial = nil,         -- Posição inicial do item
    offsetArrasto = Vector2.new(0, 0), -- Offset do mouse em relação ao item
    dropZones = {},               -- Lista de drop zones ativas
    itemSelecionados = {},        -- Itens selecionados para multi-arrasto
    modoMultiSelecao = false,     -- Se está no modo de multi-seleção
    ultimoToque = {               -- Dados do último toque (para mobile)
        posicao = nil,
        tempo = 0,
        longPress = false
    },
    gridAtivo = true,             -- Se o grid está ativo
    elementosUI = {},             -- Referências a elementos da UI
    conexoes = {}                 -- Conexões de eventos para limpar depois
}

-- Funções de utilidade

-- Função para criar uma animação de tween
local function CriarTween(objeto, propriedades, duracao, estilo, direcao)
    local info = TweenInfo.new(
        duracao or CONFIG.DURACAO_ANIMACAO,
        estilo or Enum.EasingStyle.Quad,
        direcao or Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(objeto, info, propriedades)
    return tween
end

-- Função para mostrar notificação
local function MostrarNotificacao(titulo, mensagem, tipo, duracao)
    duracao = duracao or 3 -- Duração padrão de 3 segundos
    
    -- Criar notificação na interface
    local notificacoesFrame = mainGui:WaitForChild("NotificacoesFrame")
    local templateNotificacao = notificacoesFrame:WaitForChild("TemplateNotificacao"):Clone()
    templateNotificacao.Name = "Notificacao_" .. os.time()
    templateNotificacao.Visible = true
    
    -- Configurar aparência baseado no tipo
    if tipo == "sucesso" then
        templateNotificacao.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde
    elseif tipo == "erro" then
        templateNotificacao.BackgroundColor3 = Color3.fromRGB(211, 47, 47) -- Vermelho
    else
        templateNotificacao.BackgroundColor3 = Color3.fromRGB(33, 150, 243) -- Azul (info)
    end
    
    -- Configurar texto
    local tituloLabel = Instance.new("TextLabel")
    tituloLabel.Name = "Titulo"
    tituloLabel.Size = UDim2.new(1, 0, 0, 20)
    tituloLabel.Position = UDim2.new(0, 0, 0, 0)
    tituloLabel.BackgroundTransparency = 1
    tituloLabel.TextColor3 = Color3.new(1, 1, 1)
    tituloLabel.TextSize = 14
    tituloLabel.Font = Enum.Font.SourceSansBold
    tituloLabel.Text = titulo
    tituloLabel.Parent = templateNotificacao
    
    local mensagemLabel = Instance.new("TextLabel")
    mensagemLabel.Name = "Mensagem"
    mensagemLabel.Size = UDim2.new(1, 0, 0, 40)
    mensagemLabel.Position = UDim2.new(0, 0, 0, 20)
    mensagemLabel.BackgroundTransparency = 1
    mensagemLabel.TextColor3 = Color3.new(1, 1, 1)
    mensagemLabel.TextSize = 12
    mensagemLabel.Font = Enum.Font.SourceSans
    mensagemLabel.Text = mensagem
    mensagemLabel.TextWrapped = true
    mensagemLabel.Parent = templateNotificacao
    
    -- Posicionar notificação
    templateNotificacao.Position = UDim2.new(1, 300, 1, -80) -- Começa fora da tela
    templateNotificacao.AnchorPoint = Vector2.new(1, 1)
    templateNotificacao.Parent = notificacoesFrame
    
    -- Animação de entrada
    local tweenEntrada = CriarTween(templateNotificacao, {Position = UDim2.new(1, -20, 1, -80)}, 0.5)
    tweenEntrada:Play()
    
    -- Animação de saída após duração
    task.delay(duracao, function()
        local tweenSaida = CriarTween(templateNotificacao, {Position = UDim2.new(1, 300, 1, -80)}, 0.5)
        tweenSaida:Play()
        tweenSaida.Completed:Connect(function()
            templateNotificacao:Destroy()
        end)
    end)
end

-- Função para verificar se um ponto está dentro de um elemento GUI
local function PontoEmElemento(ponto, elemento)
    local posicao = elemento.AbsolutePosition
    local tamanho = elemento.AbsoluteSize
    
    return ponto.X >= posicao.X and ponto.X <= posicao.X + tamanho.X and
           ponto.Y >= posicao.Y and ponto.Y <= posicao.Y + tamanho.Y
end

-- Função para obter a posição do grid mais próxima
local function ObterPosicaoGrid(posicao)
    if not estado.gridAtivo then return posicao end
    
    local gridX = math.round(posicao.X / (CONFIG.GRID_TAMANHO + CONFIG.GRID_ESPACAMENTO)) * 
                 (CONFIG.GRID_TAMANHO + CONFIG.GRID_ESPACAMENTO)
    local gridY = math.round(posicao.Y / (CONFIG.GRID_TAMANHO + CONFIG.GRID_ESPACAMENTO)) * 
                 (CONFIG.GRID_TAMANHO + CONFIG.GRID_ESPACAMENTO)
    
    return Vector2.new(gridX, gridY)
end

-- Função para verificar se um drop é válido
local function VerificarDropValido(posicao)
    -- Verificar se está sobre uma drop zone
    for _, dropZone in ipairs(estado.dropZones) do
        if PontoEmElemento(posicao, dropZone) then
            return true, dropZone
        end
    end
    
    return false, nil
end

-- Funções principais do sistema de drag & drop

-- Função para criar o clone de arrasto
local function CriarCloneArrasto(item)
    -- Criar um clone do item para arrastar
    local clone = item:Clone()
    clone.Name = "ArrastoClone_" .. item.Name
    clone.Size = CONFIG.TAMANHO_ARRASTO
    clone.BackgroundTransparency = CONFIG.TRANSPARENCIA_ARRASTO
    clone.ZIndex = 1000 -- Garantir que fique acima de tudo
    
    -- Remover elementos internos que não queremos no clone
    for _, child in pairs(clone:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    clone.Parent = mainGui
    return clone
end

-- Função para iniciar o arrasto
local function IniciarArrasto(item, inputPosition)
    if estado.arrastando then return end
    
    print("🔄 DRAG & DROP: Iniciando arrasto do item: " .. item.Name)
    
    -- Guardar referências
    estado.arrastando = true
    estado.itemOriginal = item
    estado.posicaoInicial = item.Position
    
    -- Calcular offset do mouse em relação ao item
    local itemPos = item.AbsolutePosition
    estado.offsetArrasto = Vector2.new(
        inputPosition.X - itemPos.X,
        inputPosition.Y - itemPos.Y
    )
    
    -- Criar clone para arrastar
    estado.itemArrastado = CriarCloneArrasto(item)
    
    -- Animar item original (reduzir opacidade)
    item.BackgroundTransparency = 0.7
    
    -- Posicionar clone na posição do mouse
    AtualizarPosicaoArrasto(inputPosition)
    
    -- Mostrar drop zones
    MostrarDropZones()
    
    -- Feedback visual
    local efeitoSelecao = Instance.new("UIStroke")
    efeitoSelecao.Name = "EfeitoSelecao"
    efeitoSelecao.Color = CONFIG.COR_VALIDO
    efeitoSelecao.Thickness = 2
    efeitoSelecao.Parent = estado.itemArrastado
    
    -- Iniciar animação de pulso
    IniciarAnimacaoPulso(efeitoSelecao)
end

-- Função para iniciar animação de pulso
function IniciarAnimacaoPulso(objeto)
    -- Criar sequência de animação de pulso
    spawn(function()
        while estado.arrastando and objeto and objeto.Parent do
            -- Pulsar para fora
            local tweenExpand = CriarTween(objeto, {Thickness = 3}, 0.5)
            tweenExpand:Play()
            tweenExpand.Completed:Wait()
            
            -- Pulsar para dentro
            local tweenContract = CriarTween(objeto, {Thickness = 1}, 0.5)
            tweenContract:Play()
            tweenContract.Completed:Wait()
        end
    end)
end

-- Função para atualizar a posição do item sendo arrastado
function AtualizarPosicaoArrasto(inputPosition)
    if not estado.arrastando or not estado.itemArrastado then return end
    
    -- Calcular nova posição considerando o offset
    local novaPosicao = Vector2.new(
        inputPosition.X - estado.offsetArrasto.X,
        inputPosition.Y - estado.offsetArrasto.Y
    )
    
    -- Aplicar snap ao grid se ativado
    if estado.gridAtivo then
        novaPosicao = ObterPosicaoGrid(novaPosicao)
    end
    
    -- Atualizar posição do clone
    estado.itemArrastado.Position = UDim2.new(
        0, novaPosicao.X,
        0, novaPosicao.Y
    )
    
    -- Verificar se está sobre uma drop zone válida
    local valido, dropZone = VerificarDropValido(inputPosition)
    
    -- Atualizar feedback visual
    local efeitoSelecao = estado.itemArrastado:FindFirstChild("EfeitoSelecao")
    if efeitoSelecao then
        efeitoSelecao.Color = valido and CONFIG.COR_VALIDO or CONFIG.COR_INVALIDO
    end
    
    -- Destacar drop zone atual
    DestacarDropZone(dropZone)
end

-- Função para destacar uma drop zone
function DestacarDropZone(dropZone)
    -- Resetar todas as drop zones
    for _, zone in ipairs(estado.dropZones) do
        zone.BackgroundColor3 = CONFIG.DROPZONE_COR
        zone.BackgroundTransparency = CONFIG.DROPZONE_TRANSPARENCIA
    end
    
    -- Destacar a drop zone atual
    if dropZone then
        dropZone.BackgroundColor3 = CONFIG.COR_VALIDO
        dropZone.BackgroundTransparency = CONFIG.DROPZONE_TRANSPARENCIA - 0.2
    end
end

-- Função para finalizar o arrasto
function FinalizarArrasto(inputPosition)
    if not estado.arrastando then return end
    
    print("🔄 DRAG & DROP: Finalizando arrasto")
    
    -- Verificar se o drop é válido
    local valido, dropZone = VerificarDropValido(inputPosition)
    
    if valido then
        -- Processar o drop válido
        ProcessarDropValido(dropZone)
    else
        -- Retornar o item à posição original com animação
        RetornarItemOriginal()
    end
    
    -- Limpar estado
    LimparEstadoArrasto()
    
    -- Esconder drop zones
    EsconderDropZones()
end

-- Função para processar um drop válido
function ProcessarDropValido(dropZone)
    print("🔄 DRAG & DROP: Drop válido na zona: " .. dropZone.Name)
    
    -- Identificar o tipo de drop zone
    if dropZone.Name:match("^DropZone_Inventario") then
        -- Reorganizar no inventário
        ReorganizarInventario(dropZone)
    elseif dropZone.Name:match("^DropZone_Construcao") then
        -- Colocar item na ilha
        ColocarItemNaIlha(dropZone)
    elseif dropZone.Name:match("^DropZone_Categoria") then
        -- Mover para outra categoria
        MoverParaCategoria(dropZone)
    end
    
    -- Animação de sucesso
    local efeitoSucesso = Instance.new("Frame")
    efeitoSucesso.Size = UDim2.new(1, 0, 1, 0)
    efeitoSucesso.BackgroundColor3 = CONFIG.COR_VALIDO
    efeitoSucesso.BackgroundTransparency = 0.5
    efeitoSucesso.ZIndex = 999
    efeitoSucesso.Parent = dropZone
    
    -- Animar e remover o efeito
    local tweenFade = CriarTween(efeitoSucesso, {BackgroundTransparency = 1}, 0.5)
    tweenFade:Play()
    tweenFade.Completed:Connect(function()
        efeitoSucesso:Destroy()
    end)
end

-- Função para reorganizar item no inventário
function ReorganizarInventario(dropZone)
    -- Obter informações do item e posição de destino
    local itemId = estado.itemOriginal:GetAttribute("ItemId")
    local posicaoDestino = dropZone:GetAttribute("PosicaoGrid")
    
    if not itemId or not posicaoDestino then
        print("🔄 DRAG & DROP: Faltam atributos para reorganização")
        return
    end
    
    -- Enviar evento para o servidor para reorganizar
    -- (Esta parte depende da implementação do servidor)
    ReplicatedStorage.RemoteEvents.ReorganizarInventario:FireServer(itemId, posicaoDestino)
    
    -- Feedback visual local imediato
    estado.itemOriginal.Position = dropZone.Position
    estado.itemOriginal.BackgroundTransparency = 0
    
    MostrarNotificacao("Item Movido", "Item reorganizado no inventário", "sucesso", 2)
end

-- Função para colocar item na ilha (integração com sistema de construção)
function ColocarItemNaIlha(dropZone)
    -- Obter informações do item
    local itemId = estado.itemOriginal:GetAttribute("ItemId")
    if not itemId then
        print("🔄 DRAG & DROP: Falta ID do item para colocação")
        return
    end
    
    -- Converter posição da tela para posição 3D no mundo
    -- (Esta é uma simplificação, a posição real dependeria de raycast)
    local posicao3D = workspace.CurrentCamera:ScreenPointToRay(
        mouse.X, 
        mouse.Y, 
        100 -- Distância do raio
    ).Origin
    
    -- Enviar evento para o servidor para colocar o item
    colocarDecoracaoEvent:FireServer(itemId, posicao3D, 0) -- 0 = rotação padrão
    
    -- Feedback visual
    MostrarNotificacao(
        "Item Colocado",
        "Item colocado na ilha! Use o modo construção para ajustar a posição.",
        "sucesso",
        3
    )
    
    -- Reduzir a quantidade no inventário (feedback visual imediato)
    local quantidadeLabel = estado.itemOriginal:FindFirstChild("Quantidade")
    if quantidadeLabel and tonumber(quantidadeLabel.Text) > 1 then
        quantidadeLabel.Text = tostring(tonumber(quantidadeLabel.Text) - 1)
    else
        -- Se for o último, podemos esconder temporariamente até a atualização do servidor
        estado.itemOriginal.BackgroundTransparency = 0.9
    end
end

-- Função para mover item para outra categoria
function MoverParaCategoria(dropZone)
    -- Obter informações do item e categoria de destino
    local itemId = estado.itemOriginal:GetAttribute("ItemId")
    local categoriaDestino = dropZone:GetAttribute("Categoria")
    
    if not itemId or not categoriaDestino then
        print("🔄 DRAG & DROP: Faltam atributos para mudança de categoria")
        return
    end
    
    -- Enviar evento para o servidor para mudar categoria
    -- (Esta parte depende da implementação do servidor)
    ReplicatedStorage.RemoteEvents.MudarCategoriaItem:FireServer(itemId, categoriaDestino)
    
    -- Feedback visual
    MostrarNotificacao(
        "Categoria Alterada",
        "Item movido para a categoria: " .. categoriaDestino,
        "sucesso",
        2
    )
    
    -- O servidor deve atualizar a interface após a mudança de categoria
end

-- Função para retornar o item à posição original
function RetornarItemOriginal()
    -- Animar o clone retornando à posição original
    local tweenRetorno = CriarTween(
        estado.itemArrastado,
        {Position = UDim2.new(
            estado.posicaoInicial.X.Scale,
            estado.posicaoInicial.X.Offset,
            estado.posicaoInicial.Y.Scale,
            estado.posicaoInicial.Y.Offset
        )},
        0.3
    )
    
    tweenRetorno:Play()
    tweenRetorno.Completed:Connect(function()
        -- Restaurar opacidade do item original
        estado.itemOriginal.BackgroundTransparency = 0
        
        -- Remover o clone
        if estado.itemArrastado and estado.itemArrastado.Parent then
            estado.itemArrastado:Destroy()
        end
    end)
end

-- Função para limpar o estado do arrasto
function LimparEstadoArrasto()
    -- Remover o clone se ainda existir
    if estado.itemArrastado and estado.itemArrastado.Parent then
        estado.itemArrastado:Destroy()
    end
    
    -- Restaurar opacidade do item original
    if estado.itemOriginal then
        estado.itemOriginal.BackgroundTransparency = 0
    end
    
    -- Resetar estado
    estado.arrastando = false
    estado.itemArrastado = nil
    estado.itemOriginal = nil
    estado.posicaoInicial = nil
    estado.offsetArrasto = Vector2.new(0, 0)
end

-- Funções para gerenciar drop zones

-- Função para criar drop zones
function CriarDropZones()
    print("🔄 DRAG & DROP: Criando drop zones")
    
    -- Limpar drop zones existentes
    for _, dropZone in ipairs(estado.dropZones) do
        if dropZone and dropZone.Parent then
            dropZone:Destroy()
        end
    end
    estado.dropZones = {}
    
    -- Criar drop zones no inventário (grid)
    local gridInventario = inventarioFrame:FindFirstChild("GridFrame")
    if gridInventario then
        -- Criar uma drop zone para cada posição no grid
        for i = 0, 3 do -- Linhas
            for j = 0, 3 do -- Colunas
                local dropZone = Instance.new("Frame")
                dropZone.Name = "DropZone_Inventario_" .. i .. "_" .. j
                dropZone.Size = UDim2.new(0, CONFIG.GRID_TAMANHO, 0, CONFIG.GRID_TAMANHO)
                dropZone.Position = UDim2.new(
                    0, j * (CONFIG.GRID_TAMANHO + CONFIG.GRID_ESPACAMENTO) + 10,
                    0, i * (CONFIG.GRID_TAMANHO + CONFIG.GRID_ESPACAMENTO) + 10
                )
                dropZone.BackgroundColor3 = CONFIG.DROPZONE_COR
                dropZone.BackgroundTransparency = 1 -- Inicialmente invisível
                dropZone.ZIndex = 10
                dropZone:SetAttribute("PosicaoGrid", {linha = i, coluna = j})
                dropZone.Parent = gridInventario
                
                table.insert(estado.dropZones, dropZone)
            end
        end
    end
    
    -- Criar drop zones para categorias
    local categoriaFrame = inventarioFrame:FindFirstChild("CategoriaFrame")
    if categoriaFrame then
        local categorias = {"todos", "decoracoes", "moveis", "plantas"}
        
        for i, categoria in ipairs(categorias) do
            local botaoCategoria = categoriaFrame:FindFirstChild("Categoria_" .. categoria)
            if botaoCategoria then
                local dropZone = Instance.new("Frame")
                dropZone.Name = "DropZone_Categoria_" .. categoria
                dropZone.Size = botaoCategoria.Size
                dropZone.Position = botaoCategoria.Position
                dropZone.BackgroundColor3 = CONFIG.DROPZONE_COR
                dropZone.BackgroundTransparency = 1 -- Inicialmente invisível
                dropZone.ZIndex = 10
                dropZone:SetAttribute("Categoria", categoria)
                dropZone.Parent = categoriaFrame
                
                table.insert(estado.dropZones, dropZone)
            end
        end
    end
    
    -- Criar drop zone para construção (colocar na ilha)
    local dropZoneConstrucao = Instance.new("Frame")
    dropZoneConstrucao.Name = "DropZone_Construcao"
    dropZoneConstrucao.Size = UDim2.new(1, 0, 1, 0)
    dropZoneConstrucao.Position = UDim2.new(0, 0, 0, 0)
    dropZoneConstrucao.BackgroundColor3 = CONFIG.DROPZONE_COR
    dropZoneConstrucao.BackgroundTransparency = 1 -- Inicialmente invisível
    dropZoneConstrucao.ZIndex = 5
    dropZoneConstrucao.Parent = mainGui
    
    table.insert(estado.dropZones, dropZoneConstrucao)
    
    print("🔄 DRAG & DROP: " .. #estado.dropZones .. " drop zones criadas")
end

-- Função para mostrar drop zones
function MostrarDropZones()
    for _, dropZone in ipairs(estado.dropZones) do
        -- Animar aparecimento
        local tween = CriarTween(dropZone, {BackgroundTransparency = CONFIG.DROPZONE_TRANSPARENCIA}, 0.3)
        tween:Play()
    end
end

-- Função para esconder drop zones
function EsconderDropZones()
    for _, dropZone in ipairs(estado.dropZones) do
        -- Animar desaparecimento
        local tween = CriarTween(dropZone, {BackgroundTransparency = 1}, 0.3)
        tween:Play()
    end
end

-- Funções para multi-seleção

-- Função para alternar seleção de um item
function AlternarSelecaoItem(item)
    local itemId = item:GetAttribute("ItemId")
    if not itemId then return end
    
    -- Verificar se já está selecionado
    local jaSelecionado = false
    for i, selecionado in ipairs(estado.itemSelecionados) do
        if selecionado.id == itemId then
            -- Remover da seleção
            table.remove(estado.itemSelecionados, i)
            jaSelecionado = true
            break
        end
    end
    
    -- Se não estava selecionado, adicionar à seleção
    if not jaSelecionado then
        table.insert(estado.itemSelecionados, {
            id = itemId,
            elemento = item
        })
    end
    
    -- Atualizar visual
    AtualizarVisualMultiSelecao()
end

-- Função para atualizar o visual da multi-seleção
function AtualizarVisualMultiSelecao()
    -- Limpar efeitos visuais existentes
    for _, item in pairs(inventarioFrame:FindFirstChild("GridFrame"):GetChildren()) do
        if item:IsA("Frame") and item:FindFirstChild("EfeitoMultiSelecao") then
            item.EfeitoMultiSelecao:Destroy()
        end
    end
    
    -- Aplicar efeito visual aos itens selecionados
    for _, selecionado in ipairs(estado.itemSelecionados) do
        local item = selecionado.elemento
        if item and item.Parent then
            local efeito = Instance.new("UIStroke")
            efeito.Name = "EfeitoMultiSelecao"
            efeito.Color = CONFIG.MULTI_SELECAO_COR
            efeito.Thickness = 3
            efeito.Parent = item
        end
    end
    
    -- Atualizar contador de seleção, se existir
    local contadorSelecao = mainGui:FindFirstChild("ContadorMultiSelecao")
    if #estado.itemSelecionados > 0 then
        if not contadorSelecao then
            contadorSelecao = Instance.new("Frame")
            contadorSelecao.Name = "ContadorMultiSelecao"
            contadorSelecao.Size = UDim2.new(0, 50, 0, 50)
            contadorSelecao.Position = UDim2.new(0, 20, 0, 20)
            contadorSelecao.BackgroundColor3 = CONFIG.MULTI_SELECAO_COR
            contadorSelecao.BackgroundTransparency = 0.3
            contadorSelecao.BorderSizePixel = 0
            contadorSelecao.ZIndex = 1000
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = contadorSelecao
            
            local texto = Instance.new("TextLabel")
            texto.Name = "Contador"
            texto.Size = UDim2.new(1, 0, 1, 0)
            texto.BackgroundTransparency = 1
            texto.TextColor3 = Color3.new(1, 1, 1)
            texto.TextSize = 24
            texto.Font = Enum.Font.SourceSansBold
            texto.Text = #estado.itemSelecionados
            texto.ZIndex = 1001
            texto.Parent = contadorSelecao
            
            contadorSelecao.Parent = mainGui
        else
            contadorSelecao.Contador.Text = #estado.itemSelecionados
        end
    elseif contadorSelecao then
        contadorSelecao:Destroy()
    end
end

-- Função para iniciar arrasto de múltiplos itens
function IniciarArrastoMultiplo(inputPosition)
    if #estado.itemSelecionados == 0 then return end
    
    print("🔄 DRAG & DROP: Iniciando arrasto múltiplo de " .. #estado.itemSelecionados .. " itens")
    
    -- Criar um container para os itens selecionados
    local containerMulti = Instance.new("Frame")
    containerMulti.Name = "ArrastoMultiplo"
    containerMulti.Size = UDim2.new(0, 150, 0, 150)
    containerMulti.BackgroundTransparency = 1
    containerMulti.ZIndex = 1000
    containerMulti.Parent = mainGui
    
    -- Posicionar container na posição do mouse
    containerMulti.Position = UDim2.new(0, inputPosition.X - 75, 0, inputPosition.Y - 75)
    
    -- Adicionar representação visual de cada item
    local gridSize = math.ceil(math.sqrt(#estado.itemSelecionados))
    local itemSize = 150 / gridSize
    
    for i, selecionado in ipairs(estado.itemSelecionados) do
        local linha = math.floor((i-1) / gridSize)
        local coluna = (i-1) % gridSize
        
        local itemClone = Instance.new("ImageLabel")
        itemClone.Name = "Item_" .. selecionado.id
        itemClone.Size = UDim2.new(0, itemSize - 4, 0, itemSize - 4)
        itemClone.Position = UDim2.new(0, coluna * itemSize + 2, 0, linha * itemSize + 2)
        itemClone.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        itemClone.BackgroundTransparency = 0.3
        itemClone.Image = selecionado.elemento:FindFirstChild("Imagem") and 
                          selecionado.elemento.Imagem.Image or ""
        itemClone.ZIndex = 1001
        itemClone.Parent = containerMulti
        
        -- Adicionar contador se houver mais de um do mesmo item
        local quantidade = selecionado.elemento:FindFirstChild("Quantidade")
        if quantidade and quantidade.Text and tonumber(quantidade.Text) > 1 then
            local quantidadeLabel = Instance.new("TextLabel")
            quantidadeLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
            quantidadeLabel.Position = UDim2.new(0.5, 0, 0.7, 0)
            quantidadeLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            quantidadeLabel.BackgroundTransparency = 0.3
            quantidadeLabel.TextColor3 = Color3.new(1, 1, 1)
            quantidadeLabel.TextSize = 12
            quantidadeLabel.Font = Enum.Font.SourceSansBold
            quantidadeLabel.Text = quantidade.Text
            quantidadeLabel.ZIndex = 1002
            quantidadeLabel.Parent = itemClone
        end
        
        -- Reduzir opacidade do item original
        selecionado.elemento.BackgroundTransparency = 0.7
    end
    
    -- Guardar referências
    estado.arrastando = true
    estado.itemArrastado = containerMulti
    estado.offsetArrasto = Vector2.new(75, 75)
    
    -- Mostrar drop zones
    MostrarDropZones()
    
    -- Efeito visual
    local efeitoSelecao = Instance.new("UIStroke")
    efeitoSelecao.Name = "EfeitoSelecao"
    efeitoSelecao.Color = CONFIG.COR_VALIDO
    efeitoSelecao.Thickness = 2
    efeitoSelecao.Parent = containerMulti
    
    -- Iniciar animação de pulso
    IniciarAnimacaoPulso(efeitoSelecao)
end

-- Função para finalizar arrasto múltiplo
function FinalizarArrastoMultiplo(inputPosition)
    if not estado.arrastando or #estado.itemSelecionados == 0 then return end
    
    print("🔄 DRAG & DROP: Finalizando arrasto múltiplo")
    
    -- Verificar se o drop é válido
    local valido, dropZone = VerificarDropValido(inputPosition)
    
    if valido then
        -- Processar o drop válido para todos os itens selecionados
        ProcessarDropMultiplo(dropZone)
    else
        -- Retornar os itens à posição original
        RetornarItensOriginais()
    end
    
    -- Limpar estado
    LimparEstadoArrasto()
    
    -- Esconder drop zones
    EsconderDropZones()
    
    -- Limpar seleção
    estado.itemSelecionados = {}
    AtualizarVisualMultiSelecao()
end

-- Função para processar drop múltiplo
function ProcessarDropMultiplo(dropZone)
    print("🔄 DRAG & DROP: Drop múltiplo na zona: " .. dropZone.Name)
    
    -- Identificar o tipo de drop zone
    if dropZone.Name:match("^DropZone_Inventario") then
        -- Reorganizar no inventário (não implementado para múltiplos)
        MostrarNotificacao(
            "Não Suportado",
            "Reorganização de múltiplos itens não suportada ainda.",
            "info",
            3
        )
    elseif dropZone.Name:match("^DropZone_Construcao") then
        -- Colocar múltiplos itens na ilha
        ColocarMultiplosItensNaIlha()
    elseif dropZone.Name:match("^DropZone_Categoria") then
        -- Mover múltiplos itens para categoria
        MoverMultiplosParaCategoria(dropZone)
    end
    
    -- Animação de sucesso
    local efeitoSucesso = Instance.new("Frame")
    efeitoSucesso.Size = UDim2.new(1, 0, 1, 0)
    efeitoSucesso.BackgroundColor3 = CONFIG.COR_VALIDO
    efeitoSucesso.BackgroundTransparency = 0.5
    efeitoSucesso.ZIndex = 999
    efeitoSucesso.Parent = dropZone
    
    -- Animar e remover o efeito
    local tweenFade = CriarTween(efeitoSucesso, {BackgroundTransparency = 1}, 0.5)
    tweenFade:Play()
    tweenFade.Completed:Connect(function()
        efeitoSucesso:Destroy()
    end)
end

-- Função para colocar múltiplos itens na ilha
function ColocarMultiplosItensNaIlha()
    -- Obter lista de IDs de itens
    local itemIds = {}
    for _, selecionado in ipairs(estado.itemSelecionados) do
        table.insert(itemIds, selecionado.id)
    end
    
    -- Enviar evento para o servidor
    -- (Esta parte depende da implementação do servidor)
    ReplicatedStorage.RemoteEvents.ColocarMultiplosItens:FireServer(itemIds)
    
    -- Feedback visual
    MostrarNotificacao(
        "Itens Colocados",
        #itemIds .. " itens foram colocados na ilha.",
        "sucesso",
        3
    )
    
    -- Atualizar quantidades (feedback visual imediato)
    for _, selecionado in ipairs(estado.itemSelecionados) do
        local quantidadeLabel = selecionado.elemento:FindFirstChild("Quantidade")
        if quantidadeLabel and tonumber(quantidadeLabel.Text) > 1 then
            quantidadeLabel.Text = tostring(tonumber(quantidadeLabel.Text) - 1)
        else
            -- Se for o último, podemos esconder temporariamente
            selecionado.elemento.BackgroundTransparency = 0.9
        end
    end
end

-- Função para mover múltiplos itens para categoria
function MoverMultiplosParaCategoria(dropZone)
    -- Obter categoria de destino
    local categoriaDestino = dropZone:GetAttribute("Categoria")
    if not categoriaDestino then return end
    
    -- Obter lista de IDs de itens
    local itemIds = {}
    for _, selecionado in ipairs(estado.itemSelecionados) do
        table.insert(itemIds, selecionado.id)
    end
    
    -- Enviar evento para o servidor
    -- (Esta parte depende da implementação do servidor)
    ReplicatedStorage.RemoteEvents.MudarCategoriaMultiplos:FireServer(itemIds, categoriaDestino)
    
    -- Feedback visual
    MostrarNotificacao(
        "Categoria Alterada",
        #itemIds .. " itens movidos para a categoria: " .. categoriaDestino,
        "sucesso",
        3
    )
    
    -- O servidor deve atualizar a interface após a mudança de categoria
end

-- Função para retornar os itens originais
function RetornarItensOriginais()
    -- Restaurar opacidade dos itens originais
    for _, selecionado in ipairs(estado.itemSelecionados) do
        if selecionado.elemento then
            selecionado.elemento.BackgroundTransparency = 0
        end
    end
    
    -- Remover o container de arrasto
    if estado.itemArrastado and estado.itemArrastado.Parent then
        -- Animar desaparecimento
        local tweenFade = CriarTween(estado.itemArrastado, {BackgroundTransparency = 1}, 0.3)
        tweenFade:Play()
        tweenFade.Completed:Connect(function()
            estado.itemArrastado:Destroy()
        end)
    end
end

-- Funções para suporte a touch (mobile)

-- Função para processar início de toque
function ProcessarInicioToque(input)
    -- Guardar informações do toque
    estado.ultimoToque.posicao = input.Position
    estado.ultimoToque.tempo = tick()
    estado.ultimoToque.longPress = false
    
    -- Iniciar timer para long press
    spawn(function()
        wait(CONFIG.TOUCH_LONG_PRESS)
        if estado.ultimoToque.posicao and 
           (estado.ultimoToque.posicao - input.Position).magnitude < CONFIG.TOUCH_THRESHOLD then
            estado.ultimoToque.longPress = true
            
            -- Verificar se está tocando em um item do inventário
            local itemSobToque = EncontrarItemSobPosicao(input.Position)
            if itemSobToque then
                -- Long press em item do inventário ativa multi-seleção
                AlternarSelecaoItem(itemSobToque)
            end
        end
    end)
end

-- Função para processar movimento de toque
function ProcessarMovimentoToque(input)
    -- Verificar se houve movimento significativo
    if not estado.ultimoToque.posicao or 
       (estado.ultimoToque.posicao - input.Position).magnitude < CONFIG.TOUCH_THRESHOLD then
        return
    end
    
    -- Se ainda não estiver arrastando, iniciar arrasto
    if not estado.arrastando then
        -- Verificar se está tocando em um item do inventário
        local itemSobToque = EncontrarItemSobPosicao(estado.ultimoToque.posicao)
        if itemSobToque then
            if #estado.itemSelecionados > 0 and estado.ultimoToque.longPress then
                -- Iniciar arrasto múltiplo
                IniciarArrastoMultiplo(estado.ultimoToque.posicao)
            else
                -- Iniciar arrasto simples
                IniciarArrasto(itemSobToque, estado.ultimoToque.posicao)
            end
        end
    end
    
    -- Atualizar posição do arrasto
    if estado.arrastando then
        AtualizarPosicaoArrasto(input.Position)
    end
end

-- Função para processar fim de toque
function ProcessarFimToque(input)
    -- Se estiver arrastando, finalizar arrasto
    if estado.arrastando then
        if #estado.itemSelecionados > 0 and estado.ultimoToque.longPress then
            FinalizarArrastoMultiplo(input.Position)
        else
            FinalizarArrasto(input.Position)
        end
    elseif not estado.ultimoToque.longPress then
        -- Toque simples (sem arrasto nem long press)
        local itemSobToque = EncontrarItemSobPosicao(input.Position)
        if itemSobToque then
            -- Toque simples em item do inventário seleciona para detalhes
            SelecionarItemParaDetalhes(itemSobToque)
        end
    end
    
    -- Limpar informações de toque
    estado.ultimoToque.posicao = nil
    estado.ultimoToque.tempo = 0
    estado.ultimoToque.longPress = false
}

-- Função para encontrar item sob uma posição
function EncontrarItemSobPosicao(posicao)
    -- Verificar se o inventário está visível
    if not inventarioFrame.Visible then return nil end
    
    local gridFrame = inventarioFrame:FindFirstChild("GridFrame")
    if not gridFrame then return nil end
    
    -- Verificar cada item no grid
    for _, item in pairs(gridFrame:GetChildren()) do
        if item:IsA("Frame") and item.Name:match("^Celula_") and PontoEmElemento(posicao, item) then
            return item
        end
    end
    
    return nil
end

-- Função para selecionar um item para mostrar detalhes
function SelecionarItemParaDetalhes(item)
    -- Obter informações do item
    local itemId = item:GetAttribute("ItemId")
    if not itemId then return end
    
    print("🔄 DRAG & DROP: Selecionando item para detalhes: " .. itemId)
    
    -- Atualizar detalhes no painel lateral
    local detalhesFrame = inventarioFrame:FindFirstChild("DetalhesFrame")
    if detalhesFrame then
        detalhesFrame.Visible = true
        
        -- Atualizar imagem
        local itemImagem = detalhesFrame:FindFirstChild("ItemImagem")
        if itemImagem then
            itemImagem.Image = item:FindFirstChild("Imagem") and item.Imagem.Image or ""
        end
        
        -- Atualizar nome
        local itemNome = detalhesFrame:FindFirstChild("ItemNome")
        if itemNome then
            itemNome.Text = item:GetAttribute("Nome") or "Item"
        end
        
        -- Atualizar descrição
        local itemDescricao = detalhesFrame:FindFirstChild("ItemDescricao")
        if itemDescricao then
            itemDescricao.Text = item:GetAttribute("Descricao") or "Sem descrição disponível."
        end
        
        -- Atualizar quantidade
        local itemQuantidade = detalhesFrame:FindFirstChild("ItemQuantidade")
        if itemQuantidade then
            local quantidade = item:FindFirstChild("Quantidade") and item.Quantidade.Text or "0"
            itemQuantidade.Text = "Quantidade: " .. quantidade
        end
    end
    
    -- Efeito visual de seleção
    for _, elemento in pairs(inventarioFrame:FindFirstChild("GridFrame"):GetChildren()) do
        if elemento:IsA("Frame") and elemento:FindFirstChild("EfeitoSelecao") then
            elemento.EfeitoSelecao:Destroy()
        end
    end
    
    local efeitoSelecao = Instance.new("UIStroke")
    efeitoSelecao.Name = "EfeitoSelecao"
    efeitoSelecao.Color = Color3.fromRGB(255, 215, 0) -- Dourado
    efeitoSelecao.Thickness = 2
    efeitoSelecao.Parent = item
}

-- Função para alternar o grid
function AlternarGrid()
    estado.gridAtivo = not estado.gridAtivo
    
    MostrarNotificacao(
        "Grid " .. (estado.gridAtivo and "Ativado" or "Desativado"),
        estado.gridAtivo 
            and "Os itens serão alinhados automaticamente ao grid." 
            or "Os itens podem ser colocados em qualquer posição.",
        "info",
        2
    )
}

-- Função para inicializar o sistema de drag & drop
local function Inicializar()
    print("🔄 DRAG & DROP: Inicializando sistema...")
    
    -- Criar drop zones
    CriarDropZones()
    
    -- Conectar eventos de mouse
    table.insert(estado.conexoes, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Verificar se está clicando em um item do inventário
            local itemSobMouse = EncontrarItemSobPosicao(input.Position)
            if itemSobMouse then
                -- Verificar se é multi-seleção
                if UserInputService:IsKeyDown(CONFIG.MULTI_SELECAO_TECLA) then
                    AlternarSelecaoItem(itemSobMouse)
                else
                    IniciarArrasto(itemSobMouse, input.Position)
                end
            end
        elseif input.KeyCode == CONFIG.MULTI_SELECAO_TECLA then
            estado.modoMultiSelecao = true
        elseif input.KeyCode == Enum.KeyCode.G then
            AlternarGrid()
        end
    end))
    
    table.insert(estado.conexoes, UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseMovement and estado.arrastando then
            AtualizarPosicaoArrasto(input.Position)
        end
    end))
    
    table.insert(estado.conexoes, UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 and estado.arrastando then
            if #estado.itemSelecionados > 0 and estado.modoMultiSelecao then
                FinalizarArrastoMultiplo(input.Position)
            else
                FinalizarArrasto(input.Position)
            end
        elseif input.KeyCode == CONFIG.MULTI_SELECAO_TECLA then
            estado.modoMultiSelecao = false
        end
    end))
    
    -- Conectar eventos de touch para suporte mobile
    table.insert(estado.conexoes, UserInputService.TouchStarted:Connect(ProcessarInicioToque))
    table.insert(estado.conexoes, UserInputService.TouchMoved:Connect(ProcessarMovimentoToque))
    table.insert(estado.conexoes, UserInputService.TouchEnded:Connect(ProcessarFimToque))
    
    -- Conectar evento de atualização do inventário
    table.insert(estado.conexoes, atualizarInventarioEvent.OnClientEvent:Connect(function()
        -- Atualizar drop zones quando o inventário for atualizado
        CriarDropZones()
    end))
    
    print("🔄 DRAG & DROP: Sistema inicializado com sucesso!")
}

-- Função para limpar o sistema quando o script for destruído
local function Limpar()
    print("🔄 DRAG & DROP: Limpando sistema...")
    
    -- Desconectar todos os eventos
    for _, conexao in ipairs(estado.conexoes) do
        if conexao.Connected then
            conexao:Disconnect()
        end
    end
    
    -- Limpar drop zones
    for _, dropZone in ipairs(estado.dropZones) do
        if dropZone and dropZone.Parent then
            dropZone:Destroy()
        end
    end
    
    -- Limpar estado de arrasto
    LimparEstadoArrasto()
}

-- Inicializar o sistema
Inicializar()

-- Limpar quando o script for destruído
script.Destroyed:Connect(Limpar)
