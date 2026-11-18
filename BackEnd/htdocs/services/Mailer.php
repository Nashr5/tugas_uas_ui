<?php

declare(strict_types=1);

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

final class Mailer
{
    /**
     * Kirim email kode OTP ke user untuk proses Lupa Kata Sandi
     */
    public static function sendOtpEmail(string $recipientEmail, string $recipientName, string $otp): bool
    {
        $smtpHost = Config::smtpHost();

        // Jika SMTP Host belum diatur di environment, catat di log dan kembalikan false
        if (trim($smtpHost) === '') {
            error_log("[Mailer] SMTP_HOST belum dikonfigurasi. Kode OTP untuk {$recipientEmail}: {$otp}");
            return false;
        }

        try {
            $mail = new PHPMailer(true);

            // Server settings
            $mail->isSMTP();
            $mail->Host       = $smtpHost;
            $mail->Port       = Config::smtpPort();
            $mail->CharSet    = 'UTF-8';
            $mail->Timeout    = 10;

            $smtpUser = Config::smtpUser();
            $smtpPass = Config::smtpPassword();
            if ($smtpUser !== '') {
                $mail->SMTPAuth = true;
                $mail->Username = $smtpUser;
                $mail->Password = $smtpPass;
            } else {
                $mail->SMTPAuth = false;
            }

            $encryption = Config::smtpEncryption();
            if ($encryption === 'ssl') {
                $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
            } elseif ($encryption === 'tls') {
                $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            } else {
                $mail->SMTPSecure = '';
                $mail->SMTPAutoTLS = false;
            }

            // Recipients
            $fromEmail = Config::smtpFromEmail();
            $fromName = Config::smtpFromName();
            $mail->setFrom($fromEmail, $fromName);
            $mail->addAddress($recipientEmail, $recipientName !== '' ? $recipientName : $recipientEmail);

            // Content
            $mail->isHTML(true);
            $mail->Subject = "Kode OTP Reset Kata Sandi Belikita: {$otp}";
            $mail->Body    = self::buildHtmlTemplate($recipientName, $otp);
            $mail->AltBody = "Halo " . ($recipientName ?: 'Pengguna') . ",\n\n"
                . "Kode OTP Anda untuk reset kata sandi adalah: {$otp}\n"
                . "Kode ini berlaku selama 15 menit.\n"
                . "Jangan berikan kode ini kepada siapa pun demi keamanan akun Anda.\n\n"
                . "Salam,\nTim Belikita";

            $mail->send();
            return true;
        } catch (PHPMailerException $e) {
            error_log("[Mailer Error] Gagal mengirim email ke {$recipientEmail}: {$e->getMessage()}");
            return false;
        } catch (\Throwable $e) {
            error_log("[Mailer Error] Kesalahan tak terduga: {$e->getMessage()}");
            return false;
        }
    }

    /**
     * Template HTML Email yang modern dan rapi
     */
    private static function buildHtmlTemplate(string $name, string $otp): string
    {
        $displayName = htmlspecialchars($name !== '' ? $name : 'Pengguna Belikita', ENT_QUOTES, 'UTF-8');
        $safeOtp = htmlspecialchars($otp, ENT_QUOTES, 'UTF-8');

        return <<<HTML
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Kata Sandi</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #f4f6f9;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      color: #333333;
    }
    .wrapper {
      width: 100%;
      background-color: #f4f6f9;
      padding: 40px 0;
    }
    .card {
      max-width: 520px;
      margin: 0 auto;
      background: #ffffff;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
    }
    .header {
      background: linear-gradient(135deg, #78A4CB 0%, #5A86AD 100%);
      padding: 32px 24px;
      text-align: center;
      color: #ffffff;
    }
    .header h1 {
      margin: 0;
      font-size: 26px;
      font-weight: 800;
      letter-spacing: 0.5px;
    }
    .header p {
      margin: 6px 0 0 0;
      font-size: 13px;
      color: rgba(255, 255, 255, 0.9);
    }
    .content {
      padding: 32px 28px;
    }
    .greeting {
      font-size: 16px;
      font-weight: 600;
      margin-bottom: 12px;
      color: #222222;
    }
    .desc {
      font-size: 14px;
      line-height: 1.6;
      color: #555555;
      margin-bottom: 24px;
    }
    .otp-container {
      background-color: #f0f5fa;
      border: 2px dashed #78A4CB;
      border-radius: 12px;
      padding: 20px;
      text-align: center;
      margin: 24px 0;
    }
    .otp-code {
      font-size: 34px;
      font-weight: 800;
      letter-spacing: 8px;
      color: #5A86AD;
      font-family: monospace, 'Courier New', Courier;
      margin: 0;
    }
    .otp-expiry {
      font-size: 12px;
      color: #777777;
      margin-top: 8px;
    }
    .warning {
      background-color: #fff9e6;
      border-left: 4px solid #ffb800;
      padding: 12px 16px;
      font-size: 13px;
      color: #8a6d3b;
      border-radius: 4px;
      margin-bottom: 20px;
      line-height: 1.5;
    }
    .footer {
      text-align: center;
      padding: 20px 24px 30px 24px;
      font-size: 12px;
      color: #999999;
      border-top: 1px solid #eeeeee;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="card">
      <div class="header">
        <h1>Belikita</h1>
        <p>Permintaan Reset Kata Sandi Akun</p>
      </div>
      <div class="content">
        <div class="greeting">Halo, {$displayName}!</div>
        <div class="desc">
          Kami menerima permintaan untuk mereset kata sandi akun Belikita Anda. Gunakan kode One-Time Password (OTP) di bawah ini untuk melanjutkan verifikasi:
        </div>

        <div class="otp-container">
          <div class="otp-code">{$safeOtp}</div>
          <div class="otp-expiry">⏱️ Kode berlaku selama <strong>15 menit</strong></div>
        </div>

        <div class="warning">
          <strong>Perhatian Keamanan:</strong> Jangan berikan kode OTP ini kepada siapa pun, termasuk pihak yang mengatasnamakan Belikita. Jika Anda tidak merasa meminta reset kata sandi, akun Anda tetap aman dan Anda dapat mengabaikan email ini.
        </div>
      </div>
      <div class="footer">
        © 2026 Belikita. Semua Hak Cipta Dilindungi.<br>
        Email otomatis, mohon tidak membalas langsung ke alamat ini.
      </div>
    </div>
  </div>
</body>
</html>
HTML;
    }
}
