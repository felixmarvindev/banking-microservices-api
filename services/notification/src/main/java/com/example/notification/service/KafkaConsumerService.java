// The bug is in the content format for the account event email.
// In KafkaConsumerService.java, the email content for AccountEvent is plain text
// but should be HTML format like the TransactionEvent

package com.example.notification.service;

import com.example.notification.dto.KafkaEventDto;
import com.example.notification.event.AccountEvent;
import com.example.notification.event.TransactionEvent;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class KafkaConsumerService {

    private final EmailService emailService;
    private final EventTrackerService eventTrackerService;
    private final EventBroadcasterService eventBroadcasterService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @KafkaListener(
        topics = "transaction-events",
        groupId = "notification-group",
        containerFactory = "transactionKafkaListenerContainerFactory"
    )
    public void consumeTransactionEvent(TransactionEvent event) {
        boolean processed = false;
        try {
            log.info("Received Transaction Event: {}", event);

            if (event.getEmail() == null || event.getEmail().isEmpty()) {
                log.warn("No email address provided in event: {}", event);
                return;
            }

            String subject = "Transaction Notification";
            String content = String.format("""
                <html>
                    <body>
                        <h2>Transaction Alert</h2>
                        <p>Dear Customer,</p>
                        <p>Your transaction with reference %s has been processed.</p>
                        <p><strong>Amount:</strong> %s</p>
                        <p><strong>Type:</strong> %s</p>
                        <p><strong>Status:</strong> %s</p>
                        <p>Thank you for banking with us.</p>
                    </body>
                </html>
                """,
                event.getTransactionReference(),
                event.getAmount(),
                event.getType(),
                event.getStatus());

            log.info("event.getEmail(): {}, subject: {}, content: {}", event.getEmail(), subject, content);
//            emailService.sendEmail(event.getEmail(), subject, content);
            processed = true;

        } catch (Exception e) {
            log.error("Error processing transaction event: {}", event, e);
        } finally {
            // Update event tracking with final status and broadcast
            try {
                String eventData = objectMapper.writeValueAsString(event);
                KafkaEventDto kafkaEvent = KafkaEventDto.builder()
                        .eventType("TransactionEvent")
                        .eventData(eventData)
                        .timestamp(LocalDateTime.now())
                        .topic("transaction-events")
                        .processed(processed)
                        .build();
                eventTrackerService.trackEvent("TransactionEvent", eventData, "transaction-events", processed);
                eventBroadcasterService.broadcastEvent(kafkaEvent);
            } catch (JsonProcessingException e) {
                log.warn("Failed to update event tracking status", e);
            }
        }
    }

    @KafkaListener(
        topics = "account-events",
        groupId = "notification-group",
        containerFactory = "accountKafkaListenerContainerFactory"
    )
    public void consumeAccountEvent(AccountEvent event) {
        boolean processed = false;
        try {
            log.info("Received Account Event: {}", event);

            if (event.getEmail() == null) {
                log.error("No email in account event: {}", event);
                return;
            }

            String subject = "Account Notification";
            // FIXED: Changed from plain text to HTML format to match expected email format
            String content = String.format("""
                <html>
                    <body>
                        <h2>Account Notification</h2>
                        <p>Dear Customer,</p>
                        <p>We're writing to inform you about your account:</p>
                        <p><strong>Account Number:</strong> %s</p>
                        <p><strong>Event:</strong> %s</p>
                        <p><strong>Balance:</strong> %s %s</p>
                        <p><strong>Created:</strong> %s</p>
                        <p>Thank you for banking with us.</p>
                    </body>
                </html>
                """,
                event.getAccountNumber(),
                event.getEventType(),
                event.getBalance(),
                event.getCurrency(),
                event.getCreatedAt());

//            emailService.sendEmail(event.getEmail(), subject, content);
            log.info("event.getEmail(): {}, subject: {}, content: {}", event.getEmail(), subject, content);
            processed = true;

        } catch (Exception e) {
            log.error("Failed to process account event", e);
            throw e; // Re-throwing the exception
        } finally {
            // Update event tracking with final status and broadcast
            try {
                String eventData = objectMapper.writeValueAsString(event);
                KafkaEventDto kafkaEvent = KafkaEventDto.builder()
                        .eventType("AccountEvent")
                        .eventData(eventData)
                        .timestamp(LocalDateTime.now())
                        .topic("account-events")
                        .processed(processed)
                        .build();
                eventTrackerService.trackEvent("AccountEvent", eventData, "account-events", processed);
                eventBroadcasterService.broadcastEvent(kafkaEvent);
            } catch (JsonProcessingException e) {
                log.warn("Failed to update event tracking status", e);
            }
        }
    }
}