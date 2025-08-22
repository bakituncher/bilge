// lib/features/home/screens/library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bilge_ai/data/models/test_model.dart';
import 'package:bilge_ai/data/providers/firestore_providers.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsync = ref.watch(testsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Performans Arşivi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.cardColor.withOpacity(0.8),
            ],
          ),
        ),
        child: testsAsync.when(
          data: (tests) {
            if (tests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 80, color: AppTheme.secondaryTextColor),
                    const SizedBox(height: 16),
                    Text('Arşivin Henüz Boş', style: textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        'Her deneme, gelecekteki başarın için bir kanıtıdır. İlk kanıtı arşive ekle.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home/add-test'),
                      child: const Text("İlk Kaydı Ekle"),
                    )
                  ],
                ).animate().fadeIn(duration: 800.ms),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: tests.length,
              itemBuilder: (context, index) {
                final test = tests[index];
                return _TriumphPlaqueCard(test: test)
                    .animate()
                    .fadeIn(delay: (100 * (index % 10)).ms, duration: 500.ms)
                    .slideY(begin: 0.5, curve: Curves.easeOutCubic);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
          error: (e, s) => Center(child: Text('Arşiv yüklenemedi: ${e.toString()}')),
        ),
      ),
    );
  }
}

class _TriumphPlaqueCard extends StatefulWidget {
  final TestModel test;
  const _TriumphPlaqueCard({required this.test});

  @override
  State<_TriumphPlaqueCard> createState() => _TriumphPlaqueCardState();
}

class _TriumphPlaqueCardState extends State<_TriumphPlaqueCard> {
  bool _isHovered = false;

  double _calculateWisdomScore() {
    return widget.test.wisdomScore;
  }

  double _calculateAccuracy() {
    final attemptedQuestions = widget.test.totalCorrect + widget.test.totalWrong;
    if (attemptedQuestions == 0) return 0.0;
    return (widget.test.totalCorrect / attemptedQuestions) * 100;
  }

  Color _getTierColor(double score) {
    if (score > 85) return const Color(0xFF40E0D0); // Platin
    if (score > 70) return const Color(0xFFFFD700); // Altın
    if (score > 50) return const Color(0xFFC0C0C0); // Gümüş
    return const Color(0xFFCD7F32); // Bronz
  }

  @override
  Widget build(BuildContext context) {
    final wisdomScore = _calculateWisdomScore();
    final accuracy = _calculateAccuracy();
    final tierColor = _getTierColor(wisdomScore);
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push('/home/test-result-summary', extra: widget.test),
        child: AnimatedContainer(
          duration: 300.ms,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? tierColor.withOpacity(0.5)
                    : Colors.black.withOpacity(0.6),
                blurRadius: _isHovered ? 25 : 10,
              )
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppTheme.cardColor,
              gradient: LinearGradient(
                colors: [
                  AppTheme.lightSurfaceColor.withOpacity(0.1),
                  AppTheme.cardColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppTheme.lightSurfaceColor.withOpacity(0.3)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.test.testName,
                          style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            children: [
                              Text(
                                widget.test.sectionName,
                                style: textTheme.bodySmall?.copyWith(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "  |  ${DateFormat.yMd('tr').format(widget.test.date)}",
                                style: textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 160,
                    child: Center(
                      child: Animate(
                        target: _isHovered ? 1 : 0,
                        effects: [
                          ScaleEffect(duration: 300.ms, curve: Curves.easeOutBack, begin: const Offset(1,1), end: const Offset(1.05, 1.05))
                        ],
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.test.totalNet.toStringAsFixed(2),
                              style: textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            Text("NET", style: textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryTextColor)),
                            const SizedBox(height: 12),
                            Text(
                              "${wisdomScore.toInt()} BP",
                              style: textTheme.titleLarge?.copyWith(
                                color: tierColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Doğruluk", style: textTheme.bodySmall?.copyWith(color: AppTheme.secondaryTextColor)),
                        Text(
                          "%${accuracy.toStringAsFixed(1)}",
                          style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
