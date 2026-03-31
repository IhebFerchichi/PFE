package iheb_ferchichi.batterypack_backend.controller;



import iheb_ferchichi.batterypack_backend.dto.CellHistoryPointResponse;
import iheb_ferchichi.batterypack_backend.dto.PackHistoryPointResponse;
import iheb_ferchichi.batterypack_backend.service.HistoryService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.OffsetDateTime;
import java.util.List;

@RestController
public class HistoryController {

    private final HistoryService historyService;

    public HistoryController(HistoryService historyService) {
        this.historyService = historyService;
    }

    @GetMapping("/packs/lfp/history")
    public List<PackHistoryPointResponse> getLfpHistory(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return historyService.getLfpHistory(from, to);
    }

    @GetMapping("/packs/supercap/history")
    public List<PackHistoryPointResponse> getSupercapHistory(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return historyService.getSupercapHistory(from, to);
    }

    @GetMapping("/packs/lfp/cells/{cellIndex}/history")
    public List<CellHistoryPointResponse> getLfpCellHistory(
            @PathVariable short cellIndex,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return historyService.getLfpCellHistory(cellIndex, from, to);
    }

    @GetMapping("/packs/supercap/cells/{cellIndex}/history")
    public List<CellHistoryPointResponse> getSupercapCellHistory(
            @PathVariable short cellIndex,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return historyService.getSupercapCellHistory(cellIndex, from, to);
    }
}
