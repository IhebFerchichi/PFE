package iheb_ferchichi.batterypack_backend.repository;

import iheb_ferchichi.batterypack_backend.entity.LfpPackData;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

public interface LfpPackDataRepository extends JpaRepository<LfpPackData, Long> {
    @Query("select p from LfpPackData p order by p.ts desc")
    List<LfpPackData> findLatest(Pageable pageable);
    Optional<LfpPackData> findTopByOrderByTsDesc();
    Optional<LfpPackData> findTopByBmsIdInOrderByTsDesc(List<String> bmsIds);
    List<LfpPackData> findByBmsIdInOrderByTsDesc(List<String> bmsIds, Pageable pageable);

    List<LfpPackData> findByTsBetweenOrderByTsAsc(OffsetDateTime from, OffsetDateTime to);
    List<LfpPackData> findByBmsIdAndTsBetweenOrderByTsAsc(String bmsId, OffsetDateTime from, OffsetDateTime to);
    List<LfpPackData> findByBmsIdInAndTsBetweenOrderByTsAsc(List<String> bmsIds, OffsetDateTime from, OffsetDateTime to);
}
