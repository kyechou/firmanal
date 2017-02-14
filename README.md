# Table of Contents

- [Introduction](#introduction)
- [Setup](#setup)
  - [Binaries](#binaries)
- [Usage](#usage)
- [Database](#database-1)
  - [Schema](#schema)
- [Analyses](#analyses)

# Introduction

Firmanal is an automated firmware analysis tool based on [Firmadyne](https://github.com/firmadyne/firmadyne),
and it currently only works on Arch Linux.

# Setup

After cloning this repository, edit the `MAIN_DIR` variable in the `configure.sh`.
Then execute the `setup.sh`, which will set up the environment.

```
./scripts/setup.sh
```

## Binaries

All pre-built binaries (console, libnvram, kernels) have been included in this repository.

You may, if you want, compile those binaries by yourself using the `./scripts/compile_bin.sh`.

# Usage

1. Set `MAIN_DIR` in `configure.sh` to point to the root of this repository.
2. Download a firmware image, e.g. [v2.0.3](http://www.downloads.netgear.com/files/GDC/WNAP320/WNAP320%20Firmware%20Version%202.0.3.zip) for [Netgear WNAP320](http://www.netgear.com/business/products/wireless/business-wireless/wnap320.aspx).
   * `wget http://www.downloads.netgear.com/files/GDC/WNAP320/WNAP320%20Firmware%20Version%202.0.3.zip`
3. Use the extractor to recover only the filesystem, no kernel (`-nk`), no parallel operation (`-np`), populating the `image` table in the SQL server at `127.0.0.1` (`-sql`) with the `Netgear` brand (`-b`), and storing the tarball in `images`.
   * `./scripts/extractor.py -b Netgear -sql 127.0.0.1 -np -nk "WNAP320 Firmware Version 2.0.3.zip" images`
4. Load the contents of the filesystem for firmware `1` into the database, populating the `object` and `object_to_image` tables.
   * `./db/import.py -i 1 -f ./images/1.tar.gz`
5. Create the QEMU disk image for firmware `1`.
   * `sudo ./qemu/scripts/makeImage.sh 1`
6. Infer the network configuration for firmware `1`. Kernel messages are logged to `./qemu/vm/1/qemu.initial.serial.log`.
   * `./qemu/scripts/inferNetwork.sh 1`
7. Emulate firmware `1` with the inferred network configuration. This will modify the configuration of the host system by creating a TAP device and adding a route.
   Use `Ctrl-a + x` to terminate the guest.
   * `./qemu/vm/1/run.sh`
8. The system should be available over the network, and is ready for analysis. Kernel messages are logged to `./qemu/vm/1/qemu.final.serial.log`.
   * `./anal/dynamic/snmpwalk.sh 192.168.0.100`
   * `./anal/dynamic/webAccess.py 1 192.168.0.100 log.txt`
   * `mkdir exploits && ./anal/metasploit/runExploits.py -t 192.168.0.100 -o exploits -e all` (requires Metasploit Framework)
   * `sudo nmap -O -sV 192.168.0.100`
9. The following scripts can be used to mount/unmount the filesystem of firmware `1`. Ensure that the emulated firmware is not running, and remember to unmount before performing any other operations.
   * `sudo ./qemu/scripts/mount.sh 1`
   * `sudo ./qemu/scripts/umount.sh 1`
10. To delete the firmware, use the `delete.sh`.
   * `./scripts/delete.sh 1`

# Database

During development, the database was stored on a PostgreSQL server.

## [Schema](https://github.com/niorehkids/firmanal/blob/master/db/schema)

Below are descriptions of tables in the schema.

* `brand`: Stores brand names for each vendor.

| Column | Description |
| ------ | ----------- |
| id     | Primary key |
| name   | Brand name  |

* `image`: Stores information about each firmware image.

| Column           | Description                                  |
| ---------------- | -------------------------------------------- |
| id               | Primary key                                  |
| filename         | File name                                    |
| brand_id         | Foreign key to `brand`                       |
| hash             | MD5                                          |
| rootfs_extracted | Whether the primary filesystem was extracted |
| kernel_extracted | Whether the kernel was extracted             |
| arch             | Hardware architecture                        |
| kernel_version   | Version of the extracted kernel              |

* `object`: Stores information about each file in a filesystem.

| Column           | Description            |
| ---------------- | ---------------------- |
| id               | Primary key            |
| hash             | MD5                    |

* `object_to_image`: Maps unique files to their firmware images.

| Column           | Description                 |
| ---------------- | --------------------------- |
| id               | Primary key                 |
| oid              | Foreign key to `object`     |
| iid              | Foreign key to `image`      |
| filename         | Full path to the file       |
| regular_file     | Whether the file is regular |
| permissions      | File permissions in octal   |
| uid              | Owner's user ID             |
| gid              | Group's group ID            |
| mime             | Mime type                   |
| score            | The score of analysis       |

* `product`

| Column       | Description                    |
| ------------ | ------------------------------ |
| id           | Primary key                    |
| iid          | Foreign key to `image`         |
| url          | Download URL                   |
| mib_filename | Filename of the SNMP MIB       |
| mib_hash     | MD5 of the SNP MIB             |
| mib_url      | Download URL of the SNMP MIB   |
| sdk_filename | Filename of the source SDK     |
| sdk_hash     | MD5 of the source SDK          |
| sdk_url      | Download URL of the source SDK |
| product      | Product name                   |
| version      | Version string                 |
| build        | Build string                   |
| date         | Release date                   |

# Analyses

(TODO)

