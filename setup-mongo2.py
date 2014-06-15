#!/usr/bin/python
# -*- coding: utf-8 -*-

# This program reads the text file (eg "database.txt") and converts it to Mongo DB format, outputs a JSON file

# This version (2) uses the improved numbering scheme

import sys
import os
import string
import re

from pymongo import Connection
from pymongo.errors import ConnectionFailure

try:
	c = Connection(host = "localhost", port = 27017)
	print "Connected successfully"
except ConnectionFailure, e:
	sys.stderr.write("Could not connect to MongoDB: %s" % e)
	sys.exit(1)

dbh = c["conkey_dev"]
assert dbh.connection == c
print "Database handle to 'conkey_dev' created successfully"

dbh.collection.remove(None, safe=True)
dbh.dictionaries.remove(None, safe=True)
dbh.dictionaries.drop()
print "Database cleared"

# Ask user for database text file, eg "database_default.txt"
fname = raw_input('Enter database text filename [database_default.txt]: ')
if fname == "":
	fname = "database_default.txt"
f = open(fname, 'r')
stdout = sys.stdout

grand_parents = []
current_level = -1
last_parent = None

pattern = re.compile("([0-9]?[A-Z])\.")

for line in f:
	stdout.write("****** " + line)
	line = line[:-1]
	if line[0] == '\t':			# this is a heading line
		# get heading level = number of periods '.'
		level = line.count('.')
		# the 'index' is the key combination for that item
		#index = ''.join(pattern.findall(line))		# join all the 'numbers' together
		index = pattern.findall(line)[-1]		# only the last 'number' is needed
		print index + ":"
		# get heading text
		heading = line.rpartition(" ")[2]
		# level has increased?
		if level == current_level:
			i = 1
			# add to current parent, current parent stays the same
			if grand_parents == []:
				doc = {
					"name" : heading,
					"idx" : index
				}
			else:
				doc = {
					"name" : heading,
					"idx" : index,
					"parent" : grand_parents[-1]
				}
			last_parent = dbh.collection.insert(doc, safe = True)
			# print "Inserted heading: %s" % doc
		elif level > current_level:
			i = 1
			# level has increased
			# new parent = current node
			if last_parent == None:
				doc = {
					"name" : heading,
					"idx" : index
				}
			else:
				doc = {
					"name" : heading,
					"idx" : index,
					"parent" : last_parent
				}
			grand_parents.append(last_parent)
			last_parent = dbh.collection.insert(doc, safe = True)
			# print "Inserted sub-heading: %s" % doc
		elif level < current_level:
			i = 1
			# retract one or more levels
			grand_parents = grand_parents[0: level - 1]
			if grand_parents == []:
				doc = {
					"name" : heading,
					"idx" : index
				}
			else:
				doc = {
					"name" : heading,
					"idx" : index,
					"parent" : grand_parents[-1]
				}
			last_parent = dbh.collection.insert(doc, safe = True)
			# print "Inserted heading: %s" % doc
			
	else:
		items = line.split('|')
		# add items to current parent
		for item in items:
			doc = {
				"name" : item,
				"idx" : ":" + str(i),
				"parent" : last_parent
			}
			i += 1
			dbh.collection.insert(doc, safe = True)
			# print "Inserted item: %s" % doc

	current_level = level
	# print grand_parents
	
f.close()

# export mongo to json
os.system("mongoexport -d conkey_dev -c collection > test.json")
print "Mongo DB 'conkey_dev' exported to test.json"

# re-format file as json array
os.system("sed 's/}$/},/; 1s/^{/[{/; $s/},$/}]/' test.json > db/conkey_db.json")
print "JSON formated as array and copied to db/conkey_db.json"

exit()
