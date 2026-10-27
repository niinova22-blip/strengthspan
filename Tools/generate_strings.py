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
    "today.workout.empty.message": ("No session is planned yet.", "Henüz planlanmış bir seans yok."),
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
    "common.back": ("Back", "Geri"),
    "common.continue": ("Continue", "Devam"),
    "common.yes": ("Yes", "Evet"),
    "common.no": ("No", "Hayır"),
    "common.close": ("Close", "Kapat"),
    "common.cancel": ("Cancel", "Vazgeç"),
    "common.done": ("Done", "Tamam"),

    "startup.error.title": ("Strengthspan couldn't start", "Strengthspan başlatılamadı"),
    "startup.error.message": (
        "Your data couldn't be opened. Please restart the app. If this keeps happening, contact support.",
        "Verilerin açılamadı. Lütfen uygulamayı yeniden başlat. Sorun devam ederse destekle iletişime geç.",
    ),

    # Settings — workout
    "settings.section.workout": ("Workout", "Antrenman"),
    "settings.voiceGuidance": ("Voice guidance", "Sesli yönlendirme"),
    "settings.haptics": ("Haptic feedback", "Titreşimli geri bildirim"),

    # Onboarding
    "onboarding.progress": ("Setup progress", "Kurulum ilerlemesi"),
    "onboarding.start": ("Get started", "Başla"),
    "onboarding.finish": ("Finish setup", "Kurulumu bitir"),
    "onboarding.saveFailed": ("Your answers couldn't be saved. Please try again.", "Yanıtların kaydedilemedi. Lütfen tekrar dene."),
    "onboarding.welcome.title": ("Welcome to Strengthspan", "Strengthspan'e hoş geldin"),
    "onboarding.welcome.message": (
        "In a few short steps we'll set up a plan that fits your body, your time and your equipment.",
        "Birkaç kısa adımda vücuduna, zamanına ve ekipmanına uygun bir plan hazırlayacağız.",
    ),
    "onboarding.welcome.privacy": ("Your answers stay on this iPhone.", "Yanıtların bu iPhone'da kalır."),
    "onboarding.ageRange.title": ("How old are you?", "Kaç yaşındasın?"),
    "onboarding.activity.title": ("How active are you on a typical day?", "Sıradan bir günde ne kadar aktifsin?"),
    "onboarding.experience.title": ("How familiar are you with strength training?", "Kuvvet antrenmanına ne kadar aşinasın?"),
    "onboarding.goal.title": ("What matters most to you?", "Senin için en önemli olan ne?"),
    "onboarding.days.title": ("Which days suit you?", "Hangi günler sana uygun?"),
    "onboarding.days.detail": (
        "Choose the days you'd like to train. Two or three days a week is a great start.",
        "Antrenman yapmak istediğin günleri seç. Haftada iki ya da üç gün harika bir başlangıç.",
    ),
    "onboarding.sessionLength.title": ("How long should a session be?", "Bir seans ne kadar sürsün?"),
    "onboarding.equipment.title": ("What do you have at home?", "Evde neler var?"),
    "onboarding.equipment.detail": (
        "Choose everything that applies. Every exercise has a no-equipment version.",
        "Uygun olanların hepsini seç. Her hareketin ekipmansız bir versiyonu var.",
    ),
    "onboarding.screening.title": ("A few safety questions", "Birkaç güvenlik sorusu"),
    "onboarding.screening.detail": (
        "These help us keep your plan safe. They are not a medical assessment.",
        "Bu sorular planını güvenli tutmamıza yardımcı olur. Tıbbi bir değerlendirme değildir.",
    ),
    "onboarding.painRegions.title": ("Where do you feel pain?", "Nerede ağrı hissediyorsun?"),
    "onboarding.painRegions.detail": (
        "We'll leave out exercises that load these areas.",
        "Bu bölgelere yük bindiren hareketleri planına koymayacağız.",
    ),
    "onboarding.result.cleared.title": ("You're all set", "Her şey hazır"),
    "onboarding.result.cleared.message": (
        "We'll build your first week now. Every session starts gently, and you can stop at any time.",
        "İlk haftanı şimdi hazırlıyoruz. Her seans hafif başlar ve istediğin an durabilirsin.",
    ),
    "onboarding.result.review.title": ("Let's check in with a professional first", "Önce bir uzmana danışalım"),
    "onboarding.result.review.message": (
        "Based on your answers, we recommend talking to a doctor or physiotherapist before starting a new exercise program. Once they've given you the go-ahead, you can unlock your plan from the Today screen.",
        "Yanıtlarına göre yeni bir egzersiz programına başlamadan önce bir doktor ya da fizyoterapistle görüşmeni öneriyoruz. Onay aldığında planını Bugün ekranından açabilirsin.",
    ),

    # Options
    "option.ageRange.under45": ("Under 45", "45 yaş altı"),
    "option.ageRange.age45to49": ("45–49", "45–49"),
    "option.ageRange.age50to54": ("50–54", "50–54"),
    "option.ageRange.age55to59": ("55–59", "55–59"),
    "option.ageRange.age60to64": ("60–64", "60–64"),
    "option.ageRange.age65to69": ("65–69", "65–69"),
    "option.ageRange.age70plus": ("70 or older", "70 ve üzeri"),
    "option.activity.mostlySedentary": ("Mostly sitting during the day", "Günün çoğunu oturarak geçiriyorum"),
    "option.activity.lightlyActive": ("Some light activity, like walking", "Yürüyüş gibi biraz hafif aktivite"),
    "option.activity.moderatelyActive": ("Regular moderate activity", "Düzenli orta düzey aktivite"),
    "option.activity.veryActive": ("Very active most days", "Çoğu gün çok aktifim"),
    "option.experience.new": ("New to strength training", "Kuvvet antrenmanında yeniyim"),
    "option.experience.returning": ("Getting back into it after a break", "Aradan sonra yeniden başlıyorum"),
    "option.experience.regular": ("I train regularly", "Düzenli antrenman yapıyorum"),
    "option.goal.buildStrength": ("Get stronger", "Daha güçlü olmak"),
    "option.goal.improveBalance": ("Improve my balance", "Dengemi geliştirmek"),
    "option.goal.moveMoreEasily": ("Move more easily", "Daha rahat hareket etmek"),
    "option.goal.stayIndependent": ("Stay independent as I age", "Yaşlandıkça bağımsız kalmak"),
    "option.goal.generalFitness": ("General fitness", "Genel zindelik"),
    "option.equipment.bodyweightOnly": ("No equipment", "Ekipman yok"),
    "option.equipment.dumbbells": ("Dumbbells", "Dambıl"),
    "option.equipment.resistanceBand": ("Resistance band", "Direnç bandı"),
    "option.region.neck": ("Neck", "Boyun"),
    "option.region.shoulder": ("Shoulder", "Omuz"),
    "option.region.back": ("Back", "Sırt veya bel"),
    "option.region.hip": ("Hip", "Kalça"),
    "option.region.knee": ("Knee", "Diz"),
    "option.region.ankleFoot": ("Ankle or foot", "Ayak bileği veya ayak"),
    "option.region.wristHand": ("Wrist or hand", "El bileği veya el"),
    "option.region.other": ("Somewhere else", "Başka bir yer"),
    "option.block.warmUp": ("Warm-up", "Isınma"),
    "option.block.mainStrength": ("Strength", "Kuvvet"),
    "option.block.balanceControl": ("Balance & control", "Denge ve kontrol"),
    "option.block.cooldown": ("Cool-down", "Soğuma"),
    "option.sessionLength.short": ("10 minutes", "10 dakika"),
    "option.sessionLength.standard": ("20 minutes", "20 dakika"),
    "option.sessionLength.long": ("30 minutes", "30 dakika"),

    # Screening (docs/05 §2)
    "screening.supervisedOnly": (
        "Has a health professional told you to exercise only under medical supervision?",
        "Bir sağlık profesyoneli sana yalnızca tıbbi gözetim altında egzersiz yapmanı söyledi mi?",
    ),
    "screening.chestPain": (
        "Do you feel pain, pressure or tightness in your chest during physical activity?",
        "Fiziksel aktivite sırasında göğsünde ağrı, baskı ya da sıkışma hissediyor musun?",
    ),
    "screening.dizziness": (
        "In the past 12 months, have you lost your balance because of dizziness, or fainted?",
        "Son 12 ayda baş dönmesi nedeniyle dengeni kaybettin mi ya da bayıldın mı?",
    ),
    "screening.recentSurgery": (
        "Have you had surgery or a significant injury in the past 3 months?",
        "Son 3 ay içinde ameliyat oldun mu ya da ciddi bir yaralanma geçirdin mi?",
    ),
    "screening.recentFall": ("Have you had a fall in the past 12 months?", "Son 12 ayda düştün mü?"),
    "screening.jointPain": (
        "Do you have joint or back pain that gets worse with movement?",
        "Hareketle kötüleşen eklem ya da sırt ağrın var mı?",
    ),
    "screening.movementLimitation": (
        "Do you have any other condition that limits how you move?",
        "Hareketini kısıtlayan başka bir durumun var mı?",
    ),

    # Today — plan states
    "today.blocked.review.message": (
        "We recommend talking to a health professional before you start. When you've been cleared to exercise, unlock your plan here.",
        "Başlamadan önce bir sağlık profesyoneliyle görüşmeni öneriyoruz. Egzersiz için onay aldığında planını buradan açabilirsin.",
    ),
    "today.blocked.review.action": ("I've been cleared to exercise", "Egzersiz için onay aldım"),
    "today.blocked.review.confirm": (
        "Please confirm that a health professional has said it's safe for you to start exercising.",
        "Lütfen bir sağlık profesyonelinin egzersize başlamanın senin için güvenli olduğunu söylediğini onayla.",
    ),
    "today.blocked.dizziness.message": (
        "Training is paused because you reported dizziness or other warning signs. If it happens again, please talk to a health professional.",
        "Baş dönmesi ya da başka uyarı işaretleri bildirdiğin için antrenman duraklatıldı. Tekrarlarsa lütfen bir sağlık profesyoneliyle görüş.",
    ),
    "today.blocked.dizziness.action": ("I feel well again", "Kendimi yeniden iyi hissediyorum"),
    "today.blocked.dizziness.confirm": ("Only continue if your symptoms have fully passed.", "Yalnızca belirtilerin tamamen geçtiyse devam et."),
    "today.workout.returnWeek": ("Welcome back — this week starts a little lighter.", "Tekrar hoş geldin — bu hafta biraz daha hafif başlıyor."),
    "today.workout.exerciseCount %lld": ("%lld exercises", "%lld hareket"),
    "today.workout.start": ("Start workout", "Antrenmana başla"),
    "today.workout.continue": ("Continue workout", "Antrenmana devam et"),
    "today.workout.done": ("Today's session is done. Nice work.", "Bugünkü seans tamam. Harika iş."),
    "today.workout.next %@": ("Next session: %@", "Sonraki seans: %@"),
    "today.progress.week %lld %lld": ("This week: %1$lld of %2$lld sessions done", "Bu hafta: %2$lld seanstan %1$lld tanesi tamam"),

    # Player
    "player.end": ("End", "Bitir"),
    "player.progress": ("Workout progress", "Antrenman ilerlemesi"),
    "player.checkIn.title": ("Before we start", "Başlamadan önce"),
    "player.checkIn.question": (
        "Do you have any new pain, dizziness or chest discomfort today, or do you feel unwell?",
        "Bugün yeni bir ağrın, baş dönmen ya da göğüs rahatsızlığın var mı, ya da kendini iyi hissetmiyor musun?",
    ),
    "player.checkIn.plan": ("Today's plan", "Bugünün planı"),
    "player.checkIn.ok": ("No, I feel fine — let's start", "Hayır, iyiyim — başlayalım"),
    "player.checkIn.notOk": ("Yes, something isn't right", "Evet, bir şeyler yolunda değil"),
    "player.reps %lld": ("%lld reps", "%lld tekrar"),
    "player.seconds %lld": ("%lld sec", "%lld sn"),
    "player.setOf %lld %lld": ("Set %1$lld of %2$lld", "Set %1$lld / %2$lld"),
    "player.secondsLeft %lld": ("%lld seconds left", "%lld saniye kaldı"),
    "player.load %@": ("Weight: %@ kg", "Ağırlık: %@ kg"),
    "player.useSupport": ("Hold a sturdy chair, counter or wall.", "Sağlam bir sandalyeye, tezgâha ya da duvara tutun."),
    "player.easier": ("Make it easier", "Daha kolay versiyon"),
    "player.skipExercise": ("Skip exercise", "Hareketi atla"),
    "player.pause": ("Pause", "Duraklat"),
    "player.unwell": ("I don't feel well", "Kendimi iyi hissetmiyorum"),
    "player.timer.start": ("Start timer", "Süreyi başlat"),
    "player.timer.pause": ("Pause timer", "Süreyi durdur"),
    "player.setDone": ("Set done", "Set tamam"),
    "player.paused": ("Paused", "Duraklatıldı"),
    "player.resume": ("Resume", "Devam et"),
    "player.rest": ("Rest", "Dinlen"),
    "player.next": ("Up next", "Sıradaki"),
    "player.skipRest": ("Skip rest", "Dinlenmeyi atla"),
    "player.announce.finished": ("Well done. That was the last exercise.", "Tebrikler. Bu son hareketti."),
    "player.announce.set %@ %lld %lld": ("%1$@. Set %2$lld of %3$lld.", "%1$@. Set %2$lld / %3$lld."),

    # Feedback
    "feedback.title": ("How did it go?", "Nasıl geçti?"),
    "feedback.rpe.title": ("How hard did it feel?", "Ne kadar zorlandın?"),
    "feedback.rpe.value %lld %@": ("%1$lld of 10 — %2$@", "10 üzerinden %1$lld — %2$@"),
    "feedback.rpe.veryEasy": ("very easy", "çok kolay"),
    "feedback.rpe.easy": ("easy", "kolay"),
    "feedback.rpe.moderate": ("moderate", "orta"),
    "feedback.rpe.hard": ("hard", "zor"),
    "feedback.rpe.veryHard": ("very hard", "çok zor"),
    "feedback.rpe.max": ("as hard as possible", "olabildiğince zor"),
    "feedback.discomfort.title": ("Any discomfort?", "Rahatsızlık oldu mu?"),
    "feedback.discomfort.none": ("None", "Hayır"),
    "feedback.discomfort.mildFamiliar": ("Mild, familiar soreness", "Hafif, bildik bir sızı"),
    "feedback.discomfort.newOrSharp": ("New or sharp pain", "Yeni ya da keskin bir ağrı"),
    "feedback.regions.title": ("Where did you feel it?", "Nerede hissettin?"),
    "feedback.dizziness": ("I felt dizzy or light-headed", "Başım döndü ya da sersemlik hissettim"),
    "feedback.note.title": ("Notes (optional)", "Notlar (isteğe bağlı)"),
    "feedback.note.placeholder": ("Anything you'd like to remember", "Hatırlamak istediğin bir şey"),
    "feedback.save": ("Save", "Kaydet"),

    # Safety
    "safety.check.title": ("What's happening?", "Ne oluyor?"),
    "safety.check.regions": ("Where do you feel pain?", "Nerede ağrı hissediyorsun?"),
    "safety.check.warningSigns": (
        "Chest pain, dizziness, feeling faint or very short of breath",
        "Göğüs ağrısı, baş dönmesi, bayılacak gibi olma ya da ciddi nefes darlığı",
    ),
    "safety.check.pain": ("Pain in part of my body", "Vücudumun bir yerinde ağrı"),
    "safety.check.unwell": ("I'm tired or not feeling up to it", "Yorgunum ya da bugün hiç havamda değilim"),
    "safety.check.confirmPain": ("Stop and adjust my plan", "Dur ve planımı uyarla"),
    "safety.emergency": (
        "Stop exercising and sit down. If symptoms are severe or don't pass within a few minutes, call your local emergency number (112 in Türkiye and Europe).",
        "Egzersizi bırak ve otur. Belirtiler şiddetliyse ya da birkaç dakika içinde geçmezse yerel acil numarasını ara (Türkiye'de 112).",
    ),
    "safety.professional": (
        "Please talk to a health professional before your next session. Training is paused until you confirm you feel well.",
        "Bir sonraki seanstan önce lütfen bir sağlık profesyoneliyle görüş. Kendini iyi hissettiğini onaylayana kadar antrenman duraklatıldı.",
    ),
    "safety.painAdjusted": (
        "We've removed exercises that load this area from your plan. If the pain continues, please see a health professional.",
        "Bu bölgeye yük bindiren hareketleri planından çıkardık. Ağrı devam ederse lütfen bir sağlık profesyoneline görün.",
    ),

    # Session outcome
    "outcome.finished.title": ("Session complete", "Seans tamamlandı"),
    "outcome.finished.message": (
        "Thanks for checking in. Your next session will adapt to how today went.",
        "Geri bildirimin için teşekkürler. Sonraki seansın bugüne göre uyarlanacak.",
    ),
    "outcome.stopped.title": ("Session stopped", "Seans durduruldu"),
    "outcome.stopped.message": ("Stopping was the right call. Rest and look after yourself.", "Durmak doğru bir karardı. Dinlen ve kendine iyi bak."),
}

# Exercise library: variant key → ((EN name, EN how-to), (TR name, TR how-to)).
EXERCISES = {
    "march.inPlace": (
        ("March in Place", "Stand tall and lift your knees one at a time at an easy pace. Swing your arms gently. Hold a chair if you like."),
        ("Yerinde Yürüyüş", "Dik dur ve dizlerini sırayla, rahat bir tempoda kaldır. Kollarını hafifçe salla. İstersen bir sandalyeye tutun."),
    ),
    "armCircles.standing": (
        ("Arm Circles", "Stand with your arms out to the sides. Make small, slow circles forward, then backward. Keep your shoulders relaxed."),
        ("Kol Çevirme", "Kollarını yana aç. Önce öne, sonra geriye doğru küçük ve yavaş daireler çiz. Omuzlarını gevşek tut."),
    ),
    "hipCircles.supported": (
        ("Supported Hip Circles", "Hold a sturdy chair. With feet hip-width apart, slowly circle your hips in one direction, then the other."),
        ("Destekli Kalça Çevirme", "Sağlam bir sandalyeye tutun. Ayakların kalça genişliğinde, kalçanı yavaşça bir yöne, sonra diğer yöne döndür."),
    ),
    "sitToStand.withHands": (
        ("Sit-to-Stand with Hands", "Sit near the front of a sturdy chair, feet flat. Lean forward, push through your heels and use your hands on the chair or your thighs to stand. Sit back down slowly."),
        ("Elden Destekli Oturup Kalkma", "Sağlam bir sandalyenin önüne doğru otur, ayakların yere tam bassın. Öne eğil, topuklarından it ve ellerini sandalyeye ya da uyluklarına koyarak ayağa kalk. Yavaşça geri otur."),
    ),
    "sitToStand.armsCrossed": (
        ("Sit-to-Stand, Arms Crossed", "Cross your arms over your chest. Lean forward and stand up without using your hands. Lower yourself back down with control."),
        ("Kollar Çapraz Oturup Kalkma", "Kollarını göğsünde çaprazla. Öne eğil ve ellerini kullanmadan ayağa kalk. Kontrollü şekilde geri otur."),
    ),
    "sitToStand.slowLower": (
        ("Slow Sit-to-Stand", "Stand up as before, then take three slow seconds to sit back down. Keep your knees in line with your toes."),
        ("Yavaş Oturup Kalkma", "Aynı şekilde kalk, sonra üç saniyede yavaşça geri otur. Dizlerin ayak parmaklarınla aynı hizada kalsın."),
    ),
    "sitToStand.goblet": (
        ("Goblet Sit-to-Stand", "Hold one dumbbell close to your chest with both hands. Stand up from the chair and sit back down slowly. Choose a weight you can lift with good control."),
        ("Dambılla Oturup Kalkma", "Bir dambılı iki elinle göğsüne yakın tut. Sandalyeden kalk ve yavaşça geri otur. Kontrollü kaldırabildiğin bir ağırlık seç."),
    ),
    "pushUp.wall": (
        ("Wall Push-Up", "Stand an arm's length from a wall with your hands on it at shoulder height. Bend your elbows to bring your chest toward the wall, then push back."),
        ("Duvarda Şınav", "Duvardan bir kol boyu uzakta dur, ellerini omuz hizasında duvara koy. Dirseklerini bükerek göğsünü duvara yaklaştır, sonra geri it."),
    ),
    "pushUp.counter": (
        ("Counter Push-Up", "Place your hands on a sturdy kitchen counter and step your feet back. Keep your body straight as you lower your chest and push back up."),
        ("Tezgâhta Şınav", "Ellerini sağlam bir mutfak tezgâhına koy ve ayaklarını geriye al. Göğsünü indirip geri iterken vücudunu düz tut."),
    ),
    "pushUp.counterSlow": (
        ("Slow Counter Push-Up", "Do a counter push-up, but take three slow seconds to lower and pause briefly before pushing back."),
        ("Yavaş Tezgâhta Şınav", "Tezgâhta şınav gibi yap, ancak üç saniyede yavaşça in ve geri itmeden önce kısa bir an bekle."),
    ),
    "row.shoulderSqueeze": (
        ("Shoulder Blade Squeeze", "Sit or stand tall with your elbows bent at your sides. Squeeze your shoulder blades together, hold for two seconds and relax."),
        ("Kürek Kemiği Sıkıştırma", "Dirseklerin yanlarda bükülü, dik otur ya da dur. Kürek kemiklerini birbirine yaklaştır, iki saniye tut ve gevşe."),
    ),
    "row.band": (
        ("Band Row", "Anchor the band at chest height in a closed door or around a sturdy post. Pull the ends toward your ribs, squeezing your shoulder blades, then release slowly."),
        ("Bantla Çekiş", "Bandı göğüs hizasında kapalı bir kapıya ya da sağlam bir direğe sabitle. Uçları kaburgalarına doğru çek, kürek kemiklerini sık, sonra yavaşça bırak."),
    ),
    "row.dumbbellSupported": (
        ("Supported Dumbbell Row", "Rest one hand on a sturdy chair or table and hold a dumbbell in the other. Pull it up toward your hip, then lower slowly. Work both sides."),
        ("Destekli Dambıl Çekişi", "Bir elini sağlam bir sandalyeye ya da masaya daya, diğer elinde dambıl tut. Dambılı kalçana doğru çek, sonra yavaşça indir. İki tarafı da çalıştır."),
    ),
    "hinge.handsOnThighs": (
        ("Hip Hinge", "Stand with your hands on your thighs and knees soft. Push your hips back and let your hands slide toward your knees, keeping your back straight. Stand up by squeezing your glutes."),
        ("Kalçadan Menteşe Hareketi", "Ellerin uyluklarında, dizlerin hafif bükülü dur. Kalçanı geriye it ve sırtını düz tutarak ellerini dizlerine doğru kaydır. Kalçanı sıkarak doğrul."),
    ),
    "hinge.slowTempo": (
        ("Slow Hip Hinge", "Do the hip hinge, taking three slow seconds on the way down. Keep your back straight throughout."),
        ("Yavaş Menteşe Hareketi", "Menteşe hareketini inerken üç saniye sürecek şekilde yavaş yap. Sırtını baştan sona düz tut."),
    ),
    "hinge.dumbbell": (
        ("Dumbbell Hip Hinge", "Hold dumbbells in front of your thighs. Push your hips back and lower them along your legs to just below the knees with a straight back, then stand tall."),
        ("Dambıllı Menteşe Hareketi", "Dambılları uyluklarının önünde tut. Kalçanı geriye it ve dambılları bacakların boyunca dizlerin hemen altına indir; sırtın düz olsun, sonra doğrul."),
    ),
    "calfRaise.supported": (
        ("Supported Calf Raise", "Hold a chair or counter. Rise slowly onto the balls of your feet, then lower your heels with control."),
        ("Destekli Topuk Kaldırma", "Bir sandalyeye ya da tezgâha tutun. Yavaşça parmak uçlarında yüksel, sonra topuklarını kontrollü şekilde indir."),
    ),
    "calfRaise.pause": (
        ("Calf Raise with Pause", "Holding on for support, rise onto your toes, pause for two seconds at the top and lower slowly."),
        ("Bekletmeli Topuk Kaldırma", "Desteğe tutunarak parmak uçlarında yüksel, yukarıda iki saniye bekle ve yavaşça in."),
    ),
    "calfRaise.dumbbell": (
        ("Dumbbell Calf Raise", "Hold a dumbbell in one hand and a chair or counter with the other. Rise onto your toes and lower slowly."),
        ("Dambıllı Topuk Kaldırma", "Bir elinde dambıl, diğer elinle sandalyeye ya da tezgâha tutun. Parmak uçlarında yüksel ve yavaşça in."),
    ),
    "overhead.wallSlide": (
        ("Wall Slide", "Stand with your back to a wall, arms bent and hands at shoulder height. Slide your arms up the wall as far as is comfortable, then back down."),
        ("Duvarda Kol Kaydırma", "Sırtın duvara dönük, kolların bükülü ve ellerin omuz hizasında dur. Kollarını rahat edebildiğin kadar duvar boyunca yukarı kaydır, sonra indir."),
    ),
    "overhead.band": (
        ("Band Overhead Press", "Stand on the middle of the band holding an end in each hand at shoulder height. Press up overhead without arching your back, then lower slowly."),
        ("Bantla Baş Üstü İtiş", "Bandın ortasına bas, uçlarını omuz hizasında tut. Belini çukurlaştırmadan baş üstüne it, sonra yavaşça indir."),
    ),
    "overhead.dumbbellSeated": (
        ("Seated Dumbbell Press", "Sit tall in a chair with dumbbells at shoulder height. Press them up until your arms are almost straight, then lower slowly."),
        ("Oturarak Dambıl İtişi", "Sandalyede dik otur, dambıllar omuz hizasında olsun. Kolların neredeyse düzleşene kadar yukarı it, sonra yavaşça indir."),
    ),
    "sideLegRaise.supported": (
        ("Supported Side Leg Raise", "Hold a chair. Keeping your body upright and toes pointing forward, lift one leg out to the side and lower it slowly. Work both sides."),
        ("Destekli Yana Bacak Kaldırma", "Bir sandalyeye tutun. Gövden dik, ayak ucun önde olacak şekilde bir bacağını yana kaldır ve yavaşça indir. İki tarafı da çalıştır."),
    ),
    "sideLegRaise.band": (
        ("Band Side Leg Raise", "Loop the band around your ankles and hold a chair. Lift one leg out to the side against the band, then lower slowly."),
        ("Bantla Yana Bacak Kaldırma", "Bandı ayak bileklerine geçir ve bir sandalyeye tutun. Bir bacağını bandın direncine karşı yana kaldır, sonra yavaşça indir."),
    ),
    "weightShift.supported": (
        ("Supported Weight Shift", "Hold a counter with your feet hip-width apart. Slowly shift your weight to one foot, then the other, without lifting your feet."),
        ("Destekli Ağırlık Aktarma", "Ayakların kalça genişliğinde, bir tezgâha tutun. Ayaklarını kaldırmadan ağırlığını yavaşça bir ayağına, sonra diğerine aktar."),
    ),
    "tandem.semi": (
        ("Semi-Tandem Stand", "Holding a counter, place one foot half a step ahead so its heel is beside the big toe of the other foot. Stand steady and hold on whenever you need to."),
        ("Yarı Tandem Duruş", "Bir tezgâha tutunarak bir ayağını yarım adım öne al; topuğu diğer ayağının başparmağının yanında olsun. Dengede dur, gerektiğinde tutun."),
    ),
    "tandem.full": (
        ("Tandem Stand", "Holding a counter, place one foot directly in front of the other, heel touching toe. Stand steady, then switch feet. Keep a hand on the counter."),
        ("Tandem Duruş", "Bir tezgâha tutunarak bir ayağını diğerinin tam önüne koy, topuk parmak ucuna değsin. Dengede dur, sonra ayak değiştir. Bir elin tezgâhta kalsın."),
    ),
    "heelToe.counter": (
        ("Heel-to-Toe Walk", "Walk slowly along a kitchen counter, placing each heel just in front of the toes of the other foot. Keep one hand on the counter."),
        ("Topuk-Parmak Yürüyüşü", "Mutfak tezgâhı boyunca yavaşça yürü; her adımda topuğunu diğer ayağının parmaklarının hemen önüne koy. Bir elin tezgâhta kalsın."),
    ),
    "stepTap.supported": (
        ("Supported Step Tap", "Hold a chair. Tap one foot forward, to the side and back, returning to the centre each time. Switch feet."),
        ("Destekli Adım Dokunuşu", "Bir sandalyeye tutun. Bir ayağınla öne, yana ve geriye dokun, her seferinde ortaya dön. Ayak değiştir."),
    ),
    "stretch.calfWall": (
        ("Calf Stretch", "With your hands on a wall, step one foot back and press the heel down until you feel a gentle stretch in the calf. Switch sides halfway."),
        ("Baldır Esnetme", "Ellerin duvarda, bir ayağını geri al ve baldırında hafif bir gerilme hissedene kadar topuğunu yere bastır. Yarısında taraf değiştir."),
    ),
    "stretch.chestOpener": (
        ("Chest Opener", "Clasp your hands behind your back or rest them on your lower back. Gently draw your shoulders back and breathe slowly."),
        ("Göğüs Açma", "Ellerini arkanda birleştir ya da belinin üstüne koy. Omuzlarını nazikçe geriye al ve yavaş nefes al."),
    ),
    "stretch.hamstringSeated": (
        ("Seated Hamstring Stretch", "Sit near the edge of a chair with one leg straight and the heel on the floor. Sit tall and lean forward slightly until you feel a gentle stretch. Switch sides halfway."),
        ("Oturarak Arka Bacak Esnetme", "Sandalyenin ucuna otur, bir bacağın düz ve topuğun yerde olsun. Dik otur ve hafif bir gerilme hissedene kadar biraz öne eğil. Yarısında taraf değiştir."),
    ),
    "breathing.slow": (
        ("Slow Breathing", "Sit comfortably. Breathe in through your nose for a count of four and out slowly for a count of six. Let your shoulders relax."),
        ("Yavaş Nefes", "Rahatça otur. Burnundan dört sayıda nefes al, altı sayıda yavaşça ver. Omuzlarını gevşet."),
    ),
}

for _key, ((_en_name, _en_how), (_tr_name, _tr_how)) in EXERCISES.items():
    STRINGS[f"exercise.{_key}"] = (_en_name, _tr_name)
    STRINGS[f"exercise.{_key}.how"] = (_en_how, _tr_how)


STRINGS.update({
    # Today — assessments & free tier
    "today.assessment.start": ("Start capacity check", "Kapasite değerlendirmesine başla"),
    "today.assessment.reassess": ("Reassess my capacity", "Kapasitemi yeniden değerlendir"),
    "today.progress.freeWorkouts %lld": ("Free sample workouts left: %lld", "Kalan ücretsiz örnek antrenman: %lld"),
    "progress.capacityMap.footnote": (
        "Values only compare you with your own earlier measurements taken the same way. They are not a medical assessment.",
        "Değerler seni yalnızca aynı şekilde yapılmış kendi önceki ölçümlerinle karşılaştırır. Tıbbi bir değerlendirme değildir.",
    ),

    # Assessment flow
    "assessment.overview.title": ("Capacity check", "Kapasite değerlendirmesi"),
    "assessment.overview.message": (
        "Five short tests of strength, balance, mobility and movement control. It takes about 10 minutes. You can skip any test, and you can stop at any time.",
        "Kuvvet, denge, mobilite ve hareket kontrolü için beş kısa test. Yaklaşık 10 dakika sürer. İstediğin testi atlayabilir, istediğin an durabilirsin.",
    ),
    "assessment.overview.prepare": ("Before you start", "Başlamadan önce"),
    "assessment.overview.prepareList": (
        "• A sturdy chair without wheels, placed against a wall\n• A kitchen counter or table to hold\n• Comfortable shoes and some clear space",
        "• Duvara dayalı, tekerleksiz sağlam bir sandalye\n• Tutunmak için bir mutfak tezgâhı ya da masa\n• Rahat ayakkabılar ve biraz boş alan",
    ),
    "assessment.overview.start": ("Start", "Başla"),
    "assessment.progress %lld %lld": ("Test %1$lld of %2$lld", "Test %1$lld / %2$lld"),
    "assessment.intro.cameraSetup": ("Using the camera", "Kamerayla ölçüm"),
    "assessment.intro.beta": (
        "Beta: camera measurement for this test is still being validated. Treat the value as an estimate.",
        "Beta: bu test için kamera ölçümü henüz doğrulanıyor. Değeri bir tahmin olarak düşün.",
    ),
    "assessment.intro.useCamera": ("Measure with the camera", "Kamerayla ölç"),
    "assessment.intro.skip": ("Skip this test", "Bu testi atla"),
    "assessment.useManual": ("Measure by hand", "Elle ölç"),
    "assessment.camera.go": ("Go!", "Başla!"),
    "assessment.camera.done": ("Done.", "Bitti."),
    "assessment.camera.denied": (
        "Camera access is off. You can allow it in iOS Settings, or measure this test by hand.",
        "Kamera erişimi kapalı. iOS Ayarlar'dan izin verebilir ya da bu testi elle ölçebilirsin.",
    ),
    "assessment.camera.unavailable": ("The camera isn't available on this device. You can measure this test by hand.", "Bu cihazda kamera kullanılamıyor. Bu testi elle ölçebilirsin."),
    "assessment.camera.noPerson": ("Step into view so your whole body is visible.", "Tüm vücudun görünecek şekilde kadraja gir."),
    "assessment.camera.multiplePeople": ("Make sure only you are in view.", "Kadrajda yalnızca senin olduğundan emin ol."),
    "assessment.camera.jointsNotVisible": ("Turn sideways and step back until your hips, knees and feet are visible.", "Yan dön ve kalçan, dizlerin ve ayakların görünene kadar geri çekil."),
    "assessment.camera.outOfFrame": ("Step back a little — part of your body is out of the picture.", "Biraz geri çekil — vücudunun bir kısmı kadrajın dışında."),
    "assessment.camera.ready": ("Hold still — starting shortly.", "Kıpırdama — birazdan başlıyoruz."),
    "assessment.camera.measuring": ("Keep going at a safe pace.", "Güvenli bir tempoda devam et."),
    "assessment.manual.start": ("Start timer", "Süreyi başlat"),
    "assessment.manual.tapEach": ("Tap once for every repetition", "Her tekrarda bir kez dokun"),
    "assessment.manual.undo": ("Undo last tap", "Son dokunuşu geri al"),
    "assessment.manual.confirmCount": ("Check the count and correct it if needed.", "Sayıyı kontrol et, gerekirse düzelt."),
    "assessment.manual.fiveDone": ("Stop — five stands done", "Durdur — beş kalkış tamam"),
    "assessment.manual.couldNotFinish": ("I couldn't finish", "Tamamlayamadım"),
    "assessment.manual.holdStop": ("Stop timer", "Süreyi durdur"),
    "assessment.manual.reachQuestion": ("How far could you comfortably raise your arm?", "Kolunu rahatça ne kadar kaldırabildin?"),
    "assessment.result.save": ("Save result", "Sonucu kaydet"),
    "assessment.result.continue": ("Continue", "Devam"),
    "assessment.result.retry": ("Try again", "Tekrar dene"),
    "assessment.result.cameraEstimate": ("Camera estimate. You can measure by hand instead if it looks wrong.", "Kamera tahmini. Yanlış görünüyorsa elle de ölçebilirsin."),
    "assessment.result.manualNote": ("Measured by you.", "Senin ölçümün."),
    "assessment.result.lowQuality": (
        "We couldn't measure this reliably, so no result was saved. Try again with better lighting and your whole body in view, or measure by hand.",
        "Bunu güvenilir şekilde ölçemedik, bu yüzden sonuç kaydedilmedi. Daha iyi ışıkta ve tüm vücudun görünürken tekrar dene ya da elle ölç.",
    ),
    "assessment.result.notCompleted": ("Not completed — that's completely fine. We'll note it and build from where you are.", "Tamamlanmadı — bu tamamen normal. Bunu not edip bulunduğun yerden ilerleyeceğiz."),
    "assessment.summary.title": ("Your results", "Sonuçların"),
    "assessment.summary.note": ("Results are compared only with your own future checks done the same way.", "Sonuçlar yalnızca aynı şekilde yapılan kendi sonraki ölçümlerinle karşılaştırılır."),
    "assessment.summary.save": ("Save capacity check", "Değerlendirmeyi kaydet"),
    "assessment.summary.skipped": ("Skipped", "Atlandı"),
    "assessment.summary.noResult": ("No result", "Sonuç yok"),
    "assessment.saved.title": ("Capacity check saved", "Değerlendirme kaydedildi"),
    "assessment.saved.message": ("Your capacity map is updated. We'll suggest the next check in four weeks.", "Kapasite haritan güncellendi. Bir sonraki değerlendirmeyi dört hafta sonra önereceğiz."),
    "measurement.reps %lld": ("%lld reps", "%lld tekrar"),
    "measurement.seconds %@": ("%@ s", "%@ sn"),
    "measurement.degrees %lld": ("%lld°", "%lld°"),
    "measurement.level.3": ("Arm fully overhead, beside my ear", "Kolum tamamen yukarıda, kulağımın yanında"),
    "measurement.level.2": ("Most of the way up", "Büyük ölçüde yukarıda"),
    "measurement.level.1": ("Less than halfway", "Yarıdan az"),

    # Progress
    "progress.metric.first": ("First measurement. Reassess in four weeks to see your change.", "İlk ölçüm. Değişimini görmek için dört hafta sonra yeniden değerlendir."),
    "progress.metric.notComparable": (
        "Earlier results were measured differently, so they aren't compared with this one.",
        "Önceki sonuçlar farklı şekilde ölçüldüğü için bununla karşılaştırılmıyor.",
    ),
    "progress.metric.camera": ("Camera estimate", "Kamera tahmini"),
    "progress.metric.manual": ("Measured by you", "Senin ölçümün"),
    "progress.metric.baseline %@ %@": ("Baseline: %1$@ on %2$@", "Başlangıç: %1$@ (%2$@)"),
    "progress.chart.label": ("Results over time", "Zaman içindeki sonuçlar"),
    "progress.consistency.title": ("Consistency", "Tutarlılık"),
    "progress.consistency.empty": ("Your training history will appear here.", "Antrenman geçmişin burada görünecek."),
    "progress.consistency.last30 %lld %lld": ("Last 30 days: %1$lld of %2$lld planned sessions", "Son 30 gün: %2$lld planlı seanstan %1$lld tanesi"),
    "progress.consistency.note": ("Every session counts — there are no streaks to lose.", "Her seans önemli — kaybedilecek bir seri yok."),
    "progress.proof.title": ("Proof of progress", "Gelişimin kanıtı"),
    "progress.proof.workouts %lld %lld": ("Workouts in the last 4 weeks: %1$lld of %2$lld", "Son 4 haftadaki antrenmanlar: %2$lld seanstan %1$lld tanesi"),
    "progress.proof.noLoads": ("Weights you use with dumbbells will appear here.", "Dambılla kullandığın ağırlıklar burada görünecek."),
    "progress.locked.change": ("See how much you've changed with Strengthspan Pro.", "Ne kadar değiştiğini Strengthspan Pro ile gör."),
    "progress.locked.proof": ("Your four-week progress report is part of Strengthspan Pro.", "Dört haftalık gelişim raporun Strengthspan Pro'nun bir parçası."),
    "progress.locked.action": ("See Pro plans", "Pro planlarına bak"),

    # Paywall
    "paywall.title": ("Strengthspan Pro", "Strengthspan Pro"),
    "paywall.subtitle": ("Keep training with a plan that adapts to you, and see your progress in numbers.", "Sana uyum sağlayan bir planla devam et ve gelişimini rakamlarla gör."),
    "paywall.benefit.plan": ("Your personal weekly plan", "Kişisel haftalık planın"),
    "paywall.benefit.adapt": ("Automatic, safe progression", "Otomatik ve güvenli ilerleme"),
    "paywall.benefit.reassess": ("Capacity check every four weeks", "Dört haftada bir kapasite değerlendirmesi"),
    "paywall.benefit.progress": ("Before-and-after comparisons and charts", "Önce-sonra karşılaştırmaları ve grafikler"),
    "paywall.benefit.health": ("Save workouts to Apple Health", "Antrenmanları Apple Sağlık'a kaydetme"),
    "paywall.unavailable": ("Plans couldn't be loaded. Check your connection and try again.", "Planlar yüklenemedi. Bağlantını kontrol edip tekrar dene."),
    "paywall.retry": ("Try again", "Tekrar dene"),
    "paywall.trial %@": ("Includes a free trial: %@", "Ücretsiz deneme dahil: %@"),
    "paywall.monthlyEquivalent %@": ("Just %@ per month", "Aylık yalnızca %@"),
    "paywall.pricePer %@ %@": ("%1$@ / %2$@", "%1$@ / %2$@"),
    "paywall.startTrial": ("Start free trial", "Ücretsiz denemeyi başlat"),
    "paywall.subscribe": ("Subscribe", "Abone ol"),
    "paywall.restore": ("Restore purchases", "Satın alımları geri yükle"),
    "paywall.manage": ("Manage subscription", "Aboneliği yönet"),
    "paywall.nothingToRestore": ("No active subscription was found for this Apple Account.", "Bu Apple hesabında etkin bir abonelik bulunamadı."),
    "paywall.pending": ("Your purchase is waiting for approval.", "Satın alımın onay bekliyor."),
    "paywall.failed": ("The purchase couldn't be completed. You haven't been charged.", "Satın alım tamamlanamadı. Ücret alınmadı."),
    "paywall.renewalTerms": (
        "Payment is charged to your Apple Account when you confirm the purchase. The subscription renews automatically unless it is cancelled at least 24 hours before the end of the current period; renewal is charged within 24 hours before the period ends. If you start a free trial, any unused part of it ends when you buy a subscription. You can manage or cancel in your Apple Account settings.",
        "Ödeme, satın almayı onayladığında Apple hesabından alınır. Abonelik, mevcut dönemin bitiminden en az 24 saat önce iptal edilmezse otomatik olarak yenilenir; yenileme ücreti dönem bitmeden önceki 24 saat içinde alınır. Ücretsiz deneme başlatırsan, abonelik satın aldığında denemenin kullanılmayan kısmı sona erer. Aboneliğini Apple hesap ayarlarından yönetebilir veya iptal edebilirsin.",
    ),
    "period.days %lld": ("%lld days", "%lld gün"),
    "period.weeks %lld": ("%lld weeks", "%lld hafta"),
    "period.months %lld": ("%lld months", "%lld ay"),
    "period.years %lld": ("%lld years", "%lld yıl"),

    # Settings
    "settings.section.subscription": ("Subscription", "Abonelik"),
    "settings.subscription.status": ("Plan", "Plan"),
    "settings.subscription.pro": ("Strengthspan Pro", "Strengthspan Pro"),
    "settings.subscription.free": ("Free", "Ücretsiz"),
    "settings.subscription.seePlans": ("See Pro plans", "Pro planlarına bak"),
    "settings.appleHealth": ("Save workouts to Apple Health", "Antrenmanları Apple Sağlık'a kaydet"),
    "settings.appleHealth.footer": ("Strengthspan only writes completed workouts and never reads your health data. Pro feature.", "Strengthspan yalnızca tamamlanan antrenmanları yazar, sağlık verilerini asla okumaz. Pro özelliği."),
    "settings.appleHealth.denied": ("Apple Health access wasn't allowed. You can change this in the Health app under Sharing › Apps.", "Apple Sağlık erişimine izin verilmedi. Bunu Sağlık uygulamasında Paylaşım › Uygulamalar bölümünden değiştirebilirsin."),
    "settings.export": ("Export my data", "Verilerimi dışa aktar"),
    "settings.export.failure": ("Your data couldn't be exported. Please try again.", "Verilerin dışa aktarılamadı. Lütfen tekrar dene."),
})

# Capacity tests: key → ((EN name, how, camera setup), (TR name, how, camera setup)).
ASSESSMENTS = {
    "chairStand30s": (
        ("30-Second Chair Stand",
         "Sit in the middle of a sturdy chair without wheels, placed against a wall, with your arms crossed over your chest. When the timer starts, stand up fully and sit back down as many times as you can in 30 seconds. Go at a pace that feels safe and stop if you feel unwell.",
         "Lean your iPhone against something stable 2–3 metres away at hip height, so it sees you from the side. Your hips, knees and ankles must stay visible."),
        ("30 Saniye Sandalyeden Kalkma",
         "Duvara dayalı, tekerleksiz sağlam bir sandalyenin ortasına otur, kollarını göğsünde çaprazla. Süre başlayınca 30 saniye içinde olabildiğince çok kez tamamen ayağa kalk ve geri otur. Güvenli hissettiğin bir tempoda yap, kendini iyi hissetmezsen dur.",
         "iPhone'unu 2–3 metre uzakta, kalça hizasında sabit bir yere yasla; seni yandan görsün. Kalçan, dizlerin ve ayak bileklerin görünür kalmalı."),
    ),
    "fiveTimesSitToStand": (
        ("Five Times Sit-to-Stand",
         "Sit in the chair with your arms crossed. When the timer starts, stand up fully and sit down five times as quickly as you safely can. Stop the timer after the fifth stand.",
         "Lean your iPhone against something stable 2–3 metres away at hip height, so it sees you from the side. Your hips, knees and ankles must stay visible."),
        ("5 Kez Oturup Kalkma",
         "Kollarını çaprazlayarak sandalyeye otur. Süre başlayınca güvenli şekilde yapabildiğin en hızlı tempoyla beş kez tamamen kalk ve otur. Beşinci kalkıştan sonra süre durur.",
         "iPhone'unu 2–3 metre uzakta, kalça hizasında sabit bir yere yasla; seni yandan görsün. Kalçan, dizlerin ve ayak bileklerin görünür kalmalı."),
    ),
    "calfRaise30s": (
        ("30-Second Calf Raise",
         "Stand facing a counter and hold it lightly. When the timer starts, rise onto the balls of both feet and lower again, as many times as you can in 30 seconds. Tap once for each rise.",
         "This test is counted by hand."),
        ("30 Saniye Topuk Kaldırma",
         "Bir tezgâha dönük dur ve hafifçe tutun. Süre başlayınca 30 saniye içinde olabildiğince çok kez iki ayağının parmak uçlarında yüksel ve in. Her yükselişte bir kez dokun.",
         "Bu test elle sayılır."),
    ),
    "supportedSemiTandem": (
        ("Supported Balance Stand",
         "Stand next to a counter with one hand resting on it. Place one foot half a step ahead so its heel is beside the big toe of the other foot. Start the timer and hold the position for up to 30 seconds. Keep your hand on the counter, and stop the timer if you need to step out.",
         "This test is measured by hand."),
        ("Destekli Denge Duruşu",
         "Bir elin tezgâhın üzerinde, tezgâhın yanında dur. Bir ayağını yarım adım öne al; topuğu diğer ayağının başparmağının yanında olsun. Süreyi başlat ve bu duruşu en fazla 30 saniye koru. Elin tezgâhta kalsın; adım atman gerekirse süreyi durdur.",
         "Bu test elle ölçülür."),
    ),
    "overheadReach": (
        ("Overhead Reach",
         "Stand tall with your arms by your sides. Slowly raise one arm forward and up as high as is comfortable, then lower it. Don't force the movement.",
         "Place your iPhone 2 metres away at chest height so it sees you from the side. Your hip, shoulder, elbow and wrist must be visible."),
        ("Baş Üstüne Uzanma",
         "Kolların yanlarda, dik dur. Bir kolunu yavaşça önden yukarı, rahat edebildiğin kadar kaldır, sonra indir. Hareketi zorlama.",
         "iPhone'unu 2 metre uzakta, göğüs hizasında yerleştir; seni yandan görsün. Kalçan, omzun, dirseğin ve bileğin görünür olmalı."),
    ),
}

for _key, ((_en_name, _en_how, _en_setup), (_tr_name, _tr_how, _tr_setup)) in ASSESSMENTS.items():
    STRINGS[f"assessment.{_key}"] = (_en_name, _tr_name)
    STRINGS[f"assessment.{_key}.how"] = (_en_how, _tr_how)
    STRINGS[f"assessment.{_key}.setup"] = (_en_setup, _tr_setup)

# Info.plist strings: permission prompts and display name.
INFO_PLIST = {
    "CFBundleDisplayName": ("Strengthspan", "Strengthspan"),
    "NSCameraUsageDescription": (
        "Strengthspan uses the camera only during a capacity check to count your movements on this iPhone. Images are never saved or sent anywhere.",
        "Strengthspan kamerayı yalnızca kapasite değerlendirmesi sırasında, hareketlerini bu iPhone'da saymak için kullanır. Görüntüler asla kaydedilmez veya gönderilmez.",
    ),
    "NSHealthUpdateUsageDescription": ("Strengthspan can save your completed workouts to Apple Health.", "Strengthspan tamamladığın antrenmanları Apple Sağlık'a kaydedebilir."),
    "NSHealthShareUsageDescription": ("Strengthspan does not read your Apple Health data.", "Strengthspan Apple Sağlık verilerini okumaz."),
}


def unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def catalog(table: dict) -> dict:
    return {
        "sourceLanguage": "en",
        "strings": {
            key: {
                "extractionState": "manual",
                "localizations": {"en": unit(en), "tr": unit(tr)},
            }
            for key, (en, tr) in sorted(table.items())
        },
        "version": "1.0",
    }


def main() -> None:
    resources = pathlib.Path(__file__).resolve().parent.parent / "Strengthspan" / "Resources"
    resources.mkdir(parents=True, exist_ok=True)
    for name, table in (("Localizable.xcstrings", STRINGS), ("InfoPlist.xcstrings", INFO_PLIST)):
        out = resources / name
        out.write_text(json.dumps(catalog(table), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Wrote {len(table)} keys to {out}")


if __name__ == "__main__":
    main()
