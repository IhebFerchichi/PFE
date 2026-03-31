package iheb_ferchichi.batterypack_backend.dto;



import java.util.List;

public class BalanceDto {

    private List<Integer> cell_bal;     // MUST be size 16, values 0/1
    private Integer active_cells_mask;  // optional

    public BalanceDto() {}

    public List<Integer> getCell_bal() { return cell_bal; }
    public void setCell_bal(List<Integer> cell_bal) { this.cell_bal = cell_bal; }

    public Integer getActive_cells_mask() { return active_cells_mask; }
    public void setActive_cells_mask(Integer active_cells_mask) { this.active_cells_mask = active_cells_mask; }
}