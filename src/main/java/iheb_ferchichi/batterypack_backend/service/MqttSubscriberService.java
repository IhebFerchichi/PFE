package iheb_ferchichi.batterypack_backend.service;

import iheb_ferchichi.batterypack_backend.dto.*;
import iheb_ferchichi.batterypack_backend.entity.LfpCellData;
import iheb_ferchichi.batterypack_backend.entity.LfpPackData;
import iheb_ferchichi.batterypack_backend.entity.SupercapCellData;
import iheb_ferchichi.batterypack_backend.entity.SupercapPackData;
import iheb_ferchichi.batterypack_backend.repository.LfpCellDataRepository;
import iheb_ferchichi.batterypack_backend.repository.LfpPackDataRepository;
import iheb_ferchichi.batterypack_backend.repository.SupercapCellDataRepository;
import iheb_ferchichi.batterypack_backend.repository.SupercapPackDataRepository;
import jakarta.annotation.PostConstruct;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class MqttSubscriberService {

    private final LfpPackDataRepository lfpPackRepo;
    private final LfpCellDataRepository lfpCellRepo;
    private final SupercapPackDataRepository scPackRepo;
    private final SupercapCellDataRepository scCellRepo;
    private final AlertRuleService alertRuleService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    public MqttSubscriberService(
            LfpPackDataRepository lfpPackRepo,
            LfpCellDataRepository lfpCellRepo,
            SupercapPackDataRepository scPackRepo,
            SupercapCellDataRepository scCellRepo,
            AlertRuleService alertRuleService
    ) {
        this.lfpPackRepo = lfpPackRepo;
        this.lfpCellRepo = lfpCellRepo;
        this.scPackRepo = scPackRepo;
        this.scCellRepo = scCellRepo;
        this.alertRuleService = alertRuleService;
    }

    @Value("${mqtt.broker}") private String broker;
    @Value("${mqtt.client-id}") private String clientId;
    @Value("${mqtt.username:}") private String username;
    @Value("${mqtt.password:}") private String password;

    private static final String TOPIC_LFP = "packs/lfp/telemetry";
    private static final String TOPIC_SC  = "packs/supercap/telemetry";

    @PostConstruct
    public void start() {
        try {
            MqttConnectOptions options = new MqttConnectOptions();
            options.setAutomaticReconnect(true);
            options.setCleanSession(true);
            if (!username.isEmpty()) {
                options.setUserName(username);
                options.setPassword(password.toCharArray());
            }

            MqttClient client = new MqttClient(broker, clientId);
            client.connect(options);

            client.subscribe(TOPIC_LFP, (t, msg) -> handleMessage(t, msg));
            client.subscribe(TOPIC_SC,  (t, msg) -> handleMessage(t, msg));

            System.out.println("MQTT subscribed: " + TOPIC_LFP + " & " + TOPIC_SC);
        } catch (Exception e) {
            System.err.println("MQTT start failed: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void handleMessage(String topic, MqttMessage msg) {
        String payloadStr = new String(msg.getPayload());
        System.out.println("RAW PAYLOAD >>>" + payloadStr + "<<<");

        try {
            TelemetryPayload payload = objectMapper.readValue(payloadStr, TelemetryPayload.class);
            Map<String, Object> raw = objectMapper.readValue(payloadStr, new TypeReference<>() {});

            if (TOPIC_LFP.equals(topic)) {
                saveLfp(payload, raw);
            } else if (TOPIC_SC.equals(topic)) {
                saveSupercap(payload, raw);
            } else {
                System.out.println("Ignoring unknown topic: " + topic);
            }
        } catch (Exception e) {
            System.err.println("MQTT decode/save error: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void requireNonNull(Object obj, String name) {
        if (obj == null) throw new IllegalArgumentException(name + " is required");
    }

    private static void requireSize(List<?> list, int size, String name) {
        if (list.size() != size) throw new IllegalArgumentException(name + " must be size " + size + ", got " + list.size());
    }

    private static boolean isOne(Integer x) {
        return x != null && x == 1;
    }

    @Transactional
    public void saveLfp(TelemetryPayload p, Map<String, Object> raw) {
        OffsetDateTime now = OffsetDateTime.now();

        requireNonNull(p.getMeas(), "meas");
        requireNonNull(p.getBalance(), "balance");
        requireNonNull(p.getMeas().getCell_v(), "meas.cell_v");
        requireNonNull(p.getBalance().getCell_bal(), "balance.cell_bal");

        requireSize(p.getMeas().getCell_v(), 16, "meas.cell_v");
        requireSize(p.getBalance().getCell_bal(), 16, "balance.cell_bal");

        MeasDto meas = p.getMeas();
        BalanceDto bal = p.getBalance();
        ProtDto prot = p.getProt();
        BqDto bq = p.getBq();

        LfpPackData pack = new LfpPackData();
        pack.setTs(now);
        pack.setBmsId(p.getSource() != null ? p.getSource().getBms_id() : null);

        // Pack-level mapping from meas.*
        pack.setPackVoltage(meas.getPack_v());
        pack.setPackCurrent(meas.getCurrent_a());

        // Temperature: choose first sensor if available
        if (meas.getTemp_c() != null && !meas.getTemp_c().isEmpty()) {
            pack.setTemperature(meas.getTemp_c().get(0));
        }

        // Status flags: you can map this however you like; simplest is protections_triggered
        if (prot != null) {
            pack.setStatusFlags(prot.getProtections_triggered());
        }

        // Raw payload always stored
        pack.setRawPayload(raw);

        pack = lfpPackRepo.save(pack);

        // Cell rows from meas.cell_v[] + balance.cell_bal[]
        List<LfpCellData> cells = new ArrayList<>();
        for (int i = 0; i < 16; i++) {
            LfpCellData c = new LfpCellData();
            c.setPack(pack);
            c.setTs(now);
            c.setCellIndex((short) (i + 1));
            c.setCellVoltage(meas.getCell_v().get(i));
            c.setBalancingOn(isOne(bal.getCell_bal().get(i)));
            cells.add(c);
        }
        lfpCellRepo.saveAll(cells);

        // Alerts: include prot + bq so you can create UV/OV/SCD/OCD/etc later
        alertRuleService.evaluateLfp(pack, cells, prot, bq);
    }

    @Transactional
    public void saveSupercap(TelemetryPayload p, Map<String, Object> raw) {
        OffsetDateTime now = OffsetDateTime.now();

        requireNonNull(p.getMeas(), "meas");
        requireNonNull(p.getBalance(), "balance");
        requireNonNull(p.getMeas().getCell_v(), "meas.cell_v");
        requireNonNull(p.getBalance().getCell_bal(), "balance.cell_bal");

        requireSize(p.getMeas().getCell_v(), 16, "meas.cell_v");
        requireSize(p.getBalance().getCell_bal(), 16, "balance.cell_bal");

        MeasDto meas = p.getMeas();
        BalanceDto bal = p.getBalance();
        ProtDto prot = p.getProt();
        BqDto bq = p.getBq();

        SupercapPackData pack = new SupercapPackData();
        pack.setTs(now);
        pack.setBmsId(p.getSource() != null ? p.getSource().getBms_id() : null);

        pack.setPackVoltage(meas.getPack_v());
        pack.setPackCurrent(meas.getCurrent_a());

        if (meas.getTemp_c() != null && !meas.getTemp_c().isEmpty()) {
            pack.setTemperature(meas.getTemp_c().get(0));
        }

        if (prot != null) {
            pack.setStatusFlags(prot.getProtections_triggered());
        }

        pack.setRawPayload(raw);

        pack = scPackRepo.save(pack);

        List<SupercapCellData> cells = new ArrayList<>();
        for (int i = 0; i < 16; i++) {
            SupercapCellData c = new SupercapCellData();
            c.setPack(pack);
            c.setTs(now);
            c.setCellIndex((short) (i + 1));
            c.setCellVoltage(meas.getCell_v().get(i));
            c.setBalancingOn(isOne(bal.getCell_bal().get(i)));
            cells.add(c);
        }
        scCellRepo.saveAll(cells);

        alertRuleService.evaluateSupercap(pack, cells, prot, bq);
    }
}