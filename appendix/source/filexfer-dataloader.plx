#!/usr/bin/perl

use strict;
use warnings;

use Modules::App::FileXfer::DataLoader ();
our $VERSION = $Modules::App::FileXfer::DataLoader::VERSION;

MAIN: {
    # Process and merge command-line and config file options
    my $getopt   = Modules::App::FileXfer::DataLoader::get_command_line_options();
    my $fileconf = Modules::App::FileXfer::DataLoader::read_config_file( $getopt->get_configfile );
    Modules::App::FileXfer::DataLoader::merge_options( $getopt, $fileconf );
    
    # Make sure we're the only instance running    
    Modules::App::FileXfer::DataLoader::check_pid_file( 
        $Modules::App::FileXfer::DataLoader::Options->{pidfile} );
    
    # Get logger and evenge objects
    Modules::App::FileXfer::DataLoader::create_evenge_obj();
    my $logger = Modules::App::FileXfer::DataLoader::create_logger_obj( 
        $Modules::App::FileXfer::DataLoader::Options->{logger}, 
        $Modules::App::FileXfer::DataLoader::Program 
    );
    
    # Get the load jobs with pending files
    my $dl   = Modules::App::FileXfer::DataLoader::create_dataloader_obj();
    my $jobs = Modules::App::FileXfer::DataLoader::get_load_jobs( $dl );
    
    for my $job ( @{ $jobs } )
    {
        next if 414 == $job->idJob;
        Log::Log4perl::MDC->put( 'idJob', $job->idJob );
        $logger->info( sprintf( 'Executing job "%s".', $job->jobName ));

        eval {
            # Get the list of pending load files
            my $files = Modules::App::FileXfer::DataLoader::list_load_files( $dl, $job );
            next unless scalar @{ $files };

            # Import the class for this job's files
            Modules::App::FileXfer::DataLoader::import_file_class( $files->[0]->{fileclass} );
            
            # Bulk load the data from each file
            for my $file ( @{ $files } )
            {
                Modules::App::FileXfer::DataLoader::load_file_data( $dl, $job, $file );
                Modules::App::FileXfer::DataLoader::dequeue_load_file( $dl, $job, $file );
            }
        };

        $@ and $logger->error( "$@" );

        # Close the external db handle
        $dl->close_ext_dbh();        
    }
    
    $logger->info( 'Main application exiting.' );    
    exit;
}

__END__

=head1 NAME

filexfer-dataloader -- Bulk load file data from filexfer into a database table.

=head1 VERSION

0.51

=head1 SYNOPSIS

filexfer-dataloader -c configfile [options]

=head1 ARGUMENTS

=over 4

=item -c, --configfile

Specify the configuration file to load. Must be in YAML format.

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

Template cache file location. Defaults to /var/lib/filexfer/dataloader.kch.

=item -h, --help

Output this documentation.

=item -p, --pidfile

PID file name. This will be appended with a ".pid" suffix.

=item -r, --resource

Resource name of this application. Used in indicator and event messages sent to the NMS system.

=item --verbose, -v

Log to the screen at increasingly verbose levels. This option may be repeated
multiple times to increase the log level. For example, "-v" logs at info level,
"-vv" logs at debug level, and "-vvv" logs at trace level.

=back
