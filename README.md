# Belikita - Tugas Besar PPB (E-Commerce App)

Aplikasi E-Commerce mobile bernama **Belikita** yang dikembangkan untuk Tugas Akhir / Tugas Besar Mata Kuliah **Program Perangkat Bergerak (PPB)**. Proyek ini menggabungkan antarmuka **Flutter (FrontEnd)** dengan backend berbasis **Docker Compose (PHP, MySQL, phpMyAdmin, Google Authenticator)**.

---

## 👥 Tim Pengembang (Kelompok)

- **M. Nashrudin**
- **Abi Bintara**
- **Aditya**
- **M. Ikhsan**
- **M. Reiza**

---

## 🏗️ Struktur Proyek

```text
tugas_uas_ui/
├── FrontEnd/              # Aplikasi Mobile Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── login_page.dart
│   │   └── register_page.dart
│   └── pubspec.yaml
│
└── BackEnd/               # Layanan Backend & Database (Docker Compose)
    ├── docker-compose.yaml
    ├── Dockerfile
    ├── Caddyfile
    ├── .env
    ├── databases/
    ├── htdocs/
    └── README.md
```

---

## ⚡ Panduan Menjalankan Aplikasi

### 1. Menjalankan Backend (Docker Compose)
Pastikan aplikasi **Docker Desktop** sudah aktif di komputer Anda.

```powershell
# Masuk ke folder BackEnd
cd BackEnd

# Jalankan service di background
docker compose up -d --build
```

Setelah berjalan, layanan berikut siap digunakan:
- **API Belikita**: `http://localhost:8080`
- **Login Web Google Authenticator**: `http://localhost:8080/`
- **phpMyAdmin**: `http://localhost:8081` (User: `app` / Pass: `app_secret` atau User: `root` / Pass: `root_secret`)
- **MySQL Database**: `localhost:3306`

*(Opsional) Isi data produk awal ke database:*
```powershell
docker compose exec php php /var/www/html/seed.php
```

---

### 2. Menjalankan FrontEnd (Flutter)
Buka terminal baru di folder `FrontEnd`:

```powershell
# Masuk ke folder FrontEnd
cd FrontEnd

# Install dependensi
flutter pub get

# Jalankan aplikasi (Chrome / Emulator / Desktop)
flutter run
```

> 📌 **Catatan URL API pada Flutter:**
> - Jika menggunakan **Android Emulator**, gunakan base URL: `http://10.0.2.2:8080`
> - Jika menggunakan **Chrome (Web) / Windows App**, gunakan base URL: `http://localhost:8080`
> - Jika menggunakan **HP Fisik**, gunakan IP LAN laptop: `http://<IP-Lokal-Anda>:8080`

---

## 🔑 Fitur Utama
- **Autentikasi 2FA (Google Authenticator TOTP):** Pengamanan login menggunakan kode 6 digit berbasis waktu.
- **Katalog & CRUD Produk:** Mengambil daftar produk, mencari produk, menambah, mengubah, dan menghapus item. *⚒ ON Proccess
- **Database MySQL & phpMyAdmin:** Visualisasi dan manajemen data secara langsung lewat web interface.
- **Cross-Platform UI:** Tampilan responsif modern menggunakan Flutter Material 3.

Untuk rincian dokumentasi endpoint API dan arsitektur backend, silakan baca [BackEnd/README.md](BackEnd/README.md).
