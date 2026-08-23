#!/usr/bin/perl
use strict;
use warnings;
use bytes;

my $root = '/home/jxser/server1';
my $exp_path = "$root/settings/npc/player/magic_level_exp.txt";

# Skill 150 => [skill 90 cung nhanh, ten block Lua cua skill 150]
my %map = (
    1055 => [318,  'quanshaolin150'],
    1056 => [319,  'gunshaolin150'],
    1057 => [321,  'daoshaolin150'],
    1058 => [322,  'daotianwang150'],
    1059 => [325,  'chuitianwang150'],
    1060 => [323,  'qiangtianwang150'],
    1061 => [328,  'jianemei150'],
    1062 => [380,  'zhangemei150'],
    1063 => [336,  'daocuiyan150'],
    1065 => [337,  'neicuiyan150'],
    1066 => [353,  'zhangwudu150'],
    1067 => [355,  'daowudu150'],
    1069 => [339,  'feidaotang150'],
    1070 => [302,  'nutang150'],
    1071 => [342,  'biaotang150'],
    1073 => [357,  'zhanggaibang150'],
    1074 => [359,  'gungaibang150'],
    1075 => [361,  'zhanren150'],
    1076 => [362,  'moren150'],
    1078 => [365,  'qiwudang150'],
    1079 => [368,  'jianwudang150'],
    1080 => [372,  'daokunlun150'],
    1081 => [375,  'jiankunlun150fu'],
    1110 => [342,  'pili_dan'],
    1114 => [380,  'fuzhuemei150'],
);

my %lua_file = (
    1055 => 'shaolin.lua', 1056 => 'shaolin.lua', 1057 => 'shaolin.lua',
    1058 => 'tianwang.lua', 1059 => 'tianwang.lua', 1060 => 'tianwang.lua',
    1061 => 'emei.lua', 1062 => 'emei.lua', 1114 => 'emei.lua',
    1063 => 'cuiyan.lua', 1065 => 'cuiyan.lua',
    1066 => 'wudu.lua', 1067 => 'wudu.lua',
    1069 => 'tangmen.lua', 1070 => 'tangmen.lua', 1071 => 'tangmen.lua', 1110 => 'tangmen.lua',
    1073 => 'gaibang.lua', 1074 => 'gaibang.lua',
    1075 => 'tianren.lua', 1076 => 'tianren.lua',
    1078 => 'wudang.lua', 1079 => 'wudang.lua',
    1080 => 'kunlun.lua', 1081 => 'kunlun.lua',
);

open my $efh, '<:raw', $exp_path or die "open $exp_path: $!";
my @exp_lines = <$efh>;
close $efh;

my %row;
for my $line (@exp_lines) {
    my $copy = $line;
    $copy =~ s/[\r\n]+$//;
    my @f = split /\t/, $copy, -1;
    $row{$f[0]} = \@f if defined $f[0] && $f[0] =~ /^\d+$/;
}

my %curve;
for my $target (sort {$a <=> $b} keys %map) {
    my $source = $map{$target}[0];
    die "missing source exp row $source" unless $row{$source};
    die "missing target exp row $target" unless $row{$target};
    my @values = @{$row{$source}}[3 .. 22];
    die "source $source has an empty level 1-20 value" if grep { !defined($_) || $_ eq '' } @values;
    $curve{$target} = \@values;
    @{$row{$target}}[3 .. 22] = @values;
    for my $i (23 .. 28) { $row{$target}[$i] = ''; }
}

for my $i (0 .. $#exp_lines) {
    my $copy = $exp_lines[$i];
    my $ending = ($copy =~ /\r\n$/) ? "\r\n" : "\n";
    $copy =~ s/[\r\n]+$//;
    my @f = split /\t/, $copy, -1;
    next unless defined $f[0] && exists $map{$f[0]};
    $exp_lines[$i] = join("\t", @{$row{$f[0]}}) . $ending;
}

my %raw_by_file;
for my $target (sort {$a <=> $b} keys %map) {
    my $path = "$root/script/skill/$lua_file{$target}";
    if (!exists $raw_by_file{$path}) {
        open my $lfh, '<:raw', $path or die "open $path: $!";
        local $/;
        $raw_by_file{$path} = <$lfh>;
        close $lfh;
    }
    my $raw_ref = \$raw_by_file{$path};
    my $block = $map{$target}[1];
    my $block_pos = index($$raw_ref, "\t$block={");
    die "cannot find block $block in $path" if $block_pos < 0;
    my $prop_pos = index($$raw_ref, 'skill_skillexp_v=', $block_pos);
    die "cannot find skill_skillexp_v in block $block" if $prop_pos < 0;
    my $open = index($$raw_ref, '{', $prop_pos);
    die "cannot find exp opening brace in block $block" if $open < 0;
    my $depth = 0;
    my $close = -1;
    for (my $i = $open; $i < length($$raw_ref); $i++) {
        my $c = substr($$raw_ref, $i, 1);
        $depth++ if $c eq '{';
        if ($c eq '}') {
            $depth--;
            if ($depth == 0) { $close = $i; last; }
        }
    }
    die "unbalanced exp table in block $block" if $close < 0;
    my @values = @{$curve{$target}};
    my $new = "{\r\n\t\t\t{\r\n";
    for my $level (1 .. 20) {
        $new .= "\t\t\t\t{$level,$values[$level-1]},\r\n";
    }
    $new .= "\t\t\t}\r\n\t\t}";
    substr($$raw_ref, $open, $close - $open + 1, $new);
}

open my $eout, '>:raw', "$exp_path.tmp" or die "write $exp_path.tmp: $!";
print {$eout} @exp_lines;
close $eout;
rename "$exp_path.tmp", $exp_path or die "rename $exp_path: $!";

for my $path (sort keys %raw_by_file) {
    open my $lout, '>:raw', "$path.tmp" or die "write $path.tmp: $!";
    print {$lout} $raw_by_file{$path};
    close $lout;
    rename "$path.tmp", $path or die "rename $path: $!";
}

for my $target (sort {$a <=> $b} keys %map) {
    print "$target <= $map{$target}[0] : $curve{$target}[0] .. $curve{$target}[19]\n";
}
