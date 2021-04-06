#!/usr/bin/env python
# -*- coding: utf-8 -*-
import torch
x = torch.arange(1., 6.) # x= 1,2,3,4,5,6
y,index = torch.topk(x.cuda(), 1) # y=6, index=5
y = y.cpu().detach().numpy()
index = index.cpu().detach().numpy()
print("y is: ", y)
print("index is:", index)
