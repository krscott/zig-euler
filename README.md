# zig-euler

[Project Euler](https://projecteuler.net/) exercises solved with [Zig](https://ziglang.org/), and no dependencies other than the standard library.

## Usage

Run an individual solution number N (as in `euler-N.zig`) with `zig build N`.

Run tests for all solutions with `zig build test`

## Notes

This is me learning Zig and experimenting with its features. These solutions are probably
not anywhere near minimal, nor "production-ready". Caveat lector.

That said, I've created helper libs (`./src/common/*.zig`) that might be useful outside of academic problems:

* `iterutil.zig` - Iterator helpers (e.g. `map(f, iter)`) that work with generic function and iterator duck-types. Will be extra nice once [function expressions](https://github.com/ziglang/zig/issues/1717) are added.
* `bigdecimal.zig` - Handling large ints represented by strings. Directly uses decimal operations.
* `sliceutil.zig` - Generic slice inspection methods (e.g. `indexOf()` and `contains()`)
