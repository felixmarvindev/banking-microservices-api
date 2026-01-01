package com.example.loan.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI loanServiceOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Loan Service API")
                        .description("Loan Management Service for Online Banking Microservices")
                        .version("v1.0")
                        .contact(new Contact()
                                .name("Banking API Team")
                                .email("support@banking.com"))
                        .license(new License()
                                .name("Apache 2.0")
                                .url("https://www.apache.org/licenses/LICENSE-2.0.html")));
    }
}

