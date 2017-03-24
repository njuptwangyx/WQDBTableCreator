//
//  WQDBTableCreator.h
//  Exmobi
//
//  Created by wangyuxiang on 2016/11/15.
//  Copyright © 2016年 wangyuxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "FMDB.h"

@interface WQDBTableCreator : NSObject

/**
 根据类创建或更新表。
 如果表不存在，就创建表。
 如果存在，检查是否有新增的字段，如果有，则更新表；如果没有，什么也不做。

 @param cls 类，如果属性里面有"ID"，则默认做为主键。
 @param tableName 表名，如果为空，就用传入的类名作为表名
 @param db 数据库

 */
+ (BOOL)updateTableForClass:(Class)cls tableName:(NSString *)tableName inDatabase:(FMDatabase *)db;

@end




/**
 创建表的类可以继承这个基类，用于一些自定义需求。
 */
@interface WQTableBaseModel : NSObject
+ (NSString *)primaryKey;//主键
+ (NSArray *)ignoreArray;//忽略的字段
//要修改和删除的列可以在这里扩展
@end




/**
 Ivar information.
 */
@interface WQClassIvarInfo : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *typeEncode;
@property (nonatomic, copy) NSString *dbName;
@property (nonatomic, copy) NSString *dbType;
@property (nonatomic, assign) BOOL isPrimaryKey;//是否主键

- (instancetype)initWithIvar:(Ivar)ivar;
@end
