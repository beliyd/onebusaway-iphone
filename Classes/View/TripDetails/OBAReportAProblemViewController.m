#import "OBAReportAProblemViewController.h"
#import "OBAUITableViewCell.h"
#import "OBAListSelectionViewController.h"
#import "OBATextEditViewController.h"
#import "OBALabelAndSwitchTableViewCell.h"
#import "OBALabelAndTextFieldTableViewCell.h"
#import "OBALogger.h"
#import "SBJSON.h"


typedef enum {
	OBASectionTypeNone,	
	OBASectionTypeProblem,
	OBASectionTypeComment,
	OBASectionTypeOnTheVehicle,
	OBASectionTypeSubmit
} OBASectionType;


@interface OBAReportAProblemViewController (Private)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;
- (NSUInteger) sectionIndexForType:(OBASectionType)type;

- (UITableViewCell*) tableView:(UITableView*)tableView vehicleCellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSString*) getVehicleTypeLabeForTripDetails:(OBATripDetailsV2*)tripDetails;

- (void) submit;
- (NSString*) getProblemAsData;

@end


@implementation OBAReportAProblemViewController

@synthesize currentStopId;

#pragma mark -
#pragma mark Initialization

- (id)initWithApplicationContext:(OBAApplicationContext*)context tripDetails:(OBATripDetailsV2*)tripDetails {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_appContext = [context retain];
		_tripDetails = [tripDetails retain];
		
		self.navigationItem.title = @"Report a Problem";

		UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithTitle:@"Custom Title"
										 style:UIBarButtonItemStyleBordered
										target:nil
										action:nil];
		self.navigationItem.backBarButtonItem = item;
		[item release];
		
		_vehicleNumber = @"0000";
		_vehicleType = [self getVehicleTypeLabeForTripDetails:tripDetails];
		
		NSMutableArray * problemNames = [[NSMutableArray alloc] init];
		[problemNames addObject:[NSString stringWithFormat:@"The %@ never came",_vehicleType]];
		[problemNames addObject:[NSString stringWithFormat:@"The %@ came early",_vehicleType]];
		[problemNames addObject:[NSString stringWithFormat:@"The %@ came late",_vehicleType]];
		[problemNames addObject:@"Wrong destination shown"];
		[problemNames addObject:@"Other"];
		_problemNames = [problemNames retain];
		[problemNames release];
		
		_progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];		
    }
    return self;
}

- (void)dealloc {
	[_appContext release];
	[_problemNames release];
	[_comment release];
	[_progressView release];
    [super dealloc];
}


#pragma mark UIViewController

-(void)viewDidLoad {
	self.navigationItem.backBarButtonItem.title = @"Problem";
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch (sectionType) {
		case OBASectionTypeProblem:
			return @"What's the problem?";
		case OBASectionTypeComment:
			return @"Optional - Comment:";
		case OBASectionTypeOnTheVehicle:
			return [NSString stringWithFormat:@"Optional - Are you on this %@?",_vehicleType];
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch( sectionType ) {
		case OBASectionTypeProblem:
			return 1;
		case OBASectionTypeComment:
			return 1;
		case OBASectionTypeOnTheVehicle:
			return 2;
		case OBASectionTypeSubmit:
			return 1;
		case OBASectionTypeNone:
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionTypeProblem: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];			
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = [_problemNames objectAtIndex:_problemIndex];
			return cell;			
		}
		case OBASectionTypeComment: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];			
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			if (_comment && [_comment length] > 0) {
				cell.textLabel.textColor = [UIColor blackColor];
				cell.textLabel.text = _comment;
			}
			else {
				cell.textLabel.textColor = [UIColor grayColor];
				cell.textLabel.text = @"Touch to edit";
			}
			
			return cell;
		}
		
		case OBASectionTypeOnTheVehicle:
			return [self tableView:tableView vehicleCellForRowAtIndexPath:indexPath];

		case OBASectionTypeSubmit: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];			
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.text = @"Submit";
			return cell;
		}
		default:	
			break;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	switch (sectionType) {
		case OBASectionTypeProblem: {
			NSIndexPath * selectedIndex = [NSIndexPath indexPathForRow:_problemIndex inSection:0];			
			OBAListSelectionViewController * vc = [[OBAListSelectionViewController alloc] initWithValues:_problemNames selectedIndex:selectedIndex];
			vc.target = self;
			vc.action = @selector(setProblem:);
			[self.navigationController pushViewController:vc animated:TRUE];
			[vc release];
			break;
		}
			
		case OBASectionTypeComment: {
			OBATextEditViewController * vc = [OBATextEditViewController pushOntoViewController:self withText:_comment withTitle:@"Comment"];
			vc.target = self;
			vc.action = @selector(setComment:);
			break;
		}
			
		case OBASectionTypeSubmit: {
			[self submit];
		}
			
		default:
			break;
	}
}


#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
	return YES;
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
	[self.navigationController popViewControllerAnimated:TRUE];
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
	[_progressView removeFromSuperview];
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
	OBALogSevereWithError(error,@"problem posting problem");
	[_progressView removeFromSuperview];
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
	[_progressView setProgress:progress];
}


#pragma mark Other methods

- (void) setProblem:(NSIndexPath*)indexPath {
	_problemIndex = indexPath.row;
	NSUInteger section = [self sectionIndexForType:OBASectionTypeProblem];
	NSIndexPath * p = [NSIndexPath indexPathForRow:0 inSection:section];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:p] withRowAnimation:UITableViewRowAnimationFade];
}

- (void) setComment:(NSString*)comment {
	_comment = [NSObject releaseOld:_comment retainNew:comment];
	NSUInteger section = [self sectionIndexForType:OBASectionTypeComment];
	NSIndexPath * p = [NSIndexPath indexPathForRow:0 inSection:section];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:p] withRowAnimation:UITableViewRowAnimationFade];
}

- (void) setOnVehicle:(id) obj {
	UISwitch * toggleSwitch = obj;
	_onVehicle = toggleSwitch.on;
}

- (void) setVehicleNumber:(id) obj {
	UITextField * textField = obj;	
	_vehicleNumber = [NSObject releaseOld:_vehicleNumber retainNew:[textField text]];
}

@end


@implementation OBAReportAProblemViewController (Private)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	switch (section) {
		case 0:
			return OBASectionTypeProblem;
		case 1:
			return OBASectionTypeComment;
		case 2:
			return OBASectionTypeOnTheVehicle;
		case 3:
			return OBASectionTypeSubmit;
		default:
			return OBASectionTypeNone;
	}
}

- (NSUInteger) sectionIndexForType:(OBASectionType)type {
	switch (type) {
		case OBASectionTypeProblem:
			return 0;
		case OBASectionTypeComment:
			return 1;
		case OBASectionTypeOnTheVehicle:
			return 2;
		case OBASectionTypeSubmit:
			return 3;
		case OBASectionTypeNone:
		default:
			break;
	}
	return -1;
}

- (UITableViewCell*) tableView:(UITableView*)tableView vehicleCellForRowAtIndexPath:(NSIndexPath *)indexPath {

	switch (indexPath.row) {
		case 0: {
			OBALabelAndSwitchTableViewCell * cell = [OBALabelAndSwitchTableViewCell getOrCreateCellForTableView:tableView];
			cell.label.text = [NSString stringWithFormat:@"On this %@?",[_vehicleType capitalizedString]];
			[cell.toggleSwitch setOn:_onVehicle];
			[cell.toggleSwitch addTarget:self action:@selector(setOnVehicle:) forControlEvents:UIControlEventValueChanged];
			return cell;
		}
		case 1: {
			OBALabelAndTextFieldTableViewCell * cell = [OBALabelAndTextFieldTableViewCell getOrCreateCellForTableView:tableView];
			cell.label.text = [NSString stringWithFormat:@"%@ Number",[_vehicleType capitalizedString]];
			
			cell.textField.text = _vehicleNumber;
			cell.textField.delegate = self;
			[cell.textField addTarget:self action:@selector(setVehicleNumber:) forControlEvents:UIControlEventEditingChanged];
			[cell setNeedsLayout];
			return cell;
		}
		default:
			break;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}

- (NSString*) getVehicleTypeLabeForTripDetails:(OBATripDetailsV2*)tripDetails {
	
	OBATripV2 * trip = tripDetails.trip;
	OBARouteV2 * route = trip.route;

	switch ([route.routeType intValue]) {
		case 0:
		case 1:
		case 2:
			return @"train";
		case 3:
			return @"bus";
		case 4:
			return @"ferry";
		default:
			return @"vehicle";
	}
}

- (void) submit {

	OBAReportProblemWithTripV2 * problem = [[OBAReportProblemWithTripV2 alloc] init];
	problem.tripId = _tripDetails.tripId;
	problem.serviceDate = _tripDetails.status.serviceDate;
	problem.stopId = self.currentStopId;
	problem.data = [self getProblemAsData];
	problem.userComment = _comment;
	problem.userOnVehicle = _onVehicle;
	problem.userVehicleNumber = _vehicleNumber;
	problem.userLocation = _appContext.locationManager.currentLocation;
	
	
	[self.view addSubview:_progressView];
	
	[_appContext.modelService reportProblemWithTrip:problem withDelegate:self withContext:nil];
	
	[problem release];
}

- (NSString*) getProblemAsData {

	NSMutableDictionary * p = [[NSMutableDictionary alloc] init];
	[p setObject:[_problemNames objectAtIndex:_problemIndex] forKey:@"text"];
	NSString * code = nil;
	
	switch (_problemIndex) {
		case 0:
			code = @"vehicle_never_came";
			break;
		case 1:
			code = @"vehicle_came_early";
			break;
		case 2:
			code = @"vehicle_came_late";
			break;
		case 3:
			code = @"wrong_headsign";
			break;
		default:
			code = @"other";
			break;
	}

	if (code)
		[p setObject:code forKey:@"code"];
	
	SBJSON * json = [[SBJSON alloc] init];
	NSString * v = [json stringWithObject:p];
	[json release];
	[p release];
	return v;	
}

@end