#!/bin/bash
cd /mnt/c/Tools/workarea/CoffeeOS
git add -A
git commit -m "chore: remove relocated root docs and temp files"
git push origin develop
echo PUSH_OK
