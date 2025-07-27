# Debug Checklist – Botões da GUI não Funcionam

Use esta lista rápida para localizar e resolver problemas quando os botões da **MainGui** não abrem os menus.

---

## 1. Verifique a Estrutura de Pastas

Explorer deve estar exatamente assim:

```
ServerScriptService
└─ GameManager.lua

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

✓  Confirme que **init.lua** está dentro de `StarterGui/MainGui`  
✓  Confirme que os módulos estão em `ServerStorage/Modules`

---

## 2. Verifique os RemoteEvents

1. Abra `ReplicatedStorage/RemoteEvents`.
2. Confira **nomes exatos** (sensível a maiúsculas/minúsculas):
   - `AtualizarHUD`
   - `AlternarFrame`
   - `CompletarMissao`
   - `ColocarDecoracao`
   - `RemoverDecoracao`
3. Tipo do objeto deve ser **RemoteEvent** (não Folder ou RemoteFunction).

---

## 3. Veja os Prints no Output

1. Abra **View → Output**.
2. Clique **Play (Solo)**.
3. Procure mensagens como:

```
📱 GUI: Script cliente iniciado
📱 GUI: Botão Loja clicado
📱 GUI: Menu aberto: LojaFrame
```

Se não aparecer nenhum log do cliente:

- Verifique se **init.lua** está ativo (não `Disabled`).
- Confirme que está em **StarterGui** (o Studio clona para `PlayerGui` em runtime).

---

## 4. Passos de Teste Rápidos

1. **Play** no Studio.
2. No Output, digite na barra de filtro `📱`.
3. Clique cada botão:
   - 🛒 deve gerar `Botão Loja clicado` e alternar visibilidade de `LojaFrame`.
   - 🎒 idem para `InventarioFrame`, etc.
4. Pare o jogo; problemas mostrados em vermelho no Output indicam onde agir.

---

## 5. Soluções Rápidas

| Sintoma | Causa Provável | Ação Imediata |
|---------|----------------|---------------|
| Nenhum print no Output | `init.lua` desabilitado ou fora do lugar | Arraste `init.lua` para `StarterGui/MainGui`, marque `Enabled = true` |
| Erro “RemoteEvent is not a valid member” | Nome do RemoteEvent errado | Renomeie no Explorer para corresponder ao script |
| Botão muda print mas não abre menu | `AlternarFrame` não existe ou erro no servidor | Crie `AlternarFrame` em `ReplicatedStorage/RemoteEvents` |
| Erro “Module not found” no Output | Módulo fora da pasta `Modules` | Mova arquivo para `ServerStorage/Modules` |
| HUD não atualiza moedas | Falta disparo `AtualizarHUD` no servidor | Verifique `EconomiaModule.AdicionarMoedas` |

---

Se todos os itens acima estiverem corretos e o problema persistir, envie o trecho do **Output** mostrado em vermelho para análise detalhada. Boa depuração! 🚀
