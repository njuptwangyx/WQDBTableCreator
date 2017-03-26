//
//  Student.h
//  DBTableCreateTest
//
//  Created by wangyuxiang on 2017/3/26.
//  Copyright © 2017年 wangyuxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WQDBTableCreator.h"

@interface Student : WQTableBaseModel
{
    long ID;
    NSString *name;
    double score;
}
@end
