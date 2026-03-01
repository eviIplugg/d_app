library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'get_my_profile.dart';

part 'update_my_profile.dart';

part 'get_restaurant_details.dart';

part 'create_booking.dart';







class ExampleConnector {
  
  
  GetMyProfileVariablesBuilder getMyProfile () {
    return GetMyProfileVariablesBuilder(dataConnect, );
  }
  
  
  UpdateMyProfileVariablesBuilder updateMyProfile () {
    return UpdateMyProfileVariablesBuilder(dataConnect, );
  }
  
  
  GetRestaurantDetailsVariablesBuilder getRestaurantDetails ({required String restaurantId, }) {
    return GetRestaurantDetailsVariablesBuilder(dataConnect, restaurantId: restaurantId,);
  }
  
  
  CreateBookingVariablesBuilder createBooking ({required String restaurantId, required DateTime bookingDate, required String bookingTime, required int numberOfGuests, }) {
    return CreateBookingVariablesBuilder(dataConnect, restaurantId: restaurantId,bookingDate: bookingDate,bookingTime: bookingTime,numberOfGuests: numberOfGuests,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'dapp',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
