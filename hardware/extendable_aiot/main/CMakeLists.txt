idf_component_register(
    SRCS "led_manager.c" "main.c" "oled_display.c" "wifi_manager.c" "time_sync.c"
    INCLUDE_DIRS "."
)

target_compile_options(${COMPONENT_LIB} PRIVATE -Wno-error=deprecated-declarations)
