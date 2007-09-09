#######################################################################
#   This file is part of JMdictDB. 
#   Copyright (c) 2007 Stuart McGraw 
# 
#   JMdictDB is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published 
#   by the Free Software Foundation; either version 2 of the License, 
#   or (at your option) any later version.
# 
#   JMdictDB is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
# 
#   You should have received a copy of the GNU General Public License
#   along with JMdictDB; if not, write to the Free Software Foundation,
#   51 Franklin Street, Fifth Floor, Boston, MA  02110#1301, USA
#######################################################################

# This module contains user-defined modifiers for Petal and 
# used in the jmdict Petal templates.

package jmdicttal;

@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict;  use warnings;

# split_args() and fetch_arg() are borrowed from Petal::Utils:::Base.

sub split_args { my ($args) = @_;
	return ($args =~ /('[^']+'|\S+)/g); }

sub fetch_arg { my ($hash, $arg) = @_;
	return undef unless defined($arg);
	if ($arg =~ /\'/) { $arg =~ s/\'//g; return $arg; }
	elsif ($arg =~ /^[0-9.]+$/) { return $arg; }
	else { return $hash->fetch($arg); } }

$Petal::Hash::MODIFIERS->{'perl:'} = sub { my ($hash, $args) = @_;
	my $a = eval $args;
	return $a; };

$Petal::Hash::MODIFIERS->{'gt:'} = sub { my ($hash, $args) = @_;
	my ($a, $b, $e1, $e2);
	($e1, $e2) = jmdicttal::split_args ($args);
	$a = $hash->jmdicttal::fetch_arg ($e1);
	$b = $hash->jmdicttal::fetch_arg ($e2);
	return $a > $b; };

$Petal::Hash::MODIFIERS->{'lt:'} = sub { my ($hash, $args) = @_;
	my ($a, $b, $e1, $e2);
	($e1, $e2) = jmdicttal::split_args ($args);
	$a = $hash->jmdicttal::fetch_arg ($e1);
	$b = $hash->jmdicttal::fetch_arg ($e2);
	return $a < $b; };

$Petal::Hash::MODIFIERS->{'len:'} = sub { my ($hash, $args) = @_;
	my $a = $hash->jmdicttal::fetch_arg ($args);
	return scalar (@$a); };

$Petal::Hash::MODIFIERS->{'kwabbr:'} = sub { my ($hash, $args) = @_;
	my (@a, $t, $e, $r);
	@a = jmdicttal::split_args ($args);
	$t = $hash->jmdicttal::fetch_arg ($a[0]);
	$e = $hash->jmdicttal::fetch_arg ($a[1]);
	return $::KW->{$t}{$e}{kw}; };

$Petal::Hash::MODIFIERS->{'kwabbrs:'} = sub { my ($hash, $args) = @_;
	my ( @a, $t, $d, $e);
	@a = jmdicttal::split_args ($args);
	$t = $hash->jmdicttal::fetch_arg ($a[0]);
	$d = $hash->jmdicttal::fetch_arg ($a[1]);
	$e = $hash->jmdicttal::fetch_arg ($a[2]);
	@a = map ($::KW->{$t}{$_->{kw}}{kw}, @$e);
	return join ($d, @a); };

$Petal::Hash::MODIFIERS->{'kwfull:'} = sub { my ($hash, $args) = @_;
	my (@a, $t, $e, $a);
	@a = jmdicttal::split_args ($args);
	$t = $hash->jmdicttal::fetch_arg  ($a[0]);
	$e = $hash->jmdicttal::fetch_arg  ($a[1]);
	return $::KW->{$t}{$e}{descr}; };

$Petal::Hash::MODIFIERS->{'kwfulls:'} = sub { my ($hash, $args) = @_;
	my (@a, $t, $d, $e);
	@a = jmdicttal::split_args ($args);
	$t = $hash->jmdicttal::fetch_arg ($a[0]);
	$d = $hash->jmdicttal::fetch_arg ($a[1]);
	$e = $hash->jmdicttal::fetch_arg ($a[2]);
	@a = map ($::KW->{$t}{$_->{kw}}{descr}, @$e);
	return join ($d, @a); };

$Petal::Hash::MODIFIERS->{'freqs:'} = sub { my ($hash, $args) = @_;
	my (@a, $d, $e);
	@a = jmdicttal::split_args ($args);
	$d = $hash->jmdicttal::fetch_arg ($a[0]);
	$e = $hash->jmdicttal::fetch_arg ($a[1]);
	@a = map ($::KW->{FREQ}{$_->{kw}}{kw}.($_->{value}), @$e);
	return join ($d, @a); };

$Petal::Hash::MODIFIERS->{'h2l:'} = sub { my ($hash, $args) = @_;
	# Hash-to-list
	my (@a, $h, $k, $v);
	$h = $hash->jmdicttal::fetch_arg ($args);
	while (($k, $v) = each %$h) { push (@a, {key=>$k, val=>$v}); }
	@a = sort {$a->{key} cmp $b->{key}} @a;
	return (\@a); };

$Petal::Hash::MODIFIERS->{'join:'} = sub { my ($hash, $args) = @_;
	my ($a, $b, $e1, $e2);
	($e1, $e2) = jmdicttal::split_args ($args);
	$a = $hash->jmdicttal::fetch_arg ($e1);
	$b = $hash->jmdicttal::fetch_arg ($e2);
	return join($a, @$b); };

$Petal::Hash::MODIFIERS->{'rev:'} = sub { my ($hash, $args) = @_;
	my $a = $hash->jmdicttal::fetch_arg ($args);
	return reverse (@$a); };

1;
