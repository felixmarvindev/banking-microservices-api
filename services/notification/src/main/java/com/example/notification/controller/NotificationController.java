package com.example.notification.controller;

import com.example.notification.dto.*;
import com.example.notification.model.Notification;
import com.example.notification.repository.NotificationRepository;
import com.example.notification.event.AccountEvent;
import com.example.notification.event.TransactionEvent;
import com.example.notification.service.EmailService;
import com.example.notification.service.EventBroadcasterService;
import com.example.notification.service.EventTrackerService;
import com.example.notification.service.KafkaProducerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
@Slf4j
public class NotificationController {

    private final NotificationRepository notificationRepository;
    private final EmailService emailService;
    private final EventTrackerService eventTrackerService;
    private final EventBroadcasterService eventBroadcasterService;
    private final KafkaProducerService kafkaProducerService;

    @GetMapping
    public ResponseEntity<Page<NotificationResponseDto>> getAllNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Notification> notifications = notificationRepository.findAllByOrderBySentAtDesc(pageable);
        Page<NotificationResponseDto> response = notifications.map(NotificationResponseDto::fromEntity);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/stats")
    public ResponseEntity<NotificationStatsDto> getStatistics() {
        long total = notificationRepository.count();
        long sentCount = notificationRepository.countByStatus(Notification.NotificationStatus.SENT);
        long failedCount = notificationRepository.countByStatus(Notification.NotificationStatus.FAILED);
        long pendingCount = notificationRepository.countByStatus(Notification.NotificationStatus.PENDING);

        double successRate = total > 0 ? (double) sentCount / total * 100 : 0.0;

        NotificationStatsDto stats = NotificationStatsDto.builder()
                .totalNotifications(total)
                .sentCount(sentCount)
                .failedCount(failedCount)
                .pendingCount(pendingCount)
                .successRate(successRate)
                .build();

        return ResponseEntity.ok(stats);
    }

    @GetMapping("/kafka/status")
    public ResponseEntity<KafkaStatusDto> getKafkaStatus() {
        LocalDateTime lastEventTime = eventTrackerService.getLastEventTime();
        int eventCount = eventTrackerService.getEventCount();

        KafkaStatusDto status = KafkaStatusDto.builder()
                .isConnected(eventCount > 0 || lastEventTime != null)
                .consumerGroup("notification-group")
                .topics(List.of("transaction-events", "account-events"))
                .lastEventTime(lastEventTime)
                .build();

        return ResponseEntity.ok(status);
    }

    @GetMapping("/kafka/events")
    public ResponseEntity<List<KafkaEventDto>> getKafkaEvents(
            @RequestParam(defaultValue = "50") int limit) {
        List<KafkaEventDto> events = eventTrackerService.getRecentEvents(limit);
        return ResponseEntity.ok(events);
    }

    @GetMapping(value = "/events/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamEvents() {
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE);
        eventBroadcasterService.addEmitter(emitter);

        // Send initial connection message
        try {
            emitter.send(SseEmitter.event()
                    .name("connected")
                    .data("Connected to notification event stream"));
        } catch (IOException e) {
            log.error("Error sending initial SSE message", e);
            emitter.completeWithError(e);
        }

        return emitter;
    }

    @PostMapping("/test")
    public ResponseEntity<?> testNotification(
            @Valid @RequestBody TestNotificationRequestDto request) {
        try {
            log.info("Test notification requested: email={}, subject={}", request.getEmail(), request.getSubject());

            emailService.sendEmail(request.getEmail(), request.getSubject(), request.getMessage());

            // Get the latest notification (the one we just created)
            Page<Notification> latest = notificationRepository.findAllByOrderBySentAtDesc(PageRequest.of(0, 1));
            if (latest.hasContent()) {
                NotificationResponseDto response = NotificationResponseDto.fromEntity(latest.getContent().get(0));
                return ResponseEntity.status(HttpStatus.CREATED).body(response);
            }

            return ResponseEntity.status(HttpStatus.CREATED).build();
        } catch (Exception e) {
            log.error("Error sending test notification", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ErrorResponse("Failed to send test notification: " + e.getMessage()));
        }
    }

    @PostMapping("/trigger/transaction")
    public ResponseEntity<?> triggerTransactionEvent(
            @Valid @RequestBody TriggerTransactionEventDto request) {
        try {
            TransactionEvent event = new TransactionEvent();
            event.setTransactionReference(request.getTransactionReference());
            event.setSourceAccountId(request.getSourceAccountId());
            event.setDestinationAccountId(request.getDestinationAccountId());
            event.setAmount(request.getAmount());
            event.setType(request.getType());
            event.setStatus(request.getStatus());
            event.setDescription(request.getDescription());
            event.setUserId(request.getUserId());
            event.setEmail(request.getEmail());

            kafkaProducerService.sendTransactionEvent(event);

            return ResponseEntity.ok().body(new SuccessResponse("Transaction event sent to Kafka successfully"));
        } catch (Exception e) {
            log.error("Error triggering transaction event", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ErrorResponse("Failed to trigger transaction event: " + e.getMessage()));
        }
    }

    @PostMapping("/trigger/account")
    public ResponseEntity<?> triggerAccountEvent(
            @Valid @RequestBody TriggerAccountEventDto request) {
        try {
            AccountEvent event = AccountEvent.builder()
                    .eventType(request.getEventType())
                    .accountNumber(request.getAccountNumber())
                    .userId(request.getUserId())
                    .accountType(request.getAccountType())
                    .balance(request.getBalance())
                    .currency(request.getCurrency() != null ? request.getCurrency() : "USD")
                    .email(request.getEmail())
                    .createdAt(LocalDateTime.now())
                    .build();

            kafkaProducerService.sendAccountEvent(event);

            return ResponseEntity.ok().body(new SuccessResponse("Account event sent to Kafka successfully"));
        } catch (Exception e) {
            log.error("Error triggering account event", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ErrorResponse("Failed to trigger account event: " + e.getMessage()));
        }
    }

    // Simple error response class
    private static class ErrorResponse {
        private final String message;
        private final String timestamp = LocalDateTime.now().toString();

        public ErrorResponse(String message) {
            this.message = message;
        }

        public String getMessage() {
            return message;
        }

        public String getTimestamp() {
            return timestamp;
        }
    }

    // Simple success response class
    private static class SuccessResponse {
        private final String message;
        private final String timestamp = LocalDateTime.now().toString();

        public SuccessResponse(String message) {
            this.message = message;
        }

        public String getMessage() {
            return message;
        }

        public String getTimestamp() {
            return timestamp;
        }
    }

    @GetMapping(value = "/dashboard", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> getDashboard() {
        try {
            Resource resource = new ClassPathResource("static/notification-dashboard.html");
            String html = new String(resource.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.TEXT_HTML);
            return new ResponseEntity<>(html, headers, HttpStatus.OK);
        } catch (IOException e) {
            log.error("Error loading dashboard HTML", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("<html><body><h1>Error loading dashboard</h1></body></html>");
        }
    }
}

