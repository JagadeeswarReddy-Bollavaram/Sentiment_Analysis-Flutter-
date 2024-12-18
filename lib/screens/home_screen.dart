import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentiment_detection/model/network_response.dart';
import 'package:sentiment_detection/model/sentiment_model.dart';
import 'package:sentiment_detection/services/network_caller.dart';
import 'package:sentiment_detection/utils/showSnackBerMessage.dart';
import 'package:sentiment_detection/utils/urls.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  double? score;
  String? sentiment;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            _buildBackground(),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 120),
                    Text(
                      'Analyze Your Sentiment',
                      style: GoogleFonts.aBeeZee(
                        textStyle: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (score != null && sentiment != null) _buildResultCard(),
                    const SizedBox(height: 24),
                    _buildInputField(),
                    const SizedBox(height: 20),
                    _buildAnalyzeButton(),
                    if (isLoading) const SizedBox(height: 20),
                    if (isLoading)
                      const Center(
                          child: CircularProgressIndicator(
                        color: Colors.greenAccent,
                      ))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Soft Blue Gradient Background
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0093E9), // Bright blue
            Color(0xFF80D0C7), // Soft teal
            Color(0xFF7D5BA6), // Lavender
            Color(0xFFCB74B0), // Pinkish purple
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
          // Control the transition points between colors
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return AnimatedOpacity(
      opacity: score != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Card(
        color: Colors.white.withOpacity(0.9),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FittedBox(
                child: Text(
                  'Sentiment: $sentiment',
                  style: GoogleFonts.aBeeZee(
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getSentimentColor(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Score: ${score!.toStringAsFixed(2)}',
                style: GoogleFonts.aBeeZee(
                  textStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Icon(
                _getSentimentIcon(),
                color: _getSentimentColor(),
                size: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Customized Text Field with Icon and Shadow
  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: _textEditingController,
        maxLines: 3,
        style: GoogleFonts.aBeeZee(
            textStyle: const TextStyle(fontSize: 16, color: Colors.black87)),
        decoration: InputDecoration(
          hintText: 'Enter text for sentiment analysis...',
          labelText: 'Write here...',
          labelStyle: TextStyle(
            color: Colors.teal[700],
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          suffixIcon: IconButton(
            onPressed: () {
              _textEditingController.clear();
            },
            icon: const Icon(
              Icons.delete_outline,
              size: 28,
              color: Colors.redAccent,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }

  // Customized Analyze Button with Gradient and Shadow
  Widget _buildAnalyzeButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : _onTabCheck,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.teal.shade400,
        foregroundColor: Colors.white,
        elevation: 6,
        shadowColor: Colors.tealAccent.withOpacity(0.5),
      ),
      child: const Text(
        'Analyze Sentiment',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  IconData _getSentimentIcon() {
    if (score == null) return Icons.help_outline;
    if (score! > 0.5) return Icons.sentiment_very_satisfied;
    if (score! > 0) return Icons.sentiment_satisfied;
    if (score! == 0) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  Color _getSentimentColor() {
    if (score == null) return Colors.grey;
    if (score! > 0.5) return Colors.green;
    if (score! > 0) return Colors.lightGreen;
    if (score! == 0) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  void _onTabCheck() {
    setState(() {
      isLoading = true;
    });
    _getData();
  }

  Future<void> _getData() async {
    NetworkResponse networkResponse = await NetworkCaller.getRequest(
      url: Urls.sentimentUrl(_textEditingController.text),
    );

    if (networkResponse.isSuccess) {
      final SentimentModel sentimentModel =
          SentimentModel.fromJson(networkResponse.responseData);
      setState(() {
        score = sentimentModel.score;
        sentiment = sentimentModel.sentiment;
        isLoading = false;
      });
      showSnackBerMessage(context, 'Sentiment Analysis Successful!');
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBerMessage(
          context, 'Failed to fetch sentiment analysis data', true);
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
