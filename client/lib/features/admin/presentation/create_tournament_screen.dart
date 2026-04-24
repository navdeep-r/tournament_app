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
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';

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
  final List<_ReferralEntry> _referrals = [];

  DateTime? _startDateTime;
  DateTime? _registrationDeadline;
  File? _bannerImage;
  bool _isLoadingExisting = false;

  final List<_RoundEntry> _rounds = [
    _RoundEntry(name: 'Round 1', description: ''),
  ];

  bool get isEdit => widget.tournamentId != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _loadExistingTournament();
    }
  }

  Future<void> _loadExistingTournament() async {
    setState(() => _isLoadingExisting = true);
    try {
      final repo = context.read<AdminBloc>().repo;
      final data = await repo.getTournamentById(widget.tournamentId!);
      if (!mounted) return;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _descController.text = data['description'] ?? '';
        _maxParticipantsController.text = '${data['max_participants'] ?? 500}';
        _entryFeeController.text = '${data['entry_fee_paise'] ?? 0}';
        _rulesController.text = data['rules'] ?? '';
        if (data['starts_at'] != null) {
          _startDateTime = DateTime.tryParse(data['starts_at']);
        }
        if (data['registration_closes_at'] != null) {
          _registrationDeadline = DateTime.tryParse(data['registration_closes_at']);
        }
        final referralRows = (data['referral_codes'] as List<dynamic>?) ?? const [];
        _referrals
          ..clear()
          ..addAll(referralRows.map((item) {
            final row = item as Map<String, dynamic>;
            return _ReferralEntry(
              code: row['code']?.toString() ?? '',
              discountPercent: (row['discount_percent'] as num?)?.toInt() ?? 0,
            );
          }));
        _isLoadingExisting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingExisting = false);
      showErrorSnackbar(context, 'Failed to load tournament: $e');
    }
  }

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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDateTime == null) {
      showErrorSnackbar(context, 'Please set a start date and time.');
      return;
    }
    if (!_startDateTime!.isAfter(DateTime.now())) {
      showErrorSnackbar(context, 'Start time must be in the future.');
      return;
    }
    if (_registrationDeadline != null &&
        !_registrationDeadline!.isBefore(_startDateTime!)) {
      showErrorSnackbar(
        context,
        'Registration deadline must be before start time.',
      );
      return;
    }
    final nonEmptyReferrals = _referrals.where((r) => r.code.trim().isNotEmpty).toList();
    for (final r in nonEmptyReferrals) {
      final code = r.code.trim().toUpperCase();
      final validCode = RegExp(r'^[A-Z0-9_-]{3,20}$').hasMatch(code);
      if (!validCode) {
        showErrorSnackbar(
          context,
          'Referral codes must be 3-20 chars (A-Z, 0-9, _ or -).',
        );
        return;
      }
      if (r.discountPercent < 1 || r.discountPercent > 100) {
        showErrorSnackbar(context, 'Referral discount must be between 1 and 100.');
        return;
      }
    }
    final distinct = nonEmptyReferrals
        .map((r) => r.code.trim().toUpperCase())
        .toSet();
    if (distinct.length != nonEmptyReferrals.length) {
      showErrorSnackbar(context, 'Duplicate referral codes are not allowed.');
      return;
    }

    final referralPayload = _referrals
        .where((r) => r.code.trim().isNotEmpty)
        .map((r) => {
              'code': r.code.trim().toUpperCase(),
              'discount_percent': r.discountPercent,
            })
        .toList();

    final data = {
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'max_participants': int.tryParse(_maxParticipantsController.text.trim()) ?? 500,
      'entry_fee_paise': int.tryParse(_entryFeeController.text.trim()) ?? 0,
      'rules': _rulesController.text.trim(),
      'starts_at': _startDateTime!.toIso8601String(),
    };
    if (referralPayload.isNotEmpty) {
      data['referral_codes'] = referralPayload;
    }
    if (_registrationDeadline != null) {
      data['registration_closes_at'] = _registrationDeadline!.toIso8601String();
    }

    if (isEdit) {
      context.read<AdminBloc>().add(AdminTournamentUpdateRequested(widget.tournamentId!, data));
    } else {
      context.read<AdminBloc>().add(AdminTournamentCreateRequested(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listenWhen: (prev, current) => current is AdminOperationSuccess || current is AdminError,
      listener: (context, state) {
        if (state is AdminOperationSuccess) {
          showSuccessSnackbar(context, state.message);
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/admin');
          }
        } else if (state is AdminError) {
          showErrorSnackbar(context, state.message);
        }
      },
      builder: (context, state) {
        final _isSaving = state is AdminOperationInProgress;
        if (_isLoadingExisting) {
          return CreamScaffold(
            appBar: AppBar(title: Text('Loading...', style: AppTypography.titleLarge)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
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
                  context.go('/admin');
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
                    validator: (v) {
                      final parsed = int.tryParse(v ?? '');
                      if (parsed == null) return 'Required';
                      if (parsed < 2) return 'Must be at least 2';
                      if (parsed > 10000) return 'Cannot exceed 10000';
                      return null;
                    },
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

            // ── Referrals ────────────────────────────────────────────
            _SectionLabel('Referral Codes (Optional)'),
            const SizedBox(height: 8),
            if (_referrals.isEmpty)
              Text('No referral codes added yet.', style: AppTypography.caption),
            ..._referrals.asMap().entries.map((entry) {
              return _ReferralEditorCard(
                key: ValueKey('ref_${entry.key}'),
                index: entry.key,
                referral: entry.value,
                onChanged: (updated) =>
                    setState(() => _referrals[entry.key] = updated),
                onDelete: () => setState(() => _referrals.removeAt(entry.key)),
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _referrals.add(_ReferralEntry())),
              icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Add Referral Code'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
              ),
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
    });
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

class _ReferralEntry {
  String code;
  int discountPercent;

  _ReferralEntry({this.code = '', this.discountPercent = 10});
}

class _ReferralEditorCard extends StatefulWidget {
  final int index;
  final _ReferralEntry referral;
  final ValueChanged<_ReferralEntry> onChanged;
  final VoidCallback onDelete;

  const _ReferralEditorCard({
    super.key,
    required this.index,
    required this.referral,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_ReferralEditorCard> createState() => _ReferralEditorCardState();
}

class _ReferralEditorCardState extends State<_ReferralEditorCard> {
  late TextEditingController _codeCtrl;
  late TextEditingController _discountCtrl;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.referral.code);
    _discountCtrl =
        TextEditingController(text: widget.referral.discountPercent.toString());
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Code',
                hintText: 'e.g. FRIEND10',
                counterText: '',
              ),
              onChanged: (v) {
                widget.referral.code = v.toUpperCase().trim();
                widget.onChanged(widget.referral);
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _discountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Discount %',
                hintText: '10',
              ),
              onChanged: (v) {
                final parsed = int.tryParse(v) ?? 0;
                widget.referral.discountPercent = parsed.clamp(1, 100);
                widget.onChanged(widget.referral);
              },
            ),
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          ),
        ],
      ),
    );
  }
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
