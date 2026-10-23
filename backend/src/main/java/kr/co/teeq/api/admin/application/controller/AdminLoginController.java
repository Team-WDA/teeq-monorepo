package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * 관리자 로그인 화면. 로그인 처리(POST)와 로그아웃은 관리자 보안 체인이 맡는다.
 */
@Hidden
@Controller
public class AdminLoginController {

    @LogMonitoring
    @GetMapping("/admin/login")
    public String loginPage() {
        return "admin/login";
    }

}
