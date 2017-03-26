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
 Create or update table from 'Class' in designated database.
 If table exists, check for new fields to update table or do nothing; otherwise create a table.

 @param cls Class, if the class contains property or variable named 'ID', the 'ID' will be designated as primary key. Of course you can customize primary key by methods of 'WQTableBaseModel'.
 @param tableName Name of the table. If it is nil or a empty string, the class‘s name will be designated as table's name.
 @param db database, 'FMDatabase' object.
 
 @return 'YES' if successful; 'NO' if failure.

 */
+ (BOOL)createOrUpdateTableFromClass:(Class)cls tableName:(NSString *)tableName inDatabase:(FMDatabase *)db;

@end




/**
 Super class of model for customized requirements.
 */
@interface WQTableBaseModel : NSObject
+ (NSString *)primaryKey;//return the primary key.
+ (NSArray *)ignoreArray;//return ignored fields.
@end




/**
 Ivar information.
 */
@interface WQClassIvarInfo : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *typeEncode;
@property (nonatomic, copy) NSString *dbName;
@property (nonatomic, copy) NSString *dbType;
@property (nonatomic, assign) BOOL isPrimaryKey;

- (instancetype)initWithIvar:(Ivar)ivar;
@end
