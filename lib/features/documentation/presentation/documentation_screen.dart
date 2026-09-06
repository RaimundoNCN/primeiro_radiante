import 'package:flutter/material.dart';

import '../../../core/theme/radiant_theme.dart';

class DocumentationScreen extends StatefulWidget {
  const DocumentationScreen({super.key});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocumentationScreenState extends State<DocumentationScreen> {
  final _search = TextEditingController();

  final _sections = const [
    _DocumentationSection(
      icon: Icons.route_rounded,
      title: 'Como começar',
      tags: 'fluxo desbloqueio núcleo',
      paragraphs: [
        'Desbloqueie o portal pelo círculo e três toques ou use a entrada acessível. No Núcleo, escolha Novo cálculo para abrir a Bancada ou Visualização para abrir o Observatório de tendências.',
        'O fluxo recomendado é: definir entradas, executar, revisar o resultado, comparar cenários e salvar uma observação reproduzível.',
      ],
    ),
    _DocumentationSection(
      icon: Icons.timeline_rounded,
      title: 'Simulação de cenário',
      tags: 'cenário crescimento etapas semente população',
      fields: [
        'Estado inicial: valor a partir do qual a trajetória começa.',
        'Crescimento por etapa: taxa decimal aplicada a cada período. Exemplo: 0.12 equivale a 12%.',
        'Etapas: quantidade de passos simulados.',
        'Semente: controla o ruído aleatório. A mesma semente reproduz o mesmo resultado.',
      ],
      paragraphs: [
        'Use para explorar crescimento, queda e choques em um sistema agregado.',
      ],
    ),
    _DocumentationSection(
      icon: Icons.alt_route_rounded,
      title: 'Cadeia de Markov',
      tags: 'markov transição estados probabilidade matriz',
      fields: [
        'Matriz: cada linha representa um estado de origem e cada valor uma probabilidade de transição. Separe linhas por ponto e vírgula.',
        'Distribuição inicial: probabilidades dos estados no começo. Deve somar 1.',
        'Etapas: número de transições aplicadas.',
      ],
      paragraphs: [
        'O resultado mostra a distribuição futura e a distribuição estacionária aproximada.',
      ],
    ),
    _DocumentationSection(
      icon: Icons.show_chart_rounded,
      title: 'Série temporal',
      tags: 'série média móvel tendência previsão valores',
      fields: [
        'Valores: observações numéricas separadas por vírgulas e ordenadas no tempo.',
        'Janela da média móvel: quantidade de pontos usados em cada média.',
        'Períodos de previsão: quantidade de pontos futuros estimados pela tendência linear.',
      ],
      paragraphs: [
        'A previsão é uma extrapolação matemática; não representa uma garantia sobre o futuro.',
      ],
    ),
    _DocumentationSection(
      icon: Icons.hub_outlined,
      title: 'Rede e influência',
      tags: 'rede nós arestas influência propagação decaimento',
      fields: [
        'Arestas: use o formato A>B:0.8, B>C:0.6. O peso deve ser não negativo.',
        'Nó de origem: ponto onde a influência começa.',
        'Etapas: profundidade da propagação.',
        'Decaimento: fator aplicado a cada etapa; valores menores reduzem o alcance.',
      ],
      paragraphs: [
        'O mapa interativo permite arrastar nós para inspecionar visualmente as relações.',
      ],
    ),
    _DocumentationSection(
      icon: Icons.visibility_rounded,
      title: 'Observatório de tendências',
      tags:
          'observatório grupos instituições história crise seldon monte carlo',
      fields: [
        'Períodos históricos: extensão da linha do tempo.',
        'Simulações Monte Carlo: quantidade de trajetórias alternativas.',
        'Evento e impacto: choque histórico aplicado no período escolhido.',
        'Grupos: nome:população:estabilidade:recursos:resistência, separados por |.',
        'Instituições: nome:influência:decadência, separadas por |.',
      ],
      paragraphs: [
        'O Observatório combina tendências coletivas, recursos, instituições, propagação de ideias, crises, contrafactuais e explicação histórica.',
        'P10, P50 e P90 resumem a distribuição das simulações. P50 é a mediana; P10 e P90 delimitam uma faixa de resultados possíveis.',
      ],
    ),
    _DocumentationSection(
      icon: Icons.insights_rounded,
      title: 'Como ler os resultados',
      tags: 'resultado gráfico comparação histórico explicação p10 p50 p90',
      paragraphs: [
        'Trajetórias mostram como uma grandeza muda ao longo dos períodos. Picos, quedas e mudanças próximas a eventos merecem investigação, não uma conclusão automática.',
        'Crises são sinais definidos por limiares do modelo. Elas indicam que as premissas produziram instabilidade, não que um acontecimento real necessariamente ocorrerá.',
        'A comparação de cenários mostra diferenças entre execuções. Altere uma premissa por vez quando quiser entender causalidade.',
      ],
    ),
    _DocumentationSection(
      icon: Icons.save_outlined,
      title: 'Salvar e exportar',
      tags: 'sqlite salvar persistência exportar json texto',
      paragraphs: [
        'Salvar cenário ou observação grava entradas, parâmetros, resultados e data no banco SQLite local do dispositivo.',
        'A exportação copia JSON ou texto para a área de transferência. O JSON é apropriado para backup e processamento; o texto é apropriado para leitura rápida.',
      ],
    ),
    _DocumentationSection(
      icon: Icons.fact_check_outlined,
      title: 'Previsão e validação',
      tags: 'previsão determinística probabilística backtesting erro viés rmse',
      paragraphs: [
        'Previsão determinística significa que entradas iguais e a mesma semente produzem a mesma trajetória.',
        'Previsão probabilística significa executar várias trajetórias e resumir a distribuição, sem transformar incerteza em certeza.',
        'O módulo de backtesting compara previsões com observações históricas e calcula erro absoluto médio, RMSE, viés e cobertura P10-P90. Uma previsão só deve ganhar confiança depois de ser avaliada em dados que não ajustaram o modelo.',
      ],
    ),
    _DocumentationSection(
      icon: Icons.science_outlined,
      title: 'Limites e uso responsável',
      tags: 'limites ciência psicohistória privacidade hipótese',
      paragraphs: [
        'O sistema não prevê indivíduos, não descobre leis universais da sociedade e não substitui dados, especialistas ou decisões responsáveis.',
        'Os modelos atuais são hipotéticos e locais. Resultados dependem da qualidade dos dados, das premissas, dos limiares e da semente usada.',
        'Não use o aplicativo sozinho para decisões médicas, financeiras, legais, estruturais ou de segurança.',
        'A inspiração em Fundação é conceitual: estudar tendências coletivas com humildade científica, sem afirmar que a psicohistória fictícia existe.',
      ],
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _sections
        .where((section) => section.matches(query))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Documentação')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'GUIA DO PRIMEIRO RADIANTE',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: RadiantColors.gold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entenda cada câmara',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Consulte os campos, cálculos, resultados e limites do sistema.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          TextField(
            key: const Key('documentation-search'),
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Buscar na documentação',
            ),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Nenhuma seção encontrada.'),
            ),
          for (final section in visible) _DocumentationCard(section: section),
        ],
      ),
    );
  }
}

class _DocumentationSection {
  const _DocumentationSection({
    required this.icon,
    required this.title,
    required this.tags,
    this.fields = const [],
    this.paragraphs = const [],
  });

  final IconData icon;
  final String title;
  final String tags;
  final List<String> fields;
  final List<String> paragraphs;

  bool matches(String query) =>
      query.isEmpty ||
      '$title $tags ${fields.join(' ')} ${paragraphs.join(' ')}'
          .toLowerCase()
          .contains(query);
}

class _DocumentationCard extends StatelessWidget {
  const _DocumentationCard({required this.section});

  final _DocumentationSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: RadiantColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: ExpansionTile(
          leading: Icon(section.icon, color: RadiantColors.gold),
          title: Text(section.title),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            for (final paragraph in section.paragraphs) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  paragraph,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (section.fields.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Campos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              for (final field in section.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '• $field',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
