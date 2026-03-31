package iheb_ferchichi.batterypack_backend.dto;

import java.math.BigDecimal;
import java.util.List;

public class MeasDto {

    private List<BigDecimal> cell_v;     // MUST be size 16
    private BigDecimal stack_v;
    private BigDecimal pack_v;
    private BigDecimal ld_v;
    private BigDecimal current_a;
    private List<BigDecimal> temp_c;     // size 5 ideally
    private Integer soc_pct;

    public MeasDto() {}

    public List<BigDecimal> getCell_v() { return cell_v; }
    public void setCell_v(List<BigDecimal> cell_v) { this.cell_v = cell_v; }

    public BigDecimal getStack_v() { return stack_v; }
    public void setStack_v(BigDecimal stack_v) { this.stack_v = stack_v; }

    public BigDecimal getPack_v() { return pack_v; }
    public void setPack_v(BigDecimal pack_v) { this.pack_v = pack_v; }

    public BigDecimal getLd_v() { return ld_v; }
    public void setLd_v(BigDecimal ld_v) { this.ld_v = ld_v; }

    public BigDecimal getCurrent_a() { return current_a; }
    public void setCurrent_a(BigDecimal current_a) { this.current_a = current_a; }

    public List<BigDecimal> getTemp_c() { return temp_c; }
    public void setTemp_c(List<BigDecimal> temp_c) { this.temp_c = temp_c; }

    public Integer getSoc_pct() { return soc_pct; }
    public void setSoc_pct(Integer soc_pct) { this.soc_pct = soc_pct; }
}
