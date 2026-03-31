package iheb_ferchichi.batterypack_backend.service;



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

    public HistoryService(LfpPackDataRepository lfpPackRepo,
                          LfpCellDataRepository lfpCellRepo,
                          SupercapPackDataRepository supercapPackRepo,
                          SupercapCellDataRepository supercapCellRepo) {
        this.lfpPackRepo = lfpPackRepo;
        this.lfpCellRepo = lfpCellRepo;
        this.supercapPackRepo = supercapPackRepo;
        this.supercapCellRepo = supercapCellRepo;
    }

    public List<PackHistoryPointResponse> getLfpHistory(OffsetDateTime from, OffsetDateTime to) {
        List<LfpPackData> rows = lfpPackRepo.findByTsBetweenOrderByTsAsc(from, to);
        List<PackHistoryPointResponse> result = new ArrayList<>();

        for (LfpPackData row : rows) {
            PackHistoryPointResponse p = new PackHistoryPointResponse();
            p.setTs(row.getTs());
            p.setPackVoltage(row.getPackVoltage());
            p.setPackCurrent(row.getPackCurrent());
            p.setTemperature(row.getTemperature());
            p.setStatusFlags(row.getStatusFlags());
            result.add(p);
        }

        return result;
    }

    public List<PackHistoryPointResponse> getSupercapHistory(OffsetDateTime from, OffsetDateTime to) {
        List<SupercapPackData> rows = supercapPackRepo.findByTsBetweenOrderByTsAsc(from, to);
        List<PackHistoryPointResponse> result = new ArrayList<>();

        for (SupercapPackData row : rows) {
            PackHistoryPointResponse p = new PackHistoryPointResponse();
            p.setTs(row.getTs());
            p.setPackVoltage(row.getPackVoltage());
            p.setPackCurrent(row.getPackCurrent());
            p.setTemperature(row.getTemperature());
            p.setStatusFlags(row.getStatusFlags());
            result.add(p);
        }

        return result;
    }

    public List<CellHistoryPointResponse> getLfpCellHistory(short cellIndex, OffsetDateTime from, OffsetDateTime to) {
        List<LfpCellData> rows = lfpCellRepo.findByCellIndexAndTsBetweenOrderByTsAsc(cellIndex, from, to);
        List<CellHistoryPointResponse> result = new ArrayList<>();

        for (LfpCellData row : rows) {
            CellHistoryPointResponse p = new CellHistoryPointResponse();
            p.setTs(row.getTs());
            p.setCellIndex((int) row.getCellIndex());
            p.setCellVoltage(row.getCellVoltage());
            p.setBalancingOn(row.getBalancingOn());
            result.add(p);
        }

        return result;
    }

    public List<CellHistoryPointResponse> getSupercapCellHistory(short cellIndex, OffsetDateTime from, OffsetDateTime to) {
        List<SupercapCellData> rows = supercapCellRepo.findByCellIndexAndTsBetweenOrderByTsAsc(cellIndex, from, to);
        List<CellHistoryPointResponse> result = new ArrayList<>();

        for (SupercapCellData row : rows) {
            CellHistoryPointResponse p = new CellHistoryPointResponse();
            p.setTs(row.getTs());
            p.setCellIndex((int) row.getCellIndex());
            p.setCellVoltage(row.getCellVoltage());
            p.setBalancingOn(row.getBalancingOn());
            result.add(p);
        }

        return result;
    }
}
