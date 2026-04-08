import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_choice_chip.dart';
import '../widgets/app_surface.dart';
import '../widgets/brand_logo.dart';

enum _AuthView {
  signIn,
  signUp,
  forgotPassword;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  _AuthView _view = _AuthView.signIn;
  String? _infoMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setView(_AuthView view) {
    FocusScope.of(context).unfocus();
    widget.controller.clearAuthError();
    setState(() {
      _view = view;
      _infoMessage = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    widget.controller.clearAuthError();
    setState(() => _infoMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    switch (_view) {
      case _AuthView.signIn:
        await widget.controller.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        break;
      case _AuthView.signUp:
        try {
          final response = await widget.controller.register(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          if (!mounted) {
            return;
          }
          setState(() {
            _infoMessage = response.message;
            _view = _AuthView.signIn;
            _passwordController.clear();
            _confirmPasswordController.clear();
          });
        } on ApiException {
          return;
        }
        break;
      case _AuthView.forgotPassword:
        try {
          final response = await widget.controller.requestPasswordReset(
            email: _emailController.text.trim(),
          );
          if (!mounted) {
            return;
          }
          setState(() {
            _infoMessage = response.message;
            _view = _AuthView.signIn;
            _passwordController.clear();
            _confirmPasswordController.clear();
          });
        } on ApiException {
          return;
        }
        break;
    }
  }

  String get _title {
    switch (_view) {
      case _AuthView.signIn:
        return 'Battery Pack Mobile';
      case _AuthView.signUp:
        return 'Create your account';
      case _AuthView.forgotPassword:
        return 'Reset your password';
    }
  }

  String get _subtitle {
    switch (_view) {
      case _AuthView.signIn:
        return 'Sign in to monitor packs, cell telemetry, and alert activity from your phone.';
      case _AuthView.signUp:
        return 'Register a new account. After registration, check your email verification before signing in.';
      case _AuthView.forgotPassword:
        return 'Request a password reset email for your account.';
    }
  }

  String get _submitLabel {
    switch (_view) {
      case _AuthView.signIn:
        return 'Sign in';
      case _AuthView.signUp:
        return 'Create account';
      case _AuthView.forgotPassword:
        return 'Send reset link';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppSurface(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: BrandLogo(
                                  width: 188,
                                  height: 88,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                _title,
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _subtitle,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  AppChoiceChip(
                                    label: 'Sign in',
                                    selected: _view == _AuthView.signIn,
                                    onTap: () => _setView(_AuthView.signIn),
                                    icon: Icons.login_rounded,
                                  ),
                                  AppChoiceChip(
                                    label: 'Sign up',
                                    selected: _view == _AuthView.signUp,
                                    onTap: () => _setView(_AuthView.signUp),
                                    icon: Icons.person_add_alt_1_rounded,
                                  ),
                                  AppChoiceChip(
                                    label: 'Forgot password',
                                    selected: _view == _AuthView.forgotPassword,
                                    onTap: () =>
                                        _setView(_AuthView.forgotPassword),
                                    icon: Icons.lock_reset_rounded,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (_view == _AuthView.signUp) ...[
                                TextFormField(
                                  controller: _fullNameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Full name',
                                    hintText: 'Your full name',
                                  ),
                                  validator: (value) {
                                    if (_view != _AuthView.signUp) {
                                      return null;
                                    }
                                    if ((value ?? '').trim().isEmpty) {
                                      return 'Enter your full name.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'you@example.com',
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Enter your email.';
                                  }
                                  if (!text.contains('@')) {
                                    return 'Use a valid email.';
                                  }
                                  return null;
                                },
                              ),
                              if (_view != _AuthView.forgotPassword) ...[
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_view == _AuthView.forgotPassword) {
                                      return null;
                                    }
                                    if ((value ?? '').isEmpty) {
                                      return 'Enter your password.';
                                    }
                                    if (_view == _AuthView.signUp &&
                                        (value?.length ?? 0) < 6) {
                                      return 'Use at least 6 characters.';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                              ],
                              if (_view == _AuthView.signUp) ...[
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm password',
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      ),
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_view != _AuthView.signUp) {
                                      return null;
                                    }
                                    if ((value ?? '').isEmpty) {
                                      return 'Confirm your password.';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match.';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                              ],
                              if (_infoMessage != null) ...[
                                const SizedBox(height: 14),
                                _MessageBanner(
                                  color: AppColors.success,
                                  message: _infoMessage!,
                                ),
                              ],
                              if (widget.controller.authError != null) ...[
                                const SizedBox(height: 14),
                                _MessageBanner(
                                  color: AppColors.danger,
                                  message: widget.controller.authError!,
                                ),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: widget.controller.authBusy
                                      ? null
                                      : _submit,
                                  icon: widget.controller.authBusy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          _view == _AuthView.forgotPassword
                                              ? Icons.mail_outline_rounded
                                              : _view == _AuthView.signUp
                                                  ? Icons
                                                      .person_add_alt_1_rounded
                                                  : Icons.login_rounded,
                                        ),
                                  label: Text(
                                    widget.controller.authBusy
                                        ? 'Please wait...'
                                        : _submitLabel,
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.sand,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Backend target',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText(
                                      widget.controller.baseUrl,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.color,
    required this.message,
  });

  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: color),
      ),
    );
  }
}
