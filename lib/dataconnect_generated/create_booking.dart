part of 'generated.dart';

class CreateBookingVariablesBuilder {
  String restaurantId;
  DateTime bookingDate;
  String bookingTime;
  int numberOfGuests;
  Optional<String> _specialRequests = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreateBookingVariablesBuilder specialRequests(String? t) {
   _specialRequests.value = t;
   return this;
  }

  CreateBookingVariablesBuilder(this._dataConnect, {required  this.restaurantId,required  this.bookingDate,required  this.bookingTime,required  this.numberOfGuests,});
  Deserializer<CreateBookingData> dataDeserializer = (dynamic json)  => CreateBookingData.fromJson(jsonDecode(json));
  Serializer<CreateBookingVariables> varsSerializer = (CreateBookingVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateBookingData, CreateBookingVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateBookingData, CreateBookingVariables> ref() {
    CreateBookingVariables vars= CreateBookingVariables(restaurantId: restaurantId,bookingDate: bookingDate,bookingTime: bookingTime,numberOfGuests: numberOfGuests,specialRequests: _specialRequests,);
    return _dataConnect.mutation("CreateBooking", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateBookingBookingInsert {
  final String id;
  CreateBookingBookingInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBookingBookingInsert otherTyped = other as CreateBookingBookingInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateBookingBookingInsert({
    required this.id,
  });
}

@immutable
class CreateBookingData {
  final CreateBookingBookingInsert booking_insert;
  CreateBookingData.fromJson(dynamic json):
  
  booking_insert = CreateBookingBookingInsert.fromJson(json['booking_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBookingData otherTyped = other as CreateBookingData;
    return booking_insert == otherTyped.booking_insert;
    
  }
  @override
  int get hashCode => booking_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['booking_insert'] = booking_insert.toJson();
    return json;
  }

  CreateBookingData({
    required this.booking_insert,
  });
}

@immutable
class CreateBookingVariables {
  final String restaurantId;
  final DateTime bookingDate;
  final String bookingTime;
  final int numberOfGuests;
  late final Optional<String>specialRequests;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateBookingVariables.fromJson(Map<String, dynamic> json):
  
  restaurantId = nativeFromJson<String>(json['restaurantId']),
  bookingDate = nativeFromJson<DateTime>(json['bookingDate']),
  bookingTime = nativeFromJson<String>(json['bookingTime']),
  numberOfGuests = nativeFromJson<int>(json['numberOfGuests']) {
  
  
  
  
  
  
    specialRequests = Optional.optional(nativeFromJson, nativeToJson);
    specialRequests.value = json['specialRequests'] == null ? null : nativeFromJson<String>(json['specialRequests']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBookingVariables otherTyped = other as CreateBookingVariables;
    return restaurantId == otherTyped.restaurantId && 
    bookingDate == otherTyped.bookingDate && 
    bookingTime == otherTyped.bookingTime && 
    numberOfGuests == otherTyped.numberOfGuests && 
    specialRequests == otherTyped.specialRequests;
    
  }
  @override
  int get hashCode => Object.hashAll([restaurantId.hashCode, bookingDate.hashCode, bookingTime.hashCode, numberOfGuests.hashCode, specialRequests.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['restaurantId'] = nativeToJson<String>(restaurantId);
    json['bookingDate'] = nativeToJson<DateTime>(bookingDate);
    json['bookingTime'] = nativeToJson<String>(bookingTime);
    json['numberOfGuests'] = nativeToJson<int>(numberOfGuests);
    if(specialRequests.state == OptionalState.set) {
      json['specialRequests'] = specialRequests.toJson();
    }
    return json;
  }

  CreateBookingVariables({
    required this.restaurantId,
    required this.bookingDate,
    required this.bookingTime,
    required this.numberOfGuests,
    required this.specialRequests,
  });
}

