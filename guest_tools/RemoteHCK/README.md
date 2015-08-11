Purpose
===============
Running tests in the VirtHCK setup from the host machine, cancelling the need to bring up the HCK Controller machine UI (allows also to shut it down remotely).

Prerequisites
===============
* On the Linux host the following is needed:
  1. [Winexe](http://sourceforge.net/projects/winexe)
  2. Samba server.
  3. The [AutoHCK](https://github.com/daynix/VirtHCK/blob/master/guest_tools/AutoHCK) Guest Tool.
* On the Controller Windows guest, the 64-bit Windows PowerShell, version 3.0 or above is needed. It is integrated in Windows 8, Windows Server 2012, and above. If using with Windows 7 or Windows Server 2008, it needs to be installed separately. Earlier versions are not supported.

Usage
===============
### Preparations
1. Start up a VirtHCK setup.
2. in the [RemoteHCK.sh](https://github.com/daynix/VirtHCK/blob/master/guest_tools/RemoteHCK/RemoteHCK.sh) file, set the required parameters, such as the HCK Controller external IP, the names of the Clients, the Administrator password for the Controller machine, the device to be tested, and the project name.
  * **Warning: do not use the same project name to test different devices!** This will lead to the need of manual intervention, and may require client reinstallation!
3. Run `./RemoteHCK.sh setup` on the host machine. This will prepare the needed files and copy them to the Samba share directory.

### Running Tests From The Host
1. Run `./RemoteHCK.sh run` on the host machine. This will begin the tests, and the progress will be shown. The tests may take a very long time.
3. The test results (**.hckx** and **.txt** files) will be available in the Samba share directory on the host.

### Shutting Down The HCK Controller
* To shut down the controller, run `./RemoteHCK.sh shutdown-studio`
