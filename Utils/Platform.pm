#!/usr/bin/env perl
#-*- Mode: perl; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

# Determine the platform we're running on.
#
# Copyright (C) 2000-2001 Ximian, Inc.
#
# Authors: Arturo Espinosa <arturo@ximian.com>
#          Hans Petter Jansson <hpj@ximian.com>
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

package Utils::Platform;

use Utils::XML;
use Utils::Parse;
use Utils::Backend;

use base qw(Net::DBus::Object);
use Net::DBus::Exporter ($Utils::Backend::DBUS_PREFIX . ".Platform");

my $OBJECT_NAME = "Platform";
my $OBJECT_PATH = "$Utils::Backend::DBUS_PATH/$OBJECT_NAME";

dbus_method ("getPlatformList", [], [[ "array", [ "struct", "string", "string", "string", "string" ]]]);
dbus_method ("getPlatform", [], [ "string" ]);
dbus_method ("setPlatform", [ "string" ], []);
dbus_signal ("noPlatformDetected", []);

# --- System guessing --- #

my $PLATFORM_INFO = {
  "debian-3.0"      => [ "Debian GNU/Linux", "3.0", "Woody" ],
  "debian-3.1"      => [ "Debian GNU/Linux", "3.1", "Sarge" ],
  "ubuntu-5.04"     => [ "Ubuntu Linux", "5.04", "Hoary" ],
  "ubuntu-5.10"     => [ "Ubuntu Linux", "5.10", "Breezy" ],
  "ubuntu-6.06"     => [ "Ubuntu Linux", "6.06", "Dapper" ],
  "ubuntu-6.10"     => [ "Ubuntu Linux", "6.10", "Edgy" ],
  "redhat-5.2"      => [ "Red Hat Linux", "5.2", "Apollo" ],
  "redhat-6.0"      => [ "Red Hat Linux", "6.0", "Hedwig" ],
  "redhat-6.1"      => [ "Red Hat Linux", "6.1", "Cartman" ],
  "redhat-6.2"      => [ "Red Hat Linux", "6.2", "Zoot" ],
  "redhat-7.0"      => [ "Red Hat Linux", "7.0", "Guinness" ],
  "redhat-7.1"      => [ "Red Hat Linux", "7.1", "Seawolf" ],
  "redhat-7.2"      => [ "Red Hat Linux", "7.2", "Enigma" ],
  "redhat-7.3"      => [ "Red Hat Linux", "7.3", "Valhalla" ],
  "redhat-8.0"      => [ "Red Hat Linux", "8.0", "Psyche" ],
  "redhat-9"        => [ "Red Hat Linux", "9.0", "Shrike" ],
  "openna-1.0"      => [ "OpenNA Linux", "1.0", "VSLC" ],
  "mandrake-7.1"    => [ "Linux Mandrake", "7.1" ],
  "mandrake-7.2"    => [ "Linux Mandrake", "7.2", "Odyssey" ],
  "mandrake-8.0"    => [ "Linux Mandrake", "8.0", "Traktopel" ],
  "mandrake-9.0"    => [ "Linux Mandrake", "9.0", "Dolphin" ],
  "mandrake-9.1"    => [ "Linux Mandrake", "9.1", "Bamboo" ],
  "mandrake-9.2"    => [ "Linux Mandrake", "9.2", "FiveStar" ],
  "mandrake-10.0"   => [ "Linux Mandrake", "10.0" ],
  "mandrake-10.1"   => [ "Linux Mandrake", "10.1" ],
  "mandrake-10.2"   => [ "Linux Mandrake", "2005" ],
  "mandriva-2006.0" => [ "Mandriva Linux", "2006.0" ],
  "mandriva-2006.1" => [ "Mandriva Linux", "2006.1" ],
  "yoper-2.2"       => [ "Yoper Linux", "2.2" ],
  "blackpanther-4.0" => [ "Black Panther OS", "4.0", "" ],
  "conectiva-9"     => [ "Conectiva Linux", "9", "" ],
  "conectiva-10"    => [ "Conectiva Linux", "10", "" ],
  "suse-9.0"        => [ "SuSE Linux", "9.0", "" ],
  "suse-9.1"        => [ "SuSE Linux", "9.1", "" ],
  "slackware-9.1.0" => [ "Slackware", "9.1.0", "" ],
  "slackware-10.0.0" => [ "Slackware", "10.0.0", "" ],
  "slackware-10.1.0" => [ "Slackware", "10.1.0", "" ],
  "slackware-10.2.0" => [ "Slackware", "10.2.0", "" ],
  "freebsd-4"       => [ "FreeBSD", "4", "" ],
  "freebsd-5"       => [ "FreeBSD", "5", "" ],
  "freebsd-6"       => [ "FreeBSD", "6", "" ],
  "freebsd-7"       => [ "FreeBSD", "7", "" ],
  "gentoo"          => [ "Gentoo Linux", "", "" ],
  "vlos-1.2"        => [ "Vida Linux OS", "1.2" ],
  "archlinux"       => [ "Arch Linux", "", "" ],
  "pld-1.0"         => [ "PLD", "1.0", "Ra" ],
  "pld-1.1"         => [ "PLD", "1.1", "Ra" ],
  "pld-1.99"        => [ "PLD", "1.99", "Ac-pre" ],
  "pld-2.99"        => [ "PLD", "1.99", "Th-pre" ],
  "vine-3.0"        => [ "Vine Linux", "3.0", "" ],
  "vine-3.1"        => [ "Vine Linux", "3.1", "" ],
  "fedora-1"        => [ "Fedora Core", "1", "Yarrow" ],
  "fedora-2"        => [ "Fedora Core", "2", "Tettnang" ],
  "fedora-3"        => [ "Fedora Core", "3", "Heidelberg" ],
  "fedora-4"        => [ "Fedora Core", "4", "Stentz" ],
  "rpath"           => [ "rPath Linux" ],
  "ark"             => [ "Ark Linux" ]
};

sub ensure_distro_map
{
  my ($distro) = @_;

  # This is a distro metamap, if one distro
  # behaves *exactly* like another, just specify it here
  my %metamap =
    (
     "blackpanther-4.0" => "mandrake-9.0",
     "conectiva-10"     => "conectiva-9",
     "debian-3.1"       => "debian-3.0",
     "mandrake-7.1"     => "redhat-6.2",
     "mandrake-7.2"     => "redhat-6.2",
     "mandrake-9.1"     => "mandrake-9.0",
     "mandrake-9.2"     => "mandrake-9.0",
     "mandrake-10.0"    => "mandrake-9.0",
     "mandrake-10.1"    => "mandrake-9.0",
     "mandrake-10.2"    => "mandrake-9.0",
     "mandriva-2006.0"  => "mandrake-9.0",
     "mandriva-2006.1"  => "mandrake-9.0",
     "fedora-1"         => "redhat-7.2",
     "fedora-2"         => "redhat-7.2",
     "fedora-3"         => "redhat-7.2",
     "fedora-4"         => "redhat-7.2",
     "fedora-5"         => "redhat-7.2",
     "freebsd-6"        => "freebsd-5",
     "freebsd-7"        => "freebsd-5",
     "openna-1.0"       => "redhat-6.2",
     "pld-1.1"          => "pld-1.0",
     "pld-1.99"         => "pld-1.0",
     "pld-2.99"         => "pld-1.0",
     "redhat-9"         => "redhat-8.0",
     "rpath"            => "redhat-7.2",
     "slackware-10.0.0" => "slackware-9.1.0",
     "slackware-10.1.0" => "slackware-9.1.0",
     "slackware-10.2.0" => "slackware-9.1.0",
     "suse-9.1"         => "suse-9.0",
     "ubuntu-5.04"      => "debian-3.0",
     "ubuntu-5.10"      => "debian-3.0",
     "ubuntu-6.06"      => "debian-3.0",
     "ubuntu-6.10"      => "debian-3.0",
     "vine-3.1"         => "vine-3.0",
     "vlos-1.2"         => "gentoo"
     );

  return $metamap{$distro} if ($metamap{$distro});
  return $distro;
}
  
sub check_lsb
{
  my ($ver, $dist);

  $dist = lc (&Utils::Parse::get_sh ("/etc/lsb-release", "DISTRIB_ID"));
  $ver = lc (&Utils::Parse::get_sh ("/etc/lsb-release", "DISTRIB_RELEASE"));
  
  return -1 if ($dist eq "") || ($ver eq "");
  return "$dist-$ver";
}

sub check_yoper
{
   open YOPER, "$gst_prefix/etc/yoper-release" or return -1;
   while (<YOPER>)
   {
     $ver = $_;
     chomp ($ver);
     if ($ver =~ m/Yoper (\S+)/)
     {
       close YOPER;
       # find the first digit of our release
       $mystring= ~m/(\d)/;
       #store it in $fdigit
       $fdigit= $1;
       # the end of the release is marked with -2 so find the -
       $end = index($ver,"-");
       $start = index($ver,$fdigit);
       # extract the substring into $newver
       $newver= substr($ver,$start,$end-$start);
       print $newver;
       return "yoper-$newver";
     }
   }
   close YOPER;
   return -1;
}

sub check_rpath
{
  open RPATH, "$gst_prefix/etc/distro-release" or return -1;

  while (<RPATH>)
  {
    $ver = $_;
    chomp ($ver);

    if ($ver =~ /^rPath Linux/)
    {
      close RPATH;
      return "rpath";
    }
    elsif ($ver =~ /Foresight/)
    {
      close RPATH;
      return "rpath";
    }
  }

  close RPATH;
  return -1;
}

sub check_ark
{
  open ARK, "$gst_prefix/etc/ark-release" or return -1;
  while (<ARK>)
  {
    $ver = $_;
    chomp ($ver);

    if ($ver =~ /^Ark Linux/)
    {
      close ARK;
      return "ark";
    }
  }

  close ARK;
  return -1;
}

sub check_freebsd
{
  my ($sysctl_cmd, @output);

  $sysctl_cmd = &Utils::File::locate_tool ("sysctl");
  @output = (readpipe("$sysctl_cmd -n kern.version"));
  foreach (@output)
  {
    chomp;
    if (/^FreeBSD\s([0-9]+)\.\S+.*/)
    {
      return "freebsd-$1";
    }
  }
  return -1;
}

sub check_solaris
{
  my ($fd, $dist);

  #
  # The file /etc/release is present for solaris-2.6
  # solaris 2.5 does not have the file.  Solaris-7.0 and 8.0 have not
  # been checked
  #
  # uname output
  # Solaris 2.5: 5.5(.1)
  # Solaris 2.6: 5.6
  # Solaris 7:   unknown, assume 7.0
  # Solaris 8:   unknown, assume 8.0
  #
  $fd = &Utils::File::run_pipe_read ("uname -r");
  return -1 if $fd eq undef;
  chomp ($dist = <$fd>);
  &Utils::File::close_file ($fd);

  if ($dist =~ /^5\.(\d)/) { return "solaris-2.$1" }
  else { if ($dist =~ /^([78])\.\d/) { return "solaris-$1.0" } }
  return -1;
}

sub check_distro_file
{
  my ($file, $dist, $re, $map) = @_;
  my ($ver);
  local *FILE;

  open FILE, "$gst_prefix/$file" or return -1;

  while (<FILE>)
  {
    chomp;

    if ($_ =~ "$re")
    {
      $ver = $1;
      $ver = $$map{$ver} if ($$map{$ver});

      close FILE;
      return "$dist-$ver";
    }
  }

  close FILE;
  return -1;
}

sub check_file_exists
{
  my ($file, $distro) = @_;

  return $distro if stat ("$gst_prefix/$file");
  return -1;
}

sub get_system
{
  # get the output of 'uname -s', it returns the system we are running
  $Utils::Backend::tool{"system"} = &Utils::File::run_backtick ("uname -s");
  chomp ($Utils::Backend::tool{"system"});
}

sub set_platform
{
  my ($platform) = @_;
  my ($p);


  if (&ensure_platform ($platform))
  {
    $platform = &ensure_distro_map ($platform);

    $Utils::Backend::tool{"platform"} = $gst_dist = $platform;
    &Utils::Report::do_report ("platform_success", $platform);
    &Utils::Report::end ();
    return;
  }

  &set_platform_unsupported ($object);
  &Utils::Report::do_report ("platform_unsup", $platform);
  &Utils::Report::end ();
}

sub set_platform_unsupported
{
  my ($object) = @_;

  $Utils::Backend::tool{"platform"} = $gst_dist = undef;
  #&Net::DBus::Object::emit_signal ($object, "noPlatformDetected");
}

sub ensure_platform
{
  my ($platform) = @_;

  return $platform if ($$PLATFORM_INFO{$platform} ne undef);
  return undef;
}

sub guess
{
  my ($object) = @_;
  my ($distro, $func);
  my ($checks, $check);

  my %platform_checks = (
    "Linux"   => [[ \&check_lsb ],
                  [ \&check_distro_file, "/etc/debian_version", "debian", "(.*)", { "testing/unstable" => "sarge" } ],
                  [ \&check_distro_file, "/etc/SuSE-release", "suse", "VERSION\s*=\s*(\S+)" ],
                  [ \&check_distro_file, "/etc/blackPanther-release", "blackpanther", "^Linux Black Panther release (\S+)" ],
                  [ \&check_distro_file, "/etc/blackPanther-release", "blackpanther", "^Black Panther ( L|l)inux release ([\d\.]+)" ],
                  [ \&check_distro_file, "/etc/vine-release", "vine", "^Vine Linux ([0-9.]+)" ],
                  [ \&check_distro_file, "/etc/fedora-release", "fedora", "^Fedora Core release (\S+)" ],
                  [ \&check_distro_file, "/etc/mandrake-release", "mandrake", "^Linux Mandrake release (\S+)" ],
                  [ \&check_distro_file, "/etc/mandrake-release", "mandrake", "^Mandrake( L|l)inux release ([\d\.]+)" ],
                  [ \&check_distro_file, "/etc/mandriva-release", "mandriva", "^Linux Mandriva release (\S+)" ],
                  [ \&check_distro_file, "/etc/mandriva-release", "mandriva", "^Mandriva( L|l)inux release ([\d\.]+)" ],
                  [ \&check_distro_file, "/etc/conectiva-release", "conectiva", "^Conectiva Linux (\S+)" ],
                  [ \&check_distro_file, "/etc/redhat-release", "redhat", "^Red Hat Linux.*\s+([0-9.]+)" ],
                  [ \&check_distro_file, "/etc/openna-release", "openna", "^OpenNA (\S+)" ],
                  [ \&check_distro_file, "/etc/slackware-version", "slackware", "^Slackware ([0-9.]+)" ],
                  [ \&check_distro_file, "/etc/vlos-release", "vlos", "^VLOS.*\s+([0-9.]+)" ],
                  [ \&check_file_exists, "/usr/portage", "gentoo" ],
                  [ \&check_distro_file, "/etc/pld-release", "pld", "^([0-9.]+) PLD Linux" ],
                  [ \&check_rpath ],
                  [ \&check_file_exists, "/etc/arch-release", "archlinux" ],
                  [ \&check_ark ],
                  [ \&check_yoper ],
                 ],
    "FreeBSD" => [[ \&check_freebsd ]],
    "SunOS"   => [[ \&check_solaris ]]
  );

  $distro = $Utils::Backend::tool{"system"};
  $checks = $platform_checks{$distro};

  foreach $check (@$checks) {
    $func = shift (@$check);
    $dist = &$func (@$check);

    if ($dist != -1 && &ensure_platform ($dist))
    {
      $dist = &ensure_distro_map ($dist);
      $Utils::Backend::tool{"platform"} = $gst_dist = $dist;
      &Utils::Report::do_report ("platform_success", $dist);
      return;
    }
  }

  &set_platform_unsupported ($tool, $object);
  &Utils::Report::do_report ("platform_unsup", $platform);
  &Utils::Report::end ();
}

sub new
{
  my $class   = shift;
  my $service = shift;
  my $self    = $class->SUPER::new ($service, $OBJECT_PATH);

  bless $self, $class;
  &get_system ();
  &guess ($self) if !$Utils::Backend::tool{"platform"};

  return $self;
}

sub getPlatformList
{
  my ($self) = @_;
  my ($arr, $key);

  foreach $key (keys %$PLATFORM_INFO)
  {
      push @$arr, [ $$PLATFORM_INFO{$key}[0],
                    $$PLATFORM_INFO{$key}[1],
                    $$PLATFORM_INFO{$key}[2],
                    $key ];
  }

  return $arr;
}

sub getPlatform
{
  return $Utils::Backend::tool{"platform"};
}

# A directive handler that sets the currently selected platform.
sub setPlatform
{
  my ($self, $platform) = @_;

  &set_platform ($platform);
}