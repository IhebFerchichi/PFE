package iheb_ferchichi.batterypack_backend.auth.service;

import iheb_ferchichi.batterypack_backend.auth.dto.*;
import iheb_ferchichi.batterypack_backend.auth.entity.EmailActionToken;
import iheb_ferchichi.batterypack_backend.auth.entity.EmailTokenType;
import iheb_ferchichi.batterypack_backend.auth.entity.Role;
import iheb_ferchichi.batterypack_backend.auth.entity.User;
import iheb_ferchichi.batterypack_backend.auth.repository.EmailActionTokenRepository;
import iheb_ferchichi.batterypack_backend.auth.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
public class AuthAccountService {

    private final UserRepository userRepository;
    private final EmailActionTokenRepository emailActionTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthEmailService authEmailService;
    private final String frontendBaseUrl;

    public AuthAccountService(UserRepository userRepository,
                              EmailActionTokenRepository emailActionTokenRepository,
                              PasswordEncoder passwordEncoder,
                              AuthEmailService authEmailService,
                              @Value("${app.frontend-base-url:http://localhost:4200}") String frontendBaseUrl) {
        this.userRepository = userRepository;
        this.emailActionTokenRepository = emailActionTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.authEmailService = authEmailService;
        this.frontendBaseUrl = frontendBaseUrl;
    }

    @Transactional
    public AuthMessageResponse register(RegisterRequest request) {
        String fullName = request.getFullName() != null ? request.getFullName().trim() : "";
        String email = normalizeEmail(request.getEmail());
        String password = request.getPassword() != null ? request.getPassword() : "";

        if (fullName.isBlank()) {
            throw new IllegalArgumentException("Full name is required");
        }
        if (email.isBlank()) {
            throw new IllegalArgumentException("Email is required");
        }
        validatePassword(password);

        if (userRepository.findByEmail(email).isPresent()) {
            throw new IllegalArgumentException("An account with this email already exists");
        }

        User user = new User();
        user.setFullName(fullName);
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setRole(Role.USER);
        user.setEnabled(true);
        user.setEmailVerified(false);
        user.setCreatedAt(OffsetDateTime.now());

        User savedUser = userRepository.save(user);
        sendEmailToken(savedUser, EmailTokenType.VERIFY_EMAIL);

        return new AuthMessageResponse("Account created. Please verify your email before signing in.", savedUser.getEmail());
    }

    @Transactional
    public AuthMessageResponse verifyEmail(String token) {
        EmailActionToken actionToken = requireValidToken(token, EmailTokenType.VERIFY_EMAIL);
        User user = actionToken.getUser();
        user.setEmailVerified(true);
        userRepository.save(user);
        markTokenUsed(actionToken);
        expireOpenTokens(user, EmailTokenType.VERIFY_EMAIL);

        return new AuthMessageResponse("Email verified successfully. You can sign in now.", user.getEmail());
    }

    @Transactional
    public AuthMessageResponse resendVerification(String emailRaw) {
        String email = normalizeEmail(emailRaw);
        if (email.isBlank()) {
            throw new IllegalArgumentException("Email is required");
        }

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("No account was found for that email."));

        if (Boolean.TRUE.equals(user.getEmailVerified())) {
            throw new IllegalArgumentException("This account is already verified.");
        }

        sendEmailToken(user, EmailTokenType.VERIFY_EMAIL);
        return new AuthMessageResponse("A new verification email has been sent.", user.getEmail());
    }

    @Transactional
    public AuthMessageResponse requestPasswordReset(String emailRaw) {
        String email = normalizeEmail(emailRaw);
        if (email.isBlank()) {
            throw new IllegalArgumentException("Email is required");
        }

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("No account was found for that email."));

        if (!Boolean.TRUE.equals(user.getEmailVerified())) {
            throw new IllegalArgumentException("Please verify your email before using password reset.");
        }

        sendEmailToken(user, EmailTokenType.RESET_PASSWORD);
        return new AuthMessageResponse("A password reset link has been sent to your email.", user.getEmail());
    }

    @Transactional
    public AuthMessageResponse resetPassword(ResetPasswordRequest request) {
        String token = request.getToken() != null ? request.getToken().trim() : "";
        String password = request.getPassword() != null ? request.getPassword() : "";
        validatePassword(password);

        EmailActionToken actionToken = requireValidToken(token, EmailTokenType.RESET_PASSWORD);
        User user = actionToken.getUser();
        user.setPasswordHash(passwordEncoder.encode(password));
        userRepository.save(user);
        markTokenUsed(actionToken);
        expireOpenTokens(user, EmailTokenType.RESET_PASSWORD);

        return new AuthMessageResponse("Password updated successfully. You can sign in with the new password.", user.getEmail());
    }

    private EmailActionToken requireValidToken(String tokenRaw, EmailTokenType tokenType) {
        String token = tokenRaw != null ? tokenRaw.trim() : "";
        if (token.isBlank()) {
            throw new IllegalArgumentException("Token is required.");
        }

        EmailActionToken actionToken = emailActionTokenRepository.findByTokenAndUsedAtIsNull(token)
                .orElseThrow(() -> new IllegalArgumentException("This link is invalid or has already been used."));

        if (actionToken.getTokenType() != tokenType) {
            throw new IllegalArgumentException("This link is not valid for this action.");
        }

        if (actionToken.getExpiresAt().isBefore(OffsetDateTime.now())) {
            throw new IllegalArgumentException("This link has expired. Please request a new one.");
        }

        return actionToken;
    }

    private void sendEmailToken(User user, EmailTokenType tokenType) {
        expireOpenTokens(user, tokenType);

        EmailActionToken token = new EmailActionToken();
        token.setUser(user);
        token.setTokenType(tokenType);
        token.setToken(UUID.randomUUID().toString());
        token.setCreatedAt(OffsetDateTime.now());
        token.setExpiresAt(tokenType == EmailTokenType.VERIFY_EMAIL
                ? OffsetDateTime.now().plusHours(24)
                : OffsetDateTime.now().plusMinutes(30));

        EmailActionToken savedToken = emailActionTokenRepository.save(token);

        if (tokenType == EmailTokenType.VERIFY_EMAIL) {
            authEmailService.sendVerificationEmail(
                    user.getEmail(),
                    user.getFullName(),
                    frontendBaseUrl + "/verify-email?token=" + savedToken.getToken()
            );
            return;
        }

        authEmailService.sendPasswordResetEmail(
                user.getEmail(),
                user.getFullName(),
                frontendBaseUrl + "/reset-password?token=" + savedToken.getToken()
        );
    }

    private void expireOpenTokens(User user, EmailTokenType tokenType) {
        for (EmailActionToken token : emailActionTokenRepository.findByUserAndTokenTypeAndUsedAtIsNull(user, tokenType)) {
            token.setUsedAt(OffsetDateTime.now());
            emailActionTokenRepository.save(token);
        }
    }

    private void markTokenUsed(EmailActionToken actionToken) {
        actionToken.setUsedAt(OffsetDateTime.now());
        emailActionTokenRepository.save(actionToken);
    }

    private String normalizeEmail(String email) {
        return email != null ? email.trim().toLowerCase() : "";
    }

    private void validatePassword(String password) {
        if (password.isBlank()) {
            throw new IllegalArgumentException("Password is required");
        }

        if (password.length() < 6) {
            throw new IllegalArgumentException("Password must be at least 6 characters");
        }
    }
}
