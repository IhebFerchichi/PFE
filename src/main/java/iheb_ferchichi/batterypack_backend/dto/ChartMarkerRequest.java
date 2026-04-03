package iheb_ferchichi.batterypack_backend.dto;

public class ChartMarkerRequest {

    private String packType;
    private String bmsId;
    private String chartKey;
    private Integer cellIndex;

    public String getPackType() {
        return packType;
    }

    public void setPackType(String packType) {
        this.packType = packType;
    }

    public String getBmsId() {
        return bmsId;
    }

    public void setBmsId(String bmsId) {
        this.bmsId = bmsId;
    }

    public String getChartKey() {
        return chartKey;
    }

    public void setChartKey(String chartKey) {
        this.chartKey = chartKey;
    }

    public Integer getCellIndex() {
        return cellIndex;
    }

    public void setCellIndex(Integer cellIndex) {
        this.cellIndex = cellIndex;
    }
}
