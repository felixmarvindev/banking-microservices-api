package com.example.notification.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KafkaEventDto {
    private String eventType;
    private String eventData;
    private LocalDateTime timestamp;
    private String topic;
    private Boolean processed;
}

