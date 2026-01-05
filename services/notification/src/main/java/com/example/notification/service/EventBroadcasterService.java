package com.example.notification.service;

import com.example.notification.dto.KafkaEventDto;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
@Slf4j
public class EventBroadcasterService {

    private final List<SseEmitter> sseEmitters = new CopyOnWriteArrayList<>();

    public void addEmitter(SseEmitter emitter) {
        sseEmitters.add(emitter);
        emitter.onCompletion(() -> sseEmitters.remove(emitter));
        emitter.onTimeout(() -> sseEmitters.remove(emitter));
        emitter.onError((ex) -> sseEmitters.remove(emitter));
    }

    public void broadcastEvent(KafkaEventDto event) {
        List<SseEmitter> deadEmitters = new CopyOnWriteArrayList<>();
        sseEmitters.forEach(emitter -> {
            try {
                emitter.send(SseEmitter.event()
                        .name("kafka-event")
                        .data(event));
            } catch (IOException e) {
                log.debug("SSE emitter error, removing", e);
                deadEmitters.add(emitter);
            }
        });
        sseEmitters.removeAll(deadEmitters);
    }

    public int getActiveConnections() {
        return sseEmitters.size();
    }
}




