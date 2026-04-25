import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_alchemy_ui/flutter_gen/gen_l10n/app_localizations.dart';

class CropHistoryPage extends StatelessWidget {
  const CropHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.fertilizerHistoryTitle),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Connect to Firestore and get the fertilizer recommendations
        // Note: No orderBy since we don't see timestamp in your collection
        stream: FirebaseFirestore.instance
            .collection('fertilizer_recommendations')
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
              ),
            );
          }

          // Handle error state
          if (snapshot.hasError) {
            print('DEBUG: Error occurred: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      '${loc.errorLoadingData}: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Force rebuild widget
                        (context as Element).markNeedsBuild();
                      },
                      child: Text(loc.retry),
                    )
                  ],
                ),
              ),
            );
          }

          // Handle empty data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.agriculture, color: Color(0xFF2E7D32), size: 48),
                  SizedBox(height: 16),
                  Text(
                    loc.noFertilizerRecommendations,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          // Print data for debugging
          print('DEBUG: Found ${snapshot.data!.docs.length} documents');

          // Display data
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              // Get document data - using the field names from your screenshot
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              // Extract the data using the correct field names from your Firestore
              final cropName = data['Crop'] ?? 'Unknown Crop';
              final districtName = data['District_Name'] ?? 'Unknown Location';
              final fertilizer = data['Fertilizer'] ?? 'N/A';
              final nitrogen = data['Nitrogen']?.toString() ?? 'N/A';
              final phosphorus = data['Phosphorus']?.toString() ?? 'N/A';
              final potassium = data['Potassium']?.toString() ?? 'N/A';
              final rainfall = data['Rainfall']?.toString() ?? 'N/A';
              final soilColor = data['Soil_color'] ?? 'N/A';
              final temperature = data['Temperature']?.toString() ?? 'N/A';
              final pH = data['pH']?.toString() ?? 'N/A';
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.agriculture, color: Color(0xFF2E7D32), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cropName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "$districtName - $fertilizer",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrientColumn(loc.nutrientNitrogen, nitrogen, Colors.blue),
                          _buildNutrientColumn(loc.nutrientPhosphorus, phosphorus, Colors.orange),
                          _buildNutrientColumn(loc.nutrientPotassium, potassium, Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ExpansionTile(
                        title: Text(
                          loc.moreDetails,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              children: [
                                _buildDetailRow(loc.soilColor, soilColor),
                                _buildDetailRow(loc.temperature, '$temperature°C'),
                                _buildDetailRow(loc.ph, pH),
                                _buildDetailRow(loc.rainfall, '$rainfall mm'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.refresh, color: Colors.white),
        onPressed: () {
          // Force refresh
          (context as Element).markNeedsBuild();
        },
      ),
    );
  }

  Widget _buildNutrientColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value kg',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}