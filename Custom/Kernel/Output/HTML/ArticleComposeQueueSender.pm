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
use Kernel::System::QueueSender;
use Kernel::System::SystemAddress;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    for my $Object ( qw/QueueObject MainObject DBObject EncodeObject ConfigObject UserObject LogObject TimeObject LayoutObject/ ) {
        $Self->{$Object} = $Param{$Object} || '';
    }

    $Self->{QueueSenderObject}   = Kernel::System::QueueSender->new( %{$Self} );
    $Self->{SystemAddressObject} = Kernel::System::SystemAddress->new( %{$Self} );

    $Self->{UserID} = $Param{UserID};

    return $Self;
}

sub Option {
    my ( $Self, %Param ) = @_;

    return ('From');
}

sub Run {
    my ( $Self, %Param ) = @_;

    my %SenderList = $Self->Data( %Param );
    
    my $LayoutObject = $Self->{LayoutObject};

    my $List = $LayoutObject->BuildSelection(
        Data         => \%SenderList,
        Name         => 'From',
        HTMLQuote    => 1,
        SelectedID   => $Param{From} || $Self->{SelectedAddress},
        AutoComplete => 'off',
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

    my %SenderList;

    if ( $Param{QueueID} ) {

        my %List  = $Self->{QueueSenderObject}->QueueSenderGet( QueueID => $Param{QueueID} );
        my %Queue = $Self->{QueueObject}->QueueGet(
            ID => $Param{QueueID},
        );

        my $QueueSystemAddressID = $Queue{SystemAddressID};
        my $Template             = $Self->{QueueSenderObject}->QueueSenderTemplateGet(
            QueueID => $Param{QueueID},
        );

        my %IDAddressMap;

        if ( $Template ) {
            my %UserData   = $Self->{UserObject}->GetUserData(
                UserID => $Self->{UserID},
            );

            $Template =~ s{<OTRS_([^>]+)>}{$UserData{$1}}xsmg;
        }

        for my $ID ( keys %List, $Queue{SystemAddressID} ) {
            my %Address = $Self->{SystemAddressObject}->SystemAddressGet(
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
