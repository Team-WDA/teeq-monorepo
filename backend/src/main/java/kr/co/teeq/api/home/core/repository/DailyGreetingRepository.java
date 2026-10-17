package kr.co.teeq.api.home.core.repository;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.home.core.entity.DailyGreeting;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DailyGreetingRepository extends JpaRepository<DailyGreeting, UUID> {

    Optional<DailyGreeting> findByMemberIdAndGreetingDateAndDeletedFalse(UUID memberId, LocalDate greetingDate);

}
