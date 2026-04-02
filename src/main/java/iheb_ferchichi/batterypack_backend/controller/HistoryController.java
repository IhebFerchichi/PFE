package iheb_ferchichi.batterypack_backend.controller;



import iheb_ferchichi.batterypack_backend.dto.CellHistoryPointResponse;
import iheb_ferchichi.batterypack_backend.dto.PackHistoryPointResponse;
import iheb_ferchichi.batterypack_backend.service.HistoryService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.Authentication;
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
            Authentication authentication,
            @RequestParam(required = false) String bmsId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return historyService.getLfpHistory(authentication.getName(), bmsId, from, to);
    }

    @GetMapping("/packs/supercap/history")
    public List<PackHistoryPointResponse> getSupercapHistory(
            Authentication authentication,
            @RequestParam(required = false) String bmsId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return historyService.getSupercapHistory(authentication.getName(), bmsId, from, to);
    }

    @GetMapping("/packs/lfp/cells/{cellIndex}/history")
    public List<CellHistoryPointResponse> getLfpCellHistory(
            Authentication authentication,
            @PathVariable short cellIndex,
            @RequestParam(required = false) String bmsId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return historyService.getLfpCellHistory(authentication.getName(), bmsId, cellIndex, from, to);
    }

    @GetMapping("/packs/supercap/cells/{cellIndex}/history")
    public List<CellHistoryPointResponse> getSupercapCellHistory(
            Authentication authentication,
            @PathVariable short cellIndex,
            @RequestParam(required = false) String bmsId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return historyService.getSupercapCellHistory(authentication.getName(), bmsId, cellIndex, from, to);
    }
}
