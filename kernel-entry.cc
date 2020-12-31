extern int kernel_main();
extern "C" int _start() {
  return kernel_main();
}
