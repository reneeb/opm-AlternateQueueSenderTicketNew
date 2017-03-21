# --
# Kernel/Output/HTML/ArticleComposeQueueSender.pm
# Copyright (C) 2015 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::ArticleComposeQueueSender;

use strict;
use warnings;

use Mail::Address;

our @ObjectDependencies = qw(
    Kernel::System::QueueSender
    Kernel::System::Queue
    Kernel::System::User
    Kernel::System::SystemAddress
    Kernel::Output::HTML::Layout
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{UserID} = $Param{UserID};
    $Self->{Action} = $Param{Action};

    return $Self;
}

sub Option {
    my ( $Self, %Param ) = @_;

    return if !$Self->{Action} || $Self->{Action} ne 'AgentTicketEmail';

    return ('From');
}

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Self->{Action} || $Self->{Action} ne 'AgentTicketEmail';

    my %SenderList = $Self->Data( %Param );
    
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $List = $LayoutObject->BuildSelection(
        Data         => \%SenderList,
        Name         => 'From',
        HTMLQuote    => 1,
        SelectedID   => $Param{From} || $Self->{SelectedAddress},
        AutoComplete => 'off',
        Class        => 'Modernize',
    );

    $LayoutObject->Block(
        Name => 'Option',
        Data => {
            Name  => 'From',
            Key   => 'From',
            Value => $List,
        },
    );

    return;
}

sub ArticleOption {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{From};

    $Value =~ s{&lt;}{<};
    $Value =~ s{&gt;}{>};

    return From => $Value;
}

sub GetParamAJAX {
    my ($Self, %Param) = @_;

    return From => $Self->{SelectedAddress};
}

sub Data {
    my ($Self, %Param) = @_;

    return if !$Self->{Action} || $Self->{Action} ne 'AgentTicketEmail';

    my %SenderList;

    if ( $Param{QueueID} ) {

        my $QueueSenderObject   = $Kernel::OM->Get('Kernel::System::QueueSender');
        my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');
        my $UserObject          = $Kernel::OM->Get('Kernel::System::User');
        my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');

        my %List  = $QueueSenderObject->QueueSenderGet( QueueID => $Param{QueueID} );
        my %Queue = $QueueObject->QueueGet(
            ID => $Param{QueueID},
        );

        my $QueueSystemAddressID = $Queue{SystemAddressID};
        my $Template             = $QueueSenderObject->QueueSenderTemplateGet(
            QueueID => $Param{QueueID},
        );

        my %IDAddressMap;

        if ( $Template ) {
            my %UserData = $UserObject->GetUserData(
                UserID => $Self->{UserID},
            );

            $Template =~ s{<OTRS_([^>]+)>}{$UserData{$1}}xsmg;
        }

        for my $ID ( keys %List, $Queue{SystemAddressID} ) {
            my %Address = $SystemAddressObject->SystemAddressGet(
                ID => $ID,
            );

            next if !$Address{ValidID} || $Address{ValidID} != 1;

            my $Address = $Address{Realname} ? (sprintf "%s &lt;%s&gt;", $Address{Realname}, $Address{Name}) : $Address{Name};
            $SenderList{$Address} = $Address;

            if ( $Template ) {
                $Address =  sprintf "%s &lt;%s&gt;", $Template, $Address{Name};
                $SenderList{$Address} = $Address;
            }

            $IDAddressMap{ $ID } = $Address;
        }

        $Self->{SelectedAddress} = $IDAddressMap{ $QueueSystemAddressID };
    }


    return %SenderList;
}

sub Error {
    my ( $Self, %Param ) = @_;

    if ( $Self->{Error} ) {
        return %{ $Self->{Error} };
    }

    return;
}

1;
