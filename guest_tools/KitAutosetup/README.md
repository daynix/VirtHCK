Auto-configuration of VirtHCK Environment
===============
This allows to automate the steps needed to configure the guest machines (Controller and Clients) that are described in the [VirtHCK Wiki](https://github.com/daynix/VirtHCK/wiki#Checklist_for_a_new_studio_VM). Meaning, given a [VirtHCK](https://github.com/daynix/VirtHCK) setup of machines with freshly installed copies of Windows, one executable takes care of all the needed preparations and the installation of the Controller/Client.
* This works for both the Hardware Certification Kit (HCK) and the Hardware Lab Kit (HLK, Windows 10) setups.

Prerequisites
===============
* On the Linux host Samba server is needed.
* In the Samba Share directory, that is shared between the host and the guests (which can be configured in [hck_setup.cfg](https://github.com/daynix/VirtHCK/blob/master/hck_setup.cfg) or via the `SHARE_ON_HOST` environment variable) the **complete** installation directory of the Kit Controller (Which contains the setup file and the Installers directory) is required. It can be obtained by running the Kit installer on a Windows machine (possibly the intended HCK Controller itself) and choosing the option to download for installation on a separate computer.
* On the Controller and the Client machines Windows PowerShell, version 3.0 or above is needed. It is integrated in Windows 8, Windows Server 2012, and above. If using with Windows 7 or Windows Server 2008, it needs to be installed separately. Earlier versions are not supported.

Usage
===============
1. Prepare 3 separate (**not** copied) freshly installed images of the Windows OS using the VirtHCK scripts.
2. in the [KitSetup.sh](https://github.com/daynix/VirtHCK/blob/master/guest_tools/KitAutosetup/KitSetup.sh) file, set the required parameters, such as the **desired** (not current) names of the Clients, the version of the Kit to install (currently only 8, 8.1, or 10), the directory on the Samba share where the Kit installation files are, the desired (not necessairly current) Administrator's password for the Windows guests, the path to the Samba share directory on the host, and so on (but the parameters listed above are usually the only ones one would need to change).
3. Run `./KitSetup.sh` on the host machine. This will prepare the needed files and copy them to the Samba share directory.
4. Start the Kit Controller machine (don't start the clients yet), go to the Samba share (`\\192.168.101.1\qemu`, by default) and run **SYS_SETUP.bat**, by right-clicking it, and choosing "Run as Administrator". This will prepare the machine, reboot it, and start the installation of the HCK Controller. The installation process will take a **very** long time (may be over an hour) and no progress bar is seen. Please use patience.
5. After the installation of the Controller is complete, start the client machines, go to the Samba share on them, and run **SYS_SETUP.bat** as an Administrator also. This will prepare the machines and install the Kit Client on them. Again, this will take a long time, but the installation of both clients can be done simultaneously.

End Result
===============
* In the end, the freshly installed machines will become ready for running HCK or HLK tests in the VirtHCK environment.
* You should run the Kit using the special shortcut that is created on the desktop of the Controller machine - it turns off the access to the external network while the Studio is running.
* You can update the Kit filters, from time to time, using the shortcut created on the desktop of the Controller machine. Internet access is needed for that.
