package iheb_ferchichi.batterypack_backend.dto;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;


public class CellData {
    private BigDecimal voltage;
    private Boolean balancing;

    public CellData() {}
    public BigDecimal getVoltage() {return voltage;};
    public Boolean getBalancing() {return balancing;};
    public void setVoltage(BigDecimal voltage) {this.voltage = voltage;};
    public void setBalancing(Boolean balancing) {this.balancing = balancing;};

}
