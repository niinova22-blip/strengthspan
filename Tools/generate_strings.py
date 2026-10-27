"""Generates Strengthspan/Resources/Localizable.xcstrings from the table below.

Keeps English and Turkish in lockstep: every key must have both values.
Run from the repository root:  python Tools/generate_strings.py
After Xcode becomes the main editor of the catalog, this script can be retired.
"""
import json
import pathlib

STRINGS = {
    "tab.today": ("Today", "Bugün"),
    "tab.progress": ("Progress", "İlerleme"),
    "tab.settings": ("Settings", "Ayarlar"),

    "today.title": ("Today", "Bugün"),
    "today.workout.title": ("Today's workout", "Bugünkü antrenman"),
    "today.workout.empty.message": (
        "Your personal plan is created after your first capacity check.",
        "Kişisel planın, ilk kapasite değerlendirmenden sonra oluşturulur.",
    ),
    "today.workout.planned %lld": (
        "A %lld-minute session is planned for today.",
        "Bugün için %lld dakikalık bir seans planlandı.",
    ),
    "today.progress.title": ("Your progress", "İlerlemen"),
    "today.progress.empty.message": ("Not enough measurements yet.", "Henüz yeterli ölçüm yok."),
    "today.progress.measured %lld": (
        "%lld of 4 capacity areas measured.",
        "4 kapasite alanından %lld tanesi ölçüldü.",
    ),
    "today.assessment.title": ("Next capacity check", "Sonraki kapasite değerlendirmesi"),
    "today.assessment.never": (
        "Start with your first capacity check.",
        "İlk kapasite değerlendirmenle başla.",
    ),
    "today.assessment.scheduled %@": ("Suggested for %@.", "Önerilen tarih: %@."),
    "today.assessment.due": ("Your capacity check is due.", "Kapasite değerlendirmenin zamanı geldi."),
    "today.assessment.cadence": (
        "We suggest a capacity check every 4 weeks.",
        "Her 4 haftada bir kapasite değerlendirmesi öneriyoruz.",
    ),

    "progress.title": ("Progress", "İlerleme"),
    "progress.capacityMap": ("Capacity map", "Kapasite haritası"),
    "progress.capacityMap.footnote": (
        "Scores only compare you with your own earlier measurements. They are not a medical assessment.",
        "Puanlar seni yalnızca kendi önceki ölçümlerinle karşılaştırır. Tıbbi bir değerlendirme değildir.",
    ),
    "progress.metric.insufficient": ("Not enough measurements yet", "Henüz yeterli ölçüm yok"),

    "dimension.strength": ("Strength", "Kuvvet"),
    "dimension.balance": ("Balance", "Denge"),
    "dimension.mobility": ("Mobility", "Mobilite"),
    "dimension.movementControl": ("Movement control", "Hareket kontrolü"),

    "settings.title": ("Settings", "Ayarlar"),
    "settings.section.general": ("General", "Genel"),
    "settings.language": ("Language", "Dil"),
    "settings.language.footer": (
        "You can change the app language in iOS Settings.",
        "Uygulama dilini iOS Ayarlar'dan değiştirebilirsin.",
    ),
    "settings.section.privacy": ("Privacy & data", "Gizlilik ve veriler"),
    "settings.privacy.localOnly": (
        "Your fitness data is stored only on this iPhone.",
        "Fitness verilerin yalnızca bu iPhone'da saklanır.",
    ),
    "settings.deleteAll": ("Delete all my data", "Tüm verilerimi sil"),
    "settings.deleteAll.confirm.title": ("Delete all data?", "Tüm veriler silinsin mi?"),
    "settings.deleteAll.confirm.message": (
        "This permanently deletes your profile, assessments and workouts from this iPhone. This can't be undone.",
        "Profilin, değerlendirmelerin ve antrenmanların bu iPhone'dan kalıcı olarak silinir. Bu işlem geri alınamaz.",
    ),
    "settings.deleteAll.confirm.action": ("Delete", "Sil"),
    "settings.deleteAll.success": ("All data deleted.", "Tüm veriler silindi."),
    "settings.deleteAll.failure": (
        "Your data couldn't be deleted. Please try again.",
        "Verilerin silinemedi. Lütfen tekrar dene.",
    ),
    "settings.section.about": ("About", "Hakkında"),
    "settings.privacyPolicy": ("Privacy Policy", "Gizlilik Politikası"),
    "settings.termsOfUse": ("Terms of Use", "Kullanım Koşulları"),
    "settings.support": ("Support", "Destek"),
    "settings.version": ("Version", "Sürüm"),
    "settings.disclaimer": (
        "Strengthspan is a fitness and wellness app. It does not diagnose or treat any medical condition.",
        "Strengthspan bir fitness ve sağlıklı yaşam uygulamasıdır. Herhangi bir tıbbi durumu teşhis etmez veya tedavi etmez.",
    ),

    "common.ok": ("OK", "Tamam"),

    "startup.error.title": ("Strengthspan couldn't start", "Strengthspan başlatılamadı"),
    "startup.error.message": (
        "Your data couldn't be opened. Please restart the app. If this keeps happening, contact support.",
        "Verilerin açılamadı. Lütfen uygulamayı yeniden başlat. Sorun devam ederse destekle iletişime geç.",
    ),
}


def unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def main() -> None:
    catalog = {
        "sourceLanguage": "en",
        "strings": {
            key: {
                "extractionState": "manual",
                "localizations": {"en": unit(en), "tr": unit(tr)},
            }
            for key, (en, tr) in sorted(STRINGS.items())
        },
        "version": "1.0",
    }
    out = pathlib.Path(__file__).resolve().parent.parent / "Strengthspan" / "Resources" / "Localizable.xcstrings"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(STRINGS)} keys to {out}")


if __name__ == "__main__":
    main()
