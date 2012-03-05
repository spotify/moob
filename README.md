    moob: simple cli to various crappy LOMs
    ----
    
    moob currently has support for Dell iDrac6, Megatrends, Sun and IBM remote management.
    
        Usage: moob [options]
            -t, --type t                     LOM type, 'auto' for autodetection, 'list' to list
                                             Defaults to auto
            -a, --actions a,b,c              Actions to perform, 'list' to list
                                             Defaults to jnlp
            -u, --username u                 LOM username
                                             Defaults to the model's default if known
            -p, --password p                 LOM password
                                             Defaults to the model's default if known
                                             Use the environment variable PASSWORD instead!
            -m, --machines a,b,c             Comma-separated list of LOM hostnames
            -v, --verbose
    
    moob supports the following actions:
    
    idrac6:
      jnlp: Remote control
      poff: Power Off System
      pon: Power On System
      pcycle: Power Cycle System (cold boot)
      preset: Reset System (warm boot)
      nmi: NMI (Non-Masking Interrupt)
      shutdown: Graceful Shutdown
      bnone: Do not change the next boot
      bpxe: Boot on PXE once
      bbios: Boot on BIOS setup once
      blfloppy: Boot on Local Floppy/Primary Removable Media once
      blcd: Boot on Local CD/DVD once
      blhd: Boot on Hard Drive once
      biscsi: Boot on NIC BEV iSCSI once
      bvfloppy: Boot on Virtual Floppy once
      bvcd: Boot on Virtual CD/DVD/ISO once
      blsd: Boot on Local SD Card once
      bvflash: Boot on vFlash once
      pstatus: Power status
      infos: Get system information
    megatrends:
      jnlp: Remote control
      poff: Power Off
      pon: Power On
      pcycle: Power Cycle
      preset: Power Reset
      shutdown: Soft Power Off
      pstatus: Power status
    sun:
      jnlp: Remote control
    ibm:
      infos: Vital Product Data
