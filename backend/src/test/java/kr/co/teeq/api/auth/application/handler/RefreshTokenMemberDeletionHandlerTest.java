package kr.co.teeq.api.auth.application.handler;

import static org.mockito.Mockito.verify;

import java.util.UUID;
import kr.co.teeq.api.auth.core.repository.RefreshTokenRepository;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class RefreshTokenMemberDeletionHandlerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Mock
    private RefreshTokenRepository refreshTokenRepository;

    private RefreshTokenMemberDeletionHandler handler;

    @BeforeEach
    void setUp() {
        handler = new RefreshTokenMemberDeletionHandler(refreshTokenRepository);
    }

    @Test
    void handle_hardDeletesRefreshToken() {
        handler.handle(new MemberDeletedEvent(MEMBER_ID));

        verify(refreshTokenRepository).deleteByMemberId(MEMBER_ID);
    }

}
