package kz.jemis.delivery;

import jakarta.persistence.*;
import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.Arrays;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "delivery_slot_templates")
@Getter @Setter @NoArgsConstructor
public class SlotTemplate {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "start_time") private LocalTime startTime;
    @Column(name = "end_time") private LocalTime endTime;
    private int capacity;
    @Column(name = "days_of_week") private String daysOfWeek = "1,2,3,4,5,6,7";
    @Column(name = "extra_fee_minor") private long extraFeeMinor;
    private boolean active = true;

    public boolean runsOn(DayOfWeek d) {
        Set<Integer> days = Arrays.stream(daysOfWeek.split(",")).map(String::trim).filter(s -> !s.isEmpty())
                .map(Integer::parseInt).collect(Collectors.toSet());
        return days.contains(d.getValue());
    }
}
