# Guia de Testes – Melhoria A (Funcionalidade Completa)

Este documento descreve passo-a-passo como validar todas as funcionalidades entregues na **Melhoria A** do projeto **Viva Fantasy Island**: Sistema de Construção, Drag & Drop Avançado e Modelos 3D.  
Siga as seções na ordem sugerida e assinale cada item na checklist final.

---

## Pré-requisitos

1. Roblox Studio  ≥  0.592 com **Studio Access to APIs** habilitado.  
2. Último commit da branch `main` já importado no seu jogo local.  
3. Pasta `ServerStorage/Modelos` contendo os modelos listados no módulo `ModelosItens.lua`.  
4. Modo **Play Solo** ou **Start Server + n Clients** para testes multiplayer.

---

## 1 · Como testar o Sistema de Construção

| Passo | Ação | Resultado esperado |
|-------|------|--------------------|
| 1 | Entre no jogo (`F5`) e abra o menu Construção (“Construir” ou tecla **B**). | Abre um painel de ferramentas com ícone de _martelo_. |
| 2 | Selecione um item do inventário e arraste para o terreno. | Aparece um _preview 3D_ verde (válido) ou vermelho (inválido). |
| 3 | Use **R** / **Shift + mouse scroll** para girar o item. | Ângulo muda em incrementos de 15 ° e UI exibe rotação atual. |
| 4 | Aproxime o preview de outro objeto. | Snap ao grid de 0.5 stud; colisão impede sobreposição. |
| 5 | Clique **Mouse 1** para confirmar. | Item aparece sólido, DreamCoins descontados (se aplicável). |
| 6 | Pressione **Ctrl + Z** (Undo) e **Ctrl + Y** (Redo). | Item é removido e recolocado respetivamente. |
| 7 | Tente colocar item em superfície não permitida (ex.: no ar). | Mensagem “Posicionamento inválido” + preview vermelho. |
| 8 | Mobile: toque longo no item colocado → ícone de mover. | Ativa modo de edição móvel; arraste para nova posição. |

---

## 2 · Como testar o Drag & Drop Avançado

1. Abra inventário (**I**) e confirme que a grade mostra ao menos 16 células.  
2. **Arrasto simples:** clique e arraste um item dentro do inventário para outra célula.  
   • Drop zone azul aparece; item muda de célula; toast “Item Movido”.  
3. **Multi-seleção (desktop):**  
   a. Pressione **Shift** e clique em 3 itens diferentes. Borda azul clara indica seleção.  
   b. Sem soltar **Shift**, arraste qualquer item selecionado ➜ contêiner múltiplo segue cursor.  
   c. Solte sobre drop zone de construção ➜ todos os itens são enviados ao servidor.  
4. **Mobile:** toque longo (>0.5 s) em um item → seleção; mova dedo para arrastar; solte.  
5. Enquanto arrasta, pressione **G** para ligar/desligar _snap grid_. Visual toast confirma.

---

## 3 · Como testar os Modelos 3D

1. Aproxime-se de cada item colocado e verifique:  
   • Texturas corretas, materiais (Wood, Grass, etc.), luz e partículas (se houver).  
2. Afaste-se lentamente (usar `Shift+P` FreeCam) e observe troca de LOD:  
   • Distância 20 → alta, 50 → média, 100 → baixa, >200 → muito baixa.  
   • Queda suave de triângulos; sem _pop-in_ notável.  
3. No **Output**, busque por warnings `ModelosItens:`. Não deve haver “Modelo inválido”.  
4. Rode o jogo por 10 min e execute script `print(ModelosItens:ObterEstatisticas())` no server-console — `numItensEmCache` deve permanecer ≤ 50.

---

## 4 · Funcionalidades Esperadas

- Pré-visualização 3D com cores de status (verde / vermelho).  
- Grid-snap opcional; rotação incremental.  
- Drag & drop com animações, stroke pulsante, drop zones visíveis.  
- Multi-seleção e contagem em badge flutuante.  
- Suporte completo Desktop + Mobile (toque longo).  
- Undo / Redo ilimitado na sessão.  
- Modelos com materiais, texturas, efeitos (vento, partículas, luz, envelhecimento).  
- Cache de modelos com limpeza automática.  
- Nenhum erro ou warning persistente no **Output**.

---

## 5 · Possíveis Problemas & Soluções

| Sintoma | Causa comum | Solução rápida |
|---------|-------------|----------------|
| Preview não aparece | `RemoteEvents` ausentes | Verifique se `ColocarDecoracao` existe em `ReplicatedStorage/RemoteEvents`. |
| Botão “Construir” sem resposta | LocalScript fora de *StarterGui* | Garanta `SistemaConstrucao.lua` dentro de `StarterGui/MainGui`. |
| LOD não muda | Distâncias alteradas | Confirme valores em `DISTANCIA_LOD` em `ModelosItens.lua`. |
| Undo falha após 1ª ação | `history` nulado por erro de script | Cheque **Output** por stacktrace do `SistemaConstrucao`. |
| Itens somem após colocar | Falta de DreamCoins / inventário não atualizado | Confirme eventos `AtualizarInventario` e saldo no `EconomiaModule`. |

---

## 6 · Checklist de Testes

- [ ] Construir 1 item de cada categoria (decor, móveis, plantas).  
- [ ] Utilizar rotação e verificar alinhamento.  
- [ ] Desfazer & refazer 3 vezes seguidas.  
- [ ] Reorganizar inventário com drag dentro da grade.  
- [ ] Multi-selecionar ≥ 4 itens e colocá-los na ilha.  
- [ ] Testar grid on/off (tecla **G**).  
- [ ] Mobile: arrasto com toque longo.  
- [ ] Conferir partículas das flores e luz da flor azul à noite (`TimeOfDay=20`).  
- [ ] Executar estatísticas de cache e validar limites.  
- [ ] Nenhum warning/erro restante no **Output**.

---

## 7 · Como Reportar Problemas

1. Abra um **Issue** no repositório GitHub `anacarolmoraes/VivaFantasyIsland`.  
2. Use o template **Bug Report** e inclua:  
   • Passos para reproduzir.  
   • Resultado atual x esperado.  
   • Print do **Output** ou log de servidor.  
   • Vídeo/GIF opcional (<30 s) mostrando o problema.  
3. Marque com o label `bug` e a milestone `Melhoria A`.  
4. Para bloqueios críticos, mencione `@Factory-AI` para priorização.

---

_Feliz teste!_  
Equipe Factory AI 🎉
