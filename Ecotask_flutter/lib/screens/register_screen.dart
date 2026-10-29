import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_toast.dart';
import '../widgets/eco_background.dart';
import '../widgets/eco_button.dart';
import '../widgets/form_widgets.dart';
import '../widgets/glass_card.dart';
import 'auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result = await context
        .read<AuthProvider>()
        .register(_name.text, _email.text, _password.text);
    if (result.success) {
      AppToast.success('Welcome to EcoTask! 🌱');
    } else {
      AppToast.error(result.message ?? 'Registration failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthProvider, bool>((a) => a.loading);

    return AuthScaffold(
      emoji: '🌍',
      title: 'Join EcoTask',
      subtitle: 'Start tracking your carbon footprint today',
      blobs: const [
        Positioned(
            top: -128, left: -128, child: SoftBlob(color: Color(0x33F4DCA9))),
        Positioned(
            bottom: -128,
            right: -128,
            child: SoftBlob(color: Color(0x4DBBF7D0))),
      ],
      cardChildren: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledTextField(
                label: 'Full Name',
                controller: _name,
                hint: 'Jane Doe',
                validator: Validators.name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                fieldKey: const Key('register-name'),
              ),
              const SizedBox(height: 16),
              LabeledTextField(
                label: 'Email',
                controller: _email,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                fieldKey: const Key('register-email'),
              ),
              const SizedBox(height: 16),
              LabeledTextField(
                label: 'Password',
                controller: _password,
                hint: '••••••••',
                obscure: true,
                validator: Validators.newPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.newPassword],
                fieldKey: const Key('register-password'),
              ),
              const SizedBox(height: 24),
              EcoButton(
                  label: loading ? '🌱 Creating account...' : 'Create Account',
                  onPressed: loading ? null : _submit),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already have an account? ', style: AppText.subtitle),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Sign in',
                    style: AppText.bodyStyle(14,
                        weight: FontWeight.w600, color: AppColors.forest600)),
              ),
            ),
          ],
        ),
      ],
      below: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          '🌿 By joining, you commit to tracking and reducing your environmental impact. Every action counts for our planet.',
          textAlign: TextAlign.center,
          style: AppText.bodyStyle(12, color: AppColors.sage600, height: 1.33),
        ),
      ),
    );
  }
}
