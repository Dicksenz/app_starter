import 'dart:convert';
import 'dart:io';

import 'package:app_starter_plus/src/utils.dart';

/// Model representing app information
class AppModel {
  final String? name;
  final String? organization;
  final String? templateRepository;
  final bool? useFvm;
  final String? fvmVersion;

  AppModel({
    required this.name,
    required this.organization,
    required this.templateRepository,
    this.useFvm,
    this.fvmVersion,
  });

  /// Generate AppModel instance from configuration file
  factory AppModel.fromConfigFile() {
    final File configFile = Utils.getConfigFile();
    if (configFile.existsSync()) {
      final Map<String, dynamic> json =
          jsonDecode(configFile.readAsStringSync());
      return AppModel(
        name: json["name"],
        organization: json["organization"],
        templateRepository: json["template"],
        useFvm: json["useFvm"],
        fvmVersion: json["fvmVersion"],
      );
    }

    return AppModel(
      name: null,
      organization: null,
      templateRepository: null,
      useFvm: null,
      fvmVersion: null,
    );
  }

  /// Write information in config file
  void writeInConfigFile() {
    final String jsonText = _toJsonText();
    final File configFile = Utils.getConfigFile();
    configFile.writeAsStringSync(jsonText, mode: FileMode.write);
  }

  /// Read FVM version from .fvmrc in current directory or parent directories
  /// If not found, attempts to read from 'fvm flutter --version'
  static String? getFvmVersionFromSource() {
    try {
      // 1. Search for .fvmrc up the directory tree
      Directory current = Directory.current;
      while (true) {
        final File fvmrcFile = File(current.path + "/.fvmrc");
        if (fvmrcFile.existsSync()) {
          final Map<String, dynamic> json =
              jsonDecode(fvmrcFile.readAsStringSync());
          final version = json["flutter"];
          if (version != null) return version;
        }

        final parent = current.parent;
        if (parent.path == current.path) break; // Reached root
        current = parent;
      }

      // 2. Fallback: run 'fvm flutter --version' to get current FVM version
      final result = Process.runSync("fvm", ["flutter", "--version"],
          runInShell: true, includeParentEnvironment: true);
      if (result.exitCode == 0) {
        final String output = result.stdout.toString();
        // Regex to match "Flutter 3.16.0" or similar at the start
        final RegExp versionRegex = RegExp(r"Flutter\s+(\d+\.\d+\.\d+)");
        final match = versionRegex.firstMatch(output);
        if (match != null) {
          return match.group(1);
        }
      }
    } catch (error) {
      // Ignore errors reading .fvmrc or running command
    }
    return null;
  }

  /// Return if package identifier is a valid one or not, base on dart specifications
  bool hasValidPackageName() {
    if (name != null) {
      final match = Utils.identifierRegExp.matchAsPrefix(name!);
      return match != null && match.end == name!.length;
    }
    return false;
  }

  /// Returns Json-String formatted AppModel
  String _toJsonText() {
    final map = {
      "name": name,
      "organization": organization,
      "template": templateRepository,
      "useFvm": useFvm,
      "fvmVersion": fvmVersion,
    };

    return jsonEncode(map);
  }
}
