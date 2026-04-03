package iheb_ferchichi.batterypack_backend.repository;

import iheb_ferchichi.batterypack_backend.entity.SupercapPackData;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

public interface SupercapPackDataRepository extends JpaRepository<SupercapPackData, Long> {
    Optional<SupercapPackData> findTopByOrderByTsDesc();
    Optional<SupercapPackData> findTopByBmsIdOrderByTsDesc(String bmsId);
    Optional<SupercapPackData> findTopByBmsIdInOrderByTsDesc(List<String> bmsIds);
    List<SupercapPackData> findByBmsIdInOrderByTsDesc(List<String> bmsIds, Pageable pageable);
    List<SupercapPackData> findByTsBetweenOrderByTsAsc(OffsetDateTime from, OffsetDateTime to);
    List<SupercapPackData> findByBmsIdAndTsBetweenOrderByTsAsc(String bmsId, OffsetDateTime from, OffsetDateTime to);
    List<SupercapPackData> findByBmsIdInAndTsBetweenOrderByTsAsc(List<String> bmsIds, OffsetDateTime from, OffsetDateTime to);
}
