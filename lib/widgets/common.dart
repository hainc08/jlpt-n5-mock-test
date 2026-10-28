import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../theme.dart';

/// Thẻ nền trắng, viền mảnh (Level 1).
class ZenCard extends StatelessWidget {
  const ZenCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.onTap, this.color, this.borderColor});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Zen.surface,
        borderRadius: BorderRadius.circular(Zen.radiusCard),
        border: Border.all(color: borderColor ?? Zen.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(Zen.radiusCard), onTap: onTap, child: card),
    );
  }
}

/// Nhãn nhỏ bo góc 12px.
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color = Zen.ink2, this.filled = false, this.icon});

  final String text;
  final Color color;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
        Text(text, style: Zen.labelSm.copyWith(color: fg, locale: Zen.jaLocale)),
      ]),
    );
  }
}

class N5Badge extends StatelessWidget {
  const N5Badge({super.key});

  @override
  Widget build(BuildContext context) => const Tag('N5', color: Zen.sage, filled: true);
}

/// Văn bản tiếng Nhật có hỗ trợ: {gạch chân}, ［1］ ô trống, ★.
class JpText extends StatelessWidget {
  const JpText(this.text, {super.key, this.size = 20, this.weight = FontWeight.w500, this.color = Zen.ink, this.textAlign});

  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final TextAlign? textAlign;

  static final _re = RegExp(r'\{([^}]*)\}|［(\d)］|★');

  @override
  Widget build(BuildContext context) {
    final base = Zen.ja(size, weight: weight, color: color);
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _re.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      if (m.group(1) != null) {
        spans.add(TextSpan(
          text: m.group(1),
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Zen.primary,
            decorationThickness: 2,
          ),
        ));
      } else if (m.group(2) != null) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: Zen.primary.withValues(alpha: 0.08),
              border: Border.all(color: Zen.primary),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(m.group(2)!, style: Zen.ja(size * 0.75, weight: FontWeight.w700, color: Zen.primary, height: 1.3)),
          ),
        ));
      } else {
        spans.add(const TextSpan(text: '★', style: TextStyle(color: Zen.primary, fontWeight: FontWeight.w700)));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(style: base, children: spans), textAlign: textAlign);
  }
}

enum OptionState { normal, selected, correct, wrong }

/// Lựa chọn đáp án 1–4.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.number,
    required this.text,
    this.state = OptionState.normal,
    this.onTap,
    this.note,
  });

  final int number;
  final String? text;
  final OptionState state;
  final VoidCallback? onTap;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final (Color border, Color bg, Color badgeBg, Color badgeFg, double width) = switch (state) {
      OptionState.selected => (Zen.primary, Zen.primary.withValues(alpha: 0.04), Zen.primary, Colors.white, 1.5),
      OptionState.correct => (Zen.green, Zen.green.withValues(alpha: 0.06), Zen.green, Colors.white, 1.5),
      OptionState.wrong => (Zen.primary, Zen.primary.withValues(alpha: 0.06), Zen.primary, Colors.white, 1.5),
      OptionState.normal => (Zen.border, Zen.surface, Zen.subtle, Zen.ink, 1.0),
    };
    final trailing = switch (state) {
      OptionState.correct => const Icon(Icons.check_circle, color: Zen.green, size: 22),
      OptionState.wrong => const Icon(Icons.cancel, color: Zen.primary, size: 22),
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Zen.radiusControl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(Zen.radiusControl),
              border: Border.all(color: border, width: width),
              boxShadow: state == OptionState.selected
                  ? [BoxShadow(color: Zen.primary.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Row(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
                child: Text('$number', style: Zen.label.copyWith(color: badgeFg)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (text != null)
                    JpText(text!, size: 17)
                  else
                    Text('Lựa chọn $number (nghe)', style: Zen.body.copyWith(color: Zen.ink2)),
                  if (note != null) Text(note!, style: Zen.small),
                ]),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Đồng hồ đếm ngược dạng viên thuốc.
class TimerPill extends StatelessWidget {
  const TimerPill({super.key, required this.text, this.warn = false});

  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final c = warn ? Zen.primary : Zen.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: warn ? Zen.primary.withValues(alpha: 0.08) : Zen.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: Zen.ink.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_outlined, size: 16, color: c),
        const SizedBox(width: 4),
        Text(text, style: Zen.label.copyWith(color: c, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

/// Bảng thông tin (情報検索).
class InfoTableView extends StatelessWidget {
  const InfoTableView(this.table, {super.key});

  final InfoTable table;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Zen.surface,
        borderRadius: BorderRadius.circular(Zen.radiusCard),
        border: Border.all(color: Zen.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: Zen.subtle,
          padding: const EdgeInsets.all(12),
          child: Text(table.title, style: Zen.ja(15, weight: FontWeight.w700), textAlign: TextAlign.center),
        ),
        Table(
          border: const TableBorder(horizontalInside: BorderSide(color: Zen.border)),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFFAF8F5)),
              children: [for (final h in table.headers) _cell(h, header: true)],
            ),
            for (final r in table.rows) TableRow(children: [for (final c in r) _cell(c)]),
          ],
        ),
      ]),
    );
  }

  Widget _cell(String s, {bool header = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(s, style: Zen.ja(13, weight: header ? FontWeight.w700 : FontWeight.w400, height: 1.4)),
      );
}

/// Khung đoạn văn đọc hiểu.
class PassageView extends StatelessWidget {
  const PassageView(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF8),
        borderRadius: BorderRadius.circular(Zen.radiusCard),
        border: Border.all(color: Zen.border),
      ),
      child: JpText(text, size: 16, weight: FontWeight.w400),
    );
  }
}

/// Thanh phát bài nghe (聴解).
class AudioBar extends StatelessWidget {
  const AudioBar({super.key, required this.playKey, required this.script, this.readOptions, this.maxPlays});

  final String playKey;
  final List<ScriptLine> script;
  final List<String>? readOptions;
  final int? maxPlays;

  @override
  Widget build(BuildContext context) {
    final player = AppScope.of(context).player;
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final mine = player.playingKey == playKey;
        final playing = mine && player.playing;
        final plays = player.playCounts[playKey] ?? 0;
        final limitReached = maxPlays != null && plays >= maxPlays! && !playing;
        final progress = mine && player.totalLines > 0 ? (player.currentLine.clamp(0, player.totalLines) / player.totalLines) : 0.0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Zen.subtle, borderRadius: BorderRadius.circular(Zen.radiusControl)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: limitReached ? Zen.ink3 : Zen.ink, foregroundColor: Colors.white),
                  onPressed: limitReached
                      ? null
                      : () => playing ? player.stop() : player.play(playKey, script, readOptions: readOptions),
                  icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: playing ? progress : (plays > 0 ? 1 : 0),
                      minHeight: 6,
                      backgroundColor: Zen.border,
                      color: Zen.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    playing
                        ? 'Đang phát…'
                        : limitReached
                            ? 'Đã hết lượt nghe'
                            : (plays == 0 ? 'Nhấn để nghe' : 'Nghe lại'),
                    style: Zen.small,
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Text(maxPlays == null ? 'Lần nghe: $plays' : 'Lần nghe: $plays/$maxPlays', style: Zen.labelSm),
            ]),
            if (player.japaneseAvailable == false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Thiết bị chưa có giọng đọc tiếng Nhật. Vào Cài đặt › Chuyển văn bản thành giọng nói để tải giọng 日本語.',
                  style: Zen.small.copyWith(color: Zen.amber),
                ),
              ),
          ]),
        );
      },
    );
  }
}

/// Khối tiêu đề mondai: もんだい1 · 漢字読み.
class MondaiHeader extends StatelessWidget {
  const MondaiHeader(this.mondai, {super.key, this.showInstruction = true});

  final Mondai mondai;
  final bool showInstruction;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Tag('${mondai.label}　${mondai.titleJa}', color: Zen.primary),
        Text(mondai.titleVi, style: Zen.small),
      ]),
      if (showInstruction) ...[
        const SizedBox(height: 10),
        Text(mondai.instructionJa, style: Zen.ja(14, weight: FontWeight.w400, color: Zen.ink, height: 1.6)),
        const SizedBox(height: 2),
        Text(mondai.instructionVi, style: Zen.small),
      ],
    ]);
  }
}

/// Tiêu đề nhóm trong danh sách.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Row(children: [
          Expanded(child: Text(text, style: Zen.hMD)),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Con dấu 合格 / 不合格.
class PassStamp extends StatelessWidget {
  const PassStamp({super.key, required this.passed, this.size = 56});

  final bool passed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = passed ? Zen.primary : Zen.ink3;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: 2.5)),
      child: Text(passed ? '合格' : '不合格',
          style: Zen.ja(passed ? size * 0.28 : size * 0.22, weight: FontWeight.w700, color: c, height: 1.1)),
    );
  }
}

