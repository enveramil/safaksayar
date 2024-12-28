import 'package:flutter/material.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4B5320), // Askeri yeşil
              Color(0xFF706C61), // Kamuflaj kahverengisi
              Color(0xFF3D3C3A), // Koyu gri ton
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Askeri Rütbeler',
                style: TextStyle(
                  color: Colors.white, // Başlık rengi beyaz
                ),
              ),
              centerTitle: true,
            ),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/rank.png', // Resminizin yolu
                  width: 425, // Resmin genişliği
                  height: 600, // Resmin yüksekliği
                  fit: BoxFit.fitWidth, // Resmi kapsama şekli
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
