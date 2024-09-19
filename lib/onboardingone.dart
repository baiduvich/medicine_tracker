import 'package:flutter/material.dart';
import 'onboardingtwo.dart'; // Import the next onboarding page
import 'package:video_player/video_player.dart';

class OnboardingOne extends StatefulWidget {
  @override
  _OnboardingOneState createState() => _OnboardingOneState();
}

class _OnboardingOneState extends State<OnboardingOne> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the video controller with the video asset
    _controller = VideoPlayerController.asset('assets/videos/video1.mov')
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        // Wrap the entire body in a SingleChildScrollView
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 60,
              ),
              SizedBox(height: screenHeight * 0.05), // Add some top padding
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
                      height: screenHeight * 0.6,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
              SizedBox(height: 20),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'Track ', // Normal text
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold, // Make text bold
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'UNLIMITED ', // Highlighted text
                      style: TextStyle(
                        color: Colors.yellow, // Yellow color for 'ANY TYPE'
                        fontWeight: FontWeight.w900, // Keep bold
                      ),
                    ),
                    TextSpan(
                      text: 'Medicines!', // Continue with normal text
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Navigate to OnboardingTwo page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OnboardingTwo()),
                  );
                },
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
              SizedBox(height: screenHeight * 0.05), // Add some bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
