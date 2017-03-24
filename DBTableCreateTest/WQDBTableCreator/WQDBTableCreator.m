//
//  WQDBTableCreator.m
//  Exmobi
//
//  Created by wangyuxiang on 2016/11/15.
//  Copyright © 2016年 wangyuxiang. All rights reserved.
//

#import "WQDBTableCreator.h"

@implementation WQDBTableCreator

//更新表
+ (BOOL)updateTableForClass:(Class)cls tableName:(NSString *)tableName inDatabase:(FMDatabase *)db {
    if (!cls || !db) {
        return NO;
    }
    
    //传入的表名为空，就用类名做为表名
    if (!tableName || tableName.length == 0) {
        NSString *fullName = NSStringFromClass(cls);
        if ([fullName rangeOfString:@"."].location != NSNotFound) {
            tableName = [fullName substringFromIndex:[fullName rangeOfString:@"."].location + 1];
        } else {
            tableName = fullName;
        }
    }
    
    tableName = [tableName lowercaseString];
    
    BOOL suc = YES;
    
    if ([self tableExists:tableName inDatabase:db]) {
        //表存在，检查是否需要更新
        NSArray *ivars = [self ivarListForClass:cls];
        NSArray *columns = [self columnsForTable:tableName inDatabase:db];
        if (ivars.count > columns.count) {
            //类的变量个数和已存在列的个数不一样，说明要更新
            [db open];
            [db beginTransaction];
            
            for (NSInteger i = columns.count; i < ivars.count; i++) {
                WQClassIvarInfo *info = ivars[i];
                NSString *sql = [NSString stringWithFormat:@"alter table %@ add column %@ %@", tableName, info.dbName, info.dbType];
                suc = [db executeUpdate:sql];
                
                NSLog(@"%@", sql);
            }
            
            [db commit];
            [db close];
        }
    } else {
        //表不存在，创建表
        suc = [self createTableForClass:cls tableName:tableName inDatabase:db];
    }
    
    return suc;
}

//创建表
+ (BOOL)createTableForClass:(Class)cls tableName:(NSString *)tableName inDatabase:(FMDatabase *)db {
    NSMutableString *sql = [NSMutableString string];
    [sql appendFormat:@"create table if not exists %@ ", tableName];
    [sql appendString:@"("];
    
    NSArray *ivars = [self ivarListForClass:cls];
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
    
    return suc;
}

//判断表在数据库里是否存在
+ (BOOL)tableExists:(NSString *)tableName inDatabase:(FMDatabase *)db {
    [db open];
    
    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat: @"pragma table_info('%@')", tableName]];
    BOOL exist = [rs next];
    
    [rs close];
    [db close];
    
    return exist;
}

//获取表的所有列
+ (NSArray *)columnsForTable:(NSString *)tableName inDatabase:(FMDatabase *)db {
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


//获取类的所有成员变量，包括@property的属性，支持的数据类型有：
//int,long,BOOL,float,double,String,NSNumber,NSData,NSDate
+ (NSArray *)ivarListForClass:(Class)cls {
    //主键
    NSString *primaryKeyStr = nil;
    SEL primaryKeySel = @selector(primaryKey);
    if (class_getClassMethod(cls, primaryKeySel)) {
        IMP imp = [cls methodForSelector:primaryKeySel];
        primaryKeyStr = imp(cls, primaryKeySel);
    }
    //忽略的字段
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

//根据变量类型返回对应的数据库字段类型
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
