package iheb_ferchichi.batterypack_backend.controller;


import iheb_ferchichi.batterypack_backend.entity.Alert;
import iheb_ferchichi.batterypack_backend.service.AlertService;
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
    public List<Alert> getActiveAlerts() {
        return alertService.getActiveAlerts();
    }

    @GetMapping("/alerts/recent")
    public List<Alert> getRecentAlerts() {
        return alertService.getRecentAlerts();
    }

    @GetMapping("/alerts/active/{packType}")
    public List<Alert> getActiveAlertsByPack(@PathVariable String packType) {
        return alertService.getActiveAlertsByPack(packType.toUpperCase());
    }
}
