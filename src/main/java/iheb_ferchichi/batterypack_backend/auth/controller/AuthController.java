package iheb_ferchichi.batterypack_backend.auth.controller;

import iheb_ferchichi.batterypack_backend.auth.dto.LoginRequest;
import iheb_ferchichi.batterypack_backend.auth.dto.LoginResponse;
import iheb_ferchichi.batterypack_backend.auth.dto.MeResponse;
import iheb_ferchichi.batterypack_backend.auth.dto.RegisterRequest;
import iheb_ferchichi.batterypack_backend.auth.entity.Role;
import iheb_ferchichi.batterypack_backend.auth.entity.User;
import iheb_ferchichi.batterypack_backend.auth.repository.UserRepository;
import iheb_ferchichi.batterypack_backend.auth.service.JwtService;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;

    public AuthController(
            AuthenticationManager authenticationManager,
            UserRepository userRepository,
            JwtService jwtService,
            PasswordEncoder passwordEncoder
    ) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/login")
    public LoginResponse login(@RequestBody LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        String token = jwtService.generateToken(user);

        return new LoginResponse(
                token,
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getRole().name()
        );
    }

    @PostMapping("/register")
    public LoginResponse register(@RequestBody RegisterRequest request) {
        String fullName = request.getFullName() != null ? request.getFullName().trim() : "";
        String email = request.getEmail() != null ? request.getEmail().trim().toLowerCase() : "";
        String password = request.getPassword() != null ? request.getPassword() : "";

        if (fullName.isBlank()) {
            throw new IllegalArgumentException("Full name is required");
        }

        if (email.isBlank()) {
            throw new IllegalArgumentException("Email is required");
        }

        if (password.isBlank()) {
            throw new IllegalArgumentException("Password is required");
        }

        if (password.length() < 6) {
            throw new IllegalArgumentException("Password must be at least 6 characters");
        }

        if (userRepository.findByEmail(email).isPresent()) {
            throw new IllegalArgumentException("An account with this email already exists");
        }

        User user = new User();
        user.setFullName(fullName);
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setRole(Role.USER);
        user.setEnabled(true);
        user.setCreatedAt(OffsetDateTime.now());

        User savedUser = userRepository.save(user);
        String token = jwtService.generateToken(savedUser);

        return new LoginResponse(
                token,
                savedUser.getId(),
                savedUser.getEmail(),
                savedUser.getFullName(),
                savedUser.getRole().name()
        );
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
                user.getRole().name()
        );
    }
}
