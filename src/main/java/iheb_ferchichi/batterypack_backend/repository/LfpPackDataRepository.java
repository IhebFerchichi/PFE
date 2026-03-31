package iheb_ferchichi.batterypack_backend.repository;

import iheb_ferchichi.batterypack_backend.entity.LfpPackData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.awt.print.Pageable;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

public interface LfpPackDataRepository extends JpaRepository<LfpPackData, Long> {
    @Query("select p from LfpPackData p order by p.ts desc")
    List<LfpPackData> findLatest(Pageable pageable);
    Optional<LfpPackData> findTopByOrderByTsDesc();

    List<LfpPackData> findByTsBetweenOrderByTsAsc(OffsetDateTime from, OffsetDateTime to);
}
