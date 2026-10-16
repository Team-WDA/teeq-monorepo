package kr.teeq.api.auth.infrastructure.config;

import kr.teeq.api.common.infrastructure.properties.AiServerProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

// /api/ai-server/** 전용 체인. JWT가 아니라 공유 헤더로만 인증한다
@Configuration
@RequiredArgsConstructor
public class AiServerSecurityConfig {

    private final AiServerProperties aiServerProperties;
    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;

    // 필터는 빈으로 만들지 않고 체인에만 넣어 서블릿 컨테이너에 이중 등록되지 않게 한다
    @Bean
    @Order(1)
    public SecurityFilterChain aiServerSecurityFilterChain(HttpSecurity http) throws Exception {
        http
            .securityMatcher("/api/ai-server/**")
            .csrf(AbstractHttpConfigurer::disable)
            .formLogin(AbstractHttpConfigurer::disable)
            .httpBasic(AbstractHttpConfigurer::disable)
            .logout(AbstractHttpConfigurer::disable)
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(authorize -> authorize.anyRequest().authenticated())
            .exceptionHandling(handling -> handling.authenticationEntryPoint(jwtAuthenticationEntryPoint))
            .addFilterBefore(new AiServerAuthenticationFilter(
                    aiServerProperties.authHeaderName(), aiServerProperties.authHeaderValue()),
                UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

}
