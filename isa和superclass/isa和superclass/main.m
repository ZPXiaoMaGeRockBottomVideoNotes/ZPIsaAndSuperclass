//
//  main.m
//  isa和superclass
//
//  Created by 赵鹏 on 2019/5/2.
//  Copyright © 2019 赵鹏. All rights reserved.
//

/**
 1、想要调用Runtime的API就先要在文件中引入"#include <objc/message.h>"头文件，然后在"TARGETS"中的"Build Settings"中搜索"msg"，在搜索结果中把"Enable Strict Checking of objc_msgSend Calls"由"Yes"改为"No"，否则无法调用相关的函数。最后再调用Runtime自己的API，例如："objc_msgSend()"；
 2、OC对象调用方法的总结：
 （1）isa指针的调用：
 ①某个类的实例对象的isa指针指向这个类的类对象；
 ②类对象的isa指针指向这个类的元类对象；
 ③元类对象的isa指针指向基类(NSObject)的元类对象；
 ④基类的元类对象的isa指针指向它自己。
 （2）superclass指针的调用：
 ①某个类的类对象里面的superclass指针指向这个类的父类的类对象。因为OC中所有的类都是继承于基类(NSObject)的，所以最后都会指向基类的类对象，基类的类对象里面的superclass指针指向nil；
 ②某个类的元类对象里面的superclass指针指向这个类的父类的元类对象，最后都会指向基类的元类对象；
 ③基类的元类对象里面的superclass指针指向基类的类对象。
（3）实例对象调用实例方法的原理：
 当某个类的实例对象调用某个实例方法的时候，系统先根据实例对象里面的isa指针找到这个类的类对象，看看这个类对象里面有没有这个实例方法，如果有的话就进行调用，如果没有的话就再根据这个类对象里面的superclass指针找到这个类的父类的类对象，再看看这个类对象里面有没有这个实例方法，如果没有的话就再根据这个类对象里面的superclass指针再找它的父类的类对象，这样一直往上找，直到找到基类(NSObject)的类对象，因为基类的类对象里面的superclass指针指向的是nil，所以在里面如果还是找不到这个实例方法的话，系统就会报"nrecognized selector sent to instance..."（方法找不到）错误。
（4）类对象调用类方法的原理：
 当某个类调用某个类方法的时候，其内部的实现原理为：系统先根据这个类的class对象里面的isa指针找到这个类的meta-class对象，如果这个meta-class对象里面有这个类方法的话就进行调用，如果没有的话再根据这个meta-class对象里面的superclass指针找到这个类的父类的meta-class对象，再看看这个meta-class对象里面有没有这个类方法，如果没有的话就再根据这个meta-class对象里面的superclass指针再找到它的父类的meta-class对象，这样一直往上找，直到找到基类(NSObject)的meta-class对象，如果里面还是没有这个类方法的话就再根据基类的meta-class对象里面的superclass指针找到基类的class对象，再看看这个class对象里面有没有这个类方法，如果还是找不到的话，系统就会报"nrecognized selector sent to instance..."（方法找不到）的错误了。
 */
#import <Foundation/Foundation.h>
#include <objc/message.h>

//自定义类
@interface Person : NSObject <NSCopying>
{
    @public
    int _age;
}

@property (nonatomic, assign) int no;

- (void)personInstanceMethod;

+ (void)personClassMethod;

- (void)test;

@end

@implementation Person

- (void)personInstanceMethod
{
    NSLog(@"personInstanceMethod");
}

+ (void)personClassMethod
{
    NSLog(@"personClassMethod");
}

- (void)test
{
    NSLog(@"Person test");
}

@end

//自定义类
@interface Student : Person <NSCoding>
{
    @public
    int _weight;
}

@property (nonatomic, assign) int height;

- (void)studentInstanceMethod;

+ (void)studentClassMethod;

- (void)test;

@end

@implementation Student

- (void)studentInstanceMethod
{
    NSLog(@"studentInstanceMethod");
}

+ (void)studentClassMethod
{
    NSLog(@"studentClassMethod");
}

- (void)test
{
    NSLog(@"Student test");
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
//------------------------- 父类的实例对象调用父类的实例方法 ------------------------
        Person *person = [[Person alloc] init];
        person->_age = 10;
        
        [person personInstanceMethod];
        
        /**
         ·上面调用person对象的personInstanceMethod方法，实质上在Runtime层面上讲是消息的发送，如下所示，相当于给person对象发送一条personInstanceMethod消息；
         ·下面代码的执行原理：根据Runtime，系统会根据Person类的实例对象里面的isa指针找到Person类的类对象，然后在这个类对象的实例方法列表中寻找personInstanceMethod实例方法，然后再进行调用。
         */
        objc_msgSend(person, @selector(personInstanceMethod));
        
 //--------------------------- 父类的类对象调用父类的类方法 ------------------------
        [Person personClassMethod];
        
        /**
         ·上面调用Person类的personClassMethod方法实质上可以写成如下的代码；
         ·下面代码的执行原理：根据Runtime，系统会根据Person类的类对象里面的isa指针找到它的元类对象，然后在这个元类对象的类方法列表中寻找personClassMethod类方法，然后再进行调用。
         */
        objc_msgSend([Person class], @selector(personClassMethod));
        
 //--------------------------- 子类的实例对象调用父类的实例方法 ------------------------
        /**
         ·Student类继承自Person类，Person类继承自NSObject，他们之间是父子关系；
         ·下面代码的执行原理：根据Runtime，系统会根据Student的实例对象里面的isa指针找到Student的类对象，根据类对象里面的superclass指针找到Student类的父类Person类的类对象，在这个类对象的实例方法列表中找到personInstanceMethod实例方法，然后再进行调用。
         */
        Student *student = [[Student alloc] init];
        [student personInstanceMethod];
     
//--------------------------- 子类的类对象调用父类的类方法 ------------------------
        /**
         下面代码的执行原理：根据Runtime，系统会根据Student类对象里面的isa指针找到Student类的元类对象，然后根据这个元类对象里面的superclass指针找到Student类的父类Person类的元类对象，然后在这个元类对象的类方法列表中寻找personClassMethod类方法，然后再进行调用。
         */
        [Student personClassMethod];
        
//--------------------------- 子类的类对象调用基类的类方法 ------------------------
        /**
         下面代码的执行原理：根据Runtime，系统会根据Student类对象里面的isa指针找到Student类的元类对象，然后根据这个元类对象里面的superclass指针找到Student类的父类Person类的元类对象，然后根据Person类的元类对象里面的superclass指针找到基类的元类对象，然后在这个元类对象里面的类方法列表中找到load类方法，然后再进行调用。
         */
        [Student load];
        
//--------------------------- 子类重写父类的方法会覆盖父类的方法 ------------------------
        /**
         下面代码的执行原理：根据Runtime，系统会根据student实例对象里面的isa指针找到student类的类对象，然后在这个类对象里面的实例方法列表中找到test实例方法，然后再进行调用，整个调用过程就结束了，就不会再继续往student类的父类的类对象中去找了。这也就是为什么子类重写父类的方法后，会把父类的方法覆盖掉的原因。
         */
        [student test];
    }
    
    return 0;
}
