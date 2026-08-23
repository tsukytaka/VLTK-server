#!/usr/bin/perl
use strict;
use warnings;
use bytes;

my $root = '/home/jxser/server1';
my @ids = qw(1055 1056 1057 1058 1059 1060 1061 1062 1063 1065 1066 1067 1069 1070 1071 1073 1074 1075 1076 1078 1079 1080 1081 1110 1114);
my %wanted = map { $_ => 1 } @ids;
my $skills_path = "$root/settings/skills.txt";

open my $sfh, '<:raw', $skills_path or die "open $skills_path: $!";
local $/;
my $skills_raw = <$sfh>;
close $sfh;

my @lines = split /\n/, $skills_raw, -1;
my @header = split /\t/, $lines[0], -1;
$header[-1] =~ s/\r$//;
my %col;
for my $i (0 .. $#header) { $col{$header[$i]} = $i; }
for my $required (qw(SkillId LvlSetScript LvlSetting1 LvlData1 LvlSetting20 LvlData20)) {
    die "missing column $required" unless exists $col{$required};
}

my %lua_edits;
my %seen;
for my $line (@lines) {
    my $had_cr = ($line =~ s/\r$//);
    my @f = split /\t/, $line, -1;
    my $id = $f[$col{SkillId}] // '';
    if ($wanted{$id}) {
        my ($block, $has_add, $empty_setting, $add_setting, $exp_setting);
        for my $n (1 .. 20) {
            my $setting = $col{"LvlSetting$n"};
            my $data = $col{"LvlData$n"};
            my $name = $f[$setting] // '';
            if ($name eq 'skill_skillexp_v') {
                $block = $f[$data];
                $exp_setting = $n;
            }
            if ($name eq 'addskillexp1') {
                $has_add = 1;
                $add_setting = $n;
            }
            $empty_setting = $n if !defined($empty_setting) && $name eq '';
        }
        die "skill $id has no skill_skillexp_v block" unless defined $block && $block ne '';
        if (!$has_add) {
            die "skill $id has no empty LvlSetting" unless defined $empty_setting;
            $f[$col{"LvlSetting$empty_setting"}] = 'addskillexp1';
            $f[$col{"LvlData$empty_setting"}] = $block;
            $add_setting = $empty_setting;
        }
        if ($add_setting > $exp_setting) {
            my $add_col = $col{"LvlSetting$add_setting"};
            my $add_data_col = $col{"LvlData$add_setting"};
            my $exp_col = $col{"LvlSetting$exp_setting"};
            my $exp_data_col = $col{"LvlData$exp_setting"};
            ($f[$add_col], $f[$exp_col]) = ($f[$exp_col], $f[$add_col]);
            ($f[$add_data_col], $f[$exp_data_col]) = ($f[$exp_data_col], $f[$add_data_col]);
        }
        my $lua_rel = $f[$col{LvlSetScript}];
        $lua_rel =~ s{\\}{/}g;
        $lua_rel =~ s{^/}{};
        push @{$lua_edits{"$root/$lua_rel"}}, [$id, $block];
        $seen{$id} = 1;
        $line = join("\t", @f) . ($had_cr ? "\r" : '');
    }
}

for my $id (@ids) { die "skill $id not found" unless $seen{$id}; }

my %new_lua;
for my $path (sort keys %lua_edits) {
    open my $lfh, '<:raw', $path or die "open $path: $!";
    my $raw = <$lfh>;
    close $lfh;
    for my $edit (@{$lua_edits{$path}}) {
        my ($id, $block) = @$edit;
        my $block_re = quotemeta($block);
        if ($raw =~ /addskillexp1=\{\{\{1,\Q$id\E\},\{2,\Q$id\E\}\}/) {
            next;
        }
        my $insert = "\t\taddskillexp1={{{1,$id},{2,$id}},{{1,1},{20,1}},{{1,0},{2,0}}}, -- Kinh nghiem luyen skill 150\r\n";
        my $count = ($raw =~ s/(^\s*$block_re\s*=\s*\{[^\r\n]*\r?\n)/$1$insert/m);
        die "cannot locate Lua block $block for skill $id in $path" unless $count == 1;
    }
    $new_lua{$path} = $raw;
}

open my $out, '>:raw', "$skills_path.tmp" or die "write $skills_path.tmp: $!";
print {$out} join("\n", @lines);
close $out;
rename "$skills_path.tmp", $skills_path or die "rename skills: $!";

for my $path (sort keys %new_lua) {
    open my $out_lua, '>:raw', "$path.tmp" or die "write $path.tmp: $!";
    print {$out_lua} $new_lua{$path};
    close $out_lua;
    rename "$path.tmp", $path or die "rename $path: $!";
}

print "Enabled combat proficiency for ".scalar(@ids)." level-150 skills.\n";
