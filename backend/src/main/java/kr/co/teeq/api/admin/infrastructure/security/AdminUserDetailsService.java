package kr.co.teeq.api.admin.infrastructure.security;

import kr.co.teeq.api.member.core.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

/**
 * 관리자 로그인 시 활성 관리자 계정을 username으로 조회한다. 빈이 아니라 관리자 체인이 직접 생성한다.
 */
@RequiredArgsConstructor
public class AdminUserDetailsService implements UserDetailsService {

    private final AdminRepository adminRepository;

    @Override
    public UserDetails loadUserByUsername(String username) {
        return adminRepository.findByUsernameAndDeletedFalse(username)
            .map(AdminUserDetails::from)
            .orElseThrow(() -> new UsernameNotFoundException("관리자 계정을 찾을 수 없습니다."));
    }

}
