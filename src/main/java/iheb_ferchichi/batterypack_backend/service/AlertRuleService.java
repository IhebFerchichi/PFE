package iheb_ferchichi.batterypack_backend.service;

import iheb_ferchichi.batterypack_backend.dto.BqDto;
import iheb_ferchichi.batterypack_backend.dto.PackStatusResponse;
import iheb_ferchichi.batterypack_backend.dto.ProtDto;
import iheb_ferchichi.batterypack_backend.entity.LfpCellData;
import iheb_ferchichi.batterypack_backend.entity.LfpPackData;
import iheb_ferchichi.batterypack_backend.entity.SupercapCellData;
import iheb_ferchichi.batterypack_backend.entity.SupercapPackData;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;

@Service
public class AlertRuleService {

    private static final BigDecimal LFP_TEMP_THRESHOLD = new BigDecimal("60.0");
    private static final BigDecimal SUPERCAP_TEMP_THRESHOLD = new BigDecimal("60.0");

    private static final BigDecimal LFP_IMBALANCE_THRESHOLD = new BigDecimal("0.050");
    private static final BigDecimal SUPERCAP_IMBALANCE_THRESHOLD = new BigDecimal("0.020");

    private final AlertService alertService;
    private final PackStatusService packStatusService;

    public AlertRuleService(AlertService alertService,
                            PackStatusService packStatusService) {
        this.alertService = alertService;
        this.packStatusService = packStatusService;
    }

    // UPDATED SIGNATURES (now accept prot + bq)
    public void evaluateLfp(LfpPackData pack, List<LfpCellData> cells, ProtDto prot, BqDto bq) {
        checkTemperature("LFP", pack.getTemperature(), LFP_TEMP_THRESHOLD);
        checkLfpImbalance(cells);

        evaluateProtFlags("LFP", prot);
        evaluateBqSummary("LFP", bq);
    }

    public void evaluateSupercap(SupercapPackData pack, List<SupercapCellData> cells, ProtDto prot, BqDto bq) {
        checkTemperature("SUPERCAP", pack.getTemperature(), SUPERCAP_TEMP_THRESHOLD);
        checkSupercapImbalance(cells);

        evaluateProtFlags("SUPERCAP", prot);
        evaluateBqSummary("SUPERCAP", bq);
    }

    private void checkTemperature(String packType, BigDecimal temperature, BigDecimal threshold) {
        if (temperature == null) return;

        if (temperature.compareTo(threshold) > 0) {
            alertService.createIfNotActive(
                    packType,
                    "BACKEND",
                    "HIGH_TEMPERATURE",
                    "SENSOR",
                    "WARNING",
                    "High temperature",
                    packType + " temperature exceeded threshold",
                    null,
                    temperature,
                    threshold,
                    "C"
            );
        } else {
            alertService.resolveIfActive(packType, "HIGH_TEMPERATURE");
        }
    }

    private void checkLfpImbalance(List<LfpCellData> cells) {
        if (cells == null || cells.isEmpty()) return;

        BigDecimal min = null;
        BigDecimal max = null;

        for (LfpCellData cell : cells) {
            if (cell.getCellVoltage() == null) continue;

            if (min == null || cell.getCellVoltage().compareTo(min) < 0) min = cell.getCellVoltage();
            if (max == null || cell.getCellVoltage().compareTo(max) > 0) max = cell.getCellVoltage();
        }

        if (min == null || max == null) return;

        BigDecimal imbalance = max.subtract(min);

        if (imbalance.compareTo(LFP_IMBALANCE_THRESHOLD) > 0) {
            alertService.createIfNotActive(
                    "LFP",
                    "BACKEND",
                    "HIGH_IMBALANCE",
                    "SENSOR",
                    "WARNING",
                    "High cell imbalance",
                    "LFP cell imbalance exceeded threshold",
                    null,
                    imbalance,
                    LFP_IMBALANCE_THRESHOLD,
                    "V"
            );
        } else {
            alertService.resolveIfActive("LFP", "HIGH_IMBALANCE");
        }
    }

    private void checkSupercapImbalance(List<SupercapCellData> cells) {
        if (cells == null || cells.isEmpty()) return;

        BigDecimal min = null;
        BigDecimal max = null;

        for (SupercapCellData cell : cells) {
            if (cell.getCellVoltage() == null) continue;

            if (min == null || cell.getCellVoltage().compareTo(min) < 0) min = cell.getCellVoltage();
            if (max == null || cell.getCellVoltage().compareTo(max) > 0) max = cell.getCellVoltage();
        }

        if (min == null || max == null) return;

        BigDecimal imbalance = max.subtract(min);

        if (imbalance.compareTo(SUPERCAP_IMBALANCE_THRESHOLD) > 0) {
            alertService.createIfNotActive(
                    "SUPERCAP",
                    "BACKEND",
                    "HIGH_IMBALANCE",
                    "SENSOR",
                    "WARNING",
                    "High cell imbalance",
                    "Supercap cell imbalance exceeded threshold",
                    null,
                    imbalance,
                    SUPERCAP_IMBALANCE_THRESHOLD,
                    "V"
            );
        } else {
            alertService.resolveIfActive("SUPERCAP", "HIGH_IMBALANCE");
        }
    }

    // =========================
    // NEW: Protection flag alerts
    // =========================

    private static boolean on(Integer x) {
        return x != null && x == 1;
    }

    private void evaluateProtFlags(String packType, ProtDto prot) {
        if (prot == null) return;

        // Alerts (warnings)
        flag(packType, "UV_ALERT",  on(prot.getUv_alert()),  "Cell undervoltage alert",        "BQ/STM reports UV alert",  "WARNING");
        flag(packType, "OV_ALERT",  on(prot.getOv_alert()),  "Cell overvoltage alert",         "BQ/STM reports OV alert",  "WARNING");
        flag(packType, "OCC_ALERT", on(prot.getOcc_alert()), "Overcurrent charge alert",       "BQ/STM reports OCC alert", "WARNING");
        flag(packType, "OCD1_ALERT",on(prot.getOcd1_alert()),"Overcurrent discharge alert",    "BQ/STM reports OCD1 alert","WARNING");
        flag(packType, "SCD_ALERT", on(prot.getScd_alert()), "Short circuit alert",            "BQ/STM reports SCD alert", "CRITICAL");

        // Faults (critical)
        flag(packType, "UV_FAULT",  on(prot.getUv_fault()),  "Cell undervoltage fault",        "BQ/STM reports UV fault",  "CRITICAL");
        flag(packType, "OV_FAULT",  on(prot.getOv_fault()),  "Cell overvoltage fault",         "BQ/STM reports OV fault",  "CRITICAL");
        flag(packType, "OCD1_FAULT",on(prot.getOcd1_fault()),"Overcurrent discharge fault",    "BQ/STM reports OCD1 fault","CRITICAL");
        flag(packType, "SCD_FAULT", on(prot.getScd_fault()), "Short circuit fault",            "BQ/STM reports SCD fault", "CRITICAL");
    }

    private void flag(String packType, String code, boolean isOn, String title, String message, String severity) {
        if (isOn) {
            alertService.createIfNotActive(
                    packType,
                    "BQ",
                    code,
                    "PROTECTION",
                    severity,
                    title,
                    message,
                    null,
                    null,
                    null,
                    null
            );
        } else {
            alertService.resolveIfActive(packType, code);
        }
    }

    // =========================
    // NEW: Summary alerts from BQ status values (until you decode bits precisely)
    // =========================

    private void evaluateBqSummary(String packType, BqDto bq) {
        if (bq == null) return;

        summary(packType, "SAFETY_STATUS_A", bq.getSafety_status_a(), "Safety status A non-zero", "PROTECTION");
        summary(packType, "SAFETY_STATUS_B", bq.getSafety_status_b(), "Safety status B non-zero", "PROTECTION");
        summary(packType, "PF_STATUS_A",     bq.getPf_status_a(),     "PF status A non-zero",     "PERMANENT_FAIL");
        summary(packType, "PF_STATUS_B",     bq.getPf_status_b(),     "PF status B non-zero",     "PERMANENT_FAIL");
    }

    private void summary(String packType, String code, Integer value, String title, String category) {
        if (value != null && value != 0) {
            alertService.createIfNotActive(
                    packType,
                    "BQ",
                    code,
                    category,
                    "CRITICAL",
                    title,
                    code + "=" + value,
                    null,
                    null,
                    null,
                    null
            );
        } else {
            alertService.resolveIfActive(packType, code);
        }
    }

    // =========================
    // Offline detection (unchanged)
    // =========================

    @Scheduled(fixedRate = 10000)
    public void checkOfflinePacks() {
        checkOfflinePack("LFP", packStatusService.getLfpStatus());
        checkOfflinePack("SUPERCAP", packStatusService.getSupercapStatus());
    }

    private void checkOfflinePack(String packType, PackStatusResponse status) {
        if (status == null || status.getOnline() == null || !status.getOnline()) {
            alertService.createIfNotActive(
                    packType,
                    "BACKEND",
                    "PACK_OFFLINE",
                    "COMMUNICATION",
                    "CRITICAL",
                    "Pack offline",
                    packType + " pack is offline or stale",
                    null,
                    null,
                    null,
                    null
            );
        } else {
            alertService.resolveIfActive(packType, "PACK_OFFLINE");
        }
    }
}