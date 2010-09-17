@interface OBAReportProblemWithTripV2 : NSObject {

}

@property (nonatomic,retain) NSString * tripId;
@property (nonatomic) long long serviceDate;
@property (nonatomic,retain) NSString * stopId;
@property (nonatomic,retain) NSString * data;
@property (nonatomic,retain) NSString * userComment;
@property (nonatomic) BOOL userOnVehicle;
@property (nonatomic,retain) NSString * userVehicleNumber;
@property (nonatomic,retain) CLLocation * userLocation;

@end