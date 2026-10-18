package kr.co.teeq.api.home.application.service;

import java.time.LocalDate;
import java.util.UUID;
import kr.co.teeq.api.home.core.entity.DailyGreeting;
import kr.co.teeq.api.home.core.repository.DailyGreetingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 오늘의 한마디 저장만 한 트랜잭션으로 처리한다. AI 서버 호출은 이 트랜잭션 밖({@link DailyGreetingService})에서 한다.
 */
@Service
@RequiredArgsConstructor
public class DailyGreetingCommandService {

    private final DailyGreetingRepository dailyGreetingRepository;

    // 같은 날 동시 저장은 unique 위반(DataIntegrityViolationException)으로 전파한다
    @Transactional
    public String save(UUID memberId, LocalDate greetingDate, String message) {
        dailyGreetingRepository.saveAndFlush(DailyGreeting.of(memberId, greetingDate, message));
        return message;
    }

}
