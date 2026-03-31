package iheb_ferchichi.batterypack_backend.auth.repository;

import iheb_ferchichi.batterypack_backend.auth.entity.PackageRequest;
import iheb_ferchichi.batterypack_backend.auth.entity.PackageRequestStatus;
import iheb_ferchichi.batterypack_backend.auth.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PackageRequestRepository extends JpaRepository<PackageRequest, Long> {
    List<PackageRequest> findByUserOrderByRequestedAtDesc(User user);
    List<PackageRequest> findByStatusOrderByRequestedAtAsc(PackageRequestStatus status);
}
