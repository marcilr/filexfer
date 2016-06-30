#!/usr/bin/perl

use strict;
use warnings;

use Modules::App::FileXfer::JobMonitor ();
our $VERSION = $Modules::App::FileXfer::JobMonitor::VERSION;

MAIN: {
    # Process and merge command-line and config file options
    my $getopt   = Modules::App::FileXfer::JobMonitor::get_command_line_options();
    my $fileconf = Modules::App::FileXfer::JobMonitor::read_config_file( $getopt->get_configfile );
    Modules::App::FileXfer::JobMonitor::merge_options( $getopt, $fileconf );
    
    # Make sure we're the only instance running    
    Modules::App::FileXfer::JobMonitor::check_pid_file( 
        $Modules::App::FileXfer::JobMonitor::Options->{pidfile} );
    
    # Get logger and evenge objects
    Modules::App::FileXfer::JobMonitor::create_evenge_obj();
    my $log = Modules::App::FileXfer::JobMonitor::create_logger_obj( 
        $Modules::App::FileXfer::JobMonitor::Options->{logger}, 
        $Modules::App::FileXfer::JobMonitor::Program 
    );
    
    # Get a list of job monitors
    my $jm = Modules::App::FileXfer::JobMonitor::create_jobmonitor_obj();
    my $mons = Modules::App::FileXfer::JobMonitor::get_monitors( $jm );
    
    for my $mon ( @{ $mons } )
    {
        Log::Log4perl::MDC->put( 'idJob', $mon->idJob );
        $log->info( sprintf( 'Executing monitor "%s".', $mon->monitorName ));
        
        # Set the subresource for this monitor in the evenge object
        $Modules::App::FileXfer::JobMonitor::Evenge->subresourceName( $mon->monitorName );
        
        # Execute the job monitor
        eval { Modules::App::FileXfer::JobMonitor::run_monitor( $jm, $mon ) };
        $@ and $log->error( "$@" );
    }
   
    $log->info( 'Main application exiting.' );    
}

__END__

=head1 NAME

jobmonitor -- Monitor filexfer jobs for any condition and generate alerts

=head1 VERSION

0.51

=head1 SYNOPSIS

jobmonitor.plx -c configfile [options]

=head1 ARGUMENTS

=over 4

=item -c, --configfile

Specify the configuration file to load. Must be in YAML format.

=back

=head1 OPTIONS

=over 4

=item -a, --mailhost

Address of the mail server. Used to send email notifications. Defaults to localhost.

=item -d, --piddir

Directory where the pid file will be written. Defaults to /var/run/filexfer.

=item --db

Sets the database connection parameters. Valid keys are: server (default 
localhost), port (default 3306), driver (default mysql), uid, pwd, database, 
and table. Specify tags as key/value pairs, e.g.:

    --db server=localhost --db database=filexfer

=item -e, --evengehost

Address of the Evenge web server. Used to send indicators and events to the NMS system.

=item -f, --cachefile

Template cache file location. Defaults to /var/lib/filexfer/jobmonitor.kch.

=item -h, --help

Output this documentation.

=item -i, --mailinterval

Minimum time, in seconds, before repeat emails may be sent for the same monitor. Defaults to 3600 (1 hour).

=item -l, --mailfrom

Sender's email address in email notifications. Defaults to [username]@[hostname].

=item -m, --mailstatfile

Mail status file location. Defaults to /var/lib/filexfer/jobmonitor-mailstat.kch.

=item -o, --mailport

Port on which the mail server is listening for SMTP traffic. Defaults to 25.

=item -p, --pidfile

PID file name. This will be appended with a ".pid" suffix.

=item -r, --resource

Resource name of this application. Used in indicator and event messages sent to the NMS system.

=item --verbose, -v

Log to the screen at increasingly verbose levels. This option may be repeated
multiple times to increase the log level. For example, "-v" logs at info level,
"-vv" logs at debug level, and "-vvv" logs at trace level.

=back
