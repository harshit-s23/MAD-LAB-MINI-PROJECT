import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result =
        await context.read<AuthProvider>().login(_email.text, _password.text);
    if (!result.success) AppToast.error(result.message ?? 'Login failed');
    // On success the router redirects to /dashboard.
  }

  void _fillDemo() {
    _email.text = AppConstants.demoEmail;
    _password.text = AppConstants.demoPassword;
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthProvider, bool>((a) => a.loading);

    return AuthScaffold(
      emoji: '🌱',
      title: 'Welcome back',
      subtitle: 'Continue your eco journey',
      blobs: const [
        Positioned(
            top: -128, right: -128, child: SoftBlob(color: Color(0x4DBBF7D0))),
        Positioned(
            bottom: -128,
            left: -128,
            child: SoftBlob(color: Color(0x4DD4DBC6))),
      ],
      cardChildren: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledTextField(
                label: 'Email',
                controller: _email,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                fieldKey: const Key('login-email'),
              ),
              const SizedBox(height: 16),
              LabeledTextField(
                label: 'Password',
                controller: _password,
                hint: '••••••••',
                obscure: true,
                validator: Validators.loginPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
                fieldKey: const Key('login-password'),
              ),
              const SizedBox(height: 16),
              EcoButton(
                  label: loading ? '🌿 Signing in...' : 'Sign In',
                  onPressed: loading ? null : _submit),
            ],
          ),
        ),
        const SizedBox(height: 16),
        EcoOutlinedButton(label: 'Use Demo Account', onPressed: _fillDemo),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('New to EcoTask? ', style: AppText.subtitle),
            GestureDetector(
              onTap: () => context.go('/register'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Create account',
                    style: AppText.bodyStyle(14,
                        weight: FontWeight.w600, color: AppColors.forest600)),
              ),
            ),
          ],
        ),
      ],
      below: const _StatsPreview(),
    );
  }
}

/// Static marketing tiles from the original login page.
class _StatsPreview extends StatelessWidget {
  const _StatsPreview();

  static const _items = [
    ('🌍', '2.4M kg', 'CO₂ Saved'),
    ('👥', '12k+', 'Users'),
    ('🏆', '98%', 'Eco Score'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(_items[i].$1, style: const TextStyle(fontSize: 18)),
                  Text(_items[i].$2,
                      style: AppText.bodyStyle(14,
                          weight: FontWeight.w600, color: AppColors.forest800)),
                  Text(_items[i].$3, style: AppText.small),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
