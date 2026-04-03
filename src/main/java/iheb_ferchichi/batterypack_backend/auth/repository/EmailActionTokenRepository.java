package iheb_ferchichi.batterypack_backend.auth.repository;

import iheb_ferchichi.batterypack_backend.auth.entity.EmailActionToken;
import iheb_ferchichi.batterypack_backend.auth.entity.EmailTokenType;
import iheb_ferchichi.batterypack_backend.auth.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

public interface EmailActionTokenRepository extends JpaRepository<EmailActionToken, Long> {
    Optional<EmailActionToken> findByTokenAndUsedAtIsNull(String token);

    List<EmailActionToken> findByUserAndTokenTypeAndUsedAtIsNull(User user, EmailTokenType tokenType);

    List<EmailActionToken> findByExpiresAtBeforeAndUsedAtIsNull(OffsetDateTime cutoff);
}
