import 'package:flutter/material.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barakali/core/widgets/barakali_button.dart';
import 'package:barakali/core/widgets/barakali_input.dart';
import 'package:barakali/features/auth/presentation/utils/phone_formatter.dart';
import '../../domain/models/merchant.dart';
import '../../providers/merchant_providers.dart';

class MerchantRegistrationScreen extends ConsumerStatefulWidget {
  const MerchantRegistrationScreen({super.key});

  @override
  ConsumerState<MerchantRegistrationScreen> createState() =>
      _MerchantRegistrationScreenState();
}

class _MerchantRegistrationScreenState
    extends ConsumerState<MerchantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  MerchantCategory _category = MerchantCategory.restaurant;
  bool _isHalal = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final router = GoRouter.of(context);
    await ref
        .read(merchantApplicationProvider.notifier)
        .submit(
          businessName: _nameController.text.trim(),
          category: _category.value,
          address: _addressController.text.trim(),
          phone: toE164(_phoneController.text),
          isHalal: _isHalal,
          description: _descriptionController.text.trim(),
        );
    if (!mounted) return;
    if (!ref.read(merchantApplicationProvider).hasError) {
      router.go('/merchant/dashboard');
    }
  }

  String _categoryLabel(AppLocalizations l10n, MerchantCategory c) {
    return switch (c) {
      MerchantCategory.restaurant => l10n.merchantCategoryRestaurant,
      MerchantCategory.cafe => l10n.merchantCategoryCafe,
      MerchantCategory.bakery => l10n.merchantCategoryBakery,
      MerchantCategory.supermarket => l10n.merchantCategorySupermarket,
      MerchantCategory.other => l10n.merchantCategoryOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(merchantApplicationProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.merchantRegisterTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.merchantRegisterSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              BarakaliInput(
                controller: _nameController,
                label: l10n.merchantBusinessNameLabel,
                hint: l10n.merchantBusinessNameHint,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MerchantCategory>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: l10n.merchantCategoryLabel,
                ),
                items: [
                  for (final c in MerchantCategory.values)
                    DropdownMenuItem(
                      value: c,
                      child: Text(_categoryLabel(l10n, c)),
                    ),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 16),
              BarakaliInput(
                controller: _addressController,
                label: l10n.merchantAddressLabel,
                hint: l10n.merchantAddressHint,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              BarakaliInput(
                controller: _phoneController,
                label: l10n.merchantPhoneLabel,
                prefixText: '+998 ',
                hint: l10n.authPhoneHint,
                keyboardType: TextInputType.phone,
                inputFormatters: [UzbekPhoneFormatter()],
                validator: (v) =>
                    isValidUzbekPhone(v ?? '') ? null : l10n.authPhoneInvalid,
              ),
              const SizedBox(height: 16),
              BarakaliInput(
                controller: _descriptionController,
                label: l10n.merchantDescriptionLabel,
                hint: l10n.merchantDescriptionHint,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _isHalal,
                onChanged: (v) => setState(() => _isHalal = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.merchantHalalToggleLabel),
                subtitle: Text(l10n.merchantHalalToggleHint),
              ),
              const SizedBox(height: 24),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    l10n.authErrorGeneric,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              BarakaliButton(
                label: l10n.merchantSubmitApplication,
                onPressed: _onSubmit,
                isLoading: state.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
