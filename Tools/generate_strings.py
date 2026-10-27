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
