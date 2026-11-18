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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

            CREATE TABLE IF NOT EXISTS password_resets (
                id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                email VARCHAR(191) NOT NULL,
                otp VARCHAR(6) NOT NULL,
                expires_at DATETIME NOT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_email (email)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
            fail('Request body harus berupa JSON yang valid.', 400);
        }

        // 1. Login dengan Email & Password (Database MySQL)
        if (isset($body['email'])) {
            if (!$this->pdo instanceof PDO) {
                fail('Koneksi database tidak tersedia.', 500);
            }

            $email = trim((string) ($body['email'] ?? ''));
            $password = (string) ($body['password'] ?? '');

            if ($email === '' || $password === '') {
                fail('Email dan kata sandi wajib diisi.', 400);
            }

            $this->initialiseDatabase();

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

        // 2. Login dengan Kode 6 Digit Google Authenticator (TOTP)
        $code = (string) ($body['code'] ?? '');
        if (!preg_match('/^\d{6}$/', $code)) {
            fail('Kode otentikasi 6 digit atau email & kata sandi diperlukan.', 400);
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
        if (!$this->pdo instanceof PDO) {
            fail('Koneksi database tidak tersedia.', 500);
        }

        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            fail('Request body harus berupa JSON yang valid.', 400);
        }

        $name = trim((string) ($body['name'] ?? ''));
        $email = trim((string) ($body['email'] ?? ''));
        $phone = trim((string) ($body['phone'] ?? ''));
        $password = (string) ($body['password'] ?? '');

        if ($name === '' || $email === '' || $password === '') {
            fail('Nama, email, dan kata sandi wajib diisi.', 400);
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            fail('Format email tidak valid.', 400);
        }

        if (strlen($password) < 6) {
            fail('Kata sandi minimal 6 karakter.', 400);
        }

        try {
            $this->initialiseDatabase();

            // Cek apakah email sudah terdaftar di database
            $stmt = $this->pdo->prepare('SELECT id FROM users WHERE email = :email LIMIT 1');
            $stmt->execute([':email' => $email]);
            if ($stmt->fetch()) {
                fail('Email sudah terdaftar, silakan gunakan email lain.', 400);
            }

            // Enkripsi password menggunakan bcrypt
            $hashedPassword = password_hash($password, PASSWORD_BCRYPT);

            // Simpan data ke tabel users
            $insertStmt = $this->pdo->prepare(
                'INSERT INTO users (name, email, phone, password) VALUES (:name, :email, :phone, :password)'
            );
            $insertStmt->execute([
                ':name' => $name,
                ':email' => $email,
                ':phone' => $phone !== '' ? $phone : null,
                ':password' => $hashedPassword,
            ]);

            respond([
                'success' => true,
                'message' => 'Pendaftaran berhasil! Silakan masuk.',
                'user' => [
                    'id' => (int) $this->pdo->lastInsertId(),
                    'name' => $name,
                    'email' => $email,
                    'phone' => $phone,
                ],
            ], 201);
        } catch (\Throwable $e) {
            fail('Database error: ' . $e->getMessage(), 500);
        }
    }

    public function forgotPassword(): void
    {
        if (!$this->pdo instanceof PDO) {
            fail('Koneksi database tidak tersedia.', 500);
        }

        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            fail('Request body harus berupa JSON yang valid.', 400);
        }

        $email = trim((string) ($body['email'] ?? ''));
        if ($email === '') {
            fail('Email wajib diisi.', 400);
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            fail('Format email tidak valid.', 400);
        }

        $this->initialiseDatabase();

        // Cari user berdasarkan email
        $stmt = $this->pdo->prepare('SELECT id, name, email FROM users WHERE email = :email LIMIT 1');
        $stmt->execute([':email' => $email]);
        $user = $stmt->fetch();

        if (!$user) {
            fail('Email tidak terdaftar dalam sistem.', 404);
        }

        // Generate 6 digit OTP acak
        $otp = (string) random_int(100000, 999999);

        // Hapus kode OTP lama untuk email ini jika ada
        $delStmt = $this->pdo->prepare('DELETE FROM password_resets WHERE email = :email');
        $delStmt->execute([':email' => $email]);

        // Simpan OTP baru ke database (berlaku 15 menit)
        $insStmt = $this->pdo->prepare(
            'INSERT INTO password_resets (email, otp, expires_at) VALUES (:email, :otp, DATE_ADD(NOW(), INTERVAL 15 MINUTE))'
        );
        $insStmt->execute([
            ':email' => $email,
            ':otp' => $otp,
        ]);

        // Kirim email OTP
        $emailSent = Mailer::sendOtpEmail($email, (string) $user['name'], $otp);

        respond([
            'success' => true,
            'message' => 'Kode OTP berhasil dikirim ke ' . $email . '. Silakan periksa kotak masuk atau folder spam email Anda.',
            'email_sent' => $emailSent,
        ]);
    }

    public function verifyOtp(): void
    {
        if (!$this->pdo instanceof PDO) {
            fail('Koneksi database tidak tersedia.', 500);
        }

        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            fail('Request body harus berupa JSON yang valid.', 400);
        }

        $email = trim((string) ($body['email'] ?? ''));
        $otp = trim((string) ($body['otp'] ?? ''));

        if ($email === '' || $otp === '') {
            fail('Email dan kode OTP wajib diisi.', 400);
        }

        if (!preg_match('/^\d{6}$/', $otp)) {
            fail('Kode OTP harus berupa 6 digit angka.', 400);
        }

        $this->initialiseDatabase();

        $stmt = $this->pdo->prepare(
            'SELECT id FROM password_resets WHERE email = :email AND otp = :otp AND expires_at > NOW() ORDER BY id DESC LIMIT 1'
        );
        $stmt->execute([':email' => $email, ':otp' => $otp]);
        $record = $stmt->fetch();

        if (!$record) {
            fail('Kode OTP tidak valid atau telah kadaluarsa.', 400);
        }

        respond([
            'success' => true,
            'message' => 'Kode OTP valid.',
        ]);
    }

    public function resetPassword(): void
    {
        if (!$this->pdo instanceof PDO) {
            fail('Koneksi database tidak tersedia.', 500);
        }

        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            fail('Request body harus berupa JSON yang valid.', 400);
        }

        $email = trim((string) ($body['email'] ?? ''));
        $otp = trim((string) ($body['otp'] ?? ''));
        $password = (string) ($body['password'] ?? '');
        $passwordConfirmation = (string) ($body['password_confirmation'] ?? '');

        if ($email === '' || $otp === '' || $password === '') {
            fail('Email, kode OTP, dan kata sandi baru wajib diisi.', 400);
        }

        if (!preg_match('/^\d{6}$/', $otp)) {
            fail('Kode OTP harus berupa 6 digit angka.', 400);
        }

        if (strlen($password) < 6) {
            fail('Kata sandi baru minimal 6 karakter.', 400);
        }

        if ($passwordConfirmation !== '' && $password !== $passwordConfirmation) {
            fail('Konfirmasi kata sandi tidak cocok.', 400);
        }

        $this->initialiseDatabase();

        // Validasi OTP
        $stmt = $this->pdo->prepare(
            'SELECT id FROM password_resets WHERE email = :email AND otp = :otp AND expires_at > NOW() ORDER BY id DESC LIMIT 1'
        );
        $stmt->execute([':email' => $email, ':otp' => $otp]);
        $record = $stmt->fetch();

        if (!$record) {
            fail('Kode OTP tidak valid atau telah kadaluarsa. Silakan minta kode baru.', 400);
        }

        // Update password user
        $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
        $updateStmt = $this->pdo->prepare(
            'UPDATE users SET password = :password, updated_at = NOW() WHERE email = :email'
        );
        $updateStmt->execute([
            ':password' => $hashedPassword,
            ':email' => $email,
        ]);

        // Hapus kode OTP yang sudah digunakan
        $delStmt = $this->pdo->prepare('DELETE FROM password_resets WHERE email = :email');
        $delStmt->execute([':email' => $email]);

        respond([
            'success' => true,
            'message' => 'Kata sandi Anda berhasil diperbarui! Silakan masuk dengan kata sandi baru.',
        ]);
    }
}
