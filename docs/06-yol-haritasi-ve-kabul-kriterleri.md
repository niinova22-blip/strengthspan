# 06 — İlk 90 Günlük Geliştirme Planı ve Kabul Kriterleri

Plan, 13 hafta boyunca tek bir iOS geliştiricinin (AI destekli) tam zamanlı çalıştığını varsayar. Sürelere ~%20 tampon dahildir.

## 1. Zaman çizelgesi

| Hafta | Faz | Ana çıktılar |
|---|---|---|
| 1 | **P1 Foundation** | XcodeGen projesi, mimari, design system, navigasyon, String Catalog (EN/TR), SwiftData V1, DI, test altyapısı, veri silme ✅ *(bu teslimat)* |
| 2–3 | **P2 Core (a)** | Onboarding + güvenlik taraması, UserProfile, egzersiz kataloğu (JSON, ~30 hareket × varyant), SafetyEngine v1 |
| 4–5 | **P2 Core (b)** | PlanGenerator v1, Workout Player, sesli yönlendirme, geri bildirim, Progression v1, Today kartları |
| 6–8 | **P3 Assessment** | Kamera izni ve önizleme, Vision hattı, QualityGate, Chair Stand ve 5x STS analizörleri, manuel mod, değerlendirme geçmişi, **gerçek cihaz doğrulaması** |
| 9 | **P4 Progress** | Capacity Map, Swift Charts, karşılaştırılabilirlik kuralları, 28 gün yeniden değerlendirme, önce/sonra, tutarlılık görünümü, geri dönüş haftası |
| 10–11 | **P5 Monetization** | StoreKit 2, `.storekit` test dosyası, paywall, entitlement servisi, Free/Pro kapıları, Restore/Manage |
| 12–13 | **P6 Release** | HealthKit, erişilebilirlik denetimi, yerelleştirme incelemesi, performans, gizlilik denetimi + Privacy Manifest, JSON dışa aktarma, UI testleri, TestFlight (iç + 10–20 dış test kullanıcısı), App Store materyalleri |

Klinik inceleme (güvenlik soruları ve metinleri) **4. haftada** başlatılmalı. Sonuçları 12. haftaya kadar entegre edilmeli.

## 2. Kabul kriterleri

Bir faz, bu kriterlerin tamamı karşılanmadan "bitti" sayılmaz. 🔵 ile işaretli kriterler **gerçek cihaz** gerektirir.

### P1 — Foundation
- [ ] `xcodegen generate` hatasız çalışıyor; proje Xcode 16+ ile **uyarısız** derleniyor (strict concurrency uyarıları dahil)
- [ ] Uygulama simülatörde açılıyor; 3 sekme görünüyor; her sekmede dürüst boş durum var (sahte veri yok)
- [ ] Light/Dark, Increase Contrast ve en büyük Dynamic Type boyutunda metin kesilmiyor
- [ ] Cihaz dili Türkçe olduğunda tüm metinler Türkçe görünüyor; hiçbir ekranda ham anahtar (`today.title`) görünmüyor
- [ ] SwiftData V1 şeması in-memory ve diskte açılıyor; `MigrationPlan` tanımlı
- [ ] "Tüm verilerimi sil" tüm modelleri siliyor (test ile kanıtlı)
- [ ] Tüm birim testleri ve UI duman testi geçiyor

### P2 — Core Product
- [ ] Onboarding 2 dakikadan kısa sürede tamamlanabiliyor (5 kişiyle hızlı kullanılabilirlik testi)
- [ ] Herhangi bir 🔴 tarama yanıtı plan üretimini engelliyor (birim test)
- [ ] PlanGenerator aynı girdiye her zaman aynı çıktıyı veriyor (deterministik test); ekipman ve süre kısıtlarına uyuyor (10/20/30 dk ± %15)
- [ ] SafetyEngine kural tablosundaki (05 §4) her kural için en az bir pozitif ve bir negatif test var
- [ ] Workout Player: duraklatma, değiştirme, bitirme, "kendimi iyi hissetmiyorum" çalışıyor; uygulama arka plana alınınca seans durumu korunuyor
- [ ] Geri bildirim kaydediliyor ve bir sonraki planın girdisi oluyor (entegrasyon testi)
- [ ] VoiceOver ile bir seans baştan sona tamamlanabiliyor 🔵

### P3 — Assessment
- [ ] Kamera izni reddedildiğinde manuel mod sunuluyor; uygulama çökmüyor
- [ ] Kadraj/eklem görünürlüğü yetersizken ölçüm başlamıyor; ölçüm sırasında bozulursa sonuç üretilmiyor
- [ ] Analizörler kaydedilmiş fixture'larla birim testten geçiyor (simülatör gerektirmez)
- [ ] Hiçbir görüntü karesi diske yazılmıyor ve ağa gönderilmiyor (kod incelemesi + ağ izleme) 🔵
- [ ] Doğrulama protokolü (04 §5) tamamlandı ve raporlandı 🔵
- [ ] A12/A13 cihazda analiz ≥ 10 Hz, 60 sn testte termal uyarı yok 🔵

### P4 — Progress
- [ ] Yetersiz veride puan yerine "Henüz yeterli ölçüm yok" gösteriliyor (test)
- [ ] Karşılaştırılamayan ölçümler (farklı yöntem, protokol sürümü veya destek) yüzde değişime katılmıyor (test)
- [ ] 28. günde Today kartı yeniden değerlendirme öneriyor (`ReassessmentPolicy` testi ✅)
- [ ] Grafikler VoiceOver'da Audio Graph / açıklama ile erişilebilir

### P5 — Monetization
- [ ] Fiyatlar `Product.displayPrice` ile gösteriliyor; kodda sabit fiyat yok
- [ ] Deneme teklifi yalnızca `isEligibleForIntroOffer == true` ise gösteriliyor
- [ ] Restore, Manage Subscription, Privacy Policy ve Terms linkleri çalışıyor
- [ ] Entitlement yalnızca doğrulanmış (`.verified`) işlemlerle veriliyor; iade, iptal ve süre dolumu test ediliyor (StoreKit Test)
- [ ] Güvenlik özellikleri Free kullanıcıda da çalışıyor
- [ ] Sandbox hesabıyla gerçek satın alma akışı 🔵

### P6 — Release
- [ ] HealthKit: her izin ayrı isteniyor; reddedilince uygulama tam çalışıyor; seans `HKWorkout` olarak yazılıyor 🔵
- [ ] Accessibility Inspector denetimi: kritik bulgu yok
- [ ] TR çeviriler yerel bir konuşmacı tarafından gözden geçirildi; uzun Türkçe metinler kesilmiyor
- [ ] Privacy Manifest ve App Store "Nutrition Label" kodla tutarlı
- [ ] JSON dışa aktarma tüm kullanıcı modellerini içeriyor (test)
- [ ] Soğuk açılış < 1 sn (iPhone 12 sınıfı) 🔵; Instruments'ta sızıntı yok 🔵
- [ ] TestFlight: 2 hafta, çökme oranı < %0.5, kritik güvenlik geri bildirimi yok 🔵
