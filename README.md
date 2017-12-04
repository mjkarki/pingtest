# pingtest
Pingtest is a small utility for logging network outages.

I created this script to monitor and analyze my Internet connection reliability.

Pingtest is a Perl script, which sends a ping every 10 seconds to check if the network connection is up. If the ping fails, the script starts to poll the connection every second to determine the duration of the network outage. The start and the end times are logged to a file.

```
Checks the state of an network connection by sending single PING messages
to Google DNS server. Script takes into account, if there is a single
failed PING (propably just a temporary problem) or if there really is a
larger problem with the connection.
```
```
Usage: pingtest.pl [-hwlvVL] [-t time] [-a address] [-o logfile]

    -h         : this help message
    -w         : use Windows ping command (default)
    -l         : use Linux ping command
    -v         : verbose output
    -V         : show version number
    -L         : show license information
    -t time    : time in seconds between pings (defalut: 10)
    -a address : ping the given address (default: $address)
    -o logfile : save log to logfile (default: $logfile)\n";
```
