//
//  WQDBTableCreator.m
//  Exmobi
//
//  Created by wangyuxiang on 2016/11/15.
//  Copyright © 2016年 wangyuxiang. All rights reserved.
//

#import "WQDBTableCreator.h"

@implementation WQDBTableCreator

+ (BOOL)createOrUpdateTableFromClass:(Class)cls tableName:(NSString *)tableName inDatabase:(FMDatabase *)db {
    if (!cls || !db) {
        return NO;
    }
    
    if (!tableName || tableName.length == 0) {
        NSString *fullName = NSStringFromClass(cls);
        if ([fullName rangeOfString:@"."].location != NSNotFound) {
            tableName = [fullName substringFromIndex:[fullName rangeOfString:@"."].location + 1];
        } else {
            tableName = fullName;
        }
    }
    
    BOOL suc = YES;
    
    if ([self tableExists:tableName inDatabase:db]) {
        suc = [self updateTableFromClass:cls tableName:tableName inDatabase:db];
    } else {
        suc = [self createTableFromClass:cls tableName:tableName inDatabase:db];
    }
    
    return suc;
}

//Create table.
+ (BOOL)createTableFromClass:(Class)cls tableName:(NSString *)tableName inDatabase:(FMDatabase *)db {
    NSMutableString *sql = [NSMutableString string];
    [sql appendFormat:@"create table if not exists %@", tableName];
    [sql appendString:@"("];
    
    NSArray *ivars = [self ivarListOfClass:cls];
    [ivars enumerateObjectsUsingBlock:^(WQClassIvarInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx > 0) {
            [sql appendString:@","];
        }
        [sql appendFormat:@"%@ %@ ", obj.dbName, obj.dbType];
        if (obj.isPrimaryKey) {
            [sql appendString:@"primary key "];
        }
    }];
    
    [sql appendString:@")"];
    
    [db open];
    [db beginTransaction];
    
    BOOL suc = [db executeUpdate:sql];
    
    [db commit];
    [db close];
    
    NSLog(@"sql:%@", sql);
    
    return suc;
}

//Update table.
+ (BOOL)updateTableFromClass:(Class)cls tableName:(NSString *)tableName inDatabase:(FMDatabase *)db {
    BOOL suc = YES;
    
    NSArray *ivars = [self ivarListOfClass:cls];
    NSArray *columns = [self columnsOfTable:tableName inDatabase:db];
    if (ivars.count > columns.count) {
        //If new fileds come, then update table.
        [db open];
        [db beginTransaction];
        
        for (NSInteger i = columns.count; i < ivars.count; i++) {
            WQClassIvarInfo *info = ivars[i];
            NSString *sql = [NSString stringWithFormat:@"alter table %@ add column %@ %@", tableName, info.dbName, info.dbType];
            suc = [db executeUpdate:sql];
            
            NSLog(@"sql:%@", sql);
        }
        
        [db commit];
        [db close];
    }
    
    return suc;
}

//Check if table exists in database.
+ (BOOL)tableExists:(NSString *)tableName inDatabase:(FMDatabase *)db {
    [db open];
    
    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat: @"pragma table_info('%@')", tableName]];
    BOOL exist = [rs next];
    
    [rs close];
    [db close];
    
    return exist;
}

//Get all columns of table.
+ (NSArray *)columnsOfTable:(NSString *)tableName inDatabase:(FMDatabase *)db {
    NSMutableArray *columns = [NSMutableArray new];
    
    [db open];
    
    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat: @"pragma table_info('%@')", tableName]];
    while ([rs next]) {
        WQClassIvarInfo *info = [[WQClassIvarInfo alloc] init];
        info.dbName = [rs stringForColumn:@"name"];
        info.dbType = [rs stringForColumn:@"type"];
        info.isPrimaryKey = [rs boolForColumn:@"pk"];
        [columns addObject:info];
    }
    
    [rs close];
    [db close];
    
    return columns;
}


//Get variables and properties of class.
//Supported data types: int,long,BOOL,float,double,String,NSNumber,NSData,NSDate
+ (NSArray *)ivarListOfClass:(Class)cls {
    //primary key
    NSString *primaryKeyStr = nil;
    SEL primaryKeySel = @selector(primaryKey);
    if (class_getClassMethod(cls, primaryKeySel)) {
        IMP imp = [cls methodForSelector:primaryKeySel];
        primaryKeyStr = imp(cls, primaryKeySel);
    }
    //ignored fields
    NSArray *ignoreIvars = nil;
    SEL ignoreIvarsSel = @selector(ignoreArray);
    if (class_getClassMethod(cls, ignoreIvarsSel)) {
        IMP imp = [cls methodForSelector:ignoreIvarsSel];
        ignoreIvars = imp(cls, ignoreIvarsSel);
    }
    
    NSMutableArray *ivarInfos = [NSMutableArray new];
    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList(cls, &ivarCount);
    if (ivars) {
        for (unsigned int i = 0; i < ivarCount; i++) {
            WQClassIvarInfo *info = [[WQClassIvarInfo alloc] initWithIvar:ivars[i]];
            if (info.dbName && info.dbType && ![ignoreIvars containsObject:info.dbName]) {
                if (primaryKeyStr && [primaryKeyStr isEqualToString:info.dbName]) {
                    info.isPrimaryKey = YES;
                }
                [ivarInfos addObject:info];
            }
        }
        free(ivars);
    }
    
    return ivarInfos;
}

+ (NSString *)dataBaseTypeWithEncodeName:(NSString *)encode {
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(int)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(unsigned int)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(long)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(unsigned long)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(BOOL)]]
        ) {
        return @"INTEGER";
    }
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(float)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(double)]]
        ) {
        return @"REAL";
    }
    if ([encode rangeOfString:@"String"].length) {
        return @"TEXT";
    }
    if ([encode rangeOfString:@"NSNumber"].length) {
        return @"REAL";
    }
    if ([encode rangeOfString:@"NSData"].length) {
        return @"BLOB";
    }
    if ([encode rangeOfString:@"NSDate"].length) {
        return @"TIMESTAMP";
    }
    return nil;
}

@end




/**
 baseModel
 */
@implementation WQTableBaseModel

+ (NSString *)primaryKey {
    return @"ID";
}

+ (NSArray *)ignoreArray {
    return nil;
}

@end



/**
 Ivar information.
 */
@implementation WQClassIvarInfo

- (instancetype)initWithIvar:(Ivar)ivar {
    if (!ivar) return nil;
    
    self = [self init];
    const char *name = ivar_getName(ivar);
    if (name) {
        self.name = [NSString stringWithUTF8String:name];
        self.dbName = self.name;
    }
    
    const char *typeEncoding = ivar_getTypeEncoding(ivar);
    if (typeEncoding) {
        self.typeEncode = [NSString stringWithUTF8String:typeEncoding];
        self.dbType = [WQDBTableCreator dataBaseTypeWithEncodeName:self.typeEncode];
    }

    return self;
}

@end
