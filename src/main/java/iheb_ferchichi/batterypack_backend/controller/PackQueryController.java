package iheb_ferchichi.batterypack_backend.controller;


import iheb_ferchichi.batterypack_backend.auth.dto.VisiblePackResponse;
import iheb_ferchichi.batterypack_backend.auth.entity.PackType;
import iheb_ferchichi.batterypack_backend.auth.service.VisiblePackService;
import iheb_ferchichi.batterypack_backend.entity.LfpCellData;
import iheb_ferchichi.batterypack_backend.entity.LfpPackData;
import iheb_ferchichi.batterypack_backend.entity.SupercapCellData;
import iheb_ferchichi.batterypack_backend.entity.SupercapPackData;
import iheb_ferchichi.batterypack_backend.repository.LfpCellDataRepository;
import iheb_ferchichi.batterypack_backend.repository.LfpPackDataRepository;
import iheb_ferchichi.batterypack_backend.repository.SupercapCellDataRepository;
import iheb_ferchichi.batterypack_backend.repository.SupercapPackDataRepository;
import iheb_ferchichi.batterypack_backend.service.TelemetryAccessService;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;

import static java.lang.StrictMath.clamp;

@RestController
@RequestMapping("/packs")
public class PackQueryController {
    private final LfpPackDataRepository lfpPackRepo;
    private final LfpCellDataRepository lfpCellRepo;
    private final SupercapPackDataRepository scPackRepo;
    private final SupercapCellDataRepository scCellRepo;
    private final TelemetryAccessService telemetryAccessService;
    private final VisiblePackService visiblePackService;

    public PackQueryController(
            LfpPackDataRepository lfpPackRepo,
            LfpCellDataRepository lfpCellRepo,
            SupercapPackDataRepository scPackRepo,
            SupercapCellDataRepository scCellRepo,
            TelemetryAccessService telemetryAccessService,
            VisiblePackService visiblePackService
    ) {
        this.lfpPackRepo = lfpPackRepo;
        this.lfpCellRepo = lfpCellRepo;
        this.scPackRepo = scPackRepo;
        this.scCellRepo = scCellRepo;
        this.telemetryAccessService = telemetryAccessService;
        this.visiblePackService = visiblePackService;
    }

    @GetMapping("/catalog")
    public List<VisiblePackResponse> visiblePacks(Authentication authentication) {
        return visiblePackService.getVisiblePacks(authentication.getName());
    }

    // -------- PACK LATEST --------
    @GetMapping("/lfp/latest")
    public List<LfpPackData> lfpLatest(Authentication authentication, @RequestParam(defaultValue = "50") int limit) {
        limit = clamp(limit, 1, 500);
        if (telemetryAccessService.isAdmin(authentication.getName())) {
            return lfpPackRepo.findAll(PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "ts"))).getContent();
        }

        List<String> bmsIds = telemetryAccessService.getAccessibleBmsIds(authentication.getName(), PackType.LFP);
        if (bmsIds.isEmpty()) {
            return List.of();
        }

        return lfpPackRepo.findByBmsIdInOrderByTsDesc(bmsIds, PageRequest.of(0, limit));
    }

    @GetMapping("/supercap/latest")
    public List<SupercapPackData> supercapLatest(Authentication authentication, @RequestParam(defaultValue = "50") int limit) {
        limit = clamp(limit, 1, 500);
        if (telemetryAccessService.isAdmin(authentication.getName())) {
            return scPackRepo.findAll(PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "ts"))).getContent();
        }

        List<String> bmsIds = telemetryAccessService.getAccessibleBmsIds(authentication.getName(), PackType.SUPERCAP);
        if (bmsIds.isEmpty()) {
            return List.of();
        }

        return scPackRepo.findByBmsIdInOrderByTsDesc(bmsIds, PageRequest.of(0, limit));
    }

    // -------- CELLS LATEST --------

    @GetMapping("/lfp/cells/latest")
    public List<LfpCellData> lfpCellsLatest(Authentication authentication, @RequestParam(defaultValue = "160") int limit) {
        limit = clamp(limit, 1, 5000);
        if (telemetryAccessService.isAdmin(authentication.getName())) {
            return lfpCellRepo.findAll(PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "ts"))).getContent();
        }

        List<String> bmsIds = telemetryAccessService.getAccessibleBmsIds(authentication.getName(), PackType.LFP);
        if (bmsIds.isEmpty()) {
            return List.of();
        }

        return lfpCellRepo.findByPackBmsIdInOrderByTsDesc(bmsIds, PageRequest.of(0, limit));
    }

    @GetMapping("/supercap/cells/latest")
    public List<SupercapCellData> supercapCellsLatest(Authentication authentication, @RequestParam(defaultValue = "160") int limit) {
        limit = clamp(limit, 1, 5000);
        if (telemetryAccessService.isAdmin(authentication.getName())) {
            return scCellRepo.findAll(PageRequest.of(0, limit, Sort.by(Sort.Direction.DESC, "ts"))).getContent();
        }

        List<String> bmsIds = telemetryAccessService.getAccessibleBmsIds(authentication.getName(), PackType.SUPERCAP);
        if (bmsIds.isEmpty()) {
            return List.of();
        }

        return scCellRepo.findByPackBmsIdInOrderByTsDesc(bmsIds, PageRequest.of(0, limit));
    }

    // -------- CELL RANGE (charts) --------

    @GetMapping("/lfp/cells/{cellIndex}/range")
    public List<LfpCellData> lfpCellRange(
            Authentication authentication,
            @PathVariable short cellIndex,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        if (telemetryAccessService.isAdmin(authentication.getName())) {
            return lfpCellRepo.findRange(cellIndex, from, to);
        }

        List<String> bmsIds = telemetryAccessService.getAccessibleBmsIds(authentication.getName(), PackType.LFP);
        if (bmsIds.isEmpty()) {
            return List.of();
        }

        return lfpCellRepo.findByPackBmsIdInAndCellIndexAndTsBetweenOrderByTsAsc(bmsIds, cellIndex, from, to);
    }

    @GetMapping("/supercap/cells/{cellIndex}/range")
    public List<SupercapCellData> supercapCellRange(
            Authentication authentication,
            @PathVariable short cellIndex,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to
    ) {
        if (telemetryAccessService.isAdmin(authentication.getName())) {
            return scCellRepo.findRange(cellIndex, from, to);
        }

        List<String> bmsIds = telemetryAccessService.getAccessibleBmsIds(authentication.getName(), PackType.SUPERCAP);
        if (bmsIds.isEmpty()) {
            return List.of();
        }

        return scCellRepo.findByPackBmsIdInAndCellIndexAndTsBetweenOrderByTsAsc(bmsIds, cellIndex, from, to);
    }

    private int clamp(int v, int min, int max) {
        return Math.max(min, Math.min(max, v));
    }
}
