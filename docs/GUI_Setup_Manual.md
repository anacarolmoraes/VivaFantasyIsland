# Guia de Criação Manual da Interface **MainGui**  
_Viva Fantasy Island – Roblox Studio_

> Este documento ensina, passo a passo, a montar manualmente a **MainGui** no Roblox Studio sem precisar importar o arquivo `.rbxmx`. Siga na ordem e você terá a mesma interface funcional do protótipo.

---

## Visão Geral da Estrutura

```
StarterGui
└── MainGui (ScreenGui)
    ├── HUD (Frame)
    │   ├── MoedasFrame (Frame)
    │   │   ├── IconMoeda (ImageLabel)
    │   │   └── ValorMoedas (TextLabel)
    │   ├── NivelFrame (Frame)
    │   │   ├── IconNivel (ImageLabel)
    │   │   └── ValorNivel (TextLabel)
    │   └── BotoesMenu (Frame)
    │       ├── BotaoLoja (TextButton)
    │       ├── BotaoInventario (TextButton)
    │       ├── BotaoMissoes (TextButton)
    │       ├── BotaoConstrucao (TextButton)
    │       ├── BotaoSocial (TextButton)
    │       └── BotaoConfiguracoes (TextButton)
    ├── LojaFrame (Frame)
    ├── InventarioFrame (Frame)
    ├── MissoesFrame (Frame)
    ├── ConstrucaoFrame (Frame)
    ├── SocialFrame (Frame)
    ├── ConfiguracoesFrame (Frame)
    └── NotificacoesFrame (Frame)
        └── TemplateNotificacao (Frame) *invisível*
```

---

## 1. Criando o ScreenGui

1. No **Explorer**, clique direito em **StarterGui → Insert Object → ScreenGui**.  
2. Nomeie como **MainGui**.  
3. Propriedades:  
   * ResetOnSpawn: `false`  
   * IgnoreGuiInset: `false`  
   * ZIndexBehavior: `Sibling`

---

## 2. Construindo o HUD

### 2.1 Frame HUD
1. Clique direito em **MainGui → Insert Object → Frame**.  
2. Nomeie **HUD**.  
3. Propriedades:  
   * AnchorPoint: `0,0`  
   * Size: `{1,0},{1,0}`  
   * BackgroundTransparency: `1`

### 2.2 MoedasFrame
1. Dentro de **HUD**, insira **Frame** → **MoedasFrame**.  
2. Propriedades principais:  
   * Position: `{0,10},{0,10}`  
   * Size: `{0,180},{0,40}`  
   * BackgroundColor3: `Color3.fromRGB(55,159,209)`  
   * BackgroundTransparency: `0.2`
3. Adicione **UICorner** com CornerRadius `{0,8}`.

#### IconMoeda
* Tipo: **ImageLabel**  
* Position: `{0,10},{0.5,0}` – AnchorPoint `{0,0.5}`  
* Size: `{0,30},{0,30}`  
* Image: `rbxassetid://7072721682`  
* ImageColor3: `Amarelo (255,215,0)`  
* BackgroundTransparency: `1`

#### ValorMoedas
* Tipo: **TextLabel**  
* Position: `{0,50},{0.5,0}` – AnchorPoint `{0,0.5}`  
* Size: `{0,120},{0,30}`  
* Font: **GothamSemibold**  
* Text: `100` (placeholder)  
* TextColor3: `White`  
* TextSize: `20`

### 2.3 NivelFrame
Repita os passos acima trocando:
* Nome: **NivelFrame**  
* Position: `{1,-90},{0,10}` – AnchorPoint `{1,0}`  
* Size: `{0,80},{0,40}`

#### IconNivel
* Image: `rbxassetid://7072725342`  
* Size: `{0,25},{0,25}`

#### ValorNivel
* Text: `1`  
* Position: `{0,45},{0.5,0}`

### 2.4 BotoesMenu
1. Em **HUD**, insira **Frame → BotoesMenu**.  
2. Propriedades:  
   * AnchorPoint: `{0.5,1}`  
   * Position: `{0.5,0},{1,-10}`  
   * Size: `{0.8,0},{0,60}`  
   * BackgroundTransparency: `0.5`  
   * BackgroundColor3: `Color3.fromRGB(45,45,45)`  
3. Adicione **UICorner** `{0,12}`.  
4. Adicione **UIListLayout**:  
   * FillDirection: `Horizontal`  
   * HorizontalAlignment: `Center`  
   * Padding: `{0,10}`  
   * VerticalAlignment: `Center`

#### Botões (Loja, Inventário, etc.)
Para cada botão:
* **TextButton**  
* Size: `{0,50},{0,50}`  
* BackgroundColor3: `Color3.fromRGB(55,159,209)`  
* Font: GothamSemibold  
* TextSize: `24`  
* Texto e Emoji:  
  * 🛒 BotaoLoja  
  * 🎒 BotaoInventario  
  * 📋 BotaoMissoes  
  * 🏗️ BotaoConstrucao  
  * 👥 BotaoSocial  
  * ⚙️ BotaoConfiguracoes  
* Adicione **UICorner** CornerRadius `{0.5,0}` (botão redondo).

---

## 3. Frames de Menus Principais

Para **LojaFrame, InventarioFrame, MissoesFrame, ConstrucaoFrame, SocialFrame, ConfiguracoesFrame**:

1. Inserir **Frame** em **MainGui**.  
2. Nomear conforme a lista.  
3. Propriedades comuns:  
   * AnchorPoint: `{0.5,0.5}`  
   * Position: `{0.5,0},{0.5,0}`  
   * Size: `{0.8,0},{0.8,0}`  
   * BackgroundColor3: `Color3.fromRGB(45,45,45)`  
   * BackgroundTransparency: `0.1`  
   * Visible: `false`  
4. **UICorner** `{0,12}`.  

### Exemplo extra – LojaFrame
* Dentro do frame, adicione um **TextLabel** topo `TituloLoja`  
  * Size: `{1,0},{0,50}`  
  * BackgroundColor3: `Color3.fromRGB(55,159,209)`  
  * Font: GothamBold, Text: “Loja de Decorações”, TextSize 24  
* Adicione **TextButton** `BotaoFechar` canto superior direito  
  * AnchorPoint: `{1,0}`  
  * Position: `{1,0},{0,0}`  
  * Size: `{0,50},{0,50}`  
  * BackgroundColor3: `Color3.fromRGB(209,55,55)`  
  * Text: `X`, FontSize 24.

Repita o padrão para os outros menus, trocando títulos.

---

## 4. Notificações

1. Adicione **Frame → NotificacoesFrame** em **MainGui**  
   * AnchorPoint `{1,1}`  
   * Position `{1,0},{1,0}`  
   * Size `{0,300},{1,0}`  
   * BackgroundTransparency `1`  

2. Dentro, crie **TemplateNotificacao** (Frame)  
   * Size: `{0,280},{0,60}`  
   * BackgroundColor3: `Color3.fromRGB(45,45,45)`  
   * Visible: `false`  
   * Adicione **UICorner** `{0,8}`  
   * Dentro crie:
     * **Barra** (Frame) – posição esquerda `{0,0},{0,0}`, Size `{0,6},{1,0}`  
     * **Titulo** (TextLabel) topo, Font Bold, TextSize 18  
     * **Mensagem** (TextLabel) abaixo, TextSize 14, TextWrapped `true`  
     * **BotaoFechar** (TextButton) canto direito, Size `{0,20},{0,20}`, Text `✕`  

---

## 5. Configurações de Cores, Fontes e Tamanhos

| Elemento                         | Cor (RGB)            | Transparência | Fonte              | Tamanho Texto |
|----------------------------------|----------------------|---------------|--------------------|---------------|
| Frames principais                | 45,45,45             | 0.1           | –                  | –             |
| Botoões HUD                      | 55,159,209           | 0             | GothamSemibold     | 24            |
| MoedasFrame & NivelFrame barra   | 55,159,209           | 0.2           | GothamSemibold     | 20            |
| Título de menu                   | 55,159,209           | 0             | GothamBold         | 24            |
| Barra de Notificação             | depende do tipo      | 0             | –                  | –             |

_Observação_: Ajuste `ImageColor3` dos ícones conforme tema.

---

## 6. Descrições Visuais (Textuais)

* **HUD** fica fixo: Moedas lado esquerdo, nível lado direito, botões centralizados na parte inferior da tela.  
* **Menus** surgem no centro (Size 80 % da tela) com fundo escuro e bordas arredondadas.  
* **Notificações** deslizam da direita para a esquerda na parte inferior (TemplateNotificacao).  
* **Botões** usam ícones emoji para rápida identificação.

---

## 7. Scripts

Após criar a hierarquia:

1. Adicione **LocalScript** `init` dentro de **MainGui** (código já fornecido em `src/StarterGui/MainGui/init.lua`).  
2. Garanta que **RemoteEvents** e **RemoteFunctions** existam em **ReplicatedStorage** (GameManager cria se não houver).

---

## 8. Checklist Final

- [ ] Hierarquia idêntica à diagrama inicial  
- [ ] Todos os nomes de objetos correspondem aos scripts  
- [ ] Propriedades de posições e tamanhos conferem  
- [ ] Cores e fontes aplicadas  
- [ ] Menus marcados como `Visible = false` (exceto HUD)  
- [ ] TemplateNotificacao invisível  

Se tudo estiver correto, pressione **Play** no Studio; a HUD deverá aparecer com 100 DC e nível 1. Abrir/fechar menus deve funcionar através dos botões.

---

### Parabéns! 🎉  
Você montou manualmente a **MainGui** do Viva Fantasy Island. Qualquer dúvida, volte a este guia ou revise as propriedades dos objetos.
