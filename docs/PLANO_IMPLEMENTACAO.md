# Plano de implementação e validação — Primeiro Radiante

## 1. Estratégia de execução

Cada marco termina com uma demonstração verificável. A equipe não inicia
sincronização, IA remota ou visualização complexa antes de o motor matemático e
a persistência local passarem pelos seus critérios.

### Marco 0 — criação do projeto independente

Entregas:

- criar diretório e repositório Git exclusivos do Primeiro Radiante;
- gerar um projeto Flutter novo, sem copiar módulos da Nuvem;
- definir identificadores próprios de Android e iOS;
- configurar banco, ambientes, dependências, testes e CI independentes;
- validar nome, identidade original e limites jurídicos da inspiração;
- definir plataformas do MVP e aparelhos mínimos;
- aprovar escopo, tipos numéricos e lista inicial de funções;
- registrar decisões arquiteturais (ADRs).

Saída: esqueleto Flutter isolado, análise estática e testes executando no CI.

### Marco 1 — protótipo do portal dourado

Entregas:

- reconhecedor puro de círculo com métricas;
- máquina de estados círculo → três toques;
- `CustomPainter` reativo e qualidade adaptativa;
- tutorial, alternativa acessível e redução de movimento;
- telemetria local de calibração sem registrar coordenadas em produção.

Saída: gesto aprovado em aparelhos físicos e critérios de
`GESTO_DESBLOQUEIO.md` atendidos.

### Marco 2 — núcleo matemático

Entregas:

- gramática, tokenizer, parser e AST;
- tipos numéricos e política de precisão;
- catálogo fechado de funções;
- validação de símbolos, unidades e domínio;
- avaliador, cancelamento, limites e explicação por etapas;
- testes unitários, de propriedades e resultados de referência.

Saída: pacote Dart independente calcula o conjunto P0 sem Flutter ou banco.

#### Incremento de análise de sistemas

O núcleo também oferece quatro primitivas locais, sem previsão determinística
de pessoas ou sociedades:

- `ScenarioSimulator`: evolução de estados por passos, com semente explícita;
- `MarkovChain`: transições, distribuição futura e estado estacionário;
- `TimeSeriesAnalysis`: média móvel e projeção linear com eixo temporal;
- `InfluenceNetwork`: grau de entrada e propagação ponderada por rede.

Cada resultado pode ser associado a um cenário e persistido em
`calculation_runs`, incluindo a configuração, a semente quando aplicável e a
versão do motor.

### Marco 3 — bancada de cálculo

Entregas:

- editor, teclado, variáveis, unidades e resultado;
- estados vazio, inválido, calculando, sucesso e falha;
- histórico da sessão, desfazer/refazer e acessibilidade;
- gráfico básico quando houver uma variável independente;
- execução pesada em isolate com cancelamento.

Saída: usuário cria e entende um cálculo completo offline.

#### Estado atual

A primeira bancada de teste humano já executa os quatro tipos de análise do
incremento de sistemas. Ela ainda usa campos de exemplo e mantém os resultados
somente em memória; editor de expressões, unidades, gráficos e histórico ficam
para as próximas iterações deste marco.

#### Incremento entregue

- validação de previsões com CSV, MAE, RMSE, viés e cobertura P10-P90;
- parser seguro de expressões com AST, variáveis, funções fechadas e erros
    tipados;
- unidades básicas de comprimento, tempo e temperatura;
- projeto/histórico persistido e tela de projetos;
- execução isolada reutilizável para cálculos pesados.
- importação de CSV, catálogo de dataset sintético e calibração automática.
- workflow de CI e roteiro de validação Android/iOS.
- validação física Android e iOS concluída de forma satisfatória.
- exportação JSON versionada com projetos, cenários, execuções e observações.

A calibração contra datasets públicos continua dependendo de fontes de dados e
licenças externas. O aplicativo oferece a infraestrutura local para executar
essas validações sem apresentar uma simulação como evidência científica.

### Marco 4 — projetos, cenários e SQLite

Entregas:

- esquema versionado e migrações;
- CRUD de projetos, revisões e tags;
- cenários, comparação e histórico reproduzível;
- importação/exportação versionadas;
- teste de corrupção, upgrade, backup e restauração.

Saída: fechar/reabrir o aplicativo preserva cálculo, cenários e auditoria.

### Marco 5 — visualização Radiante

Entregas:

- grafo derivado da AST e dependências;
- seleção, zoom, foco e detalhes de nó;
- visão tabular/lista equivalente;
- limites para grafos grandes e benchmark de renderização;
- exportação visual somente após QA de legibilidade.

Saída: a visualização ajuda a localizar dependências sem prejudicar o editor.

### Marco 6 — assistente inteligente opcional

Entregas:

- gateway falso e contratos JSON testados;
- tela de consentimento e revisão da proposta;
- backend intermediário, rate limit e proteção da chave;
- validação local completa e rejeição de funções não permitidas;
- conjunto de evals de matemática, unidade, ambiguidade e prompt injection;
- fallback manual e mensagens de indisponibilidade.

Saída: nenhuma resposta do modelo contorna o parser/validador local.

### Marco 7 — endurecimento e beta

Entregas:

- auditoria de acessibilidade, segurança, privacidade e licenças;
- perfil de desempenho em aparelhos mínimos;
- crash reporting e métricas opt-in;
- política de privacidade, termos e exclusão/exportação;
- beta fechado, triagem de feedback e correção dos bloqueadores;
- plano de publicação, rollback e suporte.

Saída: release candidate assinada e checklist de loja concluído.

### Marco 8 — nuvem, somente se validada

Entregas:

- conta opcional e autenticação;
- PostgreSQL/Supabase com RLS e testes de isolamento;
- sincronização, conflitos, tombstones e modo offline;
- backup, restauração, exportação e exclusão de conta;
- observabilidade sem fórmulas ou dados pessoais por padrão.

Saída: dois dispositivos sincronizam sem perder revisões ou sobrescrever
conflitos silenciosamente.

## 2. Backlog priorizado

| Prioridade | Item |
|---|---|
| P0 | repositório e projeto Flutter totalmente independentes |
| P0 | gesto, alternativa e redução de movimento |
| P0 | parser/AST e avaliador seguro |
| P0 | precisão, unidades, domínio e erros tipados |
| P0 | bancada offline e histórico reproduzível |
| P0 | projetos, revisões, cenários e migrações |
| P1 | simulações de cenários, Markov, séries temporais e redes de influência |
| P1 | visualização de dependências |
| P1 | importação/exportação |
| P1 | assistente com revisão e consentimento |
| P2 | sincronização e contas |
| P2 | colaboração e formatos avançados |

## 3. Definição de pronto

Uma funcionalidade só está pronta quando:

- critérios de aceite estão automatizados quando viável;
- análise estática e testes passam sem exceções ignoradas;
- erros, vazio, carregamento, offline e cancelamento foram tratados;
- funciona em 320 px, aparelho alvo e fonte ampliada;
- possui rótulos semânticos e navegação por foco quando aplicável;
- não registra dados sensíveis;
- documentação e migração foram atualizadas;
- desempenho foi medido, não apenas observado;
- não há segredo ou chave no código cliente.

## 4. Matriz mínima de validação

| Área | Evidência necessária |
|---|---|
| Matemática | suíte de referência + propriedades + limites de erro |
| Gesto | conjunto positivo/negativo + estudo em aparelhos físicos |
| Banco | criação, upgrade, rollback/recuperação e integridade |
| IA | schema, ambiguidade, injeção, indisponibilidade e revisão |
| UI | golden/widget tests, 320 px, tablet e texto ampliado |
| Desempenho | traces de quadros, memória e tempo de cálculo P95 |
| Privacidade | mapa de dados, consentimento, retenção e exclusão |
| Segurança | threat model, dependências, importação e segredos |

## 5. Sequência de comandos esperada no futuro

Os comandos exatos serão registrados após criar o aplicativo isolado:

```text
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test
flutter build apk --release
```

O CI executará análise, testes e build. Testes de banco e backend serão etapas
separadas quando esses componentes existirem.

## 6. Decisão de isolamento confirmada

O Primeiro Radiante terá repositório, projeto Flutter, banco e ciclo de vida
próprios. Não substituirá, importará ou compartilhará código com a Nuvem.

### Plataformas confirmadas

O aplicativo será distribuído e suportado exclusivamente em Android e iOS.
Web, Windows, macOS e Linux não fazem parte do produto.

### Decisões de produto ainda pendentes

1. “Primeiro Radiante” é nome definitivo ou codinome?
2. O MVP deve ter IA online ou primeiro validar apenas o motor local?
3. Conta e sincronização entram no MVP ou depois do beta offline?
4. Quais áreas de cálculo são prioritárias: científica, financeira,
   engenharia, estatística ou educação?
5. O ritual será repetido a cada abertura, por sessão ou apenas no onboarding?

## 7. Próxima ação autorizável

Criar primeiro o repositório independente e concluir o **Marco 0**. Depois de
responder às decisões de produto pendentes, iniciar o spike do **Marco 1**. O
código e o banco da Nuvem ficam permanentemente fora desse fluxo.
