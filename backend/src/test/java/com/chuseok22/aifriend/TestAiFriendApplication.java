package com.chuseok22.aifriend;

import org.springframework.boot.SpringApplication;

public class TestAiFriendApplication {

    public static void main(String[] args) {
        SpringApplication.from(AiFriendApplication::main).with(TestcontainersConfiguration.class).run(args);
    }

}
