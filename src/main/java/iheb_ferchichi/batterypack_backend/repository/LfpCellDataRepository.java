package iheb_ferchichi.batterypack_backend.repository;

import iheb_ferchichi.batterypack_backend.entity.LfpCellData;
import iheb_ferchichi.batterypack_backend.entity.LfpPackData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.awt.print.Pageable;
import java.time.OffsetDateTime;
import java.util.List;

public interface LfpCellDataRepository extends JpaRepository<LfpCellData, Long> {

    @Query("select c from LfpCellData c order by c.ts desc")
    List<LfpCellData> findLatest(Pageable pageable);

    @Query("select c from LfpCellData c where c.cellIndex = :cellIndex and c.ts between :from and :to order by c.ts asc")
    List<LfpCellData> findRange(@Param("cellIndex") short cellIndex,
                                @Param("from") OffsetDateTime from,
                                @Param("to") OffsetDateTime to);

    List<LfpCellData> findByPackOrderByCellIndexAsc(LfpPackData pack);

    List<LfpCellData> findByCellIndexAndTsBetweenOrderByTsAsc(Short cellIndex, OffsetDateTime from, OffsetDateTime to);
}
