package iheb_ferchichi.batterypack_backend.service;

import iheb_ferchichi.batterypack_backend.auth.entity.PackType;
import iheb_ferchichi.batterypack_backend.dto.ChartMarkerRequest;
import iheb_ferchichi.batterypack_backend.dto.ChartMarkerResponse;
import iheb_ferchichi.batterypack_backend.entity.ChartMarker;
import iheb_ferchichi.batterypack_backend.repository.ChartMarkerRepository;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

@Service
public class ChartMarkerService {

    private static final Set<String> ALLOWED_KEYS = Set.of(
            "lfp-voltage",
            "lfp-current",
            "lfp-temperature",
            "supercap-voltage",
            "supercap-current",
            "supercap-temperature"
    );

    private final ChartMarkerRepository chartMarkerRepository;
    private final TelemetryAccessService telemetryAccessService;

    public ChartMarkerService(ChartMarkerRepository chartMarkerRepository,
                              TelemetryAccessService telemetryAccessService) {
        this.chartMarkerRepository = chartMarkerRepository;
        this.telemetryAccessService = telemetryAccessService;
    }

    public List<ChartMarkerResponse> getMarkers(String userEmail, String packType, String bmsId) {
        PackType normalizedPackType = normalizePackType(packType);
        String normalizedBmsId = normalizeBmsId(bmsId);
        validateAccess(userEmail, normalizedPackType, normalizedBmsId);

        List<ChartMarkerResponse> result = new ArrayList<>();
        for (ChartMarker marker : chartMarkerRepository.findByPackTypeAndBmsIdOrderByMarkedAtAsc(normalizedPackType.name(), normalizedBmsId)) {
            result.add(toResponse(marker));
        }
        return result;
    }

    public ChartMarkerResponse createMarker(String userEmail, ChartMarkerRequest request) {
        PackType normalizedPackType = normalizePackType(request.getPackType());
        String normalizedBmsId = normalizeBmsId(request.getBmsId());
        validateAccess(userEmail, normalizedPackType, normalizedBmsId);
        validateChartKey(request.getChartKey(), request.getCellIndex(), normalizedPackType);

        ChartMarker marker = new ChartMarker();
        marker.setPackType(normalizedPackType.name());
        marker.setBmsId(normalizedBmsId);
        marker.setChartKey(request.getChartKey());
        marker.setCellIndex(request.getCellIndex() == null ? null : request.getCellIndex().shortValue());
        marker.setCreatedBy(userEmail);
        marker.setMarkedAt(OffsetDateTime.now());
        marker.setCreatedAt(OffsetDateTime.now());

        return toResponse(chartMarkerRepository.save(marker));
    }

    private void validateAccess(String userEmail, PackType packType, String bmsId) {
        if (!telemetryAccessService.canAccessBms(userEmail, packType, bmsId)) {
            throw new IllegalArgumentException("You do not have access to this pack marker context.");
        }
    }

    private void validateChartKey(String chartKey, Integer cellIndex, PackType packType) {
        if (chartKey == null || chartKey.isBlank()) {
            throw new IllegalArgumentException("chartKey is required.");
        }

        if (chartKey.startsWith("lfp-cell-")) {
            if (packType != PackType.LFP) {
                throw new IllegalArgumentException("Cell marker does not match pack type.");
            }
            validateCellKey(chartKey, cellIndex);
            return;
        }

        if (chartKey.startsWith("sc-cell-")) {
            if (packType != PackType.SUPERCAP) {
                throw new IllegalArgumentException("Cell marker does not match pack type.");
            }
            validateCellKey(chartKey, cellIndex);
            return;
        }

        if (!ALLOWED_KEYS.contains(chartKey)) {
            throw new IllegalArgumentException("Unsupported chartKey.");
        }

        if (cellIndex != null) {
            throw new IllegalArgumentException("cellIndex is only allowed for cell markers.");
        }
    }

    private void validateCellKey(String chartKey, Integer cellIndex) {
        if (cellIndex == null) {
            throw new IllegalArgumentException("cellIndex is required for cell markers.");
        }

        String expectedSuffix = String.valueOf(cellIndex);
        if (!chartKey.endsWith("-" + expectedSuffix)) {
            throw new IllegalArgumentException("chartKey must match the cellIndex.");
        }
    }

    private PackType normalizePackType(String packType) {
        if (packType == null || packType.isBlank()) {
            throw new IllegalArgumentException("packType is required.");
        }
        return PackType.valueOf(packType.trim().toUpperCase());
    }

    private String normalizeBmsId(String bmsId) {
        if (bmsId == null || bmsId.isBlank()) {
            throw new IllegalArgumentException("bmsId is required.");
        }
        return bmsId.trim();
    }

    private ChartMarkerResponse toResponse(ChartMarker marker) {
        ChartMarkerResponse response = new ChartMarkerResponse();
        response.setId(marker.getId());
        response.setPackType(marker.getPackType());
        response.setBmsId(marker.getBmsId());
        response.setChartKey(marker.getChartKey());
        response.setCellIndex(marker.getCellIndex() == null ? null : (int) marker.getCellIndex());
        response.setMarkedAt(marker.getMarkedAt());
        response.setCreatedBy(marker.getCreatedBy());
        return response;
    }
}
