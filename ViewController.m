//
//  ViewController.m
//  pinger
//
//  Created by lk on 16/5/4.
//  Copyright © 2016年 lk. All rights reserved.
//

#import "ViewController.h"
#import "PGPing.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *btn;
@property (weak, nonatomic) IBOutlet UITextField *txb;
@property (weak, nonatomic) IBOutlet UITextView *lbResult;

@end

@implementation ViewController
@synthesize btn;
@synthesize txb;
@synthesize lbResult;

- (void)viewDidLoad {
    [super viewDidLoad];
    [btn addTarget:self action:@selector(btnTouch) forControlEvents:UIControlEventTouchUpInside];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)btnTouch {
    for (int i = 0; i < 4; i++) {
        NSString *str = txb.text;
        int resp = [PGPing sendtoHost:str];
        if (resp != -1) {
            NSString *str = [NSString stringWithFormat:@"%d ms.\n",resp];
            lbResult.text = [lbResult.text stringByAppendingString:str];
            [lbResult scrollRangeToVisible:NSMakeRange(lbResult.text.length - 1, 1)];
        } else {
            lbResult.text = [lbResult.text stringByAppendingString:@"Request timeout.\n"];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
