# RemoteEvents Necessários – Loja Viva Fantasy Island

Este guia rápido mostra **quais RemoteEvents você deve criar em _ReplicatedStorage/RemoteEvents_** para que a LOJA e os demais botões da interface funcionem.

---

## 📋 Lista de RemoteEvents

| Nome exato | Para que serve | Já usado por… |
|------------|----------------|---------------|
| `AtualizarHUD` | Enviar novas moedas/nível do servidor → cliente | HUD (init.lua) |
| `AlternarFrame` | Servidor recebe aviso de qual menu abrir/fechar (opcional) | init.lua (cliente) |
| `ComprarItem` | Cliente solicita compra e servidor responde sucesso/erro | LojaGui.lua + EconomiaModule |
| `CompletarMissao` | Cliente pede recompensa de missão | MissoesModule |
| `ColocarDecoracao` | Cliente pede colocar objeto 3D | ConstrucaoModule |
| `RemoverDecoracao` | Cliente pede remover objeto 3D | ConstrucaoModule |

> Atenção à **grafia** e uso de **maiúsculas/minúsculas** – o código exige nomes idênticos.

---

## 🛠️ Passo a passo para criar cada RemoteEvent

1. **Abrir o Explorer**  
   View → Explorer (caso esteja fechado).

2. **Criar pasta RemoteEvents** (se ainda não existir)  
   - Clique direito em **ReplicatedStorage**  
   - _Insert Object_ → **Folder**  
   - Nomeie como **RemoteEvents**

3. **Criar cada RemoteEvent**  
   Para **cada nome** da tabela acima:
   - Selecione a pasta **RemoteEvents**  
   - Clique direito → _Insert Object_ → **RemoteEvent**  
   - Renomeie exatamente para o nome indicado.

   Exemplo para `ComprarItem`:
   ```
   ReplicatedStorage
   └─ RemoteEvents
      └─ ComprarItem  ← ✅
   ```

4. **Salvar o jogo**  
   File → Save to Roblox ou Save to File, para não perder o trabalho.

---

## ✅ Como verificar se está tudo certo

1. **Iniciar Play (Solo)**  
   Output deve mostrar prints do tipo:
   ```
   📱 GUI: Conectando aos RemoteEvents...
   ```
   Sem erros em vermelho como  
   `RemoteEvents is not a valid member of ReplicatedStorage`.

2. **Testar Loja**  
   - Clique no ícone 🛒  
   - Selecione um item → **COMPRAR**  
   - Deve aparecer notificação de sucesso ou erro de moedas.

3. **Debug rápido**  
   - Erro “_... is not a valid member of RemoteEvents_” → nome escrito errado.  
   - Nenhum print do cliente → verifique se _init.lua_ e _LojaGui.lua_ são **LocalScripts** e `Enabled = true`.

---

Pronto! Com estes RemoteEvents criados, a interface da loja, missões e construção já conseguem se comunicar entre servidor e cliente. 🎉
