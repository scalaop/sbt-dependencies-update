# Checking and updating for new dependency updates

The sbt-dependencies-update goal will update corresponding dependencies used in your project in `build.sbt`.

Here is an example of what this looks like:

```bash
docker pull scalaop/sbt-dependencies-update
docker run --rm -ti -v $PWD/example:/build scalaop/sbt-dependencies-update
```

The output of an execution will be:
```
  "io.opentracing.contrib" % "opentracing-concurrent" % "0.2.0->0.4.0" % Provided exclude("net.sf.jopt-simple", "jopt-simple"), // Comment
  "io.opentracing" % "opentracing-util" % "0.31.0->0.33.0" /* Comment */
  "org.apache.kafka" % "kafka-clients" % "2.0.0->2.2.0" exclude("org.slf4j", "slf4j-api"),
  "org.scalatest" %% "scalatest" % "3.0.7->3.2.0-SNAP10" % Test,
  "junit" % "junit" % "4.12->4.13-beta-3" % Test
```

The original build.sbt will be updated to:

```scala

lazy val root = (project in file("."))
  .settings(
    organization := "org.sbt.dependency.libs",
    name := "sbt-dependency-lib",
    libraryDependencies ++= compileDependencies ++ testDependencies
  )

lazy val compileDependencies = Seq(
  "io.opentracing.contrib" % "opentracing-concurrent" % "0.4.0" % Provided exclude("net.sf.jopt-simple", "jopt-simple"), // Comment
  "io.opentracing" % "opentracing-util" % "0.33.0" /* Comment */
  "org.apache.kafka" % "kafka-clients" % "2.2.0" exclude("org.slf4j", "slf4j-api")
)

lazy val testDependencies = Seq(
  "org.scalatest" %% "scalatest" % "3.2.0-SNAP10" % Test,
  "junit" % "junit" % "4.13-beta-3" % Test
)

```

## Conventions

The script will keep indent, scope, exclusions and comments. 
At the moment, it does support dependencies in `build.sbt` defined in the following format:

```scala
"groupId" (%% | %) "artifactId" % "version" % Scope Exclusion (// Comment | /* Comment */)
```

The dependency should be specified in one line.

## Configuration

The configuration is kept in `sbt-update.conf` and default values are:
```groovy
nexus.host = 'https://repo.maven.apache.org/maven2'
groups = '.*'
scala.version = '2.11'
```

- `nexus.host` the host is pointing to nexus repository, it can be your corporate Nexus
- `groups` regex defines the `groupId` of artifacts that has to be updated
- `scala.version` Scala version

In order to orverride the configuration, just mount new one as a volume:

```bash
docker run --rm -ti -v $PWD/example:/build -v $PWD/sbt-update.conf:/sbt-update.conf scalaop/sbt-dependencies-update
```
