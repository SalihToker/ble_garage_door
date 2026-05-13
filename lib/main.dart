import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GarajUygulamasi());
}

class GarajUygulamasi extends StatelessWidget {
  const GarajUygulamasi({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BLE Garaj Kontrol',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const KontrolEkrani(),
    );
  }
}

class KontrolEkrani extends StatefulWidget {
  const KontrolEkrani({Key? key}) : super(key: key);

  @override
  _KontrolEkraniState createState() => _KontrolEkraniState();
}

class _KontrolEkraniState extends State<KontrolEkrani> {
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _targetCharacteristic;
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // HM-10'un standart iletişim karakteristiği UUID'si
  final String hm10CharacteristicUUID = "0000ffe1-0000-1000-8000-00805f9b34fb";

  @override
  void initState() {
    super.initState();
    // Tarama sonuçlarını dinle
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  // BLE Cihazlarını Tara
  Future<void> _cihazlariTara() async {
    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });
    
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    } catch (e) {
      debugPrint("Tarama Hatası: $e");
    }
    
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Seçilen Cihaza Bağlan
  Future<void> _cihazaBaglan(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    
    try {
      // Sorunun yaşandığı yer burasıydı. IDE art ık bunun BluetoothDevice'a ait olduğunu bilecek.
      // Eski hali: await device.connect();
      await device.connect(
        license: License.free, // DİKKAT: IDE'nizin önerdiği tam değeri buraya yazın
        autoConnect: false,
      );
      
      setState(() {
        _connectedDevice = device;
      });
      _servisleriKesfet(device);
    } catch (e) {
      debugPrint("Bağlantı hatası: $e");
    }
  }

  // HM-10 Servis ve Karakteristiğini Bul
  // HM-10, BT05 ve diğer klonların Servis/Karakteristiğini Bul
  // Cihazın Tüm Kanallarının Röntgenini Çek ve Doğru Olanı Bul
  Future<void> _servisleriKesfet(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      
      debugPrint("\n--- BLE KANAL TARAMASI BAŞLADI ---");
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          String uuid = characteristic.uuid.toString().toLowerCase();
          
          bool canWrite = characteristic.properties.write;
          bool canWriteWithoutResp = characteristic.properties.writeWithoutResponse;
          
          debugPrint("Kanal Bulundu: $uuid | Yazılabilir mi? ${canWrite || canWriteWithoutResp}");

          // Piyasada BT05 ve HM-10 klonlarının kullandığı tüm olası veri kanalları:
          if (uuid.contains("ffe1") || uuid.contains("ffe2") || 
              uuid.contains("fff1") || uuid.contains("fff2") || 
              uuid.contains("fff4") || uuid.contains("dfb1")) {
            
            setState(() {
              _targetCharacteristic = characteristic;
            });
            debugPrint(">>> İŞTE DOĞRU VERİ KANALI BULUNDU: $uuid <<<");
            return; // Doğru kanalı bulduk, aramayı bitir!
          }
        }
      }
      debugPrint("--- BLE KANAL TARAMASI BİTTİ ---\n");
      debugPrint("DİKKAT: Veri kanalı eşleşmedi. Lütfen terminaldeki logları bana gönderin.");
      
    } catch (e) {
      debugPrint("Servis keşfetme hatası: $e");
    }
  }

  // Arduino'ya Veri Gönder
  // Arduino'ya Akıllı Komut Gönder (Kanalın türünü otomatik algılar)
  Future<void> _komutGonder(String komut) async {
    if (_targetCharacteristic != null) {
      List<int> bytes = utf8.encode(komut);
      try {
        // Cihaz "Onaysız yazma" (withoutResponse) destekliyorsa onu kullan, yoksa normal yaz
        bool onaysizYazma = _targetCharacteristic!.properties.writeWithoutResponse;
        
        await _targetCharacteristic!.write(bytes, withoutResponse: onaysizYazma);
        debugPrint("Komut Başarıyla Gönderildi: $komut");
      } catch (e) {
        debugPrint("Gönderme hatası: $e");
      }
    } else {
      debugPrint("Henüz cihaza veya karakteristiğe bağlanılmadı.");
    }
  }

  // Şifre Sorma Penceresi
  Future<void> _sifreSor(BuildContext context, String komut) async {
    TextEditingController sifreController = TextEditingController();
    String dogruSifre = "1234"; // GARAJ ŞİFRESİNİ BURADAN BELİRLEYEBİLİRSİN

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Güvenlik Doğrulaması"),
          content: TextField(
            controller: sifreController,
            obscureText: true, // Girilen şifreyi gizler (***)
            keyboardType: TextInputType.number,
            maxLength: 4, // En fazla 4 hane girilsin
            decoration: const InputDecoration(
              hintText: "4 Haneli Şifreyi Girin",
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Onayla", style: TextStyle(color: Colors.white)),
              onPressed: () {
                // Şifre kontrolü burada yapılıyor
                if (sifreController.text == dogruSifre) {
                  Navigator.pop(context); // Pencereyi kapat
                  _komutGonder(komut); // Şifre doğruysa komutu Arduino'ya yolla!
                } else {
                  Navigator.pop(context); // Pencereyi kapat
                  // Yanlış şifre uyarısı göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Hatalı Şifre! Erişim Reddedildi."),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Bağlantıyı Kes
  Future<void> _baglantiyiKes() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _targetCharacteristic = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE Garaj Kapısı"),
        actions: [
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: _baglantiyiKes,
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_connectedDevice != null && _targetCharacteristic != null) ...[
              Text("Bağlı Cihaz: ${_connectedDevice!.platformName.isNotEmpty ? _connectedDevice!.platformName : 'Bilinmeyen Cihaz'}", 
                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    // Artık doğrudan komut göndermiyoruz, önce şifre soruyoruz
                    onPressed: () => _sifreSor(context, 'A'), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    ),
                    child: const Text("AÇ", style: TextStyle(fontSize: 24, color: Colors.white)),
                  ),
                  ElevatedButton(
                    // Kapama işlemi için de şifre soruyoruz
                    onPressed: () => _sifreSor(context, 'K'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    ),
                    child: const Text("KAPAT", style: TextStyle(fontSize: 24, color: Colors.white)),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _isScanning ? null : _cihazlariTara,
                child: Text(_isScanning ? "Taranıyor..." : "Cihazları Tara"),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _scanResults.length,
                  itemBuilder: (context, index) {
                    final result = _scanResults[index];
                    final deviceName = result.device.platformName.isNotEmpty 
                        ? result.device.platformName 
                        : "Bilinmeyen Cihaz";
                    return ListTile(
                      title: Text(deviceName),
                      subtitle: Text(result.device.remoteId.toString()),
                      trailing: ElevatedButton(
                        child: const Text("Bağlan"),
                        onPressed: () => _cihazaBaglan(result.device),
                      ),
                    );
                  },
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}