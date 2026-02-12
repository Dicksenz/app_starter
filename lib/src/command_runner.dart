import 'dart:io';

import 'package:app_starter_plus/src/logger.dart';
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'models/app_model.dart';

/// Base app_starter class to launch app creation
class CommandRunner {
  /// Method called on app creation
  void create(List<String> args) async {
    final ArgParser parser = ArgParser()
      ..addOption(
        "name",
        abbr: "n",
        defaultsTo: null,
      )
      ..addOption(
        "template",
        abbr: "t",
        defaultsTo: null,
      )
      ..addOption(
        "org",
        abbr: "o",
        defaultsTo: null,
      )
      ..addFlag(
        "fvm",
        abbr: "f",
        negatable: false,
        defaultsTo: false,
      )
      ..addOption(
        "fvm-version",
        defaultsTo: null,
      )
      ..addFlag(
        "config",
        abbr: "c",
        negatable: false,
        defaultsTo: false,
      )
      ..addFlag(
        "save",
        abbr: "s",
        negatable: false,
        defaultsTo: false,
      )
      ..addFlag(
        "help",
        abbr: "h",
        negatable: false,
        defaultsTo: false,
      );

    final results = parser.parse(args);

    final bool save = results["save"];
    final bool showConfig = results["config"];
    final bool showHelp = results["help"];

    if (showHelp) {
      _showHelp();
      return;
    }

    final AppModel appModelFomConfig = AppModel.fromConfigFile();

    if (showConfig) {
      Logger.logConfigKeyValue("name", appModelFomConfig.name);
      Logger.logConfigKeyValue("organization", appModelFomConfig.organization);
      Logger.logConfigKeyValue(
          "template", appModelFomConfig.templateRepository);
      Logger.logConfigKeyValue("useFvm", appModelFomConfig.useFvm.toString());
      Logger.logConfigKeyValue("fvmVersion", appModelFomConfig.fvmVersion);

      return;
    }

    bool useFvm = results["fvm"] || (appModelFomConfig.useFvm ?? false);

    // Auto-detect FVM-only environment if flutter is not found but fvm is
    if (!useFvm) {
      final bool hasGlobalFlutter = _isCommandAvailable("flutter");
      final bool hasFvm = _isCommandAvailable("fvm");

      if (!hasGlobalFlutter && hasFvm) {
        Logger.logInfo(
            "Global flutter not found, but fvm detected. Switching to FVM mode.");
        useFvm = true;
      }
    }

    final AppModel appModel = AppModel(
      name: results["name"] ?? appModelFomConfig.name,
      organization: results["org"] ?? appModelFomConfig.organization,
      templateRepository:
          results["template"] ?? appModelFomConfig.templateRepository,
      useFvm: useFvm,
      fvmVersion: results["fvm-version"] ??
          appModelFomConfig.fvmVersion ??
          AppModel.getFvmVersionFromSource(),
    );

    bool hasOneFiledNull = false;

    if (appModel.name == null) {
      Logger.logError(
          "Package identifier argument not found, neither in config. --name or -n to add one.");
      hasOneFiledNull = true;
    }

    if (appModel.organization == null) {
      Logger.logError(
          "Organization identifier not found, neither in config. --org or -o to add one.");
      hasOneFiledNull = true;
    }

    if (appModel.templateRepository == null) {
      Logger.logError(
          "Template url not found, neither in config. --template or -t to use one.");
      hasOneFiledNull = true;
    }

    if (!appModel.hasValidPackageName()) {
      Logger.logError("${appModel.name} is not a dart valid package name");
      hasOneFiledNull = true;
    }

    if (hasOneFiledNull) return;

    if (save) {
      appModel.writeInConfigFile();
    }

    Logger.logInfo("Let's create ${appModel.name} application !");

    final Directory current = Directory.current;
    final String workingDirectoryPath = current.path;

    final String flutterExecutable =
        (appModel.useFvm ?? false) ? "fvm" : "flutter";
    final List<String> flutterArgsPrefix =
        (appModel.useFvm ?? false) ? ["flutter"] : [];

    try {
      final String versionMsg =
          appModel.fvmVersion != null ? "version: ${appModel.fvmVersion}" : "default";
      final String flutterVersionMsg =
          (appModel.useFvm ?? false) ? "FVM ($versionMsg)" : "your current flutter version";
      Logger.logInfo("Creating flutter project using $flutterVersionMsg...");

      final createProcess = await Process.start(
        flutterExecutable,
        [
          ...flutterArgsPrefix,
          "create",
          "--org",
          appModel.organization!,
          appModel.name!,
        ],
        workingDirectory: workingDirectoryPath,
        mode: ProcessStartMode.inheritStdio,
        runInShell: true,
      );
      await createProcess.exitCode;

      if (appModel.useFvm ?? false) {
        final versionToUse = appModel.fvmVersion ?? "stable";
        Logger.logInfo("Setting FVM version to $versionToUse...");
        final fvmUseProcess = await Process.start(
          "fvm",
          ["use", versionToUse],
          workingDirectory: "$workingDirectoryPath/${appModel.name}",
          mode: ProcessStartMode.inheritStdio,
          runInShell: true,
        );
        await fvmUseProcess.exitCode;
      }

      Logger.logInfo(
          "Retrieving your template from ${appModel.templateRepository}...");

      Process.runSync(
        "git",
        [
          "clone",
          appModel.templateRepository!,
          "temp",
        ],
        workingDirectory: "$workingDirectoryPath",
        runInShell: true,
      );

      final String content =
          await File("$workingDirectoryPath/temp/pubspec.yaml").readAsString();
      final mapData = loadYaml(content);
      final String templatePackageName = mapData["name"];

      _copyPasteDirectory(
        "$workingDirectoryPath/temp/lib",
        "$workingDirectoryPath/${appModel.name}/lib",
      );

      // Add assets
      _copyPasteDirectory(
        "$workingDirectoryPath/temp/assets",
        "$workingDirectoryPath/${appModel.name}/assets",
      );

      // Add .vscode
      _copyPasteDirectory(
        "$workingDirectoryPath/temp/.vscode",
        "$workingDirectoryPath/${appModel.name}/.vscode",
      );

      // Add .githooks
      _copyPasteDirectory(
        "$workingDirectoryPath/temp/.githooks",
        "$workingDirectoryPath/${appModel.name}/.githooks",
      );

      // Add .cursor
      final Directory cursorDir =
          Directory("$workingDirectoryPath/temp/.cursor");
      if (cursorDir.existsSync()) {
        _copyPasteDirectory(
          "$workingDirectoryPath/temp/.cursor",
          "$workingDirectoryPath/${appModel.name}/.cursor",
        );
      }

      _copyPasteDirectory(
        "$workingDirectoryPath/temp/test",
        "$workingDirectoryPath/${appModel.name}/test",
      );

      await _copyPasteFileContent(
        "$workingDirectoryPath/temp/pubspec.yaml",
        "$workingDirectoryPath/${appModel.name}/pubspec.yaml",
      );

      await _changeAllInFile(
        "$workingDirectoryPath/${appModel.name}/pubspec.yaml",
        templatePackageName,
        appModel.name!,
      );

      // Change readme
      await _copyPasteFileContent(
        "$workingDirectoryPath/temp/README.md",
        "$workingDirectoryPath/${appModel.name}/README.md",
      );

      await _changeAllInFile(
        "$workingDirectoryPath/${appModel.name}/README.md",
        templatePackageName,
        appModel.name!,
      );

      // Change analysis_options.yaml
      await _copyPasteFileContent(
        "$workingDirectoryPath/temp/analysis_options.yaml",
        "$workingDirectoryPath/${appModel.name}/analysis_options.yaml",
      );

      await _changeAllInFile(
        "$workingDirectoryPath/${appModel.name}/analysis_options.yaml",
        templatePackageName,
        appModel.name!,
      );

      // Change .gitignore
      await _copyPasteFileContent(
        "$workingDirectoryPath/temp/.gitignore",
        "$workingDirectoryPath/${appModel.name}/.gitignore",
      );

      await _changeAllInFile(
        "$workingDirectoryPath/${appModel.name}/.gitignore",
        templatePackageName,
        appModel.name!,
      );

      // Add flavorizr.yaml
      await _copyPasteFileContent(
        "$workingDirectoryPath/temp/flavorizr.yaml",
        "$workingDirectoryPath/${appModel.name}/flavorizr.yaml",
      );
      await _changeAllInFile(
        "$workingDirectoryPath/${appModel.name}/flavorizr.yaml",
        templatePackageName,
        appModel.name!,
      );

      await _changeAllInDirectory(
        "$workingDirectoryPath/${appModel.name}/lib",
        templatePackageName,
        appModel.name!,
      );

      await _changeAllInDirectory(
        "$workingDirectoryPath/${appModel.name}/test",
        templatePackageName,
        appModel.name!,
      );

      final pubGetProcess = await Process.start(
        flutterExecutable,
        [
          ...flutterArgsPrefix,
          "pub",
          "get",
        ],
        workingDirectory: "$workingDirectoryPath/${appModel.name}",
        mode: ProcessStartMode.inheritStdio,
        runInShell: true,
      );
      await pubGetProcess.exitCode;

      Logger.logInfo("Deleting temp files used for generation...");

      Process.runSync(
        "rm",
        [
          "-rf",
          "$workingDirectoryPath/temp",
        ],
      );

      Logger.logInfo("You are good to go ! :)", lineBreak: true);
    } catch (error) {
      Logger.logError("Error creating project : $error");

      Process.runSync(
        "rm",
        [
          "-rf",
          "$workingDirectoryPath/${appModel.name}",
        ],
      );
      Process.runSync(
        "rm",
        [
          "-rf",
          "$workingDirectoryPath/temp",
        ],
      );
    }
  }

  /// Copy all the content of [sourceFilePath] and paste it in [targetFilePath]
  Future<void> _copyPasteFileContent(
      String sourceFilePath, String targetFilePath) async {
    try {
      final File sourceFile = File(sourceFilePath);
      final File targetFile = File(targetFilePath);

      final String sourceContent = sourceFile.readAsStringSync();
      targetFile.writeAsStringSync(sourceContent);
    } catch (error) {
      Logger.logError("Error copying file contents : $error");
    }
  }

  /// Copy all the content of [sourceDirPath] and paste it in [targetDirPath]
  void _copyPasteDirectory(
    String sourceDirPath,
    String targetDirPath,
  ) {
    Process.runSync(
      "rm",
      [
        "-rf",
        targetDirPath,
      ],
    );

    Process.runSync(
      "cp",
      [
        "-r",
        sourceDirPath,
        targetDirPath,
      ],
    );
  }

  /// Update recursively all imports in [directoryPath] from [oldPackageName] to [newPackageName]
  Future<void> _changeAllInDirectory(String directoryPath,
      String oldPackageName, String newPackageName) async {
    final Directory directory = Directory(directoryPath);
    final String dirName = directoryPath.split("/").last;
    if (directory.existsSync()) {
      final List<FileSystemEntity> files = directory.listSync(recursive: true);
      await Future.forEach(
        files,
        (FileSystemEntity fileSystemEntity) async {
          if (fileSystemEntity is File) {
            await _changeAllInFile(
                fileSystemEntity.path, oldPackageName, newPackageName);
          }
        },
      );
      Logger.logInfo(
          "All files in $dirName updated with new package name ($newPackageName)");
    } else {
      Logger.logWarning(
          "Missing directory $dirName in your template, it will be ignored");
    }
  }

  /// Update recursively all imports in [filePath] from [oldPackageName] to [newPackageName]
  Future<void> _changeAllInFile(
      String filePath, String oldValue, String newValue) async {
    try {
      final File file = File(filePath);
      final String content = file.readAsStringSync();
      if (content.contains(oldValue)) {
        final String newContent = content.replaceAll(oldValue, newValue);
        file.writeAsStringSync(newContent);
      }
    } catch (error) {
      Logger.logError("Error updating file $filePath : $error");
    }
  }

  /// Simply print help message
  void _showHelp() {
    print("""
    
usage: app_starter [--save] [--name <name>] [--org <org>] [--template <template>] [--fvm] [--fvm-version <version>] [--config]

* Abbreviations:

--name      |  -n
--org       |  -o
--template  |  -t
--fvm       |  -f
--save      |  -s
--config    |  -c

* Add information about the app and the template:
  
name        ->       indicates the package identifier (ex: toto)
org         ->       indicates the organization identifier (ex: io.example)
template    ->       indicates the template repository (ex: https://github.com/ThomasEcalle/flappy_template)
fvm         ->       indicates if the tool should use fvm (ex: --fvm or -f)
fvm-version ->       indicates the flutter version to use with fvm (ex: --fvm-version 3.10.0)

* Store default information for future usages:

save       ->       save information in config file in order to have default configuration values

For example, running : app_starter --save -n toto -o io.example -t https://github.com/ThomasEcalle/flappy_template --fvm
  
This will store these information in configuration file.
That way, next time, you could for example just run : app_starter -n myapp
Organization, Template and FVM values would be taken from config.

config     ->      shows values stored in configuration file
    """);
  }

  bool _isCommandAvailable(String command) {
    try {
      final result = Process.runSync(
        Platform.isWindows ? 'where' : 'which',
        [command],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
