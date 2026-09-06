import 'package:flutter/material.dart';

import '../../../core/theme/radiant_theme.dart';
import '../../analysis/presentation/analysis_workbench_screen.dart';
import '../../observatory/presentation/trend_observatory_screen.dart';
import '../../documentation/presentation/documentation_screen.dart';
import '../../forecasting/presentation/forecast_validation_screen.dart';
import '../../projects/presentation/projects_screen.dart';

class RadiantHomeScreen extends StatelessWidget {
  const RadiantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NÚCLEO ATIVO',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: RadiantColors.gold,
                                  letterSpacing: 3,
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'O que vamos\ncompreender hoje?',
                            key: const Key('home-title'),
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Documentação',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DocumentationScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AnalysisWorkbenchScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Novo cálculo'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: RadiantColors.luminousGold,
                    foregroundColor: RadiantColors.voidBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Câmaras do Radiante',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 176,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildListDelegate.fixed([
                  _ChamberCard(
                    icon: Icons.calculate_outlined,
                    title: 'Bancada',
                    description: 'Expressões, variáveis e unidades',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AnalysisWorkbenchScreen(),
                      ),
                    ),
                  ),
                  _ChamberCard(
                    icon: Icons.hub_outlined,
                    title: 'Projetos',
                    description: 'Cenários e versões reproduzíveis',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProjectsScreen(),
                      ),
                    ),
                  ),
                  const _ChamberCard(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Intérprete',
                    description: 'Transforme perguntas em modelos',
                  ),
                  _ChamberCard(
                    icon: Icons.account_tree_outlined,
                    title: 'Visualização',
                    description: 'Explore relações e dependências',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TrendObservatoryScreen(),
                      ),
                    ),
                  ),
                  _ChamberCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Documentação',
                    description: 'Aprenda como cada câmara funciona',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DocumentationScreen(),
                      ),
                    ),
                  ),
                  _ChamberCard(
                    icon: Icons.fact_check_outlined,
                    title: 'Validação',
                    description: 'Compare previsões com dados históricos',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ForecastValidationScreen(),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChamberCard extends StatelessWidget {
  const _ChamberCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RadiantColors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: RadiantColors.gold),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
