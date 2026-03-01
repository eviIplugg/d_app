part of 'generated.dart';

class GetRestaurantDetailsVariablesBuilder {
  String restaurantId;

  final FirebaseDataConnect _dataConnect;
  GetRestaurantDetailsVariablesBuilder(this._dataConnect, {required  this.restaurantId,});
  Deserializer<GetRestaurantDetailsData> dataDeserializer = (dynamic json)  => GetRestaurantDetailsData.fromJson(jsonDecode(json));
  Serializer<GetRestaurantDetailsVariables> varsSerializer = (GetRestaurantDetailsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetRestaurantDetailsData, GetRestaurantDetailsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetRestaurantDetailsData, GetRestaurantDetailsVariables> ref() {
    GetRestaurantDetailsVariables vars= GetRestaurantDetailsVariables(restaurantId: restaurantId,);
    return _dataConnect.query("GetRestaurantDetails", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetRestaurantDetailsRestaurant {
  final String id;
  final String name;
  final String address;
  final String cuisineType;
  final String? description;
  final String? website;
  final String? phoneNumber;
  final String? openingHours;
  final double? averageRating;
  final List<String>? photos;
  final String? menu;
  GetRestaurantDetailsRestaurant.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  address = nativeFromJson<String>(json['address']),
  cuisineType = nativeFromJson<String>(json['cuisineType']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']),
  website = json['website'] == null ? null : nativeFromJson<String>(json['website']),
  phoneNumber = json['phoneNumber'] == null ? null : nativeFromJson<String>(json['phoneNumber']),
  openingHours = json['openingHours'] == null ? null : nativeFromJson<String>(json['openingHours']),
  averageRating = json['averageRating'] == null ? null : nativeFromJson<double>(json['averageRating']),
  photos = json['photos'] == null ? null : (json['photos'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList(),
  menu = json['menu'] == null ? null : nativeFromJson<String>(json['menu']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRestaurantDetailsRestaurant otherTyped = other as GetRestaurantDetailsRestaurant;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    address == otherTyped.address && 
    cuisineType == otherTyped.cuisineType && 
    description == otherTyped.description && 
    website == otherTyped.website && 
    phoneNumber == otherTyped.phoneNumber && 
    openingHours == otherTyped.openingHours && 
    averageRating == otherTyped.averageRating && 
    photos == otherTyped.photos && 
    menu == otherTyped.menu;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, address.hashCode, cuisineType.hashCode, description.hashCode, website.hashCode, phoneNumber.hashCode, openingHours.hashCode, averageRating.hashCode, photos.hashCode, menu.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['address'] = nativeToJson<String>(address);
    json['cuisineType'] = nativeToJson<String>(cuisineType);
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    if (website != null) {
      json['website'] = nativeToJson<String?>(website);
    }
    if (phoneNumber != null) {
      json['phoneNumber'] = nativeToJson<String?>(phoneNumber);
    }
    if (openingHours != null) {
      json['openingHours'] = nativeToJson<String?>(openingHours);
    }
    if (averageRating != null) {
      json['averageRating'] = nativeToJson<double?>(averageRating);
    }
    if (photos != null) {
      json['photos'] = photos?.map((e) => nativeToJson<String>(e)).toList();
    }
    if (menu != null) {
      json['menu'] = nativeToJson<String?>(menu);
    }
    return json;
  }

  GetRestaurantDetailsRestaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.cuisineType,
    this.description,
    this.website,
    this.phoneNumber,
    this.openingHours,
    this.averageRating,
    this.photos,
    this.menu,
  });
}

@immutable
class GetRestaurantDetailsData {
  final GetRestaurantDetailsRestaurant? restaurant;
  GetRestaurantDetailsData.fromJson(dynamic json):
  
  restaurant = json['restaurant'] == null ? null : GetRestaurantDetailsRestaurant.fromJson(json['restaurant']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRestaurantDetailsData otherTyped = other as GetRestaurantDetailsData;
    return restaurant == otherTyped.restaurant;
    
  }
  @override
  int get hashCode => restaurant.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (restaurant != null) {
      json['restaurant'] = restaurant!.toJson();
    }
    return json;
  }

  GetRestaurantDetailsData({
    this.restaurant,
  });
}

@immutable
class GetRestaurantDetailsVariables {
  final String restaurantId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetRestaurantDetailsVariables.fromJson(Map<String, dynamic> json):
  
  restaurantId = nativeFromJson<String>(json['restaurantId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRestaurantDetailsVariables otherTyped = other as GetRestaurantDetailsVariables;
    return restaurantId == otherTyped.restaurantId;
    
  }
  @override
  int get hashCode => restaurantId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['restaurantId'] = nativeToJson<String>(restaurantId);
    return json;
  }

  GetRestaurantDetailsVariables({
    required this.restaurantId,
  });
}

