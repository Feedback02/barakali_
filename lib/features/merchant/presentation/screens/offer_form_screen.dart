import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:barakali/core/constants/app_constants.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/models/dietary.dart';
import 'package:barakali/core/widgets/barakali_button.dart';
import 'package:barakali/core/widgets/barakali_image.dart';
import 'package:barakali/core/widgets/barakali_input.dart';
import '../../domain/models/offer.dart';
import '../../providers/offer_providers.dart';

/// How an [OfferFormScreen] behaves on submit.
enum OfferFormMode {
  /// New offer from a blank form.
  create,

  /// Edit an existing offer in place ([OfferFormScreen.source] required).
  edit,

  /// New offer pre-filled from a past one ("repeat"); pickup window is cleared.
  duplicate,
}

class OfferFormScreen extends ConsumerStatefulWidget {
  const OfferFormScreen({
    super.key,
    this.mode = OfferFormMode.create,
    this.source,
  }) : assert(
         mode == OfferFormMode.create || source != null,
         'edit/duplicate require a source offer',
       );

  final OfferFormMode mode;
  final Offer? source;

  @override
  ConsumerState<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends ConsumerState<OfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();

  OfferCategory _category = OfferCategory.meal;
  final Set<DietaryOption> _dietaryTags = {};
  int _quantity = 1;
  DateTime? _pickupStart;
  DateTime? _pickupEnd;
  Uint8List? _imageBytes;
  String? _existingImageUrl;

  bool get _isEdit => widget.mode == OfferFormMode.edit;

  @override
  void initState() {
    super.initState();
    final source = widget.source;
    if (source != null) {
      _titleController.text = source.title;
      _descriptionController.text = source.description ?? '';
      _originalPriceController.text = source.originalPrice.toString();
      _sellingPriceController.text = source.discountedPrice.toString();
      _category = source.category;
      _dietaryTags.addAll(source.dietaryOptions);
      _quantity = source.quantityTotal;
      _existingImageUrl = source.imageUrl;
      // Duplicate keeps the past pickup window cleared (it would be in the
      // past); edit carries it over so the merchant can tweak it.
      if (_isEdit) {
        _pickupStart = source.pickupStart;
        _pickupEnd = source.pickupEnd;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  void _showImageSourceSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(l10n.imageSourceCamera),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l10n.imageSourceGallery),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final base = (isStart ? _pickupStart : _pickupEnd) ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 7)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;
    final composed = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _pickupStart = composed;
      } else {
        _pickupEnd = composed;
      }
    });
  }

  Future<void> _submit({required bool publish}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    if (!_formKey.currentState!.validate()) return;

    final original = int.parse(_originalPriceController.text.trim());
    final selling = int.parse(_sellingPriceController.text.trim());
    if (selling >= original) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.offerValidationPriceOrder)),
      );
      return;
    }
    if (_pickupStart == null || _pickupEnd == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.offerPickupWindowRequired)),
      );
      return;
    }
    final start = _pickupStart!;
    final end = _pickupEnd!;
    if (!end.isAfter(start)) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.offerValidationPickupOrder)),
      );
      return;
    }
    if (!end.isAfter(DateTime.now())) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.offerPickupInPast)));
      return;
    }

    final notifier = ref.read(offerFormProvider.notifier);
    if (_isEdit) {
      await notifier.submitUpdate(
        offerId: widget.source!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        originalPrice: original,
        discountedPrice: selling,
        quantity: _quantity,
        pickupStart: start,
        pickupEnd: end,
        imageBytes: _imageBytes,
        existingImageUrl: _existingImageUrl,
        dietaryTags: _dietaryTags.map((o) => o.wire).toList(),
        publish: publish,
      );
    } else {
      await notifier.submitCreate(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        originalPrice: original,
        discountedPrice: selling,
        quantity: _quantity,
        pickupStart: start,
        pickupEnd: end,
        imageBytes: _imageBytes,
        existingImageUrl: _existingImageUrl,
        dietaryTags: _dietaryTags.map((o) => o.wire).toList(),
        publish: publish,
      );
    }
    if (!mounted) return;
    if (ref.read(offerFormProvider).hasError) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.offerCreateError)));
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? l10n.offerUpdatedSuccess : l10n.offerCreatedSuccess,
          ),
        ),
      );
      router.go('/merchant/dashboard');
    }
  }

  String _categoryLabel(AppLocalizations l10n, OfferCategory c) {
    return switch (c) {
      OfferCategory.meal => l10n.offerCategoryMeal,
      OfferCategory.bakery => l10n.offerCategoryBakery,
      OfferCategory.grocery => l10n.offerCategoryGrocery,
      OfferCategory.mixed => l10n.offerCategoryMixed,
      OfferCategory.other => l10n.offerCategoryOther,
    };
  }

  String? _priceValidator(String? v, AppLocalizations l10n) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n <= 0) return l10n.offerPriceInvalid;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(offerFormProvider);

    final original = int.tryParse(_originalPriceController.text.trim());
    final selling = int.tryParse(_sellingPriceController.text.trim());
    final savings = (original != null && selling != null && selling < original)
        ? (100 - (selling * 100 / original)).round()
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editOfferTitle : l10n.createOfferTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.mode == OfferFormMode.duplicate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    l10n.offerDuplicatePickupHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              _PhotoPicker(
                bytes: _imageBytes,
                existingUrl: _existingImageUrl,
                onTap: _showImageSourceSheet,
                addLabel: (_imageBytes == null && _existingImageUrl == null)
                    ? l10n.offerPhotoAdd
                    : l10n.offerPhotoChange,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<OfferCategory>(
                initialValue: _category,
                decoration: InputDecoration(labelText: l10n.offerCategoryLabel),
                items: [
                  for (final c in OfferCategory.values)
                    DropdownMenuItem(
                      value: c,
                      child: Text(_categoryLabel(l10n, c)),
                    ),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.offerDietaryLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in DietaryOption.offerTags)
                    FilterChip(
                      avatar: Icon(tag.icon, size: 18),
                      label: Text(tag.label(l10n)),
                      selected: _dietaryTags.contains(tag),
                      onSelected: (on) => setState(() {
                        if (on) {
                          _dietaryTags.add(tag);
                        } else {
                          _dietaryTags.remove(tag);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              BarakaliInput(
                controller: _titleController,
                label: l10n.offerTitleLabel,
                hint: l10n.offerTitleHint,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              BarakaliInput(
                controller: _descriptionController,
                label: l10n.offerDescriptionLabel,
                hint: l10n.offerDescriptionHint,
              ),
              const SizedBox(height: 16),
              BarakaliInput(
                controller: _originalPriceController,
                label: l10n.offerOriginalPriceLabel,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) => _priceValidator(v, l10n),
              ),
              const SizedBox(height: 16),
              BarakaliInput(
                controller: _sellingPriceController,
                label: l10n.offerSellingPriceLabel,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) => _priceValidator(v, l10n),
              ),
              if (savings != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.offerSavingsPercent(savings),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                l10n.offerQuantityLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _QuantityStepper(
                value: _quantity,
                onChanged: (v) => setState(() => _quantity = v),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.offerPickupWindowLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _DateTimeField(
                label: l10n.offerPickupStart,
                value: _pickupStart,
                onTap: () => _pickDateTime(isStart: true),
              ),
              const SizedBox(height: 12),
              _DateTimeField(
                label: l10n.offerPickupEnd,
                value: _pickupEnd,
                onTap: () => _pickDateTime(isStart: false),
              ),
              const SizedBox(height: 24),
              BarakaliButton(
                label: l10n.offerPublish,
                onPressed: () => _submit(publish: true),
                isLoading: state.isLoading,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: state.isLoading
                    ? null
                    : () => _submit(publish: false),
                child: Text(l10n.offerSaveDraft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.bytes,
    required this.existingUrl,
    required this.onTap,
    required this.addLabel,
  });

  final Uint8List? bytes;
  final String? existingUrl;
  final VoidCallback onTap;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppConstants.borderRadius);
    final hasImage = bytes != null || (existingUrl != null);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: !hasImage
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(addLabel),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (bytes != null)
                    Image.memory(bytes!, fit: BoxFit.cover)
                  else
                    BarakaliImage(
                      url: existingUrl,
                      width: double.infinity,
                      height: 180,
                      borderRadius: 0,
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Chip(label: Text(addLabel)),
                  ),
                ],
              ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.value, required this.onChanged});

  static const int _max = 50;

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('$value', style: Theme.of(context).textTheme.titleLarge),
        ),
        IconButton.filledTonal(
          onPressed: value < _max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mat = MaterialLocalizations.of(context);
    final text = value == null
        ? '-'
        : '${mat.formatMediumDate(value!)}  '
              '${TimeOfDay.fromDateTime(value!).format(context)}';
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.event_rounded),
        ),
        child: Text(text),
      ),
    );
  }
}
