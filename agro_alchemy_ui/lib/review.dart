import 'package:flutter/material.dart';
import 'package:agro_alchemy_ui/flutter_gen/gen_l10n/app_localizations.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final TextEditingController _reviewController = TextEditingController();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/dashboard');
      case 1:
        Navigator.pushNamed(context, '/history');
      case 2:
        Navigator.pushNamed(context, '/chatbot');
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: const Color(0xFF36522E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF36522E)),
              accountName:  Text(loc.drawerHelloUser),
              accountEmail: null,
              currentAccountPicture: const CircleAvatar(
                backgroundImage: AssetImage('assets/profile.png'),
              ),
            ),
            _buildDrawerItem(Icons.bar_chart, loc.drawerYieldPrediction, '/yield'),
            _buildDrawerItem(Icons.science, loc.fertilizerPrediction, '/fertilizer'),
            _buildDrawerItem(Icons.bug_report, loc.drawerPestPrediction, '/pest'),
            _buildDrawerItem(Icons.rate_review, loc.writeReview, '/reviews'),
            _buildDrawerItem(Icons.help_outline, loc.aboutHelp, '/about'),
            _buildDrawerItem(Icons.phone, loc.drawerContactUs, '/contact'),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        title:  Text(loc.writeReview, style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.yourFeedback,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: loc.writeExperienceHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36522E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                // TODO: Add review submission logic
              },
              child: Text(loc.submitReview),
            ),
            const SizedBox(height: 24),
            Text(loc.previousReviews,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildReviewCard(
                    name: 'Ramesh P.',
                    review: 'Great prediction results. Helped my farm a lot!',
                  ),
                  _buildReviewCard(
                    name: 'Seeta Devi',
                    review: 'Fertilizer advice was spot on. Thank you!',
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF36522E),
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items:  [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: loc.home),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: loc.cropHistory),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: loc.chatbot),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String routeName) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context); // Close the drawer
        Navigator.pushNamed(context, routeName);
      },
    );
  }

  Widget _buildReviewCard({required String name, required String review}) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(review),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(onPressed: () {}, child:  Text(loc.edit)),
                TextButton(onPressed: () {}, child:  Text(loc.delete)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
