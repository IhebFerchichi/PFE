package iheb_ferchichi.batterypack_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class BatteryPackBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(BatteryPackBackendApplication.class, args);
    }

}
