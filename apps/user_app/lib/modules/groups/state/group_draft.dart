import 'dart:typed_data';

import '../data/group_models.dart';

/// Data collected over the 3 create steps (Name & Photo -> Description -> Settings).
class GroupDraft {
  GroupDraft._();

  static GroupDraft current = GroupDraft._();

  String name = '';
  Uint8List? photoBytes;
  String? photoName;
  String? avatarUrl; // set once the photo is uploaded
  String description = '';
  String category = 'Business';
  String rules = '';
  GroupSettings settings = GroupSettings();

  static void reset() => current = GroupDraft._();
}
