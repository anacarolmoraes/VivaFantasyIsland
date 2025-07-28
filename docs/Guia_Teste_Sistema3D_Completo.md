# Guia de Teste – Sistema 3D Completo (v2.0.0)
_Viva Fantasy Island_

Este guia cobre a validação de todos os 26 itens 3D introduzidos na **Melhoria B**.  
Ao final, você terá verificado listagem, compra, inventário, construção, LOD, efeitos e performance.

---

## 1. Preparação do Ambiente

1. Abra o projeto no **Roblox Studio** (branch/main atualizado).  
2. Confirme que o serviço **ServerStorage › Modelos › ModelosItens.lua** exibe `VERSAO_SISTEMA = "2.0.0"`.  
3. Defina **Play Solo** para testes locais – facilita observar Output e Explorer.  
4. Limpe o **Output** antes de começar (`Ctrl+L`) para capturar apenas mensagens do teste.

---

## 2. Fluxo Básico de Teste (repetir por item)

| Etapa | Ação | Expectativa |
|-------|------|-------------|
| 1 | Abrir Loja → categoria correta | Item aparece com preço previsto |
| 2 | Clicar “Comprar” | Botão muda para “Comprado” e DreamCoins reduzem |
| 3 | Abrir Inventário → filtro categoria | Item presente, ícone e nome corretos |
| 4 | Arrastar para a ilha (Construction Mode) | Pré-visualização resp. ao offset; verde = posição válida |
| 5 | Confirmar colocação | Modelo é spawnado, sem erros no Output |
| 6 | Aproximar/afastar câmera | Modelo alterna LOD sem popping exagerado |
| 7 | Testar interações/efeitos | Ex.: sentar no banco, luz da luminária, partículas da fonte |
| 8 | Remover item (Ferramenta de remoção) | DreamCoins são parcialmente devolvidos (se aplicável) |

> Dica: Anote falhas em uma planilha “Item / Passo / Resultado”.

---

## 3. Roteiro por Categoria

### 3.1 Decorações (9 itens)
1. **cerca_madeira** – verifique colisão e snap em sequência.  
2. **fonte_pedra** – confirme som e partículas de água.  
3. **luminaria_jardim** – use _Clock_ para alternar dia/noite e ver brilho.  
4. **banco_parque** – use _Sit_ (avatar deve sentar sem afundar).  
5. **caixa_correio** – clique para abrir GUI de armazenamento (5 slots).  
6. **estatua_pequena / estatua_grande** – observe textura de envelhecimento.  
7. **arvore_pequena** (já validada em plantas, mas teste colisão aqui também).

### 3.2 Móveis (7 itens)
- **mesa_madeira / mesa_centro** – tente colocar objetos decorativos em cima.  
- **cadeira_simples / sofa_moderno** – sentar, verificar alinhamento ao assento.  
- **estante_livros** – abra painel “GuardarItens”, mova um item decorativo.  
- **cama_simples** – pressione tecla _E_ para “Dormir” e veja animação.  
- **guarda_roupa** – guardar 3+ roupas dummy, fechar/abrir novamente.

### 3.3 Plantas (6 itens)
- **arvore_grande / palmeira** – aproxime, afaste e olhe variação LOD.  
- **arbusto_flores / grama_decorativa / jardim_flores** – verifique que _CanCollide_ está **false** para evitar bloqueios.  
- Todos: efeito de vento oscilando suavemente (check Output para Script “EfeitoVento”).

### 3.4 Especiais (5 itens)
- **portal_magico** – entrar: personagem teleporta 10 studs à frente.  
- **cristal_energia** – PointLight roxo pulsante.  
- **altar_mistico** – clique _E_ → mensagem “Ritual não disponível”.  
- **totem_tribal** – partículas ocasionais de fogo.  
- **ruinas_antigas** – colisão complexa OK.

### 3.5 Ferramentas (5 itens)
1. Comprar **martelo_construcao** → aparecer no _Hotbar_.  
2. Selecionar **pa_jardinagem** → cavar buraco (simulação de remover terreno).  
3. **regador** → clicar sobre planta, Output: “Planta regada!”.  
4. **serra** → usar em _cerca_madeira_ → modelo remove-se.  
5. **caixa_ferramentas** → abrir/fechar, guardar ferramentas.

---

## 4. Testes de Performance & Cache

1. Coloque 40 + itens misturados em um canto da ilha.  
2. Abra **F9** (MicroProfiler) e observe quadros; FPS não deve cair abaixo de 55 em máquina média.  
3. Espere 11 min e abra a interface novamente → verifique no Output logs “Removido do cache” (função LimparCache).  
4. Reabra loja: itens ainda carregam rápido (cache repovoado).

---

## 5. Regressão de Dados

1. Finalize sessão _Play_ → _Stop_.  
2. Inicie outra sessão e confira se itens comprados/colocados persistem (DataStore).  
3. Comparar DreamCoins antes/depois (EconomiaModule).

---

## 6. Troubleshooting

| Sintoma | Possível causa | Ação sugerida |
|---------|----------------|---------------|
| Item não aparece na loja | ModelosItens: ItemExiste false | Verifique `id` na tabela; recompile script |
| “Cannot load Asset” no Output | Modelo ausente em **ServerStorage/Modelos** | Copiar .rbxm correto ou rely on fallback |
| Avatar atravessa modelo | `CanCollide=false` na PrimaryPart | Ajuste `fisica.canCollide` p/ true |
| LOD nunca troca | Distância teste < 25 studs | Afastar câmera ou reduzir `DISTANCIA_LOD` |
| Partículas ou luz não aparecem | `modelo.PrimaryPart` errado | Checar fallback; setar PrimaryPart manualmente |
| Cache não limpa | `cacheModelos` < MAX_CACHE_SIZE | Teste com mais itens ou diminua `TEMPO_CACHE` |

---

## 7. Checklist Final

- [ ] Todos os 26 itens visíveis e compráveis  
- [ ] Interações funcionam conforme descrição  
- [ ] Nenhum erro ou warning crítico no Output  
- [ ] FPS ≥ 55 com 40+ itens  
- [ ] Dados persistem entre sessões  

_Assim que todas as caixas estiverem marcadas, a Melhoria B está **APROVADA**!_

---
