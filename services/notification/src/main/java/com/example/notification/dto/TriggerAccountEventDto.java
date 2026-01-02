package com.example.notification.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TriggerAccountEventDto {
    @NotBlank(message = "Event type is required")
    private String eventType;

    @NotBlank(message = "Account number is required")
    private String accountNumber;

    @NotNull(message = "User ID is required")
    private Long userId;

    private String accountType;

    private BigDecimal balance;

    private String currency;

    @NotBlank(message = "Email is required")
    @Email(message = "Email must be valid")
    private String email;
}

