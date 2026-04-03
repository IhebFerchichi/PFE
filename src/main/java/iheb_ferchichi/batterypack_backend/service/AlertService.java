package iheb_ferchichi.batterypack_backend.service;



import iheb_ferchichi.batterypack_backend.entity.Alert;
import iheb_ferchichi.batterypack_backend.auth.entity.PackType;
import iheb_ferchichi.batterypack_backend.repository.AlertRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class AlertService {

    private final AlertRepository alertRepository;
    private final TelemetryAccessService telemetryAccessService;

    public AlertService(AlertRepository alertRepository, TelemetryAccessService telemetryAccessService) {
        this.alertRepository = alertRepository;
        this.telemetryAccessService = telemetryAccessService;
    }

    public Alert createAlert(String packType,
                             String bmsId,
                             String source,
                             String alertCode,
                             String alertCategory,
                             String severity,
                             String title,
                             String message,
                             Short cellIndex,
                             BigDecimal measuredValue,
                             BigDecimal thresholdValue,
                             String unit) {

        Alert alert = new Alert();
        alert.setPackType(packType);
        alert.setBmsId(bmsId);
        alert.setSource(source);
        alert.setAlertCode(alertCode);
        alert.setAlertCategory(alertCategory);
        alert.setSeverity(severity);
        alert.setTitle(title);
        alert.setMessage(message);
        alert.setCellIndex(cellIndex);
        alert.setMeasuredValue(measuredValue);
        alert.setThresholdValue(thresholdValue);
        alert.setUnit(unit);
        alert.setActive(true);
        alert.setAcknowledged(false);
        alert.setCreatedAt(OffsetDateTime.now());
        alert.setUpdatedAt(OffsetDateTime.now());

        return alertRepository.save(alert);
    }

    public Alert createIfNotActive(String packType,
                                   String bmsId,
                                   String source,
                                   String alertCode,
                                   String alertCategory,
                                   String severity,
                                   String title,
                                   String message,
                                   Short cellIndex,
                                   BigDecimal measuredValue,
                                   BigDecimal thresholdValue,
                                   String unit) {

        Optional<Alert> existing = alertRepository.findFirstByPackTypeAndBmsIdAndAlertCodeAndActiveTrue(packType, bmsId, alertCode);
        if (existing.isPresent()) {
            return existing.get();
        }

        return createAlert(
                packType, bmsId, source, alertCode, alertCategory, severity,
                title, message, cellIndex, measuredValue, thresholdValue, unit
        );
    }

    public void resolveIfActive(String packType, String bmsId, String alertCode) {
        Optional<Alert> existing = alertRepository.findFirstByPackTypeAndBmsIdAndAlertCodeAndActiveTrue(packType, bmsId, alertCode);
        if (existing.isPresent()) {
            Alert alert = existing.get();
            alert.setActive(false);
            alert.setResolvedAt(OffsetDateTime.now());
            alert.setUpdatedAt(OffsetDateTime.now());
            alertRepository.save(alert);
        }
    }

    public Alert acknowledgeAlert(String userEmail, Long alertId) {
        Alert alert = findAccessibleAlert(userEmail, alertId);

        if (Boolean.TRUE.equals(alert.getAcknowledged())) {
            return alert;
        }

        alert.setAcknowledged(true);
        alert.setAcknowledgedBy(userEmail);
        alert.setAcknowledgedAt(OffsetDateTime.now());
        alert.setUpdatedAt(OffsetDateTime.now());
        return alertRepository.save(alert);
    }

    public Alert resolveAlert(String userEmail, Long alertId) {
        Alert alert = findAccessibleAlert(userEmail, alertId);

        if (!Boolean.TRUE.equals(alert.getActive())) {
            return alert;
        }

        alert.setActive(false);
        alert.setResolvedAt(OffsetDateTime.now());
        alert.setUpdatedAt(OffsetDateTime.now());
        return alertRepository.save(alert);
    }

    public List<Alert> getActiveAlerts(String userEmail) {
        if (telemetryAccessService.isAdmin(userEmail)) {
            return alertRepository.findByActiveTrueOrderByCreatedAtDesc();
        }

        List<String> bmsIds = getAccessibleAlertBmsIds(userEmail);
        if (bmsIds.isEmpty()) {
            return List.of();
        }

        return alertRepository.findByBmsIdInAndActiveTrueOrderByCreatedAtDesc(bmsIds);
    }

    public List<Alert> getRecentAlerts(String userEmail) {
        if (telemetryAccessService.isAdmin(userEmail)) {
            return alertRepository.findTop50ByOrderByCreatedAtDesc();
        }

        List<String> bmsIds = getAccessibleAlertBmsIds(userEmail);
        if (bmsIds.isEmpty()) {
            return List.of();
        }

        return alertRepository.findTop50ByBmsIdInOrderByCreatedAtDesc(bmsIds);
    }

    public List<Alert> getActiveAlertsByPack(String userEmail, String packType) {
        if (telemetryAccessService.isAdmin(userEmail)) {
            return alertRepository.findByPackTypeAndActiveTrueOrderByCreatedAtDesc(packType);
        }

        List<String> bmsIds = telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.valueOf(packType));
        if (bmsIds.isEmpty()) {
            return List.of();
        }

        return alertRepository.findByBmsIdInAndPackTypeAndActiveTrueOrderByCreatedAtDesc(bmsIds, packType);
    }

    private List<String> getAccessibleAlertBmsIds(String userEmail) {
        List<String> bmsIds = new ArrayList<>();
        bmsIds.addAll(telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.LFP));
        bmsIds.addAll(telemetryAccessService.getAccessibleBmsIds(userEmail, PackType.SUPERCAP));
        return bmsIds;
    }

    private Alert findAccessibleAlert(String userEmail, Long alertId) {
        Alert alert = alertRepository.findById(alertId)
                .orElseThrow(() -> new IllegalArgumentException("Alert not found"));

        if (telemetryAccessService.isAdmin(userEmail)) {
            return alert;
        }

        String bmsId = alert.getBmsId();
        if (bmsId == null || bmsId.isBlank()) {
            throw new IllegalArgumentException("You do not have access to this alert");
        }

        List<String> accessible = getAccessibleAlertBmsIds(userEmail);
        if (!accessible.contains(bmsId)) {
            throw new IllegalArgumentException("You do not have access to this alert");
        }

        return alert;
    }
}
