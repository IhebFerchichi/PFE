package iheb_ferchichi.batterypack_backend.repository;

import iheb_ferchichi.batterypack_backend.entity.SupercapPackData;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

public interface SupercapPackDataRepository extends JpaRepository<SupercapPackData, Long> {
    Optional<SupercapPackData> findTopByOrderByTsDesc();
    List<SupercapPackData> findByTsBetweenOrderByTsAsc(OffsetDateTime from, OffsetDateTime to);
}
