//
//  AppDelegate.m
//  Proxy
//
//  Created by gao on 2020/2/28.
//  Copyright © 2020 Gao. All rights reserved.
//

#import "AppDelegate.h"
#import "STPrivilegedTask.h"

@interface AppDelegate ()

@property (nonatomic,strong) NSStatusItem *statusItem; //必须应用、且强引用，否则不会显示。

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
        
    NSStatusItem *statusItem = [statusBar statusItemWithLength: NSSquareStatusItemLength];
    [statusItem setHighlightMode:YES];
    [statusItem.button setImage: [NSImage imageNamed:@"abc"]]; //设置图标，请注意尺寸
    [statusItem.button setToolTip:@"代理切换"];
    
    NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"Load_TEXT"];
    [subMenu addItemWithTitle:@"打开"action:@selector(clickItem1) keyEquivalent:@"E"];
    [subMenu addItemWithTitle:@"关闭"action:@selector(clickItem2) keyEquivalent:@"R"];
    [subMenu addItemWithTitle:@"退出"action:@selector(clickItem3) keyEquivalent:@"F"];
    statusItem.menu = subMenu;
    
    self.statusItem = statusItem;
}

- (void)clickItem1{
    [self runNSTaskCmd:@"/usr/sbin/networksetup -setautoproxystate Wi-Fi on"];
    [self runNSTaskCmd:@"/usr/sbin/networksetup -setautoproxyurl Wi-Fi http://www.baidu.com/"];
//    system(@"sudo networksetup -setautoproxystate Wi-Fi on".UTF8String);//无效只能运行非root命令
}

- (void)clickItem2{
    [self runNSTaskCmd:@"/usr/sbin/networksetup -setautoproxystate Wi-Fi off"];
}

- (void)clickItem3 {
    exit(0);
}

- (void)runPrivilegedTask:(NSString*) cmdStr{
    STPrivilegedTask *privilegedTask = [[STPrivilegedTask alloc] init];
    
    NSMutableArray *components = [[cmdStr componentsSeparatedByString:@" "] mutableCopy];
    NSString *launchPath = components[0];
    [components removeObjectAtIndex:0];
    
    [privilegedTask setLaunchPath:launchPath];
    [privilegedTask setArguments:components];
    [privilegedTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    
    //set it off
    OSStatus err = [privilegedTask launch];
    if (err != errAuthorizationSuccess) {
        if (err == errAuthorizationCanceled) {
            NSLog(@"User cancelled");
            return;
        }  else {
            NSLog(@"Something went wrong: %d", (int)err);
            // For error codes, see http://www.opensource.apple.com/source/libsecurity_authorization/libsecurity_authorization-36329/lib/Authorization.h
        }
    }
    
    [privilegedTask waitUntilExit];
}

- (NSString *)runNSTaskCmd:(NSString *)cmd
{
    NSMutableArray *components = [[cmd componentsSeparatedByString:@" "] mutableCopy];
    NSString *launchPath = components[0];
    [components removeObjectAtIndex:0];
    
    // 初始化并设置shell路径
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: launchPath];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSArray *arguments = components;
    [task setArguments: arguments];
    
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    // 开始task
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    
    // 获取运行结果
    NSData *data = [file readDataToEndOfFile];
    return [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
