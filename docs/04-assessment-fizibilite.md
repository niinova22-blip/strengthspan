# 04 — Assessment Teknik Fizibilitesi ve Cihaz Uyumluluk Matrisi

> **Önemli:** Bu belgedeki fizibilite değerlendirmeleri API kabiliyetlerine ve mühendislik tahminine dayanır. **Hiçbiri gerçek cihazda ölçülmüş bir doğruluk değeri değildir.** Gerçek doğruluk Faz 3'te tanımlanan doğrulama protokolüyle ölçülecek. O zamana kadar uygulama içinde doğruluk iddiası yapılmaz.

## 1. Ölçüm hattı

```
AVCaptureSession (ön/arka kamera, 1280×720, 30 fps)
  → AVCaptureVideoDataOutput (alwaysDiscardsLateVideoFrames = true)
  → VNDetectHumanBodyPoseRequest (her 2. kare ≈ 15 Hz)
  → PoseFrame (19 eklem, normalize 2D nokta + confidence, zaman damgası)   ← Sendable struct
  → QualityGate (kadraj, eklem güveni, ışık, kişi sayısı)
  → MovementAnalyzer (teste özel durum makinesi: açı/yükseklik sinyali → tekrar)
  → AssessmentResult (değer + reliability + qualityFlags)  → SwiftData
```
- Görüntü kareleri (`CVPixelBuffer`) yalnızca bellekte işlenir. Hiçbir kare diske yazılmaz veya ağa gönderilmez.
- iOS 17 minimum hedef olduğu için klasik `VNDetectHumanBodyPoseRequest` API'si kullanılır. iOS 18'in Swift-native `DetectHumanBodyPoseRequest` API'si minimum sürüm yükseltildiğinde değerlendirilecek.
- `VNDetectHumanBodyPose3DRequest` (iOS 17+) daha ağır bir API ve gerçek zamanlı kullanım için uygun olup olmadığı belirsiz. MVP'de kullanılmayacak, yalnızca deney olarak denenecek.

### Vision eklemleri ve sınırlar
Vision 2D body pose şu noktaları verir: burun, gözler, kulaklar, boyun, omuzlar, dirsekler, bilekler, kök (pelvis), kalçalar, dizler, ayak bilekleri. **Topuk ve ayak ucu noktası yoktur.** Bu sınır Calf Raise ölçümünü doğrudan etkiliyor.

## 2. Test bazında fizibilite

| Test | Sinyal | Kamera konumu | Fizibilite | MVP kararı |
|---|---|---|---|---|
| **30 sn Chair Stand** | Kalça–diz–ayak bileği açısı (oturma ≈ 90°, ayakta ≈ 170°) + kalça yüksekliği | Yan profil, 2–3 m, bel hizasında, dikey | **Yüksek.** Büyük açı değişimi, belirgin iki durum | Kamera + manuel |
| **5x Sit-to-Stand (süreli)** | Aynı sinyal; 5. tam kalkışta süre durur | Aynı | **Yüksek** | Kamera + manuel |
| **30 sn Calf Raise (destekli)** | Ayak bileği/kalça dikey yer değiştirmesi (≈ 4–8 cm) | Yan profil, ayak hizasına yakın, 1.5–2 m | **Orta-düşük.** Küçük genlik, topuk noktası yok, destek tutan elin gövdeyi örtme riski | Manuel varsayılan, kamera **beta** |
| **Destekli denge duruşu** (tandem/yarı-tandem, sandalye desteğiyle, max 30 sn) | Süre + gövde orta noktası salınımı (yalnızca kalite bilgisi) | Önden, 2–3 m | Zamanlayıcı: **yüksek**. Salınımın skor olarak kullanılması: **düşük** (doğrulanmadı) | Kamera yalnızca varlık/kadraj kontrolü yapar. Ölçüm süre üzerinden |
| **Kol kaldırma mobilitesi** (omuz fleksiyonu) | Kalça–omuz–bilek açısı | Yan profil, 2 m | **Orta-yüksek** (tek düzlem, büyük eklemler) | Kamera + manuel ("kolun kulağına değdi mi?") |

### Tekrar sayımı (Chair Stand örneği)
1. Açı sinyali hareketli medyan filtresiyle yumuşatılır (pencere 5).
2. Durum makinesi iki eşikle (histerezis) çalışır: `seated` (açı < 110°) → `standing` (açı > 155°) → `seated`. Bir tam döngü bir tekrar sayılır.
3. Minimum tekrar süresi 0.6 sn. Bundan daha hızlı geçişler gürültü kabul edilip atılır.
4. Eşikler, ilk gerçek cihaz veri setiyle kalibre edilecek sabit parametrelerdir (`ChairStandAnalyzer.Configuration`). Birim testler kaydedilmiş `PoseFrame` dizileriyle (fixture) çalışır, bu yüzden kamera gerektirmez.

## 3. Kalite kapısı (QualityGate) — sonuç üretmeme kuralları

| Kontrol | Eşik (başlangıç) | Başarısızlıkta |
|---|---|---|
| Gerekli eklem güveni | Kalça, diz, ayak bileği (tek taraf) ≥ 0.3 | Kare geçersiz |
| Geçerli kare oranı | Test süresince ≥ %85 | **Sonuç üretilmez** |
| Kadraj | Gerekli eklemler normalize 0.05–0.95 aralığında | Ölçüm başlamaz / duraklar |
| Kişi sayısı | Tam 1 gözlem | Ölçüm başlamaz |
| Kamera hareketi | Ayak bileği konumunda ani sıçrama | `cameraMoved` bayrağı, sonuç reddedilir |
| Işık | Ortalama luma < eşik (deneysel) | Uyarı + kalite bayrağı |

Reliability eşleme: `high` (≥ %95 geçerli kare, uyarı yok), `moderate` (%85–95), `low` (uyarılı ama sayım tutarlı), `insufficient` (sonuç yok). `low` sonuçlar Capacity Map'te gösterilir ama **karşılaştırma ve yüzde hesabına katılmaz**.

## 4. Cihaz uyumluluk matrisi

iOS 17, iPhone XS / XR (A12) ve sonrasını destekler. Bu cihazların hepsinde Neural Engine bulunduğu için Vision body pose çalışır.

| Cihaz grubu | Çip | Vision 2D pose | Beklenen performans (tahmin) | Not |
|---|---|---|---|---|
| iPhone XS / XS Max / XR | A12 | ✓ | Orta — 10–15 Hz analiz hedefi | En düşük performanslı hedef cihaz. **Doğrulama zorunlu** |
| iPhone SE (2. ve 3. nesil) | A13 / A15 | ✓ | İyi | Küçük ekran → talimat yerleşimini 4.7" ekranda test et |
| iPhone 11 serisi | A13 | ✓ | İyi | |
| iPhone 12–13 serisi | A14–A15 | ✓ | Çok iyi | Pro modellerde LiDAR (MVP'de kullanılmıyor) |
| iPhone 14–17 serisi | A15–A19 | ✓ | Çok iyi | |
| Simülatör | — | Kamera **yok** | — | Kamera akışı simülatörde test edilemez. Fixture tabanlı birim testler + manuel mod kullanılır |

**Gerçek cihaz test listesi (Faz 3, zorunlu):** en az 1 × A12/A13 cihaz, 1 × SE (küçük ekran), 1 × güncel Pro.

## 5. Doğrulama protokolü (Faz 3 kabulü için)

1. 10+ gönüllü (mümkünse 45+ yaş). Her biri her testi 2 kez yapar. Kamera sayımı, video izlenerek yapılan manuel sayım (altın standart) ile karşılaştırılır. Video yalnızca gönüllünün yazılı onayıyla ve uygulama dışında kaydedilir.
2. Metrikler: tekrar sayısında mutlak hata, |hata| ≤ 1 olan denemelerin oranı, QualityGate ret oranı.
3. **Yayın eşiği (öneri):** Chair Stand için denemelerin ≥ %90'ında |hata| ≤ 1. Eşik karşılanmazsa ilgili test kamera modunda "beta" etiketiyle kalır veya yalnızca manuel olarak sunulur.
4. Sonuçlar `docs/` altında raporlanır. Uygulama içi metinlerde yine sayısal doğruluk iddiası yapılmaz.

## 6. Manuel mod (her cihazda)
- Kronometre + büyük "+1" butonu (kullanıcı sayar) veya test sonunda sayı girişi.
- Sonuç `method = manual` olarak saklanır. Kamera ve manuel sonuçlar **ayrı seriler** olarak tutulur ve birbiriyle karşılaştırılmaz.
