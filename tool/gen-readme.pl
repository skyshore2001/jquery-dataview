#!perl

undef $/;
$_ = <>;
m`/\*\*\s*(.*?)\s*\*/`gs && print $1;
