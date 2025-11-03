- [ ] `#load` should only make symbols available for that individual file
- [ ] do some housekeeping around the compiler, I'm a little iffy about how types are handled
- [ ] support pointers
- [ ] add struct methods
- [ ] better error messages and add warning and error codes
- [ ] support the `using` keyword
- [ ] support adding the same namespace twice in different files.
- [ ] enforce structs be initialized in order to be used
- [ ] `assert` function

## Todo
LTO (link time optimization) in release mode is currently disabled due to pointer stuff being wack. I need to make a bug report or something...