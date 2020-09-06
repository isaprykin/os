cmake_minimum_required(VERSION 3.18)

project(os)

# This gets substituted into `nasm -f <value>` for compilation.
set(CMAKE_ASM_NASM_OBJECT_FORMAT bin)
# CMake insists on a linking step, even though the bootloader doesn't
# need it.  Just rename the `.asm.o` file into a `.bin` file.
set(CMAKE_ASM_NASM_LINK_EXECUTABLE "mv <OBJECTS> <TARGET>.bin")
# `CMAKE_ASM_NASM_OBJECT_FORMAT` won't get set if `enable_language` is
# placed higher.
enable_language(ASM_NASM)
add_executable(boot-sect boot-sect.asm)

# `-q` skips the user prompt at the start.
add_custom_target(run
  COMMAND bochs -f ../bochsrc.txt -q)
add_dependencies(run boot-sect)
