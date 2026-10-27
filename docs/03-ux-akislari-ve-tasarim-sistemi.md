# 03 — Kullanıcı Akışları ve Design System

## 1. Navigasyon

Üç sekme kullanılır. Az sekme, düşük bilişsel yük demektir.

| Sekme | İçerik |
|---|---|
| **Today / Bugün** | Bugünkü seans, kısa ilerleme özeti, sonraki değerlendirme |
| **Progress / İlerleme** | Capacity Map, geçmiş, grafikler, Proof of Progress |
| **Settings / Ayarlar** | Tercihler, abonelik, HealthKit, gizlilik, veri silme/dışa aktarma |

Değerlendirme ve Workout Player **tam ekran** (`fullScreenCover`) açılır. Odak gerektiren bir görev olduğu için sekme çubuğu görünmez.

## 2. Ana akışlar

### 2.1 İlk açılış
```
Hoş geldin (değer önerisi, 1 ekran)
  → Yaş aralığı → Aktivite → Deneyim → Hedef
  → Gün sayısı → Seans süresi → Ekipman → Kısıtlar
  → Güvenlik taraması (evet/hayır, 6–7 soru)
       ├─ Herhangi bir "kırmızı" evet → Profesyonel görüş önerisi ekranı
       │     (plan üretilmez; "Onay aldım" ile sonradan güncellenebilir)
       └─ Temiz → "Başlangıç değerlendirmesi yapalım mı?" [Başla] [Sonra]
  → Today
```

### 2.2 Değerlendirme
```
Test listesi (atlanabilir kartlar)
  → Test tanıtımı (animasyon/görsel + güvenlik notu)
  → Yöntem seç: [Kamera ile] [Manuel]
  → (Kamera) İzin → Yerleştirme talimatı → Canlı kadraj kontrolü
        (tüm eklemler yeşil olana kadar "Başla" pasif)
  → Geri sayım (sesli 3-2-1) → Ölçüm (sayaç + süre, büyük rakamlar)
  → Kalite kontrolü ─┬─ Geçerli → Sonuç + açıklama
                     └─ Yetersiz → "Bu ölçüm güvenilir değil" + [Tekrar] [Manuel]
  → Sonraki test … → Özet → Capacity Map
```

### 2.3 Antrenman
```
Today kartı [Başla] → Önizleme (hareketler, süre, ekipman)
  → Player: hareket kartı → set işaretle → dinlenme sayacı → …
       [Duraklat] [Değiştir] [Bitir]   •   her ekranda "Kendimi iyi hissetmiyorum"
  → Geri bildirim: RPE → Rahatsızlık → Tamamlanma → Ağırlık → Not
  → Özet ("Harika iş" + bir sonraki seans)
```
"Kendimi iyi hissetmiyorum" butonu her an erişilebilir olur. Basıldığında seans durur ve güvenlik ekranı açılır (bkz. 05).

### 2.4 Yeniden değerlendirme (28. gün)
Today kartı "Değerlendirme zamanı" mesajını gösterir. Aynı test protokolü uygulanır. Ardından Proof of Progress ekranı açılır: önce/sonra çubukları, karşılaştırılamayan testler için açıklama.

### 2.5 Ara sonrası dönüş
Son seanstan bu yana 7 günden fazla geçtiyse Today kartı şunu gösterir: *"Tekrar hoş geldin. Bu hafta biraz daha hafif başlayalım."* Ardından düşük yoğunluklu bir hafta önerilir.

## 3. Design System

### 3.1 Renk tokenları

Tüm renkler `SSColor` içinde tanımlıdır. Her token light, dark ve yüksek kontrast varyantlarına sahiptir.

| Token | Light | Dark | Kullanım | Kontrast (zemin üzerinde) |
|---|---|---|---|---|
| `background` | `#F6F7F6` | `#0D1114` | Ekran zemini | — |
| `surface` | `#FFFFFF` | `#182025` | Kartlar | — |
| `textPrimary` | `#14202B` | `#F1F4F6` | Başlık, gövde | ≈ 16:1 |
| `textSecondary` | `#4A5560` | `#A7B1BA` | Açıklama | ≈ 7:1 (AA+) |
| `accent` | `#0F766E` | `#2DD4BF` | Vurgu, birincil buton | ≈ 5.4:1 / 10:1 |
| `accent` (yüksek kontrast) | `#0B5A54` | `#5EEAD4` | Increase Contrast açıkken | ≥ 7:1 |
| `accentSoft` | `#E3F2F0` | `#11302D` | Seçili zemin, rozet | — |
| `onAccent` | `#FFFFFF` | `#0D1114` | Accent üzerindeki metin | ≥ 5:1 |
| `separator` | `#E1E6E9` | `#29323A` | Kart kenarlığı | — |
| `caution` | `#8A5300` | `#F5B451` | Dikkat mesajı (kırmızı yerine) | ≥ 4.5:1 |
| `stop` | `#B42318` | `#F97066` | Yalnızca "dur" güvenlik ekranı | ≥ 4.5:1 |

Kontrast değerleri hesaplanmış yaklaşık değerlerdir. Faz 6'da Xcode Accessibility Inspector ile doğrulanacak.
**İlke:** Kırmızı yalnızca güvenlik durdurma ekranında kullanılır. Kötü ölçüm sonucu ya da kaçırılan seans asla kırmızıyla gösterilmez.

### 3.2 Tipografi
Yalnızca sistem metin stilleri kullanılır (SF Pro), böylece Dynamic Type tüm boyutlarda (AX5 dahil) otomatik çalışır.

| Token | Stil | Kullanım |
|---|---|---|
| `SSFont.largeTitle` | largeTitle, bold | Ekran başlığı |
| `SSFont.title` | title2, semibold | Bölüm başlığı |
| `SSFont.headline` | headline | Kart başlığı, buton |
| `SSFont.body` | body | Gövde |
| `SSFont.footnote` | footnote | Açıklama, yasal not |
| `SSFont.metric` | largeTitle, rounded, semibold, monospacedDigit | Sayaç, puan |

### 3.3 Ölçüler
- Boşluk: 4 / 8 / 12 / 16 / 24 / 32 (`SSSpacing`)
- Köşe: kart 20, buton 14 (`.continuous`)
- **Minimum dokunma alanı: 52 pt** (Apple'ın 44 pt minimumunun üstü, 45+ kullanıcılar için)
- Birincil aksiyonlar ekranın alt yarısında tutulur (tek elle kullanım için)

### 3.4 Hareket ve geri bildirim
- Animasyonlar ≤ 0.25 sn, `easeOut`. **Reduce Motion** açıksa ölçek ve kaydırma efektleri kapanır, yalnızca opaklık değişimi kalır.
- Haptics: set tamamlandığında `.success`, geri sayımda `.impact(.light)`, güvenlik durdurmasında `.warning`. Ayarlardan kapatılabilir.

### 3.5 Erişilebilirlik kontrol listesi (her ekran)
- [ ] Tüm etkileşimli öğelerin VoiceOver etiketi var; ilgili öğeler `accessibilityElement(children: .combine)` ile gruplandı
- [ ] Ekran AX5 Dynamic Type'ta kesilmeden okunabiliyor (`ViewThatFits` / dikey yerleşime geçiş)
- [ ] Bilgi yalnızca renkle iletilmiyor (ikon ve metin de var)
- [ ] Ölçüm sırasında sesli yönlendirme var (VoiceOver kullanıcıları için de)
- [ ] Reduce Motion ve Increase Contrast test edildi

### 3.6 Microcopy ilkeleri
| Yapma | Yap |
|---|---|
| "Düşme riskin yüksek!" | "Denge çalışması bu hafta planına eklendi." |
| "Biyolojik yaşın 61" | (gösterilmez) |
| "Serini kaybettin" | "Kaldığın yerden devam edelim." |
| "Kamera %98 doğru" | "Kamera sayımı bir tahmindir; istersen düzeltebilirsin." |
