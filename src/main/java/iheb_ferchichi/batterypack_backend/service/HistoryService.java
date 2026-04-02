package iheb_ferchichi.batterypack_backend.service;



import iheb_ferchichi.batterypack_backend.auth.entity.PackType;
import iheb_ferchichi.batterypack_backend.dto.CellHistoryPointResponse;
import iheb_ferchichi.batterypack_backend.dto.PackHistoryPointResponse;
import iheb_ferchichi.batterypack_backend.entity.LfpCellData;
import iheb_ferchichi.batterypack_backend.entity.LfpPackData;
import iheb_ferchichi.batterypack_backend.entity.SupercapCellData;
import iheb_ferchichi.batterypack_backend.entity.SupercapPackData;
import iheb_ferchichi.batterypack_backend.repository.LfpCellDataRepository;
import iheb_ferchichi.batterypack_backend.repository.LfpPackDataRepository;
import iheb_ferchichi.batterypack_backend.repository.SupercapCellDataRepository;
import iheb_ferchichi.batterypack_backend.repository.SupercapPackDataRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.time.OffsetDateTime;

@Service
public class HistoryService {

    private final LfpPackDataRepository lfpPackRepo;
    private final LfpCellDataRepository lfpCellRepo;
    private final SupercapPackDataRepository supercapPackRepo;
    private final SupercapCellDataRepository supercapCellRepo;
    private final TelemetryAccessService telemetryAccessService;

    public HistoryService(LfpPackDataRepository lfpPackRepo,
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

    public List<PackHistoryPointResponse> getLfpHistory(String userEmail, String bmsId, OffsetDateTime from, OffsetDateTime to) {
        List<LfpPackData> rows = fetchLfpRows(userEmail, bmsId, from, to);
        List<PackHistoryPointResponse> result = new ArrayList<>();

        for (LfpPackData row : rows) {
            PackHistoryPointResponse p = new PackHistoryPointResponse();
            p.setTs(row.getTs());
            p.setBmsId(row.getBmsId());
            p.setPackVoltage(row.getPackVoltage());
            p.setPackCurrent(row.getPackCurrent());
            p.setTemperature(row.getTemperature());
            p.setStatusFlags(row.getStatusFlags());
            result.add(p);
        }

        return result;
    }

    public List<PackHistoryPointResponse> getSupercapHistory(String userEmail, String bmsId, OffsetDateTime from, OffsetDateTime to) {
        List<SupercapPackData> rows = fetchSupercapRows(userEmail, bmsId, from, to);
        List<PackHistoryPointResponse> result = new ArrayList<>();

        for (SupercapPackData row : rows) {
            PackHistoryPointResponse p = new PackHistoryPointResponse();
            p.setTs(row.getTs());
            p.setBmsId(row.getBmsId());
            p.setPackVoltage(row.getPackVoltage());
            p.setPackCurrent(row.getPackCurrent());
            p.setTemperature(row.getTemperature());
            p.setStatusFlags(row.getStatusFlags());
            result.add(p);
        }

        return result;
    }

    public List<CellHistoryPointResponse> getLfpCellHistory(String userEmail, String bmsId, short cellIndex, OffsetDateTime from, OffsetDateTime to) {
        List<LfpCellData> rows = fetchLfpCellRows(userEmail, bmsId, cellIndex, from, to);
        List<CellHistoryPointResponse> result = new ArrayList<>();

        for (LfpCellData row : rows) {
            CellHistoryPointResponse p = new CellHistoryPointResponse();
            p.setTs(row.getTs());
            p.setBmsId(row.getPack() != null ? row.getPack().getBmsId() : null);
            p.setCellIndex((int) row.getCellIndex());
            p.setCellVoltage(row.getCellVoltage());
            p.setBalancingOn(row.getBalancingOn());
            result.add(p);
        }

        return result;
    }

    public List<CellHistoryPointResponse> getSupercapCellHistory(String userEmail, String bmsId, short cellIndex, OffsetDateTime from, OffsetDateTime to) {
        List<SupercapCellData> rows = fetchSupercapCellRows(userEmail, bmsId, cellIndex, from, to);
        List<CellHistoryPointResponse> result = new ArrayList<>();

        for (SupercapCellData row : rows) {
            CellHistoryPointResponse p = new CellHistoryPointResponse();
            p.setTs(row.getTs());
            p.setBmsId(row.getPack() != null ? row.getPack().getBmsId() : null);
            p.setCellIndex((int) row.getCellIndex());
            p.setCellVoltage(row.getCellVoltage());
            p.setBalancingOn(row.getBalancingOn());
            result.add(p);
        }

        return result;
    }

    private List<LfpPackData> fetchLfpRows(String userEmail, String bmsId, OffsetDateTime from, OffsetDateTime to) {
        if (bmsId != null && !bmsId.isBlank()) {
            if (telemetryAccessService.isAdmin(userEmail)) {
                return lfpPackRepo.findByBmsIdAndTsBetweenOrderByTsAsc(bmsId, from, to);
            }

            List<String> allowed = telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.LFP);
            if (!allowed.contains(bmsId)) {
                return List.of();
            }

            return lfpPackRepo.findByBmsIdInAndTsBetweenOrderByTsAsc(List.of(bmsId), from, to);
        }

        return telemetryAccessService.isAdmin(userEmail)
                ? lfpPackRepo.findByTsBetweenOrderByTsAsc(from, to)
                : lfpPackRepo.findByBmsIdInAndTsBetweenOrderByTsAsc(
                        telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.LFP), from, to);
    }

    private List<SupercapPackData> fetchSupercapRows(String userEmail, String bmsId, OffsetDateTime from, OffsetDateTime to) {
        if (bmsId != null && !bmsId.isBlank()) {
            if (telemetryAccessService.isAdmin(userEmail)) {
                return supercapPackRepo.findByBmsIdAndTsBetweenOrderByTsAsc(bmsId, from, to);
            }

            List<String> allowed = telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.SUPERCAP);
            if (!allowed.contains(bmsId)) {
                return List.of();
            }

            return supercapPackRepo.findByBmsIdInAndTsBetweenOrderByTsAsc(List.of(bmsId), from, to);
        }

        return telemetryAccessService.isAdmin(userEmail)
                ? supercapPackRepo.findByTsBetweenOrderByTsAsc(from, to)
                : supercapPackRepo.findByBmsIdInAndTsBetweenOrderByTsAsc(
                        telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.SUPERCAP), from, to);
    }

    private List<LfpCellData> fetchLfpCellRows(String userEmail, String bmsId, short cellIndex, OffsetDateTime from, OffsetDateTime to) {
        if (bmsId != null && !bmsId.isBlank()) {
            if (telemetryAccessService.isAdmin(userEmail)) {
                return lfpCellRepo.findByPackBmsIdAndCellIndexAndTsBetweenOrderByTsAsc(bmsId, cellIndex, from, to);
            }

            List<String> allowed = telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.LFP);
            if (!allowed.contains(bmsId)) {
                return List.of();
            }

            return lfpCellRepo.findByPackBmsIdInAndCellIndexAndTsBetweenOrderByTsAsc(List.of(bmsId), cellIndex, from, to);
        }

        return telemetryAccessService.isAdmin(userEmail)
                ? lfpCellRepo.findByCellIndexAndTsBetweenOrderByTsAsc(cellIndex, from, to)
                : lfpCellRepo.findByPackBmsIdInAndCellIndexAndTsBetweenOrderByTsAsc(
                        telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.LFP), cellIndex, from, to);
    }

    private List<SupercapCellData> fetchSupercapCellRows(String userEmail, String bmsId, short cellIndex, OffsetDateTime from, OffsetDateTime to) {
        if (bmsId != null && !bmsId.isBlank()) {
            if (telemetryAccessService.isAdmin(userEmail)) {
                return supercapCellRepo.findByPackBmsIdAndCellIndexAndTsBetweenOrderByTsAsc(bmsId, cellIndex, from, to);
            }

            List<String> allowed = telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.SUPERCAP);
            if (!allowed.contains(bmsId)) {
                return List.of();
            }

            return supercapCellRepo.findByPackBmsIdInAndCellIndexAndTsBetweenOrderByTsAsc(List.of(bmsId), cellIndex, from, to);
        }

        return telemetryAccessService.isAdmin(userEmail)
                ? supercapCellRepo.findByCellIndexAndTsBetweenOrderByTsAsc(cellIndex, from, to)
                : supercapCellRepo.findByPackBmsIdInAndCellIndexAndTsBetweenOrderByTsAsc(
                        telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.SUPERCAP), cellIndex, from, to);
    }
}
