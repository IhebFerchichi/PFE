package iheb_ferchichi.batterypack_backend.repository;

import iheb_ferchichi.batterypack_backend.entity.SupercapCellData;
import iheb_ferchichi.batterypack_backend.entity.SupercapPackData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.List;

public interface SupercapCellDataRepository extends JpaRepository<SupercapCellData, Long> {
    @Query("""
        select c
        from SupercapCellData c
        where c.cellIndex = :cellIndex
        and c.ts between :from and :to
        order by c.ts asc
    """)
    List<SupercapCellData> findRange(
            @Param("cellIndex") short cellIndex,
            @Param("from") OffsetDateTime from,
            @Param("to") OffsetDateTime to
    );

    List<SupercapCellData> findByPackOrderByCellIndexAsc(SupercapPackData pack);
    List<SupercapCellData> findByCellIndexAndTsBetweenOrderByTsAsc(Short cellIndex, OffsetDateTime from, OffsetDateTime to);

}
