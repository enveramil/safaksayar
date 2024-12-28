import 'dart:ui';
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
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Stack(
                        children: [
                          // Bulanıklaştırılmış tam ekran arka plan
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Colors.black.withOpacity(
                                  0.3), // Hafif siyah transparan katman
                            ),
                          ),
                          // Resim büyütme popup
                          Center(
                            child: InteractiveViewer(
                              maxScale: 5.0, // Maksimum yakınlaştırma
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors
                                      .white, // Resim çerçevesi arka planı
                                ),
                                child: Image.asset(
                                  'assets/images/rank.png', // Resim yolu
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          // Sağ üstte çarpı butonu
                          Positioned(
                            top: 20, // Çarpı butonunun üstten konumu
                            right: 20, // Çarpı butonunun sağdan konumu
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(
                                      0.5), // Siyah yarı şeffaf arka plan
                                ),
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white, // Çarpı butonunun rengi
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/rank.png', // Resminizin yolu
                    width: 425, // Resmin genişliği
                    height: 600, // Resmin yüksekliği
                    fit: BoxFit.fitWidth, // Resmi kapsama şekli
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
