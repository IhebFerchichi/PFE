package iheb_ferchichi.batterypack_backend.dto;


public class FetDto {

    private Integer chg; // 0/1
    private Integer dsg; // 0/1

    public FetDto() {}

    public Integer getChg() { return chg; }
    public void setChg(Integer chg) { this.chg = chg; }

    public Integer getDsg() { return dsg; }
    public void setDsg(Integer dsg) { this.dsg = dsg; }
}
