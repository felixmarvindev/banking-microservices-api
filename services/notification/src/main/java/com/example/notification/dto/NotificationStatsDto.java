package com.example.notification.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationStatsDto {
    private Long totalNotifications;
    private Long sentCount;
    private Long failedCount;
    private Long pendingCount;
    private Double successRate;
}

