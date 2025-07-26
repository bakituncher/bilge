// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bilge_ai/features/auth/controller/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // DÜZELTME: Ekranın kendi yüklenme durumunu takip etmesi için eklendi.
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // DÜZELTME: Metot 'async' yapıldı ve hata yönetimi eklendi.
  void _submit() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await ref.read(authControllerProvider.notifier).signIn(
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
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tekrar Hoş Geldin!',
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
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifrenizi girin.';
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
                    : const Text('Giriş Yap'),
              ),
              TextButton(
                onPressed: () {
                  context.go('/register');
                },
                child: const Text('Hesabın yok mu? Kayıt Ol'),
              )
            ],
          ),
        ),
      ),
    );
  }
}