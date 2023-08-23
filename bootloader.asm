[BITS 64]

global _start

section .data
    hello_msg db "NNG Bootloader", 0

section .bss
    framebuffer resq 1   ; Allocate space for the framebuffer pointer

section .text
_start:
    ; Set up UEFI system table pointer
    mov rdi, [rsi + EFI_SYSTEM_TABLE_PTR]   ; Load system table pointer from bootloader parameter
    mov rax, [rdi + EFI_SYSTEM_TABLE.BootServices]   ; Load UEFI boot services pointer

    ; Get the console output protocol
    mov rdx, EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_GUID   ; Console output protocol GUID
    xor rcx, rcx
    call [rax + EFI_BOOT_SERVICES.LocateProtocol]
    test rax, rax
    jz .error_exit

    mov rsi, rax          ; Store the protocol interface pointer

    ; Allocate memory for framebuffer
    mov rax, EFI_BOOT_SERVICES.AllocatePool
    mov rdi, EFI_BOOT_SERVICES.EfiLoaderData
    mov rsi, 1024 * 768 * 4  ; Size in bytes (assuming 1024x768 resolution, 4 bytes per pixel)
    xor rdx, rdx          ; No alignment
    call rax
    test rax, rax
    jz .error_exit
    mov [framebuffer], rax ; Store the framebuffer pointer

    ; Set graphics mode
    mov rax, EFI_BOOT_SERVICES.QueryMode
    mov rdi, [rsi + EFI_GRAPHICS_OUTPUT_PROTOCOL]
    xor rsi, rsi          ; ModeNumber
    mov rdx, rsi          ; SizeOfInfo
    call rax
    test rax, rax
    jz .error_exit

    ; Set graphics mode
    mov rax, EFI_BOOT_SERVICES.SetMode
    mov rdi, [rsi + EFI_GRAPHICS_OUTPUT_PROTOCOL]
    mov rsi, rsi          ; ModeNumber (could be different based on supported modes)
    call rax
    test rax, rax
    jz .error_exit

    ; Draw a colored pixel
    mov rdi, [framebuffer] ; FrameBufferBase
    xor rax, rax
    mov al, 0xFF          ; Alpha
    mov ebx, 0xFF0000     ; Red
    mov ecx, 0x00FF00     ; Green
    mov edx, 0x0000FF     ; Blue
    shl rbx, 8
    or rbx, rcx
    shl rbx, 8
    or rbx, rdx
    mov [rdi], rbx        ; Write color to the first pixel

    ; Print a message
    mov rsi, hello_msg   ; Load message pointer
    xor rdx, rdx          ; Null-terminated string
    mov rcx, EFI_WHITE   ; Foreground color
    mov rax, [rsi + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString]
    call rax

    ; Call text configuration menu function here
    call print_text_configuration_menu

    ; Halt
    cli
    hlt

    ; Clean up allocated memory
    mov rax, EFI_BOOT_SERVICES.FreePool
    mov rdi, [framebuffer]
    call rax

    ; Exit UEFI application
    mov rax, [rdi + EFI_SYSTEM_TABLE.BootServices.Exit]
    xor rdi, rdi          ; ExitStatus
    call rax

.error_exit:
    ; Handle error (e.g., print an error message)
    ; You can use the same protocol to display the error message
    ; and provide more graceful error handling.

    ; Halt
    cli
    hlt

section .rodata
    EFI_SYSTEM_TABLE_PTR dq 0      ; Placeholder for system table pointer

section .data
    EFI_SYSTEM_TABLE dd 0x54535953 ; Signature "EFI_SYSTEM_TABLE"
    EFI_BOOT_SERVICES dq 0         ; Placeholder for Boot Services table
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL_GUID dq 0x387477c1, 0x69c7, 0x11d2, 0x8e, 0x39, 0x0, 0xa0, 0xc9, 0x69, 0x72, 0x3b
    EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID dq 0x9042a9de, 0x23dc, 0x4a38, 0x96, 0xfb, 0x7a, 0xde, 0xd0, 0x80, 0x51, 0x6a
    EFI_WHITE dw 0x07
