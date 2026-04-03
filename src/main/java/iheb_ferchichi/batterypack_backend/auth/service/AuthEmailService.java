package iheb_ferchichi.batterypack_backend.auth.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class AuthEmailService {

    private final JavaMailSender mailSender;
    private final String mailMode;
    private final String mailFrom;

    public AuthEmailService(ObjectProvider<JavaMailSender> mailSenderProvider,
                            @Value("${app.mail.mode:log}") String mailMode,
                            @Value("${app.mail.from:no-reply@battery-platform.local}") String mailFrom) {
        this.mailSender = mailSenderProvider.getIfAvailable();
        this.mailMode = mailMode;
        this.mailFrom = mailFrom;
    }

    public void sendVerificationEmail(String email, String fullName, String verificationUrl) {
        String subject = "Verify your Battery Platform account";
        String body = "Hello " + fullName + ",\n\n"
                + "Please verify your account by opening this link:\n"
                + verificationUrl + "\n\n"
                + "If you did not create this account, you can ignore this email.\n";

        send(email, subject, body, "[VERIFY EMAIL]");
    }

    public void sendPasswordResetEmail(String email, String fullName, String resetUrl) {
        String subject = "Reset your Battery Platform password";
        String body = "Hello " + fullName + ",\n\n"
                + "You asked to reset your password. Open this link to continue:\n"
                + resetUrl + "\n\n"
                + "If you did not request this, you can ignore this email.\n";

        send(email, subject, body, "[RESET PASSWORD]");
    }

    private void send(String email, String subject, String body, String logPrefix) {
        if (!"smtp".equalsIgnoreCase(mailMode)) {
            System.out.println(logPrefix + " " + email + " -> " + body);
            return;
        }

        if (mailSender == null) {
            throw new IllegalStateException("SMTP mail mode is enabled, but no JavaMailSender is configured.");
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(mailFrom);
        message.setTo(email);
        message.setSubject(subject);
        message.setText(body);
        mailSender.send(message);
    }
}
