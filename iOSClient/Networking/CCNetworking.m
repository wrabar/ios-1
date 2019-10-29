//
//  CCNetworking.m
//  Nextcloud
//
//  Created by Marino Faggiana on 01/06/15.
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

#import "CCNetworking.h"
#import "NCEndToEndEncryption.h"
#import "NCNetworkingEndToEnd.h"
#import "AppDelegate.h"
#import "NSDate+ISO8601.h"
#import "NSString+Encode.h"
#import "NCBridgeSwift.h"

@interface CCNetworking ()
{
    
}
@end

@implementation CCNetworking

+ (CCNetworking *)sharedNetworking {
    static CCNetworking *sharedNetworking;
    @synchronized(self)
    {
        if (!sharedNetworking) {
            sharedNetworking = [[CCNetworking alloc] init];
        }
        return sharedNetworking;
    }
}

- (id)init
{    
    self = [super init];
    
    // Initialization Sessions
    [self sessionDownload];
    [self sessionDownloadForeground];
    [self sessionWWanDownload];

    [self sessionUpload];
    [self sessionWWanUpload];
    [self sessionUploadForeground];
    
    return self;
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark =====  Session =====
#pragma --------------------------------------------------------------------------------------------

- (NSURLSession *)sessionDownload
{
    static NSURLSession *sessionDownload = nil;
    
    if (sessionDownload == nil) {
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:k_download_session];
        
        configuration.allowsCellularAccess = YES;
        configuration.sessionSendsLaunchEvents = YES;
        configuration.discretionary = NO;
        configuration.HTTPMaximumConnectionsPerHost = k_maxHTTPConnectionsPerHost;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        sessionDownload = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        sessionDownload.sessionDescription = k_download_session;
    }
    return sessionDownload;
}

- (NSURLSession *)sessionDownloadForeground
{
    static NSURLSession *sessionDownloadForeground = nil;
    
    if (sessionDownloadForeground == nil) {
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
        configuration.allowsCellularAccess = YES;
        configuration.discretionary = NO;
        configuration.HTTPMaximumConnectionsPerHost = k_maxHTTPConnectionsPerHost;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
        sessionDownloadForeground = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        sessionDownloadForeground.sessionDescription = k_download_session_foreground;
    }
    return sessionDownloadForeground;
}

- (NSURLSession *)sessionWWanDownload
{
    static NSURLSession *sessionWWanDownload = nil;
    
    if (sessionWWanDownload == nil) {
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:k_download_session_wwan];
        
        configuration.allowsCellularAccess = NO;
        configuration.sessionSendsLaunchEvents = YES;
        configuration.discretionary = NO;
        configuration.HTTPMaximumConnectionsPerHost = k_maxHTTPConnectionsPerHost;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        sessionWWanDownload = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        sessionWWanDownload.sessionDescription = k_download_session_wwan;
    }
    return sessionWWanDownload;
}

- (NSURLSession *)sessionUpload
{
    static NSURLSession *sessionUpload = nil;
    
    if (sessionUpload == nil) {
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:k_upload_session];
        
        configuration.allowsCellularAccess = YES;
        configuration.sessionSendsLaunchEvents = YES;
        configuration.discretionary = NO;
        configuration.HTTPMaximumConnectionsPerHost = k_maxHTTPConnectionsPerHost;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

        sessionUpload = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        sessionUpload.sessionDescription = k_upload_session;
    }
    return sessionUpload;
}

- (NSURLSession *)sessionWWanUpload
{
    static NSURLSession *sessionWWanUpload = nil;
    
    if (sessionWWanUpload == nil) {
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:k_upload_session_wwan];
        
        configuration.allowsCellularAccess = NO;
        configuration.sessionSendsLaunchEvents = YES;
        configuration.discretionary = NO;
        configuration.HTTPMaximumConnectionsPerHost = k_maxHTTPConnectionsPerHost;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        sessionWWanUpload = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        sessionWWanUpload.sessionDescription = k_upload_session_wwan;
    }
    return sessionWWanUpload;
}

- (NSURLSession *)sessionUploadForeground
{
    static NSURLSession *sessionUploadForeground;
    
    if (sessionUploadForeground == nil) {
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        configuration.allowsCellularAccess = YES;
        configuration.discretionary = NO;
        configuration.HTTPMaximumConnectionsPerHost = k_maxHTTPConnectionsPerHost;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        sessionUploadForeground = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        sessionUploadForeground.sessionDescription = k_upload_session_foreground;
    }
    return sessionUploadForeground;
}

- (NSURLSession *)sessionUploadExtension
{
    static NSURLSession *sessionUpload = nil;
    
    if (sessionUpload == nil) {
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:k_upload_session_extension];
        
        configuration.allowsCellularAccess = YES;
        configuration.sessionSendsLaunchEvents = YES;
        configuration.discretionary = NO;
        configuration.HTTPMaximumConnectionsPerHost = 1;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        configuration.sharedContainerIdentifier = [NCBrandOptions sharedInstance].capabilitiesGroups;
        
        sessionUpload = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        sessionUpload.sessionDescription = k_upload_session_extension;
    }
    return sessionUpload;
}

- (NSURLSession *)getSessionfromSessionDescription:(NSString *)sessionDescription
{
    if ([sessionDescription isEqualToString:k_download_session]) return [self sessionDownload];
    if ([sessionDescription isEqualToString:k_download_session_foreground]) return [self sessionDownloadForeground];
    if ([sessionDescription isEqualToString:k_download_session_wwan]) return [self sessionWWanDownload];

    if ([sessionDescription isEqualToString:k_upload_session]) return [self sessionUpload];
    if ([sessionDescription isEqualToString:k_upload_session_wwan]) return [self sessionWWanUpload];
    if ([sessionDescription isEqualToString:k_upload_session_foreground]) return [self sessionUploadForeground];
    
    if ([sessionDescription isEqualToString:k_upload_session_extension]) return [self sessionUploadExtension];

    return nil;
}

- (void)invalidateAndCancelAllSession
{
    [[self sessionDownload] invalidateAndCancel];
    [[self sessionDownloadForeground] invalidateAndCancel];
    [[self sessionWWanDownload] invalidateAndCancel];
    
    [[self sessionUpload] invalidateAndCancel];
    [[self sessionWWanUpload] invalidateAndCancel];
    [[self sessionUploadForeground] invalidateAndCancel];
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== URLSession download/upload =====
#pragma --------------------------------------------------------------------------------------------

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    // The pinnning check
    if ([[NCNetworking sharedInstance] checkTrustedChallengeWithChallenge:challenge directoryCertificate:[CCUtility getDirectoryCerificates]]) {
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSString *url = [[[task currentRequest].URL absoluteString] stringByRemovingPercentEncoding];
    
    if (!url)
        return;
    
    NSString *fileName = [url lastPathComponent];
    NSString *serverUrl = [self getServerUrlFromUrl:url];
    if (!serverUrl) return;
    
    NSInteger errorCode;
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"EEE, dd MMM y HH:mm:ss zzz"];
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)task.response;
    
    if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        
        errorCode = error.code;
        
    } else {
        
        if (httpResponse.statusCode > 0)
            errorCode = httpResponse.statusCode;
        else
            errorCode = error.code;
    }

    // ----------------------- DOWNLOAD -----------------------
    
    if ([task isKindOfClass:[NSURLSessionDownloadTask class]]) {
        
        tableMetadata *metadata = [[NCManageDatabase sharedInstance] getMetadataInSessionFromFileName:fileName serverUrl:serverUrl taskIdentifier:task.taskIdentifier];
        if (metadata) {
            
            NSString *etag = metadata.etag;
            //NSString *ocId = metadata.ocId;
            NSDictionary *fields = [httpResponse allHeaderFields];
            
            if (errorCode == 0) {
            
                etag = [CCUtility removeForbiddenCharactersFileSystem:[fields objectForKey:@"OC-ETag"]];
            
                NSString *dateString = [fields objectForKey:@"Date"];
                if (dateString) {
                    if (![dateFormatter getObjectValue:&date forString:dateString range:nil error:&error]) {
                        date = [NSDate date];
                    }
                } else {
                    date = [NSDate date];
                }
            }
            
            if (fileName.length > 0 && serverUrl.length > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self downloadFileSuccessFailure:fileName ocId:metadata.ocId etag:etag date:date serverUrl:serverUrl selector:metadata.sessionSelector errorCode:errorCode];
                });
            }
            
        } else {
            
            NSLog(@"[LOG] Remove record ? : metadata not found %@", url);

            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([self.delegate respondsToSelector:@selector(downloadFileSuccessFailure:ocId:serverUrl:selector:errorMessage:errorCode:)]) {
                    [self.delegate downloadFileSuccessFailure:fileName ocId:@"" serverUrl:serverUrl selector:@"" errorMessage:@"" errorCode:k_CCErrorInternalError];
                }
            });
        }
    }
    
    // ------------------------ UPLOAD -----------------------
    
    if ([task isKindOfClass:[NSURLSessionUploadTask class]]) {
        
        tableMetadata *metadata = [[NCManageDatabase sharedInstance] getMetadataInSessionFromFileName:fileName serverUrl:serverUrl taskIdentifier:task.taskIdentifier];
        if (metadata) {
            
            NSDictionary *fields = [httpResponse allHeaderFields];
            NSString *ocId = metadata.ocId;
            NSString *etag = metadata.etag;
            
            if (errorCode == 0) {
            
                ocId = [CCUtility removeForbiddenCharactersFileSystem:[fields objectForKey:@"OC-FileId"]];
                etag = [CCUtility removeForbiddenCharactersFileSystem:[fields objectForKey:@"OC-ETag"]];
            
                NSString *dateString = [fields objectForKey:@"Date"];
                if (dateString) {
                    if (![dateFormatter getObjectValue:&date forString:dateString range:nil error:&error]) {
                        NSLog(@"[LOG] Date '%@' could not be parsed: %@", dateString, error);
                        date = [NSDate date];
                    }
                } else {
                    date = [NSDate date];
                }
            }
                
            if (fileName.length > 0 && ocId.length > 0 && serverUrl.length > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self uploadFileSuccessFailure:metadata fileName:fileName ocId:ocId etag:etag date:date serverUrl:serverUrl errorCode:errorCode];
                });
            }
            
        } else {
            NSLog(@"[LOG] Remove record ? : metadata not found %@", url);
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
                    [self.delegate uploadFileSuccessFailure:fileName ocId:@"" assetLocalIdentifier:@"" serverUrl:serverUrl selector:@"" errorMessage:@"" errorCode:k_CCErrorInternalError];
                }
            });
        }
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark =====  Download =====
#pragma --------------------------------------------------------------------------------------------

- (void)downloadFile:(tableMetadata *)metadata taskStatus:(NSInteger)taskStatus
{
    // No Password
    if ([CCUtility getPassword:metadata.account].length == 0) {
        [self.delegate downloadFileSuccessFailure:metadata.fileName ocId:metadata.ocId serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:NSLocalizedString(@"_bad_username_password_", nil) errorCode:kOCErrorServerUnauthorized];
        return;
    } else if ([CCUtility getCertificateError:metadata.account]) {
        [self.delegate downloadFileSuccessFailure:metadata.fileName ocId:metadata.ocId serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:NSLocalizedString(@"_ssl_certificate_untrusted_", nil) errorCode:NSURLErrorServerCertificateUntrusted];
        return;
    }
    
    // File exists ?
    tableLocalFile *localfile = [[NCManageDatabase sharedInstance] getTableLocalFileWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
        
    if (localfile != nil && [CCUtility fileProviderStorageExists:metadata.ocId fileNameView:metadata.fileNameView]) {
            
        [[NCManageDatabase sharedInstance] setMetadataSession:@"" sessionError:@"" sessionSelector:@"" sessionTaskIdentifier:k_taskIdentifierDone status:k_metadataStatusNormal predicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
        
        if ([self.delegate respondsToSelector:@selector(downloadFileSuccessFailure:ocId:serverUrl:selector:errorMessage:errorCode:)]) {
            [self.delegate downloadFileSuccessFailure:metadata.fileName ocId:metadata.ocId serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:@"" errorCode:0];
        }
        return;
    }
    
    [self downloaURLSession:metadata taskStatus:taskStatus];
}

- (void)downloaURLSession:(tableMetadata *)metadata taskStatus:(NSInteger)taskStatus
{
    NSURLSession *sessionDownload;
    NSURL *url;
    NSMutableURLRequest *request;
    
    tableAccount *tableAccount = [[NCManageDatabase sharedInstance] getAccountWithPredicate:[NSPredicate predicateWithFormat:@"account == %@", metadata.account]];
    if (tableAccount == nil) {
        [[NCManageDatabase sharedInstance] deleteMetadataWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];

        if ([self.delegate respondsToSelector:@selector(downloadFileSuccessFailure:ocId:serverUrl:selector:errorMessage:errorCode:)]) {
            [self.delegate downloadFileSuccessFailure:metadata.fileName ocId:metadata.ocId serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:@"Download error, account not found" errorCode:k_CCErrorInternalError];
        }
        return;
    }
    
    NSString *serverFileUrl = [[NSString stringWithFormat:@"%@/%@", metadata.serverUrl, metadata.fileName] encodeString:NSUTF8StringEncoding];
        
    url = [NSURL URLWithString:serverFileUrl];
    request = [NSMutableURLRequest requestWithURL:url];
        
    NSData *authData = [[NSString stringWithFormat:@"%@:%@", tableAccount.user, [CCUtility getPassword:tableAccount.account]] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat: @"Basic %@",[authData base64EncodedStringWithOptions:0]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    [request setValue:[CCUtility getUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    if ([metadata.session isEqualToString:k_download_session]) sessionDownload = [self sessionDownload];
    else if ([metadata.session isEqualToString:k_download_session_foreground]) sessionDownload = [self sessionDownloadForeground];
    else if ([metadata.session isEqualToString:k_download_session_wwan]) sessionDownload = [self sessionWWanDownload];
    
    NSURLSessionDownloadTask *downloadTask = [sessionDownload downloadTaskWithRequest:request];
    
    if (downloadTask == nil) {
        
        [[NCManageDatabase sharedInstance] setMetadataSession:nil sessionError:@"Serious internal error downloadTask not available" sessionSelector:nil sessionTaskIdentifier:k_taskIdentifierDone status:k_metadataStatusDownloadError predicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
        
        if ([self.delegate respondsToSelector:@selector(downloadFileSuccessFailure:ocId:serverUrl:selector:errorMessage:errorCode:)]) {
            [self.delegate downloadFileSuccessFailure:metadata.fileName ocId:metadata.ocId serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:@"Serious internal error downloadTask not available" errorCode:k_CCErrorInternalError];
        }
        
    } else {
        
        // Manage uploadTask cancel,suspend,resume
        if (taskStatus == k_taskStatusCancel) [downloadTask cancel];
        else if (taskStatus == k_taskStatusSuspend) [downloadTask suspend];
        else if (taskStatus == k_taskStatusResume) [downloadTask resume];
        
        [[NCManageDatabase sharedInstance] setMetadataSession:nil sessionError:nil sessionSelector:nil sessionTaskIdentifier:downloadTask.taskIdentifier status:k_metadataStatusDownloading predicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
        
        NSLog(@"[LOG] downloadFileSession %@ Task [%lu]", metadata.ocId, (unsigned long)downloadTask.taskIdentifier);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(downloadStart:account:task:serverUrl:)]) {
                [self.delegate downloadStart:metadata.ocId account:metadata.account task:downloadTask serverUrl:metadata.serverUrl];
            }
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSString *url = [[[downloadTask currentRequest].URL absoluteString] stringByRemovingPercentEncoding];
    NSString *fileName = [url lastPathComponent];
    NSString *serverUrl = [self getServerUrlFromUrl:url];
    if (!serverUrl) return;
    
    if (totalBytesExpectedToWrite < 1) {
        totalBytesExpectedToWrite = totalBytesWritten;
    }
        
    float progress = (float) totalBytesWritten / (float)totalBytesExpectedToWrite;
    
    tableMetadata *metadata = [[NCManageDatabase sharedInstance] getMetadataInSessionFromFileName:fileName serverUrl:serverUrl taskIdentifier:downloadTask.taskIdentifier];
    if (metadata) {
        NSDictionary *userInfo = @{@"account": (metadata.account), @"ocId": (metadata.ocId), @"serverUrl": (serverUrl), @"status": ([NSNumber numberWithLong:k_metadataStatusInDownload]), @"progress": ([NSNumber numberWithFloat:progress]), @"totalBytes": ([NSNumber numberWithLongLong:totalBytesWritten]), @"totalBytesExpected": ([NSNumber numberWithLongLong:totalBytesExpectedToWrite])};
        if (userInfo)
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"NotificationProgressTask" object:nil userInfo:userInfo];
    } else {
        NSLog(@"[LOG] metadata not found");
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSString *url = [[[downloadTask currentRequest].URL absoluteString] stringByRemovingPercentEncoding];
    if (!url)
        return;

    NSString *fileName = [url lastPathComponent];
    NSString *serverUrl = [self getServerUrlFromUrl:url];
    if (!serverUrl) return;
    
    tableMetadata *metadata = [[NCManageDatabase sharedInstance] getMetadataInSessionFromFileName:fileName serverUrl:serverUrl taskIdentifier:downloadTask.taskIdentifier];
    if (!metadata) {
        
        NSLog(@"[LOG] Serious error internal download : metadata not found %@ ", url);

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(downloadFileSuccessFailure:ocId:serverUrl:selector:errorMessage:errorCode:)]) {
                [self.delegate downloadFileSuccessFailure:@"" ocId:@"" serverUrl:serverUrl selector:@"" errorMessage:@"Serious error internal download : metadata not found" errorCode:k_CCErrorInternalError];
            }
        });
        
        return;
    }
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)downloadTask.response;
    
    if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        
        NSString *destinationFilePath = [CCUtility getDirectoryProviderStorageOcId:metadata.ocId fileNameView:metadata.fileName];
        NSURL *destinationURL = [NSURL fileURLWithPath:destinationFilePath];
        
        [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:NULL];
        [[NSFileManager defaultManager] copyItemAtURL:location toURL:destinationURL error:nil];
    }
}

- (void)downloadFileSuccessFailure:(NSString *)fileName ocId:(NSString *)ocId etag:(NSString *)etag date:(NSDate *)date serverUrl:(NSString *)serverUrl selector:(NSString *)selector errorCode:(NSInteger)errorCode
{
#ifndef EXTENSION
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.listProgressMetadata removeObjectForKey:ocId];
#endif
    
     tableMetadata *metadata = [[NCManageDatabase sharedInstance] getMetadataWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", ocId]];
    
    if (errorCode != 0) {
        
        if (errorCode == kCFURLErrorCancelled) {
            
            [[NCManageDatabase sharedInstance] setMetadataSession:@"" sessionError:@"" sessionSelector:@"" sessionTaskIdentifier:k_taskIdentifierDone status:k_metadataStatusNormal predicate:[NSPredicate predicateWithFormat:@"ocId == %@", ocId]];
            
        } else {
            
            if (metadata && (errorCode == kOCErrorServerUnauthorized || errorCode == kOCErrorServerForbidden))
                [[OCNetworking sharedManager] checkRemoteUser:metadata.account];
            else if (metadata && errorCode == NSURLErrorServerCertificateUntrusted)
                [CCUtility setCertificateError:metadata.account error:YES];

            [[NCManageDatabase sharedInstance] setMetadataSession:nil sessionError:[CCError manageErrorKCF:errorCode withNumberError:NO] sessionSelector:nil sessionTaskIdentifier:k_taskIdentifierDone status:k_metadataStatusDownloadError predicate:[NSPredicate predicateWithFormat:@"ocId == %@", ocId]];
        }
        
        if ([self.delegate respondsToSelector:@selector(downloadFileSuccessFailure:ocId:serverUrl:selector:errorMessage:errorCode:)]) {
            [self.delegate downloadFileSuccessFailure:fileName ocId:ocId serverUrl:serverUrl selector:selector errorMessage:[CCError manageErrorKCF:errorCode withNumberError:YES] errorCode:errorCode];
        }
        
    } else {
        
        if (!metadata) {
            
            NSLog(@"[LOG] Serious error internal download : metadata not found %@ ", fileName);
            
            if ([self.delegate respondsToSelector:@selector(downloadFileSuccessFailure:ocId:serverUrl:selector:errorMessage:errorCode:)]) {
                [self.delegate downloadFileSuccessFailure:fileName ocId:ocId serverUrl:serverUrl selector:selector errorMessage:[NSString stringWithFormat:@"Serious error internal download : metadata not found %@", fileName] errorCode:k_CCErrorInternalError];
            }

            return;
        }
        
        metadata.session = @"";
        metadata.sessionError = @"";
        metadata.sessionSelector = @"";
        metadata.sessionTaskIdentifier = k_taskIdentifierDone;
        metadata.status = k_metadataStatusNormal;
            
        metadata = [[NCManageDatabase sharedInstance] updateMetadata:metadata];
        [[NCManageDatabase sharedInstance] addLocalFileWithMetadata:metadata];
        
        // E2EE Decrypted
        tableE2eEncryption *object = [[NCManageDatabase sharedInstance] getE2eEncryptionWithPredicate:[NSPredicate predicateWithFormat:@"fileNameIdentifier == %@ AND serverUrl == %@", fileName, serverUrl]];
        if (object) {
            BOOL result = [[NCEndToEndEncryption sharedManager] decryptFileName:metadata.fileName fileNameView:metadata.fileNameView ocId:metadata.ocId key:object.key initializationVector:object.initializationVector authenticationTag:object.authenticationTag];
            if (!result) {
                
                if ([self.delegate respondsToSelector:@selector(downloadFileSuccessFailure:ocId:serverUrl:selector:errorMessage:errorCode:)]) {
                    [self.delegate downloadFileSuccessFailure:fileName ocId:ocId serverUrl:serverUrl selector:selector errorMessage:[NSString stringWithFormat:@"Serious error internal download : decrypt error %@", fileName] errorCode:k_CCErrorInternalError];
                }
                
                return;
            }
        }
        
        // Exif
        if ([metadata.typeFile isEqualToString: k_metadataTypeFile_image])
            [[CCExifGeo sharedInstance] setExifLocalTableEtag:metadata];
        
        // Icon
        if ([[NSFileManager defaultManager] fileExistsAtPath:[CCUtility getDirectoryProviderStorageIconOcId:metadata.ocId fileNameView:metadata.fileNameView]] == NO) {
            [CCGraphics createNewImageFrom:metadata.fileNameView ocId:metadata.ocId extension:[metadata.fileNameView pathExtension] filterGrayScale:NO typeFile:metadata.typeFile writeImage:YES];
        }
        
        if ([self.delegate respondsToSelector:@selector(downloadFileSuccessFailure:ocId:serverUrl:selector:errorMessage:errorCode:)]) {
            [self.delegate downloadFileSuccessFailure:fileName ocId:ocId serverUrl:serverUrl selector:selector errorMessage:@"" errorCode:0];
        }
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark =====  Upload =====
#pragma --------------------------------------------------------------------------------------------

- (void)uploadFile:(tableMetadata *)metadata taskStatus:(NSInteger)taskStatus
{
    // Password nil
    if ([CCUtility getPassword:metadata.account].length == 0) {
        [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:NSLocalizedString(@"_bad_username_password_", nil) errorCode:kOCErrorServerUnauthorized];
        return;
    } else if ([CCUtility getCertificateError:metadata.account]) {
        [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:NSLocalizedString(@"_ssl_certificate_untrusted_", nil) errorCode:NSURLErrorServerCertificateUntrusted];
        return;
    }
    
    tableAccount *tableAccount = [[NCManageDatabase sharedInstance] getAccountWithPredicate:[NSPredicate predicateWithFormat:@"account == %@", metadata.account]];
    if (tableAccount == nil) {
        [[NCManageDatabase sharedInstance] deleteMetadataWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
        
        if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
            [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:@"Upload error, account not found" errorCode:k_CCErrorInternalError];
        }
        return;
    }
    
    if ([CCUtility fileProviderStorageExists:metadata.ocId fileNameView:metadata.fileNameView] == NO) {
    
        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[metadata.assetLocalIdentifier] options:nil];
        
        if (!result.count) {
            [[NCManageDatabase sharedInstance] deleteMetadataWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
            
            if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
                [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:@"Error photo/video not found, remove from upload" errorCode:k_CCErrorInternalError];
            }
            
            return;
        }
        
        PHAsset *asset= result[0];
        
        // IMAGE
        if (asset.mediaType == PHAssetMediaTypeImage) {
            
            PHImageRequestOptions *options = [PHImageRequestOptions new];
            options.networkAccessAllowed = YES; // iCloud
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.synchronous = YES;
            options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                
                NSLog(@"cacheAsset: %f", progress);
                
                if (error) {
                    [[NCManageDatabase sharedInstance] deleteMetadataWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
                
                    if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
                        [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:[NSString stringWithFormat:@"Image request iCloud failed [%@]", error.description] errorCode:error.code];
                    }
                }
            };
            
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                
                NSError *error = nil;
                NSString *extensionAsset = [[[asset valueForKey:@"filename"] pathExtension] uppercaseString];
                
                if ([extensionAsset isEqualToString:@"HEIC"] && [CCUtility getFormatCompatibility]) {
                    
                    CIImage *ciImage = [CIImage imageWithData:imageData];
                    CIContext *context = [CIContext context];
                    imageData = [context JPEGRepresentationOfImage:ciImage colorSpace:ciImage.colorSpace options:@{}];
                    NSString *fileNameJPEG = [[metadata.fileName lastPathComponent] stringByDeletingPathExtension];
                    metadata.fileName = [fileNameJPEG stringByAppendingString:@".jpg"];
                    metadata.fileNameView = metadata.fileName;
                    
                    // Change Metadata with new ocId, fileName, fileNameView
                    [[NCManageDatabase sharedInstance] deleteMetadataWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
                    metadata.ocId = [CCUtility createMetadataIDFromAccount:metadata.account serverUrl:metadata.serverUrl fileNameView:metadata.fileNameView directory:false];
                }
                
                tableMetadata *metadataForUpload = [[NCManageDatabase sharedInstance] addMetadata:[CCUtility insertFileSystemInMetadata:metadata]];
                [imageData writeToFile:[CCUtility getDirectoryProviderStorageOcId:metadataForUpload.ocId fileNameView:metadataForUpload.fileNameView] options:NSDataWritingAtomic error:&error];

                if (error) {
                    [[NCManageDatabase sharedInstance] deleteMetadataWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadataForUpload.ocId]];
                    
                    if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
                        [self.delegate uploadFileSuccessFailure:metadataForUpload.fileName ocId:metadataForUpload.ocId assetLocalIdentifier:metadataForUpload.assetLocalIdentifier serverUrl:metadataForUpload.serverUrl selector:metadataForUpload.sessionSelector errorMessage:[NSString stringWithFormat:@"Image request failed [%@]", error.description] errorCode:error.code];
                    }
                    
                } else {
                    
                    // OOOOOK
                    if ([CCUtility isFolderEncrypted:metadataForUpload.serverUrl account:tableAccount.account] && [CCUtility isEndToEndEnabled:tableAccount.account]) {
                        [self e2eEncryptedFile:metadataForUpload tableAccount:tableAccount taskStatus:taskStatus];
                    } else {
                        [self uploadURLSessionMetadata:metadataForUpload tableAccount:tableAccount taskStatus:taskStatus];
                    }
                }
            }];
        }
        
        // VIDEO
        if (asset.mediaType == PHAssetMediaTypeVideo) {
            
            PHVideoRequestOptions *options = [PHVideoRequestOptions new];
            options.networkAccessAllowed = YES;
            options.version = PHVideoRequestOptionsVersionOriginal;
            options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                
                NSLog(@"cacheAsset: %f", progress);
                
                if (error) {
                    [[NCManageDatabase sharedInstance] deleteMetadataWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
                    
                    if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
                        [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:[NSString stringWithFormat:@"Video request iCloud failed [%@]", error.description] errorCode:error.code];
                    }
                }
            };
            
            [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
                
                if ([asset isKindOfClass:[AVURLAsset class]]) {
                    
                    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:[CCUtility getDirectoryProviderStorageOcId:metadata.ocId fileNameView:metadata.fileNameView]];
                    NSError *error = nil;
                    
                    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
                    [[NSFileManager defaultManager] copyItemAtURL:[(AVURLAsset *)asset URL] toURL:fileURL error:&error];
                    
                    if (error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NCManageDatabase sharedInstance] deleteMetadataWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
                            
                            if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
                                [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:[NSString stringWithFormat:@"Video request failed [%@]", error.description] errorCode:error.code];
                            }
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            // create Metadata for Upload
                            tableMetadata *metadataForUpload = [[NCManageDatabase sharedInstance] addMetadata:[CCUtility insertFileSystemInMetadata:metadata]];
                            
                            // OOOOOK
                            if ([CCUtility isFolderEncrypted:metadataForUpload.serverUrl account:tableAccount.account] && [CCUtility isEndToEndEnabled:tableAccount.account]) {
                                [self e2eEncryptedFile:metadataForUpload tableAccount:tableAccount taskStatus:taskStatus];
                            } else {
                                [self uploadURLSessionMetadata:metadataForUpload tableAccount:tableAccount taskStatus:taskStatus];
                            }
                        });
                    }
                }
            }];
        }
        
    } else {
        
        // create Metadata for Upload
        tableMetadata *metadataForUpload = [[NCManageDatabase sharedInstance] addMetadata:[CCUtility insertFileSystemInMetadata:metadata]];
        
        // OOOOOK
        if ([CCUtility isFolderEncrypted:metadataForUpload.serverUrl account:tableAccount.account] && [CCUtility isEndToEndEnabled:tableAccount.account]) {
            [self e2eEncryptedFile:metadataForUpload tableAccount:tableAccount taskStatus:taskStatus];
        } else {
            [self uploadURLSessionMetadata:metadataForUpload tableAccount:tableAccount taskStatus:taskStatus];
        }
    }
}

- (void)e2eEncryptedFile:(tableMetadata *)metadata tableAccount:(tableAccount *)tableAccount taskStatus:(NSInteger)taskStatus
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSError *error;
        NSString *fileNameIdentifier;
        NSString *key;
        NSString *initializationVector;
        NSString *authenticationTag;
        NSString *metadataKey;
        NSInteger metadataKeyIndex;
        NSString *e2eeMetadata;

        // Verify File Size
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[CCUtility getDirectoryProviderStorageOcId:metadata.ocId fileNameView:metadata.fileNameView] error:&error];
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        long long fileSize = [fileSizeNumber longLongValue];

        if (fileSize > k_max_filesize_E2EE) {
            // Error for uploadFileFailure
            if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
                [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:@"E2E Error file too big" errorCode:k_CCErrorInternalError];
            }
            return;
        }
        
        // if new file upload create a new encrypted filename
        if ([metadata.ocId isEqualToString:[CCUtility createMetadataIDFromAccount:metadata.account serverUrl:metadata.serverUrl fileNameView:metadata.fileNameView directory:false]]) {
            fileNameIdentifier = [CCUtility generateRandomIdentifier];
        } else {
            fileNameIdentifier = metadata.fileName;
        }
        
        if ([[NCEndToEndEncryption sharedManager] encryptFileName:metadata.fileNameView fileNameIdentifier:fileNameIdentifier directory:[CCUtility getDirectoryProviderStorageOcId:metadata.ocId] key:&key initializationVector:&initializationVector authenticationTag:&authenticationTag]) {
            
            tableE2eEncryption *object = [[NCManageDatabase sharedInstance] getE2eEncryptionWithPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND serverUrl == %@", tableAccount.account, metadata.serverUrl]];
            if (object) {
                metadataKey = object.metadataKey;
                metadataKeyIndex = object.metadataKeyIndex;
            } else {
                metadataKey = [[[NCEndToEndEncryption sharedManager] generateKey:16] base64EncodedStringWithOptions:0]; // AES_KEY_128_LENGTH
                metadataKeyIndex = 0;
            }
            
            tableE2eEncryption *addObject = [tableE2eEncryption new];
            
            addObject.account = tableAccount.account;
            addObject.authenticationTag = authenticationTag;
            addObject.fileName = metadata.fileNameView;
            addObject.fileNameIdentifier = fileNameIdentifier;
            addObject.fileNamePath = [CCUtility returnFileNamePathFromFileName:metadata.fileNameView serverUrl:metadata.serverUrl activeUrl:tableAccount.url];
            addObject.key = key;
            addObject.initializationVector = initializationVector;
            addObject.metadataKey = metadataKey;
            addObject.metadataKeyIndex = metadataKeyIndex;
            
            CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[metadata.fileNameView pathExtension], NULL);
            CFStringRef mimeTypeRef = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
            if (mimeTypeRef) {
                addObject.mimeType = (__bridge NSString *)mimeTypeRef;
            } else {
                addObject.mimeType = @"application/octet-stream";
            }
            
            addObject.serverUrl = metadata.serverUrl;
            addObject.version = [[NCManageDatabase sharedInstance] getEndToEndEncryptionVersionWithAccount:tableAccount.account];
            
            // Get the last metadata
            tableDirectory *directory = [[NCManageDatabase sharedInstance] getTableDirectoryWithPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND serverUrl == %@", tableAccount.account, metadata.serverUrl]];
            
            error = [[NCNetworkingEndToEnd sharedManager] getEndToEndMetadata:&e2eeMetadata ocId:directory.ocId user:tableAccount.user userID:tableAccount.userID password: [CCUtility getPassword:tableAccount.account] url:tableAccount.url];
            if (error == nil) {
                if ([[NCEndToEndMetadata sharedInstance] decoderMetadata:e2eeMetadata privateKey:[CCUtility getEndToEndPrivateKey:tableAccount.account] serverUrl:metadata.serverUrl account:tableAccount.account url:tableAccount.url] == false) {
                    
                    if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
                        [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:NSLocalizedString(@"_e2e_error_decode_metadata_", nil) errorCode:k_CCErrorInternalError];
                    }
                    return;
                }
            }
            
            // write new record e2ee
            if([[NCManageDatabase sharedInstance] addE2eEncryption:addObject] == NO) {
                
                if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
                    [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:NSLocalizedString(@"_e2e_error_create_encrypted_", nil) errorCode:k_CCErrorInternalError];
                }
                return;
            }
            
        } else {
            
            if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
                [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:NSLocalizedString(@"_e2e_error_create_encrypted_", nil) errorCode:k_CCErrorInternalError];
            }
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Now the fileName is fileNameIdentifier && flag e2eEncrypted
            metadata.fileName = fileNameIdentifier;
            metadata.e2eEncrypted = YES;
            
            // Update Metadata
            tableMetadata *metadataEncrypted = [[NCManageDatabase sharedInstance] addMetadata:metadata];
            
            [self uploadURLSessionMetadata:metadataEncrypted tableAccount:tableAccount taskStatus:taskStatus];
        });
    });
}

- (void)uploadURLSessionMetadata:(tableMetadata *)metadata tableAccount:(tableAccount *)tableAccount taskStatus:(NSInteger)taskStatus
{
    NSURL *url;
    NSMutableURLRequest *request;
    PHAsset *asset;
    NSError *error;
    
    // calculate and store file size
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[CCUtility getDirectoryProviderStorageOcId:metadata.ocId fileNameView:metadata.fileName] error:&error];
    long long fileSize = [[fileAttributes objectForKey:NSFileSize] longLongValue];
    metadata.size = fileSize;
    (void)[[NCManageDatabase sharedInstance] addMetadata:metadata];
    
    url = [NSURL URLWithString:[[NSString stringWithFormat:@"%@/%@", metadata.serverUrl, metadata.fileName] encodeString:NSUTF8StringEncoding]];
    request = [NSMutableURLRequest requestWithURL:url];
        
    NSData *authData = [[NSString stringWithFormat:@"%@:%@", tableAccount.user, [CCUtility getPassword:tableAccount.account]] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat: @"Basic %@",[authData base64EncodedStringWithOptions:0]];
    [request setHTTPMethod:@"PUT"];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    [request setValue:[CCUtility getUserAgent] forHTTPHeaderField:@"User-Agent"];

    // Create Image for Upload (gray scale)
#ifndef EXTENSION
    [CCGraphics createNewImageFrom:metadata.fileNameView ocId:metadata.ocId extension:[metadata.fileNameView pathExtension] filterGrayScale:YES typeFile:metadata.typeFile writeImage:YES];
#endif
    
    // Change date file upload with header : X-OC-Mtime (ctime assetLocalIdentifier) image/video
    if (metadata.assetLocalIdentifier) {
        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[metadata.assetLocalIdentifier] options:nil];
        if (result.count) {
            asset = result[0];
            long dateFileCreation = [asset.creationDate timeIntervalSince1970];
            [request setValue:[NSString stringWithFormat:@"%ld", dateFileCreation] forHTTPHeaderField:@"X-OC-Mtime"];
        }
    }
    
    NSURLSession *sessionUpload;
    
    // NSURLSession
    if ([metadata.session isEqualToString:k_upload_session]) sessionUpload = [self sessionUpload];
    else if ([metadata.session isEqualToString:k_upload_session_wwan]) sessionUpload = [self sessionWWanUpload];
    else if ([metadata.session isEqualToString:k_upload_session_foreground]) sessionUpload = [self sessionUploadForeground];
    else if ([metadata.session isEqualToString:k_upload_session_extension]) sessionUpload = [self sessionUploadExtension];
    
    NSURLSessionUploadTask *uploadTask = [sessionUpload uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:[CCUtility getDirectoryProviderStorageOcId:metadata.ocId fileNameView:metadata.fileName]]];
    
    // Error
    if (uploadTask == nil) {
        
        NSString *messageError = @"Serious internal error uploadTask not available";
        [[NCManageDatabase sharedInstance] setMetadataSession:metadata.session sessionError:messageError sessionSelector:nil sessionTaskIdentifier:k_taskIdentifierDone status:k_metadataStatusUploadError predicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
        
        if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
            [self.delegate uploadFileSuccessFailure:metadata.fileNameView ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:messageError errorCode:k_CCErrorInternalError];
        }
        
    } else {
        
        // E2EE : CREATE AND SEND METADATA
        if ([CCUtility isFolderEncrypted:metadata.serverUrl account:tableAccount.account] && [CCUtility isEndToEndEnabled:tableAccount.account]) {
            
            NSString *serverUrl = metadata.serverUrl;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                
                // Send Metadata
                NSError *error = [[NCNetworkingEndToEnd sharedManager] sendEndToEndMetadataOnServerUrl:serverUrl fileNameRename:nil fileNameNewRename:nil account:tableAccount.account user:tableAccount.user userID:tableAccount.userID password:[CCUtility getPassword:tableAccount.account] url:tableAccount.url];
                
                dispatch_async(dispatch_get_main_queue(), ^{

                    if (error) {
                    
                        [uploadTask cancel];

                        NSString *messageError = [NSString stringWithFormat:@"%@ (%d)", error.localizedDescription, (int)error.code];
                        [[NCManageDatabase sharedInstance] setMetadataSession:metadata.session sessionError:messageError sessionSelector:nil sessionTaskIdentifier:k_taskIdentifierDone status:k_metadataStatusUploadError predicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
                        
                        if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
                            [self.delegate uploadFileSuccessFailure:metadata.fileNameView ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:metadata.serverUrl selector:metadata.sessionSelector errorMessage:messageError errorCode:k_CCErrorInternalError];
                        }
                        
                    } else {
                    
                        // Manage uploadTask cancel,suspend,resume
                        if (taskStatus == k_taskStatusCancel) [uploadTask cancel];
                        else if (taskStatus == k_taskStatusSuspend) [uploadTask suspend];
                        else if (taskStatus == k_taskStatusResume) [uploadTask resume];
                        
                        // *** E2EE ***
                        [[NCManageDatabase sharedInstance] setMetadataSession:metadata.session sessionError:@"" sessionSelector:nil sessionTaskIdentifier:uploadTask.taskIdentifier status:k_metadataStatusUploading predicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
                        
                        NSLog(@"[LOG] Upload file %@ TaskIdentifier %lu", metadata.fileName, (unsigned long)uploadTask.taskIdentifier);
                        
                        NSString *ocId = metadata.ocId;
                        NSString *account = metadata.account;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([self.delegate respondsToSelector:@selector(uploadStart:account:task:serverUrl:)]) {
                                [self.delegate uploadStart:ocId account:account task:uploadTask serverUrl:metadata.serverUrl];
                            }
                        });
                    }
                });
            });
            
         } else {
    
             // Manage uploadTask cancel,suspend,resume
             if (taskStatus == k_taskStatusCancel) [uploadTask cancel];
             else if (taskStatus == k_taskStatusSuspend) [uploadTask suspend];
             else if (taskStatus == k_taskStatusResume) [uploadTask resume];
             
             // *** PLAIN ***
             [[NCManageDatabase sharedInstance] setMetadataSession:metadata.session sessionError:@"" sessionSelector:nil sessionTaskIdentifier:uploadTask.taskIdentifier status:k_metadataStatusUploading predicate:[NSPredicate predicateWithFormat:@"ocId == %@", metadata.ocId]];
             
             NSLog(@"[LOG] Upload file %@ TaskIdentifier %lu", metadata.fileName, (unsigned long)uploadTask.taskIdentifier);
             
             NSString *ocId = metadata.ocId;
             NSString *account = metadata.account;
             NSString *serverUrl = metadata.serverUrl;
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 if ([self.delegate respondsToSelector:@selector(uploadStart:account:task:serverUrl:)]) {
                     [self.delegate uploadStart:ocId account:account task:uploadTask serverUrl:serverUrl];
                 }
             });
         }
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    NSString *url = [[[task currentRequest].URL absoluteString] stringByRemovingPercentEncoding];
    NSString *fileName = [url lastPathComponent];
    NSString *serverUrl = [self getServerUrlFromUrl:url];
    if (!serverUrl) return;
    
    if (totalBytesExpectedToSend < 1) {
        totalBytesExpectedToSend = totalBytesSent;
    }
    
    float progress = (float) totalBytesSent / (float)totalBytesExpectedToSend;

    tableMetadata *metadata = [[NCManageDatabase sharedInstance] getMetadataInSessionFromFileName:fileName serverUrl:serverUrl taskIdentifier:task.taskIdentifier];
    
    if (metadata) {
        NSDictionary *userInfo = @{@"account": (metadata.account), @"ocId": (metadata.ocId), @"serverUrl": (serverUrl), @"status": ([NSNumber numberWithLong:k_metadataStatusInUpload]), @"progress": ([NSNumber numberWithFloat:progress]), @"totalBytes": ([NSNumber numberWithLongLong:totalBytesSent]), @"totalBytesExpected": ([NSNumber numberWithLongLong:totalBytesExpectedToSend])};
        if (userInfo)
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"NotificationProgressTask" object:nil userInfo:userInfo];
    }
}

- (void)uploadFileSuccessFailure:(tableMetadata *)metadata fileName:(NSString *)fileName ocId:(NSString *)ocId etag:(NSString *)etag date:(NSDate *)date serverUrl:(NSString *)serverUrl errorCode:(NSInteger)errorCode
{
    NSString *tempocId = metadata.ocId;
    NSString *tempSession = metadata.session;
    NSString *errorMessage = @"";
    BOOL isE2EEDirectory = false;
    
    tableAccount *tableAccount = [[NCManageDatabase sharedInstance] getAccountWithPredicate:[NSPredicate predicateWithFormat:@"account == %@", metadata.account]];
    if (tableAccount == nil) {
        [[NCManageDatabase sharedInstance] deleteMetadataWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", tempocId]];

        if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
            [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:serverUrl selector:metadata.sessionSelector errorMessage:errorMessage errorCode:errorCode];
        }
        return;
    }
    
    // is this a E2EE Directory ?
    if ([CCUtility isFolderEncrypted:serverUrl account:tableAccount.account] && [CCUtility isEndToEndEnabled:tableAccount.account]) {
        isE2EEDirectory = true;
    }
    
    // ERRORE
    if (errorCode != 0) {
        
#ifndef EXTENSION
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.listProgressMetadata removeObjectForKey:metadata.ocId];
#endif
        
        // Mark error only if not Cancelled Task
        if (errorCode == kCFURLErrorCancelled)  {
            
            if (metadata.status == k_metadataStatusUploadForcedStart) {
                
                errorCode = 0;
                
                metadata.session = k_upload_session;
                metadata.sessionError = @"";
                metadata.sessionTaskIdentifier = 0;
                metadata.status = k_metadataStatusInUpload;
                metadata = [[NCManageDatabase sharedInstance] addMetadata:metadata];

                [[CCNetworking sharedNetworking] uploadFile:metadata taskStatus:k_taskStatusResume];
                
            } else {
                
                [[NSFileManager defaultManager] removeItemAtPath:[CCUtility getDirectoryProviderStorageOcId:tempocId] error:nil];
                [[NCManageDatabase sharedInstance] deleteMetadataWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", tempocId]];
                
                errorMessage = [CCError manageErrorKCF:errorCode withNumberError:YES];
            }
            
        } else {

            if (metadata && (errorCode == kOCErrorServerUnauthorized || errorCode == kOCErrorServerForbidden))
                [[OCNetworking sharedManager] checkRemoteUser:metadata.account];
            else if (metadata && errorCode == NSURLErrorServerCertificateUntrusted)
                [CCUtility setCertificateError:metadata.account error:YES];
            
            [[NCManageDatabase sharedInstance] setMetadataSession:nil sessionError:[CCError manageErrorKCF:errorCode withNumberError:NO] sessionSelector:nil sessionTaskIdentifier:k_taskIdentifierDone status:k_metadataStatusUploadError predicate:[NSPredicate predicateWithFormat:@"ocId == %@", tempocId]];
            
            errorMessage = [CCError manageErrorKCF:errorCode withNumberError:YES];
        }
        
    } else {
            
        // Replace Metadata
        metadata.date = date;
        if (isE2EEDirectory) {
            metadata.e2eEncrypted = true;
        } else {
            metadata.e2eEncrypted = false;
        }
        metadata.etag = etag;
        metadata.ocId = ocId;
        metadata.session = @"";
        metadata.sessionError = @"";
        metadata.sessionTaskIdentifier = k_taskIdentifierDone;
        metadata.status = k_metadataStatusNormal;
        
        [[NCManageDatabase sharedInstance] deleteMetadataWithPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND serverUrl == %@ AND fileName == %@", metadata.account, metadata.serverUrl, metadata.fileName]];
        metadata = [[NCManageDatabase sharedInstance] addMetadata:metadata];
        
        NSLog(@"[LOG] Insert new upload : %@ - ocId : %@", metadata.fileName, ocId);

        // remove tempocId and adjust the directory provider storage
        if ([tempocId isEqualToString:[CCUtility createMetadataIDFromAccount:metadata.account serverUrl:metadata.serverUrl fileNameView:metadata.fileNameView directory:metadata.directory]]) {
            
            [[NCManageDatabase sharedInstance] deleteMetadataWithPredicate:[NSPredicate predicateWithFormat:@"ocId == %@", tempocId]];
            
            // adjust file system Directory Provider Storage
            if ([tempSession isEqualToString:k_upload_session_extension]) {
                // this is for File Provider Extension [Apple Works and ... ?]
                [CCUtility copyFileAtPath:[NSString stringWithFormat:@"%@/%@", [CCUtility getDirectoryProviderStorage], tempocId] toPath:[NSString stringWithFormat:@"%@/%@", [CCUtility getDirectoryProviderStorage], metadata.ocId]];
            } else {
                [CCUtility moveFileAtPath:[NSString stringWithFormat:@"%@/%@", [CCUtility getDirectoryProviderStorage], tempocId] toPath:[NSString stringWithFormat:@"%@/%@", [CCUtility getDirectoryProviderStorage], metadata.ocId]];
            }
        }
        
#ifndef EXTENSION
        
        // EXIF
        if ([metadata.typeFile isEqualToString: k_metadataTypeFile_image])
            [[CCExifGeo sharedInstance] setExifLocalTableEtag:metadata];
        
        // Create preview
        [CCGraphics createNewImageFrom:metadata.fileNameView ocId:metadata.ocId extension:[metadata.fileNameView pathExtension] filterGrayScale:NO typeFile:metadata.typeFile writeImage:YES];

        // Copy photo or video in the photo album for auto upload
        if ([metadata.assetLocalIdentifier length] > 0 && ([metadata.sessionSelector isEqualToString:selectorUploadAutoUpload] || [metadata.sessionSelector isEqualToString:selectorUploadFile])) {
            
            PHAsset *asset;
            PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[metadata.assetLocalIdentifier] options:nil];
            
            if(result.count){
                asset = result[0];
                
                [asset saveToAlbum:[NCBrandOptions sharedInstance].brand completionBlock:^(BOOL success) {
                    if (success) NSLog(@"[LOG] Insert file %@ in %@", metadata.fileName, [NCBrandOptions sharedInstance].brand);
                    else NSLog(@"[LOG] File %@ do not insert in %@", metadata.fileName, [NCBrandOptions sharedInstance].brand);
                }];
            }
        }
 #endif
        
        // Add Local or Remove from cache
        if ([CCUtility getDisableLocalCacheAfterUpload]) {
            [[NSFileManager defaultManager] removeItemAtPath:[CCUtility getDirectoryProviderStorageOcId:metadata.ocId] error:nil];
        } else {
            // Add Local
            [[NCManageDatabase sharedInstance] addLocalFileWithMetadata:metadata];
        }
    }
    
    // Detect E2EE
    tableMetadata *e2eeMetadataInSession = [[NCManageDatabase sharedInstance] getMetadataWithPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND serverUrl == %@ AND e2eEncrypted == 1 AND (status == %d OR status == %d)", metadata.account, metadata.serverUrl, k_metadataStatusInUpload, k_metadataStatusUploading]];
    
    // E2EE : UNLOCK
    if (isE2EEDirectory && e2eeMetadataInSession == nil) {
        
        tableE2eEncryptionLock *tableLock = [[NCManageDatabase sharedInstance] getE2ETokenLockWithServerUrl:serverUrl];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if (tableLock) {
                
                NSError *error = [[NCNetworkingEndToEnd sharedManager] unlockEndToEndFolderEncryptedOnServerUrl:serverUrl ocId:tableLock.ocId token:tableLock.token user:tableAccount.user userID:tableAccount.userID password:[CCUtility getPassword:tableAccount.account] url:tableAccount.url];
                if (error) {
#ifndef EXTENSION
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [(AppDelegate *)[[UIApplication sharedApplication] delegate] messageNotification:@"_e2e_error_unlock_" description:error.localizedDescription visible:YES delay:k_dismissAfterSecond type:TWMessageBarMessageTypeError errorCode:error.code];
                    });
#endif
                }
            } else {
                NSLog(@"Error unlock not found");
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
                    [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:serverUrl selector:metadata.sessionSelector errorMessage:errorMessage errorCode:errorCode];
                }
            });
        });
    } else {
        
        if ([self.delegate respondsToSelector:@selector(uploadFileSuccessFailure:ocId:assetLocalIdentifier:serverUrl:selector:errorMessage:errorCode:)]) {
            [self.delegate uploadFileSuccessFailure:metadata.fileName ocId:metadata.ocId assetLocalIdentifier:metadata.assetLocalIdentifier serverUrl:serverUrl selector:metadata.sessionSelector errorMessage:errorMessage errorCode:errorCode];
        }
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark =====  Utility =====
#pragma --------------------------------------------------------------------------------------------

- (NSString *)getServerUrlFromUrl:(NSString *)url
{
    NSString *fileName = [url lastPathComponent];
    
    url = [url stringByReplacingOccurrencesOfString:[@"/" stringByAppendingString:fileName] withString:@""];

    return url;
}

@end
