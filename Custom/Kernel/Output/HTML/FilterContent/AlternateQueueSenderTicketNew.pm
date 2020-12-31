# --
# Copyright (C) 2015 - 2020 Perl-Services.de, http://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterContent::AlternateQueueSenderTicketNew;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::System::Web::Request
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};

    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get template name
    my $Templatename = $ParamObject->GetParam( Param => 'Action' );

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

    return 1;
}

1;
