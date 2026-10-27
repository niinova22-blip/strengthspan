# Strengthspan (iOS)

*Measure your strength. Train for your future.*

45+ yaş kullanıcıların kuvvet, denge, mobilite ve hareket kontrolünü ölçen, kişisel antrenman planı oluşturan ve gelişimi kanıtlayan bir iPhone uygulaması. Yalnızca iOS 17+ ve iPhone için.

## Belgeler (`docs/`)

| # | Belge |
|---|---|
| 01 | [Ürün gereksinimleri (PRD), MVP ve sonraki sürümler, metrikler](docs/01-urun-gereksinimleri.md) |
| 02 | [Teknik mimari, klasör yapısı, SwiftData şeması](docs/02-teknik-mimari.md) |
| 03 | [Kullanıcı akışları ve design system](docs/03-ux-akislari-ve-tasarim-sistemi.md) |
| 04 | [Assessment fizibilitesi ve cihaz uyumluluk matrisi](docs/04-assessment-fizibilite.md) |
| 05 | [Safety Engine ve risk matrisi](docs/05-guvenlik-risk-matrisi.md) |
| 06 | [90 günlük plan ve faz kabul kriterleri](docs/06-yol-haritasi-ve-kabul-kriterleri.md) |
| 07 | [Test stratejisi](docs/07-test-stratejisi.md) |

## Derleme (GitHub Actions)

Her `main` push'unda ve PR'da `.github/workflows/ios.yml` çalışır: XcodeGen → birim + UI testleri (simülatör) → imzasız Release cihaz derlemesi. Yerel Mac gerekmez.

## Yayın bilgileri

| | |
|---|---|
| Bundle ID | `com.strengthspan.app` · Team `ML3UZXMU3D` |
| App Store Connect | Strengthspan (Apple ID 6827702773) |
| Abonelikler | `com.strengthspan.app.pro.monthly` · `com.strengthspan.app.pro.annual` (grup 22520215, 2 hafta ücretsiz deneme) |
| StoreKit test | `StoreKit/Strengthspan.storekit` (Run şemasına bağlı) |
| Yasal sayfalar | [Gizlilik](https://niinova22-blip.github.io/strengthspan/privacy.html) · [Koşullar](https://niinova22-blip.github.io/strengthspan/terms.html) · [Destek](https://niinova22-blip.github.io/strengthspan/support.html) — kaynak: `docs/*.html` |

## TestFlight

`.github/workflows/testflight.yml` elle tetiklenir (Actions › TestFlight › Run workflow). Her çalışma:

1. App Store Connect API ile **bu çalışmaya özel** bir Apple Distribution sertifikası ve App Store profili oluşturur (`scripts/asc_signing.py`).
2. Arşivler, imzalar, imzayı doğrular ve `altool` ile yükler.
3. "Strengthspan Internal" iç test grubunu (tüm build'lere erişimli, ekip üyeleri eklenmiş) hazırlar.
4. Çalışma sonunda profili siler, sertifikayı iptal eder. Repoda imzalama malzemesi saklanmaz.

Gereken repo secret'ları (bir kez):

```bash
gh secret set ASC_KEY_ID      -R niinova22-blip/strengthspan --body "<Key ID>"
gh secret set ASC_ISSUER_ID   -R niinova22-blip/strengthspan --body "<Issuer ID>"
gh secret set ASC_PRIVATE_KEY -R niinova22-blip/strengthspan < /yol/AuthKey_<Key ID>.p8
gh workflow run testflight.yml -R niinova22-blip/strengthspan
```

Anahtarın App Store Connect › Users and Access › Integrations altında **Admin** rolünde olması gerekir (sertifika ve profil oluşturmak için).

## Yerel geliştirme (isteğe bağlı, Mac)

- macOS + **Xcode 16 veya üzeri** (Swift Testing ve `@Entry` makrosu için)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

`.xcodeproj` dosyası depoda tutulmaz. `project.yml` dosyasından üretilir.

## Çalıştırma

```bash
xcodegen generate            # Strengthspan.xcodeproj oluşturur
open Strengthspan.xcodeproj  # Strengthspan şemasını seç → iPhone simülatörü → Run (⌘R)
```

Gerçek cihazda çalıştırmak için Xcode'da *Signing & Capabilities* altından kendi Team'ini seç. Gerekirse `PRODUCT_BUNDLE_IDENTIFIER` değerini değiştir.

## Test

```bash
xcodebuild test -project Strengthspan.xcodeproj -scheme Strengthspan \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Xcode'da ⌘U. UI testleri uygulamayı `-ui-testing` argümanıyla başlatır. Bu argüman uygulamanın boş, in-memory bir veritabanıyla açılmasını sağlar.

## Yerelleştirme

Metinler `Strengthspan/Resources/Localizable.xcstrings` (EN + TR) dosyasında tutulur. Bu dosya şimdilik `Tools/generate_strings.py` ile üretiliyor. Yeni metin eklerken tabloya ekle ve `python Tools/generate_strings.py` komutunu çalıştır. `LocalizationTests` iki dilin anahtar setlerinin aynı kalmasını denetler.

## Faz 1 durumu

Ayrıntılı kabul kriterleri için [docs/06](docs/06-yol-haritasi-ve-kabul-kriterleri.md) belgesine bakın. Neyin doğrulandığı ve neyin henüz doğrulanmadığı en son teslim raporunda yazıyor.
