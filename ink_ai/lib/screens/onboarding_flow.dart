import 'package:flutter/material.dart';

import 'design_source_screen.dart';

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
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _goToDesignStudio() {
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
          children: [
            _HookPage(onNext: _nextPage),
            _SelectionScreen(
              header: "What's your ink status?",
              options: const [
                'First tattoo',
                'I have a few (1-3)',
                'Practically covered',
              ],
              onSelected: _nextPage,
            ),
            _SelectionScreen(
              header: "What's your style?",
              options: const [
                'Minimalist / Fine Line',
                'American Traditional',
                'Realism / Portrait',
                'Surprise me',
              ],
              onSelected: _nextPage,
            ),
            _SelectionScreen(
              header: 'What are your aesthetic goals?',
              options: const [
                'Bold statement',
                'Subtle & elegant',
                'Conversation starter',
                'Deeply personal',
              ],
              onSelected: _nextPage,
            ),
            _SelectionScreen(
              header: 'Describe your ideal vibe',
              options: const [
                'Dark & moody',
                'Light & airy',
                'Colorful',
                'Black & grey',
              ],
              onSelected: _nextPage,
            ),
            _SelectionScreen(
              header: "How's your pain tolerance?",
              options: const [
                'Low — I\'m nervous',
                'Medium — I can handle it',
                'High — bring it on',
              ],
              onSelected: _nextPage,
            ),
            _SelectionScreen(
              header: 'Where is the ink going?',
              options: const [
                'Arm / Sleeve',
                'Leg / Calf',
                'Chest / Torso',
                'Back / Neck',
                'Not sure yet',
              ],
              onSelected: _nextPage,
            ),
            _SelectionScreen(
              header: 'How big are we thinking?',
              options: const [
                'Micro / Patchwork',
                'Palm-sized',
                'Half-sleeve or larger',
              ],
              onSelected: _nextPage,
            ),
            _SelectionScreen(
              header: 'Any placement concerns?',
              options: const [
                'Must be work-safe',
                'Hidden & personal',
                'Easy to show off',
                'No concerns',
              ],
              onSelected: _nextPage,
            ),
            _SelectionScreen(
              header: 'Are you ready for aftercare?',
              options: const [
                'Absolutely — I\'m committed',
                'I\'ll manage',
                'Tell me more first',
              ],
              onSelected: _nextPage,
            ),
            _SelectionScreen(
              header: "What's the story?",
              options: const [
                'Deeply meaningful',
                'Strictly aesthetics',
                'Covering up old ink',
                'Just testing ideas',
              ],
              onSelected: _nextPage,
            ),
            _SelectionScreen(
              header: 'Is this a memorial or tribute?',
              options: const [
                'Yes — for a loved one',
                'Yes — for a milestone',
                'No — purely aesthetic',
                'Not sure yet',
              ],
              onSelected: _nextPage,
            ),
            _SelectionScreen(
              header: 'Are you spontaneous or strategic?',
              options: const [
                'I plan everything out',
                'I\'m spontaneous',
                'A mix of both',
              ],
              onSelected: _nextPage,
            ),
            _SelectionScreen(
              header: 'How soon do you want this?',
              options: const [
                'ASAP — let\'s go!',
                'Within a few months',
                'Just planning ahead',
                'Just exploring ideas',
              ],
              onSelected: _nextPage,
            ),
            _ProcessingPage(onComplete: _goToDesignStudio),
          ],
        ),
      ),
    );
  }
}

class _HookPage extends StatelessWidget {
  final VoidCallback onNext;
  const _HookPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Text(
            'Ready for new ink?',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF111111)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Let's calibrate the AI to your skin.",
            style: TextStyle(fontSize: 14, color: Color(0xFF7E7E7E)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: MaterialButton(
              onPressed: onNext,
              height: 54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              color: const Color(0xFF000000),
              elevation: 0,
              highlightElevation: 0,
              child: const Text(
                "Let's Go",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SelectionScreen extends StatelessWidget {
  final String header;
  final List<String> options;
  final VoidCallback onSelected;

  const _SelectionScreen({
    required this.header,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),
          Text(
            header,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF111111)),
          ),
          const SizedBox(height: 28),
          ...options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: onSelected,
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
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF111111)),
                    ),
                  ),
                ),
              )),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _ProcessingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const _ProcessingPage({required this.onComplete});

  @override
  State<_ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<_ProcessingPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Text(
            'Calibrating Studio...',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF111111)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tuning Gemini Vision models for your preferences...',
            style: TextStyle(fontSize: 14, color: Color(0xFF7E7E7E)),
          ),
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
      ),
    );
  }
}
