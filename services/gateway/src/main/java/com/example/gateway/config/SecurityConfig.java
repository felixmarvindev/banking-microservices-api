package com.example.gateway.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;


@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    private static final Logger logger = LoggerFactory.getLogger(SecurityConfig.class);

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity serverHttpSecurity) {
        logger.info("SecurityConfig is being applied...");
        serverHttpSecurity
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .authorizeExchange(exchange ->
                        exchange.pathMatchers(
                                        "/",
                                        "/eureka/**",
                                        "/api/v1/**",
                                        "/swagger-ui/**",
                                        "/swagger-ui.html",
                                        "/swagger-aggregator.html",
                                        "/v3/api-docs/**",
                                        "/webjars/**",
                                        "/actuator/**",
                                        // Service-specific swagger routes
                                        "/auth-service/swagger-ui/**",
                                        "/auth-service/v3/api-docs/**",
                                        "/account-service/swagger-ui/**",
                                        "/account-service/v3/api-docs/**",
                                        "/transaction-service/swagger-ui/**",
                                        "/transaction-service/v3/api-docs/**",
                                        "/loan-service/swagger-ui/**",
                                        "/loan-service/v3/api-docs/**",
                                        "/notification-service/swagger-ui/**",
                                        "/notification-service/v3/api-docs/**"
                                )
                                .permitAll()
                                .anyExchange()
                                .authenticated())
                .oauth2ResourceServer(spec -> spec.jwt(Customizer.withDefaults()));
        return serverHttpSecurity.build();
    }
}