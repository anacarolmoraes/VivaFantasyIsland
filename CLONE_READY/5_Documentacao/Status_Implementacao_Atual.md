# 📑 Status da Implementação – Viva Fantasy Island  
_Data: 27 jul 2025 – Commit `33e561e`_

Este documento resume o **estado atual do jogo** depois das últimas correções do inventário e da limpeza de arquivos. Use-o como referência rápida para jogar, testar ou continuar o desenvolvimento.

---

## 1. ✅ Funcionalidades que Estão Funcionando

| Sistema | Descrição | Status |
|---------|-----------|--------|
| Economia (DreamCoins) | Saldo local, compra de itens na loja e atualização visual. | Funcional ✅ |
| Loja Rich UI | Categorias, busca, filtro por preço, compra com validação. | Funcional ✅ |
| Inventário Rich UI | Grade 4×N, pesquisa, ordenação, categorias, detalhes do item. | Funcional ✅ |
| Drag & Drop Avançado | Arrasto dentro do inventário, multi-seleção, contador flutuante, drop zones. | Funcional ✅ |
| Sistema de Construção | Preview 3D, grid-snap, rotação, **Undo / Redo**, validação de colisão. | Funcional ✅ |
| Modelos 3D (6 itens) | LOD dinâmico, cache, materiais, efeitos (vento, partículas). | Funcional ✅ |
| Missões | Lista, progresso, coleta de recompensa; ligação com compra/colocação. | Funcional ✅ |
| Persistência Básica | Salvamento/Carregamento de saldo e inventário (DataStoreModule). | Funcional ✅ |

---

## 2. 📚 Como Usar Cada Funcionalidade

1. **Abrir Menus**  
   • Clique nos botões do HUD ou use os atalhos (veja § 3).  
   • Apenas um menu fica aberto por vez (`init.lua` força fechamento dos demais).

2. **Loja**  
   • Selecione categoria → Pesquise → Clique em **Comprar** → Confirme.  
   • DreamCoins são debitados e o item vai para o inventário.

3. **Inventário**  
   • Pesquise ou filtre por categoria.  
   • Clique em um item para ver detalhes.  
   • Arraste para outra célula para reorganizar.  
   • Clique em “Colocar na Ilha” ou entre em **modo Construção** para uso avançado.

4. **Drag & Drop**  
   • _Arrasto simples_: Mouse 1 e arraste.  
   • _Multi-seleção_: Segure **Shift** (desktop) ou toque longo (mobile) e clique em vários itens; arraste todos juntos.  
   • Drop zones ficam azuis; soltar sobre construção coloca o item(s) na ilha.

5. **Construção**  
   • Abra com tecla **B** ou botão martelo.  
   • Use **R** ou _scroll+Shift_ para girar (incremento 15 °).  
   • **G** ativa/desativa snap de grid (0,5 stud).  
   • **Ctrl+Z / Ctrl+Y** desfaz/refaz a última ação.  
   • Clique direito ou **Esc** sai do modo.

6. **Missões**  
   • Acesse aba Missões. Barras de progresso exibem objetivos diários/semanais.  
   • Clique em **Coletar** quando 100 %.

7. **Economia & Persistência**  
   • DreamCoins atualizam em HUD.  
   • Dados persistem a cada 120 s ou na saída do jogador.

---

## 3. ⌨️ Teclas de Atalho

| Tecla | Ação |
|-------|------|
| **I** | Abrir/fechar Inventário |
| **L** | Abrir Loja |
| **M** | Abrir Missões |
| **B** | Modo Construção |
| **R** | Girar item (construção) |
| **G** | Ligar/Desligar grid-snap |
| **Shift + Clique** | Multi-seleção no inventário |
| **Ctrl + Z / Ctrl + Y** | Undo / Redo (construção) |
| **Esc / Botão Direito** | Cancelar modo construção |
| **← / → mouse scroll** | Ajuste fino de rotação (com Shift) |

_Mobile_: toque longo = seleção / arrasto; pinça = zoom; dois toques = girar.

---

## 4. 🐞 Problemas Conhecidos & Soluções

| Sintoma | Causa Comum | Solução Rápida |
|---------|-------------|----------------|
| Preview 3D não aparece | `RemoteEvents` ausentes no jogo local | Verifique pasta `ReplicatedStorage/RemoteEvents` e recrie `ColocarDecoracao`. |
| Inventário abre vazio | Script fora de `StarterGui/MainGui` | Confirme `InventarioGui.lua` dentro da pasta correta. |
| Itens voltam a 0 após rejoin | DataStore limite de 30 seg latência | Aumente `SAVE_INTERVAL` em `DataStoreModule` ou teste no ambiente Live. |
| Pop-in nos modelos | Distâncias LOD muito curtas | Ajuste `DISTANCIA_LOD` em `ModelosItens.lua` (ALTA/MÉDIA/BAIXA). |
| Undo trava | Histórico > 20 ações | Aumente `HISTORICO_MAXIMO` no `SistemaConstrucao`. |

---

## 5. 🚀 Próximos Passos

1. **Melhoria B – Catálogo Completo de Modelos 3D**  
   • Converter todos os itens da loja/inventário em modelos com LOD.  
2. **Melhoria C – Sistema Social**  
   • Visita de ilhas, amizade, chat local, likes.  
3. **Melhoria D – Mini-jogos e Eventos**  
   • Corrida de obstáculos, pescaria, caça-ao-tesouro.  
4. Otimizar DataStore: _queue_, **ProfileService**.  
5. Revisar UI mobile (telas ≤ 6ʺ).

---

## 6. 🧪 Checklist de Testes Rápidos

| Sistema | Teste | Esperado |
|---------|-------|----------|
| Loja | Comprar item de cada categoria | Saldo diminui, item +1 no inventário |
| Inventário | Pesquisar “mesa” | Mostra apenas “Mesa de Madeira” |
| Drag & Drop | Shift + clicar 3 itens, arrastar p/ construção | Todos aparecem na ilha, toast “Itens Colocados” |
| Construção | Colocar árvore, girar, Undo/Redo | Item gira corretamente e desfaz/refaz sem erro |
| Modelos 3D | Afastar-se > 100 stud | LOD troca p/ baixa sem pop-in severo |
| Missões | Colocar 5 cercas | Progresso +5, botão Coletar habilita em 100 % |
| Persistência | Dar _Play Solo_, colocar item, Stop, Play novamente | Item ainda está salvo na ilha |

Execute esses passos e anote falhas para abrir um **Issue** no GitHub com _milestone_ “Melhoria A”.

---

_Fim do documento_  
Equipe Factory AI 🤖
