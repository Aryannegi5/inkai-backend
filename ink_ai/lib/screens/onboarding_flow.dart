import 'package:flutter/material.dart';

import 'auth_screen.dart';

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

  Future<void> _autoAdvance() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) _nextPage();
  }

  void _goToAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
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
            _HookScreen(onNext: _nextPage),
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
              header: 'What is your vibe?',
              options: const [
                'Minimalist / Fine Line',
                'American Traditional',
                'Realism / Portrait',
                'Surprise me',
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
              header: 'How do you plan to use this?',
              options: const [
                'Show my artist a reference',
                'See if I actually like a design',
                'Just playing around',
              ],
              onSelected: _nextPage,
            ),
            _ProcessingPage(autoAdvance: _autoAdvance),
            _CompletionPage(onCreateAccount: _goToAuth),
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
  final Future<void> Function() autoAdvance;

  const _ProcessingPage({required this.autoAdvance});

  @override
  State<_ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<_ProcessingPage> {
  @override
  void initState() {
    super.initState();
    widget.autoAdvance();
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

class _CompletionPage extends StatelessWidget {
  final VoidCallback onCreateAccount;
  const _CompletionPage({required this.onCreateAccount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Text(
            'Your studio is ready.',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF111111)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your account to save your custom generations.',
            style: TextStyle(fontSize: 14, color: Color(0xFF7E7E7E)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: MaterialButton(
              onPressed: onCreateAccount,
              height: 54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              color: const Color(0xFF000000),
              elevation: 0,
              highlightElevation: 0,
              child: const Text(
                'Create Account',
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