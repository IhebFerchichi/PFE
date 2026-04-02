package iheb_ferchichi.batterypack_backend.controller;


import iheb_ferchichi.batterypack_backend.entity.Alert;
import iheb_ferchichi.batterypack_backend.service.AlertService;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class AlertController {

    private final AlertService alertService;

    public AlertController(AlertService alertService) {
        this.alertService = alertService;
    }

    @GetMapping("/alerts/active")
    public List<Alert> getActiveAlerts(Authentication authentication) {
        return alertService.getActiveAlerts(authentication.getName());
    }

    @GetMapping("/alerts/recent")
    public List<Alert> getRecentAlerts(Authentication authentication) {
        return alertService.getRecentAlerts(authentication.getName());
    }

    @GetMapping("/alerts/active/{packType}")
    public List<Alert> getActiveAlertsByPack(Authentication authentication, @PathVariable String packType) {
        return alertService.getActiveAlertsByPack(authentication.getName(), packType.toUpperCase());
    }
}
