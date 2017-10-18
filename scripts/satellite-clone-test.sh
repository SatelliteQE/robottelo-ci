#!/bin/bash -xe

ssh jomitsch@$BREAD_HOST "cd ~/dolly; ./jenkins/run_dolly.rb ${ghprbPullId}"
