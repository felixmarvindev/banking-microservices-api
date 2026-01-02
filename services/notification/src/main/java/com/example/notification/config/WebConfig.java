package com.example.notification.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Serve static files from /static directory
        registry.addResourceHandler("/**")
                .addResourceLocations("classpath:/static/")
                .setCachePeriod(0);
        
        // Explicitly handle the dashboard HTML file
        registry.addResourceHandler("/notification-dashboard.html")
                .addResourceLocations("classpath:/static/notification-dashboard.html")
                .setCachePeriod(0);
    }
}

