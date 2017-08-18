//
//  ReferenceRenderer.h
//  MetalTest
//
//  Created by Ceylo on 17/08/2017.
//  Copyright © 2017 Yalir. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReferenceRenderer : NSObject

- (id) initWithImageAtURL:(NSURL *)imgURL;
- (BOOL) render;
- (void) saveOutputTo:(NSString *)path;

@end
