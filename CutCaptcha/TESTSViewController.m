//
//  TESTSViewController.m
//  CutCaptcha
//
//  Created by Jorge Maroto on 16/09/2012.
//  Copyright (c) 2012 Jorge Maroto. All rights reserved.
//

#import "TESTSViewController.h"

@interface UIImage (Crop)
    -(UIImage*) crop:(CGRect)rect;
@end

@implementation UIImage (Crop)
-(UIImage *)crop:(CGRect)rect {
    if (self.scale > 1.0f) {
        rect = CGRectMake(rect.origin.x * self.scale,
                          rect.origin.y * self.scale,
                          rect.size.width * self.scale,
                          rect.size.height * self.scale);
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}
@end

@interface TESTSViewController ()
@property (retain, nonatomic) IBOutlet UIImageView *imageOriginal;
@property (retain, nonatomic) IBOutlet UIImageView *imageCutted;
@end

@implementation TESTSViewController
- (void)viewDidLoad{
    [super viewDidLoad];
    [self reloadImages:nil];
}

- (void)dealloc {
    [_imageOriginal release];
    [_imageCutted release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setImageOriginal:nil];
    [self setImageCutted:nil];
    [super viewDidUnload];
}

- (IBAction)reloadImages:(id)sender {
    UIImage *imageFromInternet = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://www.cmt.es/pmovil/jcaptcha.jpg"]]];
    
    self.imageOriginal.frame = CGRectMake(0, 0, imageFromInternet.size.width, imageFromInternet.size.height);
    self.imageOriginal.image = imageFromInternet;
    
    
    UIImage *imageCropped = [imageFromInternet crop:[self usefulRectangle:imageFromInternet]];
    self.imageCutted.frame = CGRectMake(0, self.imageOriginal.frame.size.height + 10, imageCropped.size.width, imageCropped.size.height);
    self.imageCutted.image = imageCropped;
}


-(CGRect)usefulRectangle:(UIImage *)imageIn{
    CGImageRef image = imageIn.CGImage;
    NSUInteger width = CGImageGetWidth(image);
    NSUInteger height = CGImageGetHeight(image);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = malloc(height * width * 4);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGContextRelease(context);
    
    int x_min, x_max, y_min, y_max;
    x_min = y_min = INT_MAX;
    x_max = y_max = 0;
    NSLog(@"Iniciando");
    for (int x = 0; x <= CGImageGetWidth(image); x++){
        for (int y = 0; y <= CGImageGetHeight(image); y++){
            int byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
            CGFloat red = rawData[byteIndex];
            CGFloat green = rawData[byteIndex + 1];
            CGFloat blue = rawData[byteIndex + 2];
//            CGFloat alpha = rawData[byteIndex + 3];
            
            CGFloat sumRGBA = red + green + blue;
            if (sumRGBA < 704){    // (255 * 3) * 0.92
                if (x < x_min)  x_min = x;
                if (x > x_max)  x_max = x;
                if (y < y_min)  y_min = y;
                if (y > y_max)  y_max = y;
            }
        }
    }
    NSLog(@"Finalizando");
    
    return CGRectMake(x_min, y_min, (x_max - x_min), (y_max - y_min));
}
@end
