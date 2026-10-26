import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n_x.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';

/// Pure validators (unit tested).
class Validators {
  static String? required(String? v, String message) => (v == null || v.trim().isEmpty) ? message : null;

  static bool isEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  static bool isPhone(String v) => RegExp(r'^\+?[0-9\s\-()]{10,18}$').hasMatch(v.trim());

  static bool isStrongEnough(String v) => v.length >= 8;
}

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: Center(
        child: auth.hasError
            ? ErrorView(error: auth.error!, onRetry: () => ref.invalidate(authProvider))
            : Column(mainAxisSize: MainAxisSize.min, children: [
                const JemisLogo(size: 72),
                const SizedBox(height: Space.l),
                Text(context.l.slogan, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: Space.xl),
                const CircularProgressIndicator(),
              ]),
      ),
    );
  }
}

class JemisLogo extends StatelessWidget {
  const JemisLogo({super.key, this.size = 32, this.showName = false});
  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: JemisColors.primaryStrong, borderRadius: BorderRadius.circular(size * 0.3)),
      alignment: Alignment.center,
      child: Text('J', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * 0.6)),
    );
    if (!showName) return Semantics(label: 'JEMIS', child: mark);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      mark,
      const SizedBox(width: Space.s),
      Text('JEMIS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: size * 0.65, color: Theme.of(context).colorScheme.onSurface)),
    ]);
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).login(_id.text.trim(), _pw.text);
      if (mounted && context.canPop()) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(context.l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final l = context.l;
    if (_id.text.trim().isEmpty) {
      setState(() => _error = l.fieldRequired);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(_id.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.resetRequested)));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xl),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Center(child: JemisLogo(size: 56, showName: true)),
              const SizedBox(height: Space.s),
              Center(child: Text(l.slogan)),
              const SizedBox(height: Space.xxl),
              TextFormField(
                controller: _id,
                decoration: InputDecoration(labelText: l.emailOrPhone),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, l.fieldRequired),
              ),
              const SizedBox(height: Space.m),
              TextFormField(
                controller: _pw,
                decoration: InputDecoration(labelText: l.password),
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                validator: (v) => Validators.required(v, l.fieldRequired),
              ),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: Space.m), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
              const SizedBox(height: Space.l),
              FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.login)),
              TextButton(onPressed: _reset, child: Text(l.forgotPassword)),
              TextButton(onPressed: () => context.pushReplacement('/register'), child: Text(l.noAccount)),
            ]),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _pw]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l;
    if (!_form.currentState!.validate()) return;
    if (_email.text.trim().isEmpty && _phone.text.trim().isEmpty) {
      setState(() => _error = l.contactRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).register(email: _email.text.trim(), phone: _phone.text.trim(), password: _pw.text, fullName: _name.text.trim());
      if (mounted && context.canPop()) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(context.l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xl),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextFormField(controller: _name, decoration: InputDecoration(labelText: l.fullName), textInputAction: TextInputAction.next, validator: (v) => Validators.required(v, l.fieldRequired)),
              const SizedBox(height: Space.m),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: l.email),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty || Validators.isEmail(v)) ? null : l.invalidEmail,
              ),
              const SizedBox(height: Space.m),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Телефон / Phone', hintText: '+7 700 000 00 00'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty || Validators.isPhone(v)) ? null : l.invalidPhone,
              ),
              const SizedBox(height: Space.m),
              TextFormField(
                controller: _pw,
                decoration: InputDecoration(labelText: l.password),
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => Validators.isStrongEnough(v ?? '') ? null : l.passwordShort,
              ),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: Space.m), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
              const SizedBox(height: Space.l),
              FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.register)),
              TextButton(onPressed: () => context.pushReplacement('/login'), child: Text(l.haveAccount)),
            ]),
          ),
        ),
      ),
    );
  }
}
