package kr.co.teeq.api.auth.application.controller;

import io.swagger.v3.oas.annotations.Hidden;
import java.util.Map;
import org.springframework.http.ResponseEntity;

@Hidden
public interface AppleCallbackControllerDocs {

    ResponseEntity<Void> callback(Map<String, String> parameters);

}
