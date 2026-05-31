part of 'dashboard_screen.dart';

// ── Revenue card with target bar + confetti ───────────────────────────────────
class _RevenueCard extends StatefulWidget {
  final double weekRevenue;
  final double monthRevenue;
  final double outstanding;
  final double revenueTarget;

  const _RevenueCard({
    required this.weekRevenue,
    required this.monthRevenue,
    required this.outstanding,
    required this.revenueTarget,
  });

  @override
  State<_RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<_RevenueCard> {
  String _period = 'Month';
  late ConfettiController _confetti;
  bool _hasTriggeredConfetti = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _maybeConfetti();
  }

  @override
  void didUpdateWidget(_RevenueCard old) {
    super.didUpdateWidget(old);
    _maybeConfetti();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  double get _current =>
      _period == 'Week' ? widget.weekRevenue : widget.monthRevenue;

  double get _periodTarget =>
      _period == 'Week' ? widget.revenueTarget / 4.345 : widget.revenueTarget;

  bool get _targetReached => _periodTarget > 0 && _current >= _periodTarget;

  void _maybeConfetti() {
    if (_hasTriggeredConfetti) return;
    if (_targetReached) {
      _hasTriggeredConfetti = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confetti.play();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final revenue = _current;
    final target = _periodTarget;
    final hasTarget = target > 0;
    final progress = hasTarget ? (revenue / target).clamp(0.0, 1.0) : 0.0;
    final targetReached = _targetReached;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.panelSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.panelSoftRaised),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'REVENUE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      color: AppColors.panelMuted,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.panelFaint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: ['Week', 'Month'].map((p) {
                        final active = _period == p;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _period = p;
                            _hasTriggeredConfetti = false;
                            _maybeConfetti();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.panelInk
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              p,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? AppColors.panelSoft
                                    : AppColors.panelMuted,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '£${revenue.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: AppColors.panelInk,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
              if (hasTarget) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      targetReached
                          ? 'Target reached'
                          : '£${(target - revenue).toStringAsFixed(0)} to go',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: targetReached
                            ? AppColors.success
                            : AppColors.panelMuted,
                      ),
                    ),
                    Text(
                      '£${target.toStringAsFixed(0)} target',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.panelMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.panelFaint,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      targetReached
                          ? AppColors.success
                          : AppColors.panelInk.withValues(alpha: 0.62),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(height: 1, color: AppColors.panelFaint),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PAID',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.panelMuted,
                        ),
                      ),
                      Text(
                        '£${revenue.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.panelInk,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'OUTSTANDING',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.panelMuted,
                        ),
                      ),
                      Text(
                        '£${widget.outstanding.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: widget.outstanding > 0
                              ? AppColors.panelInk
                              : AppColors.panelInk.withValues(alpha: 0.28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 8,
            emissionFrequency: 0.05,
            gravity: 0.3,
            colors: const [
              AppColors.slate,
              AppColors.slateLight,
              AppColors.panelSoft,
              AppColors.panelInk,
              AppColors.bgRaised,
            ],
          ),
        ),
      ],
    );
  }
}
