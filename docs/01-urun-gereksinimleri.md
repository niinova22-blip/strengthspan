# 01 — Ürün Gereksinimleri Belgesi (PRD)

**Ürün:** Strengthspan (geçici ad) · **Kategori:** Health & Fitness · **Platform:** yalnızca iPhone (iOS 17+)
**Vaat:** *Measure your strength. Train for your future.*
**Belge durumu:** Taslak v0.1 — 27 Ekim 2026

---

## 1. Problem

45 yaş üzeri, kuvvet antrenmanına yeni başlayan veya ara verip geri dönen kullanıcılar üç sorunla karşılaşıyor:

1. **Nerede olduklarını bilmiyorlar:** Fiziksel kapasitelerinin (kuvvet, denge, mobilite) gelişip gelişmediğini ölçebilecek basit bir yolları yok.
2. **Neyi, ne kadar yapacaklarını bilmiyorlar:** Genel fitness uygulamaları genç ve deneyimli kullanıcılar için tasarlanmış; başlangıç seviyesi ve ilerleme hızı uygun değil.
3. **Motivasyonları ilerlemeyi görememekten düşüyor:** "Ağırlık/kalori" odaklı metrikler bu segmentin asıl hedefi olan *fonksiyonel bağımsızlığı* yansıtmıyor.

## 2. Çözüm ve temel döngü

```
ASSESS → UNDERSTAND → TRAIN → ADAPT → PROVE → REPEAT
 ölç      anla         çalış   uyarla   kanıtla   tekrarla
```

| Adım | Ürün karşılığı | Modül |
|---|---|---|
| Assess | Kamera destekli veya manuel kapasite değerlendirmesi | Assessment, PoseAnalysis |
| Understand | 4 boyutlu Capacity Map, açıklayıcı sonuç ekranı | Capacity |
| Train | Kişisel haftalık plan + Workout Player | Workout |
| Adapt | Deterministik progresyon motoru (RPE, tamamlanma, rahatsızlık) | Progression, Safety |
| Prove | 4 haftalık yeniden değerlendirme + önce/sonra karşılaştırması | Progress |
| Repeat | Suçlamayan tutarlılık sistemi, ara sonrası dönüş planı | Workout, Progress |

## 3. Hedef kullanıcı

**Birincil persona — "Ayşe, 52":** Masa başı çalışıyor, haftada 2–3 gün 20 dakika ayırabiliyor, evde 2 adet 3 kg dambıl ve bir direnç bandı var. Dizlerinde zaman zaman hassasiyet var. Karmaşık uygulamalardan sıkılıyor; "Ne yapacağım?" sorusuna tek dokunuşla cevap istiyor. En büyük motivasyonu: "Yaşlandığımda kimseye muhtaç olmamak."

**İkincil persona — "Murat, 58":** Eskiden spor yapmış, 5 yıldır ara vermiş. Rakam ve grafik seviyor; gelişimini kanıtlanmış biçimde görmek istiyor.

Marka dili yaş ya da cinsiyetle sınırlandırılmaz ("for women over 50" gibi dışlayıcı ifadeler kullanılmaz). Ürün 60–70 yaş segmentine genişleyebilecek şekilde tasarlanır (daha büyük dokunma alanları, sesli yönlendirme, düşük yoğunluklu varyantlar).

## 4. Ana ekran — 3 saniye kuralı

Ana ekran (Today) açıldığı anda yalnızca şunları gösterir:

1. **Bugün ne yapacağım?** → Bugünkü antrenman kartı (süre, odak, "Başla")
2. **Ne kadar ilerledim?** → Son değerlendirmeye göre kısa ilerleme özeti
3. **Sonraki değerlendirmem ne zaman?** → Tarih veya "zamanı geldi"

Veri yoksa kartlar dürüst boş durumlar gösterir ("Henüz yeterli ölçüm yok"). Sahte veya örnek veri **hiçbir zaman** üretim ekranında gösterilmez.

## 5. Fonksiyonel gereksinimler

### 5.1 Onboarding (F-ONB)
- F-ONB-1: Her ekranda tek soru; ilerleme göstergesi; geri dönülebilir.
- F-ONB-2: Toplanacak bilgiler: yaş aralığı, aktivite seviyesi, deneyim, temel hedef, haftalık gün sayısı, seans süresi (10/20/30 dk), ekipman (ekipmansız / dambıl / direnç bandı), kullanıcının bildirdiği hareket kısıtları.
- F-ONB-3: Güvenlik taraması (bkz. `05-guvenlik-risk-matrisi.md`). "Profesyonel değerlendirme önerilir" sonucu çıkarsa otomatik plan **üretilmez**; kullanıcıya sakin, korkutmayan bir yönlendirme ve sonradan güncelleyebileceği bir yol sunulur.
- F-ONB-4: Hesap açma zorunlu değildir.
- F-ONB-5: Onboarding sonunda başlangıç değerlendirmesi önerilir; kullanıcı atlayabilir.

### 5.2 Functional Capacity Assessment (F-ASM)
- F-ASM-1: MVP testleri: 30 sn Chair Stand, 5x Sit-to-Stand (süreli), 30 sn Calf Raise (destekli), destekli denge duruşu, omuz/kol kaldırma mobilitesi.
- F-ASM-2: Her test için: görsel anlatım, telefon yerleştirme talimatı, kadraj kontrolü, kullanıcı onayı, başlat/durdur/iptal, sayaç, süre, veri kalitesi kontrolü, sonuç açıklaması.
- F-ASM-3: Ölçüm hattı tamamen cihazda: Camera → Vision → Joint Landmarks → Movement Analysis → Quality Validation → Local Storage. Ham görüntü saklanmaz ve gönderilmez.
- F-ASM-4: Eklem görünürlüğü/kadraj yetersizse **sonuç üretilmez**; kullanıcıya düzeltme önerilir veya manuel moda geçiş sunulur.
- F-ASM-5: Her test atlanabilir; her test manuel olarak (kullanıcının saydığı tekrar / kronometre) yapılabilir.
- F-ASM-6: Tek ayak denge gibi düşme riski yüksek testler MVP'de yoktur.
- F-ASM-7: Sonuçlar tıbbi teşhis olarak sunulmaz; kamera doğruluğu hakkında, gerçek cihaz doğrulaması tamamlanana kadar hiçbir yüzde/kesinlik iddiası yapılmaz.

### 5.3 Capacity Map (F-CAP)
- F-CAP-1: Dört boyut: Strength, Balance, Mobility, Movement Control.
- F-CAP-2: Her boyutta: başlangıç, son ölçüm, değişim, geçmiş, güvenilirlik, grafik.
- F-CAP-3: 0–100 puanı kullanılırsa ekranda tanımı yer alır: *"Bu puan yalnızca senin kendi ölçümlerinin özetidir; bir sağlık, risk veya biyolojik yaş göstergesi değildir."*
- F-CAP-4: Yeterli geçerli ölçüm yoksa puan gösterilmez → "Henüz yeterli ölçüm yok".
- F-CAP-5: Karşılaştırma yalnızca kullanıcının kendi geçmişiyle yapılır (popülasyon normu yok — MVP).

### 5.4 Adaptive Workout Engine (F-WKT)
- F-WKT-1: Girdiler: değerlendirme, geçmiş seanslar, tamamlanma, ağırlık, tekrar, RPE, rahatsızlık, ekipman, süre, uygun günler, güvenlik kısıtları.
- F-WKT-2: Çıktı: haftalık plan → günlük seans (Warm-up, Main Strength, Balance/Movement Control, Cooldown).
- F-WKT-3: Motor **deterministik kurallarla** çalışır, sürümlenir (`generatorVersion`) ve birim testlerle kapsanır. Yapay zekâ güvenlik açısından kritik karar vermez.
- F-WKT-4: Safety Engine her plan üretiminden ve her progresyon adımından **önce** çalışır ve veto yetkisine sahiptir.

### 5.5 Today's Workout / Player (F-PLY)
- Bugünkü program, tahmini süre, hareket listesi, set/tekrar, dinlenme süresi, açıklamalar, sesli yönlendirme (AVSpeechSynthesizer), set işaretleme, egzersiz değiştirme, duraklatma, bitirme.
- Sonunda: RPE (basitleştirilmiş 1–10 ölçeği, sözel etiketli), rahatsızlık, tamamlanma, kullanılan ağırlık, kısa not.
- Rahatsızlık/risk sinyalinde progresyon durur, güvenli alternatif değerlendirilir; ciddi sinyallerde seans durdurulur ve profesyonel değerlendirme önerilir.

### 5.6 Proof of Progress (F-PRF)
- Her 28 günde yeniden değerlendirme önerisi.
- Örnek karşılaştırma: Chair Stand 11 → 15 tekrar; Calf Raise 14 → 19; tamamlanan antrenman 9/12; ağırlık 4 kg → 6 kg.
- Yüzdelik değişim yalnızca **karşılaştırılabilir** ölçümler için (aynı test, aynı protokol sürümü, aynı destek koşulu, geçerli kalite) hesaplanır.
- Paylaşılabilir kart ve PDF rapor → v1.1.

### 5.7 Consistency & Return (F-CON)
- Streak yok. Son 30 gün tutarlılığı, haftalık tamamlanma oranı, planlanan/tamamlanan.
- 7+ gün aradan sonra düşük yoğunluklu "Geri dönüş haftası" planı.
- Bildirimler davetkâr, suçlayıcı değil ("Kısa bir 10 dakikalık seans hazır" ✓ / "Serini kaybettin!" ✗).

### 5.8 HealthKit (F-HK)
- Okuma: Workouts, Step Count; Heart Rate ve Active Energy yalnızca bir özellik bunlara gerçekten ihtiyaç duyuyorsa.
- Yazma: tamamlanan seanslar `HKWorkout` (`.traditionalStrengthTraining` / `.functionalStrengthTraining`).
- İzinler bağlam içinde, özellik bazında istenir. Reddedilirse uygulama tam çalışmaya devam eder.

### 5.9 Abonelik (F-SUB)
- StoreKit 2; `Monthly Pro`, `Annual Pro`. Fiyat varsayımı $12.99 / $69.99 (kesin değil, App Store Connect'ten okunur).
- Deneme (App Store Connect'te 2 hafta olarak yapılandırıldı; bkz. §10) yalnızca `isEligibleForIntroOffer` doğruysa gösterilir. Süre metni koddan değil `Product.subscription?.introductoryOffer` değerinden üretilir.
- Paywall: değer önerisi, gerçek fiyatlar (`Product.displayPrice`), yenileme koşulları, Restore, Manage Subscription, Privacy Policy, Terms of Use.

### 5.10 Ayarlar, gizlilik, yerelleştirme
- Tüm kişisel verileri silme (Faz 1'de mevcut), JSON dışa aktarma (Faz 6).
- English + Türkçe, String Catalog; birimler/tarihler yerel ayara göre.

## 6. Free / Pro ayrımı

| Özellik | Free | Pro |
|---|:-:|:-:|
| Onboarding + güvenlik taraması | ✓ | ✓ |
| İlk değerlendirme | ✓ | ✓ |
| Başlangıç Capacity Map | ✓ | ✓ |
| Sınırlı örnek antrenman (3 sabit seans) | ✓ | ✓ |
| Kişisel haftalık plan + adaptif progresyon | | ✓ |
| 4 haftalık yeniden değerlendirme + karşılaştırma | | ✓ |
| Gelişim grafikleri ve geçmiş | | ✓ |
| Ekipman adaptasyonu, tam kütüphane | | ✓ |
| HealthKit entegrasyonu | | ✓ |
| Güvenlik özellikleri (durdurma, uyarılar, veri silme) | ✓ | ✓ |

**İlke:** Güvenlikle ilgili hiçbir özellik paywall arkasında değildir.

## 7. MVP ve sonraki sürümler

| Özellik | MVP (v1.0) | v1.1 | v1.2+ |
|---|:-:|:-:|:-:|
| Onboarding + güvenlik taraması | ✓ | | |
| Manuel değerlendirme (tüm testler) | ✓ | | |
| Kamera değerlendirmesi: Chair Stand, 5x STS | ✓ | | |
| Kamera değerlendirmesi: Calf Raise, mobilite | Beta (manuel varsayılan) | ✓ | |
| Destekli denge (zamanlayıcı + kamera varlık kontrolü) | ✓ | | |
| Capacity Map (4 boyut) | ✓ | | |
| Deterministik plan + progresyon | ✓ | | |
| Workout Player + sesli yönlendirme | ✓ | | |
| Proof of Progress (28 gün) | ✓ | | |
| Tutarlılık + geri dönüş planı | ✓ | | |
| StoreKit 2 abonelik | ✓ | | |
| HealthKit okuma/yazma | ✓ | | |
| EN + TR | ✓ | | |
| Paylaşılabilir ilerleme kartı, PDF rapor | | ✓ | |
| Widget (bugünkü seans) | | ✓ | |
| iCloud senkronizasyonu (CloudKit, isteğe bağlı) | | | ✓ |
| Apple Watch tamamlayıcı (bağımsız değil) | | | ✓ |
| Ek diller (DE, ES) | | | ✓ |

## 8. Ürün metrikleri

**North Star:** *Monthly Capacity Reassessment Rate* — son 28 günde yeniden değerlendirmesi "vadesi gelmiş" kullanıcılar içinde, vade tarihinden itibaren 7 gün içinde yeniden değerlendirmeyi tamamlayanların oranı.

| Metrik | Tanım |
|---|---|
| Onboarding Completion | Onboarding'i başlatıp bitirenler / başlatanlar |
| First Assessment Completion | İlk 7 günde ≥1 geçerli değerlendirme tamamlayan |
| First Workout Completion | İlk 7 günde ≥1 seans tamamlayan |
| Week 1 Activation | İlk 7 günde değerlendirme + ≥2 seans |
| Week 4 Retention | 22–28. günlerde ≥1 seans |
| Second Assessment Completion | 2. değerlendirmeyi tamamlayan |
| Trial / Paid Conversion, Renewal, Churn | App Store Connect + StoreKit verisi |

**Gizlilik kuralı:** Ölçüm değerleri, sağlık yanıtları ve HealthKit verileri hiçbir analitik servisine gönderilmez. Yalnızca olay sayıları (ör. `assessment_completed`) gönderilir. MVP'de bunun için App Store Connect Analytics yeterlidir; üçüncü taraf SDK eklenmez. Gerekirse v1.1'de kullanıcı onayıyla, toplulaştırılmış ve kimliksiz bir uç nokta değerlendirilir.

## 9. Kapsam dışı (v1.0)

Android, web, iPad'e özel arayüz, bağımsız Watch uygulaması, sosyal akış, AI sohbet botu, beslenme/kalori takibi, rehabilitasyon protokolleri, popülasyon normlarıyla kıyaslama, biyolojik yaş tahmini.

## 10. Kararlar (27 Ekim 2026)

| Konu | Karar |
|---|---|
| Derleme | GitHub Actions (`.github/workflows/ios.yml`, macos-15, Xcode latest-stable) |
| Klinik inceleme | Ürün sahibi tarafından **şimdilik ertelendi**. Güvenlik kuralları muhafazakâr varsayılanlarla uygulanır; yayın öncesi inceleme hâlâ önerilir |
| Bundle ID / Team | `com.strengthspan.app` (HealthKit ve In-App Purchase açık) · Team `ML3UZXMU3D` |
| App Store Connect | Uygulama kaydı "Strengthspan" (Apple ID 6827702773, SKU `strengthspan-ios`, birincil dil EN-US) |
| Yasal sayfalar | GitHub Pages: `/privacy.html`, `/terms.html` (Apple Standart EULA + ek koşullar), `/support.html` |
| Abonelik grubu | "Strengthspan Pro" (ID 22520215) |
| Ürünler | `com.strengthspan.app.pro.annual` (1 yıl, $69.99) · `com.strengthspan.app.pro.monthly` (1 ay, $12.99) · 175 ülke, fiyatlar ülkelere otomatik dağıtıldı |
| Deneme | **2 hafta ücretsiz** (her iki ürün, 27 Ekim 2026'dan itibaren, bitiş yok). App Store Connect 21 günlük süre sunmuyor (3 gün, 1 hafta, 2 hafta, 1 ay…); 21 güne en yakın seçenek 2 haftadır (7 gün fark; 1 ay 9–10 gün fark) |

Faz 5'te tamamlanacaklar: abonelik görünen ad/açıklama yerelleştirmeleri (EN/TR), inceleme ekran görüntüsü, ilk abonelik grubunun uygulama sürümüyle birlikte incelemeye gönderilmesi.
