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

  /// Read FVM version from .fvmrc in current directory
  static String? getFvmVersionFromSource() {
    try {
      final File fvmrcFile = File(".fvmrc");
      if (fvmrcFile.existsSync()) {
        final Map<String, dynamic> json =
            jsonDecode(fvmrcFile.readAsStringSync());
        return json["flutter"];
      }
    } catch (error) {
      // Ignore errors reading .fvmrc
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
