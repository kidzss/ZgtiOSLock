//
//  ViewController.m
//  ZgtiOSLock
//
//  Created by gtzhou on 2019/5/2.
//  Copyright © 2019 xyz. All rights reserved.
//
#import <os/lock.h>
#import <libkern/OSAtomic.h>
#import "ViewController.h"
#import <pthread.h>

@interface ViewController ()
{
    OSSpinLock spinlock;
    os_unfair_lock_t unfairLock;
    __block NSInteger number;
    dispatch_queue_t diapatchQueue;
    CFTimeInterval end;
    CFTimeInterval begin;
    dispatch_semaphore_t semaphore;
    
    __block pthread_mutex_t mutex;
    NSLock *lock;
    NSRecursiveLock *recursiveLock;
    NSConditionLock *conditionLock;// = [[NSConditionLock alloc] init];
    float timerGap;// = 5.0f
    NSArray *testFuncArr;
    NSUInteger customer;
    float gap;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"iOS Lock";
    spinlock = OS_SPINLOCK_INIT;
    diapatchQueue = dispatch_queue_create("com.testiOSLock.queue", DISPATCH_QUEUE_CONCURRENT);
    timerGap= 5.0f;
    gap = 60;
    
    unfairLock = &(OS_UNFAIR_LOCK_INIT);
    semaphore = dispatch_semaphore_create(1);
    
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);  // 定义锁的属性
    
    pthread_mutex_init(&mutex, &attr); // 创建锁
    lock = [[NSLock alloc] init];
    recursiveLock = [[NSRecursiveLock alloc] init];
    conditionLock = [[NSConditionLock alloc] init];
    testFuncArr = @[@"testSpinlock",@"testSemaphore",@"testMutex",@"testNSLock",@"testRecursiveLock",@"testConditionLock",@"testSynchronized"];
}

- (void)numberReset {
    customer = 100000;
    number = 99000;
    begin = 0.0;
    end = 0.0;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self autoTest];
}

- (float)theTimeGap {
    timerGap = timerGap + gap;
    return timerGap;
}

- (void)autoTest {
    NSUInteger count = testFuncArr.count;
    for (int i=0; i<count; i++) {
        NSTimer*timer = [NSTimer timerWithTimeInterval:[self theTimeGap] target:self selector:NSSelectorFromString(testFuncArr[i]) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
}

- (void)testSpinlock {
    [self numberReset];
    begin = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < customer; i++) {
        if (number > 0) {
            dispatch_async(diapatchQueue, ^{
                [self sellTicketSpinlock];
            });
        }
    }
}

- (void)sellTicketSpinlock {
    OSSpinLockLock(&spinlock);
    if(number == 0) {
        end = CFAbsoluteTimeGetCurrent();
        NSLog(@"Spinlock test result %f",end - begin);
        //Spinlock test result 0.016475
    }
    number--;
    OSSpinLockUnlock(&spinlock);
}

- (void)testSemaphore {
    [self numberReset];
    begin = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < customer; i++) {
        if (number > 0) {
            dispatch_async(diapatchQueue, ^{
                [self sellTicketSemaphore];
            });
        }
    }
}

- (void)sellTicketSemaphore {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if(number == 0) {
        end = CFAbsoluteTimeGetCurrent();
        NSLog(@"Semaphore test result %f",end - begin);
        //Semaphore test result 0.014200
    }
    number--;
    dispatch_semaphore_signal(semaphore);
}

- (void)testMutex {
    [self numberReset];
    begin = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < customer; i++) {
        if (number>0) {
            dispatch_async(diapatchQueue, ^{
                [self sellTicketMutex];
            });
        }
    }
}

- (void)sellTicketMutex {
    pthread_mutex_lock(&mutex);
    if(number == 0) {
        end = CFAbsoluteTimeGetCurrent();
        NSLog(@"Mutex test result %f",end - begin);
        return;
    }
    number--;
    pthread_mutex_unlock(&mutex);
}

- (void)testNSLock {
    [self numberReset];
    begin = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < customer; i++) {
        if (number>0) {
            dispatch_async(diapatchQueue, ^{
                [self sellTicketNSLock];
            });
        }
    }
}

- (void)sellTicketNSLock {
    [lock lock];
    if(number == 0) {
        end = CFAbsoluteTimeGetCurrent();
        NSLog(@"NSLock test result %f",end - begin);
    }
    number--;
    [lock unlock];
}

- (void)testRecursiveLock {
    [self numberReset];
    begin = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < customer; i++) {
        if (number>0) {
            dispatch_async(diapatchQueue, ^{
                [self sellTicketRecursiveLock];
            });
        }
    }
}

- (void)sellTicketRecursiveLock {
    [recursiveLock lock];
    if(number == 0) {
        end = CFAbsoluteTimeGetCurrent();
        NSLog(@"RecursiveLock test result %f",end - begin);
    }
    number--;
    [recursiveLock unlock];
}

- (void)testConditionLock {
    [self numberReset];
    begin = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < customer; i++) {
        if (number>0) {
            dispatch_async(diapatchQueue, ^{
                [self sellTicketConditionLock];
            });
        }
    }
}

//conditionLock 场合不合适
- (void)sellTicketConditionLock {
    [conditionLock lock];
    
    if(number == 0) {
        end = CFAbsoluteTimeGetCurrent();
        NSLog(@"ConditionLock test result %f",end - begin);
    }
    number--;
    [conditionLock unlock];
}

- (void)testSynchronized {
    [self numberReset];
    begin = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < customer; i++) {
        if (number>0) {
            dispatch_async(diapatchQueue, ^{
                [self sellTicketSynchronized];
            });
        }
    }
}

//conditionLock 场合不合适
- (void)sellTicketSynchronized {
    @synchronized (self) {
        if(number == 0) {
            end = CFAbsoluteTimeGetCurrent();
            NSLog(@"Synchronized test result %f",end - begin);
        }
        number--;
    }
}

//不支持并发模式
- (void)testUnfairLock {
    begin = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < customer; i++) {
        if (number>0) {
            dispatch_async(diapatchQueue, ^{
                [self sellTicketUnfairLock];
            });
        }
    }
}
//
- (void)sellTicketUnfairLock {
    os_unfair_lock_lock(unfairLock);
    if(number == 0) {
        end = CFAbsoluteTimeGetCurrent();
        NSLog(@"UnfairLock test result %f",end - begin);
        //start end - begin 0.016532
    }
    number--;
    os_unfair_lock_unlock(unfairLock);
}


@end
