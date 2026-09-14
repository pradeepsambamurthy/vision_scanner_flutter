import 'package:flutter/material.dart';

import 'acuity_test_screen.dart';
import 'accessible_vision_test_screen.dart';

class TestMenuScreen extends StatefulWidget {
  const TestMenuScreen({super.key});

  @override
  State<TestMenuScreen> createState() =>
      _TestMenuScreenState();
}

class _TestMenuScreenState extends State<TestMenuScreen> {
  Widget? _activeTest;

  @override
  Widget build(BuildContext context) {
    if (_activeTest != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
  alignment: Alignment.centerLeft,
  child: Container(
    margin: const EdgeInsets.only(
      bottom: 8,
    ),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.35),
      borderRadius: BorderRadius.circular(10),
    ),
    child: TextButton.icon(
      onPressed: () => setState(() {
        _activeTest = null;
      }),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
      ),
      icon: const Icon(
        Icons.arrow_back,
        color: Colors.white,
      ),
      label: const Text(
        'Choose another test',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  ),
),
          Expanded(
            child: _activeTest!,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Choose a Vision Test',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Select the vision screening that is easiest for you to use.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 24),

        _TestCard(
          icon: Icons.visibility_outlined,
          title: 'Standard Vision Test',
          description:
              'For people who have difficulty seeing or using the standard vision test. '
              'Includes larger letters, spoken instructions, voice responses and large controls.',
          features: const [
            'Distance and near vision',
            'Right Eye (OD)',
            'Left Eye (OS)',
            'Both Eyes (OU)',
            'Starts at 20/50',
            'Progressively smaller letters',
          ],
          buttonText:
              'Start Standard Vision Test',
          onPressed: () {
            setState(() {
              _activeTest =
                  const AcuityTestScreen();
            });
          },
        ),

        const SizedBox(height: 20),

        _TestCard(
          icon: Icons.accessibility_new,
          title: 'Accessible Vision Test',
          description:
              'For people who have difficulty seeing or '
              'using the standard vision test.',
          features: const [
            'Large high-contrast letters',
            'Spoken step-by-step instructions',
            'Voice responses for the 5 letters',
            'Large-button response fallback',
            'No time limit',
            'Designed for reduced vision',
          ],
          buttonText:
              'Start Accessible Vision Test',
          onPressed: () {
            setState(() {
              _activeTest =
                  const AccessibleVisionTestScreen();
            });
          },
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(
              0xFFFFF8E7,
            ),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: const Text(
            'If you cannot see the largest letters in the '
            'Accessible Vision Test, the online screening '
            'may not be able to measure your visual acuity. '
            'Consider a professional eye examination.',
            style: TextStyle(
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.buttonText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(
            0xFFE3E7EE,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 14),

          ...features.map(
            (feature) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 7,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons
                        .check_circle_outline,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              style:
                  FilledButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(
                  52,
                ),
              ),
              child: Text(
                buttonText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
