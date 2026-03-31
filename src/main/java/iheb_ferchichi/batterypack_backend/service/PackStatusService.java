package iheb_ferchichi.batterypack_backend.service;


import iheb_ferchichi.batterypack_backend.dto.PackStatusResponse;
import iheb_ferchichi.batterypack_backend.dto.SystemStatusResponse;
import iheb_ferchichi.batterypack_backend.entity.LfpCellData;
import iheb_ferchichi.batterypack_backend.entity.LfpPackData;
import iheb_ferchichi.batterypack_backend.entity.SupercapCellData;
import iheb_ferchichi.batterypack_backend.entity.SupercapPackData;
import iheb_ferchichi.batterypack_backend.repository.LfpCellDataRepository;
import iheb_ferchichi.batterypack_backend.repository.LfpPackDataRepository;
import iheb_ferchichi.batterypack_backend.repository.SupercapCellDataRepository;
import iheb_ferchichi.batterypack_backend.repository.SupercapPackDataRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class PackStatusService {

    private final LfpPackDataRepository lfpPackRepo;
    private final LfpCellDataRepository lfpCellRepo;
    private final SupercapPackDataRepository supercapPackRepo;
    private final SupercapCellDataRepository supercapCellRepo;

    public PackStatusService(LfpPackDataRepository lfpPackRepo,
                             LfpCellDataRepository lfpCellRepo,
                             SupercapPackDataRepository supercapPackRepo,
                             SupercapCellDataRepository supercapCellRepo) {
        this.lfpPackRepo = lfpPackRepo;
        this.lfpCellRepo = lfpCellRepo;
        this.supercapPackRepo = supercapPackRepo;
        this.supercapCellRepo = supercapCellRepo;
    }

    public PackStatusResponse getLfpStatus() {
        Optional<LfpPackData> opt = lfpPackRepo.findTopByOrderByTsDesc();
        if (opt.isEmpty()) {
            return null;
        }

        LfpPackData pack = opt.get();
        List<LfpCellData> cells = lfpCellRepo.findByPackOrderByCellIndexAsc(pack);

        PackStatusResponse response = new PackStatusResponse();
        response.setPackType("LFP");
        response.setTs(pack.getTs());
        response.setPackVoltage(pack.getPackVoltage());
        response.setPackCurrent(pack.getPackCurrent());
        response.setTemperature(pack.getTemperature());
        response.setStatusFlags(pack.getStatusFlags());

        fillCellStatsForLfp(response, cells);
        fillFreshness(response, pack.getTs());

        return response;
    }

    public PackStatusResponse getSupercapStatus() {
        Optional<SupercapPackData> opt = supercapPackRepo.findTopByOrderByTsDesc();
        if (opt.isEmpty()) {
            return null;
        }

        SupercapPackData pack = opt.get();
        List<SupercapCellData> cells = supercapCellRepo.findByPackOrderByCellIndexAsc(pack);

        PackStatusResponse response = new PackStatusResponse();
        response.setPackType("SUPERCAP");
        response.setTs(pack.getTs());
        response.setPackVoltage(pack.getPackVoltage());
        response.setPackCurrent(pack.getPackCurrent());
        response.setTemperature(pack.getTemperature());
        response.setStatusFlags(pack.getStatusFlags());

        fillCellStatsForSupercap(response, cells);
        fillFreshness(response, pack.getTs());

        return response;
    }

    public SystemStatusResponse getSystemStatus() {
        PackStatusResponse lfp = getLfpStatus();
        PackStatusResponse supercap = getSupercapStatus();

        SystemStatusResponse response = new SystemStatusResponse();
        response.setServerTime(OffsetDateTime.now());
        response.setLfp(lfp);
        response.setSupercap(supercap);

        boolean bothOnline = lfp != null && Boolean.TRUE.equals(lfp.getOnline())
                && supercap != null && Boolean.TRUE.equals(supercap.getOnline());

        response.setBothOnline(bothOnline);

        return response;
    }

    private void fillCellStatsForLfp(PackStatusResponse response, List<LfpCellData> cells) {
        if (cells == null || cells.isEmpty()) {
            response.setBalancingCount(0);
            return;
        }

        BigDecimal min = null;
        BigDecimal max = null;
        BigDecimal sum = BigDecimal.ZERO;
        int count = 0;
        int balancingCount = 0;

        for (LfpCellData cell : cells) {
            BigDecimal v = cell.getCellVoltage();
            if (v != null) {
                if (min == null || v.compareTo(min) < 0) {
                    min = v;
                }
                if (max == null || v.compareTo(max) > 0) {
                    max = v;
                }
                sum = sum.add(v);
                count++;
            }

            if (Boolean.TRUE.equals(cell.getBalancingOn())) {
                balancingCount++;
            }
        }

        response.setMinCellVoltage(min);
        response.setMaxCellVoltage(max);
        response.setBalancingCount(balancingCount);

        if (count > 0) {
            BigDecimal avg = sum.divide(BigDecimal.valueOf(count), 6, RoundingMode.HALF_UP);
            response.setAvgCellVoltage(avg);
        }

        if (min != null && max != null) {
            response.setImbalance(max.subtract(min));
        }
    }

    private void fillCellStatsForSupercap(PackStatusResponse response, List<SupercapCellData> cells) {
        if (cells == null || cells.isEmpty()) {
            response.setBalancingCount(0);
            return;
        }

        BigDecimal min = null;
        BigDecimal max = null;
        BigDecimal sum = BigDecimal.ZERO;
        int count = 0;
        int balancingCount = 0;

        for (SupercapCellData cell : cells) {
            BigDecimal v = cell.getCellVoltage();
            if (v != null) {
                if (min == null || v.compareTo(min) < 0) {
                    min = v;
                }
                if (max == null || v.compareTo(max) > 0) {
                    max = v;
                }
                sum = sum.add(v);
                count++;
            }

            if (Boolean.TRUE.equals(cell.getBalancingOn())) {
                balancingCount++;
            }
        }

        response.setMinCellVoltage(min);
        response.setMaxCellVoltage(max);
        response.setBalancingCount(balancingCount);

        if (count > 0) {
            BigDecimal avg = sum.divide(BigDecimal.valueOf(count), 6, RoundingMode.HALF_UP);
            response.setAvgCellVoltage(avg);
        }

        if (min != null && max != null) {
            response.setImbalance(max.subtract(min));
        }
    }

    private void fillFreshness(PackStatusResponse response, OffsetDateTime ts) {
        if (ts == null) {
            response.setAgeSeconds(null);
            response.setOnline(false);
            return;
        }

        long age = Duration.between(ts, OffsetDateTime.now()).getSeconds();
        response.setAgeSeconds(age);

        // you can tune this threshold later
        response.setOnline(age <= 15);
    }
}
