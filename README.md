# mvn-parent-jdk17

Maven Parent POM for JDK 17 projects - a companion module to [mvn-parent](https://github.com/sabirhussain/mvn-parent).

## Overview

`mvn-parent-jdk17` extends `mvn-parent` to provide JDK 17-specific configurations while inheriting all the standard
build configurations, plugin management, and best practices from the base parent POM.

### Key Features

- **JDK 17 Configuration**: Pre-configured for Java 17 with appropriate compiler settings
- **Eclipse Temurin Base Image**: Uses `eclipse-temurin:17-jre-alpine` for Jib containerization
- **Inherits from mvn-parent**: Gets all standard plugin versions and configurations
- **Flexible Installation**: Supports both local filesystem and remote git repository sources

## Purpose

This module solves the problem of managing JDK-specific configurations separately from the base parent POM. It allows
organizations to:

1. Maintain a single base parent POM (`mvn-parent`) with company-wide standards
2. Create JDK-version-specific parents (like this JDK 17 variant) that extend the base
3. Let projects choose the appropriate JDK-versioned parent based on their requirements

## Prerequisites

### For Installation

The installer requires:

- **Bash** shell
- **Git** (only if using remote git URL for mvn-parent)
- **mvn-parent** repository - either:
    - A local filesystem path to your customized `mvn-parent`, OR
    - A git repository URL (GitHub, GitLab, Bitbucket, etc.) of your forked `mvn-parent`
- **.env file** - must exist in either:
    - Your `mvn-parent` repository directory, OR
    - `~/.m2/.env`

**Optional (for better XML parsing)**:

- **Python 3** - Preferred for POM parsing, but installer will fall back to awk if not available

### For Post-Installation Use

After installation, to build and deploy the POM, you'll need:

- **Maven** 3.6+ (for `mvn clean install` and `mvn deploy`)
- **Java** 17+ (for building projects that use this parent POM)

### Why mvn-parent is Required

The `mvn-parent-jdk17` POM has a `<parent>` reference to `mvn-parent`. During installation, the script:

1. Extracts the `groupId` and `version` from your `mvn-parent` POM
2. Updates the parent coordinates in `mvn-parent-jdk17` to match your customized version
3. Optionally inherits the same `groupId` for the JDK17 module

## Installation

### Remote Installation (Recommended)

Use this method to install from anywhere:

```bash
# Navigate to your desired installation directory
cd /path/to/installation/directory
```
```bash
# Run the remote installer
bash <(curl -fsSL https://raw.githubusercontent.com/sabirhussain/mvn-parent-jdk17/main/install/install.sh)
```

The installer will prompt you for:

1. **mvn-parent location**: Choose `local` (filesystem path) or `remote` (git URL)
2. **Module groupId**: Override the default `io.xprevel.jdk17` or use parent's groupId

### Local Installation

If you have cloned this repository locally:

```bash
# Navigate to your desired installation directory
cd /path/to/installation/directory

# Run the local installer
bash /path/to/mvn-parent-jdk17/install/local-install.sh
```

### Installation Options

#### Option 1: Local mvn-parent Path

```
Use [local] filesystem path or [remote] git URL? local
Enter absolute path to mvn-parent repository: /Users/yourname/projects/mvn-parent
```

#### Option 2: Remote mvn-parent Git URL

```
Use [local] filesystem path or [remote] git URL? remote
Enter git repository URL for mvn-parent: https://github.com/yourorg/mvn-parent.git
```

### GroupId Inheritance

During installation, you can choose whether to:

1. **Use parent groupId** (e.g., `com.mycompany`) - the module groupId will be *omitted* from the POM and inherited from
   parent
2. **Use custom groupId** (e.g., `com.mycompany.jdk17`) - the module groupId will be explicitly set

**Recommendation**: Use the same groupId as parent for simpler dependency management.

## Post-Installation

After installation, you'll have these files in your installation directory:

```
.
├── pom.xml       # Customized with your parent coordinates
├── .gitignore    # Standard Java .gitignore
├── LICENSE       # Apache 2.0 License
├── .env          # Environment variables copied from mvn-parent or ~/.m2
└── .mvn/
    └── maven.config  # Copied from mvn-parent if present
```

### Next Steps

1. **Review** the generated `pom.xml`
2. **Install** to your local Maven repository:
   ```bash
   mvn clean install
   ```
3. **Deploy** to your company's artifact repository (Nexus/Artifactory):
   ```bash
   mvn deploy
   ```
4. **Use** in your JDK 17 projects:
   ```xml
   <parent>
       <groupId>com.yourcompany</groupId>
       <artifactId>mvn-parent-jdk17</artifactId>
       <version>1.0.0-SNAPSHOT</version>
   </parent>
   ```

## Usage in Projects

To use this parent POM in your JDK 17 Maven projects:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>com.yourcompany</groupId>
        <artifactId>mvn-parent-jdk17</artifactId>
        <version>1.0.0-SNAPSHOT</version>
    </parent>

    <artifactId>your-jdk17-project</artifactId>
    <version>1.0.0-SNAPSHOT</version>

    <!-- Your project configuration -->
</project>
```

## What You Get

By using `mvn-parent-jdk17` as your parent POM, your projects automatically get:

### From mvn-parent:

- Standard plugin versions (compiler, surefire, failsafe, jar, etc.)
- Jacoco code coverage configuration
- SonarQube integration
- Jib containerization plugin
- Container registry configuration

### From mvn-parent-jdk17:

- Java 17 compiler configuration (`source` and `target` set to 17)
- Eclipse Temurin 17 JRE Alpine base image for containers
- Maven compiler release flag set to 17

## Customization

After installation, you can customize the `pom.xml` to add:

- Additional properties
- Extra plugin configurations
- Company-specific profiles
- Dependency management

Remember to reinstall/redeploy after customizations:

```bash
mvn clean install
# or
mvn deploy
```

## Troubleshooting

### .env file not found

**Error**: `.env file not found`

**Solution**: Create a `.env` file in either:

- Your `mvn-parent` repository directory, or
- `~/.m2/.env`

Example `.env` content:

```properties
MAVEN_REGISTRY_URL=https://nexus.yourcompany.com/repository/maven-releases/
MAVEN_SNAPSHOT_URL=https://nexus.yourcompany.com/repository/maven-snapshots/
CONTAINER_REGISTRY=docker.io
CONTAINER_ORGANIZATION=yourcompany
```

### .mvn/maven.config not found

**Warning**: `.mvn/maven.config not found in mvn-parent repository`

**Behavior**: Installer continues without copying this file.

**Optional Solution**: If your builds rely on Maven CLI options from `maven.config`, add this file to your `mvn-parent`
repository at:

- `.mvn/maven.config`

### Parent POM not found during build

**Error**: `Non-resolvable parent POM`

**Solution**: Ensure your `mvn-parent` is installed in your local repository or deployed to your artifact repository:

```bash
cd /path/to/mvn-parent
mvn clean install
# or
mvn deploy
```

## License

Apache License 2.0 - See LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Related Projects

- [mvn-parent](https://github.com/sabirhussain/mvn-parent) - Base Maven Parent POM

## Support

For issues and questions:

- Open an issue on GitHub
- Check existing issues for solutions
