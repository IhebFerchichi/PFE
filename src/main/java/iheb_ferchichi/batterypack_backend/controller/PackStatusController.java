package iheb_ferchichi.batterypack_backend.controller;



import iheb_ferchichi.batterypack_backend.dto.PackStatusResponse;
import iheb_ferchichi.batterypack_backend.dto.SystemStatusResponse;
import iheb_ferchichi.batterypack_backend.service.PackStatusService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class PackStatusController {

    private final PackStatusService packStatusService;

    public PackStatusController(PackStatusService packStatusService) {
        this.packStatusService = packStatusService;
    }

    @GetMapping("/packs/lfp/status")
    public PackStatusResponse getLfpStatus(Authentication authentication) {
        return packStatusService.getLfpStatus(authentication.getName());
    }

    @GetMapping("/packs/supercap/status")
    public PackStatusResponse getSupercapStatus(Authentication authentication) {
        return packStatusService.getSupercapStatus(authentication.getName());
    }

    @GetMapping("/system/status")
    public SystemStatusResponse getSystemStatus(Authentication authentication) {
        return packStatusService.getSystemStatus(authentication.getName());
    }
}
