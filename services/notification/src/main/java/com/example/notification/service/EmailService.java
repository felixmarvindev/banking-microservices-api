package com.example.notification.service;

import com.example.notification.model.Notification;
import com.example.notification.repository.NotificationRepository;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;
    private final NotificationRepository notificationRepository;

    @Transactional
    public void sendEmail(String to, String subject, String content) {
        sendEmail(to, subject, content, null);
    }

    @Transactional
    public void sendEmail(String to, String subject, String content, Long userId) {
        Notification notification = Notification.builder()
            .email(to)
            .subject(subject)
            .message(content)
            .sentAt(LocalDateTime.now())
            .status(Notification.NotificationStatus.PENDING)
            .userId(userId)
            .build();

        try {
            // Save notification first
            notification = notificationRepository.save(notification);
            
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, "utf-8");
            helper.setText(content, true);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setFrom("noreply@bankapp.com");

            mailSender.send(mimeMessage);

            notification.setStatus(Notification.NotificationStatus.SENT);
            log.info("Email sent to: {}, with subject: {}", to, subject);
        } catch (MessagingException e) {
            notification.setStatus(Notification.NotificationStatus.FAILED);
            log.error("Failed to send email to: {}, error: {}", to, e.getMessage(), e);
        } catch (Exception e) {
            notification.setStatus(Notification.NotificationStatus.FAILED);
            log.error("Unexpected error sending email to: {}, error: {}", to, e.getMessage(), e);
        } finally {
            // Ensure notification is saved with final status
            try {
                notificationRepository.save(notification);
            } catch (Exception e) {
                log.error("Failed to save notification to database", e);
                throw e; // Re-throw if we can't save to DB
            }
        }
    }
}