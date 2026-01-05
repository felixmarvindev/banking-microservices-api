package com.example.notification.dto;

import com.example.notification.model.Notification;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationResponseDto {
    private Long id;
    private Long userId;
    private String email;
    private String subject;
    private String message;
    private Notification.NotificationStatus status;
    private LocalDateTime sentAt;

    public static NotificationResponseDto fromEntity(Notification notification) {
        return NotificationResponseDto.builder()
                .id(notification.getId())
                .userId(notification.getUserId())
                .email(notification.getEmail())
                .subject(notification.getSubject())
                .message(notification.getMessage())
                .status(notification.getStatus())
                .sentAt(notification.getSentAt())
                .build();
    }
}




