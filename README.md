# Checking and updating for new dependency updates

The sbt-dependencies-update goal will update corresponding dependencies used in your project in `build.sbt`.

Here is an example of what this looks like:

```bash
docker pull bapbap/sbt-dependencies-update
docker run --rm -ti -v $PWD/example:/build bapbap/sbt-dependencies-update
```

