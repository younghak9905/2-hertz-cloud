package com.example.stresstest.controller;

import org.springframework.web.bind.annotation.*;
import java.util.concurrent.*;

@RestController
@RequestMapping("/load")
public class LoadController {

    @GetMapping("/cpu")
    public String cpuLoad(@RequestParam(defaultValue = "5") int sec) {
        long end = System.currentTimeMillis() + sec * 1000;
        while (System.currentTimeMillis() < end) {
            Math.sqrt(Math.random());
        }
        return "CPU load for " + sec + " seconds finished.";
    }

    @GetMapping("/memory")
    public String memoryLoad(@RequestParam(defaultValue = "100") int mb) {
        try {
            byte[] memory = new byte[mb * 1024 * 1024];
            for (int i = 0; i < memory.length; i++) {
                memory[i] = 1;
            }
        } catch (OutOfMemoryError e) {
            return "OutOfMemoryError after attempting to allocate " + mb + " MB";
        }
        return "Allocated ~" + mb + " MB of memory.";
    }

    @GetMapping("/io")
    public String ioLoad() {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < 100000; i++) {
            builder.append("sample text");
        }
        return "Simulated IO load.";
    }
}