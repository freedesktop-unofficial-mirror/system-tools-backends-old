#-*- Mode: perl; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

# Copyright (C) 2005 Carlos Garnacho
#
# Authors: Carlos Garnacho Parro  <carlosg@gnome.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.

package Init::ServicesList;


# This function determines if a service is "forbidden" or not (if runlevel-admin must show it or not)
sub is_forbidden
{
  my ($service) = @_;
  my ($ret);

  my ($service_forbidden_list) =
    [
     # These are the forbidden services I found in Red Hat
     "halt",
     "functions",
     "killall",
     # These are the forbidden services I found in Debian Woody	
     "single",
     "sendsigs",
     "reboot",
     "rcS",
     "modutils",
     "hostname\.sh",
     "devpts\.sh",
     "console-screen\.sh",
     "checkroot\.sh",
     "checkfs\.sh",
     "bootmisc\.sh",
     "bootclean\.sh",
     "checkfs\.sh",
     "keymap\.sh",
     "hwclockfirst\.sh",
     "etc-setserial",
     "procps\.sh",
     "mountall\.sh",
     "dns-clean",
     "ifupdown",
     "networking",
     "mountnfs\.sh",
     "mountkernfs",
     "mountvirtfs",
     "setserial",
     "hwclock\.sh",
     "urandom",
     "nviboot",
     "pppd-dns",
     "skeleton",
     "xfree86-common",
     "rc",
     ".*\.dpkg-old",
     ".*~",
     # this shouldn't be shown in slackware
     "inet2",
     # those were found in gentoo
     "bootmisc",
     "checkfs",
     "checkroot",
     "clock",
     "consolefont",
     "crypto-loop",
     "domainname",
     "hostname",
     "keymaps",
     "localmount",
     "net\..*",
     "numlock",
     "depscan\.sh",
     "functions\.sh",
     "halt\.sh",
     "reboot\.sh",
     "rmnologin",
     "runscript\.sh",
     "serial",
     "shutdown\.sh",
     "switch",
     # those were found in FreeBSD
     "DAEMON",
     "LOGIN",
     "NETWORKING",
     "SERVERS",
     "addswap",
     "adjkerntz",
     "archdep",
     "atm2\.sh",
     "atm3\.sh",
     "ccd",
     "cleanvar",
     "cleartmp",
     "devdb",
     "devfs",
     "dhclient",
     "diskless",
     "dumpon",
     "fsck",
     "hostname",
     "initdiskless",
     "initrandom",
     "ldconfig",
     "local",
     "localdaemons",
     "mountcritlocal",
     "mountcritremote",
     "msgs",
     "netif",
     "network1",
     "network2",
     "network3",
     "nisdomain",
     "othermta",
     "pccard",
     "pcvt",
     "pwcheck",
     "random",
     "rcconf\.sh",
     "root",
     "savecore",
     "securelevel",
     "serial",
     "sppp",
     "swap1",
     "syscons",
     "sysctl",
     "tmp",
     "ttys",
     "var",
     "virecover",
     # These are the services found in SuSE
     "rc[sS0-9]\.d",
     "boot",
     "boot\..*",
    ];

  foreach $i (@$service_forbidden_list)
  {
    return 1 if ($service =~ "^$i\$");
  }

  return 0;
}


# Ok, maybe we should define this roles stuff a bit:
#
# SYSTEM: all system related services that only powerusers care of
# SOUND:  any service related to sound
# WEB_SERVER: any web server
# COMMAND_SCHEDULER: any service which runs scheduled commands
# NETWORK: network related services that only powerusers care of
# PRINTER_SERVICE: printing daemons in general
# DYNAMIC_DNS: Dinamic DNS services
# DICT:
# MTA: Mail transport agents
# MAIL_FETCHER: services that fetch the mail from other accounts
# DISPLAY_MANAGER: Display managers
# SYSTEM_LOGGER: system log services
# DATABASE_SERVER: database servers
# FILE_SERVER: file servers
# NTP_SERVER: Network time protocol servers
# SECURE_SHELL_SERVER: Secure shell servers
# AUTOMOUNTER: automounter daemons and so
# ANTIVIRUS:
# FILE_SHARING: for emule-like services
# FTP_SERVER:
#
#
# If you feel that there are more important/necessary roles,
# mail me at carlosg@gnome.org

sub get_role
{
  my ($script) = @_;

  my %service_roles = (
    "acpid" => "SYSTEM",
    "alsa" => "SOUND",
    "am-utils" => "AUTOMOUNTER",
    "amavis" => "ANTIVIRUS",
    "amavis-ng" => "ANTIVIRUS",
    "apache" => "WEB_SERVER",
    "apache-perl" => "WEB_SERVER",
    "apache-ssl" => "WEB_SERVER",
    "apache2" => "WEB_SERVER",
    "anacron" => "COMMAND_SCHEDULER",
    "apmd" => "SYSTEM",
    "atd" => "COMMAND_SCHEDULER", #FIXME
    "atftpd" => "FTP_SERVER",
    "aumix" => "SOUND",
    "autofs" => "AUTOMOUNTER",
    "bind" => "NETWORK",
    "binfmt-support" => "SYSTEM",
    "bootlogd" => "SYSTEM",
    "chargen" => "NETWORK",
    "chargen-udp" => "NETWORK",
    "cherokee" => "WEB_SERVER",
    "clamav-daemon" => "ANTIVIRUS",
    "courier" => "MTA",
    "courier-mta" => "MTA",
    "cpufreqd" => "SYSTEM",
    "cron" => "COMMAND_SCHEDULER",
    "crond" => "COMMAND_SCHEDULER",
    "cupsd" => "PRINTER_SERVICE",
    "cupsys" => "PRINTER_SERVICE",
    "daytime" => "NETWORK",
    "daytime-udp" => "NETWORK",
    "dbus-1" => "SYSTEM",
    "ddclient" => "DYNAMIC_DNS",
    "dhis-client" => "DYNAMIC_DNS",
    "dictd" => "DICT",
    "echo" => "NETWORK",
    "echo-udp" => "NETWORK",
    "esound" => "SOUND",
    "exim" => "MTA",
    "fam" => "SYSTEM",
    "fcron" => "COMMAND_SCHEDULER",
    "firstboot" => "SYSTEM",
    "festival" => "SOUND",	 #FIXME
    "fetchmail" => "MAIL_FETCHER",
    "freenet6" => "NETWORK",
    "ftpd" => "FTP_SERVER",
    "gdm" => "DISPLAY_MANAGER",
    "gpm" => "SYSTEM",			#FIXME
    "hdparm" => "SYSTEM",
    "hotplug" => "SYSTEM",
    "httpd"	=> "WEB_SERVER",
    "inetd" => "NETWORK",
    "iptables" => "NETWORK",
    "irda" => "SYSTEM",
    "isakmpd" => "NETWORK",
    "isdn" => "NETWORK",
    "joystick" => "SYSTEM",
    "kdm"	=> "DISPLAY_MANAGER",
    "keytable" => "SYSTEM",
    "klogd"	=> "SYSTEM_LOGGER",
    "kudzu"	=> "SYSTEM",
    "lircd"	=> "SYSTEM",
    "lircmd" => "SYSTEM",
    "local" => "SYSTEM",
    "lpd" => "PRINTER_SERVICE",
    "lpdng" => "PRINTER_SERVICE",
    "mailscanner" => "ANTIVIRUS",
    "makedev" => "SYSTEM",
    "metalog" => "SYSTEM_LOGGER",
    "mldonkey-server" => "FILE_SHARING",
    "modules" => "SYSTEM",
    "module-init-tools" => "SYSTEM",
    "mysql" => "DATABASE_SERVER",
    "muddleftpd" => "FTP_SERVER",
    "named" => "NETWORK",
    "netfs" => "SYSTEM",
    "network" => "SYSTEM",
    "nfs"	=> "FILE_SERVER_NFS",
    "nfs-user-server"	=> "FILE_SERVER_NFS",
    "nfs-kernel-server"	=> "FILE_SERVER_NFS",
    "nfslock" => "SYSTEM",
    "nscd" => "NETWORK",
    "ntpd" => "NTP_SERVER",
    "ntpdate" => "NTP_SERVER",
    "ntp-client" => "NTP_CLIENT",
    "ntp-server" => "NTP_SERVER",
    "ntp-simple" => "NTP_SERVER",
    "oftpd" => "FTP_SERVER",
    "oops" => "NETWORK",
    "pcmcia" => "SYSTEM",
    "pdnsd" => "NETWORK",
    "pipsecd" => "NETWORK",
    "portmap" => "NETWORK",
    "postfix" => "MTA",
    "postgresql" => "DATABASE_SERVER",
    "postgresql-7.4" => "DATABASE_SERVER",
    "postgresql-8.0" => "DATABASE_SERVER",
    "postgresql-8.1" => "DATABASE_SERVER",
    "ppp"	=> "NETWORK",
    "proftpd" => "FTP_SERVER",
    "privoxy" => "NETWORK",
    "pure-ftpd" => "FTP_SERVER",
    "qmail" => "MTA",
    "random" => "SYSTEM",
    "rawdevices" => "SYSTEM",
    "rhnsd" => "SYSTEM",
    "rsync" => "NETWORK",
    "rsyncd" => "NETWORK",
    "samba" => "FILE_SERVER_SMB",
    "saslauthd" => "SYSTEM",	 # FIXME: maybe a SECURITY role makes sense?
    "sendmail" => "MTA",
    "servers" => "NETWORK",
    "services" => "NETWORK",
    "setserial" => "SYSTEM",
    "sgi_fam" => "SYSTEM",
    "smartmontools" => "SYSTEM",
    "spamassassin" => "SYSTEM",
    "snmpd"	=> "NETWORK",
    "ssh"	=> "SECURE_SHELL_SERVER",
    "sshd" => "SECURE_SHELL_SERVER",
    "sysklogd" => "SYSTEM_LOGGER",
    "syslog" => "SYSTEM_LOGGER",
    "tftpd-hpa" => "FTP_SERVER",
    "time" => "NETWORK",
    "time-udp" => "NETWORK",
    "urandom" => "SYSTEM",
    "vcron" => "COMMAND_SCHEDULER",
    "vmware" => "SYSTEM",	 # FIXME
    "vsftpd" => "FTP_SERVER",
    "wdm"	=> "DISPLAY_MANAGER",
    "webmin" => "SYSTEM",	 # FIXME as well
    "winbind" => "NETWORK",
    "wine" => "SYSTEM",	 # FIXME like vmware
    "wu-ftpd" => "FTP_SERVER",
    "wzdftpd" => "FTP_SERVER",
    "xdm" => "DISPLAY_MANAGER",
    "xfs" => "SYSTEM",
    "xinetd" => "NETWORK",
    "zmailer" => "MTA",
  );

  my ($role) = $service_roles{$script};

  return $role if ($role);
  return "UNKNOWN";
}

1;
