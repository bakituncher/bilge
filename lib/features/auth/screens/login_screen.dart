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

  bool _isLoading = false;
  // ✅ UX GELİŞTİRMESİ: Hata durumunu tutacak bir state
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null; // Her denemede hata mesajını sıfırla
      });

      try {
        await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Başarılı girişten sonra yönlendirme zaten redirect'te halledilecek
      } catch (e) {
        if (mounted) {
          // ✅ UX GELİŞTİRMESİ: Hata mesajını bir state'e ata ve formu yeniden doğrula
          setState(() {
            _errorMessage = e.toString();
            _formKey.currentState?.validate(); // Formu yeniden doğrula
          });
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
                  // ✅ UX GELİŞTİRMESİ: API'den gelen hatayı göster
                  if (_errorMessage != null) {
                    return _errorMessage;
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _errorMessage = null),
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
                  // ✅ UX GELİŞTİRMESİ: API'den gelen hatayı göster
                  if (_errorMessage != null) {
                    return _errorMessage;
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
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