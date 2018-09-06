#!/usr/bin/perl

use strict;
use warnings;

use Modules::App::FileXfer ();
our $VERSION = $Modules::App::FileXfer::VERSION;

# Core modules
use Clone qw( clone );
use File::Basename ();
use File::Spec ();
use POSIX ();

$SIG{CHLD} = \&Modules::App::FileXfer::REAPER;

MAIN: {
    # Process and merge command-line and config file options
    my $getopt   = Modules::App::FileXfer::get_command_line_options();
    my $fileconf = Modules::App::FileXfer::read_config_file( $getopt->get_configfile );
    Modules::App::FileXfer::merge_options( $getopt, $fileconf );
    
    # Make sure we're the only instance running    
    Modules::App::FileXfer::check_pid_file( $Modules::App::FileXfer::Options->{pidfile} );
    
    # Get logger and evenge objects
    Modules::App::FileXfer::create_evenge_obj();
    my $logger = Modules::App::FileXfer::create_logger_obj( 
        $Modules::App::FileXfer::Options->{logger}, $Modules::App::FileXfer::Program );
    
    # Get the ready jobs
    my $fx       = Modules::App::FileXfer::create_filexfer_obj( $Modules::App::FileXfer::Program );
    my $jobs     = Modules::App::FileXfer::get_jobs( $fx );
    my $loadjobs = Modules::App::FileXfer::get_jobs_with_load_jobs( $fx );
    undef $fx;
    
    for my $job ( @{ $jobs } )
    {
        # Enforce the "max children" constraint
        $logger->info( 'Max child processes reached. Waiting for one to complete before starting job.' )
            if ( scalar keys %Modules::App::FileXfer::Children 
                 >= $Modules::App::FileXfer::Options->{maxchildren} );
    
        sleep 1 while ( scalar keys %Modules::App::FileXfer::Children 
                        >= $Modules::App::FileXfer::Options->{maxchildren} );
    
        # Fork a child process for this job
        $logger->info( sprintf( 'Spawning child process for job "%s".', $job->jobName ));

        my $pid = fork;
        defined $pid or Modules::App::FileXfer::log_event( 
            5, sprintf( "Can't fork for job \"%s\": %s", $job->jobName, $! ), 'logdie' );
            
        if ( $pid == 0 ) # child
        {
            # Set random seed for this child
            srand();

            # Lower the OS scheduling priority based on job priority
            POSIX::nice( Modules::App::FileXfer::pri_to_nice( $job->priority ));

            # Add the NE name to our command line string
            $0 .= " @ARGV " . $job->neName;
            my $jobtag = Modules::App::FileXfer::get_jobtag( $job );
        
            # Set the subresource for this job in the evenge object
            $Modules::App::FileXfer::Evenge->subresourceName( $job->jobName );

            # Create a logger specific to this child process
            my $logopt = clone( $Modules::App::FileXfer::Options->{logger} );
            my ( undef, $logdir ) = File::Basename::fileparse( $logopt->{file}{filename} );
            $logopt->{file}{filename} = File::Spec->catfile( $logdir, "$jobtag.log" );

            $logger->delete();
            my $logger = Modules::App::FileXfer::create_logger_obj( $logopt, $job->jobName );
            Log::Log4perl::MDC->put( 'idJob', $job->idJob );
            
            # Make sure another instance isn't still running
            Modules::App::FileXfer::check_pid_file( $jobtag );
        
            # Create a FileXfer object for database updates
            my $fx = Modules::App::FileXfer::create_filexfer_obj( $jobtag );
        
            # Execute the job
            Modules::App::FileXfer::run_job( $fx, $job, $loadjobs );
            
            $logger->info( 'Child exiting.' );
            exit 0;
        }
        else # parent
        {
            $logger->debug( sprintf( 'Spawned child process %d for job "%s".', $pid, $job->jobName ));
            $Modules::App::FileXfer::Children{ $pid } = $job->jobName;
        }    
    }
    
    $logger->info( 'Main application exiting.' );    
}

# Safely exit
$SIG{CHLD} = 'IGNORE';

__END__

=head1 NAME

filexfer -- Move a file from point A to point B over an IP network

=head1 VERSION

0.51

=head1 SYNOPSIS

filexfer.plx -c configfile -t {get|put} [options]

=head1 ARGUMENTS

=over 4

=item -c, --configfile

Specify the configuration file to load. Must be in YAML format.

=item -t, --transfertype

One of "get" or "put". Get jobs download files and put jobs upload files.

=back

=head1 OPTIONS

=over 4

=item -d, --piddir

Directory where the pid file will be written. Defaults to /var/run/filexfer.

=item --db

Sets the database connection parameters. Valid keys are: server (default 
localhost), port (default 3306), driver (default mysql), uid, pwd, database, 
and table. Specify tags as key/value pairs, e.g.:

    --db server=localhost --db database=filexfer

=item -e, --evengehost

Address of the Evenge web server. Used to send indicators and events to the NMS system.

=item --evengetimeout

Timeout in seconds for communicating with the Evenge web server. Defaults to 10.

=item -f, --cachefile

Template cache file location. Defaults to /var/lib/filexfer/filexfer.kch.

=item -h, --help

Output this documentation.

=item -m, --maxchildren

Maximum number of child processes to spawn. Defaults to 50.

=item -p, --pidfile

PID file name. This will be appended with a ".pid" suffix.

=item -r, --resource

Resource name of this application. Used in indicator and event messages sent to the NMS system.

=item --verbose, -v

Log to the screen at increasingly verbose levels. This option may be repeated
multiple times to increase the log level. For example, "-v" logs at info level,
"-vv" logs at debug level, and "-vvv" logs at trace level.

=back
