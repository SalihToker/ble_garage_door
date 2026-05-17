#include <SoftwareSerial.h>
#include <Servo.h> // Servo motor kütüphanesini ekliyoruz

// RX pini 10, TX pini 11 (HM-10 için)
SoftwareSerial btModule(10, 11); 

// Motor ve LED pinlerini tanımlıyoruz
Servo garajMotoru;
const int yesilLed = 4;
const int kirmiziLed = 5;
const int motorPini = 9;
const int dogruSifre = 1234;

void setup() {
  Serial.begin(9600);
  btModule.begin(9600);
  
  // Pin görevlerini atıyoruz
  pinMode(yesilLed, OUTPUT);
  pinMode(kirmiziLed, OUTPUT);
  garajMotoru.attach(motorPini);
  
  // SİSTEMİN BAŞLANGIÇ DURUMU (KAPI KAPALI)
  garajMotoru.write(0); // Motoru 0 dereceye (Kapalı konuma) getir
  digitalWrite(kirmiziLed, HIGH); // Kırmızı yansın
  digitalWrite(yesilLed, LOW);    // Yeşil sönsün
  
  Serial.println("Sistem hazir. Bluetooth baglantisi bekleniyor...");
}

void loop() {
  if (btModule.available()) {
    String gelenVeri = btModule.readStringUntil('\n');
    Serial.print("Gelen Komut: ");
    Serial.println(gelenVeri);

    char gelenKomut= gelenVeri.charAt(0);
    int gelenSifre = gelenVeri.substring(1).toInt();

    if(gelenSifre == dogruSifre){
      // EĞER TELEFONDAN 'A' KOMUTU GELİRSE (AÇ)
      if (gelenKomut == 'A') {
        garajMotoru.write(90); // Motoru 90 dereceye çevir (Kapı kalksın)
        digitalWrite(yesilLed, HIGH); // Yeşil LED'i yak
        digitalWrite(kirmiziLed, LOW); // Kırmızı LED'i söndür
        Serial.println("Garaj Kapisi Acildi!");
      } 
      // EĞER TELEFONDAN 'K' KOMUTU GELİRSE (KAPAT)
      else if (gelenKomut == 'K') {
        garajMotoru.write(0);  // Motoru eski haline (0 derece) getir
        digitalWrite(yesilLed, LOW); // Yeşil LED'i söndür
        digitalWrite(kirmiziLed, HIGH); // Kırmızı LED'i yak
        Serial.println("Garaj Kapisi Kapatildi!");
      }
    }
  }
}