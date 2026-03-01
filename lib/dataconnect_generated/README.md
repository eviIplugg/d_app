# dataconnect_generated SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
ExampleConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetMyProfile
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.getMyProfile().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyProfileData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getMyProfile();
GetMyProfileData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.getMyProfile().ref();
ref.execute();

ref.subscribe(...);
```


### GetRestaurantDetails
#### Required Arguments
```dart
String restaurantId = ...;
ExampleConnector.instance.getRestaurantDetails(
  restaurantId: restaurantId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetRestaurantDetailsData, GetRestaurantDetailsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getRestaurantDetails(
  restaurantId: restaurantId,
);
GetRestaurantDetailsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String restaurantId = ...;

final ref = ExampleConnector.instance.getRestaurantDetails(
  restaurantId: restaurantId,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### UpdateMyProfile
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.updateMyProfile().execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateMyProfile, we created `UpdateMyProfileBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateMyProfileVariablesBuilder {
  ...
 
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

  ...
}
ExampleConnector.instance.updateMyProfile()
.displayName(displayName)
.bio(bio)
.profilePictureUrl(profilePictureUrl)
.preferredCuisines(preferredCuisines)
.diningPreferences(diningPreferences)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateMyProfileData, UpdateMyProfileVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateMyProfile();
UpdateMyProfileData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.updateMyProfile().ref();
ref.execute();
```


### CreateBooking
#### Required Arguments
```dart
String restaurantId = ...;
DateTime bookingDate = ...;
String bookingTime = ...;
int numberOfGuests = ...;
ExampleConnector.instance.createBooking(
  restaurantId: restaurantId,
  bookingDate: bookingDate,
  bookingTime: bookingTime,
  numberOfGuests: numberOfGuests,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateBooking, we created `CreateBookingBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateBookingVariablesBuilder {
  ...
   CreateBookingVariablesBuilder specialRequests(String? t) {
   _specialRequests.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.createBooking(
  restaurantId: restaurantId,
  bookingDate: bookingDate,
  bookingTime: bookingTime,
  numberOfGuests: numberOfGuests,
)
.specialRequests(specialRequests)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateBookingData, CreateBookingVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createBooking(
  restaurantId: restaurantId,
  bookingDate: bookingDate,
  bookingTime: bookingTime,
  numberOfGuests: numberOfGuests,
);
CreateBookingData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String restaurantId = ...;
DateTime bookingDate = ...;
String bookingTime = ...;
int numberOfGuests = ...;

final ref = ExampleConnector.instance.createBooking(
  restaurantId: restaurantId,
  bookingDate: bookingDate,
  bookingTime: bookingTime,
  numberOfGuests: numberOfGuests,
).ref();
ref.execute();
```

