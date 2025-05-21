package com.example.demo;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/server")
public class Controller {

    @GetMapping("/status")
    public ResponseEntity<Map<String, Boolean>> status() {
        return ResponseEntity.ok(Map.of("server", false,
                "ai", true,
                "calendar", true));
    }

    @PostMapping(value = "/send", consumes = "multipart/form-data")
    public ResponseEntity<List<Map<String, Object>>> sendMockup(
            @RequestParam("comment") String comment,
            @RequestParam("gender") String gender,
            @RequestParam("child") boolean isChild,
            @RequestParam("pregnant") boolean isPregnant,
            @RequestPart("file") MultipartFile file) {

        System.out.println(comment + " " + gender + " " + isChild + " " + isPregnant + " " + file);
        String fileName = file.getOriginalFilename();
        long fileSize = file.getSize();

        //check if everything is ok
        if (fileName == null || fileSize == 0) {
            return ResponseEntity.badRequest().body(List.of(Map.of("error", "File is empty or not provided")));
        }
        if(gender.isEmpty()) {
            return ResponseEntity.badRequest().body(List.of(Map.of("error", "All fields are required")));
        }

        List<Map<String, Object>> mockModels = List.of(
            Map.of("name", "Paracetamol", "date", LocalDate.now(), "time", "12:59"),
            Map.of("name", "Ibuprofen", "date", LocalDate.now() , "time", "09:00"),
            Map.of("name", "Aspirin", "date", LocalDate.now() , "time", "18:30"),
            Map.of("name", "Paracetamol", "date", LocalDate.now(), "time", "12:00"),
            Map.of("name", "Ibuprofen", "date", LocalDate.now() , "time", "09:00"),
            Map.of("name", "Aspirin", "date", LocalDate.now() , "time", "18:30")
        );

        return ResponseEntity.ok(mockModels);
    }

    @PostMapping("/calendar")
    public ResponseEntity calendar(@RequestBody Map<String, Object> body) {
        System.out.println(body);
        return ResponseEntity.ok().build();

    }
}
