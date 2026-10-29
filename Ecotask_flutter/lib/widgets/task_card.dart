import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/number_format.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'carbon_pill.dart';
import 'category_colors.dart';
import 'entrance.dart';
import 'glass_card.dart';

/// Activity card (TaskCard.jsx).
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final int index;
  final ValueChanged<Task> onToggle;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context) {
    final meta = AppConstants.categoryMeta(task.category);
    final done = task.completed;

    return Entrance(
      delay: Duration(milliseconds: (index.clamp(0, 12)) * 40),
      duration: const Duration(milliseconds: 350),
      offset: const Offset(0, 15),
      child: GlassCard(
        key: Key('task-${task.id}'),
        opacity: done ? 0.6 : 1,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckButton(done: done, onTap: () => onToggle(task)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          task.title,
                          style: AppText.bodyStyle(
                            14,
                            weight: FontWeight.w600,
                            color:
                                done ? AppColors.sage400 : AppColors.forest900,
                            height: 1.43,
                          ).copyWith(
                              decoration:
                                  done ? TextDecoration.lineThrough : null),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: meta.bg,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('${meta.emoji} ${meta.label}',
                                style: AppText.bodyStyle(12,
                                    weight: FontWeight.w500,
                                    color: meta.color)),
                          ),
                          Text(task.date,
                              style: AppText.bodyStyle(12,
                                  color: AppColors.sage400)),
                          if (task.quantity != 0 && task.unit.isNotEmpty)
                            Text(
                                '${JsNumber.toJsString(task.quantity)} ${task.unit}',
                                style: AppText.monoStyle(12,
                                    color: AppColors.sage400)),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyStyle(12,
                                color: AppColors.sage500)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    CarbonPill(value: task.carbonValue, large: true),
                    if (task.isSaving)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('saved',
                            style: AppText.bodyStyle(10,
                                color: AppColors.forest500)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.forest50),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(label: '✏️ Edit', onTap: () => onEdit(task)),
                const SizedBox(width: 4),
                _ActionButton(label: '🗑 Delete', onTap: () => onDelete(task)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: done,
      label: done ? 'Mark as not completed' : 'Mark as completed',
      child: InkResponse(
        key: const Key('task-toggle'),
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.forest500 : Colors.transparent,
                border: Border.all(
                    color: done ? AppColors.forest500 : AppColors.forest300,
                    width: 2),
              ),
              child: done
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(label,
            style: AppText.bodyStyle(12,
                weight: FontWeight.w500, color: AppColors.sage500)),
      ),
    );
  }
}
