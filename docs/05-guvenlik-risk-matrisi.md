# 05 — Safety Engine ve Risk Matrisi

> Strengthspan bir **fitness ve genel wellness** uygulamasıdır. Tanı koymaz, tedavi önermez, tıbbi cihaz değildir. Bu belgedeki kurallar deterministiktir. Yapay zekâya devredilmez. Yayın öncesinde bir klinik uzman (fizyoterapist veya spor hekimi) tarafından **gözden geçirilmelidir**.

## 1. Mimari ilke

```
Kullanıcı girdisi ──► SafetyEngine.evaluate(context) ──► SafetyDecision
                                                    ├─ .proceed
                                                    ├─ .proceedWithModifications([…])   (ör. progresyonu dondur, varyantı düşür)
                                                    ├─ .pauseProgression(reason)
                                                    └─ .stopAndRecommendProfessional(reason)
PlanGenerator / Progression ──► öneri ──► SafetyEngine (veto) ──► kullanıcı
```
- SafetyEngine saf Swift'tir, `Sendable`'dır ve %100 birim test kapsamı hedeflenir.
- Kurallar sürümlüdür (`safetyRulesVersion`). Her karar, gerekçesiyle birlikte yerelde loglanır (kullanıcı ayarlardan görebilir).
- **En kısıtlayıcı karar kazanır.**

## 2. Onboarding güvenlik taraması (taslak — klinik inceleme gerekli)

Genel kabul görmüş egzersiz öncesi tarama yaklaşımlarından esinlenilmiş evet/hayır soruları:

| # | Soru (özet) | "Evet" ise |
|---|---|---|
| S1 | Bir sağlık profesyoneli yalnızca gözetim altında egzersiz yapmanı söyledi mi? | 🔴 Profesyonel görüş önerisi, plan üretilmez |
| S2 | Fiziksel aktivite sırasında göğüs ağrısı veya baskı hissediyor musun? | 🔴 |
| S3 | Son 12 ayda baş dönmesi nedeniyle dengeni kaybettin mi ya da bayıldın mı? | 🔴 |
| S4 | Son 3 ay içinde ameliyat oldun ya da ciddi bir yaralanma geçirdin mi? | 🔴 |
| S5 | Son 12 ayda düştün mü? | 🟠 Denge testleri yalnızca destekli. Plan muhafazakâr başlar |
| S6 | Hareketle kötüleşen eklem veya sırt ağrın var mı? (bölge seçimi) | 🟠 Bölgeye ait `SafetyConstraint` oluşur. İlgili hareketler düşük yüklü varyanta geçer |
| S7 | Hareketini kısıtlayan bilinen bir durum var mı? (serbest seçim) | 🟠 Constraint oluşur |

🔴 = `screeningOutcome = professionalReviewRecommended`. Kullanıcı daha sonra "Sağlık profesyonelimden onay aldım" diyerek beyanını güncelleyebilir. Beyan tarih damgasıyla saklanır.

## 3. Risk matrisi

Olasılık (O) ve Etki (E): 1 = düşük … 3 = yüksek. Risk = O × E.

| # | Risk | O | E | Risk | Önlem | Kural / Sahip |
|---|---|:-:|:-:|:-:|---|---|
| R1 | Kullanıcı seans sırasında yeni veya keskin ağrı bildirir | 2 | 3 | 6 | Seans durur. İlgili bölge için constraint oluşur. Sonraki planda o bölgeye yük artışı yapılmaz. Ağrı tekrar ederse profesyonel öneri gösterilir | SAF-01 |
| R2 | Baş dönmesi / göğüs ağrısı / ciddi nefes darlığı | 1 | 3 | 3 | "Kendimi iyi hissetmiyorum" → seans **durur**. Şu mesaj gösterilir: dinlen, belirtiler sürerse acil yardım ara (yerel acil numarası, ör. 112). Bugün ve bir sonraki seans iptal edilir | SAF-02 |
| R3 | Değerlendirme sırasında düşme | 1 | 3 | 3 | MVP'de tek ayak testi yok. Denge testi destekli (sandalye talimatı zorunlu onay adımı). S5 "evet" ise yalnızca yarı-tandem. Test her an durdurulabilir (büyük buton + sesli "dur" yok, ekran dokunuşu yeterli) | SAF-03 |
| R4 | Uygunsuz yük artışı | 2 | 2 | 4 | Progresyon şu sınırlarla çalışır: haftalık yük artışı ≤ %10 veya en küçük dambıl adımı. Önceki 2 seansta RPE ≤ 7 ve rahatsızlık yoksa artış olur. Aynı seansta tek bir değişken (tekrar **veya** yük) artar | SAF-04 |
| R5 | Düşük güvenilirlikli ölçüme dayanarak zorluk artırılması | 2 | 2 | 4 | `reliability ∈ {low, insufficient}` olan sonuçlar progresyon girdisi olamaz | SAF-05 |
| R6 | Yakın zamanda ameliyat / yaralanma (S4) | 1 | 3 | 3 | Otomatik plan yok. Profesyonel öneri gösterilir | SAF-06 |
| R7 | Uzun aradan sonra (≥ 7 gün) eski yükle başlama | 3 | 2 | 6 | Geri dönüş haftası uygulanır: hacim %60 civarına iner, yük bir basamak düşer, RPE hedefi ≤ 6 | SAF-07 |
| R8 | Kamera sayımının tıbbi sonuç gibi algılanması | 2 | 2 | 4 | Metinlerde "tahmin" ifadesi kullanılır. Sonuç ekranında wellness notu yer alır. Puanlar risk veya biyolojik yaş olarak sunulmaz | SAF-08 / Ürün |
| R9 | Kullanıcının güvenlik sorularına dikkatsizce "hayır" demesi | 2 | 3 | 6 | Sorular sade dilde yazılır. Her seans öncesinde tek dokunuşlu hızlı kontrol ("Bugün yeni bir ağrı ya da baş dönmesi var mı?") yapılır. Plan ilk 2 hafta muhafazakâr tutulur | SAF-09 |
| R10 | Telefonun düşmesi / yerleştirme kazası | 2 | 1 | 2 | Yerleştirme talimatı verilir: zemine veya sabit bir yüzeye yasla, sandalyenin önüne koyma | Ürün |
| R11 | Sağlık verisinin sızması | 1 | 3 | 3 | Local-first saklama, sunucu yok, 3. taraf SDK yok, veri silme imkânı, HealthKit için minimum izin | Mimari |
| R12 | Ağrı/rehabilitasyon segmentine özel protokol beklentisi | 2 | 2 | 4 | Rehabilitasyon protokolü sunulmaz. Metinler bunu açıkça belirtir. Gerektiğinde profesyonel yönlendirme yapılır | Ürün |

## 4. Progresyon güvenlik kuralları (özet)

```
SAF-04  artış yalnızca: son 2 seans tamamlandı ∧ RPE ≤ 7 ∧ discomfort = none ∧ aktif kısıt yok (ilgili bölge)
SAF-01  discomfort = newOrSharp   → seansı durdur, bölge constraint'i, progresyon dondur (o bölge)
SAF-02  dizziness = true          → seansı durdur, 1 seans iptal, profesyonel öneri metni
        RPE ≥ 9 iki seans üst üste → bir basamak geri
SAF-05  reliability < moderate    → progresyon girdisi değil
SAF-07  gün_arası ≥ 7             → geri dönüş haftası
```

## 5. Metin kuralları
- Teşhis dili kullanılmaz ("artrit", "sarkopeni riski", "düşme riski yüksek").
- Korku içeren dil kullanılmaz. Sakin, yönlendirici bir dil seçilir.
- Acil durum metni her zaman şunu söyler: "Belirtiler devam ederse veya şiddetliyse acil yardım çağır."
