package com.example.notification.repository;

import com.example.notification.model.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
    Page<Notification> findAllByOrderBySentAtDesc(Pageable pageable);
    long countByStatus(Notification.NotificationStatus status);
}