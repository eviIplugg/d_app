part of 'generated.dart';

class GetMyProfileVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetMyProfileVariablesBuilder(this._dataConnect, );
  Deserializer<GetMyProfileData> dataDeserializer = (dynamic json)  => GetMyProfileData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetMyProfileData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyProfileData, void> ref() {
    
    return _dataConnect.query("GetMyProfile", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetMyProfileUser {
  final String id;
  final String username;
  final String? displayName;
  final String? profilePictureUrl;
  final String? bio;
  final List<String>? preferredCuisines;
  final String? diningPreferences;
  GetMyProfileUser.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  username = nativeFromJson<String>(json['username']),
  displayName = json['displayName'] == null ? null : nativeFromJson<String>(json['displayName']),
  profilePictureUrl = json['profilePictureUrl'] == null ? null : nativeFromJson<String>(json['profilePictureUrl']),
  bio = json['bio'] == null ? null : nativeFromJson<String>(json['bio']),
  preferredCuisines = json['preferredCuisines'] == null ? null : (json['preferredCuisines'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList(),
  diningPreferences = json['diningPreferences'] == null ? null : nativeFromJson<String>(json['diningPreferences']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyProfileUser otherTyped = other as GetMyProfileUser;
    return id == otherTyped.id && 
    username == otherTyped.username && 
    displayName == otherTyped.displayName && 
    profilePictureUrl == otherTyped.profilePictureUrl && 
    bio == otherTyped.bio && 
    preferredCuisines == otherTyped.preferredCuisines && 
    diningPreferences == otherTyped.diningPreferences;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, username.hashCode, displayName.hashCode, profilePictureUrl.hashCode, bio.hashCode, preferredCuisines.hashCode, diningPreferences.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['username'] = nativeToJson<String>(username);
    if (displayName != null) {
      json['displayName'] = nativeToJson<String?>(displayName);
    }
    if (profilePictureUrl != null) {
      json['profilePictureUrl'] = nativeToJson<String?>(profilePictureUrl);
    }
    if (bio != null) {
      json['bio'] = nativeToJson<String?>(bio);
    }
    if (preferredCuisines != null) {
      json['preferredCuisines'] = preferredCuisines?.map((e) => nativeToJson<String>(e)).toList();
    }
    if (diningPreferences != null) {
      json['diningPreferences'] = nativeToJson<String?>(diningPreferences);
    }
    return json;
  }

  GetMyProfileUser({
    required this.id,
    required this.username,
    this.displayName,
    this.profilePictureUrl,
    this.bio,
    this.preferredCuisines,
    this.diningPreferences,
  });
}

@immutable
class GetMyProfileData {
  final GetMyProfileUser? user;
  GetMyProfileData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetMyProfileUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyProfileData otherTyped = other as GetMyProfileData;
    return user == otherTyped.user;
    
  }
  @override
  int get hashCode => user.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null) {
      json['user'] = user!.toJson();
    }
    return json;
  }

  GetMyProfileData({
    this.user,
  });
}

