package kr.teeq.api;

import org.springframework.boot.SpringApplication;

public class TestTeeqApplication {

    public static void main(String[] args) {
        SpringApplication.from(TeeqApplication::main).with(TestcontainersConfiguration.class).run(args);
    }

}
