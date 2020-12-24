# This CMake script builds the toolchain and the operating system itself.
#
# It can be used in two steps.  First, build the toolchain for
# compiling and linking programs for the target architecture $TARGET.
#
# This relies on the host operating system.  The host needs to have a
# compiler, `nasm` and `bochs` installed:
#   $ cmake -S . -B toolchain/ -Dbuild_the_toolchain=ON
#   $ make -C toolchain/
#
# After that, use the toolchain to build the operating system itself:
#   $ cmake -S . -B build/
#   $ make run -C build/
cmake_minimum_required(VERSION 3.18)
include(ExternalProject)

option(build_the_toolchain "Whether to compile the toolchain first?" OFF)

set(TOOLCHAIN_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/toolchain")
set(TARGET "i386-elf")

if (NOT build_the_toolchain)
  if (NOT EXISTS ${TOOLCHAIN_ROOT})
    message(FATAL_ERROR "Set $TOOLCHAIN_ROOT to the path where the toolchain got "
      "built.  If the toolchain isn't there yet, yet then run CMake with "
      "-Dbuilt_the_toolchain=ON.")
  endif()
  set(CMAKE_SYSTEM_PROCESSOR i386)
  set(CMAKE_SYSTEM_VERSION 1)
  # Use the toolchain's libraries instead of the one's on the host.
  set(CMAKE_SYSROOT ${TOOLCHAIN_ROOT})
  set(CMAKE_OSX_SYSROOT ${TOOLCHAIN_ROOT})
  # Link a free standing C code without relying on standard libraries or treating
  # `main()` in a special way.
  SET(CMAKE_C_FLAGS "-ffreestanding" CACHE STRING "" FORCE)
  # CMake will try to test the toolchain compiler.  It's going to
  # assume the standard library, which isn't yet available without
  # setting this option.
  set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
  set(CMAKE_C_COMPILER ${TOOLCHAIN_ROOT}/bin/${TARGET}-gcc)
  set(CMAKE_CXX_COMPILER ${TOOLCHAIN_ROOT}/bin/${TARGET}-g++)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
endif()
project(os)

if (build_the_toolchain)
  ExternalProject_Add(gmp
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}
      URL https://gmplib.org/download/gmp/gmp-6.2.0.tar.xz
	  https://ftp.gnu.org/gnu/gmp/gmp-6.2.0.tar.xz
    URL_HASH SHA256=258e6cd51b3fbdfc185c716d55f82c08aff57df0c6fbd143cf6ed561267a1526
    CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_CURRENT_BINARY_DIR} --enable-cxx --with-pic
    TEST_BEFORE_INSTALL 1
    TEST_COMMAND make check
    )

  ExternalProject_Add(mpfr
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}
    DEPENDS gmp
      URL https://ftp.gnu.org/gnu/mpfr/mpfr-4.1.0.tar.xz
	  https://ftpmirror.gnu.org/mpfr/mpfr-4.1.0.tar.xz
    URL_HASH SHA256=0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f
    CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_CURRENT_BINARY_DIR} --disable-dependency-tracking --disable-silent-rules --with-gmp=${CMAKE_CURRENT_BINARY_DIR}
    TEST_BEFORE_INSTALL 1
    TEST_COMMAND make check
    )

  ExternalProject_Add(libmpc
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}
    DEPENDS gmp mpfr
      URL https://ftp.gnu.org/gnu/mpc/mpc-1.2.0.tar.gz
	  https://ftpmirror.gnu.org/mpc/mpc-1.2.0.tar.gz
    URL_HASH SHA256=e90f2d99553a9c19911abdb4305bf8217106a957e3994436428572c8dfe8fda6
    CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_CURRENT_BINARY_DIR} --disable-dependency-tracking --disable-silent-rules --with-gmp=${CMAKE_CURRENT_BINARY_DIR} --with-mpfr=${CMAKE_CURRENT_BINARY_DIR}
    TEST_BEFORE_INSTALL 1
    TEST_COMMAND make check
    )

  ExternalProject_Add(binutils
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}
      URL https://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.xz
	https://ftpmirror.gnu.org/binutils/binutils-2.35.tar.xz
    URL_HASH SHA256=1b11659fb49e20e18db460d44485f09442c8c56d5df165de9461eb09c8302f85
    CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_CURRENT_BINARY_DIR} --infodir=${CMAKE_CURRENT_BINARY_DIR}/share --mandir=${CMAKE_CURRENT_BINARY_DIR}/share --target=${TARGET} --disable-werror --disable-nls
    TEST_BEFORE_INSTALL 1
    TEST_COMMAND make check
    )

  ExternalProject_Add(gcc
    DEPENDS binutils mpfr gmp libmpc
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}
    URL https://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.xz
	https://ftpmirror.gnu.org/gcc/gcc-10.2.0/gcc-10.2.0.tar.xz
    URL_HASH SHA256=b8dd4368bb9c7f0b98188317ee0254dd8cc99d1e3a18d0ff146c855fe16c1d8c
    CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_CURRENT_BINARY_DIR} --infodir=${CMAKE_CURRENT_BINARY_DIR}/share --mandir=${CMAKE_CURRENT_BINARY_DIR}/share --target=${TARGET} --disable-nls --enable-languages=c,c++ --without-headers --with-gmp=${CMAKE_CURRENT_BINARY_DIR} --with-mpfr=${CMAKE_CURRENT_BINARY_DIR} --with-mpc=${CMAKE_CURRENT_BINARY_DIR}
    BUILD_COMMAND make all-gcc all-target-libgcc
    INSTALL_COMMAND make install-gcc install-target-libgcc
    )
  return()
endif()

# CMake insists on a linking step, even though the bootloader doesn't
# need it.  Just rename the `.asm.o` file into a `.bin` file.
set(CMAKE_ASM_NASM_LINK_EXECUTABLE "mv <OBJECTS> <TARGET>")
# `CMAKE_ASM_NASM_OBJECT_FORMAT` won't get set if `enable_language` is
# placed higher.
enable_language(ASM_NASM)
# We need two build NASM files in two ways:
#  - `-f bin` for the boot loader,
#  - `-f elf` for everything else such as the libraries written in assembly.
# 
# This is achieved in a special way.  First, the default rule for compiling 
# NASM is redefined.  It's the same as the default, but it doesn't have the
# facilities that automatically add the `-f <format>` parameter.
set(CMAKE_ASM_NASM_COMPILE_OBJECT "<CMAKE_ASM_NASM_COMPILER> <INCLUDES> <FLAGS> -o <OBJECT> <SOURCE>")
# In general case, the output of NASM needs to be in `elf` format so that it
# be linked with the C code.
set(CMAKE_ASM_NASM_OBJECT_FORMAT elf)
# Add `-f <format>` parameter when compiling NASM.  The value of `<format>`
# is set to `CMAKE_ASM_NASM_OBJECT_FORMAT` unless the target has the
# `NASM_OBJECT_FORMAT` property defined on it.
add_compile_options(
    #    if NASM is being compiled produce a string value, otherwise it's empty.
    "$<$<COMPILE_LANGUAGE:ASM_NASM>:-f $<IF:$<BOOL:$<TARGET_PROPERTY:NASM_OBJECT_FORMAT>>,\
    $<TARGET_PROPERTY:NASM_OBJECT_FORMAT>,${CMAKE_ASM_NASM_OBJECT_FORMAT}>>"
    # The produced value is 
    # "-f <TARGET_PROPERTY:NASM_OBJECT_FORMAT or CMAKE_ASM_NASM_OBJECT_FORMAT>".
)

# This is needed for NASM to find its %includes, which is merely a
# text replacement.  We don't need to link multiple object files, since NASM composes a one source file that contains all the includes.
include_directories(${PROJECT_SOURCE_DIR})
add_executable(boot-sect boot-sect.asm)
set_target_properties(boot-sect PROPERTIES NASM_OBJECT_FORMAT bin)
set_target_properties(boot-sect PROPERTIES OUTPUT_NAME boot-sect.bin)

# The structure of the operating system image is |boot loader|kernel|.  The
# |kernel| from the linker perspective is the entrance function that has to
# be in the beginning because that's what the boot loader start executing.
# The entrance function uses the typical C-linking to link another library called 
# "kernel".  libkernel can then depend on other libraries in a normal way.
add_library(int-types INTERFACE)
target_sources(int-types INTERFACE int-types.h)
add_library(idt-flush idt-flush.asm)
add_library(idt-handlers idt-handlers.asm)
add_library(kernel kernel.c)
target_link_libraries(kernel PUBLIC idt-flush)
target_link_libraries(kernel PUBLIC idt-handlers)
target_link_libraries(kernel PUBLIC int-types)

add_executable(system kernel-entry.c)
# This is actually passing arguments to GCC.  No need for special libraries 
# related to startup in user-space.  GCC still recommends to link with libgcc.
target_link_libraries(system "-nostdlib -lgcc -Wl,-Ttext -Wl,0x1000")
target_link_libraries(system kernel)
set_target_properties(system PROPERTIES ENABLE_EXPORTS 1)

# Call the linker directly to pass the special options.
add_custom_target(kernel-bin
  DEPENDS system
  COMMAND ${TOOLCHAIN_ROOT}/bin/${TARGET}-ld -o ${CMAKE_CURRENT_BINARY_DIR}/kernel.elf $<TARGET_LINKER_FILE:system>
  COMMAND ${TOOLCHAIN_ROOT}/bin/${TARGET}-objcopy -O binary -j ".text" -j ".data" -j ".bss" ${CMAKE_CURRENT_BINARY_DIR}/kernel.elf ${CMAKE_CURRENT_BINARY_DIR}/kernel.bin
  BYPRODUCTS kernel.elf kernel.bin
  )

# Merge together the boot-sector program together with the free standing C code.
add_custom_target(link-boot-sect
  DEPENDS kernel-bin boot-sect
  COMMAND sh -c 'cat $<TARGET_FILE:boot-sect> ${CMAKE_CURRENT_BINARY_DIR}/kernel.bin > ${CMAKE_CURRENT_BINARY_DIR}/boot-sect-kernel.bin'
  )

add_custom_target(run
  COMMAND bochs -f ../bochsrc.txt -q)  # `-q` skips the user prompt at the start.
add_dependencies(run link-boot-sect)
