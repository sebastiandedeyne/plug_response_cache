# PlugResponseCache

[![Hex.pm](https://img.shields.io/hexpm/v/plug_response_cache.svg)](https://hex.pm/packages/plug_response_cache)
[![Hex.pm](https://img.shields.io/hexpm/dt/plug_response_cache.svg)](https://hex.pm/packages/plug_response_cache)
[![Travis](https://img.shields.io/travis/sebastiandedeyne/plug_response_cache.svg)](https://travis-ci.org/sebastiandedeyne/plug_response_cache)

A highly-configurable plug module to cache entire responses.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `plug_response_cache` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:plug_response_cache, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc) and published on [HexDocs](https://hexdocs.pm). Once published, the docs can be found at [https://hexdocs.pm/plug_response_cache](https://hexdocs.pm/plug_response_cache).

## Usage

See [https://hexdocs.pm/plug_response_cache/](https://hexdocs.pm/plug_response_cache/)

## Changelog

Please see [CHANGELOG](https://github.com/sebastiandedeyne/plug_response_cache/blob/master/CHANGELOG.md) for more information what has changed recently.

## Testing

```bash
$ mix test
```

## Contributing

Pull requests are welcome!

## Credits

This package is based on the Laravel (PHP) [response cache package](github.com/spatie/laravel-responsecache) by Spatie.

- [Sebastian De Deyne](https://github.com/sebastiandedeyne)
- [All Contributors](../../contributors)

## Alternative libraries

There are two similar libraries on Hex I know of.

- [mneudert/plug_pagecache](https://github.com/mneudert/plug_pagecache) - Also supports an Agent cache
- [andreapavoni/plug_ets_cache](https://github.com/andreapavoni/plug_ets_cache) - Has more granular ttl configuration

No other implementations implement conditional caching based on the request or response, or dynamic expiration times.

## License

The MIT License (MIT). Please check the [LICENSE](https://github.com/sebastiandedeyne/plug_response_cache/blob/master/LICENSE.md) for more information.
