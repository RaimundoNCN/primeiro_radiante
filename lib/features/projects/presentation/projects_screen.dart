import 'package:flutter/material.dart';

import '../../../core/persistence/analysis_database.dart';
import '../../../core/theme/radiant_theme.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<ProjectRecord> _projects = const [];
  List<AnalysisRunRecord> _runs = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final projects = await AnalysisDatabase.instance.projects();
      final runs = await AnalysisDatabase.instance.recentRuns(limit: 20);
      if (mounted) {
        setState(() {
          _projects = projects;
          _runs = runs;
          _error = null;
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _create() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo projeto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty) return;
    await AnalysisDatabase.instance.createProject(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projetos'),
        actions: [
          IconButton(
            onPressed: _create,
            tooltip: 'Novo projeto',
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'MODELOS E HISTÓRICO',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: RadiantColors.gold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Experimentos reproduzíveis',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (_error != null) Text(_error!),
          const SizedBox(height: 16),
          for (final project in _projects)
            Card(
              child: ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(project.title),
                subtitle: Text('Criado em ${project.createdAt.toLocal()}'),
                trailing: project.id == 'default'
                    ? const Icon(Icons.lock_outline)
                    : IconButton(
                        onPressed: () async {
                          await AnalysisDatabase.instance.deleteProject(
                            project.id,
                          );
                          await _load();
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Execuções recentes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final run in _runs)
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(run.scenarioName),
              subtitle: Text('${run.kind} • ${run.createdAt.toLocal()}'),
            ),
        ],
      ),
    );
  }
}
