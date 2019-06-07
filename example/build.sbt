
lazy val root = (project in file("."))
  .settings(
    organization := "org.sbt.dependency.libs",
    name := "sbt-dependency-lib",
    libraryDependencies ++= compileDependencies ++ testDependencies
  )

lazy val compileDependencies = Seq(
  "io.opentracing.contrib" %  "opentracing-concurrent" % "0.2.0" % Provided exclude("net.sf.jopt-simple", "jopt-simple"), // Comment
  "io.opentracing" %  "opentracing-util" % "0.31.0", /* Comment */
  "org.apache.kafka" % "kafka-clients" % "2.0.0" exclude("org.slf4j", "slf4j-api")
)

lazy val testDependencies = Seq(
  "org.scalatest" %%  "scalatest"     % "3.0.7" % Test,
  "junit"         %   "junit"         % "4.12"  % Test
)
