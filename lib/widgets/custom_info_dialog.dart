import 'package:flutter/material.dart';

class InfoDialog extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;

  const InfoDialog({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 10,
      insetPadding: EdgeInsets.all(20),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imageUrl,
                    width: double.maxFinite,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontVariations: [FontVariation.width(500)],
                      color: Colors.grey[700],
                      leadingDistribution: TextLeadingDistribution.even),
                ),
              ],
            ),
          ),

          /// Sağ Üst Köşedeki Çarpı Butonu (X)
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.black),
              onPressed: () {
                Navigator.of(context).pop(); // Diyaloğu kapat
              },
            ),
          ),
        ],
      ),
    );
  }
}
