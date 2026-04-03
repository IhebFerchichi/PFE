package iheb_ferchichi.batterypack_backend.controller;

import iheb_ferchichi.batterypack_backend.dto.ChartMarkerRequest;
import iheb_ferchichi.batterypack_backend.dto.ChartMarkerResponse;
import iheb_ferchichi.batterypack_backend.service.ChartMarkerService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class ChartMarkerController {

    private final ChartMarkerService chartMarkerService;

    public ChartMarkerController(ChartMarkerService chartMarkerService) {
        this.chartMarkerService = chartMarkerService;
    }

    @GetMapping("/packs/markers")
    public List<ChartMarkerResponse> getMarkers(Authentication authentication,
                                                @RequestParam String packType,
                                                @RequestParam String bmsId) {
        return chartMarkerService.getMarkers(authentication.getName(), packType, bmsId);
    }

    @PostMapping("/packs/markers")
    public ChartMarkerResponse createMarker(Authentication authentication,
                                            @RequestBody ChartMarkerRequest request) {
        return chartMarkerService.createMarker(authentication.getName(), request);
    }
}
