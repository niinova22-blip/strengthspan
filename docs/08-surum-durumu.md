# 08 — Sürüm Durumu ve Doğrulama Raporu (v1.0, TestFlight öncesi)

Son güncelleme: 28 Ekim 2026. Kaynak: GitHub Actions `iOS Build` (macos-15, Xcode 26.3, iPhone simülatörü).

## 1. Otomatik doğrulananlar (her push'ta)

| Kontrol | Sonuç |
|---|---|
| Derleme (Debug simülatör + imzasız Release cihaz) | ✅ Swift uyarısı 0 (strict concurrency `complete`) |
| Birim testleri (Swift Testing) | ✅ 112 test: güvenlik, tarama, progresyon, plan üretici, katalog, poz analizi, kalite kapısı, karşılaştırılabilirlik, tutarlılık, abonelik yetkisi, kalıcılık, veri silme, dışa aktarma, yerelleştirme |
| UI testleri (XCTest) | ✅ Onboarding → plan; antrenmanın güvenli şekilde durdurulması; ilk değerlendirmenin ücretsiz olması, ikincisinin paywall'a gitmesi; Türkçe açılış |
| Erişilebilirlik denetimi (`performAccessibilityAudit`) | Welcome, Today, Progress, Settings, antrenman check-in ve hareket ekranlarında. Dokunma alanı, kesilen metin, etiket ve kontrast. Yanlış alarm filtreleri test kodunda gerekçeleriyle yazılı |
| Gizlilik koruması (`scripts/check-privacy.sh`) | ✅ Ağ isteği yok, analitik/reklam/izleme SDK'sı yok, kamera görüntüsü diske yazılmıyor, Apple Sağlık'tan okuma yok, `NSPrivacyTracking = false` |
| Yerelleştirme | ✅ EN/TR anahtar setleri eşit. Çalışma zamanında üretilen tüm anahtarlar (egzersiz, test, seçenek, tarama) iki dilde de mevcut |

Domain kodu (güvenlik, plan, progresyon, poz analizi, karşılaştırma, abonelik kuralları) ayrıca Windows'taki Swift 6.4 araç zincirinde de derlenip test edildi (74 test).

## 2. Gerçek cihaz gerektirenler 🔵 (TestFlight ile)

| Konu | Neden simülatörde test edilemez | Nasıl doğrulanacak |
|---|---|---|
| Kamera ile Chair Stand / 5x STS sayımı | Simülatörde kamera yok | docs/04 §5 protokolü: 10+ kişi, video ile manuel sayıma karşı karşılaştırma, hedef: denemelerin %90'ında hata ≤ 1 tekrar |
| Omuz fleksiyonu (beta) | Aynı | Gonyometre ile karşılaştırma. O zamana kadar güvenilirlik en fazla "moderate" ve "beta" etiketiyle gösteriliyor |
| Vision performansı ve ısınma | Neural Engine yok | A12/A13 cihazda 60 sn test, analiz ≥ 10 Hz |
| StoreKit gerçek satın alma | CI'da StoreKit yapılandırması yok | TestFlight'ta Sandbox hesabıyla deneme ve satın alma, Restore, Manage |
| Apple Sağlık'a yazma | Simülatörde HealthKit kısıtlı | Pro + izin → antrenman → Sağlık › Antrenmanlar |
| VoiceOver ile tam seans | Otomatik denetim kapsamı sınırlı | Gerçek cihazda bir seansı VoiceOver ile tamamlama |
| Sesli yönlendirme | Ses çıkışı | Cihazda EN ve TR sesle |
| Uygulama arka plandayken seans | Zamanlayıcı ve dinlenme sayacı sıfırlanır (bilinen sınırlama) | Kabul edilebilirliğini cihazda değerlendir |

## 3. Bilinen sınırlamalar (v1.0)

- Calf Raise ve destekli denge testleri yalnızca elle ölçülüyor (docs/04'teki karar: topuk noktası yok, düşme riski).
- Kapasite haritası 0–100 puan yerine gerçek test değerlerini gösteriyor. Uydurma bir ölçek kullanılmıyor.
- Free kullanıcı: ilk değerlendirme, 3 örnek antrenman ve başlangıç değerleri. Güvenlik özellikleri hiçbir zaman kilitli değil.
- Klinik inceleme ürün sahibinin kararıyla ertelendi. Tarama soruları ve metinler yayın öncesinde bir uzmana gösterilmeli (docs/05).

## 4. App Store'a göndermeden önce elle yapılacaklar

1. App Store Connect › abonelikler: görünen ad ve açıklama (EN/TR) ile inceleme ekran görüntüsü.
2. App Privacy formu: "Data Not Collected" (uygulama veri toplamıyor; StoreKit Apple tarafından işleniyor).
3. Ekran görüntüleri (6.9" ve 6.5"), açıklama, anahtar kelimeler, Support URL, Privacy Policy URL.
4. Yaş derecelendirmesi anketi ve kategori (Health & Fitness).
5. İlk abonelik grubunu 1.0 sürümüyle birlikte incelemeye gönderme.
