import 'package:agro_alchemy_ui/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AboutHelpPage extends StatelessWidget {
  const AboutHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.aboutHelp),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // About Us Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children:  [
                      Icon(Icons.info, color: Color(0xFF2E7D32)),
                      SizedBox(width: 8),
                      Text(
                        loc.aboutUs,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loc.aboutUsDescription,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                   Text(
                    loc.developmentTeam,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loc.teamMembers,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Help Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help, color: Color(0xFF2E7D32)),
                      SizedBox(width: 8),
                      Text(
                        loc.helpFaqs,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ExpansionTile(
                    leading: const Icon(Icons.question_answer),
                    title:Text(loc.faqAnalyzeCropHealth),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          loc.faqAnalyzeCropHealthAnswer,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    leading: const Icon(Icons.question_answer),
                    title: Text(loc.faqFertilizerRecommendations),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          loc.faqFertilizerRecommendationsAnswer,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    leading: const Icon(Icons.question_answer),
                    title: Text(loc.faqChatbotPurpose),
                    children:[
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          loc.faqChatbotPurposeAnswer,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    leading: const Icon(Icons.question_answer),
                    title: Text(loc.faqViewCropHistory),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          loc.faqViewCropHistoryAnswer,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    leading: const Icon(Icons.question_answer),
                    title:  Text(loc.faqContactSupport),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          loc.faqContactSupportAnswer,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  // Add more FAQs as needed
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
