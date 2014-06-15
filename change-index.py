#!/usr/bin/python
# -*- coding: utf-8 -*-

# Change index numbering scheme of Database text file

import sys
import os
import string

# Ask user for database text file, eg "database_default.txt"
fname = sys.argv[1]
if fname == "":
	fname = "database_default.txt"
f = open(fname, 'r')

stdout = sys.stdout

current_label = 1
parents = []
current_level = -1
i = 1

for line in f:
	# stdout.write("****** " + line)
	line = line[:-1]
	if line[0] == '\t':			# this is a heading line
		# get heading level = number of periods '.'
		level = line.count('.')
		# get heading
		heading = string.lstrip(line, '\t0123456789. ')
		# level has increased?
		if level == current_level:
			current_label += 1
			parents[-1] = current_label
			i = 1
		elif level > current_level:
			current_label = 1
			parents.append(current_label)
			i = 1
		elif level < current_level:
			parents = parents[0 : level]
			current_label = parents[-1] + 1
			parents[-1] = current_label
			i = 1
		stdout.write('\t')
		for p in parents:
			stdout.write(chr(p + 64) + '.')
			# stdout.write(chr(p + 64))
		stdout.write(' ' + heading + '\n')
	else:
		items = line.split('|')
		# add items to current parent
		for item in items:
			# print i, item
			print item
			i += 1

	current_level = level
	# print grand_parents

f.close()

# export mongo to json
# os.system("mongoexport -d conkey-yky -c collection > test.json")
exit()
