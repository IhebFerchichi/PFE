/*package iheb_ferchichi.batterypack_backend.dto;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.List;


public class TelemetryPayload {
    private BigDecimal pack_voltage;
    private BigDecimal pack_current;
    private BigDecimal temperature;
    private Integer status_flags;
    private List<CellData> cells;
    private BqStatus bq;

    public TelemetryPayload() {}
    public BigDecimal getPack_voltage() {return pack_voltage;}
    public BigDecimal getPack_current() {return pack_current;}
    public BigDecimal getTemperature() {return temperature;}
    public Integer getStatus_flags() {return status_flags;}
    public List<CellData> getCells() {return cells;}
}
*/

package iheb_ferchichi.batterypack_backend.dto;

public class TelemetryPayload {

    private String pack_type;
    private SourceDto source;

    private MeasDto meas;
    private BalanceDto balance;
    private FetDto fet;
    private ProtDto prot;
    private BqDto bq;

    public TelemetryPayload() {}

    public String getPack_type() { return pack_type; }
    public void setPack_type(String pack_type) { this.pack_type = pack_type; }

    public SourceDto getSource() { return source; }
    public void setSource(SourceDto source) { this.source = source; }

    public MeasDto getMeas() { return meas; }
    public void setMeas(MeasDto meas) { this.meas = meas; }

    public BalanceDto getBalance() { return balance; }
    public void setBalance(BalanceDto balance) { this.balance = balance; }

    public FetDto getFet() { return fet; }
    public void setFet(FetDto fet) { this.fet = fet; }

    public ProtDto getProt() { return prot; }
    public void setProt(ProtDto prot) { this.prot = prot; }

    public BqDto getBq() { return bq; }
    public void setBq(BqDto bq) { this.bq = bq; }
}