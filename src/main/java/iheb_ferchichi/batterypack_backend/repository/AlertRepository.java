package iheb_ferchichi.batterypack_backend.repository;

import iheb_ferchichi.batterypack_backend.entity.Alert;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AlertRepository extends JpaRepository<Alert, Long> {
    List<Alert> findByActiveTrueOrderByCreatedAtDesc();

    List<Alert> findTop50ByOrderByCreatedAtDesc();

    List<Alert> findByPackTypeAndActiveTrueOrderByCreatedAtDesc(String packType);

    Optional<Alert> findFirstByPackTypeAndAlertCodeAndActiveTrue(String packType, String alertCode);

}
