package iheb_ferchichi.batterypack_backend.auth.entity;


import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "package_devices")
@Data
public class PackageDevice {


    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_package_id", nullable = false)
    private CustomerPackage customerPackage;

    @Enumerated(EnumType.STRING)
    @Column(name = "pack_type", nullable = false, length = 20)
    private PackType packType;

    @Column(name = "bms_id", nullable = false, length = 100, unique = true)
    private String bmsId;

    @Column(nullable = false)
    private Boolean enabled = true;

    public CustomerPackage getCustomerPackage() {
        return customerPackage;
    }

    public void setCustomerPackage(CustomerPackage customerPackage) {
        this.customerPackage = customerPackage;
    }

    public PackType getPackType() {
        return packType;
    }

    public void setPackType(PackType packType) {
        this.packType = packType;
    }

    public String getBmsId() {
        return bmsId;
    }

    public void setBmsId(String bmsId) {
        this.bmsId = bmsId;
    }

    public Boolean getEnabled() {
        return enabled;
    }

    public void setEnabled(Boolean enabled) {
        this.enabled = enabled;
    }

}