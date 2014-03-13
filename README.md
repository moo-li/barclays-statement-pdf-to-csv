barclays-statement-pdf-to-csv
=============================

Convert Barclays PDF statements to useful CSV files.

### How to use

1.  Put all your PDF statements in a folder called `doc` in the root of this project.
1.  Run `rake parse`.
2.  There should now be a CSV file in the `doc` folder with your transactions in it.
  
### Notes

1.  Text versions of your statements will also be left in the folder by `rake parse`
2.  I tested it using 2013 statements from a Barclays business account. They may of course change their statement format at any time and this may stop this app from working.
