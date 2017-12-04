#!/usr/bin/perl -w

# Checks the state of an network connection by sending single PING messages
# to Google DNS server. Script takes into account, if there is a single
# failed PING (propably just a temporary problem) or if there really is a
# larger problem with the connection.

use strict;
use warnings;

use Getopt::Std;

my ($helptext, $cmdline, $address, $logfile, $delay, $timestamp, $retval,
    $state, $isFirst, $tmp, %opts, $version, $verbose, $userdelay);

$version = 4;

$cmdline = 'ping -n 1 > NUL';   # Windows
$address = '8.8.8.8';
$logfile = 'ping.log';
$userdelay = $delay = 10;
$verbose = 0;

$helptext = "\nusage: $0 [-hwlvVL] [-t time] [-a address] [-o logfile]

    -h         : this help message
    -w         : use Windows ping command (default)
    -l         : use Linux ping command
    -v         : verbose output
    -V         : show version number
    -L         : show license information
    -t time    : time in seconds between pings (defalut: 10)
    -a address : ping the given address (default: $address)
    -o logfile : save log to logfile (default: $logfile)\n";

exit if (!getopts("hwlvVLt:a:o:", \%opts));

if ($opts{h}) {
    print $helptext;
    exit;
}

if ($opts{V}) {
    print "\nThis is version $version.\n";
    exit;
}

if ($opts{L}) {
    printLicense();
    exit;
}

$cmdline   = 'ping -n 1 > NUL'       if $opts{w};
$cmdline   = 'ping -c 1 > /dev/null' if $opts{l};
$address   = $opts{a}                if $opts{a};
$logfile   = $opts{o}                if $opts{o};
$userdelay = $delay = $opts{t}       if $opts{t};
$verbose   = $opts{v}                if $opts{v};

$state = 1;    # 1 = connection OK, 0 no connection.
$isFirst = 0;  # 1 = first failure, 0 no failure / several failures
$timestamp = time;

open LOG, ">>$logfile" or die "cannot open the log file: $!";
print LOG "\n*** Pinging started at ";
print LOG makeTimeStamp($timestamp);
print LOG ". ***\n\n";
close LOG;

while (1) {
    
    verbosePrint("Sending ping... ", $verbose);
    
    $retval = system("$cmdline $address");
    
    verbosePrint("ping return value is $retval.\n", $verbose, 1);

    if ($retval != 0 && $state == 1) {
        # We just lost the connection.
        
        $timestamp = time;
        $state = 0;
        $isFirst = 1;
        $delay = 1;

        verbosePrint("We just lost the connection!\n", $verbose);
    }
    elsif ($retval != 0 && $state == 0) {
        # Still off-line, reset the isFirst flag.
        
        $isFirst = 0;

        verbosePrint("Off-line. Connection is broken.\n", $verbose);
    }
    elsif ($retval == 0 && $state == 0) {
        # We are back on-line.
        
        if ($isFirst == 0) {
            $tmp = $timestamp;
            
            open LOG, ">>$logfile" or die "cannot open the log file: $!\n";
            
            print LOG "No connection between ";
            print LOG makeTimeStamp($timestamp);
            print LOG " - ";

            $timestamp = time;

            print LOG makeTimeStamp($timestamp);
            print LOG "  downtime: ";
            
            if (($timestamp - $tmp) >= 60) {
                printf LOG "%.2f minutes.", (($timestamp - $tmp) / 60);
            }
            else {
                printf LOG "%d seconds.", ($timestamp - $tmp);
            }
            
            print LOG "\n";
            
            close LOG;

            verbosePrint("Back on-line.\n", $verbose);
        }
        else {
            verbosePrint("Only one failure. Disregarding.\n", $verbose);
        }

        $state = 1;
        $isFirst = 0;
        $delay = $userdelay;
    }
    
    sleep $delay;
}

sub makeTimeStamp {
    my $t = shift;
    my @lt = localtime($t);
    
    return sprintf("%04d-%02d-%02d %02d:%02d:%02s",
                   1900 + $lt[5], 1 + $lt[4], $lt[3], $lt[2], $lt[1], $lt[0]);
}

# Print to stdout if verbose mode on.
#
# Parameters:
#
# verbosePrint(string, isVerbose, suppressTimestamp)
#
# string            : string to be printed
# isVerbose         : verbose mode flag
# suppressTimestamp : is true, do not insert time stamp

sub verbosePrint {
    my $s = shift;
    my $b = shift;
    my $t = shift;

    if ($t) {
        print "$s" if $b;
    }
    else {
        print "[" . makeTimeStamp(time) . "] $s" if $b;
    }
}

sub printLicense {
    print '
BSD 3-Clause License

Copyright (c) 2010, Matti J. Kärki
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
';
}
