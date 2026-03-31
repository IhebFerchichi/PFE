package iheb_ferchichi.batterypack_backend.service;



import iheb_ferchichi.batterypack_backend.entity.Alert;
import iheb_ferchichi.batterypack_backend.repository.AlertRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class AlertService {

    private final AlertRepository alertRepository;

    public AlertService(AlertRepository alertRepository) {
        this.alertRepository = alertRepository;
    }

    public Alert createAlert(String packType,
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

        Optional<Alert> existing = alertRepository.findFirstByPackTypeAndAlertCodeAndActiveTrue(packType, alertCode);
        if (existing.isPresent()) {
            return existing.get();
        }

        return createAlert(
                packType, source, alertCode, alertCategory, severity,
                title, message, cellIndex, measuredValue, thresholdValue, unit
        );
    }

    public void resolveIfActive(String packType, String alertCode) {
        Optional<Alert> existing = alertRepository.findFirstByPackTypeAndAlertCodeAndActiveTrue(packType, alertCode);
        if (existing.isPresent()) {
            Alert alert = existing.get();
            alert.setActive(false);
            alert.setResolvedAt(OffsetDateTime.now());
            alert.setUpdatedAt(OffsetDateTime.now());
            alertRepository.save(alert);
        }
    }

    public List<Alert> getActiveAlerts() {
        return alertRepository.findByActiveTrueOrderByCreatedAtDesc();
    }

    public List<Alert> getRecentAlerts() {
        return alertRepository.findTop50ByOrderByCreatedAtDesc();
    }

    public List<Alert> getActiveAlertsByPack(String packType) {
        return alertRepository.findByPackTypeAndActiveTrueOrderByCreatedAtDesc(packType);
    }
}
