## Development

#### Local

Developing on openbel-api requires the following system dependencies:

- Git
- Java 8 (JDK)
- JRuby 9.x
- MongoDB 3.2
- SQLite 3.x

Setting up data:

- To start you will have to obtain RDF resources and full-text search
  database containing biological concepts (e.g. annotations, namespaces).
  Obtain data from [OpenBEL Build Server](https://build.openbel.org/browse/OR).

Then follow a few steps:

1. Clone the *openbel-api* using Git.
  - `git clone git@github.com:OpenBEL/openbel-api.git`
2. Change directory to the cloned repository.
  - `cd openbel-api`
3. Clone submodules for local developement to the *subprojects/* directory.
  - `git submodule update`
4. Install bundle on JRuby.
  - `jruby -S gem install bundler`
5. Install *openbel-api* dependencies using bundler.
  - ` jruby -S bundle install --path .gems`
  - This ensures we isolate gem dependencies from other system gem paths.
  - Bundler saves this configuration so we don't need to specify *--path*
    again.
6. Run *bin/openbel-api* using bundler.
  - `jruby -S bundle exec bin/openbel-api --file config/config.yml`

If all went well you should see:

```
Puma starting in single mode...
* Version 3.1.0 (jruby 2.3.1), codename: El Niño Winter Wonderland
* Min threads: 0, max threads: 16
* Environment: development
* Listening on tcp://0.0.0.0:9292
Use Ctrl-C to stop
```

#### On Docker

Please see the DOCKER.md file for guidance with Docker

### Running Tests


    API_ROOT_URL=https://pmi-openbel.sbvimprover.com/api rspec -fd spec/expression/*

You will need to install the **hyperclient** gem first with: `gem install hyperclient`