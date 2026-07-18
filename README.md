# brModelo

Fork of [chcandido/brModelo](https://github.com/chcandido/brModelo).

## What's different here

- macOS app bundle packaging via `package-macos.sh`
- Open-file handler for `.brM3` files on macOS

## Building

```sh
ant jar
./package-macos.sh
```

Then drag `brModelo.app` to `/Applications`.
