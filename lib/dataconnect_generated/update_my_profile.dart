part of 'generated.dart';

class UpdateMyProfileVariablesBuilder {
  Optional<String> _displayName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _bio = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _profilePictureUrl = Optional.optional(nativeFromJson, nativeToJson);
  Optional<List<String>> _preferredCuisines = Optional.optional(listDeserializer(nativeFromJson), listSerializer(nativeToJson));
  Optional<String> _diningPreferences = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  UpdateMyProfileVariablesBuilder displayName(String? t) {
   _displayName.value = t;
   return this;
  }
  UpdateMyProfileVariablesBuilder bio(String? t) {
   _bio.value = t;
   return this;
  }
  UpdateMyProfileVariablesBuilder profilePictureUrl(String? t) {
   _profilePictureUrl.value = t;
   return this;
  }
  UpdateMyProfileVariablesBuilder preferredCuisines(List<String>? t) {
   _preferredCuisines.value = t;
   return this;
  }
  UpdateMyProfileVariablesBuilder diningPreferences(String? t) {
   _diningPreferences.value = t;
   return this;
  }

  UpdateMyProfileVariablesBuilder(this._dataConnect, );
  Deserializer<UpdateMyProfileData> dataDeserializer = (dynamic json)  => UpdateMyProfileData.fromJson(jsonDecode(json));
  Serializer<UpdateMyProfileVariables> varsSerializer = (UpdateMyProfileVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateMyProfileData, UpdateMyProfileVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateMyProfileData, UpdateMyProfileVariables> ref() {
    UpdateMyProfileVariables vars= UpdateMyProfileVariables(displayName: _displayName,bio: _bio,profilePictureUrl: _profilePictureUrl,preferredCuisines: _preferredCuisines,diningPreferences: _diningPreferences,);
    return _dataConnect.mutation("UpdateMyProfile", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateMyProfileUserUpdate {
  final String id;
  UpdateMyProfileUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMyProfileUserUpdate otherTyped = other as UpdateMyProfileUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateMyProfileUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateMyProfileData {
  final UpdateMyProfileUserUpdate? user_update;
  UpdateMyProfileData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateMyProfileUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMyProfileData otherTyped = other as UpdateMyProfileData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateMyProfileData({
    this.user_update,
  });
}

@immutable
class UpdateMyProfileVariables {
  late final Optional<String>displayName;
  late final Optional<String>bio;
  late final Optional<String>profilePictureUrl;
  late final Optional<List<String>>preferredCuisines;
  late final Optional<String>diningPreferences;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateMyProfileVariables.fromJson(Map<String, dynamic> json) {
  
  
    displayName = Optional.optional(nativeFromJson, nativeToJson);
    displayName.value = json['displayName'] == null ? null : nativeFromJson<String>(json['displayName']);
  
  
    bio = Optional.optional(nativeFromJson, nativeToJson);
    bio.value = json['bio'] == null ? null : nativeFromJson<String>(json['bio']);
  
  
    profilePictureUrl = Optional.optional(nativeFromJson, nativeToJson);
    profilePictureUrl.value = json['profilePictureUrl'] == null ? null : nativeFromJson<String>(json['profilePictureUrl']);
  
  
    preferredCuisines = Optional.optional(listDeserializer(nativeFromJson), listSerializer(nativeToJson));
    preferredCuisines.value = json['preferredCuisines'] == null ? null : (json['preferredCuisines'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList();
  
  
    diningPreferences = Optional.optional(nativeFromJson, nativeToJson);
    diningPreferences.value = json['diningPreferences'] == null ? null : nativeFromJson<String>(json['diningPreferences']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMyProfileVariables otherTyped = other as UpdateMyProfileVariables;
    return displayName == otherTyped.displayName && 
    bio == otherTyped.bio && 
    profilePictureUrl == otherTyped.profilePictureUrl && 
    preferredCuisines == otherTyped.preferredCuisines && 
    diningPreferences == otherTyped.diningPreferences;
    
  }
  @override
  int get hashCode => Object.hashAll([displayName.hashCode, bio.hashCode, profilePictureUrl.hashCode, preferredCuisines.hashCode, diningPreferences.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(displayName.state == OptionalState.set) {
      json['displayName'] = displayName.toJson();
    }
    if(bio.state == OptionalState.set) {
      json['bio'] = bio.toJson();
    }
    if(profilePictureUrl.state == OptionalState.set) {
      json['profilePictureUrl'] = profilePictureUrl.toJson();
    }
    if(preferredCuisines.state == OptionalState.set) {
      json['preferredCuisines'] = preferredCuisines.toJson();
    }
    if(diningPreferences.state == OptionalState.set) {
      json['diningPreferences'] = diningPreferences.toJson();
    }
    return json;
  }

  UpdateMyProfileVariables({
    required this.displayName,
    required this.bio,
    required this.profilePictureUrl,
    required this.preferredCuisines,
    required this.diningPreferences,
  });
}

