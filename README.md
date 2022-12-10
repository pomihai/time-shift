shiftBySeconds.sh

This program is designed to be used for shifting a time column in a log file.

Use-case:
If you have two log files coming from different machines that "live" in
different time zones and you need to synchronize them, you may want to shift
one of the time stamps or both to let's say UTC.

This script is an gawk program and follows the awk paradigm of parsing the file
one line at the time; one way to use this script is to parse the log file by
it like this:
```code
$ cat aLogFile.log | shiftBySeconds.sh "C02#D.M.YYYY#C03#H:M:S#3600"
```
Where the parameter string shows the format of the time-related column(s)

The string can be broken in column-number#column-info fields separated by the
"#" character. The column-info has the meaning of a time or a date.

When the column-info has the meaning of time then it should be of the form:

```code
 			H[H]:M[M]:S[S]
```

where if you have HH it means that the hour is zero-padded and if you
have H it means that the hour is not zero-padded so for example a format of
```code
		HH:M.s
```
would mean that the length of the time string varies from 6 to 8 characters,
the hour is zero-padded, minutes and seconds are not, also the separator
between the hour field and minutes ```:``` field is different from that	between
the minutes field and the seconds field ```.```.

When the column-info has the meaning of date then it should be of the form:

```code
			YYYY.M[M].D[D]
```

it uses the same logic from above with the exception that the year part
always has the century part: for example you cannot say	```"56.12.31"``` with
the format ```"YY.MM.DD"``` and hope to get a value for the last day of let's
say the year 2056
Observations:
* if you have a situation where the input has only two digits for the year,
  then you should know what century you are in and before you use this tool,
  you should concatenate the century part to the rest of the digits.
* There is the possibility that you have a year field > 9999;
  if this is happening, you may have to rewrite	parts of this tool,
  and also it is odd that you still use this after ~8000 years!!!

In the example from above:
```code
$ cat aLogFile.log | shiftBySeconds.sh "C02#D.M.YYYY#C03#H:M:S#3600"
```

- the second column ```"C02"``` of the ```aLogFile.log``` file contains a
  date in the ```day.month.year``` format where the month and day fields are
  not zero-padded.
- the third column ```"C03"``` of the ```aLogFile.log``` file contains a
  time in the ```hour:minute:second``` format where all the fields are not
  zero-padded. 

