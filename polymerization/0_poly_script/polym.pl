# Subroutines findPair() is revised by YC Lai in 2022_2_15 
# The result may be different from the tutorial

#!/usr/bin/perl

################################################################################
#
# polym.pl
# This file is part of the Polymatic distribution.
#
# Author: Lauren J. Abbott
# Version: 1.1
# Date: August 16, 2015
#
# Description: Performs a polymerization step for use within the Polymatic code.
# Finds the closest pair of 'linker' atoms satisfying all bonding criteria and
# adds all new bonds, angles, dihedrals, and impropers. Bonding criteria that
# are implemented include a maximum cutoff distance, oriential checks of angles
# between vectors and normal vectors to planes for given atoms, and intra-
# molecular bonding. Options are provided in an input script. Reads and writes
# LAMMPS data files. The Polymatic.pm module is used in this code. It must be in
# the same directory or at a file path recognized by the script (e.g., with 'use
# lib').
#
# Syntax:
#  ./polym.pl -i data.lmps
#             -t types.txt
#             -s polym.in
#             -o new.lmps
#
# Arguments:
#  1. data.lmps, LAMMPS data file of initial system (-i)
#  2. types.txt, data types text file (-t)
#  3. polym.in, input script specifying polymerization options (-l)
#  4. new.lmps, updated LAMMPS data file after polymerization step (-o)
#
################################################################################
#
# Polymatic: a general simulated polymerization algorithm
# Copyright (C) 2013, 2015 Lauren J. Abbott
#
# Polymatic is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# Polymatic is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License (COPYING)
# along with Polymatic. If not, see <http://www.gnu.org/licenses/>.
#
################################################################################

#use experimental 'smartmatch';
use strict;
use lib '../0_poly_script'; # Position of Polymatic.pm
use Polymatic();
use Math::Trig();

# Variables
my ($fileData, $fileTypes, $fileInput, $fileOut);
my (%sys, %inp, @pair, @huge_pair);
my ($type1, $type2, $type3, $type4, $type5);
my ($atom1_mol, $atom2_mol);
$type1 = 0;
$type2 = 0;
$type3 = 0;
$type4 = 0;
$type5 = 0;
# Main
readArgs();
%sys = Polymatic::readLammps($fileData);
Polymatic::readTypes($fileTypes, \%sys);
%inp = Polymatic::readPolym($fileInput);
# @pair = findPair();
findPair();
Polymatic::writeLammps($fileOut, \%sys);
printf "$type1 $type2 $type3 $type4 $type5\n";
exit @pair;

################################################################################
# Subroutines

# errExit( $error )
# Exit program and print error
sub errExit
{
    printf "Error: %s\n", $_[0];
    exit 2;
}

# readArgs( )
# Read command line arguments
sub readArgs
{
    # Variables
    my @args = @ARGV;
    my $flag;

    # Read by flag
    while (scalar(@args) > 0)
    {
        $flag = shift(@args);

        # Input file
        if ($flag eq "-i")
        {
            $fileData = shift(@args);
            errExit("LAMMPS data file '$fileData' does not exist.")
                if (! -e $fileData);
        }

        # Types file
        elsif ($flag eq "-t")
        {
            $fileTypes = shift(@args);
            errExit("Data types file '$fileTypes' does not exist.")
                if (! -e $fileTypes);
        }

        # Input script
        elsif ($flag eq "-s")
        {
            $fileInput = shift(@args);
            errExit("Input script '$fileInput' does not exist.")
                if (! -e $fileInput);
        }

        # Output file
        elsif ($flag eq "-o")
        {
            $fileOut = shift(@args);
        }

        # Help/syntax
        elsif ($flag eq "-h")
        {
            printf "Syntax: ./polym.pl -i data.lmps -t types.txt ".
                "-s polym.in -o new.lmps\n";
            exit 2;
        }

        # Error
        else
        {
            errExit("Command-line flag '$flag' not recognized.\n".
                "Syntax: ./polym.pl -i data.lmps -t types.txt ".
                "-s polym.in -o new.lmps");
        }
    }

    # Check all defined
    errExit("Output file is not defined.") if (!defined($fileOut));
    errExit("Data file is not defined.") if (!defined($fileData));
    errExit("Types file is not defined.") if (!defined($fileTypes));
    errExit("Input script is not defined.") if (!defined($fileInput));
}

# findPair( )
# Find closest pair of linker atoms meeting all bonding criteria
sub findPair
{
    # Variables
    my ($t1, $t2, $a1, $a2, $sep, $flag, $atom1_mol, $atom2_mol);
    my (@link1, @link2, @pair);
	my ($atom1_mol, $atom2_mol);
    my $closest = 0;
	$flag = 0;
	
    # Numeric atom types of linking atoms
    $t1 = $sys{'atomTypes'}{'num'}{$inp{'link'}[0][0]};
    $t2 = $sys{'atomTypes'}{'num'}{$inp{'link'}[1][0]};
    errExit("At least one linker atom does not have a ".
        "corresponding type in the given types file.")
        if (!defined($t1) || !defined($t2));

    # Find linking atoms in system
    @link1 = Polymatic::group(\@{$sys{'atoms'}{'type'}}, $t1);
    @link2 = Polymatic::group(\@{$sys{'atoms'}{'type'}}, $t2);
    errExit("Linker atoms of both types do not exist in system.")
        if (scalar(@link1) == 0 || scalar(@link2) == 0);
		
    # Check bonding criteria for all pairs
    for (my $i=0; $i < scalar(@link1); $i++)
    {
        $a1 = $link1[$i];
        for (my $j=0; $j < scalar(@link2); $j++)
        {
            $a2 = $link2[$j];
		
			
            # Intra check
            if (defined($inp{'intra'})) {
                next if (intra([$a1, $a2]));
            } else {
                next if ($sys{'atoms'}{'mol'}[$a1] ==
                    $sys{'atoms'}{'mol'}[$a2]);
            }

            # Cutoff check
            $sep = Polymatic::getSep(\%sys, $a1, $a2);
            next if ($sep > $inp{'cutoff'});

            # Alignment check
            if (defined($inp{'align'})) {
                next if (!aligned([$a1, $a2]));
            }
			
			# Show found pair
			@pair = sort ($a1, $a2);
			# printf "Inside Pair: (%d,%d)\n",$pair[0], $pair[1];
			
			# If found before, ignore, else update
			if ($pair[0] ~~ @huge_pair) {
				if ($pair[1] ~~ @huge_pair) {
					printf "Pair: %.2f A (%d,%d) has been created\n", $sep, $pair[0], $pair[1];
				} else {
					printf "Pair: %.2f A (%d,%d) , both has been bonded\n", $sep, $pair[0], $pair[1];
				}
			}
			elsif ($pair[1] ~~ @huge_pair) {
				if ($pair[0] ~~ @huge_pair) {
					printf "Pair: %.2f A (%d,%d) has been created\n", $sep, $pair[0], $pair[1];
				} else {
					printf "Pair: %.2f A (%d,%d) , both has been bonded\n", $sep, $pair[0], $pair[1];
				}				
			}
			else {
				push(@huge_pair,@pair);
				# printf "Not found\n";
				printf "\nCreating Pair: %.2f A (%d,%d)\n\n", $sep, $pair[0], $pair[1];
				$flag = 1;
				# if ($pair[0] <= 2154 || $pair[0] >= 7226 ) {
					# if ($pair[1] <= 2154 || $pair[0] >= 7226 ) {
						
					# }
				# }
				
				# Calculate crosslink type
				# Get fragment by atom serial
				if ($pair[0] >= 1 && $pair[0]<= 718 ) {
					$atom1_mol = 0;
				}
				elsif ($pair[0] >= 719 && $pair[0]<= 1436 ) {
					$atom1_mol = 1;
				}
				elsif ($pair[0] >= 1437 && $pair[0]<= 2154 ) {
					$atom1_mol = 2;
				}
				elsif ($pair[0] >= 2155 && $pair[0]<= 2825 ) {
					$atom1_mol = 3;
				}
				elsif ($pair[0] >= 2826 && $pair[0]<= 3457 ) {
					$atom1_mol = 4;
				}
				elsif ($pair[0] >= 3458 && $pair[0]<= 4051 ) {
					$atom1_mol = 5;
				}
				elsif ($pair[0] >= 4052 && $pair[0]<= 4654 ) {
					$atom1_mol = 6;
				}
				elsif ($pair[0] >= 4655 && $pair[0]<= 5025 ) {
					$atom1_mol = 7;
				}
				elsif ($pair[0] >= 5026 && $pair[0]<= 5752 ) {
					$atom1_mol = 8;
				}
				elsif ($pair[0] >= 5753 && $pair[0]<= 6479 ) {
					$atom1_mol = 9;
				}
				elsif ($pair[0] >= 6480 && $pair[0]<= 7225 ) {
					$atom1_mol = 10;
				}
				elsif ($pair[0] >= 7226 && $pair[0]<= 7943 ) {
					$atom1_mol = 11;
				}
				elsif ($pair[0] >= 7944 && $pair[0]<= 8661 ) {
					$atom1_mol = 12;
				}
				elsif ($pair[0] >= 8662 && $pair[0]<= 9379 ) {
					$atom1_mol = 13;
				}
				elsif ($pair[0] >= 9380 && $pair[0]<= 10097 ) {
					$atom1_mol = 14;
				}
				elsif ($pair[0] >= 10098 && $pair[0]<= 10815 ) {
					$atom1_mol = 15;
				}
				elsif ($pair[0] >= 10816 && $pair[0]<= 11533 ) {
					$atom1_mol = 16;
				}
				elsif ($pair[0] >= 11534 && $pair[0]<= 12251 ) {
					$atom1_mol = 17;
				}
				elsif ($pair[0] >= 12252 && $pair[0]<= 12969 ) {
					$atom1_mol = 18;
				}
				elsif ($pair[0] >= 12970 && $pair[0]<= 13687 ) {
					$atom1_mol = 19;
				}
				elsif ($pair[0] >= 13688 && $pair[0]<= 14405 ) {
					$atom1_mol = 20;
				}
				elsif ($pair[0] >= 14406 && $pair[0]<= 15123 ) {
					$atom1_mol = 21;
				}
				elsif ($pair[0] >= 15124 && $pair[0]<= 15841 ) {
					$atom1_mol = 22;
				}
				elsif ($pair[0] >= 15842 && $pair[0]<= 16559 ) {
					$atom1_mol = 23;
				}
				elsif ($pair[0] >= 16560 && $pair[0]<= 17277 ) {
					$atom1_mol = 24;
				}
				elsif ($pair[0] >= 17278 && $pair[0]<= 17995 ) {
					$atom1_mol = 25;
				}
				elsif ($pair[0] >= 17996 && $pair[0]<= 18713 ) {
					$atom1_mol = 26;
				}
				elsif ($pair[0] >= 18714 && $pair[0]<= 19431 ) {
					$atom1_mol = 27;
				}
				elsif ($pair[0] >= 19432 && $pair[0]<= 20149 ) {
					$atom1_mol = 28;
				}
				
				if ($pair[1] >= 1 && $pair[1]<= 718 ) {
					$atom2_mol = 0;
				}
				elsif ($pair[1] >= 719 && $pair[1]<= 1436 ) {
					$atom2_mol = 1;
				}
				elsif ($pair[1] >= 1437 && $pair[1]<= 2154 ) {
					$atom2_mol = 2;
				}
				elsif ($pair[1] >= 2155 && $pair[1]<= 2825 ) {
					$atom2_mol = 3;
				}
				elsif ($pair[1] >= 2826 && $pair[1]<= 3457 ) {
					$atom2_mol = 4;
				}
				elsif ($pair[1] >= 3458 && $pair[1]<= 4051 ) {
					$atom2_mol = 5;
				}
				elsif ($pair[1] >= 4052 && $pair[1]<= 4654 ) {
					$atom2_mol = 6;
				}
				elsif ($pair[1] >= 4655 && $pair[1]<= 5025 ) {
					$atom2_mol = 7;
				}
				elsif ($pair[1] >= 5026 && $pair[1]<= 5752 ) {
					$atom2_mol = 8;
				}
				elsif ($pair[1] >= 5753 && $pair[1]<= 6479 ) {
					$atom2_mol = 9;
				}
				elsif ($pair[1] >= 6480 && $pair[1]<= 7225 ) {
					$atom2_mol = 10;
				}
				elsif ($pair[1] >= 7226 && $pair[1]<= 7943 ) {
					$atom2_mol = 11;
				}
				elsif ($pair[1] >= 7944 && $pair[1]<= 8661 ) {
					$atom2_mol = 12;
				}
				elsif ($pair[1] >= 8662 && $pair[1]<= 9379 ) {
					$atom2_mol = 13;
				}
				elsif ($pair[1] >= 9380 && $pair[1]<= 10097 ) {
					$atom2_mol = 14;
				}
				elsif ($pair[1] >= 10098 && $pair[1]<= 10815 ) {
					$atom2_mol = 15;
				}
				elsif ($pair[1] >= 10816 && $pair[1]<= 11533 ) {
					$atom2_mol = 16;
				}
				elsif ($pair[1] >= 11534 && $pair[1]<= 12251 ) {
					$atom2_mol = 17;
				}
				elsif ($pair[1] >= 12252 && $pair[1]<= 12969 ) {
					$atom2_mol = 18;
				}
				elsif ($pair[1] >= 12970 && $pair[1]<= 13687 ) {
					$atom2_mol = 19;
				}
				elsif ($pair[1] >= 13688 && $pair[1]<= 14405 ) {
					$atom2_mol = 20;
				}
				elsif ($pair[1] >= 14406 && $pair[1]<= 15123 ) {
					$atom2_mol = 21;
				}
				elsif ($pair[1] >= 15124 && $pair[1]<= 15841 ) {
					$atom2_mol = 22;
				}
				elsif ($pair[1] >= 15842 && $pair[1]<= 16559 ) {
					$atom2_mol = 23;
				}
				elsif ($pair[1] >= 16560 && $pair[1]<= 17277 ) {
					$atom2_mol = 24;
				}
				elsif ($pair[1] >= 17278 && $pair[1]<= 17995 ) {
					$atom2_mol = 25;
				}
				elsif ($pair[1] >= 17996 && $pair[1]<= 18713 ) {
					$atom2_mol = 26;
				}
				elsif ($pair[1] >= 18714 && $pair[1]<= 19431 ) {
					$atom2_mol = 27;
				}
				elsif ($pair[1] >= 19432 && $pair[1]<= 20149 ) {
					$atom2_mol = 28;
				}				
				
				
				# Type 1: Self KEMA
				# Type 2: KEMA KEMA
				# Type 3: Self GCMA
				# Type 4: GCMA GCMA
				# Type 5: KEMA GCMA
				if ($atom1_mol == $atom2_mol) {
					if ($atom1_mol >=3 && $atom1_mol<=10) {
						$type1 += 1;
					}
					else {
						$type3 += 1;
					}
				}
				else {
					if ($atom1_mol >=3 && $atom1_mol<=10) {
						if ($atom2_mol >=3 && $atom2_mol<=10) {
							$type2 += 1;
						}
						else {
							$type5 += 1;
						}
					}
					else {
						if ($atom2_mol >=3 && $atom2_mol<=10) {
							$type5 += 1;
						}
						else {
							$type4 += 1;
						}
					}
					
				}
				makeUpdates(\@pair);
			}
			
            # Save pair if closest
            # if ($closest == 0 || $sep < $closest) {
                # $closest = $sep;
                # @pair = ($a1, $a2);
            # }
        }
    }
	
	# If not found, exit with code 3
	if ($flag ==0) {
		printf "No bonding found\n";
		exit 3;
	}
	
    # Return closest pair
    # if ($closest == 0) {
        # exit 3;
    # } else {
        # printf "  Pair: %.2f A (%d,%d)\n", $closest, $pair[0], $pair[1];
        # return @pair;
    # }
}

# makeUpdates( \@pair )
# Update connectivity of system with new bond between given pair
sub makeUpdates
{
    # Variables
    my @pair = @{$_[0]};
    my ($t1, $t1n, $t2, $t2n, $a1, $a2, $a3, $a4);
    my ($type, $order, $num, $min, $max);
	my ($temp_atom);
    my (@addBonds, @addAngles, @addDiheds, @addImprops);
    my (@update, @a, @bonded1, @bonded2, @bonded3);
    my $at = 'atomTypes';

    # New bonds
    push(@addBonds, [@pair]);
    push(@addBonds, getExtraBonds(\@pair))
        if (defined($inp{'bond'}));


    # Numeric atom types for linker atoms
    $t1 = $sys{$at}{'num'}{$inp{'link'}[0][0]};
    $t1n = $sys{$at}{'num'}{$inp{'link'}[0][1]};
    $t2 = $sys{$at}{'num'}{$inp{'link'}[1][0]};
    $t2n = $sys{$at}{'num'}{$inp{'link'}[1][1]};
    errExit("At least one linker atom does not have a ".
        "corresponding type in the given types file.")
        if (!defined($t1n) || !defined($t2n));
		
	
    # Update atoms in bonds
    for (my $i=0; $i < scalar(@addBonds); $i++)
    {
        # Atoms in bond
        ($a1, $a2) = @{$addBonds[$i]};		
        push(@{$sys{'atoms'}{'bonded'}[$a1]}, $a2);
        push(@{$sys{'atoms'}{'bonded'}[$a2]}, $a1);

        # Charges
        if (defined($inp{'charge'}) &&
            $sys{'atoms'}{'type'}[$a1] == $t1 &&
            $sys{'atoms'}{'type'}[$a2] == $t2)
        {
            $sys{'atoms'}{'q'}[$a1] += $inp{'charge'}[0];
            $sys{'atoms'}{'q'}[$a2] += $inp{'charge'}[1];
        }

        # Atom types
        $sys{'atoms'}{'type'}[$a1] = $t1n
            if ($sys{'atoms'}{'type'}[$a1] == $t1);
        $sys{'atoms'}{'type'}[$a2] = $t2n
            if ($sys{'atoms'}{'type'}[$a2] == $t2);
			
		# Get surrounding atoms and change charges
		#
		#                 H18
		#                /
		#              C17--H19
		#              ||
		#   N-C15------C16  H110
		#     ||        \  /
		#     O13        C18--H111		
		#                 \		
		#                  H112		
		#
		# ASNMA for example:
		# C17     : +0.154 (change from -0.415  to -0.216 )
		# H18 H19 : -0.12  (change from  0.21   to  0.09  )
		# C16     : -0.269 (change from  0.282  to  0.013 )
		# C15     : +0.1775(change from  0.3575 to  0.535 )  
		# O13     : +0.1775(change from -0.568  to -0.3905) 
		#
		
		# H18 H19
		$temp_atom = $a1 + 1;
		$sys{'atoms'}{'q'}[$temp_atom] -= 0.12;
		$temp_atom = $a1 + 2;
		$sys{'atoms'}{'q'}[$temp_atom] -= 0.12;
		
		# C16
		$temp_atom = $a1 - 6;
		$sys{'atoms'}{'q'}[$temp_atom] -= 0.269;
		
		# C15
		$temp_atom = $a1 - 7;
		$sys{'atoms'}{'q'}[$temp_atom] += 0.1775;
		
		# O13
		$temp_atom = $a1 - 1;
		$sys{'atoms'}{'q'}[$temp_atom] += 0.1775;
		
		# H18 H19
		$temp_atom = $a2 + 1;
		$sys{'atoms'}{'q'}[$temp_atom] -= 0.12;
		$temp_atom = $a2 + 2;
		$sys{'atoms'}{'q'}[$temp_atom] -= 0.12;
		
		# C16
		$temp_atom = $a2 - 6;
		$sys{'atoms'}{'q'}[$temp_atom] -= 0.269;
		
		# C15
		$temp_atom = $a2 - 7;
		$sys{'atoms'}{'q'}[$temp_atom] += 0.1775;
		
		# O13
		$temp_atom = $a2 - 1;
		$sys{'atoms'}{'q'}[$temp_atom] += 0.1775;
    }

    # Update affected bonded terms
    for (my $i=0; $i < scalar(@addBonds); $i++)
    {
        # Atoms in bond
        ($a1, $a2) = @{$addBonds[$i]};

        # Bonds
        @update = Polymatic::uniqueArray((@{$sys{'atoms'}{'bonds'}[$a1]},
            @{$sys{'atoms'}{'bonds'}[$a2]}));
        for (my $j=0; $j < scalar(@update); $j++)
        {
            @a = @{$sys{'bonds'}{'atoms'}[$update[$j]]};
            $type = Polymatic::getBondType(\%sys, \@a);

            if ($type > 0)
            {
                $sys{'bonds'}{'type'}[$update[$j]] = $type;
            }
            elsif ($type < 0)
            {
                $sys{'bonds'}{'type'}[$update[$j]] = -1*$type;
                $sys{'bonds'}{'atoms'}[$update[$j]] = [reverse(@a)];
            }
            else
            {
                errExit("Bond type '".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[0]]].",".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[1]]].
                    "' is not defined.");
            }
        }

        # Angles
        @update = Polymatic::uniqueArray((@{$sys{'atoms'}{'angles'}[$a1]},
            @{$sys{'atoms'}{'angles'}[$a2]}));
        for (my $j=0; $j < scalar(@update); $j++)
        {
            @a = @{$sys{'angles'}{'atoms'}[$update[$j]]};
            $type = Polymatic::getAngleType(\%sys, \@a);

            if ($type > 0)
            {
                $sys{'angles'}{'type'}[$update[$j]] = $type;
            }
            elsif ($type < 0)
            {
                $sys{'angles'}{'type'}[$update[$j]] = -1*$type;
                $sys{'angles'}{'atoms'}[$update[$j]] = [reverse(@a)];
            }
            else
            {
                errExit("Angle type '".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[0]]].",".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[1]]].",".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[2]]].
                    "' is not defined.");
            }
        }

        # Dihedrals
        @update = Polymatic::uniqueArray((@{$sys{'atoms'}{'diheds'}[$a1]},
            @{$sys{'atoms'}{'diheds'}[$a2]}));
        for (my $j=0; $j < scalar(@update); $j++)
        {
            @a = @{$sys{'diheds'}{'atoms'}[$update[$j]]};
            $type = Polymatic::getDihedType(\%sys, \@a);

            if ($type > 0)
            {
                $sys{'diheds'}{'type'}[$update[$j]] = $type;
            }
            elsif ($type < 0)
            {
                $sys{'diheds'}{'type'}[$update[$j]] = -1*$type;
                $sys{'diheds'}{'atoms'}[$update[$j]] = [reverse(@a)];
            }
            else
            {
                errExit("Dihedral type '".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[0]]].",".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[1]]].",".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[2]]].",".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[3]]].
                    "' is not defined.");
            }
        }

        # Impropers
        @update = Polymatic::uniqueArray((@{$sys{'atoms'}{'improps'}[$a1]},
            @{$sys{'atoms'}{'improps'}[$a2]}));
        for (my $j=0; $j < scalar(@update); $j++)
        {
            @a = @{$sys{'improps'}{'atoms'}[$update[$j]]};
            ($type, $order) = Polymatic::getImpropType(\%sys, \@a);

            if ($type > 0)
            {
                $sys{'improps'}{'type'}[$update[$j]] = $type;
                if ($order == 1) {
                    $sys{'improps'}{'atoms'}[$update[$j]] =
                        [$a[0], $a[1], $a[3], $a[2]];
                } elsif ($order == 2) {
                    $sys{'improps'}{'atoms'}[$update[$j]] =
                        [$a[2], $a[1], $a[0], $a[3]];
                } elsif ($order == 3) {
                    $sys{'improps'}{'atoms'}[$update[$j]] =
                        [$a[2], $a[1], $a[3], $a[0]];
                } elsif ($order == 4) {
                    $sys{'improps'}{'atoms'}[$update[$j]] =
                        [$a[3], $a[1], $a[0], $a[2]];
                } elsif ($order == 5) {
                    $sys{'improps'}{'atoms'}[$update[$j]] =
                        [$a[3], $a[1], $a[2], $a[0]];
                }
            }
            else
            {
                errExit("Dihedral type '".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[0]]].",".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[1]]].",".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[2]]].",".
                    $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[3]]].
                    "' is not defined.");
            }
        }
    }

    # Add new bonded terms
    for (my $i=0; $i < scalar(@addBonds); $i++)
    {
        # Skip if no angles/diheds/improps
        last if ($sys{'angleTypes'}{'count'} == 0 &&
            $sys{'dihedTypes'}{'count'} == 0 &&
            $sys{'impropTypes'}{'count'} == 0);

        # Atoms in bond
        ($a1, $a2) = @{$addBonds[$i]};
        @bonded1 = @{$sys{'atoms'}{'bonded'}[$a1]};
        @bonded2 = @{$sys{'atoms'}{'bonded'}[$a2]};

        for (my $j=0; $j < scalar(@bonded2); $j++)
        {
            # Angle 1,2,x
            $a3 = $bonded2[$j];
            next if ($a3 == $a1);
            push(@addAngles, [$a1, $a2, $a3])
                if ($sys{'angleTypes'}{'count'} > 0);

            # Dihedral 1,2,x,y
            @bonded3 = @{$sys{'atoms'}{'bonded'}[$a3]};
            for (my $k=0; $k < scalar(@bonded3); $k++)
            {
                $a4 = $bonded3[$k];
                next if ($a4 == $a2);
                push(@addDiheds, [$a1, $a2, $a3, $a4])
                    if ($sys{'dihedTypes'}{'count'} > 0);
            }
        }

        for (my $j=0; $j < scalar(@bonded1); $j++)
        {
            # Angle 2,1,x
            $a3 = $bonded1[$j];
            next if ($a3 == $a2);
            push(@addAngles, [$a2, $a1, $a3])
                if ($sys{'angleTypes'}{'count'} > 0);

            # Dihedral 2,1,x,y
            @bonded3 = @{$sys{'atoms'}{'bonded'}[$a3]};
            for (my $k=0; $k < scalar(@bonded3); $k++)
            {
                $a4 = $bonded3[$k];
                next if ($a4 == $a1);
                push(@addDiheds, [$a2, $a1, $a3, $a4])
                    if ($sys{'dihedTypes'}{'count'} > 0);
            }

            # Dihedral x,1,2,y
            for (my $k=0; $k < scalar(@bonded2); $k++)
            {
                $a4 = $bonded2[$k];
                next if ($a4 == $a1);
                push(@addDiheds, [$a3, $a1, $a2, $a4])
                    if ($sys{'dihedTypes'}{'count'} > 0);
            }
        }

        if ($sys{'impropTypes'}{'count'} > 0 && scalar(@bonded1) > 1)
        {
            # Improper 2,1,x,y
            for (my $j=0; $j < scalar(@bonded1)-1; $j++)
            {
                $a3 = $bonded1[$j];
                next if ($a3 == $a2);

                for (my $k=$j+1; $k < scalar(@bonded1); $k++)
                {
                    $a4 = $bonded1[$k];
                    next if ($a4 == $a2);
                    push(@addImprops, [$a2, $a1, $a3, $a4]);
                }
            }
        }

        if ($sys{'impropTypes'}{'count'} > 0 && scalar(@bonded2) > 1)
        {
            # Improper 1,2,x,y
            for (my $j=0; $j < scalar(@bonded1)-1; $j++)
            {
                $a3 = $bonded2[$j];
                next if ($a3 == $a1);

                for (my $k=$j+1; $k < scalar(@bonded2); $k++)
                {
                    $a4 = $bonded2[$k];
                    next if ($a4 == $a1);
                    push(@addImprops, [$a1, $a2, $a3, $a4]);
                }
            }
        }
    }

    # Delete duplicates
    @addBonds = Polymatic::delDupBonds(\@addBonds);
    @addAngles = Polymatic::delDupBonds(\@addAngles);
    @addDiheds = Polymatic::delDupBonds(\@addDiheds);
    @addImprops = Polymatic::delDupImprops(\@addImprops);

    # New bonds
    $num = $sys{'bonds'}{'count'};
    for (my $i=0; $i < scalar(@addBonds); $i++)
    {
        $num++;
        @a = @{$addBonds[$i]};
        $type = Polymatic::getBondType(\%sys, \@a);

        if ($type > 0)
        {
            $sys{'bonds'}{'atoms'}[$num] = [@a];
            $sys{'bonds'}{'type'}[$num] = $type;
        }
        elsif ($type < 0)
        {
            $sys{'bonds'}{'atoms'}[$num] = [reverse(@a)];
            $sys{'bonds'}{'type'}[$num] = -1*$type;
        }
        else
        {
            errExit("Bond type '".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[0]]].",".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[1]]].
                "' is not defined.");
        }
    }
    $sys{'bonds'}{'count'} = $num;

    # New angles
    $num = $sys{'angles'}{'count'};
    for (my $i=0; $i < scalar(@addAngles); $i++)
    {
        $num++;
        @a = @{$addAngles[$i]};
        $type = Polymatic::getAngleType(\%sys, \@a);

        if ($type > 0)
        {
            $sys{'angles'}{'atoms'}[$num] = [@a];
            $sys{'angles'}{'type'}[$num] = $type;
        }
        elsif ($type < 0)
        {
            $sys{'angles'}{'atoms'}[$num] = [reverse(@a)];
            $sys{'angles'}{'type'}[$num] = -1*$type;
        }
        else
        {
            errExit("Angle type '".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[0]]].",".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[1]]].",".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[2]]].
                "' is not defined.");
        }
    }
    $sys{'angles'}{'count'} = $num;

    # New dihedrals
    $num = $sys{'diheds'}{'count'};
    for (my $i=0; $i < scalar(@addDiheds); $i++)
    {
        $num++;
        @a = @{$addDiheds[$i]};
        $type = Polymatic::getDihedType(\%sys, \@a);

        if ($type > 0)
        {
            $sys{'diheds'}{'atoms'}[$num] = [@a];
            $sys{'diheds'}{'type'}[$num] = $type;
        }
        elsif ($type < 0)
        {
            $sys{'diheds'}{'atoms'}[$num] = [reverse(@a)];
            $sys{'diheds'}{'type'}[$num] = -1*$type;
        }
        else
        {
            errExit("Dihedral type '".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[0]]].",".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[1]]].",".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[2]]].",".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[3]]].
                "' is not defined.");
        }
    }
    $sys{'diheds'}{'count'} = $num;

    # New impropers
    $num = $sys{'improps'}{'count'};
    for (my $i=0; $i < scalar(@addImprops); $i++)
    {
        $num++;
        @a = @{$addImprops[$i]};
        ($type, $order) = Polymatic::getImpropType(\%sys, \@a);

        if ($type > 0)
        {
            $sys{'improps'}{'type'}[$num] = $type;
            if ($order == 0) {
                $sys{'improps'}{'atoms'}[$num] = [@a];
            } elsif ($order == 1) {
                $sys{'improps'}{'atoms'}[$num] = [$a[0], $a[1], $a[3], $a[2]];
            } elsif ($order == 2) {
                $sys{'improps'}{'atoms'}[$num] = [$a[2], $a[1], $a[0], $a[3]];
            } elsif ($order == 3) {
                $sys{'improps'}{'atoms'}[$num] = [$a[2], $a[1], $a[3], $a[0]];
            } elsif ($order == 4) {
                $sys{'improps'}{'atoms'}[$num] = [$a[3], $a[1], $a[0], $a[2]];
            } elsif ($order == 5) {
                $sys{'improps'}{'atoms'}[$num] = [$a[3], $a[1], $a[2], $a[0]];
            }
        }
        else
        {
            errExit("Dihedral type '".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[0]]].",".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[1]]].",".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[2]]].",".
                $sys{$at}{'name'}[$sys{'atoms'}{'type'}[$a[3]]].
                "' is not defined.");
        }
    }
    $sys{'improps'}{'count'} = $num;

    # Molecule numbers
    if ($sys{'atoms'}{'mol'}[$pair[0]] != $sys{'atoms'}{'mol'}[$pair[1]])
    {
        $num = $sys{'mols'}{'count'};

        # Max and min
        if ($sys{'atoms'}{'mol'}[$pair[0]] > $sys{'atoms'}{'mol'}[$pair[1]]) {
            $min = $sys{'atoms'}{'mol'}[$pair[1]];
            $max = $sys{'atoms'}{'mol'}[$pair[0]];
        } else {
            $min = $sys{'atoms'}{'mol'}[$pair[0]];
            $max = $sys{'atoms'}{'mol'}[$pair[1]];
        }

        # Move max to min
        @a = @{$sys{'mols'}{'atoms'}[$max]};
        for (my $i=0; $i < scalar(@a); $i++)
        {
            $sys{'atoms'}{'mol'}[$a[$i]] = $min;
            push(@{$sys{'mols'}{'atoms'}[$min]}, $a[$i]);
        }
        $sys{'mols'}{'atoms'}[$max] = [];

        # Move last to max
        @a = @{$sys{'mols'}{'atoms'}[$num]};
        for (my $i=0; $i < scalar(@a); $i++)
        {
            $sys{'atoms'}{'mol'}[$a[$i]] = $max;
            push(@{$sys{'mols'}{'atoms'}[$max]}, $a[$i]);
        }
        pop(@{$sys{'mols'}{'atoms'}});
        $sys{'mols'}{'count'} = $num-1;
    }
}

# getConnect( \@pair )
# Define connectivity from input script for the given pair
sub getConnect
{
    # Variables
    my @pair = @{$_[0]};
    my ($n, $a1, $a2);
    my (@atoms, @queue, @connect, @bonded);

    # Make sure connect and types are defined
    errExit("The 'connect' and 'types' commands must be defined ".
        "to use the 'vector', 'plane', or 'bond' commands.")
        if (!defined($inp{'connect'}) || !defined($inp{'types'}));

    # Initial atoms
    $atoms[1] = $pair[0];
    $atoms[2] = $pair[1];
    push(@queue, (1,2));

    # Follow connectivity
    while (scalar(@queue) > 0)
    {
        $n = shift(@queue);
        @connect = @{$inp{'connect'}[$n]};
        @bonded = @{$sys{'atoms'}{'bonded'}[$atoms[$n]]};

        for (my $i=0; $i < scalar(@bonded); $i++)
        {
            $a1 = $bonded[$i];
            for (my $j=0; $j < scalar(@connect); $j++)
            {
                $a2 = $connect[$j];
                if ($sys{'atomTypes'}{'name'}[$sys{'atoms'}{'type'}[$a1]] eq
                    $inp{'types'}[$a2])
                {
                    errExit("Atom connectivity in input script is not unique.")
                        if (defined($atoms[$a2]));
                    $atoms[$a2] = $a1;
                    push(@queue, $a2) if (defined($inp{'connect'}[$a2]));
                }
            }
        }
    }

    # Return atom definitions
    return @atoms;
}

# intra( \@pair )
# Check if given pair is within N bonds
sub intra
{
    # Variables
    my ($a1, $a2) = @{$_[0]};
    my ($b1, $b2, $b3, $b4, $b5);
    my (@bonded1, @bonded2, @bonded3, @bonded4, @bonded5);
    my $num = $inp{'intra'};

    # One bond
    @bonded1 = @{$sys{'atoms'}{'bonded'}[$a1]};
    for (my $i1=0; $i1 < scalar(@bonded1); $i1++)
    {
        $b1 = $bonded1[$i1];
        return 1 if ($b1 == $a2);
        next if ($num == 1);

        # Two bonds
        @bonded2 = @{$sys{'atoms'}{'bonded'}[$b1]};
        for (my $i2=0; $i2 < scalar(@bonded2); $i2++)
        {
            $b2 = $bonded2[$i2];
            return 1 if ($b2 == $a2);
            next if ($b2 == $a1);
            next if ($num == 2);

            # Three bonds
            @bonded3 = @{$sys{'atoms'}{'bonded'}[$b2]};
            for (my $i3=0; $i3 < scalar(@bonded3); $i3++)
            {
                $b3 = $bonded3[$i3];
                return 1 if ($b3 == $a2);
                next if ($b3 == $b1);
                next if ($num == 3);

                # Four bonds
                @bonded4 = @{$sys{'atoms'}{'bonded'}[$b3]};
                for (my $i4=0; $i4 < scalar(@bonded4); $i4++)
                {
                    $b4 = $bonded4[$i4];
                    return 1 if ($b4 == $a2);
                    next if ($b4 == $b2);
                    next if ($num == 4);

                    # Five bonds
                    @bonded5 = @{$sys{'atoms'}{'bonded'}[$b4]};
                    for (my $i5=0; $i5 < scalar(@bonded5); $i5++)
                    {
                        $b5 = $bonded5[$i5];
                        return 1 if ($b5 == $a2);
                        next if ($b5 == $b3);
                    }
                }
            }
        }
    }

    # Not bonded within N bonds
    return 0;
}

# aligned( \@pair )
# Perform alignment checks for given pair
sub aligned
{
    # Variables
    my @pair = @{$_[0]};
    my ($ang, @atoms, @cond);
    my (@a1, @a2, @v1, @v2, @pos1, @pos2);

    # Atom definitions
    @atoms = getConnect(\@pair);

    # Loop through checks
    for (my $i=0; $i < scalar(@{$inp{'align'}{'atoms'}}); $i++)
    {
        @a1 = @{$inp{'align'}{'atoms'}[$i][0]};
        @a2 = @{$inp{'align'}{'atoms'}[$i][1]};
        @cond = @{$inp{'align'}{'cond'}[$i]};
        @pos1 = ();
        @pos2 = ();

        # Get atoms based on atom definition
        for (my $j=0; $j < scalar(@a1); $j++)
        {
            errExit("Atom connectivity in input script ".
                "is not properly defined.")
                if (!defined($atoms[$a1[$j]]));
            $a1[$j] = $atoms[$a1[$j]];
            push(@pos1, [@{$sys{'atoms'}{'pos'}[$a1[$j]]}]);
        }

        for (my $j=0; $j < scalar(@a2); $j++)
        {
            errExit("Atom connectivity in input script ".
                "is not properly defined.")
                if (!defined($atoms[$a2[$j]]));
            $a2[$j] = $atoms[$a2[$j]];
            push(@pos2, [@{$sys{'atoms'}{'pos'}[$a2[$j]]}]);
        }

        # Vector or plane
        if (scalar(@a1) == 2) {
            @v1 = Polymatic::vectorSub(\@{$pos1[0]}, \@{$pos1[1]});
        } else {
            @v1 = Polymatic::normalPlane(\@pos1);
        }

        if (scalar(@a2) == 2) {
            @v2 = Polymatic::vectorSub(\@{$pos2[0]}, \@{$pos2[1]});
        } else {
            @v2 = Polymatic::normalPlane(\@pos2);
        }

        # Angle between vectors
        $ang = Polymatic::vectorAng(\@v1, \@v2) * 180/Math::Trig::pi;

        # Return 0 if not aligned
        if (scalar(@cond) == 1) {
            return 0 if (!eval("$ang $cond[0]"));
        } elsif (scalar(@cond) == 3) {
            return 0 if (!eval("$ang $cond[0] $cond[2] $ang $cond[1]"));
        }
    }

    # Return 1 if aligned
    return 1;
}

# getExtraBonds( \@pair )
# Define extra bonds based on the given pair
sub getExtraBonds
{
    # Variables
    my @pair = @{$_[0]};
    my ($a1, $a2, $sep, @atoms, @addBonds);

    # Atom definitions
    @atoms = getConnect(\@pair);

    # Extra bonds
    for (my $i=0; $i < scalar(@{$inp{'bond'}}); $i++)
    {
        $a1 = $atoms[$inp{'bond'}[$i][0]];
        $a2 = $atoms[$inp{'bond'}[$i][1]];
        errExit("Atom connectivity in input script is not properly defined.")
            if (!defined($a1) || !defined($a2));

        $sep = Polymatic::getSep(\%sys, $a1, $a2);
        printf "  Extra bond: %.2f A (%d,%d)\n", $sep, $a1, $a2;
        push(@addBonds, [$a1, $a2]);
    }

    # Return extra bonds
    return @addBonds;
}
