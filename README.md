![](https://github.com/td512/td512/raw/master/header_.png)


# Rescue: A live linux rescue system based on Hetzner's Rescue 

Ever used Hetzner, and wondered how their rescue system ticks? 

Yeah. Me neither, but here we are. This system is loosely based on Hetzner's rescue, utilizing almost all of the same scripts you'll find there

This project is a work in progress, and contains a few submodules. Beware, as some of these submodules can be (very) large

# Submodules

This project has three main submodules. 
- `rescue` - this is where the rescue system lives. You can chroot into it just as you would a regular system. See below for notes on functionality and how things work
- `images` - this submodule contains OS images, just like you'd expect if you were using Hetzner. It's also the largest, so if you don't have very much disk space, *don't initialize this one*

# Usage

Head over to [releases](https://github.com/td512/rescue/releases), there you'll find an ISO that is stock standard. When booting an image that is prebuilt, you need to take the following into account:

- The boot-time scripts will look for kernel options. You'll need to set those manually on each boot
- If no kernel options are supplied, the system assumes a few things. Mainly: Your NFS server lives on `169.254.254.254`, and the mount point is `/nfs`
- If no kernel options are specified *and* there is no connectivity to the assumed server, the boot-time script will fail gracefully, and functionality such as `installimage` will not work, as they live on the NFS server

The kernel options you need to set to override the NFS server and location the boot-time script is looking for are:
- `nfsserver` - this option should be self explanatory, it sets the server the boot-time script should mount from. This can either be a publicly resolvable domain such as `one.one.one.one` or an IP, i.e. `169.254.254.254`
- `nfsdir` - also self explanatory. Note that this should lead with a slash, i.e. `/nfs`, *not* `nfs`

It is therefore a really good idea if you build your own ISO. It's also one I would strongly recommend. 

Whilst I have no bad intentions, you should still verify that nothing harmful has made its way into the repo. Don't just take my word for it

# Building Your Own
Building your own ISO is super simple:
- Clone this repo
- Modify `build/config.sh` to your heart's desire
- On a Debian or Ubuntu machine, run `build.sh`

Yes, it really is just that simple. An ISO and iPXE binary will be dropped into the directory specified by `RESCUE_RESULT_DIR` in `build/config.sh`.

# Notes

- This project is a WIP. Expect relatively frequent pushes that may break functionality that was previously working
- Play round with the ISO as much as you like. On reboot your changes will be lost, and you'll be returned to an untouched state
- If you find a bug or issue, by all means [create an issue](https://github.com/td512/issues)
- Pull requests are very welcome. Browse around for a while and see what you can fix!
