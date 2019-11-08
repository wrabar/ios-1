//
//  OCnetworking.h
//  Nextcloud
//
//  Created by Marino Faggiana on 10/05/15.
//  Copyright (c) 2017 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Foundation/Foundation.h>
#import "CCNetworking.h"
@import AFNetworking;

@interface OCNetworking : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

+ (OCNetworking *)sharedManager;

@property BOOL checkRemoteUserInProgress;

#pragma mark ===== OCCommunication =====

- (OCCommunication *)sharedOCCommunication;

#pragma mark ===== Server =====

- (void)checkServerUrl:(NSString *)serverUrl user:(NSString *)user userID:(NSString *)userID password:(NSString *)password completion:(void (^)(NSString *message, NSInteger errorCode))completion;
//- (void)serverStatusUrl:(NSString *)serverUrl completion:(void(^)(NSString *serverProductName, NSInteger versionMajor, NSInteger versionMicro, NSInteger versionMinor, BOOL extendedSupport, NSString *message, NSInteger errorCode))completion;
- (void)downloadContentsOfUrl:(NSString *)serverUrl completion:(void(^)(NSData *data, NSString *message, NSInteger errorCode))completion;
- (void)getAppPassword:(NSString *)serverUrl username:(NSString *)username password:(NSString *)password completion:(void(^)(NSString *token, NSString *message, NSInteger errorCode))completion;

#pragma mark ===== Download / Upload =====

- (NSURLSessionTask *)downloadWithAccount:(NSString *)account fileNameServerUrl:(NSString *)fileNameServerUrl fileNameLocalPath:(NSString *)fileNameLocalPath encode:(BOOL)encode communication:(OCCommunication *)communication completion:(void (^)(NSString *account, int64_t length, NSString *etag, NSDate *date, NSString *message, NSInteger errorCode))completion;
- (NSURLSessionTask *)downloadWithAccount:(NSString *)account url:(NSString *)url fileNameLocalPath:(NSString *)fileNameLocalPath encode:(BOOL)encode completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (NSURLSessionTask *)uploadWithAccount:(NSString *)account fileNameServerUrl:(NSString *)fileNameServerUrl fileNameLocalPath:(NSString *)fileNameLocalPath encode:(BOOL)encode communication:(OCCommunication *)communication progress:(void(^)(NSProgress *progress))uploadProgress completion:(void(^)(NSString *account, NSString *ocId, NSString *etag, NSDate *date, NSString *message, NSInteger errorCode))completion;

#pragma mark ===== WebDav =====

- (void)readFolderWithAccount:(NSString *)account serverUrl:(NSString *)serverUrl depth:(NSString *)depth completion:(void(^)(NSString *account, NSArray *metadatas, tableMetadata *metadataFolder, NSString *message, NSInteger errorCode))completion;
- (void)readFileWithAccount:(NSString *)account serverUrl:(NSString *)serverUrl fileName:(NSString *)fileName completion:(void(^)(NSString *account, tableMetadata *metadata, NSString *message, NSInteger errorCode))completion;
- (void)createFolderWithAccount:(NSString *)account serverUrl:(NSString *)serverUrl fileName:(NSString *)fileName completion:(void(^)(NSString *account, NSString *ocId, NSDate *date, NSString *message, NSInteger errorCode))completion;
- (void)deleteFileOrFolderWithAccount:(NSString *)account path:(NSString *)path completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)moveFileOrFolderWithAccount:(NSString *)account fileName:(NSString *)fileName fileNameTo:(NSString *)fileNameTo completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)searchWithAccount:(NSString *)account fileName:(NSString *)fileName serverUrl:(NSString *)serverUrl contentType:(NSArray *)contentType lteDateLastModified:(NSDate *)lteDateLastModified gteDateLastModified:(NSDate *)gteDateLastModified depth:(NSString *)depth completion:(void(^)(NSString *account, NSArray *metadatas, NSString *message, NSInteger errorCode))completion;
- (void)searchWithAccount:(NSString *)account folder:(NSString *)folder fileName:(NSString *)fileName dateLastModified:(NSDate *)dateLastModified numberOfItem:(NSInteger)numberOfItem completion:(void(^)(NSString *account, NSArray *metadatas, NSString *message, NSInteger errorCode))completion;

#pragma mark ===== downloadPreview =====

- (void)downloadPreviewWithAccount:(NSString *)account metadata:(tableMetadata*)metadata withWidth:(CGFloat)width andHeight:(CGFloat)height completion:(void (^)(NSString *account, UIImage *image, NSString *message, NSInteger errorCode))completion;
- (void)downloadPreviewWithAccount:(NSString *)account serverPath:(NSString *)serverPath fileNamePath:(NSString *)fileNamePath completion:(void (^)(NSString *account, UIImage *image, NSString *message, NSInteger errorCode))completion;
- (void)downloadPreviewTrashWithAccount:(NSString *)account fileId:(NSString *)fileId size:(NSString *)size fileName:(NSString *)fileName completion:(void (^)(NSString *account, UIImage *image, NSString *message, NSInteger errorCode))completion;

#pragma mark ===== Favorite =====

- (void)listingFavoritesWithAccount:(NSString *)account completion:(void(^)(NSString *account, NSArray *metadatas, NSString *message, NSInteger errorCode))completion;


#pragma mark ===== Share =====

- (void)readShareWithAccount:(NSString *)account completion:(void (^)(NSString *account, NSArray *items, NSString *message, NSInteger errorCode))completion;
- (void)readShareWithAccount:(NSString *)account path:(NSString *)path completion:(void (^)(NSString *account, NSArray *items, NSString *message, NSInteger errorCode))completion;
- (void)shareWithAccount:(NSString *)account fileName:(NSString *)fileName password:(NSString *)password permission:(NSInteger)permission hideDownload:(BOOL)hideDownload completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)shareUserGroupWithAccount:(NSString *)account userOrGroup:(NSString *)userOrGroup fileName:(NSString *)fileName permission:(NSInteger)permission shareeType:(NSInteger)shareeType completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)shareUpdateAccount:(NSString *)account shareID:(NSInteger)shareID password:(NSString *)password note:(NSString *)note permission:(NSInteger)permission expirationTime:(NSString *)expirationTime hideDownload:(BOOL)hideDownload completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)unshareAccount:(NSString *)account shareID:(NSInteger)shareID completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)getUserGroupWithAccount:(NSString *)account searchString:(NSString *)searchString completion:(void (^)(NSString *account, NSArray *item, NSString *message, NSInteger errorCode))completion;

#pragma mark ===== API =====

- (void)getActivityWithAccount:(NSString *)account since:(NSInteger)since limit:(NSInteger)limit objectId:(NSString *)objectId objectType:(NSString *)objectType link:(NSString *)link completion:(void(^)(NSString *account, NSArray *listOfActivity, NSString *message, NSInteger errorCode))completion;
- (void)getExternalSitesWithAccount:(NSString *)account completion:(void (^)(NSString *account, NSArray *listOfExternalSites, NSString *message, NSInteger errorCode))completion;
- (void)getNotificationWithAccount:(NSString *)account completion:(void (^)(NSString *account, NSArray *listOfNotifications, NSString *message, NSInteger errorCode))completion;
- (void)setNotificationWithAccount:(NSString *)account serverUrl:(NSString *)serverUrl type:(NSString *)type completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)getCapabilitiesWithAccount:(NSString *)account completion:(void (^)(NSString *account, OCCapabilities *capabilities, NSString *message, NSInteger errorCode))completion;
- (void)getUserProfileWithAccount:(NSString *)account completion:(void (^)(NSString *account, OCUserProfile *userProfile, NSString *message, NSInteger errorCode))completion;

#pragma mark ===== Push Notification =====

- (void)subscribingPushNotificationWithAccount:(NSString *)account url:(NSString *)url pushToken:(NSString *)pushToken Hash:(NSString *)pushTokenHash devicePublicKey:(NSString *)devicePublicKey completion:(void(^)(NSString *account, NSString *deviceIdentifier, NSString *deviceIdentifierSignature, NSString *publicKey, NSString *message, NSInteger errorCode))completion;
- (void)unsubscribingPushNotificationWithAccount:(NSString *)account url:(NSString *)url deviceIdentifier:(NSString *)deviceIdentifier deviceIdentifierSignature:(NSString *)deviceIdentifierSignature publicKey:(NSString *)publicKey completion:(void (^)(NSString *account ,NSString *message, NSInteger errorCode))completion;
- (void)getServerNotification:(NSString *)serverUrl notificationId:(NSInteger)notificationId completion:(void(^)(NSDictionary*jsongParsed, NSString *message, NSInteger errorCode))completion;
- (void)deletingServerNotification:(NSString *)serverUrl notificationId:(NSInteger)notificationId completion:(void(^)(NSString *message, NSInteger errorCode))completion;

#pragma mark ===== Manage Mobile Editor OCS API =====

- (void)createLinkRichdocumentsWithAccount:(NSString *)account fileId:(NSString *)fileId completion:(void(^)(NSString *account, NSString *link, NSString *message, NSInteger errorCode))completion;
- (void)getTemplatesRichdocumentsWithAccount:(NSString *)account typeTemplate:(NSString *)typeTemplate completion:(void(^)(NSString *account, NSArray *listOfTemplate, NSString *message, NSInteger errorCode))completion;
- (void)createNewRichdocumentsWithAccount:(NSString *)account fileName:(NSString *)fileName serverUrl:(NSString *)serverUrl templateID:(NSString *)templateID completion:(void(^)(NSString *account, NSString *url, NSString *message, NSInteger errorCode))completion;
- (void)createAssetRichdocumentsWithAccount:(NSString *)account fileName:(NSString *)fileName serverUrl:(NSString *)serverUrl completion:(void(^)(NSString *account, NSString *link, NSString *message, NSInteger errorCode))completion;

#pragma mark ===== Full Text Search =====

- (void)fullTextSearchWithAccount:(NSString *)account text:(NSString *)text page:(NSInteger)page completion:(void(^)(NSString *account, NSArray *items, NSString *message, NSInteger errorCode))completion;

#pragma mark ===== Check remote user =====

- (void)checkRemoteUser:(NSString *)account;

#pragma mark ===== Trash =====

- (void)listingTrashWithAccount:(NSString *)account path:(NSString *)path serverUrl:(NSString *)serverUrl depth:(NSString *)depth completion:(void (^)(NSString *account, NSArray *items, NSString *message, NSInteger errorCode))completion;
- (void)emptyTrashWithAccount:(NSString *)account completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;

#pragma mark ===== Comments =====

- (void)getCommentsWithAccount:(NSString *)account fileId:(NSString *)fileId completion:(void (^)(NSString *account, NSArray *items, NSString *message, NSInteger errorCode))completion;
- (void)putCommentsWithAccount:(NSString *)account fileId:(NSString *)fileId message:(NSString *)message  completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)updateCommentsWithAccount:(NSString *)account fileId:(NSString *)fileId messageID:(NSString *)messageID message:(NSString *)message  completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)readMarkCommentsWithAccount:(NSString *)account fileId:(NSString *)fileId completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)deleteCommentsWithAccount:(NSString *)account fileId:(NSString *)fileId messageID:(NSString *)messageID completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;

#pragma mark ===== Third Parts =====

- (void)getHCUserProfileWithAccount:(NSString *)account serverUrl:(NSString *)serverUrl completion:(void (^)(NSString *account, OCUserProfile *userProfile, NSString *message, NSInteger errorCode))completion;
- (void)putHCUserProfileWithAccount:(NSString *)account serverUrl:(NSString *)serverUrl address:(NSString *)address businesssize:(NSString *)businesssize businesstype:(NSString *)businesstype city:(NSString *)city company:(NSString *)company  country:(NSString *)country displayname:(NSString *)displayname email:(NSString *)email phone:(NSString *)phone role_:(NSString *)role_ twitter:(NSString *)twitter website:(NSString *)website zip:(NSString *)zip completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)getHCFeaturesWithAccount:(NSString *)account serverUrl:(NSString *)serverUrl completion:(void (^)(NSString *account, HCFeatures *features, NSString *message, NSInteger errorCode))completion;

@end

@interface OCURLSessionManager : AFURLSessionManager

@end

