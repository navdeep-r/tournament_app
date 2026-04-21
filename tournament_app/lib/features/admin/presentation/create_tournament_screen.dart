import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/cream_scaffold.dart';
import '../../../shared/widgets/gold_button.dart';

class CreateTournamentScreen extends StatefulWidget {
  final String? tournamentId; // null = create, non-null = edit
  const CreateTournamentScreen({super.key, this.tournamentId});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _maxParticipantsController = TextEditingController(text: '500');
  final _entryFeeController = TextEditingController();
  final _rulesController = TextEditingController();

  DateTime? _startDateTime;
  DateTime? _registrationDeadline;
  File? _bannerImage;
  bool _isSaving = false;

  final List<_RoundEntry> _rounds = [
    _RoundEntry(name: 'Round 1', description: ''),
  ];

  bool get isEdit => widget.tournamentId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _maxParticipantsController.dispose();
    _entryFeeController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _pickBannerImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _bannerImage = File(picked.path));
  }

  Future<void> _pickDateTime({required bool isDeadline}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryBrand),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryBrand),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isDeadline) {
        _registrationDeadline = dt;
      } else {
        _startDateTime = dt;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDateTime == null) {
      showErrorSnackbar(context, 'Please set a start date and time.');
      return;
    }
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulated API call
    setState(() => _isSaving = false);
    if (mounted) {
      showSuccessSnackbar(
          context, isEdit ? 'Tournament updated!' : 'Tournament created!');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreamScaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Tournament' : 'New Tournament',
            style: AppTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Banner image ─────────────────────────────────────────
            _SectionLabel('Tournament Banner'),
            const SizedBox(height: 8),
            ImageUploadWidget(
              currentImage: _bannerImage,
              onPickImage: _pickBannerImage,
            ),
            const SizedBox(height: 20),

            // ── Basic info ───────────────────────────────────────────
            _SectionLabel('Basic Information'),
            const SizedBox(height: 12),
            _Field(
              controller: _nameController,
              label: 'Tournament Name',
              hint: 'e.g. The Grand Summer League',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _descController,
              label: 'Description',
              hint: 'Brief description for participants',
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // ── Date / time ──────────────────────────────────────────
            _SectionLabel('Schedule'),
            const SizedBox(height: 12),
            _DateTimePicker(
              label: 'Start Date & Time',
              value: _startDateTime,
              onTap: () => _pickDateTime(isDeadline: false),
            ),
            const SizedBox(height: 12),
            _DateTimePicker(
              label: 'Registration Deadline',
              value: _registrationDeadline,
              onTap: () => _pickDateTime(isDeadline: true),
              optional: true,
            ),
            const SizedBox(height: 20),

            // ── Capacity & fee ───────────────────────────────────────
            _SectionLabel('Capacity & Entry Fee'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _maxParticipantsController,
                    label: 'Max Participants',
                    hint: '500',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Required',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    controller: _entryFeeController,
                    label: 'Entry Fee (₹)',
                    hint: '200',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) >= 0 ? null : 'Required',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Rules ────────────────────────────────────────────────
            _SectionLabel('Rules'),
            const SizedBox(height: 12),
            _Field(
              controller: _rulesController,
              label: 'Rules & Format',
              hint:
                  'Describe the tournament rules, format, and any special conditions...',
              maxLines: 6,
            ),
            const SizedBox(height: 20),

            // ── Rounds ───────────────────────────────────────────────
            _SectionLabel('Rounds'),
            const SizedBox(height: 12),
            ..._rounds.asMap().entries.map((entry) => RoundEditorCard(
                  index: entry.key,
                  round: entry.value,
                  onDelete: _rounds.length > 1
                      ? () => setState(() => _rounds.removeAt(entry.key))
                      : null,
                  onChanged: (updated) =>
                      setState(() => _rounds[entry.key] = updated),
                )),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() =>
                  _rounds.add(_RoundEntry(name: 'Round ${_rounds.length + 1}'))),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Round'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46)),
            ),
            const SizedBox(height: 28),

            // ── Save ─────────────────────────────────────────────────
            GoldButton(
              label: isEdit ? 'Save Changes' : 'Create Tournament',
              onPressed: _save,
              isLoading: _isSaving,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── ImageUploadWidget ────────────────────────────────────────────────────────
class ImageUploadWidget extends StatelessWidget {
  final File? currentImage;
  final VoidCallback onPickImage;

  const ImageUploadWidget(
      {super.key, this.currentImage, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickImage,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppTheme.cardRadius,
          border: Border.all(
              color: AppColors.primaryBrand.withOpacity(0.4),
              style: BorderStyle.solid,
              width: 1.5),
        ),
        child: currentImage != null
            ? ClipRRect(
                borderRadius: AppTheme.cardRadius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(currentImage!, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.primaryBrand, size: 40),
                  const SizedBox(height: 8),
                  Text('Tap to add banner image',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.primaryBrand)),
                  Text('Recommended: 1200×400px',
                      style: AppTypography.caption),
                ],
              ),
      ),
    );
  }
}

// ─── RoundEditorCard ─────────────────────────────────────────────────────────
class _RoundEntry {
  String name;
  String description;
  DateTime? scheduledAt;
  int maxParticipants;

  _RoundEntry({
    required this.name,
    this.description = '',
    this.scheduledAt,
    this.maxParticipants = 100,
  });
}

class RoundEditorCard extends StatefulWidget {
  final int index;
  final _RoundEntry round;
  final VoidCallback? onDelete;
  final ValueChanged<_RoundEntry> onChanged;

  const RoundEditorCard({
    super.key,
    required this.index,
    required this.round,
    this.onDelete,
    required this.onChanged,
  });

  @override
  State<RoundEditorCard> createState() => _RoundEditorCardState();
}

class _RoundEditorCardState extends State<RoundEditorCard> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.round.name);
    _descCtrl = TextEditingController(text: widget.round.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryBrand.withOpacity(0.15),
                child: Text('${widget.index + 1}',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.primaryBrand)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Round ${widget.index + 1}',
                    style: AppTypography.labelLarge),
              ),
              if (widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 20),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Round name',
              hintText: 'e.g. Quarterfinals',
            ),
            onChanged: (v) {
              widget.round.name = v;
              widget.onChanged(widget.round);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Details about this round...',
            ),
            maxLines: 2,
            onChanged: (v) {
              widget.round.description = v;
              widget.onChanged(widget.round);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.headlineSmall);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final bool optional;

  const _DateTimePicker({
    required this.label,
    this.value,
    required this.onTap,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    final display = value != null
        ? '${value!.day}/${value!.month}/${value!.year}  ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
        : optional
            ? 'Not set (optional)'
            : 'Tap to set';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppTheme.chipRadius,
          border: Border.all(
              color: value != null
                  ? AppColors.primaryBrand
                  : AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: value != null
                    ? AppColors.primaryBrand
                    : AppColors.textSecondary,
                size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(display,
                      style: AppTypography.bodyMedium.copyWith(
                          color: value != null
                              ? AppColors.textPrimary
                              : AppColors.eliminated)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
