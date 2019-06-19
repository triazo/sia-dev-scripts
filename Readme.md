A small set of scripts I use to test various apps using the sia api
without worrying about messing with the main network.

### setup.sh

Prerequisites:
 - gitlab.com/NebulousLabs/Sia
 - gitlab.com/NebulousLabs/Sia-Ant-Farm

Usage:
The tricky first step is determining how your tests hosts will announce themselves. By default, even when compiled for development, siad will not allow announcement of a local ip address. This leaves us with two options without exposing our dev machine to the internet: 1) patch siad to remove this check or 2) announce a DNS record that resolves to our local IP.

Depending on your network setup, you may already have 2. If you need to use route 1, patch `staticVerifyAnnouncementAddress()` in `modules/host/announce.go` to always return nil.

Next, build both Sia and Sia-Ant-Farm, and ensure that `sia-antfarm` and `siac` are in your path by running `make install` in both directories.

The actual sia daemon is used by the antfarm is a slightly modified version of siad built into Sia-Ant-Farm, which will take care of adding the necessary dev tags to the build.

Once both binaries are in your path, simply run `setup.sh` to launch a local sia cluster for testing. It can take a few minutes to get everything started.


### form_contracts.sh
Just a saved one-liner for use in `us` development. Build `https://github.com/lukechampine/us` and make sure `user` is in your path, and this script will form a contract with every host in you know about. This is really only for use with test clusters as it would cost a ton otherwise.