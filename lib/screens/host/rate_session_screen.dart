import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/providers/auth_provider.dart';
import 'package:vnest_app/core/services/review_service.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class RateSessionScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const RateSessionScreen({super.key, this.extra});

  @override
  State<RateSessionScreen> createState() => _RateSessionScreenState();
}

class _RateSessionScreenState extends State<RateSessionScreen> {
  int _rating = 5;
  final Set<String> _selectedTags = {};
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  bool get _isHostRatingRenter => widget.extra?['isHostRatingRenter'] == true;

  static const _hostRatingLabels = {
    1: 'Difficult renter',
    2: 'Below average',
    3: 'Satisfactory',
    4: 'Good driver',
    5: 'Excellent renter! 🌟',
  };

  static const _driverRatingLabels = {
    1: 'Terrible',
    2: 'Poor',
    3: 'Average',
    4: 'Good',
    5: 'Excellent Host! ⚡',
  };

  static const _renterTags = [
    'Punctual driver',
    'Clean parking bay',
    'Careful with cable',
    'Polite communication',
    'Left bay on time',
    'Followed society rules',
  ];

  static const _hostTags = [
    'Great host',
    'Fast charging',
    'Easy access',
    'Clean spot',
    'Accurate listing',
    'Clear directions',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.extra?['initialRating'] is int) {
      _rating = (widget.extra!['initialRating'] as int).clamp(1, 5);
    }
    if (_isHostRatingRenter) {
      _selectedTags.addAll(['Punctual driver', 'Clean parking bay']);
    } else {
      _selectedTags.addAll(['Fast charging', 'Easy access']);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final user = AuthProvider().currentUser;
      final userId = (user?.id != null && user!.id.isNotEmpty) ? user.id : 'demo_user_1';
      final userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'VoltShare User';

      if (_isHostRatingRenter) {
        final renterId = widget.extra?['renterId'] ?? 'demo_renter_1';
        final renterName = widget.extra?['renterName'] ?? 'Rahul Sharma';
        await ReviewService().submitRenterReview(
          hostId: userId,
          renterId: renterId,
          renterName: renterName,
          rating: _rating,
          tags: _selectedTags.toList(),
          comment: _reviewController.text,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Renter rating submitted for $renterName! ($_rating ★)',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        final chargerId = widget.extra?['chargerId'] ?? 'ch_1';
        final bookingId = widget.extra?['bookingId'] ?? 'bk_demo_${DateTime.now().millisecondsSinceEpoch}';

        await ReviewService().submitReview(
          userId: userId,
          userName: userName,
          chargerId: chargerId,
          bookingId: bookingId,
          rating: _rating,
          comment: _reviewController.text,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Host & Charger review submitted! ($_rating ★)',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isHostRatingRenter ? 'Rate Last Renter' : 'Rate Host & Charger';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
        ),
        title: Text(
          title,
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildSessionSummaryCard(),
            const SizedBox(height: 28),
            _buildRatingQuestion(),
            const SizedBox(height: 20),
            _buildStarRating(),
            const SizedBox(height: 32),
            _buildTagSection(),
            const SizedBox(height: 28),
            _buildReviewInput(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionSummaryCard() {
    final isRenter = _isHostRatingRenter;
    final heading = isRenter
        ? (widget.extra?['renterName'] ?? 'Rahul Sharma')
        : (widget.extra?['chargerName'] ?? 'Tower B Slot 4 (Host: Amit K.)');
    final subtitle = isRenter
        ? (widget.extra?['vehicle'] ?? widget.extra?['sessionInfo'] ?? 'Tata Nexon EV · Slot B4 · Completed yesterday')
        : (widget.extra?['sessionInfo'] ?? 'Completed yesterday · 7.2 kWh · ₹86.40');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isRenter ? Icons.person : Icons.ev_station,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04);
  }

  Widget _buildRatingQuestion() {
    final question = _isHostRatingRenter
        ? 'How was your experience with this renter?'
        : 'How was your charging experience with this host?';

    return Center(
      child: Text(
        question,
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildStarRating() {
    final labels = _isHostRatingRenter ? _hostRatingLabels : _driverRatingLabels;

    return Column(
      children: [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isFilled = starIndex <= _rating;
              return GestureDetector(
                onTap: () => setState(() => _rating = starIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    isFilled ? Icons.star : Icons.star_border,
                    size: 48,
                    color: isFilled
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              labels[_rating] ?? '',
              key: ValueKey(_rating),
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildTagSection() {
    final tagList = _isHostRatingRenter ? _renterTags : _hostTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isHostRatingRenter ? 'Renter highlights' : 'What did you like most?',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tagList.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.borderHoverDark,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.04);
  }

  Widget _buildReviewInput() {
    final inputTitle = _isHostRatingRenter
        ? 'Renter feedback for community (optional)'
        : 'Add a review (optional)';
    final hint = _isHostRatingRenter
        ? 'Help fellow hosts know how this renter respects charger bays...'
        : 'Tell other drivers about your experience with this host and charger...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          inputTitle,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: TextField(
            controller: _reviewController,
            maxLines: 4,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              filled: false,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.04);
  }

  Widget _buildSubmitButton() {
    final label = _isHostRatingRenter ? 'Submit Renter Rating' : 'Submit Review';

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
              )
            : Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideY(begin: 0.06);
  }
}
