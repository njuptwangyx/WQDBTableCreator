# WQDBTableCreator
Create or update table from class's variables and properties based on FMDB.

## Preparing Works
* Add `libsqlite3.tbd` framework.
* Set `Enable Strict Checking of objc_msgSend Calls` to `NO` in Biuld Settings.

## Usage
```
FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
BOOL suc = [WQDBTableCreator createOrUpdateTableFromClass:[Student class] tableName:nil inDatabase:db];
if (suc) {
    
}
```
