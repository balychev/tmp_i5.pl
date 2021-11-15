#!/usr/bin/env perl

=pod

Этот скрипт появился как результат выполнения некоего тестового задания, которое звучало так:

Есть пул из 253 ip-адресов. Из пула выделяются комбинации по 5 ip-адресов и закрепляются за некоторым объектом.
Каждый адрес может быть привязан более чем к одному объекту, но комбинация адресов каждого объекта должна быть уникальной,
без учета порядка. [...] Нужно с минимальным расходом машинных ресурсов найти незанятую комбинацию ip-адресов с учетом того,
что "используемость" адресов пула должна быть равномерной(т.е. избегать ситуации, когда несколько адресов связаны
с существенно большим числом объектов, чем остальные) [...]. 

=cut


use strict;
use warnings;
use 5.010;

# количество адресов, предназначенных для одного объекта
my $ipset_size = 5;

# диапазон доступных для выбора адресов
my @ipaddr_pool = (ip2long("212.85.0.1")..ip2long("212.85.0.253"));

# хэш для хранения информации об объектах 
# { номер объекта, [ip-адрес, ip-адрес...] }
my $obj = {};

# Здесь последовательно выводятся на экран 10000 строк с уникальным набором ip-адресов по 5 штук
# 
populate (10000,\@ipaddr_pool,$ipset_size);
sub populate {
    my ($nobj, $ipaddr_pool, $ipset_size) = @_;
    shuffle($ipaddr_pool);
    foreach (0..$nobj) {
       my $rr = ${nested_loop( $#$ipaddr_pool, $ipset_size-1, 1)}[0];
       die "Finita la comedia" unless $rr;
       $obj->{$_} = [sort { $a <=> $b } (map { $ipaddr_pool->[$_] } @$rr)];
       say "# $_: ", join("; ", map { long2ip($_) }  @{$obj->{$_}} );
       move2tail($ipaddr_pool,$rr);
    }
}    
#
#---------------------------------------------------------------------------------------------

sub nested_loop {
    my ($maxidx, $maxdep, $find_n_stop) = @_; 
    my $result_sets = [];

    local *loop = sub {
        state $count = 0;
        state $depth = 0;
        state $ipset = [];
        state $pos = { -1 => -1 };
        if (defined $pos->{$depth}) {
           $pos->{$depth}++;  
        }    
        else {
           $pos->{$depth} = $pos->{$depth-1} + 1;
        }  
        foreach ( $depth+1..$maxdep ) {
           $pos->{$_} = undef;  
        }    
        for (my $i=$pos->{$depth}; $i <= $maxidx; $i++) {
            $ipset->[$depth]=$i;
            if ( $depth == $maxdep ) {
               if ( is_ipset_unique($ipset) ) {
                   my @res = @$ipset;
                   $result_sets->[$count]=\@res;
                   $count++;
                   if (defined($find_n_stop) && $count >= $find_n_stop) {
                      return 'done';
                   }
               }    
            }    
            else {
               $depth++;
               return 'done' if ( loop() eq 'done' );
            }
        }
        $pos->{$depth--}++;
        while ( $pos->{$depth} > $maxidx - $maxdep + $depth) {
           if ( $depth gt 0 ) {
              $pos->{$depth--}++;
           }
           else {
              return 'done';
           }
        }
        return 'done' if ( loop() eq 'done' );
    };
    
    loop();
    return $result_sets;
}

sub is_ipset_unique {
    my $iptest = shift;
    $iptest = [sort { $a <=> $b } (map { $ipaddr_pool[$_] } @$iptest)];
    my $id; my $ipset; my $k;
    foreach (keys(%$obj))  {
        my $count = 0;
        foreach ($k=0; $k<=$#$iptest; $k++) {
            if ( $obj->{$_}->[$k] eq $iptest->[$k] ) {
                $count++;
            }
            else {
                last;  
            }     
        }
        return 0 if $count == @$iptest;
    }
    return 1;     
}    


sub ip2long {
    my @a = split (/\./, shift);
    return $a[0]*0x1000000 + $a[1]*0x10000 + $a[2]*0x100 + $a[3];
}

sub long2ip {
    my $l = shift;
    my $a = [($l & 0xff000000) / 0x1000000, ($l & 0xff0000) / 0x10000,($l & 0xff00) / 0x100, $l & 0xff];
    return join('.', @$a);
} 

sub shuffle {
    my $arr = shift;
    for ( my $i = $#$arr; $i>0; $i-- ) {
        my $j = int rand($i+1);
        next if ( $j == $i );
        @$arr[$i,$j] = @$arr[$j,$i];
    }    

}    

sub move2tail {
   my ( $queue, $ordered_group ) = @_;
   my $j = 0;
   foreach (@$ordered_group) {
      @$queue[$_-$j..$#$queue] = @$queue[$_+1-$j..$#$queue,$_-$j];
      $j++;
   }    
}    



