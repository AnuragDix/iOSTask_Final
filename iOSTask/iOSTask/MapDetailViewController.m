//
//  MapDetailViewController.m
//  iOSTask
//
//  Created by Anurag Dixit on 12/16/15.
//  Copyright (c) 2015 mobility2. All rights reserved.
//

#import "MapDetailViewController.h"
#import "WebServiceInterface.h"
#import "AsynImageDownloader.h"
#import "MMDrawerBarButtonItem.h"
#import "UIViewController+MMDrawerController.h"
#import "CoreDataOperations.h"
#import "MapViewController.h"
#import "UIManager.h"
#import "MBProgressHUD.h"
@interface MapDetailViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImage *imgPhoto;
@property (strong, nonatomic) IBOutlet UIImageView *imgView;
@property (strong, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UIButton *btnFavourites;
@property (strong, nonatomic) IBOutlet UILabel *lblVicinity;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ImgViewHeight;

@end

@implementation MapDetailViewController
MBProgressHUD *progressHUD;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = LIGHT_GREY_COLOR;
    self.title = @"Details";
    if ([self.place.fromView isEqualToString:@"Fav"] || [[CoreDataOperations sharedCoreDataOperations] isExistPlace:self.place.name]) {
        [self.btnFavourites setTitle:@"Delete" forState:UIControlStateNormal];
        [self.btnFavourites setBackgroundColor:[UIColor orangeColor]];
    }else{
        [self.btnFavourites setTitle:@"Favourites" forState:UIControlStateNormal];
        [self.btnFavourites setBackgroundColor:[UIColor whiteColor]];
    }
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTitleTextAttributes:
     @{NSFontAttributeName:[UIFont fontWithName:FONT_NAVIGATIONBAR size:18.0]
       }forState:UIControlStateNormal];
    
    //building the whole UI
    self.imgPhoto = nil;
   
    NSString *strImageURL = [NSString stringWithFormat:@"%@%@&key=%@",kMapBaseURL,self.place.photoReference,GOOGLE_API_KEY];
    
    //Async download large image -
    AsynImageDownloader *async = [AsynImageDownloader new];
    async.strName = self.place.name;
    async.topDelegate = self;
    //if image is not cache in directory then it will download from server
    if (![async isExistFile:strImageURL] && self.place.photoReference != nil) {
        if ([UIManager isOnline]) {
            progressHUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
            progressHUD.dimBackground = YES;
            progressHUD.labelText = @"Downloading Image";
            progressHUD.userInteractionEnabled = YES;
           
            [async downloadImage:strImageURL];
        }
    }else {
        //if photoReference is not available it means image is not on server so we are hiding image view from view
        if (self.place.photoReference == nil) {
            self.ImgViewHeight.constant = 0;
        }
        //if image is cached then directly fetch it from dir
        self.imgPhoto = [async getImageFromName:strImageURL];
        self.imgView.image = self.imgPhoto;
        [[BusyView defaultAgent] removeBusyView];
    }
    
    self.lblName.text = self.place.name;
    self.lblVicinity.text = self.place.vicinity;
    
}

//this method is delegate method of asycn class
-(void)didImageDowloaded:(UIImage *)_image{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imgPhoto  = _image;
        self.imgView.image = self.imgPhoto;
        [progressHUD hide:YES];
    });
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //calling nnotification for updating list view
    if ([self.place.fromView isEqualToString:@"Fav"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kEventNotification object:nil];
    }
}

#pragma mark IBAction methods
- (IBAction)doNavigateMap:(id)sender {
    [self performSegueWithIdentifier:@"MapViewSegue" sender:self];
}
//this method is used to mark as fav 
-(IBAction)doMarkFavourits:(id)sender {
  
    if ([[CoreDataOperations sharedCoreDataOperations] isExistPlace:self.place.name]) {
        [[CoreDataOperations sharedCoreDataOperations] deletePlace:self.place.name];
        [self.btnFavourites setTitle:@"Favourites" forState:UIControlStateNormal];
        [self.btnFavourites setBackgroundColor:[UIColor whiteColor]];
    }else{
        [[CoreDataOperations sharedCoreDataOperations] doSavePlaceObject:self.place];
        [self.btnFavourites setTitle:@"Delete" forState:UIControlStateNormal];
        [self.btnFavourites setBackgroundColor:[UIColor orangeColor]];
       
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    MapViewController* controller =  (MapViewController *) [segue destinationViewController];
    controller.place = self.place;
}



@end
