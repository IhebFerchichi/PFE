package iheb_ferchichi.batterypack_backend.auth.repository;

import iheb_ferchichi.batterypack_backend.auth.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);

}
