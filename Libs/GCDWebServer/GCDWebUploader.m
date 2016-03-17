/*
 Copyright (c) 2012-2015, Pierre-Olivier Latour
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * The name of Pierre-Olivier Latour may not be used to endorse
 or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#if !__has_feature(objc_arc)
#error GCDWebUploader requires ARC
#endif

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <SystemConfiguration/SystemConfiguration.h>
#endif

#import "GCDWebUploader.h"

#import "GCDWebServerDataRequest.h"
#import "GCDWebServerMultiPartFormRequest.h"
#import "GCDWebServerURLEncodedFormRequest.h"

#import "GCDWebServerDataResponse.h"
#import "GCDWebServerErrorResponse.h"
#import "GCDWebServerFileResponse.h"

@interface GCDWebUploader () {
@private
  NSMutableDictionary *_uploadDirectories;
  NSArray* _allowedExtensions;
  BOOL _allowHidden;
  NSString* _title;
  NSString* _header;
  NSString* _prologue;
  NSString* _epilogue;
  NSString* _footer;
}
@end

@implementation GCDWebUploader (Methods)

// Must match implementation in GCDWebDAVServer
- (BOOL)_checkSandboxedPath:(NSString*)path endpoint:(NSString *)endpoint {
  return [[path stringByStandardizingPath] hasPrefix:_uploadDirectories[endpoint]];
}

- (BOOL)_checkFileExtension:(NSString*)fileName {
  if (_allowedExtensions && ![_allowedExtensions containsObject:[[fileName pathExtension] lowercaseString]]) {
    return NO;
  }
  return YES;
}

- (NSString*) _uniquePathForPath:(NSString*)path {
  if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
    NSString* directory = [path stringByDeletingLastPathComponent];
    NSString* file = [path lastPathComponent];
    NSString* base = [file stringByDeletingPathExtension];
    NSString* extension = [file pathExtension];
    int retries = 0;
    do {
      if (extension.length) {
        path = [directory stringByAppendingPathComponent:[[base stringByAppendingFormat:@" (%i)", ++retries] stringByAppendingPathExtension:extension]];
      } else {
        path = [directory stringByAppendingPathComponent:[base stringByAppendingFormat:@" (%i)", ++retries]];
      }
    } while ([[NSFileManager defaultManager] fileExistsAtPath:path]);
  }
  return path;
}

- (GCDWebServerResponse*)listDirectory:(GCDWebServerRequest*)request endpoint:(NSString *)endpoint {
  NSString* relativePath = [[request query] objectForKey:@"path"];
  NSString* absolutePath = [_uploadDirectories[endpoint] stringByAppendingPathComponent:relativePath];
  BOOL isDirectory = NO;
  if (![self _checkSandboxedPath:absolutePath endpoint:endpoint] || ![[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:&isDirectory]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", relativePath];
  }
  if (!isDirectory) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"\"%@\" is not a directory", relativePath];
  }
  
  NSString* directoryName = [absolutePath lastPathComponent];
  if (!_allowHidden && [directoryName hasPrefix:@"."]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Listing directory name \"%@\" is not allowed", directoryName];
  }
  
  NSError* error = nil;
  NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:absolutePath error:&error];
  if (contents == nil) {
    return [GCDWebServerErrorResponse responseWithServerError:kGCDWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed listing directory \"%@\"", relativePath];
  }
  
  NSMutableArray* array = [NSMutableArray array];
  for (NSString* item in [contents sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
    if (_allowHidden || ![item hasPrefix:@"."]) {
      NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[absolutePath stringByAppendingPathComponent:item] error:NULL];
      NSString* type = [attributes objectForKey:NSFileType];
      if ([type isEqualToString:NSFileTypeRegular] && [self _checkFileExtension:item]) {
        [array addObject:@{
                           @"path": [relativePath stringByAppendingPathComponent:item],
                           @"name": item,
                           @"size": [attributes objectForKey:NSFileSize]
                           }];
      } else if ([type isEqualToString:NSFileTypeDirectory]) {
        [array addObject:@{
                           @"path": [[relativePath stringByAppendingPathComponent:item] stringByAppendingString:@"/"],
                           @"name": item
                           }];
      }
    }
  }
  return [GCDWebServerDataResponse responseWithJSONObject:array];
}

- (GCDWebServerResponse*)downloadFile:(GCDWebServerRequest*)request endpoint:(NSString *)endpoint {
  NSString* relativePath = [[request query] objectForKey:@"path"];
  NSString* absolutePath = [_uploadDirectories[endpoint] stringByAppendingPathComponent:relativePath];
  BOOL isDirectory = NO;
  if (![self _checkSandboxedPath:absolutePath endpoint:endpoint] || ![[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:&isDirectory]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", relativePath];
  }
  if (isDirectory) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"\"%@\" is a directory", relativePath];
  }
  
  NSString* fileName = [absolutePath lastPathComponent];
  if (([fileName hasPrefix:@"."] && !_allowHidden) || ![self _checkFileExtension:fileName]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Downlading file name \"%@\" is not allowed", fileName];
  }
  
  if ([self.delegate respondsToSelector:@selector(webUploader:didDownloadFileAtPath:  )]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate webUploader:self didDownloadFileAtPath:absolutePath];
    });
  }
  return [GCDWebServerFileResponse responseWithFile:absolutePath isAttachment:YES];
}

- (GCDWebServerResponse*)uploadFile:(GCDWebServerMultiPartFormRequest*)request endpoint:(NSString *)endpoint {
  NSRange range = [[request.headers objectForKey:@"Accept"] rangeOfString:@"application/json" options:NSCaseInsensitiveSearch];
  NSString* contentType = (range.location != NSNotFound ? @"application/json" : @"text/plain; charset=utf-8");  // Required when using iFrame transport (see https://github.com/blueimp/jQuery-File-Upload/wiki/Setup)
  
  GCDWebServerMultiPartFile* file = [request firstFileForControlName:@"files[]"];
  if ((!_allowHidden && [file.fileName hasPrefix:@"."]) || ![self _checkFileExtension:file.fileName]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Uploaded file name \"%@\" is not allowed", file.fileName];
  }
  NSString* relativePath = [[request firstArgumentForControlName:@"path"] string];
  NSString* absolutePath = [self _uniquePathForPath:[[_uploadDirectories[endpoint] stringByAppendingPathComponent:relativePath] stringByAppendingPathComponent:file.fileName]];
  if (![self _checkSandboxedPath:absolutePath endpoint:endpoint]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", relativePath];
  }
  
  if (![self shouldUploadFileAtPath:absolutePath withTemporaryFile:file.temporaryPath]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Uploading file \"%@\" to \"%@\" is not permitted", file.fileName, relativePath];
  }
  
  NSError* error = nil;
  if (![[NSFileManager defaultManager] moveItemAtPath:file.temporaryPath toPath:absolutePath error:&error]) {
    return [GCDWebServerErrorResponse responseWithServerError:kGCDWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed moving uploaded file to \"%@\"", relativePath];
  }
  
  if ([self.delegate respondsToSelector:@selector(webUploader:didUploadFileAtPath:)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate webUploader:self didUploadFileAtPath:absolutePath];
    });
  }
  return [GCDWebServerDataResponse responseWithJSONObject:@{} contentType:contentType];
}

- (GCDWebServerResponse*)moveItem:(GCDWebServerURLEncodedFormRequest*)request endpoint:(NSString *)endpoint {
  NSString* oldRelativePath = [request.arguments objectForKey:@"oldPath"];
  NSString* oldAbsolutePath = [_uploadDirectories[endpoint] stringByAppendingPathComponent:oldRelativePath];
  BOOL isDirectory = NO;
  if (![self _checkSandboxedPath:oldAbsolutePath endpoint:endpoint] || ![[NSFileManager defaultManager] fileExistsAtPath:oldAbsolutePath isDirectory:&isDirectory]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", oldRelativePath];
  }
  
  NSString* newRelativePath = [request.arguments objectForKey:@"newPath"];
  NSString* newAbsolutePath = [self _uniquePathForPath:[_uploadDirectories[endpoint] stringByAppendingPathComponent:newRelativePath]];
  if (![self _checkSandboxedPath:newAbsolutePath endpoint:endpoint]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", newRelativePath];
  }
  
  NSString* itemName = [newAbsolutePath lastPathComponent];
  if ((!_allowHidden && [itemName hasPrefix:@"."]) || (!isDirectory && ![self _checkFileExtension:itemName])) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Moving to item name \"%@\" is not allowed", itemName];
  }
  
  if (![self shouldMoveItemFromPath:oldAbsolutePath toPath:newAbsolutePath]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Moving \"%@\" to \"%@\" is not permitted", oldRelativePath, newRelativePath];
  }
  
  NSError* error = nil;
  if (![[NSFileManager defaultManager] moveItemAtPath:oldAbsolutePath toPath:newAbsolutePath error:&error]) {
    return [GCDWebServerErrorResponse responseWithServerError:kGCDWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed moving \"%@\" to \"%@\"", oldRelativePath, newRelativePath];
  }
  
  if ([self.delegate respondsToSelector:@selector(webUploader:didMoveItemFromPath:toPath:)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate webUploader:self didMoveItemFromPath:oldAbsolutePath toPath:newAbsolutePath];
    });
  }
  return [GCDWebServerDataResponse responseWithJSONObject:@{}];
}

- (GCDWebServerResponse*)deleteItem:(GCDWebServerURLEncodedFormRequest*)request endpoint:(NSString *)endpoint {
  NSString* relativePath = [request.arguments objectForKey:@"path"];
  NSString* absolutePath = [_uploadDirectories[endpoint] stringByAppendingPathComponent:relativePath];
  BOOL isDirectory = NO;
  if (![self _checkSandboxedPath:absolutePath endpoint:endpoint] || ![[NSFileManager defaultManager] fileExistsAtPath:absolutePath isDirectory:&isDirectory]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", relativePath];
  }
  
  NSString* itemName = [absolutePath lastPathComponent];
  if (([itemName hasPrefix:@"."] && !_allowHidden) || (!isDirectory && ![self _checkFileExtension:itemName])) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Deleting item name \"%@\" is not allowed", itemName];
  }
  
  if (![self shouldDeleteItemAtPath:absolutePath]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Deleting \"%@\" is not permitted", relativePath];
  }
  
  NSError* error = nil;
  if (![[NSFileManager defaultManager] removeItemAtPath:absolutePath error:&error]) {
    return [GCDWebServerErrorResponse responseWithServerError:kGCDWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed deleting \"%@\"", relativePath];
  }
  
  if ([self.delegate respondsToSelector:@selector(webUploader:didDeleteItemAtPath:)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate webUploader:self didDeleteItemAtPath:absolutePath];
    });
  }
  return [GCDWebServerDataResponse responseWithJSONObject:@{}];
}

- (GCDWebServerResponse*)createDirectory:(GCDWebServerURLEncodedFormRequest*)request endpoint:(NSString *)endpoint {
  NSString* relativePath = [request.arguments objectForKey:@"path"];
  NSString* absolutePath = [self _uniquePathForPath:[_uploadDirectories[endpoint] stringByAppendingPathComponent:relativePath]];
  if (![self _checkSandboxedPath:absolutePath endpoint:endpoint]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", relativePath];
  }
  
  NSString* directoryName = [absolutePath lastPathComponent];
  if (!_allowHidden && [directoryName hasPrefix:@"."]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Creating directory name \"%@\" is not allowed", directoryName];
  }
  
  if (![self shouldCreateDirectoryAtPath:absolutePath]) {
    return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_Forbidden message:@"Creating directory \"%@\" is not permitted", relativePath];
  }
  
  NSError* error = nil;
  if (![[NSFileManager defaultManager] createDirectoryAtPath:absolutePath withIntermediateDirectories:NO attributes:nil error:&error]) {
    return [GCDWebServerErrorResponse responseWithServerError:kGCDWebServerHTTPStatusCode_InternalServerError underlyingError:error message:@"Failed creating directory \"%@\"", relativePath];
  }
  
  if ([self.delegate respondsToSelector:@selector(webUploader:didCreateDirectoryAtPath:)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate webUploader:self didCreateDirectoryAtPath:absolutePath];
    });
  }
  return [GCDWebServerDataResponse responseWithJSONObject:@{}];
}

@end

@implementation GCDWebUploader
{
    NSBundle *_siteBundle;
}

@synthesize uploadDirectory=_uploadDirectory, allowedFileExtensions=_allowedExtensions, allowHiddenItems=_allowHidden,
            title=_title, header=_header, prologue=_prologue, epilogue=_epilogue, footer=_footer;

@dynamic delegate;

- (instancetype)init
{
    if (self = [super init]) {
        _uploadDirectories = [NSMutableDictionary dictionary];
        
        // Resource files
        _siteBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[GCDWebUploader class]] pathForResource:@"GCDWebUploader" ofType:@"bundle"]];
        [self addGETHandlerForBasePath:@"/" directoryPath:[_siteBundle resourcePath] indexFilename:nil cacheAge:3600 allowRangeRequests:NO];
    }
    
    return self;
}

- (void)addDirectory:(NSString *)p endpoint:(NSString *)endp
{
    NSString *path = [NSString stringWithString:p];
    NSString *endpoint = [NSString stringWithString:endp];
    
    _uploadDirectories[endpoint] = [[path stringByStandardizingPath] copy];
    GCDWebUploader* __unsafe_unretained server = self;
    
    typeof(_siteBundle) __weak weakSiteBundle = _siteBundle;
    
    // Web page
    [self addHandlerForMethod:@"GET" path:endpoint requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
#if TARGET_OS_IPHONE
        NSString* device = [[UIDevice currentDevice] name];
#else
        NSString* device = CFBridgingRelease(SCDynamicStoreCopyComputerName(NULL, NULL));
#endif
        NSString* title = server.title;
        if (title == nil) {
            title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
            if (title == nil) {
                title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
            }
#if !TARGET_OS_IPHONE
            if (title == nil) {
                title = [[NSProcessInfo processInfo] processName];
            }
#endif
        }
        NSString* header = server.header;
        if (header == nil) {
            header = title;
        }
        NSString* prologue = server.prologue;
        if (prologue == nil) {
            prologue = [weakSiteBundle localizedStringForKey:@"PROLOGUE" value:@"" table:nil];
        }
        NSString* epilogue = server.epilogue;
        if (epilogue == nil) {
            epilogue = [weakSiteBundle localizedStringForKey:@"EPILOGUE" value:@"" table:nil];
        }
        NSString* footer = server.footer;
        if (footer == nil) {
            NSString* name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
            NSString* version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#if !TARGET_OS_IPHONE
            if (!name && !version) {
                name = @"OS X";
                version = [[NSProcessInfo processInfo] operatingSystemVersionString];
            }
#endif
            footer = [NSString stringWithFormat:[weakSiteBundle localizedStringForKey:@"FOOTER_FORMAT" value:@"" table:nil], name, version];
        }
        return [GCDWebServerDataResponse responseWithHTMLTemplate:[weakSiteBundle pathForResource:@"index" ofType:@"html"]
                                                        variables:@{
                                                                    @"device": device,
                                                                    @"title": title,
                                                                    @"header": header,
                                                                    @"prologue": prologue,
                                                                    @"epilogue": epilogue,
                                                                    @"footer": footer
                                                                    }];
        
    }];
    
    // File listing
    [self addHandlerForMethod:@"GET" path:[NSString stringWithFormat:@"%@/list", endpoint] requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        return [server listDirectory:request endpoint:endpoint];
    }];
    
    // File download
    [self addHandlerForMethod:@"GET" path:[NSString stringWithFormat:@"%@/download", endpoint] requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        return [server downloadFile:request endpoint:endpoint];
    }];
    
    // File upload
    [self addHandlerForMethod:@"POST" path:[NSString stringWithFormat:@"%@/upload", endpoint] requestClass:[GCDWebServerMultiPartFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        return [server uploadFile:(GCDWebServerMultiPartFormRequest*)request endpoint:endpoint];
    }];
    
    // File and folder moving
    [self addHandlerForMethod:@"POST" path:[NSString stringWithFormat:@"%@/move", endpoint] requestClass:[GCDWebServerURLEncodedFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        return [server moveItem:(GCDWebServerURLEncodedFormRequest*)request endpoint:endpoint];
    }];
    
    // File and folder deletion
    [self addHandlerForMethod:@"POST" path:[NSString stringWithFormat:@"%@/delete", endpoint] requestClass:[GCDWebServerURLEncodedFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        return [server deleteItem:(GCDWebServerURLEncodedFormRequest*)request endpoint:endpoint];
    }];
    
    // Directory creation
    [self addHandlerForMethod:@"POST" path:[NSString stringWithFormat:@"%@/create", endpoint] requestClass:[GCDWebServerURLEncodedFormRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        return [server createDirectory:(GCDWebServerURLEncodedFormRequest*)request endpoint:endpoint];
    }];
}

@end

@implementation GCDWebUploader (Subclassing)

- (BOOL)shouldUploadFileAtPath:(NSString*)path withTemporaryFile:(NSString*)tempPath {
  return YES;
}

- (BOOL)shouldMoveItemFromPath:(NSString*)fromPath toPath:(NSString*)toPath {
  return YES;
}

- (BOOL)shouldDeleteItemAtPath:(NSString*)path {
  return YES;
}

- (BOOL)shouldCreateDirectoryAtPath:(NSString*)path {
  return YES;
}

@end
