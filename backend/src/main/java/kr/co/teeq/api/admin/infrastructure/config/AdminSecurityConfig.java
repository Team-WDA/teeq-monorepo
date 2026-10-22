package kr.co.teeq.api.admin.infrastructure.config;

import kr.co.teeq.api.admin.infrastructure.security.AdminAccessDeniedHandler;
import kr.co.teeq.api.admin.infrastructure.security.AdminAuthenticationEntryPoint;
import kr.co.teeq.api.admin.infrastructure.security.AdminAuthenticationProvider;
import kr.co.teeq.api.admin.infrastructure.security.AdminLoginSuccessHandler;
import kr.co.teeq.api.admin.infrastructure.security.AdminUserDetailsService;
import kr.co.teeq.api.member.core.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.access.hierarchicalroles.RoleHierarchy;
import org.springframework.security.access.hierarchicalroles.RoleHierarchyImpl;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.savedrequest.NullRequestCache;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;
import tools.jackson.databind.ObjectMapper;

// /admin/**, /api/admin/** 전용 체인. 폼 로그인 + 세션으로 Admin만 인증하고, 인가는 여기서 한 번에 한다
@Configuration
@RequiredArgsConstructor
public class AdminSecurityConfig {

    private static final String LOGIN_PATH = "/admin/login";
    private static final String LOGOUT_PATH = "/admin/logout";
    private static final String HOME_PATH = "/admin";
    private static final String ASSET_PATH = "/admin/assets/**";
    private static final String ACCOUNTS_PATH = "/admin/accounts/**";
    private static final String SETTINGS_PATH = "/admin/settings/**";
    private static final String MEMBER_DELETE_PATH = "/admin/members/*/delete";
    private static final String SETTING_CONFIGS_PATH = "/api/admin/setting-configs/**";

    private final AdminRepository adminRepository;
    private final PasswordEncoder passwordEncoder;
    private final ObjectMapper objectMapper;

    // SUPER_ADMIN은 ADMIN 권한을 모두 가진다. hasRole 검사에 쓰이는 인가 관리자가 이 빈을 사용한다
    @Bean
    public RoleHierarchy adminRoleHierarchy() {
        return RoleHierarchyImpl.fromHierarchy("ROLE_SUPER_ADMIN > ROLE_ADMIN");
    }

    // 제공자·진입점·핸들러는 빈으로 만들지 않고 이 체인에만 넣어 JWT 체인과 섞이지 않게 한다
    @Bean
    @Order(2)
    public SecurityFilterChain adminSecurityFilterChain(HttpSecurity http) throws Exception {
        AdminAuthenticationProvider adminAuthenticationProvider = new AdminAuthenticationProvider(
            new AdminUserDetailsService(adminRepository), passwordEncoder);

        http
            .securityMatcher("/admin/**", "/api/admin/**")
            // 상위 AuthenticationManager로 넘어가지 않도록 관리자 제공자 하나만 가진 관리자를 쓴다
            .authenticationManager(new ProviderManager(adminAuthenticationProvider))
            .authorizeHttpRequests(authorize -> authorize
                .requestMatchers(LOGIN_PATH, ASSET_PATH).permitAll()
                .requestMatchers(ACCOUNTS_PATH).hasRole("SUPER_ADMIN")
                .requestMatchers(HttpMethod.POST, SETTINGS_PATH).hasRole("SUPER_ADMIN")
                .requestMatchers(HttpMethod.PATCH, SETTING_CONFIGS_PATH).hasRole("SUPER_ADMIN")
                .requestMatchers(HttpMethod.POST, MEMBER_DELETE_PATH).hasRole("SUPER_ADMIN")
                .anyRequest().hasRole("ADMIN"))
            .formLogin(form -> form
                .loginPage(LOGIN_PATH)
                .loginProcessingUrl(LOGIN_PATH)
                .usernameParameter("username")
                .passwordParameter("password")
                .successHandler(new AdminLoginSuccessHandler(HOME_PATH))
                .failureUrl(LOGIN_PATH + "?error")
                .permitAll())
            .logout(logout -> logout
                .logoutRequestMatcher(PathPatternRequestMatcher.withDefaults().matcher(HttpMethod.POST, LOGOUT_PATH))
                .logoutSuccessUrl(LOGIN_PATH + "?logout"))
            .exceptionHandling(handling -> handling
                .authenticationEntryPoint(new AdminAuthenticationEntryPoint(objectMapper, LOGIN_PATH))
                .accessDeniedHandler(new AdminAccessDeniedHandler(objectMapper, LOGIN_PATH)))
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED))
            // 로그인 전 요청을 세션에 저장하지 않아 불필요한 세션 생성을 막는다
            .requestCache(cache -> cache.requestCache(new NullRequestCache()));
        return http.build();
    }

}
