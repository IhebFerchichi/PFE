package iheb_ferchichi.batterypack_backend.repository;

import iheb_ferchichi.batterypack_backend.entity.ChartMarker;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ChartMarkerRepository extends JpaRepository<ChartMarker, Long> {

    List<ChartMarker> findByPackTypeAndBmsIdOrderByMarkedAtAsc(String packType, String bmsId);
}
