idf_component_register(SRCS "main.c" "oled_display.c"
                    INCLUDE_DIRS ".")

target_compile_options(${COMPONENT_LIB} PRIVATE -Wno-error=deprecated-declarations)
