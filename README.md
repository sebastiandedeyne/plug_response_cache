# PlugResponseCache

[![Hex.pm](https://img.shields.io/hexpm/v/plug_response_cache.svg)](https://hex.pm/packages/plug_response_cache)
[![Hex.pm](https://img.shields.io/hexpm/dt/plug_response_cache.svg)](https://hex.pm/packages/plug_response_cache)
[![Travis](https://img.shields.io/travis/sebastiandedeyne/plug_response_cache.svg)](https://travis-ci.org/sebastiandedeyne/plug_response_cache)

A highly-configurable plug to cache entire responses. The library allows you to configure _if_, _how long_ and _where_ a response will be cached.

## Installation

The package can be installed by adding `plug_response_cache` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:plug_response_cache, "~> 0.1.0"}
  ]
end
```

## Usage

Below is a brief overview on how to use `PlugResponseCache`. Full documentation can be found at [https://hexdocs.pm/plug_response_cache/](https://hexdocs.pm/plug_response_cache/).

### Basic usage

After installing the library, add the plug to your pipeline as early as possible. Here's what that looks like in a clean Phoenix installation:

```elixir
pipeline :browser do
  plug(:accepts, ["html"])
  plug(PlugResponseCache)
  plug(:fetch_session)
  plug(:fetch_flash)
  plug(:protect_from_forgery)
  plug(:put_secure_browser_headers)
end
```

And that's it! For basic usage at least. The default configuration will cache all successful GET requests in an ETS table forever. If you want a different configuration, read on.

### Configuration

The recommended way to configure the response cache is through your application's configuration. Since all keys have a default, you only need to specify the ones you want to override.

```elixir
config :plug_response_cache,
  enabled: false,
  store: MyApp.ResponseCache.MyCustomStore
  profile: MyApp.ResponseCache.MyCustomProfile
```

- `enabled`: Enables or disables the response cache entirely (default: `true`)
- `store`: A custom cache store — a module that implements `PlugResponseCache.Store` callbacks (default: `PlugResponseCache.Stores.Ets`)
- `profile`: A custom cache profile — a module that implements `PlugResponseCache.Profile` callbacks (default: `PlugResponseCache.Profiles.Default`)
- `debug`: Logs the response cache's result on every request when `true` (default: `false`)

Since every option has a default, the response cache will also work without specifying any custom configuration.

Options are also passed to the cache profile, so if a profile has options simply add them to the list. For example, the default profile (`PlugResponseCache.Profiles.Default`) has an `expiration_time` option to determine for how many minutes the response should be cached.

```elixir
config :plug_response_cache,
  expiration_time: 5
```

It's also possible to pass options to the plug. This is useful for enabling or disabling the response cache on the fly, or for toggling the debug mode.

```elixir
pipeline :browser do
  # ...
  plug(PlugResponseCache, debug: true)
  # ...
end
```

It's not recommended to configure the profile & store like this because they might require a supervisor, which needs to be known ahead of time.

### Profiles

Profiles are the heart of PlugResponseCache's configurability. They determine _if_ and for _how long_ a response should be cached. The default profile caches all succesfull GET requests for a configurable amount of minutes. For a full example implementation, take a look at the [`PlugResponseCache.Profiles.Default` module](https://github.com/sebastiandedeyne/plug_response_cache/blob/master/lib/plug_response_cache/profiles/default.ex).

With `cache_request?` you can choose whether or not to retrieve a cached response, or cache it if the cache is cold. Here we'll set up our profile to only cache GET requests.

```elixir
defmodule MyCacheProfile do
  @behaviour PlugResponseCache.Profile

  alias Plug.Conn

  def cache_request?(%Conn{method: "GET"}, _opts), do: true
  def cache_request?(_conn, _opts), do: false

  # ...
end
```

The `cache_request?` callback probably the most interesting one to override. For example if you'd only want to cache a specific section of your application based on the url or on user authentication.

With `cache_response?` you can choose whether or not to cache a response before it's sent. Here we'll only cache the response if it was successful.

```elixir
defmodule MyCacheProfile do
  @behaviour PlugResponseCache.Profile

  alias Plug.Conn

  # ...

  def cache_response?(%Conn{status: status}, _opts), do: status < 400
  def cache_response?(_conn, _opts), do: true
end
```

With `expires` we can determine at what time the cached response will be expired. If we want to cache the response forever, we can return a `:never` tuple. The default profile accepts an `expire_time` option set in minutes.

```elixir
defmodule MyCacheProfile do
  @behaviour PlugResponseCache.Profile

  alias Plug.Conn

  # ...

  def expires(_conn, %{expiration_time: expiration_time}),
    do: :os.system_time(:seconds) + expiration_time * 60

  def expires(_conn, _opts), do: :never
end
```

Refer to the [`Profile` behaviour's documentation](https://hexdocs.pm/plug_response_cache/PlugResponseCache.Profile.html) for a more detailed explanation of the various callbacks.

### Stores

Stores determine _where_ a response should be cached. By default, responses are stored in an ETS table.

For a full example implementation, take a look at the [`PlugResponseCache.Stores.Ets` module](https://github.com/sebastiandedeyne/plug_response_cache/blob/master/lib/plug_response_cache/stores/ets.ex).

Refer to the [`Store` behaviour's documentation](https://hexdocs.pm/plug_response_cache/PlugResponseCache.Store.html) for a more detailed explanation of the various callbacks.

## Changelog

Please see [CHANGELOG](https://github.com/sebastiandedeyne/plug_response_cache/blob/master/CHANGELOG.md) for more information what has changed recently.

## Testing

```bash
$ mix test
```

## Contributing

Pull requests are welcome!

## Credits

This package is based on the Laravel (PHP) [response cache package](https://github.com/spatie/laravel-responsecache) by [Spatie](https://spatie.be).

- [Sebastian De Deyne](https://github.com/sebastiandedeyne)
- [All Contributors](../../contributors)

## Alternative libraries

There are two similar Elixir libraries I know of:

- [mneudert/plug_pagecache](https://github.com/mneudert/plug_pagecache) - Also supports an Agent cache out of the box
- [andreapavoni/plug_ets_cache](https://github.com/andreapavoni/plug_ets_cache) - Has more granular ttl configuration

## License

The MIT License (MIT). Please check the [LICENSE](https://github.com/sebastiandedeyne/plug_response_cache/blob/master/LICENSE.md) for more information.
