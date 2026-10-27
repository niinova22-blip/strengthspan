# 07 — Test Stratejisi

## 1. Test piramidi

| Katman | Araç | Kapsam | Nerede koşar |
|---|---|---|---|
| Birim (domain) | Swift Testing | SafetyEngine, PlanGenerator, Progression, ReassessmentPolicy, CapacityScoring, karşılaştırılabilirlik, tekrar sayıcılar (fixture ile) | Simülatör / CI. Saf Swift olduğu için macOS veya Windows `swift test` ile de koşabilir |
| Birim (kalıcılık) | Swift Testing + in-memory `ModelContainer` | Şema yüklenmesi, ilişkiler, cascade silme, veri silme, migrasyon | Simülatör |
| Yerelleştirme | Swift Testing | EN ve TR anahtar setleri eşit; boş veya çevrilmemiş değer yok | Simülatör |
| Snapshot / önizleme | Xcode Previews (manuel) | Light/Dark, AX5, TR | Geliştirici makinesi |
| UI | XCTest (`XCUIApplication`) | Duman testi, onboarding, seans, paywall (StoreKit Test) | Simülatör |
| Gerçek cihaz 🔵 | Manuel test protokolü + Instruments | Kamera, Vision, performans, HealthKit, satın alma, VoiceOver | Fiziksel iPhone |

## 2. İlkeler
- **Deterministik:** Zaman `AppClock` ile, takvim parametre olarak verilir. Rastgelelik gerekiyorsa tohumlu üreteç kullanılır. Ağ bağımlılığı yoktur.
- **İzole:** Her test kendi in-memory container'ını oluşturur. UI testleri `-ui-testing` argümanıyla başlar, bu argüman uygulamayı in-memory store ile açar.
- **Güvenlik kuralları için tablo tabanlı testler:** `@Test(arguments:)` ile 05 §4'teki her kural ve sınır değeri kapsanır.
- **Kamera mantığı kamerasız test edilir:** Vision çıktısı `PoseFrame` değer tipine çevrilir. Gerçek cihazdan kaydedilen anonim eklem dizileri (görüntü değil, yalnızca sayılar) fixture olarak kullanılır.
- **Test edilmemiş = test edilmiş değil:** Her faz raporu hangi testlerin nerede koştuğunu ve hangi kriterlerin gerçek cihaz beklediğini açıkça yazar.

## 3. Faz 1'de var olan testler

| Dosya | Ne doğruluyor |
|---|---|
| `PersistenceTests.swift` | V1 şeması tüm modellerle yükleniyor; profil → tercih/kısıt round-trip; profil silinince cascade; seans silinince set ve geri bildirimin silinmesi |
| `PersonalDataEraserTests.swift` | Tüm model türlerinden kayıtlar silindikten sonra sayımların sıfır olması |
| `ReassessmentPolicyTests.swift` | Hiç değerlendirme yok → `neverAssessed`; 10 gün önce → 18 gün kaldı; 28+ gün → `due`; gün sınırı (gece yarısı) davranışı |
| `DomainTypesTests.swift` | Kalıcı raw değerlerin değişmemesi (migrasyon güvenliği) |
| `LocalizationTests.swift` | Derlenmiş EN ve TR `Localizable.strings` anahtar setlerinin eşitliği; TR değerlerin boş olmaması |
| `StrengthspanUITests.swift` | Uygulama açılıyor, 3 sekme var, sekmeler arasında gezinilebiliyor |

## 4. Komutlar

```bash
# Proje üretimi (bir kez ve project.yml her değiştiğinde)
xcodegen generate

# Tüm testler
xcodebuild test -project Strengthspan.xcodeproj -scheme Strengthspan \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Yalnızca birim testleri
xcodebuild test -project Strengthspan.xcodeproj -scheme Strengthspan \
  -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:StrengthspanTests
```

## 5. CI (Faz 2'de kurulacak)
GitHub Actions `macos-15` runner'ı kullanılacak: `brew install xcodegen` → `xcodegen generate` → `xcodebuild test`. PR'lar test geçmeden birleştirilmeyecek.
