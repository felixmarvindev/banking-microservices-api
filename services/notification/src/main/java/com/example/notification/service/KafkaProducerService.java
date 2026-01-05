package com.example.notification.service;

import com.example.notification.event.AccountEvent;
import com.example.notification.event.TransactionEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class KafkaProducerService {

    private final KafkaTemplate<String, Object> kafkaTemplate;

    public void sendTransactionEvent(TransactionEvent event) {
        try {
            event.setCreatedAt(LocalDateTime.now());
            event.setUpdatedAt(LocalDateTime.now());
            kafkaTemplate.send("transaction-events", event);
            log.info("Sent transaction event to Kafka: {}", event);
        } catch (Exception e) {
            log.error("Failed to send transaction event to Kafka", e);
            throw new RuntimeException("Failed to send transaction event", e);
        }
    }

    public void sendAccountEvent(AccountEvent event) {
        try {
            if (event.getCreatedAt() == null) {
                event.setCreatedAt(LocalDateTime.now());
            }
            kafkaTemplate.send("account-events", event);
            log.info("Sent account event to Kafka: {}", event);
        } catch (Exception e) {
            log.error("Failed to send account event to Kafka", e);
            throw new RuntimeException("Failed to send account event", e);
        }
    }
}




