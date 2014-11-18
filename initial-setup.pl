#!/usr/bin/perl

use strict;
use warnings;

$| = 1;

use Carp;
use IPC::Cmd;

my $provision_steps = [
    qq{grep '8.8.8.8' /etc/resolvconf/resolv.conf.d/head || echo "nameserver 8.8.8.8" >> /etc/resolvconf/resolv.conf.d/head},
    qq{resolvconf -u},

    qq{apt-get -y update},
    qq{apt-get -y install mc lynx-cur git python-pip},
    qq{apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10},
    qq{echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" > /etc/apt/sources.list.d/mongodb.list},
    qq{apt-get -y update},
    qq{apt-get -y install mongodb-org python-dev},
    qq{echo "db.createCollection('twitter.messages', { capped: true, size: 100000} )" | mongo devopscoil},
    qq{pip install tweepy pymongo},
    qq{cd /home/vagrant && rm -rf webpy && git clone git://github.com/webpy/webpy.git},

    qq{echo "export PYTHONPATH=/home/vagrant/webpy" > /etc/rc.local},
    qq{echo "/usr/bin/python /home/vagrant/streaming.py 2>>/var/log/streaming.errlog | mongoimport --db devopscoil --collection twitter.messages &" >> /etc/rc.local},
    qq{echo "nohup /usr/bin/python /home/vagrant/serve.py" >> /etc/rc.local},
    
    qq{echo "device has been provisioned"},
    qq{echo "installation log is available in /var/log/provision.log"},
    qq{echo "please wait till the device reboots and point your browser at http://127.0.0.1:8080 in a few seconds"},

    qq{reboot},
    ];

sub do_log {
    my ($line) = @_;
    my $msg = localtime() . "\t" . (($line =~ /\n$/s) ? $line : $line . "\n");
    print $msg;

    my $fh;
    open($fh, ">>/var/log/provision.log");
    print $fh $msg;
    close($fh);
}

sub do_provision {
    my $i = 0;
    STEP: foreach my $step_cmd (@{$provision_steps}) {
        $i = $i + 1;

        if ($ARGV[0] && $i < $ARGV[0]) {
            next STEP;
        }
        if ($ARGV[1] && $i > $ARGV[1]) {
            next STEP;
        }

        do_log("running [$step_cmd]");
        my $r = IPC::Cmd::run_forked($step_cmd,
            {
            'stdout_handler' => sub { do_log(join("", @_)); },
            'stderr_handler' => sub { do_log(join("", @_)); },
            });

        if ($r->{'exit_code'} != 0) {
            do_log("failed step [$i], command [$step_cmd]");
            return 0;
        }
    }
    
    return 1;
}

my $j = 0;
while (!do_provision()) {
    $j = $j + 1;
    do_log("retrying, try $j");
}
