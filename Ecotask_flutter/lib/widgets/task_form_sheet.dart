import 'package:flutter/material.dart';

import '../core/app_date.dart';
import '../core/constants.dart';
import '../core/number_format.dart';
import '../core/validators.dart';
import '../models/task.dart';
import '../models/task_input.dart';
import '../providers/op_result.dart';
import '../services/carbon_engine.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_toast.dart';
import 'eco_button.dart';
import 'entrance.dart';
import 'form_widgets.dart';

/// Opens the create / edit bottom sheet (TaskModal.jsx as a mobile sheet).
///
/// [onSave] persists the task; the sheet closes only when it succeeds, and
/// otherwise shows the error and stays open (like the original modal).
Future<void> showTaskFormSheet(
  BuildContext context, {
  Task? editTask,
  required Future<OpResult> Function(TaskInput input) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    builder: (_) => TaskFormSheet(editTask: editTask, onSave: onSave),
  );
}

class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({super.key, this.editTask, required this.onSave});

  final Task? editTask;
  final Future<OpResult> Function(TaskInput input) onSave;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _quantity;
  late final TextEditingController _unit;
  late String _category;
  late String _subcategory;
  late String _date;
  bool _saving = false;

  bool get _editing => widget.editTask != null;

  @override
  void initState() {
    super.initState();
    final t = widget.editTask;
    _title = TextEditingController(text: t?.title ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _quantity =
        TextEditingController(text: JsNumber.toJsString(t?.quantity ?? 1));
    _category = t?.category ?? 'transport';
    _subcategory = t?.subcategory ?? '';
    _date = t?.date ?? AppDate.today();
    var unit = t?.unit ?? 'km';
    // Original effect: selecting a known type sets the unit to the type's unit.
    final sub = _findSub(_category, _subcategory);
    if (sub != null) unit = sub.unit;
    _unit = TextEditingController(text: unit);
    _quantity.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _quantity.dispose();
    _unit.dispose();
    super.dispose();
  }

  SubcategoryOption? _findSub(String category, String value) {
    for (final s in AppConstants.subcategoriesOf(category)) {
      if (s.value == value) return s;
    }
    return null;
  }

  /// `parseFloat(value) || 1`
  double get _parsedQuantity {
    final v = double.tryParse(_quantity.text.trim());
    return (v == null || v == 0 || v.isNaN) ? 1 : v;
  }

  /// Live "Estimated impact" (factor * quantity, toFixed(3)); null when no type.
  double? get _preview {
    if (_subcategory.isEmpty) return null;
    final factor = CarbonEngine.factors[_category]?[_subcategory];
    if (factor == null) return null;
    return JsNumber.round(factor.factor * _parsedQuantity, 3);
  }

  void _selectCategory(String value) {
    final first = AppConstants.subcategoriesOf(value).isEmpty
        ? null
        : AppConstants.subcategoriesOf(value).first;
    setState(() {
      _category = value;
      _subcategory = first?.value ?? '';
      _unit.text = first?.unit ?? 'unit';
    });
  }

  void _selectSubcategory(String value) {
    setState(() {
      _subcategory = value;
      final sub = _findSub(_category, value);
      if (sub != null) _unit.text = sub.unit;
    });
  }

  Future<void> _pickDate() async {
    final initial = AppDate.tryParse(_date) ?? AppDate.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = AppDate.dayOf(picked));
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final input = TaskInput(
      title: _title.text.trim(),
      description: _description.text,
      category: _category,
      subcategory: _subcategory,
      quantity: _parsedQuantity,
      unit: _unit.text,
      date: _date,
    );
    final result = await widget.onSave(input);
    if (!mounted) return;
    if (result.success) {
      AppToast.success(result.message ?? 'Saved');
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
      AppToast.error(result.message ?? 'Failed to save');
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final subs = AppConstants.subcategoriesOf(_category);
    final preview = _preview;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.94),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
                editing: _editing, onClose: () => Navigator.of(context).pop()),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledTextField(
                        label: 'Activity Title *',
                        uppercaseLabel: true,
                        dense: true,
                        controller: _title,
                        hint: 'e.g. Morning commute to work',
                        validator: Validators.taskTitle,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel('Category *', uppercase: true),
                      _CategoryGrid(
                          selected: _category, onSelected: _selectCategory),
                      if (subs.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const FieldLabel('Type', uppercase: true),
                        AppDropdown<String>(
                          value: subs.any((s) => s.value == _subcategory)
                              ? _subcategory
                              : '',
                          onChanged: (v) => _selectSubcategory(v ?? ''),
                          items: [
                            const DropdownMenuItem(
                                value: '', child: Text('Select type...')),
                            for (final s in subs)
                              DropdownMenuItem(
                                  value: s.value, child: Text(s.label)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: LabeledTextField(
                              label: 'Quantity',
                              uppercaseLabel: true,
                              dense: true,
                              controller: _quantity,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: Validators.quantity,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LabeledTextField(
                              label: 'Unit',
                              uppercaseLabel: true,
                              dense: true,
                              controller: _unit,
                              hint: 'km, kg, kWh...',
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel('Date *', uppercase: true),
                      DateFieldBox(
                          value: _date, onTap: _pickDate, dense: false),
                      const SizedBox(height: 16),
                      LabeledTextField(
                        label: 'Notes (optional)',
                        uppercaseLabel: true,
                        dense: true,
                        controller: _description,
                        hint: 'Any additional notes...',
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      if (preview != null) ...[
                        const SizedBox(height: 16),
                        _ImpactPreview(value: preview),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: EcoOutlinedButton(
                                label: 'Cancel',
                                onPressed: () => Navigator.of(context).pop()),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: EcoButton(
                              label: _editing ? '✏️ Update' : '🌱 Log Activity',
                              onPressed: _saving ? null : _submit,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.editing, required this.onClose});

  final bool editing;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.forest600,
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(editing ? 'Edit Activity' : 'Log Activity',
                    style: AppText.displayStyle(20,
                        color: Colors.white, height: 1.4)),
                const SizedBox(height: 2),
                Text('Track your carbon impact',
                    style: AppText.bodyStyle(12, color: AppColors.forest200)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: AppColors.forest200),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final width = (constraints.maxWidth - gap * 3) / 4;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final cat in AppConstants.categories)
              SizedBox(
                width: width,
                child: InkWell(
                  key: Key('category-${cat.value}'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelected(cat.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected == cat.value
                          ? AppColors.forest600
                          : const Color(0x99FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected == cat.value
                              ? AppColors.forest600
                              : AppColors.forest100),
                    ),
                    child: Column(
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          cat.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyStyle(12,
                              weight: FontWeight.w500,
                              color: selected == cat.value
                                  ? Colors.white
                                  : AppColors.sage700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ImpactPreview extends StatelessWidget {
  const _ImpactPreview({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final negative = value < 0;
    return Entrance(
      offset: const Offset(0, 5),
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: const Key('impact-preview'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: negative ? AppColors.forest100 : AppColors.earth50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: negative ? AppColors.forest200 : AppColors.earth200),
        ),
        child: Row(
          children: [
            Text(negative ? '🟢' : '🟡'),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: AppText.bodyStyle(14,
                      weight: FontWeight.w500,
                      color:
                          negative ? AppColors.forest800 : AppColors.earth800),
                  children: [
                    const TextSpan(text: 'Estimated impact: '),
                    TextSpan(
                      text:
                          '${negative ? '−' : '+'}${JsNumber.toJsString(value.abs())} kg CO₂',
                      style: AppText.monoStyle(14,
                          weight: FontWeight.w700,
                          color: negative
                              ? AppColors.forest800
                              : AppColors.earth800),
                    ),
                    TextSpan(text: negative ? ' saved' : ' emitted'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
