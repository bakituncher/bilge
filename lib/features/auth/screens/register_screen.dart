// lib/features/auth/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // DÜZELTME: Ekranın kendi yüklenme durumunu takip etmesi için eklendi.
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // DÜZELTME: Metot 'async' yapıldı ve hata yönetimi eklendi.
  void _submit() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Başarılı olduğunda GoRouter zaten yönlendirecek.
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // DÜZELTME: ref.watch ve ref.listen kaldırıldı, çünkü artık gerekli değiller.
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'BilgeAi\'ye Hoş Geldin!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-posta'),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Lütfen geçerli bir e-posta girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Şifre'),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Şifre Tekrar'),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Şifreler eşleşmiyor.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                // DÜZELTME: Butonun durumu yerel _isLoading değişkenine bağlandı.
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kayıt Ol'),
              ),
              TextButton(
                onPressed: () {
                  // DÜZELTME: GoRouter ile doğru yönlendirme.
                  context.go('/login');
                },
                child: const Text('Zaten bir hesabın var mı? Giriş Yap'),
              )
            ],
          ),
        ),
      ),
    );
  }
}