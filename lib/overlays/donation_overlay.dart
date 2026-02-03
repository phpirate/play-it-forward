import 'package:flutter/material.dart';
import '../game/play_it_forward_game.dart';

class DonationOverlay extends StatefulWidget {
  final PlayItForwardGame game;

  const DonationOverlay({super.key, required this.game});

  @override
  State<DonationOverlay> createState() => _DonationOverlayState();
}

class _DonationOverlayState extends State<DonationOverlay> {
  bool _showThankYou = false;
  double _selectedAmount = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _showThankYou ? _buildThankYou() : _buildDonationOptions(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonationOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: () => widget.game.hideDonation(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ),

        const Icon(
          Icons.favorite,
          color: Colors.red,
          size: 50,
        ),

        const SizedBox(height: 15),

        const Text(
          'Support Our Mission',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Your donation helps charity and\nkeeps this game free for everyone!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),

        const SizedBox(height: 25),

        // Donation amounts
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _DonationButton(
              amount: 1,
              onPressed: () => _simulateDonation(1),
            ),
            _DonationButton(
              amount: 3,
              onPressed: () => _simulateDonation(3),
            ),
            _DonationButton(
              amount: 5,
              onPressed: () => _simulateDonation(5),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Transparency info
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.shade900.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            children: [
              Text(
                'Where Your Money Goes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volunteer_activism, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '70% → Charity Partners',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.code, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '30% → Game Development',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        const Text(
          'This is a demo - no real payment will be processed',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white38,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildThankYou() {
    final charityAmount = (_selectedAmount * 0.7).toStringAsFixed(2);
    final devAmount = (_selectedAmount * 0.3).toStringAsFixed(2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 60,
        ),

        const SizedBox(height: 20),

        const Text(
          'Thank You! ❤️',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 15),

        Text(
          'Your \$${_selectedAmount.toStringAsFixed(0)} donation:',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 15),

        Text(
          '\$$charityAmount → Charity',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.green,
          ),
        ),

        Text(
          '\$$devAmount → Development',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.blue,
          ),
        ),

        const SizedBox(height: 25),

        ElevatedButton(
          onPressed: () {
            setState(() {
              _showThankYou = false;
            });
            widget.game.hideDonation();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _simulateDonation(double amount) {
    setState(() {
      _selectedAmount = amount;
      _showThankYou = true;
    });
  }
}

class _DonationButton extends StatelessWidget {
  final int amount;
  final VoidCallback onPressed;

  const _DonationButton({
    required this.amount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        '\$$amount',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
