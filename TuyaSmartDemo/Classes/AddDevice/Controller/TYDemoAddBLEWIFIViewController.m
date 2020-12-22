//
//  TYDemoAddBLEWIFIViewController.m
//  TuyaSmartDemo
//
//  Created by huangkai on 2020/12/2.
//

#import "TYDemoAddBLEWIFIViewController.h"
#import <TuyaSmartBLEKit/TuyaSmartBLEKit.h>
#import "TYDemoAddDeviceUtils.h"
#import "TYDemoConfiguration.h"
#import <TuyaSmartActivatorKit/TuyaSmartActivatorKit.h>

@interface TYDemoAddBLEWIFIViewController () <TuyaSmartBLEManagerDelegate, TuyaSmartBLEWifiActivatorDelegate>

@property (nonatomic, strong) UILabel     *bleSingleUuidLabel;
@property (nonatomic, strong) UITextField *bleSingleUuidField;
@property (nonatomic, strong) UILabel     *consoleLabel;
@property (nonatomic, strong) UITextView  *consoleTextView;
@property (nonatomic, strong) UIButton    *scanButton;
@property (nonatomic, strong) UIButton    *stopScanButton;
@property (nonatomic, strong) UIAlertController *actionSheet;

@property (nonatomic, strong) UITextField *ssidField;
@property (nonatomic, strong) UITextField *passwordField;

//扫描到的蓝牙设备
@property (nonatomic, strong) NSMutableDictionary<NSString *,TYBLEAdvModel *> *uuidModelRelationDict;

@end

@implementation TYDemoAddBLEWIFIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initView];
}

- (void)initView {
    self.view.backgroundColor = [UIColor whiteColor];
    self.topBarView.leftItem = self.leftBackItem;
    self.centerTitleItem.title = @"Add BLE-WIFI Device";
    self.topBarView.centerItem = self.centerTitleItem;
    
    CGFloat currentY = self.topBarView.height;
    currentY += 10;
    
    //init ble name
    CGFloat labelWidth = 75;
    CGFloat textFieldWidth = APP_SCREEN_WIDTH - labelWidth - 30;
    CGFloat labelHeight = 44;
    
    UILabel *ssidKeyLabel = [sharedAddDeviceUtils() keyLabel];
    ssidKeyLabel.text = @"ssid:";
    ssidKeyLabel.frame = CGRectMake(10, currentY, labelWidth, labelHeight);
    [self.view addSubview:ssidKeyLabel];
    
    self.ssidField = [sharedAddDeviceUtils() textField];
    self.ssidField.placeholder = @"Input your wifi ssid";
    self.ssidField.frame = CGRectMake(labelWidth + 20, currentY, textFieldWidth, labelHeight);
    [self.view addSubview:self.ssidField];
    currentY += labelHeight;
    NSString *ssid = [TuyaSmartActivator currentWifiSSID];
    if (ssid.length) {
        self.ssidField.text = ssid;
    }
    //second line.
    currentY += 10;
    UILabel *passwordKeyLabel = [sharedAddDeviceUtils() keyLabel];
    passwordKeyLabel.text = @"password:";
    passwordKeyLabel.frame = CGRectMake(10, currentY, labelWidth, labelHeight);
    [self.view addSubview:passwordKeyLabel];
    
    self.passwordField = [sharedAddDeviceUtils() textField];
    self.passwordField.placeholder = @"password of wifi";
    self.passwordField.frame = CGRectMake(labelWidth + 20, currentY, textFieldWidth, labelHeight);
    [self.view addSubview:self.passwordField];
    currentY += labelHeight;
    
    self.bleSingleUuidLabel.frame = CGRectMake(10, currentY, labelWidth, labelHeight);
    [self.view addSubview:self.bleSingleUuidLabel];
    self.bleSingleUuidField.frame = CGRectMake(labelWidth + 20, currentY, textFieldWidth, labelHeight);
    [self.view addSubview:self.bleSingleUuidField];
    currentY += labelHeight;
    
    //init console
    currentY += 10;
    self.consoleLabel.frame = CGRectMake(10, currentY, labelWidth, labelHeight);
    [self.view addSubview:self.consoleLabel];
    currentY += labelHeight;
    self.consoleTextView.frame = CGRectMake(10, currentY, APP_SCREEN_WIDTH - 20, 220);
    [self.view addSubview:self.consoleTextView];
    currentY += self.consoleTextView.frame.size.height;
    
    //init button
    currentY += 10;
    self.scanButton.frame = CGRectMake(10, currentY, APP_SCREEN_WIDTH - 20, labelHeight);
    [self.view addSubview:self.scanButton];
    currentY += labelHeight;
    
    currentY += 10;
    self.stopScanButton.frame = CGRectMake(10, currentY, APP_SCREEN_WIDTH - 20, labelHeight);
    [self.view addSubview:self.stopScanButton];
    
}

- (void)appendConsoleLog:(NSString *)logString {
    if (!logString) {
        logString = [NSString stringWithFormat:@"%@ : param error",NSStringFromSelector(_cmd)];
    }
    NSString *result = self.consoleTextView.text?:@"";
    result = [[result stringByAppendingString:logString] stringByAppendingString:@"\n"];
    self.consoleTextView.text = result;
    [self.consoleTextView scrollRangeToVisible:NSMakeRange(result.length, 1)];
}

/// 扫描蓝牙设备
- (void)scanBleDeviceClick {
    //scan ble single device
    [TuyaSmartBLEManager sharedInstance].delegate = self;
    [self appendConsoleLog:@"start listening ..."];
    [[TuyaSmartBLEManager sharedInstance] startListening:YES];
    
}

/// 停止扫描蓝牙设备
- (void)stopScanBleDeviceClick {
    [self.uuidModelRelationDict removeAllObjects];
    [self appendConsoleLog:@"stop listening ..."];
    [[TuyaSmartBLEManager sharedInstance] stopListening:YES];
    
}

- (void)showAllBleDevice {
    WEAKSELF_AT
    if (self.actionSheet &&  [self.navigationController.visibleViewController isEqual:self.actionSheet]) {
        [self.actionSheet dismissViewControllerAnimated:YES completion:nil];
    }
    
    self.actionSheet = [UIAlertController alertControllerWithTitle:@"Select Ble Device" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [self.uuidModelRelationDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TYBLEAdvModel * _Nonnull obj, BOOL * _Nonnull stop) {
        TYBLEAdvModel *bleAdvModel = obj;
        UIAlertAction *action = [UIAlertAction actionWithTitle:bleAdvModel.uuid style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
              //select ble device
            [weakSelf_AT activeBLEWithSelectedAdvModel:bleAdvModel];
        }];
        [self.actionSheet addAction:action];
    }];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"取消配网" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf_AT.uuidModelRelationDict removeAllObjects];
        [[TuyaSmartBLEManager sharedInstance] stopListening:YES];
        
    }];
    [self.actionSheet addAction:action];
    [self presentViewController:self.actionSheet animated:YES completion:nil];
}


- (void)activeBLEWithSelectedAdvModel:(TYBLEAdvModel *)bleAdvModel {
    
//    if (self.ssidField.text.length == 0) {
//        [sharedAddDeviceUtils() alertMessage:TYSDKDemoLocalizedString(@"wifi_ssid_empty", @"")];
//        return;
//    }
    
    [self appendConsoleLog:[NSString stringWithFormat:@"selected ble device:%@",bleAdvModel.uuid]];
    self.bleSingleUuidField.text = bleAdvModel.uuid;
    id<TYDemoDeviceListModuleProtocol> impl = [[TYDemoConfiguration sharedInstance] serviceOfProtocol:@protocol(TYDemoDeviceListModuleProtocol)];
    long long homeId = [impl currentHomeId];
    
    TuyaSmartBLEWifiActivator.sharedInstance.bleWifiDelegate = self;
    [[TuyaSmartBLEWifiActivator sharedInstance] startConfigBLEWifiDeviceWithUUID:bleAdvModel.uuid
                                                                          homeId:homeId
                                                                       productId:bleAdvModel.productId
                                                                            ssid:@"3F-S-03-11"
                                                                        password:@"20112012pw"
                                                                         timeout:120
                                                                         success:^{
        
    } failure:^{
        
    }];
}


#pragma mark -- TuyaSmartBLEManager delegate

- (void)didDiscoveryDeviceWithDeviceInfo:(TYBLEAdvModel *)deviceInfo {
    
    if (deviceInfo.bleType == TYSmartBLETypeBLEWifi || deviceInfo.bleType == TYSmartBLETypeBLEWifiSecurity) {
        NSString *findDeviceStr = [NSString stringWithFormat:@"find ble device uuid:%@",deviceInfo.uuid];
        [self appendConsoleLog:findDeviceStr];
        [self.uuidModelRelationDict setValue:deviceInfo forKey:deviceInfo.uuid];
        [self showAllBleDevice];
    }
}

#pragma mark -- TuyaSmartBLEWifiActivator delegate

- (void)bleWifiActivator:(TuyaSmartBLEWifiActivator *)activator didReceiveBLEWifiConfigDevice:(TuyaSmartDeviceModel *)deviceModel error:(NSError *)error {
    
    if (!error) {
        //config network success
        [self appendConsoleLog:[NSString stringWithFormat:@"config network success with ble device name:%@",deviceModel.name]];
    }
     
}

#pragma mark -- setter and getter methods

- (UILabel *)consoleLabel {
    if (!_consoleLabel) {
        _consoleLabel = [sharedAddDeviceUtils() keyLabel];
        _consoleLabel.text = @"console:";
    }
    return _consoleLabel;
}

- (UITextView *)consoleTextView {
    if (!_consoleTextView) {
        _consoleTextView = [UITextView new];
        _consoleTextView.layer.borderColor = UIColor.blackColor.CGColor;
        _consoleTextView.layer.borderWidth = 1;
        _consoleTextView.editable = NO;
        _consoleTextView.layoutManager.allowsNonContiguousLayout = NO;
        _consoleTextView.backgroundColor = HEXCOLOR(0xededed);
    }
    return _consoleTextView;
}

- (UILabel *)bleSingleUuidLabel {
    if (!_bleSingleUuidLabel) {
        _bleSingleUuidLabel = [sharedAddDeviceUtils() keyLabel];
        _bleSingleUuidLabel.text = @"BLE uuid:";
    }
    return _bleSingleUuidLabel;
}

- (UITextField *)bleSingleUuidField {
    if (!_bleSingleUuidField) {
        _bleSingleUuidField = [sharedAddDeviceUtils() textField];
        _bleSingleUuidField.placeholder = @"BLE name cannot be entered";
        _bleSingleUuidField.enabled = NO;
    }
    return _bleSingleUuidField;
}

- (UIButton *)scanButton {
    if (!_scanButton) {
        _scanButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _scanButton.layer.cornerRadius = 5;
        [_scanButton setTitle:@"Scan ble device" forState:UIControlStateNormal];
        _scanButton.backgroundColor = UIColor.orangeColor;
        [_scanButton addTarget:self action:@selector(scanBleDeviceClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _scanButton;
}

- (UIButton *)stopScanButton {
    if (!_stopScanButton) {
        _stopScanButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _stopScanButton.layer.cornerRadius = 5;
        [_stopScanButton setTitle:@"Stop scan ble device" forState:UIControlStateNormal];
        _stopScanButton.backgroundColor = UIColor.orangeColor;
        [_stopScanButton addTarget:self action:@selector(stopScanBleDeviceClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stopScanButton;
}

- (NSMutableDictionary<NSString *,TYBLEAdvModel *> *)uuidModelRelationDict {
    if (!_uuidModelRelationDict) {
        _uuidModelRelationDict = [NSMutableDictionary dictionary];
    }
    return _uuidModelRelationDict;
}

@end
