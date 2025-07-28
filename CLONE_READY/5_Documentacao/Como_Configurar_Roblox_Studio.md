# Viva Fantasy Island  
## Guia de Configuração no Roblox Studio

Bem-vindo! Este documento ensina, do zero, a colocar **TODO o projeto** para rodar em poucos minutos.

---

## 1. Importar os arquivos do repositório

1. Faça download/clone do repositório.
2. Abra **Roblox Studio** e crie um novo _Experience ➡ Baseplate_.
3. No menu **View → Asset Manager → Bulk Import** selecione:
   - `src/StarterGui/MainGui/MainGui.rbxmx`  
   - _Demais `.rbxmx` ou `.rbxm` (modelos) quando existirem._
4. Clique **Next → Finish**. A interface aparecerá em **StarterGui**.

```
[ Baseplate Workspace ]
└─ StarterGui
   └─ MainGui (importado) ✅
```

---

## 2. Estrutura de pastas

Crie as pastas exatamente assim (Explorer → botão direito → _Insert Object → Folder_):

```
ServerStorage
│
└─ Modules
   ├─ EconomiaModule.lua
   ├─ DataStoreModule.lua
   ├─ MissoesModule.lua
   └─ ConstrucaoModule.lua

ReplicatedStorage
│
└─ RemoteEvents
   ├─ AtualizarHUD (RemoteEvent)
   ├─ AlternarFrame (RemoteEvent)
   ├─ CompletarMissao (RemoteEvent)
   ├─ ColocarDecoracao (RemoteEvent)
   └─ RemoverDecoracao (RemoteEvent)

ServerScriptService
└─ GameManager.lua

StarterGui
└─ MainGui (já importado)
    └─ init.lua
```

> Dica: arraste cada script/módulo do Asset Manager ou do Windows Explorer direto para o destino.

---

## 3. Colocando cada script no lugar

| Script/Módulo                     | Onde colocar                          |
| --------------------------------- | ------------------------------------- |
| `GameManager.lua`                 | **ServerScriptService**               |
| `EconomiaModule.lua`              | **ServerStorage/Modules**             |
| `DataStoreModule.lua`             | **ServerStorage/Modules**             |
| `MissoesModule.lua`               | **ServerStorage/Modules**             |
| `ConstrucaoModule.lua`            | **ServerStorage/Modules**             |
| `init.lua` (da MainGui)           | Dentro de **StarterGui/MainGui**      |

Arraste → solte ou use *Cut & Paste* no Explorer do Studio.

---

## 4. Configurando os RemoteEvents

1. Crie um **Folder** dentro de **ReplicatedStorage** chamado `RemoteEvents`.
2. Para cada nome da tabela abaixo, clique **RemoteEvent**:

| Nome do RemoteEvent | Uso principal |
| ------------------- | ------------- |
| `AtualizarHUD`      | Atualizar moedas/nível no cliente |
| `AlternarFrame`     | Abrir/fechar UI (loja, inventário…) |
| `CompletarMissao`   | Jogador solicita recompensa |
| `ColocarDecoracao`  | Cliente pede colocar objeto 3D |
| `RemoverDecoracao`  | Cliente pede remover objeto 3D |

A **grafia deve ser idêntica** às usadas nos scripts.

```
ReplicatedStorage
└─ RemoteEvents
   ├─ AtualizarHUD [R]
   ├─ AlternarFrame [R]
   ├─ CompletarMissao [R]
   ├─ ColocarDecoracao [R]
   └─ RemoverDecoracao [R]
```

---

## 5. Primeiros testes

1. Clique **Play (Solo)**.
2. No Output você deve ver:

```
[GameManager] Inicializado
[Economia] ✅
[DataStore] ✅
[Missoes] ✅
[Construcao] ✅
```

3. Confirme que o **HUD** mostra `DreamCoins` e `Nível 1`.
4. Clique nos botões inferiores:
   - 🛒 abre **LojaFrame**,
   - 🎒 abre **InventarioFrame**, etc.

Se abrir/fechar, RemoteEvents e `init.lua` estão ok.

---

## 6. Troubleshooting

| Sintoma | Causa comum | Solução |
| ------- | ----------- | ------- |
| Botões não fazem nada | `AlternarFrame` ausente ou mal escrito | Verifique nome no RemoteEvents |
| Erro `Module not found` | Script fora da pasta `Modules` | Mova arquivo correto |
| HUD sem valores | `AtualizarHUD` não disparou | Confirme que `EconomiaModule.Inicializar()` roda no `GameManager` |
| Dados não salvam | API Services desativadas | Home → Game Settings → Security → habilite **Enable Studio Access to API Services** |
| XML não importa | Arquivo corrompido | Baixe novamente `MainGui.rbxmx` |

---

## 7. “Imagens” em texto

### 7.1 Explorer final

```
Workspace
ServerScriptService
├─ GameManager.lua
ServerStorage
└─ Modules
   ├─ EconomiaModule.lua
   ├─ DataStoreModule.lua
   ├─ MissoesModule.lua
   └─ ConstrucaoModule.lua
ReplicatedStorage
└─ RemoteEvents
   ├─ AtualizarHUD
   ├─ AlternarFrame
   ├─ CompletarMissao
   ├─ ColocarDecoracao
   └─ RemoverDecoracao
StarterGui
└─ MainGui
    ├─ HUD, LojaFrame, …
    └─ init.lua
```

### 7.2 Fluxo de um clique de botão

```
[Player] → Clica 🛒
      │
      ▼              (LocalScript init.lua)
AlternarFrame:FireServer("LojaFrame")
      │
      ▼              (GameManager recebe)
LojaFrame.Visible = not estado
```

---

## 8. Próximos passos

1. Criar modelos 3D em **ServerStorage/Modelos**.
2. Integrar Developer Products.
3. Balancear economia e recompensas.

**Pronto!** Você já pode rodar o **Viva Fantasy Island** localmente. Boa diversão! 🎉
