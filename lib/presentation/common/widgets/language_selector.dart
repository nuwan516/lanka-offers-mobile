import 'package:flutter/material.dart';
import '../../../core/services/language_service.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../app.dart';

class LanguageSelectorDialog extends StatefulWidget {
  const LanguageSelectorDialog({super.key});

  @override
  State<LanguageSelectorDialog> createState() => _LanguageSelectorDialogState();
}

class _LanguageSelectorDialogState extends State<LanguageSelectorDialog> {
  final LanguageService _languageService = getIt<LanguageService>();
  late Locale _selectedLocale;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final currentLocale = await _languageService.getSavedLocale();
    setState(() {
      _selectedLocale = currentLocale;
    });
  }

  Future<void> _selectLanguage(Locale locale) async {
    await _languageService.setLocale(locale);
    if (!mounted) return;
    setState(() {
      _selectedLocale = locale;
    });

    // Change language in app
    context.changeLanguage(locale);

    // Close dialog
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.language,
        style: AppTextStyles.h3,
      ),
      content: RadioGroup<Locale>(
        groupValue: _selectedLocale,
        onChanged: (Locale? value) {
          if (value != null) {
            _selectLanguage(value);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              LanguageService.supportedLocales.map((locale) {
                final isSelected =
                    _selectedLocale.languageCode == locale.languageCode;
                return RadioListTile<Locale>(
                  title: Row(
                    children: [
                      Text(
                        _languageService.getLanguageName(locale.languageCode),
                        style: AppTextStyles.body1Medium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _languageService.getLanguageNativeName(
                          locale.languageCode,
                        ),
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  value: locale,
                  activeColor: AppColors.primary,
                  selected: isSelected,
                );
              }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: AppTextStyles.body1Medium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
