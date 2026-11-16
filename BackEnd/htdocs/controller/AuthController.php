<?php

declare(strict_types=1);

use BaconQrCode\Renderer\Image\SvgImageBackEnd;
use BaconQrCode\Renderer\ImageRenderer;
use BaconQrCode\Renderer\RendererStyle\RendererStyle;
use BaconQrCode\Writer;
use PragmaRX\Google2FA\Google2FA;

final class AuthController
{
    private Google2FA $google2fa;
    private ?PDO $pdo;

    public function __construct(?PDO $pdo = null)
    {
        $this->google2fa = new Google2FA();
        $this->pdo = $pdo;
    }

    public function initialiseDatabase(): void
    {
        if (!$this->pdo instanceof PDO) {
            return;
        }

        $this->pdo->exec(<<<'SQL'
            CREATE TABLE IF NOT EXISTS users (
                id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                email VARCHAR(191) NOT NULL,
                phone VARCHAR(50) NULL,
                password VARCHAR(255) NOT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE KEY users_email_unique (email)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        SQL);

        // Tambahkan akun default jika belum ada data user sama sekali
        $count = (int) $this->pdo->query('SELECT COUNT(*) FROM users')->fetchColumn();
        if ($count === 0) {
            $stmt = $this->pdo->prepare(
                'INSERT INTO users (name, email, phone, password) VALUES (:name, :email, :phone, :password)'
            );
            $stmt->execute([
                ':name' => 'Admin Belikita',
                ':email' => 'admin@belikita.com',
                ':phone' => '081234567890',
                ':password' => password_hash('password123', PASSWORD_BCRYPT),
            ]);
        }
    }

    public function setup(): void
    {
        $secret = Config::google2faSecret();
        $account = Config::google2faAccount();
        $issuer = Config::google2faIssuer();
        $otpAuthUrl = $this->google2fa->getQRCodeUrl($issuer, $account, $secret);
        $writer = new Writer(new ImageRenderer(new RendererStyle(256), new SvgImageBackEnd()));

        respond([
            'issuer' => $issuer,
            'account' => $account,
            'secret' => $secret,
            'otp_auth_url' => $otpAuthUrl,
            'qr_code' => $writer->writeString($otpAuthUrl),
        ]);
    }

    public function login(): void
    {
        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            fail('Request body harus berupa JSON yang valid.');
        }

        // Login dengan Email & Password (Database MySQL)
        if (isset($body['email'])) {
            if (!$this->pdo instanceof PDO) {
                fail('Koneksi database tidak tersedia.', 500);
            }

            $email = trim((string) ($body['email'] ?? ''));
            $password = (string) ($body['password'] ?? '');

            if ($email === '' || $password === '') {
                fail('Email dan kata sandi wajib diisi.');
            }

            $stmt = $this->pdo->prepare('SELECT id, name, email, phone, password FROM users WHERE email = :email LIMIT 1');
            $stmt->execute([':email' => $email]);
            $user = $stmt->fetch();

            if (!$user || !password_verify($password, (string) $user['password'])) {
                fail('Email atau kata sandi tidak sesuai.', 401);
            }

            unset($user['password']);

            respond([
                'success' => true,
                'message' => 'Login berhasil.',
                'user' => $user,
            ]);
        }

        // Login dengan Kode 6 Digit Google Authenticator
        $code = (string) ($body['code'] ?? '');
        if (!preg_match('/^\d{6}$/', $code)) {
            fail('Kode otentikasi 6 digit atau email & kata sandi diperlukan.');
        }

        $valid = $this->google2fa->verifyKey(Config::google2faSecret(), $code, 1);
        if (!$valid) {
            fail('Kode otentikasi tidak valid.', 401);
        }

        respond([
            'authenticated' => true,
            'message' => 'Otentikasi berhasil.',
        ]);
    }

    public function register(): void
    {
        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            fail('Invalid request body.', 400);
        if (!$this->pdo instanceof PDO) {
            fail('Koneksi database tidak tersedia.', 500);
        }

        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            fail('Request body harus berupa JSON yang valid.');
        }

        $name = trim((string) ($body['name'] ?? ''));
        $email = trim((string) ($body['email'] ?? ''));
        $phone = trim((string) ($body['phone'] ?? ''));
        $password = (string) ($body['password'] ?? '');

        if ($name === '' || $email === '' || $password === '') {
            fail('Name, email, and password are required.', 400);
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            fail('Invalid email format.', 400);
        }

        if (strlen($password) < 6) {
            fail('Password must be at least 6 characters.', 400);
        }

        try {
            // Koneksi langsung via PDO menggunakan environment Docker
            $host = getenv('DB_HOST') ?: 'mysql';
            $dbName = getenv('DB_DATABASE') ?: 'app';
            $username = getenv('DB_USERNAME') ?: 'app';
            $passwordDb = getenv('DB_PASSWORD') ?: 'app_secret';

            $dsn = "mysql:host=$host;dbname=$dbName;charset=utf8mb4";
            $db = new PDO($dsn, $username, $passwordDb, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]);

            // Buat tabel users secara otomatis jika belum tersedia
            $db->exec(<<<'SQL'
                CREATE TABLE IF NOT EXISTS users (
                    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    email VARCHAR(255) NOT NULL,
                    phone VARCHAR(50) NULL,
                    password VARCHAR(255) NOT NULL,
                    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    UNIQUE KEY users_email_unique (email)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            SQL);

            // Cek apakah email sudah terdaftar di database
            $stmt = $db->prepare('SELECT id FROM users WHERE email = ?');
            $stmt->execute([$email]);
            if ($stmt->fetch()) {
                fail('Email is already registered.', 400);
            }

            // Enkripsi password menggunakan bcrypt
            $hashedPassword = password_hash($password, PASSWORD_BCRYPT);

            // Simpan data ke tabel users
            $insertStmt = $db->prepare('INSERT INTO users (name, email, phone, password) VALUES (?, ?, ?, ?)');
            $insertStmt->execute([$name, $email, $phone, $hashedPassword]);

            respond([
                'status' => 'success',
                'message' => 'Pendaftaran berhasil! Silakan masuk.',
            ], 201);
        } catch (\Throwable $e) {
            fail('Database error: ' . $e->getMessage(), 500);
        }
    }
}
