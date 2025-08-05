// lib/features/strategic_planning/screens/command_center_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bilge_ai/core/theme/app_theme.dart';
import 'package:bilge_ai/data/models/user_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// Strateji metnini ayrıştırmak için bir model
class StrategyPhase {
  final String title;
  final String content;

  StrategyPhase({required this.title, required this.content});
}

class CommandCenterScreen extends StatefulWidget {
  final UserModel user;
  const CommandCenterScreen({super.key, required this.user});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  List<StrategyPhase> _phases = [];
  int _openPanelIndex = 0; // Başlangıçta ilk panel açık

  @override
  void initState() {
    super.initState();
    _parseStrategy(widget.user.longTermStrategy);
  }

  // --- YENİ VE DAHA AKILLI AYRIŞTIRICI FONKSİYON ---
  void _parseStrategy(String? strategyText) {
    if (strategyText == null || strategyText.isEmpty) return;

    // Markdown metnini satırlara ayır
    final lines = strategyText.split('\n');
    final List<StrategyPhase> parsedPhases = [];
    StringBuffer contentBuffer = StringBuffer();
    String? currentTitle;

    // REGEX: Başında bir veya daha fazla '#' ve bir boşluk olan satırları bulur.
    // Bu sayede AI, #, ## veya ### kullansa bile başlıkları yakalarız.
    final headerRegex = RegExp(r'^(#+)\s(.*)');

    for (var line in lines) {
      final match = headerRegex.firstMatch(line.trim());

      // Eğer satır bir başlık ise
      if (match != null) {
        if (currentTitle != null) {
          // Önceki bölümü listeye ekle
          parsedPhases.add(StrategyPhase(title: currentTitle, content: contentBuffer.toString().trim()));
        }
        // Yeni bölümü başlat
        currentTitle = match.group(2)?.trim(); // Sadece başlık metnini al
        contentBuffer.clear();
      } else if (currentTitle != null) {
        // Eğer başlık değilse, içeriğe ekle
        contentBuffer.writeln(line);
      }
    }

    // Döngü bittikten sonra kalan son bölümü de ekle
    if (currentTitle != null && contentBuffer.isNotEmpty) {
      parsedPhases.add(StrategyPhase(title: currentTitle, content: contentBuffer.toString().trim()));
    }

    setState(() {
      _phases = parsedPhases;
    });
  }

  IconData _getIconForPhase(String title) {
    if (title.contains("AŞAMA: 1") || title.contains("AŞAMA") && title.contains("1") || title.contains("HAKİMİYET")) {
      return Icons.foundation_rounded;
    } else if (title.contains("AŞAMA: 2") || title.contains("AŞAMA") && title.contains("2") || title.contains("HÜCUM")) {
      return Icons.military_tech_rounded;
    } else if (title.contains("AŞAMA: 3") || title.contains("AŞAMA") && title.contains("3") || title.contains("ZAFER")) {
      return Icons.emoji_events_rounded;
    } else if (title.contains("MOTTO")) {
      return Icons.flag_rounded;
    }
    return Icons.insights_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Komuta Merkezi"),
      ),
      body: _phases.isEmpty
      // --- HATA DURUMU İÇİN YENİ GÖRÜNÜM ---
      // Eğer strateji ayrıştırılamazsa, ham metni gösteririz.
          ? _buildFallbackView(widget.user.longTermStrategy ?? "Strateji metni bulunamadı.")
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Başlığı dinamik olarak ilk bölümden alıyoruz
          if (_phases.isNotEmpty)
            Text(
              _phases.first.title,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
            ),
          const SizedBox(height: 24),
          ExpansionPanelList(
            elevation: 0,
            dividerColor: AppTheme.lightSurfaceColor,
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                // İlk başlığı (motto vb.) her zaman kapalı tut, diğerlerini aç/kapa
                if (index == 0) return;
                _openPanelIndex = isExpanded ? -1 : index;
              });
            },
            children: _phases.skip(1).map<ExpansionPanel>((StrategyPhase phase) {
              int index = _phases.indexOf(phase);
              return ExpansionPanel(
                backgroundColor: _openPanelIndex == index ? AppTheme.cardColor : Colors.transparent,
                canTapOnHeader: true,
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return ListTile(
                    leading: Icon(_getIconForPhase(phase.title), color: AppTheme.secondaryColor),
                    title: Text(
                      phase.title,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  );
                },
                body: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: MarkdownBody(
                    data: phase.content,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 16, height: 1.5),
                      listBullet: const TextStyle(color: AppTheme.textColor, fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
                isExpanded: _openPanelIndex == index,
              );
            }).toList(),
          ),
        ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.1),
      ),
    );
  }

  // Strateji ayrıştırılamazsa gösterilecek yedek widget
  Widget _buildFallbackView(String rawStrategy) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
          const SizedBox(height: 16),
          Text(
            "Strateji Formatı Okunamadı",
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Yapay zeka tarafından oluşturulan stratejinin formatı beklenenden farklı. Ancak endişelenme, ham strateji metnini aşağıda görebilirsin:",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          const Divider(height: 32),
          MarkdownBody(data: rawStrategy),
        ],
      ),
    );
  }
}