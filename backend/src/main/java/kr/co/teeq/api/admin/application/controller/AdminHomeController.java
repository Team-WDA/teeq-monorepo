package kr.co.teeq.api.admin.application.controller;

import com.chuseok22.logging.annotation.LogMonitoring;
import io.swagger.v3.oas.annotations.Hidden;
import kr.co.teeq.api.admin.application.service.AdminDashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * 관리자 대시보드 홈(로그인 후 첫 화면). 열 때마다 집계를 새로 계산한다.
 */
@Hidden
@Controller
@RequiredArgsConstructor
public class AdminHomeController {

    private static final String HOME_VIEW = "admin/home";

    private final AdminDashboardService adminDashboardService;

    @LogMonitoring
    @GetMapping("/admin")
    public String home(Model model) {
        model.addAttribute("dashboard", adminDashboardService.getDashboard());
        return HOME_VIEW;
    }

}
