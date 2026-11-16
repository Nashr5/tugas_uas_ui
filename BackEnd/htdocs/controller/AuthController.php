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

    public function __construct()
    {
        $this->google2fa = new Google2FA();
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
        $code = is_array($body) ? (string) ($body['code'] ?? '') : '';
        if (!preg_match('/^\d{6}$/', $code)) {
            fail('A valid 6-digit authentication code is required.');
        }

        $valid = $this->google2fa->verifyKey(Config::google2faSecret(), $code, 1);
        if (!$valid) {
            fail('Invalid authentication code.', 401);
        }

        respond([
            'authenticated' => true,
            'message' => 'Authentication successful.',
        ]);
    }

    public function register(): void
    {
        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            fail('Invalid request body.', 400);
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