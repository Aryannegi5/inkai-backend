import 'package:flutter/material.dart';

import 'design_source_screen.dart';

enum OnboardingStepType { question, interstitialInfo, processing }

class OnboardingStep {
  final OnboardingStepType type;
  final String title;
  final String subtitle;
  final List<String>? options;
  final int? delayDuration;
  final String? buttonLabel;

  const OnboardingStep({
    required this.type,
    required this.title,
    this.subtitle = '',
    this.options,
    this.delayDuration,
    this.buttonLabel,
  });
}

final _steps = <OnboardingStep>[
  // Phase 1: Unity
  const OnboardingStep(
    type: OnboardingStepType.interstitialInfo,
    title: 'Ready to design your next piece?',
    subtitle: '',
    buttonLabel: "Let's Go",
  ),
  const OnboardingStep(
    type: OnboardingStepType.question,
    title: 'What is your current ink status?',
    options: ['First-timer', 'A few', 'Heavily tattooed'],
  ),
  const OnboardingStep(
    type: OnboardingStepType.question,
    title: 'What draws you to tattoos?',
    options: ['Aesthetics', 'Meaning', 'Cover-ups'],
  ),
  const OnboardingStep(
    type: OnboardingStepType.interstitialInfo,
    title: 'We built a studio that adapts to your exact vision.',
    delayDuration: 3,
  ),
  // Phase 2: Commitment (Questions 5-11)
  const OnboardingStep(
    type: OnboardingStepType.question,
    title: 'Preferred Style',
    subtitle: 'What style speaks to you?',
    options: [
      'Realism',
      'Fine Line',
      'American Traditional',
      'Japanese',
      'Geometric',
      'Watercolor',
    ],
  ),
  const OnboardingStep(
    type: OnboardingStepType.question,
    title: 'Canvas Size',
    subtitle: 'How much real estate are we working with?',
    options: ['Small (palm-sized)', 'Medium (hand-sized)', 'Large (half-sleeve+)'],
  ),
  const OnboardingStep(
    type: OnboardingStepType.question,
    title: 'Pain Tolerance',
    subtitle: 'How do you handle the sting?',
    options: ['Low — I\'m nervous', 'Medium — I can handle it', 'High — bring it on'],
  ),
  const OnboardingStep(
    type: OnboardingStepType.question,
    title: 'Placement',
    subtitle: 'Where does this ink belong?',
    options: [
      'Arm / Forearm',
      'Leg / Calf',
      'Chest / Torso',
      'Back / Shoulder',
      'Ribs / Side',
      'Not sure yet',
    ],
  ),
  const OnboardingStep(
    type: OnboardingStepType.question,
    title: 'Color vs Black/Grey',
    subtitle: 'Pick your palette.',
    options: ['Full color', 'Black and grey', 'Mostly black with color accents'],
  ),
  const OnboardingStep(
    type: OnboardingStepType.question,
    title: 'Shading Intensity',
    subtitle: 'How deep should the shadows go?',
    options: [
      'Light / Minimal shading',
      'Medium / Smooth blends',
      'Heavy / Dark contrast',
    ],
  ),
  const OnboardingStep(
    type: OnboardingStepType.question,
    title: 'Detail Level',
    subtitle: 'How intricate should the design be?',
    options: ['Minimalist / Simple', 'Moderate detail', 'Highly intricate', 'Photorealistic'],
  ),
  // Screen 12
  const OnboardingStep(
    type: OnboardingStepType.question,
    title: 'When are you getting this inked?',
    options: ['ASAP', 'Next Month', 'Just browsing'],
  ),
  // Screen 13: Processing
  const OnboardingStep(
    type: OnboardingStepType.processing,
    title: 'Locking in preferences...',
    delayDuration: 2,
  ),
  // Phase 3: Authority & Social Proof
  const OnboardingStep(
    type: OnboardingStepType.interstitialInfo,
    title: 'Your aesthetic leans heavily towards your selections.',
    delayDuration: 3,
  ),
  const OnboardingStep(
    type: OnboardingStepType.interstitialInfo,
    title: 'Our engine is trained on over 100,000 professional studio portfolios.',
    delayDuration: 3,
  ),
  const OnboardingStep(
    type: OnboardingStepType.interstitialInfo,
    title: 'Over 12,000 users found their perfect design this week.',
    delayDuration: 3,
  ),
  const OnboardingStep(
    type: OnboardingStepType.processing,
    title: 'Configuring Gemini Vision models for your skin...',
    delayDuration: 3,
  ),
  // Phase 4 & 5: The Hook & Scarcity
  const OnboardingStep(
    type: OnboardingStepType.question,
    title: 'To calibrate the generator, type your main concept.',
    subtitle: 'Describe the idea in a few words.',
  ),
  const OnboardingStep(
    type: OnboardingStepType.processing,
    title: 'Generating baseline concept...',
    delayDuration: 3,
  ),
  const OnboardingStep(
    type: OnboardingStepType.interstitialInfo,
    title: 'Your custom studio is ready.',
    subtitle: 'Your preferences have been saved to your profile.',
    buttonLabel: 'Enter Studio',
  ),
];

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToStudio() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DesignSourceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == _steps.length - 1;
            return _OnboardingPage(
              step: step,
              onNext: _nextPage,
              onComplete: isLast ? _goToStudio : null,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatefulWidget {
  final OnboardingStep step;
  final VoidCallback onNext;
  final VoidCallback? onComplete;

  const _OnboardingPage({
    required this.step,
    required this.onNext,
    this.onComplete,
  });

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage> {
  final _conceptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scheduleAutoAdvance();
  }

  void _scheduleAutoAdvance() {
    final step = widget.step;
    if (step.type == OnboardingStepType.processing ||
        (step.type == OnboardingStepType.interstitialInfo &&
            step.delayDuration != null)) {
      final delay = step.delayDuration ?? 3;
      Future.delayed(Duration(seconds: delay), () {
        if (mounted) widget.onNext();
      });
    }
  }

  @override
  void dispose() {
    _conceptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
      child: switch (widget.step.type) {
        OnboardingStepType.interstitialInfo => _buildInfoPage(),
        OnboardingStepType.question => _buildQuestionPage(),
        OnboardingStepType.processing => _buildProcessingPage(),
      },
    );
  }

  Widget _buildInfoPage() {
    final hasButton = widget.step.buttonLabel != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text(
          widget.step.title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111111),
          ),
        ),
        if (widget.step.subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.step.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7E7E7E),
            ),
          ),
        ],
        const Spacer(),
        if (hasButton)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: MaterialButton(
              onPressed: widget.onComplete ?? widget.onNext,
              height: 54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              color: const Color(0xFF000000),
              elevation: 0,
              highlightElevation: 0,
              child: Text(
                widget.step.buttonLabel!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildQuestionPage() {
    if (widget.step.options != null && widget.step.options!.isNotEmpty) {
      return _buildSelectionPage();
    }
    return _buildTextInputPage();
  }

  Widget _buildSelectionPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(flex: 1),
        Text(
          widget.step.title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111111),
          ),
        ),
        if (widget.step.subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.step.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7E7E7E),
            ),
          ),
        ],
        const SizedBox(height: 28),
        ...widget.step.options!.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: widget.onNext,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                ),
                child: Text(
                  option,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildTextInputPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(flex: 1),
        Text(
          widget.step.title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111111),
          ),
        ),
        if (widget.step.subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.step.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7E7E7E),
            ),
          ),
        ],
        const SizedBox(height: 32),
        TextField(
          controller: _conceptController,
          autofocus: true,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF111111),
          ),
          decoration: InputDecoration(
            hintText: 'Type your idea...',
            hintStyle: const TextStyle(
              fontSize: 18,
              color: Color(0xFFBDBDBD),
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFE5E5E5), width: 1),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFE5E5E5), width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF111111), width: 1.5),
            ),
            contentPadding: const EdgeInsets.only(bottom: 10),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: MaterialButton(
            onPressed: widget.onNext,
            height: 54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            color: const Color(0xFF000000),
            elevation: 0,
            highlightElevation: 0,
            child: const Text(
              'Next',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildProcessingPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text(
          widget.step.title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111111),
          ),
        ),
        if (widget.step.subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.step.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7E7E7E),
            ),
          ),
        ],
        const SizedBox(height: 48),
        const Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF000000),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
