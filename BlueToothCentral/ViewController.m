//
//  ViewController.m
//  BlueToothCentral
//
//  Created by Mac1 on 2018/6/25.
//  Copyright © 2018年 Mac1. All rights reserved.
//

/**
 蓝牙4.0，低功耗蓝牙设备
 中心设备主要流程：
 1、创建中心设备管理
 2、通过管理类判断蓝牙状态
 3、蓝牙状态可用时，通过服务ID扫描周边设备
 4、发现符合要求的设备后进行连接
 5、连接成功后外设通过服务ID寻找服务
 6、找到服务后外设通过服务和相对应的特征ID寻找服务中的特征
 7、找到特征后就可以就不同的特征进行相应的数据操作，如果设备中心要写数据到外设，外设要用不同的特征订阅相应的通知
 */

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define SERVICE_UUID @"1211"
#define CHARACTERISTIC_UUID @"0551"
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

typedef NS_ENUM(NSInteger, ManagerState) {//蓝牙状态
    ManagerStateUnknown = 0,
    ManagerStateResetting,
    ManagerStateUnsupported,
    ManagerStateUnauthorized,
    ManagerStatePoweredOff,
    ManagerStatePoweredOn,
};

@interface ViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;//中心设备管理类
@property (nonatomic, strong) CBPeripheral *peripheral;//外设
@property (nonatomic, strong) CBCharacteristic *characteristic;//特征
@property (nonatomic, strong) UITextField *inputTextField;//输入框
@property (nonatomic, strong) UIButton *getButton;//获取数据按钮
@property (nonatomic, strong) UIButton *postButton;//写入数据按钮

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"设备中心";
    self.inputTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 100, SCREEN_WIDTH - 40, 30)];
    self.inputTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.inputTextField.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.inputTextField];
    
    self.getButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.getButton.frame = CGRectMake(SCREEN_WIDTH * 0.5 - 100, 180, 60, 30);
    [self.getButton setTitle:@"Get" forState:UIControlStateNormal];
    [self.getButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.getButton.backgroundColor = [UIColor redColor];
    self.getButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.getButton addTarget:self action:@selector(readValue) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.getButton];
    
    self.postButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.postButton.frame = CGRectMake(SCREEN_WIDTH * 0.5 + 40, 180, 60, 30);
    [self.postButton setTitle:@"Post" forState:UIControlStateNormal];
    [self.postButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.postButton.backgroundColor = [UIColor redColor];
    self.postButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.postButton addTarget:self action:@selector(writeValue) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.postButton];
    
    //创建中心设备管理类，会回调centralManagerDidUpdateState方法
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
}

/** 判断蓝牙状态
 CBManagerStateUnknown = 0,  未知
 CBManagerStateResetting,    重置中
 CBManagerStateUnsupported,  不支持
 CBManagerStateUnauthorized, 未授权
 CBManagerStatePoweredOff,   未启动
 CBManagerStatePoweredOn,    可用
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (@available(iOS 10.0, *)) {
        if (central.state == CBManagerStatePoweredOn) {
            //蓝牙可用
            //根据SERVICE_UUID来扫描外设，如果不设置SERVICE_UUID，则扫描所有设备
            [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]] options:nil];
        }
        if (central.state == CBManagerStatePoweredOff) {
            NSLog(@"蓝牙关闭");
        }
        if (central.state == CBManagerStateUnsupported) {
            NSLog(@"该设备不支持蓝牙");
        }
    } else {
        if (central.state == ManagerStatePoweredOn) {
            //蓝牙可用
            //根据SERVICE_UUID来扫描外设，如果不设置SERVICE_UUID，则扫描所有设备
            [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]] options:nil];
        }
        if (central.state == ManagerStatePoweredOff) {
            NSLog(@"蓝牙关闭");
        }
        if (central.state == ManagerStateUnsupported) {
            NSLog(@"该设备不支持蓝牙");
        }
    }
}

//发现符合要求的外设，回调
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    /**
     d = 10^((abs(rssi) - A) / (10 * n))
     其中：
     d - 计算所得距离(单位：m)
     rssi - 接收信号强度
     A - 发射端和接收端相隔1米时的信号强度
     n - 环境衰减因子
     */
    
    self.peripheral = peripheral;
    //可根据外设名字来过滤外设,然后连接相对应的外设
//    if ([peripheral.name hasPrefix:@"CN"]) {
//        [central connectPeripheral:peripheral options:nil];
//    }
    //连接外设
    [central connectPeripheral:peripheral options:nil];
    //检索已经被连接的外设,会返回一个 CBPeripheral的数组
//    NSArray *peripherals = [self.centralManager retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
}

//连接成功的回调
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    //连接成功，停止扫描
    [self.centralManager stopScan];
    //设置代理
    peripheral.delegate = self;
    //根据UUID来寻找服务
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
}

//连接失败的回调
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"连接失败");
}

//断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"断开连接");
    //可进行重连
    [central connectPeripheral:peripheral options:nil];
}

//发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    //遍历外设中所有的服务
    for (CBService *service in peripheral.services) {
        NSLog(@"%@",service);
    }
    //这里由于只有一个服务，所以直接取，实际开发中可能不止一个，可通过上面的遍历获取
    CBService *service = peripheral.services.lastObject;
    //根据UUID寻找服务中的特征
    [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_UUID]] forService:service];
}

//发现特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    //遍历服务中的所有特征
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"%@",characteristic);
        //characteristic 访问权限
        //characteristic.properties
        //从外设开发人员（硬件工程师、或嵌入式开发人员）那拿到不同特征的UUID，不同的特征处理不同的事情
    }
    //由于这里只有一个特征，所以直接取
    self.characteristic = service.characteristics.lastObject;
    //直接读取这个特征的数据,会调用didUpdateValueForCharacteristic
    [peripheral readValueForCharacteristic:self.characteristic];
    //订阅通知
    [peripheral setNotifyValue:YES forCharacteristic:self.characteristic];
}

//接收到外设数据回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSData *data = characteristic.value;
    self.inputTextField.text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

//订阅状态的改变
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"订阅失败:%@",error);
    }
    if (characteristic.isNotifying) {
        NSLog(@"订阅成功");
    }else {
        NSLog(@"取消订阅");
    }
}

//写入数据回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"写入成功");
}

//读取数据
- (void)readValue {
    if (self.peripheral && self.characteristic) {
        [self.peripheral readValueForCharacteristic:self.characteristic];
    }
}

//写入数据
- (void)writeValue {
    if (self.inputTextField.text.length) {
        if (self.peripheral && self.characteristic) {
            NSData *data = [self.inputTextField.text dataUsingEncoding:NSUTF8StringEncoding];
            [self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
        }
    }else {
        NSLog(@"请输入要写入的内容");
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
