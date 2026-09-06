# Primeiro Radiante

Aplicativo Flutter independente para cálculos, exploração matemática e
simulação de cenários. O primeiro incremento implementa o portal dourado de
entrada: desenhe um círculo em um único movimento e depois dê três toques.

## Estado atual

- projeto Flutter próprio (`br.com.primeiroradiante`);
- Android e iOS como plataformas exclusivas;
- identidade visual escura e dourada;
- campo animado contínuo, sem emenda de loop, com órbitas e profundidade;
- partículas atraídas pelo toque, ondas temporizadas e traços luminosos;
- entrada progressiva, dissolução de tentativas e expansão de desbloqueio;
- reconhecedor geométrico de círculo horário e anti-horário;
- sequência temporal de três toques;
- alternativa de entrada acessível;
- tela inicial responsiva do Núcleo;
- testes unitários e de widgets;
- núcleo de análise local para cenários, Markov, séries temporais e redes de
  influência, com resultados determinísticos e testáveis;
- bancada humana para executar os quatro tipos de análise offline.
- Observatório de Tendências com dez funções inspiradas em história coletiva:
  tendências agregadas, crises, contrafactuais, Monte Carlo, instituições,
  história longa, propagação de ideias, indicadores de estabilidade,
  intervenções históricas e explicação causal.
- validação de previsões por backtesting, com erro médio, viés, RMSE e cobertura
  da faixa P10-P90.
- importação de CSV no dispositivo, calibração automática e catálogo de dataset
  sintético versionado para testes reproduzíveis.
- motor de expressões seguro com variáveis, funções fechadas e unidades básicas;
- projetos persistidos, histórico de execuções e execução isolada para cálculos
  pesados.

## Executar

```bash
flutter pub get
flutter devices
flutter run -d <dispositivo-android-ou-ios>
```

O build de iOS exige macOS com Xcode. Web e desktop não são plataformas
suportadas por este projeto.

## Teste humano atual

1. Execute `flutter run -d <dispositivo-android-ou-ios>`.
2. Use “Entrada acessível” no portal ou faça o gesto de desbloqueio.
3. No Núcleo, toque em “Novo cálculo”.
4. Escolha uma câmara na lista e altere os valores de exemplo.
5. Toque em “Executar análise”.
6. Dê um nome e use “Salvar cenário localmente” para gravar no SQLite.
7. Use o menu de exportação para copiar JSON ou texto para a área de
  transferência.
8. Na câmara “Validação”, importe CSV pelo ícone de arquivo ou carregue o
  dataset sintético versionado.
9. Execute o backtesting e use “Calibrar automaticamente” para medir a
  correção de viés e a nova faixa de incerteza.

Formatos aceitos na bancada:

- cenário: crescimento como decimal, por exemplo `0.12`;
- Markov: matriz `0.8,0.2;0.4,0.6` e distribuição `1,0`;
- série temporal: valores separados por vírgula;
- rede: arestas no formato `A>B:0.8, B>C:0.6`.

Os resultados da sessão são comparados em memória e os cenários salvos ficam no
SQLite local. O gráfico permite tocar na linha para inspecionar um ponto, e o
mapa de rede permite arrastar os nós.

Na câmara “Visualização”, abra o “Observatório de tendências”, ajuste períodos,
simulações e um choque histórico, e toque em “Observar trajetória”. O resultado
mostra a linha histórica, pontos de ruptura, efeito contrafactual, instituições,
alcance de ideias, distribuição Monte Carlo e uma explicação resumida.

O editor aceita grupos no formato `nome:população:estabilidade:recursos:resistência`
e instituições no formato `nome:influência:decadência`, separados por `|`.
Também é possível salvar a observação completa no SQLite local.

Para aproximar previsões do mundo observado, o motor também aceita observações
históricas e compara cada período previsto com o valor real. Uma previsão só
deve ganhar confiança depois de apresentar erro e cobertura medidos em dados
que não foram usados para ajustar o modelo.

## Checklist físico

- Android: abrir, desbloquear, executar os quatro modos, salvar e exportar;
- Android em 320 px: confirmar que os campos e o botão continuam alcançáveis;
- iOS: repetir o fluxo após `flutter pub get` em macOS com Xcode;
- acessibilidade: testar leitor de tela, teclado externo e texto ampliado;
- desempenho: observar rolagem, arraste dos nós e resposta ao toque no gráfico.

## Validar

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk
```

O workflow de CI em `.github/workflows/flutter.yml` repete dependências,
formatação, análise, testes e build Android em cada alteração principal.
O roteiro manual para dispositivos está em
`docs/VALIDACAO_DISPOSITIVOS.md`.

## Documentação

O planejamento completo está em [`docs/README.md`](docs/README.md).

