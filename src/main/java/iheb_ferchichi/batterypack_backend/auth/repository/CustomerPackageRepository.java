package iheb_ferchichi.batterypack_backend.auth.repository;

import iheb_ferchichi.batterypack_backend.auth.entity.CustomerPackage;
import iheb_ferchichi.batterypack_backend.auth.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CustomerPackageRepository extends JpaRepository<CustomerPackage, Long> {
    List<CustomerPackage> findByOwnerUserOrderByCreatedAtDesc(User ownerUser);
    Optional<CustomerPackage> findByPackageCode(String packageCode);
}
