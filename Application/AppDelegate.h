#import <Cocoa/Cocoa.h>

@class PlaylistDocument;
@class AppController;

@interface AppDelegate : NSObject {
    NSWindow* window;

    PlaylistDocument* playlistDoc;
    AppController* appController;

    NSPersistentStoreCoordinator* persistentStoreCoordinator;
    NSManagedObjectModel* managedObjectModel;
    NSManagedObjectContext* managedObjectContext;

    bool openedWithFile;
}

@property (nonatomic, retain) IBOutlet NSWindow* window;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel* managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext* managedObjectContext;

- (IBAction)saveAction:sender;
- (void)setPlaylistDocument:(PlaylistDocument*)plDoc;
- (void)setAppController:(AppController*)appCtrl;

@end