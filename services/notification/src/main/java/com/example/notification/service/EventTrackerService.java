package com.example.notification.service;

import com.example.notification.dto.KafkaEventDto;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.stream.Collectors;

@Service
@Slf4j
public class EventTrackerService {

    private static final int MAX_EVENTS = 100;
    private final ConcurrentLinkedQueue<KafkaEventDto> events = new ConcurrentLinkedQueue<>();
    private LocalDateTime lastEventTime;

    public void trackEvent(String eventType, String eventData, String topic, boolean processed) {
        KafkaEventDto event = KafkaEventDto.builder()
                .eventType(eventType)
                .eventData(eventData)
                .timestamp(LocalDateTime.now())
                .topic(topic)
                .processed(processed)
                .build();

        events.offer(event);
        lastEventTime = event.getTimestamp();

        // Keep only the last MAX_EVENTS
        while (events.size() > MAX_EVENTS) {
            events.poll();
        }

        log.debug("Tracked Kafka event: {} from topic: {}", eventType, topic);
    }

    public List<KafkaEventDto> getRecentEvents(int limit) {
        return events.stream()
                .sorted((e1, e2) -> e2.getTimestamp().compareTo(e1.getTimestamp()))
                .limit(limit)
                .collect(Collectors.toList());
    }

    public List<KafkaEventDto> getAllEvents() {
        return new ArrayList<>(events);
    }

    public LocalDateTime getLastEventTime() {
        return lastEventTime;
    }

    public void clearEvents() {
        events.clear();
        lastEventTime = null;
        log.info("Cleared all tracked events");
    }

    public int getEventCount() {
        return events.size();
    }
}

