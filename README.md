# Rus Tili AI Ustoz

Ushbu loyiha Flutter yordamida yaratilgan bo'lib, Google Gemini AI orqali rus tilini o'rganishga yordam beradi.

## Talablar (Avtomatik O'rnatiladi)
- **Flutter SDK**: `install_flutter.bat` orqali avtomatik yuklanadi.
- **Git**: `tools/git` papkasida avtomatik o'rnatiladi.
- **Android Studio / Emulyator**: Ilovani telefonda sinash uchun kerak (yoki USB orqali Android telefon ulang).

## Ishga Tushirish (3 Qadamda)

1.  **Muhitni Tayyorlash**:
    `install_flutter.bat` faylini ustiga ikki marta bosing. (Bir martalik ish).
    *Kuting!* Qora oyna yopilib qolmasa, demak o'rnatish ketmoqda (5-10 daqiqa).

2.  **Ilovani Yurgizish**:
    `start_env.bat` faylini ikki marta bosing.
    Ochilgan oynada quyidagi buyruqni yozing:
    ```cmd
    cd rus_tili_ai_ustoz
    flutter run
    ```

3.  **Telefonda Sinash**:
    Agar emulyatoringiz bo'lmasa, Android telefoningizni USB orqali kompyuterga ulang va `Developer Mode` (USB Debugging)ni yoqing.


4.  **Muhim Sozlamalar (Permissions)**:
    Ilova to'g'ri ishlashi uchun mikrofon va internet ruxsatlarini berishingiz kerak. (Buni men avtomatik qilmoqchiman, lekin `flutter create` buyrug'i hali ishlamagan bo'lsa, fayllar yo'q bo'lishi mumkin).

    Agar fayllar paydo bo'lsa, `android/app/src/main/AndroidManifest.xml` ga quyidagilarni qo'shing:
    ```xml
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    ```

5.  **API Kalit**:
    `.env` faylini oching va `GEMINI_API_KEY` o'rniga o'z kalitingizni qo'ying.

6.  **Ilovani Ishga Tushirish**:
    Telefoningizni ulang yoki emulyatorni yoqing, so'ng:
    ```bash
    flutter run
    ```

Omad! Loyiha `C:\Users\User\.gemini\antigravity\scratch\rus_tili_ai_ustoz` papkasida joylashgan.

## Ilovani APK Qilib Chiqarish (Release)
Do'stlaringizga yuborish uchun:
```cmd
flutter build apk --release
```
APK manzili: `build/app/outputs/flutter-apk/app-release.apk`
