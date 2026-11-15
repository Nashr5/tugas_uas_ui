# Belikita Backend API (Docker Compose)

Backend service untuk aplikasi mobile e-commerce **Belikita** (Tugas Besar Pemrograman Perangkat Bergerak / PPB). Service ini dijalankan menggunakan **Docker Compose** dan menyediakan REST API untuk autentikasi **Google Authenticator (TOTP)**, operasi **CRUD Produk**, serta database **MySQL** dengan antarmuka **phpMyAdmin**.

---

## 🏛️ Arsitektur Service

Stack backend terdiri dari:

- **PHP 8.3 FPM**: Menjalankan REST API PHP, kalkulasi TOTP Google Authenticator, dan koneksi ke MySQL via PDO.
- **Caddy 2**: Web server modern dan reverse proxy berkinerja tinggi ke PHP-FPM, dengan konfigurasi CORS siap pakai untuk Flutter.
- **MySQL 8.4 LTS**: Database relasional untuk menyimpan tabel `products` (data persisten disimpan di folder `databases/`).
- **phpMyAdmin**: Web GUI untuk mengelola database dan melihat tabel secara visual.

---

## 🔑 Informasi Akses & Akun

| Service | Host / URL | Port | Kredensial Login |
|---|---|---|---|
| **API Backend & Web Login** | `http://localhost:8080` | `8080` | - |
| **phpMyAdmin** | `http://localhost:8081` | `8081` | User: `app` / Pass: `app_secret`<br>Root: `root` / Pass: `root_secret` |
| **MySQL Database** | `localhost` (atau `mysql` antar-container) | `3306` | Database: `app`<br>User: `app` / Pass: `app_secret` |

> 💡 **Koneksi dari Flutter:**
> - **Windows Desktop / Chrome (Web):** Gunakan `http://localhost:8080`
> - **Android Emulator:** Gunakan `http://10.0.2.2:8080` (karena `localhost` di emulator mengarah ke emulator itu sendiri)
> - **HP Fisik (USB Debugging):** Gunakan IP Wi-Fi laptop Anda (misal `http://192.168.1.xxx:8080`)

---

## ⚙️ Konfigurasi Environment (`.env`)

File `.env` sudah disediakan pada folder ini dengan konfigurasi standar:

```dotenv
# Database MySQL
MYSQL_DATABASE=app
MYSQL_USER=app
MYSQL_PASSWORD=app_secret
MYSQL_ROOT_PASSWORD=root_secret

# Google Authenticator / TOTP
GOOGLE2FA_ACCOUNT=admin@belikita.com
GOOGLE2FA_ISSUER='Belikita'
```

---

## 🚀 Cara Menjalankan

### 1. Menjalankan Container
Buka terminal di folder `BackEnd`:
```bash
docker compose up -d --build
```

### 2. Memeriksa Status Container
```bash
docker compose ps
```

### 3. Melihat Log API
```bash
docker compose logs -f php
```

### 4. Import / Seed Data Contoh Produk (DummyJSON)
Tabel `products` akan otomatis dibuat saat endpoint diakses. Untuk mengisinya dengan data katalog produk:
```bash
docker compose exec php php /var/www/html/seed.php
```

### 5. Menghentikan Service
```bash
docker compose down
```
*(Data database tetap tersimpan dengan aman di folder `databases/`)*.

---

## 🔐 Autentikasi Google Authenticator (TOTP)

### Cara 1: Menggunakan Tampilan Web Bawaan
1. Buka browser ke: `http://localhost:8080/`
2. Buka aplikasi **Google Authenticator** di HP Anda.
3. Scan QR Code yang tampil di layar (atau masukkan Secret Key secara manual).
4. Masukkan kode 6 digit yang muncul di Google Authenticator lalu klik **Login**.

### Cara 2: Integrasi ke Aplikasi Flutter (REST API)

#### A. Mendapatkan Setup QR Code & Secret Key
- **Method:** `GET`
- **Endpoint:** `http://localhost:8080/login`
- **Response:**
  ```json
  {
    "issuer": "Belikita",
    "account": "admin@belikita.com",
    "secret": "JBSWY3DPEHPK3PXP...",
    "otp_auth_url": "otpauth://totp/Belikita:admin@belikita.com?secret=...",
    "qr_code": "<svg ...></svg>"
  }
  ```

#### B. Memverifikasi Kode 6 Digit
- **Method:** `POST`
- **Endpoint:** `http://localhost:8080/login`
- **Headers:** `Content-Type: application/json`
- **Body:**
  ```json
  {
    "code": "123456"
  }
  ```
- **Response Berhasil (HTTP 200):**
  ```json
  {
    "authenticated": true,
    "message": "Authentication successful."
  }
  ```
- **Response Gagal (HTTP 401):**
  ```json
  {
    "message": "Invalid authentication code."
  }
  ```

---

## 📦 REST API CRUD Produk

Semua endpoint produk beralamat di `/products`:

| Aksi | Method | Endpoint | Deskripsi |
|---|---|---|---|
| **Get All** | `GET` | `/products` | Daftar semua produk (mendukung pagination & sorting) |
| **Get Detail** | `GET` | `/products/{id}` | Detail produk berdasarkan ID |
| **Search** | `GET` | `/products/search?q={keyword}` | Pencarian produk berdasarkan nama/kategori |
| **Filter Kategori** | `GET` | `/products/category/{category}` | Filter produk berdasarkan kategori |
| **List Kategori** | `GET` | `/products/categories` | Daftar semua kategori |
| **Create (Add)** | `POST` | `/products/add` | Tambah produk baru |
| **Update** | `PUT` / `PATCH` | `/products/{id}` | Update sebagian atau seluruh data produk |
| **Delete** | `DELETE` | `/products/{id}` | Hapus produk dari database |

### Contoh Request CRUD

#### 1. Tambah Produk (`POST /products/add`)
```json
{
  "title": "Kemeja Polos Pria",
  "description": "Kemeja bahan katun premium nyaman dipakai",
  "category": "mens-shirts",
  "price": 149000,
  "stock": 25,
  "brand": "Belikita Cloth"
}
```

#### 2. Update Produk (`PATCH /products/1`)
```json
{
  "price": 129000,
  "stock": 30
}
```

#### 3. Parameter Query `GET /products`
- `q`: Kata kunci pencarian.
- `limit`: Jumlah item (default `30`, `0` untuk semua).
- `skip`: Offset data.
- `sortBy`: `id`, `title`, `price`, `rating`, `stock`.
- `order`: `asc` atau `desc`.

Contoh: `GET http://localhost:8080/products?limit=10&sortBy=price&order=desc`

---

## 📁 Struktur Direktori Backend

```text
BackEnd/
├── .env                  # Konfigurasi environment (kredensial DB & 2FA)
├── .env.example          # Template konfigurasi environment
├── Caddyfile             # Konfigurasi reverse proxy Caddy
├── Dockerfile            # Image build PHP 8.3 FPM + Extensions
├── docker-compose.yaml   # Konfigurasi orkestrasi container
├── README.md             # Dokumentasi Backend
├── databases/            # Folder penyimpanan file data MySQL
└── htdocs/               # Kode sumber aplikasi PHP
    ├── Config.php        # Konfigurasi koneksi PDO & Google2FA
    ├── Rest.php          # Helper response JSON & CORS
    ├── index.php         # Entry point aplikasi
    ├── seed.php          # Script seeder data DummyJSON
    ├── controller/       # AuthController & ProductController
    ├── models/           # Product model
    ├── routes/           # Routing API (api.php)
    └── views/            # Halaman Web Login (LoginView.php)
```
