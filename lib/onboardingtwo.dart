import 'package:flutter/material.dart';
import 'onboardingthree.dart'; // Import the next onboarding page
import 'package:video_player/video_player.dart';
import 'ReviewAsk.dart';

class OnboardingTwo extends StatefulWidget {
  @override
  _OnboardingTwoState createState() => _OnboardingTwoState();
}

class _OnboardingTwoState extends State<OnboardingTwo> {
  late VideoPlayerController _controller;
  bool _isFirstClick = true; // Track if it's the first click

  @override
  void initState() {
    super.initState();
    // Initialize the video controller with the video asset (video2)
    _controller = VideoPlayerController.asset('assets/videos/video2.mov')
      ..initialize().then((_) {
        setState(() {}); // Update the state once the video is initialized
        _controller.play(); // Play the video automatically
        _controller.setLooping(true); // Loop the video
      });
  }

  @override
  void dispose() {
    _controller
        .dispose(); // Dispose of the controller when the widget is disposed
    super.dispose();
  }

  void _handleButtonClick(BuildContext context) {
    if (_isFirstClick) {
      // Call showDirectReview() on the first click
      showDirectReview();
      setState(() {
        _isFirstClick =
            false; // Update state to track that the first click is done
      });
    } else {
      // Navigate to OnboardingThree on the second click
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OnboardingThree()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        // Make the content scrollable
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 70), // Add some spacing from the top
              _controller.value.isInitialized
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10.0), // Rounded corners
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Border color
                          borderRadius:
                              BorderRadius.circular(20), // Rounded corners
                          border: Border.all(
                            color: Colors.yellow, // Yellow border
                            width: 10, // Border thickness
                          ),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: 0.8, // 80% of the available width
                          child: AspectRatio(
                            aspectRatio: _controller
                                .value.aspectRatio, // Maintain aspect ratio
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: screenWidth * 0.8,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
              SizedBox(height: 20),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'Never ', // Normal text
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold, // Make text bold
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'MISS A PILL', // Highlighted text
                      style: TextStyle(
                        color: Colors.yellow, // Yellow color for 'BULK Files'
                        fontWeight: FontWeight.w900, // Keep bold
                      ),
                    ),
                    TextSpan(
                      text: ' Again!!', // Continue with normal text
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _handleButtonClick(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red, // Button text color
                  backgroundColor: Colors.white, // Button background color
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontWeight: FontWeight.w900, // Make button text bold
                  ),
                ),
              ),
              SizedBox(height: 40), // Add some spacing to the bottom
            ],
          ),
        ),
      ),
    );
  }
}
