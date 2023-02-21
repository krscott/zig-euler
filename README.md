# zig-euler

[Project Euler](https://projecteuler.net/) exercises solved with [Zig](https://ziglang.org/), and no dependencies other than the standard library.

## Usage

Run an individual solution number N (as in `euler-N.zig`) with `zig build N`.

Run tests for all solutions with `zig build test`

## Notes

This is me learning Zig and experimenting with its features. These solutions are probably
not anywhere near minimal, nor "production-ready". Caveat lector.

Since I only got the standard library, here's some notable things I needed to implement:

* `iterutil.zig` - Iterator helpers (e.g. `iter.map(func1).filter(func2)`) that work with
  generic function and iterators. Will be extra nice once
  [function expressions](https://github.com/ziglang/zig/issues/1717) are added.
  (Looks like there exist a few
  [good libraries](https://github.com/ziglang/zig/issues/6185#issuecomment-683261019) already)
* `sliceutil.zig` - Generic slice inspection functions (e.g. `indexOf()` and `contains()`)
  and a `formatSlice()` function for easily formatting/printing slices.
* `primes.zig` - Prime number generation and fast factorization.
* `bigdecimal.zig` - String-based number type for manipulating arbitrarily large numbers.
* `fitting.zig` - Least-squares curve-fitting on data points

## Zig Version

0.10.0-dev.3385+c0a1b4fa4

Almost 0.10.1:
* requires `-fstage1`
* fix errors in `std/os.zig`: `0` -> `@as(usize, 0)`
