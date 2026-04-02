package iheb_ferchichi.batterypack_backend.service;


import iheb_ferchichi.batterypack_backend.auth.entity.PackType;
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
    private final TelemetryAccessService telemetryAccessService;

    public PackStatusService(LfpPackDataRepository lfpPackRepo,
                             LfpCellDataRepository lfpCellRepo,
                             SupercapPackDataRepository supercapPackRepo,
                             SupercapCellDataRepository supercapCellRepo,
                             TelemetryAccessService telemetryAccessService) {
        this.lfpPackRepo = lfpPackRepo;
        this.lfpCellRepo = lfpCellRepo;
        this.supercapPackRepo = supercapPackRepo;
        this.supercapCellRepo = supercapCellRepo;
        this.telemetryAccessService = telemetryAccessService;
    }

    public PackStatusResponse getLfpStatus() {
        Optional<LfpPackData> opt = lfpPackRepo.findTopByOrderByTsDesc();
        return opt.map(this::toLfpStatus).orElse(null);
    }

    public PackStatusResponse getLfpStatus(String userEmail) {
        Optional<LfpPackData> opt = telemetryAccessService.isAdmin(userEmail)
                ? lfpPackRepo.findTopByOrderByTsDesc()
                : lfpPackRepo.findTopByBmsIdInOrderByTsDesc(telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.LFP));
        if (opt.isEmpty()) {
            return null;
        }

        return toLfpStatus(opt.get());
    }

    public PackStatusResponse getSupercapStatus() {
        Optional<SupercapPackData> opt = supercapPackRepo.findTopByOrderByTsDesc();
        return opt.map(this::toSupercapStatus).orElse(null);
    }

    public PackStatusResponse getSupercapStatus(String userEmail) {
        Optional<SupercapPackData> opt = telemetryAccessService.isAdmin(userEmail)
                ? supercapPackRepo.findTopByOrderByTsDesc()
                : supercapPackRepo.findTopByBmsIdInOrderByTsDesc(telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.SUPERCAP));
        if (opt.isEmpty()) {
            return null;
        }

        return toSupercapStatus(opt.get());
    }

    public SystemStatusResponse getSystemStatus() {
        PackStatusResponse lfp = getLfpStatus();
        PackStatusResponse supercap = getSupercapStatus();
        return buildSystemStatus(lfp, supercap);
    }

    public SystemStatusResponse getSystemStatus(String userEmail) {
        PackStatusResponse lfp = getLfpStatus(userEmail);
        PackStatusResponse supercap = getSupercapStatus(userEmail);
        return buildSystemStatus(lfp, supercap);
    }

    private SystemStatusResponse buildSystemStatus(PackStatusResponse lfp, PackStatusResponse supercap) {

        SystemStatusResponse response = new SystemStatusResponse();
        response.setServerTime(OffsetDateTime.now());
        response.setLfp(lfp);
        response.setSupercap(supercap);

        boolean bothOnline = lfp != null && Boolean.TRUE.equals(lfp.getOnline())
                && supercap != null && Boolean.TRUE.equals(supercap.getOnline());

        response.setBothOnline(bothOnline);

        return response;
    }

    private PackStatusResponse toLfpStatus(LfpPackData pack) {
        List<LfpCellData> cells = lfpCellRepo.findByPackOrderByCellIndexAsc(pack);

        PackStatusResponse response = new PackStatusResponse();
        response.setPackType("LFP");
        response.setBmsId(pack.getBmsId());
        response.setTs(pack.getTs());
        response.setPackVoltage(pack.getPackVoltage());
        response.setPackCurrent(pack.getPackCurrent());
        response.setTemperature(pack.getTemperature());
        response.setStatusFlags(pack.getStatusFlags());

        fillCellStatsForLfp(response, cells);
        fillFreshness(response, pack.getTs());

        return response;
    }

    private PackStatusResponse toSupercapStatus(SupercapPackData pack) {
        List<SupercapCellData> cells = supercapCellRepo.findByPackOrderByCellIndexAsc(pack);

        PackStatusResponse response = new PackStatusResponse();
        response.setPackType("SUPERCAP");
        response.setBmsId(pack.getBmsId());
        response.setTs(pack.getTs());
        response.setPackVoltage(pack.getPackVoltage());
        response.setPackCurrent(pack.getPackCurrent());
        response.setTemperature(pack.getTemperature());
        response.setStatusFlags(pack.getStatusFlags());

        fillCellStatsForSupercap(response, cells);
        fillFreshness(response, pack.getTs());

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
