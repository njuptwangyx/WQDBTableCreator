//
//  ViewController.m
//  DBTableCreateTest
//
//  Created by wangyuxiang on 2017/3/24.
//  Copyright © 2017年 wangyuxiang. All rights reserved.
//

#import "ViewController.h"
#import "Student.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    NSString *dbPath = [NSString stringWithFormat:@"%@/%@", documentDir, @"studentdb.db3"];
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];

    BOOL suc = [WQDBTableCreator createOrUpdateTableFromClass:[Student class] tableName:nil inDatabase:db];
    if (suc) {
        NSString *tableName = NSStringFromClass([Student class]);
        
        for (NSInteger i = 0; i < 10; i++) {
            NSString *name = [NSString stringWithFormat:@"student%d", (int)i];
            NSString *score = [NSString stringWithFormat:@"%d", arc4random() % 100];
            NSString *sql = [NSString stringWithFormat:@"replace into %@ (name, score) values (?, ?)", tableName];
            
            [db open];
            [db beginTransaction];
            
            [db executeUpdate:sql withArgumentsInArray:@[name, score]];
            
            [db commit];
            [db close];
        }
        
        {
            NSString *sql = [NSString stringWithFormat:@"select * from %@", tableName];
            [db open];
            FMResultSet *rs = [db executeQuery:sql];
            while ([rs next]) {
                long ID = [rs longForColumn:@"ID"];
                NSString *name = [rs stringForColumn:@"name"];
                double score = [rs doubleForColumn:@"score"];
                
                NSLog(@"%ld, %@, %.1f", ID, name, score);
            }
            [rs close];
            [db close];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
