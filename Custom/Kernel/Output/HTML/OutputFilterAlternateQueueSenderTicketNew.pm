# --
# Kernel/Output/HTML/OutputFilterAlternateQueueSenderTicketNew.pm
# Copyright (C) 2015 Perl-Services.de, http://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterAlternateQueueSenderTicketNew;

use strict;
use warnings;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};

    for my $Object ( qw/ParamObject/ ) {
        $Self->{$Object} = $Param{$Object} || die "Need $Object";
    }

    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get template name
    my $Templatename = $Self->{ParamObject}->GetParam( Param => 'Action' );

    return 1 if !$Templatename;
    return 1 if !$Param{Templates}->{$Templatename};

    if ( 
        ${ $Param{Data} } =~ s{(
            <label \s+ for="From"> [^<]+ </label>
                .*?
            class="Clear"></div>
        )}{}smx
    ) {

        my $From = $1;

        ${ $Param{Data} } =~ s{
            <select [^>]+ ="Dest"
                .*?
            class="Clear"></div>
            \K
        }{
            $From
        }smx;
    }

    return ${ $Param{Data} };
}

1;
