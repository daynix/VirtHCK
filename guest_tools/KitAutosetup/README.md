Auto-configuration of VirtHCK Environment
===============
This allows to automate the steps needed to configure the guest machines
(Controller and Clients) that are described in the
[VirtHCK Wiki](https://github.com/daynix/VirtHCK/wiki#Checklist_for_a_new_studio_VM).
Meaning, given a [VirtHCK](https://github.com/daynix/VirtHCK) setup of machines
with freshly installed copies of Windows, one executable takes care of all the
needed preparations and the installation of the Controller/Client.

* This works for both the Hardware Certification Kit (HCK) and the Hardware Lab
Kit (HLK, Windows 10) setups.

Prerequisites
===============
* On the Linux host Samba server is needed.
* In the Samba Share directory, that is shared between the host and the guests
(which can be configured in
[hck_setup.cfg](https://github.com/daynix/VirtHCK/blob/master/hck_setup.cfg))
the **complete** installation directory of the Kit Controller (Which contains
the setup file and the Installers directory) is required. It can be obtained by
running the Kit installer on a Windows machine (possibly the intended HCK
Controller itself) and choosing the option to download for installation on a
separate computer.

Usage
===============
1. Prepare 3 separate (**not** copied) freshly installed images of the Windows
OS using the VirtHCK scripts.
2. in the
[KitSetup.sh](https://github.com/daynix/VirtHCK/blob/master/guest_tools/KitAutosetup/KitSetup.sh)
file, set the required parameters, such as:
  * The **desired** (not current) names of the Clients.
  * The version of the Kit to install (currently only 8, 8.1, or 10 are supported).
  * The directory on the Samba share where the Kit installation files are.
  * The desired (not necessarily current) Administrator's password for the Windows guests.
  * The path to the Samba share directory on the host.
  * And so on... (but the parameters listed above are usually the only ones one would need to change).
3. Run `./KitSetup.sh` on the host machine. This will prepare the needed files
and copy them to the Samba share directory.
4. Start VirtHCK (if not running already). Go to the Samba share
(`\\192.168.101.1\qemu`, by default) **on the intended Controller machine** and
run `SYS_SETUP.bat`, by right-clicking it, and choosing "Run as Administrator".
This will prepare the machine, reboot it, and start the installation of the HCK
Controller. The installation process will take a **very** long time (may be
over an hour) and no progress bar is seen. Please use patience.
5. **After** the installation of the Controller is complete, go to the Samba
share on the Clients, and run `SYS_SETUP.bat` there as an Administrator as
well. This will prepare the machines and install the Kit Client on them. Again,
this will take a long time, but the installation of both clients can be done
simultaneously. Do **not** turn off the Controller VM during the Clients'
installation.

End Result
===============
* In the end, the freshly installed machines will become ready for running HCK
or HLK tests in the VirtHCK environment.
* You should run the Kit using the special shortcut that is created on the
desktop of the Controller machine - it turns off the access to the external
network while the Studio is running.
* You can update the Kit filters, from time to time, using the shortcut created
on the desktop of the Controller machine. Internet access is needed for that.

Troubleshooting
===============
Sometimes, the installation of the HCK/HLK itself fails. In such a case, the
Kit can be installed manually. No further preparation of the VMs is needed, as
it was already performed by these scripts - still a major time saver! :clock10:
