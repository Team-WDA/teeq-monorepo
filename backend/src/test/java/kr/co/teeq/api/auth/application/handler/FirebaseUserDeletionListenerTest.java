package kr.co.teeq.api.auth.application.handler;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import java.lang.reflect.Method;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.auth.core.port.FirebaseUserDeletionPort;
import kr.co.teeq.api.member.core.constant.LoginType;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.event.HandlesMemberDeletion;
import kr.co.teeq.api.member.core.event.MemberDeletedEvent;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@ExtendWith(MockitoExtension.class)
class FirebaseUserDeletionListenerTest {

    private static final UUID MEMBER_ID = UUID.fromString("0198a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b");

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private FirebaseUserDeletionPort firebaseUserDeletionPort;

    @InjectMocks
    private FirebaseUserDeletionListener listener;

    private Member memberWithUid(String firebaseUid) {
        return Member.createMember(LoginType.EMAIL, firebaseUid, "a@b.c", "소연");
    }

    @Test
    void handle_deletesFirebaseUserWithUidReadFromSoftDeletedMember() throws Exception {
        given(memberRepository.findById(MEMBER_ID)).willReturn(Optional.of(memberWithUid("uid-1")));

        listener.handle(new MemberDeletedEvent(MEMBER_ID));

        verify(firebaseUserDeletionPort).delete("uid-1");
    }

    @Test
    void handle_portFailure_isSwallowed() {
        given(memberRepository.findById(MEMBER_ID)).willReturn(Optional.of(memberWithUid("uid-1")));
        willThrow(new IllegalStateException("firebase down")).given(firebaseUserDeletionPort).delete("uid-1");

        assertThatCode(() -> listener.handle(new MemberDeletedEvent(MEMBER_ID))).doesNotThrowAnyException();
    }

    @Test
    void handle_memberNotFound_doesNotCallPortAndDoesNotThrow() {
        given(memberRepository.findById(MEMBER_ID)).willReturn(Optional.empty());

        assertThatCode(() -> listener.handle(new MemberDeletedEvent(MEMBER_ID))).doesNotThrowAnyException();
        verify(firebaseUserDeletionPort, never()).delete(org.mockito.ArgumentMatchers.anyString());
    }

    @Test
    void handle_repositoryFailure_isSwallowed() {
        given(memberRepository.findById(MEMBER_ID)).willThrow(new IllegalStateException("db down"));

        assertThatCode(() -> listener.handle(new MemberDeletedEvent(MEMBER_ID))).doesNotThrowAnyException();
    }

    @Test
    void listener_runsAfterCommitSynchronouslyAndIsNotADeletionHandler() throws Exception {
        Method handle = FirebaseUserDeletionListener.class.getMethod("handle", MemberDeletedEvent.class);

        assertThat(handle.getAnnotation(TransactionalEventListener.class).phase())
            .isEqualTo(TransactionPhase.AFTER_COMMIT);
        assertThat(handle.isAnnotationPresent(Async.class)).isFalse();
        assertThat(FirebaseUserDeletionListener.class.isAnnotationPresent(Async.class)).isFalse();
        assertThat(FirebaseUserDeletionListener.class.isAnnotationPresent(HandlesMemberDeletion.class)).isFalse();
    }

}
