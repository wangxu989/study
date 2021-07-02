# Guide
## Quickly Start
### inference
- run on bi:
```
import debug
model = Net(**config)
debug.builder(model, arch="bi", hook_type="inference", if_compare=False)
...
debug.run()
```
Then bi_debug.npy will exisit in current directory and copy it to nv environment.
- run on nv
```
import debug
model = Net(**config)
debug.builder(model, arch="nv", hook_type="inference", if_compare=True)
...
debug.run()
```
Then debug.csv will exisit in current directory.
#### backward
change "inference" to "backward"
#### loss graph
change "inference" to "loss"


