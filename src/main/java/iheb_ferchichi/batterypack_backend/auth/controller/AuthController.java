package iheb_ferchichi.batterypack_backend.auth.controller;

import iheb_ferchichi.batterypack_backend.auth.dto.LoginRequest;
import iheb_ferchichi.batterypack_backend.auth.dto.LoginResponse;
import iheb_ferchichi.batterypack_backend.auth.dto.MeResponse;
import iheb_ferchichi.batterypack_backend.auth.dto.AuthMessageResponse;
import iheb_ferchichi.batterypack_backend.auth.dto.ForgotPasswordRequest;
import iheb_ferchichi.batterypack_backend.auth.dto.RegisterRequest;
import iheb_ferchichi.batterypack_backend.auth.dto.ResendVerificationRequest;
import iheb_ferchichi.batterypack_backend.auth.dto.ResetPasswordRequest;
import iheb_ferchichi.batterypack_backend.auth.dto.VerifyEmailRequest;
import iheb_ferchichi.batterypack_backend.auth.entity.User;
import iheb_ferchichi.batterypack_backend.auth.repository.UserRepository;
import iheb_ferchichi.batterypack_backend.auth.service.AuthAccountService;
import iheb_ferchichi.batterypack_backend.auth.service.JwtService;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final AuthAccountService authAccountService;

    public AuthController(
            AuthenticationManager authenticationManager,
            UserRepository userRepository,
            JwtService jwtService,
            AuthAccountService authAccountService
    ) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        this.authAccountService = authAccountService;
    }

    @PostMapping("/login")
    public LoginResponse login(@RequestBody LoginRequest request) {
        String email = request.getEmail() != null ? request.getEmail().trim().toLowerCase() : "";

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Login failed. Please check your email and password."));

        if (!Boolean.TRUE.equals(user.getEmailVerified())) {
            throw new IllegalArgumentException("Please verify your email before signing in.");
        }

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        email,
                        request.getPassword()
                )
        );

        String token = jwtService.generateToken(user);

        return new LoginResponse(
                token,
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getRole().name(),
                user.getEmailVerified()
        );
    }

    @PostMapping("/register")
    public AuthMessageResponse register(@RequestBody RegisterRequest request) {
        return authAccountService.register(request);
    }

    @PostMapping("/verify-email")
    public AuthMessageResponse verifyEmail(@RequestBody VerifyEmailRequest request) {
        return authAccountService.verifyEmail(request.getToken());
    }

    @PostMapping("/resend-verification")
    public AuthMessageResponse resendVerification(@RequestBody ResendVerificationRequest request) {
        return authAccountService.resendVerification(request.getEmail());
    }

    @PostMapping("/forgot-password")
    public AuthMessageResponse forgotPassword(@RequestBody ForgotPasswordRequest request) {
        return authAccountService.requestPasswordReset(request.getEmail());
    }

    @PostMapping("/reset-password")
    public AuthMessageResponse resetPassword(@RequestBody ResetPasswordRequest request) {
        return authAccountService.resetPassword(request);
    }

    @GetMapping("/me")
    public MeResponse me(Authentication authentication) {
        UserDetails principal = (UserDetails) authentication.getPrincipal();

        User user = userRepository.findByEmail(principal.getUsername())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        return new MeResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getRole().name(),
                user.getEmailVerified()
        );
    }
}
