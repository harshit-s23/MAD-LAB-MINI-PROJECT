import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_date.dart';
import '../core/constants.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/eco_button.dart';
import '../widgets/form_widgets.dart';
import '../widgets/glass_card.dart';
import '../widgets/states.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_sheet.dart';

/// Activities screen (TasksPage.jsx): summary, filters, list, create/edit sheet.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<TaskProvider>();
    _search.text = provider.search;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) provider.load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openForm([Task? task]) {
    final provider = context.read<TaskProvider>();
    showTaskFormSheet(
      context,
      editTask: task,
      onSave: (input) => provider.save(input, editingId: task?.id),
    );
  }

  Future<void> _delete(Task task) async {
    final provider = context.read<TaskProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Delete this activity?',
            style: AppText.displayStyle(18, weight: FontWeight.w600)),
        content: Text('"${task.title}" will be removed from your history.',
            style: AppText.bodyStyle(14, color: AppColors.sage600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.sage600),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red500),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await provider.delete(task.id);
    result.success
        ? AppToast.success(result.message ?? 'Deleted')
        : AppToast.error(result.message ?? 'Failed to delete');
  }

  Future<void> _toggle(Task task) async {
    final result = await context.read<TaskProvider>().toggle(task);
    if (!result.success) {
      AppToast.error(result.message ?? 'Failed to update task');
    }
  }

  Future<void> _pickFilterDate() async {
    final provider = context.read<TaskProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: AppDate.tryParse(provider.date) ?? AppDate.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) await provider.setDate(AppDate.dayOf(picked));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    final tasks = p.filtered;

    return RefreshIndicator(
      color: AppColors.forest600,
      onRefresh: p.load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: Padding(
                  padding: AppSpacing.page,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(onAdd: () => _openForm()),
                      const SizedBox(height: 24),
                      _SummaryRow(
                          emitted: p.totalEmissions,
                          saved: p.totalSaved,
                          net: p.netCarbon),
                      const SizedBox(height: 24),
                      _Filters(
                        search: _search,
                        provider: p,
                        onPickDate: _pickFilterDate,
                        onClear: () {
                          _search.clear();
                          p.clearFilters();
                        },
                      ),
                      const SizedBox(height: 24),
                      if (p.loading && p.tasks.isEmpty)
                        const LoadingView(
                            message: 'Loading activities...',
                            emoji: '🌿',
                            height: 160)
                      else if (p.error != null && p.tasks.isEmpty)
                        ErrorState(message: p.error!, onRetry: p.load)
                      else if (tasks.isEmpty)
                        EmptyState(
                          title: 'No activities yet',
                          message:
                              'Start logging your daily activities to track your carbon footprint',
                          actionLabel: 'Log your first activity',
                          onAction: () => _openForm(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (tasks.isNotEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _TaskGrid(
                        tasks: tasks,
                        onToggle: _toggle,
                        onEdit: _openForm,
                        onDelete: _delete),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Activities', style: AppText.pageTitle),
              const SizedBox(height: 4),
              Text('Log and manage your carbon activities',
                  style: AppText.subtitle),
            ],
          ),
        ),
        const SizedBox(width: 12),
        EcoButton(
          key: const Key('add-activity'),
          label: '+ Log Activity',
          expand: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.emitted, required this.saved, required this.net});

  final double emitted;
  final double saved;
  final double net;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Emitted', emitted, false, '📈'),
      ('Saved', saved, true, '📉'),
      ('Net', net, net < 0, '⚖️'),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
              child: _SummaryCard(
                  label: items[i].$1,
                  value: items[i].$2,
                  forest: items[i].$3,
                  icon: items[i].$4)),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.forest,
      required this.icon});

  final String label;
  final double value;
  final bool forest;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final color = forest ? AppColors.forest700 : AppColors.earth700;
    final text = '${value < 0 ? '−' : ''}${value.abs().toStringAsFixed(2)}';
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStyle(11,
                        weight: FontWeight.w500,
                        color: AppColors.sage500,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: text,
                      style: AppText.displayStyle(20, color: color)),
                  TextSpan(
                      text: ' kg CO₂',
                      style: AppText.bodyStyle(12, color: AppColors.sage500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters(
      {required this.search,
      required this.provider,
      required this.onPickDate,
      required this.onClear});

  final TextEditingController search;
  final TaskProvider provider;
  final VoidCallback onPickDate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('task-search'),
            controller: search,
            onChanged: provider.setSearch,
            style: AppText.input,
            textInputAction: TextInputAction.search,
            decoration: AppTheme.inputDecoration(
                hint: '🔍 Search activities...',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final category = AppDropdown<String>(
                value: provider.category,
                onChanged: (v) => provider.setCategory(v ?? ''),
                items: [
                  const DropdownMenuItem(
                      value: '', child: Text('All Categories')),
                  for (final cat in AppConstants.categories)
                    DropdownMenuItem(
                        value: cat.value,
                        child: Text('${cat.emoji} ${cat.label}')),
                ],
              );
              final date = DateFieldBox(
                value: provider.date,
                placeholder: 'Any date',
                onTap: onPickDate,
                onClear: () => provider.setDate(''),
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: category),
                  const SizedBox(width: 12),
                  Expanded(child: date),
                ],
              );
            },
          ),
          if (provider.hasActiveFilters) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                key: const Key('clear-filters'),
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red500,
                  side: const BorderSide(color: AppColors.red100),
                  minimumSize: const Size(0, 40),
                ),
                child: const Text('Clear'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Two columns on wide screens (`md:grid-cols-2`), one column on phones.
class _TaskGrid extends StatelessWidget {
  const _TaskGrid(
      {required this.tasks,
      required this.onToggle,
      required this.onEdit,
      required this.onDelete});

  final List<Task> tasks;
  final ValueChanged<Task> onToggle;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 720 ? 2 : 1;
        Widget card(int i) => TaskCard(
            task: tasks[i],
            index: i,
            onToggle: onToggle,
            onEdit: onEdit,
            onDelete: onDelete);
        if (columns == 1) {
          return Column(
            children: [
              for (var i = 0; i < tasks.length; i++)
                Padding(
                    padding: const EdgeInsets.only(bottom: 12), child: card(i)),
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < tasks.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: card(i)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: i + 1 < tasks.length
                            ? card(i + 1)
                            : const SizedBox.shrink()),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
