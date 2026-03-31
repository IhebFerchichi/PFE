package iheb_ferchichi.batterypack_backend.controller;


import iheb_ferchichi.batterypack_backend.entity.LfpCellData;
import iheb_ferchichi.batterypack_backend.entity.LfpPackData;
import iheb_ferchichi.batterypack_backend.entity.SupercapCellData;
import iheb_ferchichi.batterypack_backend.entity.SupercapPackData;
import iheb_ferchichi.batterypack_backend.repository.LfpCellDataRepository;
import iheb_ferchichi.batterypack_backend.repository.LfpPackDataRepository;
import iheb_ferchichi.batterypack_backend.repository.SupercapCellDataRepository;
import iheb_ferchichi.batterypack_backend.repository.SupercapPackDataRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;

import static java.lang.StrictMath.clamp;

@RestController
@RequiredArgsConstructor
@RequestMapping("/packs")
public class PackQueryController {
    private final LfpPackDataRepository lfpPackRepo;
    private final LfpCellDataRepository lfpCellRepo;
    private final SupercapPackDataRepository scPackRepo;
    private final SupercapCellDataRepository scCellRepo;

    public PackQueryController(
            LfpPackDataRepository lfpPackRepo,
            LfpCellDataRepository lfpCellRepo,
            SupercapPackDataRepository scPackRepo,
            SupercapCellDataRepository scCellRepo
    ) {
        this.lfpPackRepo = lfpPackRepo;
        this.lfpCellRepo = lfpCellRepo;
        this.scPackRepo = scPackRepo;
        this.scCellRepo = scCellRepo;
    }

    // -------- PACK LATEST --------
    @GetMapping("/lfp/latest")
    public List<LfpPackData> lfpLatest(@RequestParam(defaultValue = "50") int limit) {
        limit = clamp(limit, 1, 500);
        return lfpPackRepo.findAll(PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "ts"))).getContent();
    }

    @GetMapping("/supercap/latest")
    public List<SupercapPackData> supercapLatest(@RequestParam(defaultValue = "50") int limit) {
        limit = clamp(limit, 1, 500);
        return scPackRepo.findAll(PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "ts"))).getContent();
    }

    // -------- CELLS LATEST --------

    @GetMapping("/lfp/cells/latest")
    public List<LfpCellData> lfpCellsLatest(@RequestParam(defaultValue = "160") int limit) {
        limit = clamp(limit, 1, 5000);
        return lfpCellRepo.findAll(PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "ts"))).getContent();
    }

    @GetMapping("/supercap/cells/latest")
    public List<SupercapCellData> supercapCellsLatest(@RequestParam(defaultValue = "160") int limit) {
        limit = clamp(limit, 1, 5000);
        return scCellRepo.findAll(PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "ts"))).getContent();
    }

    // -------- CELL RANGE (charts) --------

    @GetMapping("/lfp/cells/{cellIndex}/range")
    public List<LfpCellData> lfpCellRange(
            @PathVariable short cellIndex,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return lfpCellRepo.findRange(cellIndex, from, to);
    }

    @GetMapping("/supercap/cells/{cellIndex}/range")
    public List<SupercapCellData> supercapCellRange(
            @PathVariable short cellIndex,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        return scCellRepo.findRange(cellIndex, from, to);
    }

    private int clamp(int v, int min, int max) {
        return Math.max(min, Math.min(max, v));
    }
}
