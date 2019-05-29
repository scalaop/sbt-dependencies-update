#!/usr/bin/env groovy

class Dependency {
    def exclude
    def artifactId
    def groupId
    def version
    def scope
    def crossCompiled = false
    def indent
    def comma
    def comment
    def line

}

class SbtVersionUpdater {
    def migrate = false

    def buildFolder = "/build"

    def config

    static void main(String[] args) {
        new SbtVersionUpdater().updateSbt()
    }


    SbtVersionUpdater() {
        config = new ConfigSlurper().parse(new File("/sbt-update.conf").toURI().toURL())
    }

    def updateSbt() {
        def buildSbt = readBuildSbt()

        def sb = new StringBuffer()
        buildSbt.eachLine { line ->
            if (line =~ /"${config.groups}.*"\s*(%|%%)\s*".*"\s*(%|%%)\s*".*("|,|\))/) {
                def dependency = resolveDependency(line)

                if (dependency) {
                    sb.append updateDependency(dependency) + "\n"
                }
            } else {
                sb.append line + "\n"
            }
        }

        applyNewBuildSbt(sb.toString())
    }

    def readBuildSbt() {
        new File("$buildFolder/build.sbt").text
    }

    def updateDependency(dependency) {
        try {
            def scalaArtifactId = dependency.artifactId + (dependency.crossCompiled ? "_${config.scala.version}" : "")
            def nexusGroupId = dependency.groupId.replaceAll("\\.", "/")

            def metaData = String.format(config.nexus.host + "/%s/%s/maven-metadata.xml", nexusGroupId, scalaArtifactId).toURL().text

            def newVersion = resolveLatestVersion(metaData)
            def line = ""
            if (!dependency.version.equals(newVersion)) {

                migrate = true

                def scope = dependency.scope ? " % ${dependency.scope}" : ""
                def exclusion = dependency.exclude ? " ${dependency.exclude}" : ""
                def comment = dependency.comment ? " ${dependency.comment}" : ""

                line = """${dependency.indent}"${dependency.groupId}" ${dependency.crossCompiled ? "%%" : "%"} "${
                    dependency.artifactId
                }" % "${newVersion}"${scope}${exclusion}${dependency.comma}${comment}"""

                println """${dependency.indent}"${dependency.groupId}" ${dependency.crossCompiled ? "%%" : "%"} "${
                    dependency.artifactId
                }" % "${dependency.version}->${newVersion}"${scope}${exclusion}${dependency.comma}${comment}"""
            }

            line
        } catch (e) {
            println "Can't resolve dependency in given line: ${dependency.line}"
        }
    }

    def resolveDependency(line) {
        def dep = new Dependency()
        dep.line = line

        dep.indent = " ".multiply(line.indexOf("\""))

        def commentGroup = line =~ /(\/\/.*|\/\*.*\*\/)/

        dep.comment = commentGroup.find() ? commentGroup.group() : null
        line = line.replaceAll("//.*", "")

        dep.comma = line.trim().endsWith(",") ? "," : ""

        def excludeGroup = line =~ /exclude(.*)/
        //TODO Update exclude as well
        dep.exclude = excludeGroup.find() ? excludeGroup.group().trim() : null
        if (dep.exclude?.endsWith(",")) {
            dep.exclude = dep.exclude?.substring(0, dep.exclude?.length() - 1)
        }


        def artifactGroup = line =~ /".*"\s*%*\s*".*"\s*%\s*"(\d|\.)*"/
        def artifactId = artifactGroup.find() ? artifactGroup.group() : null

        if (!artifactId) {
            println "Can't resolve dependency in given line: $line"
            return null
        }

        if (artifactId.contains("%%")) {
            dep.crossCompiled = true
        }

        def attributes = artifactId.replaceAll("%%", "%").split("%")
        dep.groupId = attributes[0].trim().replaceAll("\"", "")
        dep.artifactId = attributes[1].trim().replaceAll("\"", "")
        dep.version = attributes[2].trim().replaceAll("\"", "")

        def scope = line.replaceAll("exclude\\(.*\\),?", "").replaceAll("(//.*|/\\*.*\\*/)", "")
        scope = scope
                .replaceAll("""${""}".*"\\s*%*\\s*".*"\\s*%\\s*"(\\d|\\.)*"${""}""", "")
                .replaceAll(",|%|\\s", "")

        dep.scope = scope

        return dep
    }

    def resolveLatestVersion(metaData) {
        def xml = new XmlParser().parseText(metaData)
        xml.versioning.release.text()
    }

    def applyNewBuildSbt(newBuildSbtTxt) {
        if (migrate) {
            def oldFile = new File("$buildFolder/build.sbt")
            def newFile = new File("$buildFolder/new-build.sbt")

            newFile.delete()
            newFile << newBuildSbtTxt

            oldFile.delete()

            newFile.renameTo(oldFile)
        } else {
            println "No changes required"
        }
    }

}

new SbtVersionUpdater().updateSbt()